%% lab1_report_ex1.m
% Computer Lab Exercise 1, Exercises 1A and 1B, as used in the combined
% laboratory report. Prints every number quoted in the report and writes the
% figures (English labels) to ../figures/report/. Section 2.2 of Computer Lab
% Exercise 2 (margins of the same non-minimum-phase plant) is included here
% because it supports the gain recommendation of Exercise 1B.

here   = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
figDir = fullfile(here, '..', 'figures', 'report');
if ~exist(figDir, 'dir'), mkdir(figDir); end
cols = lines(6);

%% Exercise 1A: evaluate G(s) at s = -3 + j4
zs = [-1 -2];  ps = [0 -3 -4];
G  = zpk(zs, ps, 1);                       % (s+1)(s+2) / [s(s+3)(s+4)]
s0 = -3 + 4j;
Gs = evalfr(G, s0);
M  = abs(Gs);  th = rad2deg(angle(Gs));
fprintf('1A  G(s0) = %.6f %+.6fj,  M = %.6f,  theta = %.4f deg\n', real(Gs), imag(Gs), M, th);
vz = s0 - zs;  vp = s0 - ps;
fprintf('    vector method:\n');
for k = 1:2, fprintf('      zero %+d: vector %s, |.| = %.4f, angle = %8.4f deg\n', zs(k), num2str(vz(k)), abs(vz(k)), rad2deg(angle(vz(k)))); end
for k = 1:3, fprintf('      pole %+d: vector %s, |.| = %.4f, angle = %8.4f deg\n', ps(k), num2str(vp(k)), abs(vp(k)), rad2deg(angle(vp(k)))); end
Mv  = prod(abs(vz))/prod(abs(vp));
thv = sum(rad2deg(angle(vz))) - sum(rad2deg(angle(vp)));
fprintf('    M = %.6f (1/sqrt(20) = %.6f), theta = %.4f deg; difference to evalfr: %.1e, %.1e deg\n', ...
        Mv, 1/sqrt(20), thv, abs(Mv - M), abs(thv - th));
Gj4 = evalfr(G, 4j);
fprintf('    for comparison G(j4) = %.4f %+.4fj: |G| = %.4f, angle = %.2f deg\n', real(Gj4), imag(Gj4), abs(Gj4), rad2deg(angle(Gj4)));
fprintf('    angle condition: s0 is on the root locus only if theta = +-180 deg; a compensator would need %.2f deg at s0\n', ...
        -180 - th);

%% Exercise 1B, system 5.1: G1 = (s+1)(s+2) / [s(s+3)(s+4)]
G1 = G;
Kv = [0 logspace(-4, 4, 6000)];
R1 = rlocus(G1, Kv);
fprintf('\n1B  5.1  closed-loop poles of 1 + K G1:\n');
for K = [0.5 2 10 100], fprintf('      K = %6.1f : %s\n', K, mat2str(rlocus(G1, K).', 5)); end
fprintf('      max imaginary part along the locus = %.2e (all branches real)\n', max(abs(imag(R1(:)))));
[n1, d1] = tfdata(tf(G1), 'v');  n1 = n1(end-2:end);     % breakaway condition N'D - N D' = 0
cand = roots(conv(polyder(d1), n1) - conv(d1, polyder(n1)));
fprintf('      roots of the breakaway condition: %s (none lies on a real-axis segment of the locus)\n', mat2str(cand(abs(imag(cand)) < 1e-9).', 5));

%% Exercise 1B, system 5.2: G2 = K (s-1)(s-2) / (s^2 + 4s + 16)
G2 = tf(conv([1 -1], [1 -2]), [1 4 16]);
R2 = rlocus(G2, Kv);
Kc = fzero(@(K) max(real(rlocus(G2, K))), [1 1.6]);
pc = rlocus(G2, Kc);
fprintf('\n1B  5.2(b)  imaginary-axis crossing: K = %.6f (4/3 = %.6f), poles %s\n', Kc, 4/3, mat2str(pc.', 6));
try
    [Kf, pf] = rlocfind(G2, 1j*2*sqrt(2));
    fprintf('            rlocfind at s = j2.8284: K = %.4f, poles %s\n', Kf, mat2str(pf.', 5));
catch err
    fprintf('            rlocfind unavailable (%s)\n', err.message);
end
zet  = @(K) (4 - 3*K)./(2*sqrt((16 + 2*K).*(1 + K)));
wnf  = @(K) sqrt((16 + 2*K)./(1 + K));
K45  = fzero(@(K) zet(K) - 0.45, [0 1]);
p45  = rlocus(G2, K45);
fprintf('     5.2(c)  zeta = 0.45 at K = %.6f, poles %s, wn = %.4f rad/s\n', K45, mat2str(p45.', 6), wnf(K45));
[wn45, z45] = damp(feedback(K45*G2, 1));
fprintf('            check with damp(): zeta = %.4f, wn = %.4f\n', z45(1), wn45(1));
fprintf('     5.2(d)  Routh: (1+K) s^2 + (4-3K) s + (16+2K): stable for -1 < K < 4/3\n');
for K = [1.3 4/3 1.4], fprintf('            K = %.4f : poles %s\n', K, mat2str(rlocus(G2, K).', 5)); end
sb = roots([1 4 -8]);  sb = sb(sb > 1 & sb < 2);
fprintf('            break-in point on (1,2): s = %.4f at K = %.2f\n', sb, -polyval([1 4 16], sb)/polyval([1 -3 2], sb));

fprintf('\n     gain trade-off (unity feedback, proportional gain K):\n');
fprintf('       K       poles               zeta    wn    Re(p)  4/|Re| (s)  T(0)    GM=4/(3K)  y(0+)   y_min    ts2%%(s)\n');
Ktab = [0.04 K45 0.2 1/3 2/3 1];
for K = Ktab
    T = feedback(K*G2, 1);  p = pole(T);
    [ys, ts_] = step(T, linspace(0, 20, 20001));
    si = stepinfo(T, 'SettlingTimeThreshold', 0.02);
    fprintf('     %6.4f  %-20s  %5.3f  %5.3f  %6.3f  %8.2f  %7.4f  %8.2f   %6.4f  %7.4f  %7.2f\n', K, ...
        num2str(p(1), '%.3f'), zet(K), wnf(K), real(p(1)), 4/abs(real(p(1))), dcgain(T), 4/(3*K), ...
        ys(1), min(ys), si.SettlingTime);
end

%% Computer Lab 2, Section 2.2: margins of G2 at K = 1 (frequency-domain cross-check)
[Gm, Pm, Wcg, Wcp] = margin(G2);
w = logspace(-2, 2, 20000);  mg = squeeze(abs(freqresp(G2, w)));
fprintf('\nLab 2 Sec. 2.2  K = 1: GM = %.4f (%.4f dB) at %.4f rad/s, PM = %.3f deg at %.4f rad/s\n', ...
        Gm, 20*log10(Gm), Wcg, Pm, Wcp);
fprintf('               closed-loop poles at K = 1: %s (stable despite PM < 0)\n', mat2str(pole(feedback(G2, 1)).', 5));
fprintf('               max |G2(jw)| = %.4f (%.2f dB): |K G2| < 1 at all frequencies for K < %.4f\n', ...
        max(mg), 20*log10(max(mg)), 1/max(mg));

%% integral action as the alternative structure: C(s) = Ki/s
fprintf('\n     integral control Ki/s: characteristic s^3 + (4+Ki) s^2 + (16-3Ki) s + 2Ki\n');
Kimax = fzero(@(k) max(real(roots([1 4+k 16-3*k 2*k]))), [3 5.3]);
fprintf('     stable for 0 < Ki < %.4f (Routh: -3Ki^2 + 2Ki + 64 > 0 -> %.4f)\n', Kimax, (1 + sqrt(193))/3);
for Ki = [0.5 1 2]
    T = feedback(tf(Ki, [1 0])*G2, 1);  si = stepinfo(T);  [ys, ~] = step(T, linspace(0, 200, 200001));
    fprintf('       Ki = %.1f: T(0) = %.3f, ts = %.1f s, overshoot = %.1f %%, minimum = %.3f, dominant pole %s\n', ...
        Ki, dcgain(T), si.SettlingTime, si.Overshoot, min(ys), num2str(max(real(pole(T))), '%.3f'));
end

%% ------------------------------------------------------------- figures
% Fig 1A: vectors and frequency response
fig = newfig(16, 7.5);  tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl, 1, [2 1]);  hold(ax, 'on');
for k = 1:2
    quiver(ax, zs(k), 0, real(vz(k)), imag(vz(k)), 0, 'LineWidth', 1.2, 'Color', cols(1,:), 'MaxHeadSize', 0.15);
end
for k = 1:3
    quiver(ax, ps(k), 0, real(vp(k)), imag(vp(k)), 0, 'LineWidth', 1.2, 'Color', cols(2,:), 'MaxHeadSize', 0.15);
end
plot(ax, zs, [0 0], 'o', 'MarkerSize', 7, 'LineWidth', 1.4, 'Color', cols(1,:));
plot(ax, ps, [0 0 0], 'x', 'MarkerSize', 9, 'LineWidth', 1.6, 'Color', cols(2,:));
plot(ax, real(s0), imag(s0), 'p', 'MarkerSize', 11, 'MarkerFaceColor', cols(3,:), 'Color', 'k');
text(ax, -2.85, 4.35, 's_0 = -3 + j4', 'FontSize', 8);
text(ax, -5.3, -0.75, sprintf('M = %.4f,  \\theta = %.2f\\circ', M, th), 'FontSize', 8);
xline(ax, 0, 'k-', 'LineWidth', 0.5);  yline(ax, 0, 'k-', 'LineWidth', 0.5);
axis(ax, 'equal');  xlim(ax, [-5.5 1.5]);  ylim(ax, [-1.2 5]);
xlabel(ax, 'Real axis');  ylabel(ax, 'Imaginary axis');
title(ax, '(a) Zero (blue) and pole (orange) vectors', 'FontWeight', 'normal');  style(ax);
[mgG, phG] = bode(G, w);  mgG = squeeze(mgG);  phG = squeeze(phG);
ax = nexttile(tl, 2);  semilogx(ax, w, 20*log10(mgG), 'LineWidth', 1.3, 'Color', cols(1,:));  hold(ax, 'on');
semilogx(ax, 4, 20*log10(abs(Gj4)), 'o', 'Color', cols(2,:), 'LineWidth', 1.3);
text(ax, 4.5, 20*log10(abs(Gj4)) + 7, sprintf('|G(j4)| = %.3f', abs(Gj4)), 'FontSize', 8);
ylabel(ax, 'Magnitude (dB)');  title(ax, '(b) Frequency response G(j\omega)', 'FontWeight', 'normal');
xlim(ax, [1e-2 1e2]);  style(ax);
ax = nexttile(tl, 4);  semilogx(ax, w, phG, 'LineWidth', 1.3, 'Color', cols(1,:));  hold(ax, 'on');
semilogx(ax, 4, rad2deg(angle(Gj4)), 'o', 'Color', cols(2,:), 'LineWidth', 1.3);
text(ax, 4.5, rad2deg(angle(Gj4)) - 9, sprintf('%.1f\\circ', rad2deg(angle(Gj4))), 'FontSize', 8);
ylabel(ax, 'Phase (deg)');  xlabel(ax, 'Frequency (rad/s)');  xlim(ax, [1e-2 1e2]);  ylim(ax, [-95 -35]);  style(ax);
savepng(fig, 'ex1A_vectors_bode.png', figDir);

% Fig 1B-1: root locus of G1
fig = newfig(16, 6.5);  ax = axes(fig);  hold(ax, 'on');
for i = 1:size(R1, 1), plot(ax, real(R1(i,:)), imag(R1(i,:)), 'LineWidth', 1.6, 'Color', cols(1,:), 'HandleVisibility', 'off'); end
plot(ax, zs, [0 0], 'o', 'MarkerSize', 7, 'LineWidth', 1.4, 'Color', 'k', 'DisplayName', 'open-loop zeros');
plot(ax, ps, [0 0 0], 'x', 'MarkerSize', 9, 'LineWidth', 1.6, 'Color', 'k', 'DisplayName', 'open-loop poles');
mk = {'s', 'd'};
for i = 1:2
    K = [2 10];  p = rlocus(G1, K(i));
    plot(ax, real(p), imag(p), mk{i}, 'MarkerSize', 7, 'Color', cols(i+1,:), 'LineWidth', 1.2, ...
         'DisplayName', sprintf('closed-loop poles, K = %g', K(i)));
end
legend(ax, 'Location', 'southwest', 'FontSize', 8);
xline(ax, 0, 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');
xlim(ax, [-15 1]);  ylim(ax, [-1 1]);
xlabel(ax, 'Real axis (s^{-1})');  ylabel(ax, 'Imaginary axis (s^{-1})');
title(ax, 'Root locus of G_1(s) = (s+1)(s+2)/[s(s+3)(s+4)]: all branches stay on the negative real axis', 'FontWeight', 'normal');
style(ax);  savepng(fig, 'ex1B_rlocus_G1.png', figDir);

% Fig 1B-2: root locus of G2 with zeta = 0.45 line and the key gains
fig = newfig(16, 9);  ax = axes(fig);  hold(ax, 'on');
for i = 1:size(R2, 1), plot(ax, real(R2(i,:)), imag(R2(i,:)), 'LineWidth', 1.6, 'Color', cols(1,:), 'HandleVisibility', 'off'); end
rr = linspace(0, 6, 2);  b45 = acos(0.45);
plot(ax, -rr*cos(b45), rr*sin(b45), '--', 'Color', [0.45 0.45 0.45], 'DisplayName', '\zeta = 0.45 line');
plot(ax, -rr*cos(b45), -rr*sin(b45), '--', 'Color', [0.45 0.45 0.45], 'HandleVisibility', 'off');
plot(ax, [1 2], [0 0], 'o', 'MarkerSize', 7, 'LineWidth', 1.4, 'Color', 'k', 'DisplayName', 'open-loop zeros');
plot(ax, [-2 -2], [1 -1]*sqrt(12), 'x', 'MarkerSize', 9, 'LineWidth', 1.6, 'Color', 'k', 'DisplayName', 'open-loop poles');
plot(ax, real(p45), imag(p45), 's', 'MarkerSize', 7, 'LineWidth', 1.4, 'Color', cols(2,:), 'DisplayName', sprintf('K = %.3f (\\zeta = 0.45)', K45));
p3 = rlocus(G2, 1/3);
plot(ax, real(p3), imag(p3), 'd', 'MarkerSize', 6, 'LineWidth', 1.3, 'Color', cols(5,:), 'DisplayName', 'K = 0.333 (\zeta = 0.32)');
plot(ax, real(pc), imag(pc), 'o', 'MarkerSize', 7, 'LineWidth', 1.4, 'Color', cols(4,:), 'DisplayName', 'K = 4/3 (j\omega crossing, \pm j2.83)');
plot(ax, sb, 0, '^', 'MarkerSize', 6, 'LineWidth', 1.2, 'Color', cols(3,:), 'DisplayName', sprintf('break-in s = %.3f (K = %.1f)', sb, -polyval([1 4 16], sb)/polyval([1 -3 2], sb)));
xline(ax, 0, 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');  yline(ax, 0, 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');
axis(ax, 'equal');  xlim(ax, [-3 3]);  ylim(ax, [-4 4]);
xlabel(ax, 'Real axis (s^{-1})');  ylabel(ax, 'Imaginary axis (s^{-1})');
legend(ax, 'Location', 'eastoutside', 'FontSize', 8);
title(ax, 'Root locus of K(s-1)(s-2)/(s^2+4s+16)', 'FontWeight', 'normal');
style(ax);  savepng(fig, 'ex1B_rlocus_G2.png', figDir);

% Fig 1B-3: both loci on the same axes (5.2e)
fig = newfig(16, 7.5);  ax = axes(fig);  hold(ax, 'on');
for i = 1:size(R1, 1), h1 = plot(ax, real(R1(i,:)), imag(R1(i,:)), 'LineWidth', 1.5, 'Color', cols(1,:)); end
for i = 1:size(R2, 1), h2 = plot(ax, real(R2(i,:)), imag(R2(i,:)), 'LineWidth', 1.5, 'Color', cols(2,:)); end
plot(ax, zs, [0 0], 'o', 'Color', cols(1,:), 'LineWidth', 1.3);  plot(ax, ps, [0 0 0], 'x', 'Color', cols(1,:), 'LineWidth', 1.5, 'MarkerSize', 8);
plot(ax, [1 2], [0 0], 'o', 'Color', cols(2,:), 'LineWidth', 1.3);  plot(ax, [-2 -2], [1 -1]*sqrt(12), 'x', 'Color', cols(2,:), 'LineWidth', 1.5, 'MarkerSize', 8);
xline(ax, 0, 'k-', 'LineWidth', 0.5);  yline(ax, 0, 'k-', 'LineWidth', 0.5);
xlim(ax, [-10 3]);  ylim(ax, [-4 4]);
xlabel(ax, 'Real axis (s^{-1})');  ylabel(ax, 'Imaginary axis (s^{-1})');
legend(ax, [h1 h2], {'5.1: (s+1)(s+2)/[s(s+3)(s+4)]', '5.2: (s-1)(s-2)/(s^2+4s+16)'}, 'Location', 'southwest', 'FontSize', 8);
title(ax, 'Root loci of both systems (5.2e)', 'FontWeight', 'normal');
style(ax);  savepng(fig, 'ex1B_rlocus_both.png', figDir);

% Fig 1B-4: closed-loop step responses of the non-minimum-phase loop
fig = newfig(16, 6.5);  ax = axes(fig);  hold(ax, 'on');
tt = linspace(0, 8, 8001);  ks = [K45 0.2 1/3 1];  lab = {sprintf('K = %.3f', K45), 'K = 0.2', 'K = 0.333', 'K = 1'};
for i = 1:numel(ks)
    plot(ax, tt, step(feedback(ks(i)*G2, 1), tt), 'LineWidth', 1.3, 'Color', cols(i,:), 'DisplayName', lab{i});
end
yline(ax, 0, 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');
xlabel(ax, 'Time (s)');  ylabel(ax, 'Output y(t) for a unit step command');
legend(ax, 'Location', 'northeast', 'FontSize', 8);
title(ax, 'Closed-loop step responses of the non-minimum-phase loop (5.2)', 'FontWeight', 'normal');
style(ax);  savepng(fig, 'ex1B_G2_steps.png', figDir);

% Fig 1B-5: margins of G2 at K = 1 (Lab 2, Section 2.2)
fig = newfig(16, 7);  tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
[m2, p2] = bode(G2, w);  m2 = squeeze(m2);  p2 = squeeze(p2);
ax = nexttile(tl, 1);  semilogx(ax, w, 20*log10(m2), 'LineWidth', 1.3, 'Color', cols(1,:));  hold(ax, 'on');
yline(ax, 0, 'k:');  semilogx(ax, Wcg, -20*log10(Gm), 'o', 'Color', cols(2,:), 'LineWidth', 1.3);
text(ax, 0.012, -3.5, sprintf('GM = %.2f dB at %.2f rad/s', 20*log10(Gm), Wcg), 'FontSize', 7);
ylabel(ax, 'Magnitude (dB)');  xlim(ax, [1e-2 1e2]);  title(ax, '(a) Bode diagram, K = 1', 'FontWeight', 'normal');  style(ax);
ax = nexttile(tl, 3);  semilogx(ax, w, p2, 'LineWidth', 1.3, 'Color', cols(1,:));  hold(ax, 'on');
yline(ax, -180, 'k:');  semilogx(ax, Wcp, Pm - 180, 'o', 'Color', cols(2,:), 'LineWidth', 1.3);
text(ax, 0.012, -250, sprintf('PM = %.1f\\circ at %.2f rad/s', Pm, Wcp), 'FontSize', 7);
ylabel(ax, 'Phase (deg)');  xlabel(ax, 'Frequency (rad/s)');  xlim(ax, [1e-2 1e2]);  ylim(ax, [-370 10]);  yticks(ax, -360:90:0);  style(ax);
ax = nexttile(tl, 2, [2 1]);  hold(ax, 'on');
wn_ = [-fliplr(w) w];  Gw = squeeze(freqresp(G2, wn_));
plot(ax, real(Gw), imag(Gw), 'LineWidth', 1.3, 'Color', cols(1,:));
th_ = linspace(0, 2*pi, 400);  plot(ax, cos(th_), sin(th_), 'k:');
plot(ax, -1, 0, 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);  plot(ax, -1/Gm, 0, 'o', 'Color', cols(2,:), 'LineWidth', 1.3);
text(ax, -0.95, -0.18, sprintf('%.2f', -1/Gm), 'FontSize', 7);  text(ax, -1.25, 0.15, '-1', 'FontSize', 7, 'Color', 'r');
axis(ax, 'equal');  xlim(ax, [-1.5 1.5]);  ylim(ax, [-1.4 1.4]);
xlabel(ax, 'Real axis');  ylabel(ax, 'Imaginary axis');
title(ax, '(b) Nyquist plot, K = 1', 'FontWeight', 'normal');  style(ax);
savepng(fig, 'ex1B_G2_margins.png', figDir);
fprintf('\nFigures written to %s\n', figDir);

%% ================================================================ helpers
function fig = newfig(w, h)
fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [2 2 w h]);
theme(fig, 'light');  set(fig, 'Color', 'w');
end

function style(ax)
set(ax, 'FontName', 'Helvetica', 'FontSize', 9, 'LineWidth', 0.6, 'Box', 'on');
grid(ax, 'on');  ax.GridAlpha = 0.15;
end

function savepng(fig, name, figDir)
exportgraphics(fig, fullfile(figDir, name), 'Resolution', 300);
close(fig);
end
