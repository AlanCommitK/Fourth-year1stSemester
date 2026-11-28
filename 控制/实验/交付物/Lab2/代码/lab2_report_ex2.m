%% lab2_report_ex2.m
% Computer Lab Exercise 2, Exercises 2A and 2B, as used in the combined
% laboratory report. Prints every number quoted in the report and writes the
% figures (English labels) to ../figures/report/.
% Requires the Control System and Symbolic Math Toolboxes.

here   = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
figDir = fullfile(here, '..', 'figures', 'report');
if ~exist(figDir, 'dir'), mkdir(figDir); end
cols = lines(6);

%% Exercise 2A
% 3.1 eigenvalues, natural frequency and damping of H(s)
H = tf([4 1], [1 3 5]);
[wnH, zH, pH] = damp(H);
fprintf('2A 3.1  H(s) = (4s+1)/(s^2+3s+5): poles %s, wn = %.6f rad/s, zeta = %.6f\n', mat2str(pH.', 6), wnH(1), zH(1));
fprintf('        by hand: wn = sqrt(5) = %.6f, zeta = 3/(2 sqrt 5) = %.6f\n', sqrt(5), 3/(2*sqrt(5)));

% 3.2 MIMO model and its DC gain
Hm = [tf(1, 1), tf([1 -1], [1 1 3]); tf(1, [1 1]), tf([1 2], [1 -3])];
fprintf('   3.2  dcgain(Hm) = %s\n', mat2str(dcgain(Hm), 6));
fprintf('        poles of the (2,2) element: %s (unstable channel: no steady state)\n', mat2str(pole(Hm(2,2)).', 4));

% 3.4 second-order block, 3.5 closed loop of Figure 2
z0 = 0.35;  w0 = 3.4;
G  = tf(w0^2, [1 2*z0*w0 w0^2]);
T  = feedback(G, H);
[nT, dT] = tfdata(T, 'v');
fprintf('   3.4  G(s) = %.4g/(s^2 + %.4g s + %.4g)\n', w0^2, 2*z0*w0, w0^2);
fprintf('   3.5  T(s) = G/(1+GH) = (%s)/(%s)\n', strtrim(poly2str(nT(find(nT, 1):end), 's')), strtrim(poly2str(dT, 's')));
fprintf('        T(0) = %.6f (= 1/(1 + 1/5) = %.6f)\n', dcgain(T), 5/6);

% 3.6 closed-loop poles and zeros
[wnT, zT, pT] = damp(T);
fprintf('   3.6  closed-loop poles, wn, zeta:\n');
for k = 1:numel(pT), fprintf('          %-24s wn = %.6f  zeta = %.6f\n', num2str(pT(k), '%.6f'), wnT(k), zT(k)); end
fprintf('        closed-loop zeros: %s (the poles of H)\n', mat2str(zero(T).', 6));
siG = stepinfo(G);  siT = stepinfo(T);
fprintf('        step, G alone : OS = %.3f %%, ts = %.3f s, tr = %.3f s\n', siG.Overshoot, siG.SettlingTime, siG.RiseTime);
fprintf('        step, closed  : OS = %.3f %%, ts = %.3f s, tr = %.3f s, peak time = %.3f s\n', ...
        siT.Overshoot, siT.SettlingTime, siT.RiseTime, siT.PeakTime);
[~, idd] = min(zT.*wnT);  zd = zT(idd);  wd = wnT(idd);      % slowest-decaying (dominant) pair
fprintf('        dominant pair: period %.3f s, envelope time constant %.3f s, cycles to settle %.1f\n', ...
        2*pi/(wd*sqrt(1 - zd^2)), 1/(zd*wd), siT.SettlingTime/(2*pi/(wd*sqrt(1 - zd^2))));
fprintf('        second-order formula with zeta = %.4f would predict OS = %.2f %%\n', zd, 100*exp(-pi*zd/sqrt(1 - zd^2)));

% 3.7 response to r = exp(-0.5 t)
t  = (0:0.001:60)';  r = exp(-0.5*t);
y  = lsim(T, r, t);
[ypk, ipk] = max(abs(y));
fprintf('   3.7  peak |y| = %.4f at t = %.3f s; y(10) = %.4f, y(20) = %.4f\n', ypk, t(ipk), y(t == 10), y(t == 20));

% which parameter matters most: vary the design values of G one at a time
fprintf('\n   sensitivity of the closed loop to the parameters of G (H fixed):\n');
fprintf('     zeta_G  wn_G   dominant zeta  dominant wn   OS(%%)    ts(s)    T(0)\n');
cases = [0.35 3.4; 0.5 3.4; 0.7 3.4; 1.0 3.4; 0.35 1.7; 0.35 6.8];
for c = 1:size(cases, 1)
    Gc = tf(cases(c,2)^2, [1 2*cases(c,1)*cases(c,2) cases(c,2)^2]);
    Tc = feedback(Gc, H);  [wn_, z_] = damp(Tc);  [~, id] = min(z_.*wn_);   % slowest-decaying pole
    sc = stepinfo(Tc);
    fprintf('     %5.2f  %5.2f     %7.4f      %7.4f    %7.2f  %7.2f  %6.4f\n', cases(c,1), cases(c,2), ...
            z_(id), wn_(id), sc.Overshoot, sc.SettlingTime, dcgain(Tc));
end

% local sensitivity (elasticity) of the dominant closed-loop damping ratio
zdom = @(zg, wg) min(-real(pole(feedback(tf(wg^2, [1 2*zg*wg wg^2]), H))) ./ ...
                     abs(pole(feedback(tf(wg^2, [1 2*zg*wg wg^2]), H))));
e_z = (log(zdom(z0*1.01, w0)) - log(zdom(z0*0.99, w0)))/(log(1.01) - log(0.99));
e_w = (log(zdom(z0, w0*1.01)) - log(zdom(z0, w0*0.99)))/(log(1.01) - log(0.99));
fprintf('     elasticity of the dominant damping: d ln(zeta_cl)/d ln(zeta_G) = %.2f, d ln(zeta_cl)/d ln(wn_G) = %.2f\n', e_z, e_w);

%% Exercise 2B: mesh analysis of the network of Figure 3
syms s V
Z = [2*s + 2, -(2*s + 1), -1;
     -(2*s + 1), 9*s + 1, -4*s;
     -1, -4*s, 4*s + 1 + 1/s];
I = simplify(Z\[V; 0; 0]);
fprintf('\n2B 4.1  mesh impedance matrix Z(s) = %s\n', char(Z));
for k = 1:3, fprintf('   4.2  I%d/V = %s\n', k, char(simplify(I(k)/V))); end
I3V = simplify(I(3)/V);
[nS, dS] = numden(I3V);
nI = sym2poly(expand(nS));  dI = sym2poly(expand(dS));
sc = dI(1)/24;  nI = nI/sc;  dI = dI/sc;            % scale to the form with leading coefficient 24
Hn = tf(nI, dI);
fprintf('   4.3  I3/V = (%s)/(%s)\n', strtrim(poly2str(nI, 's')), strtrim(poly2str(dI, 's')));

% independent check: nodal analysis (node A as reference, V_T = V)
% KCL at M: (VM - V)/1 + VM/(2s+1) + (VM - VB)/(4s) = 0
% KCL at B: (VB - VM)/(4s) + VB/(3s) + (VB - V) s = 0 ;  I3 = s (V - VB)
dev = 0;
for sv = [0.3j 1j 2.5j 0.7+0.4j]
    Yn = [1 + 1/(2*sv + 1) + 1/(4*sv), -1/(4*sv); -1/(4*sv), 1/(4*sv) + 1/(3*sv) + sv];
    vn = Yn\[1; sv];
    dev = max(dev, abs(sv*(1 - vn(2)) - evalfr(Hn, sv)));
end
fprintf('        nodal-analysis check at four test points: max deviation %.1e\n', dev);

[wnN, zN, pN] = damp(Hn);
fprintf('        poles, wn, zeta, time constant:\n');
for k = 1:numel(pN), fprintf('          %-24s wn = %.6f  zeta = %.6f  tau = %.2f s\n', num2str(pN(k), '%.6f'), wnN(k), zN(k), 1/(zN(k)*wnN(k))); end
fprintf('        zeros: %s;  value at s = 0: %g\n', mat2str(zero(Hn).', 5), dcgain(Hn));
tt = (0:0.01:300)';  i3 = step(Hn, tt);
[pk, ip] = max(abs(i3));  last = find(abs(i3) > 0.02*pk, 1, 'last');
fprintf('        step: peak |i3| = %.4f A at %.2f s; |i3| stays below 2 %% of peak after %.1f s\n', pk, tt(ip), tt(last + 1));
for K = [1 5]
    [~, zc] = damp(feedback(K*Hn, 1));
    fprintf('        proportional loop K = %g around I3/V: lowest closed-loop damping %.3f\n', K, min(zc));
end

% effect of the modelling assumptions on the dominant damping
syms L2 Ra R1 L4 L3 Cc rw
Zp = [R1 + L2*s + Ra + rw, -(L2*s + Ra + rw), -R1;
      -(L2*s + Ra + rw), (L2*s + Ra + rw) + (L4*s + rw) + (L3*s + rw), -(L4*s + rw);
      -R1, -(L4*s + rw), R1 + L4*s + rw + 1/(Cc*s)];
[dP, ~] = numden(simplify(det(Zp)));                 % numerator of det Z = characteristic polynomial
fD = matlabFunction(coeffs(collect(expand(dP), s), s, 'All'), 'Vars', {L2, Ra, R1, L4, L3, Cc, rw});
nom = {2, 1, 1, 4, 3, 1, 0};
pd  = roots(fD(nom{:}));
fprintf('\n        parametric model reproduces the nominal poles: max error %.1e\n', ...
        max(abs(sort(pd) - sort(pN))));
for rwv = [0.1 0.5 1]
    p_ = roots(fD(2, 1, 1, 4, 3, 1, rwv));  [z_, i_] = min(-real(p_)./abs(p_));
    fprintf('        winding resistance %.1f ohm in each inductor: dominant zeta = %.4f, tau = %.2f s\n', ...
            rwv, z_, -1/real(p_(i_)));
end
rng(2959453);  Nmc = 5000;  zmc = zeros(Nmc, 1);  tmc = zeros(Nmc, 1);
for k = 1:Nmc
    u = @(tol) 1 + tol*(2*rand - 1);
    p_ = roots(fD(2*u(0.10), 1*u(0.05), 1*u(0.05), 4*u(0.10), 3*u(0.10), 1*u(0.20), 0));
    [zmc(k), i_] = min(-real(p_)./abs(p_));  tmc(k) = -1/real(p_(i_));
end
fprintf('        Monte Carlo (L +-10 %%, R +-5 %%, C +-20 %%, uniform, %d samples):\n', Nmc);
fprintf('          dominant zeta %.4f to %.4f (5-95 %%: %.4f to %.4f); time constant %.1f to %.1f s\n', ...
        min(zmc), max(zmc), prctile(zmc, 5), prctile(zmc, 95), min(tmc), max(tmc));

%% ------------------------------------------------------------- figures
w = logspace(-2, 2, 4000);
% MIMO Bode
[mg, ph] = bode(Hm, w);
fig = newfig(16, 13);  tl = tiledlayout(fig, 4, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for out = 1:2
    for in = 1:2
        ax = nexttile(tl, (2*out - 2)*2 + in);
        semilogx(ax, w, 20*log10(squeeze(mg(out, in, :))), 'LineWidth', 1.2, 'Color', cols(1,:));
        if out == 1, title(ax, sprintf('From input %d', in), 'FontWeight', 'normal'); end
        if in == 1, ylabel(ax, {sprintf('To output %d', out), 'Mag. (dB)'}); end
        xlim(ax, [1e-2 1e2]);  style(ax);
        ax = nexttile(tl, (2*out - 1)*2 + in);
        semilogx(ax, w, squeeze(ph(out, in, :)), 'LineWidth', 1.2, 'Color', cols(2,:));
        if in == 1, ylabel(ax, 'Phase (deg)'); end
        if out == 2, xlabel(ax, 'Frequency (rad/s)'); end
        xlim(ax, [1e-2 1e2]);  style(ax);
    end
end
savepng(fig, 'ex2A_mimo_bode.png', figDir);

% closed-loop pole-zero map and impulse response
fig = newfig(16, 6.5);  tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl);  hold(ax, 'on');
for zg = [0.04 0.2 0.4 0.6 0.8]
    b = acos(zg);  plot(ax, [0 -6*cos(b)], [0 6*sin(b)], ':', 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
    plot(ax, [0 -6*cos(b)], [0 -6*sin(b)], ':', 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
    text(ax, -4.75*cos(b) - 0.05, 4.75*sin(b), sprintf('%.2f', zg), 'FontSize', 7, 'Color', [0.4 0.4 0.4]);
end
plot(ax, real(pT), imag(pT), 'x', 'MarkerSize', 9, 'LineWidth', 1.6, 'Color', cols(2,:), 'DisplayName', 'poles');
zz = zero(T);
plot(ax, real(zz), imag(zz), 'o', 'MarkerSize', 7, 'LineWidth', 1.4, 'Color', cols(1,:), 'DisplayName', 'zeros');
xline(ax, 0, 'k-', 'HandleVisibility', 'off');  yline(ax, 0, 'k-', 'HandleVisibility', 'off');
xlim(ax, [-4.6 0.4]);  ylim(ax, [-5 5]);
xlabel(ax, 'Real axis (s^{-1})');  ylabel(ax, 'Imaginary axis (s^{-1})');
legend(ax, 'Location', 'southwest', 'FontSize', 7);
title(ax, '(a) Closed-loop poles and zeros (\zeta lines dotted)', 'FontWeight', 'normal');  style(ax);
ax = nexttile(tl);
ti = (0:0.005:40)';  plot(ax, ti, impulse(T, ti), 'LineWidth', 1.0, 'Color', cols(1,:));
xlabel(ax, 'Time (s)');  ylabel(ax, 'Impulse response');
title(ax, '(b) Impulse response', 'FontWeight', 'normal');  style(ax);
savepng(fig, 'ex2A_pz_impulse.png', figDir);

% exponential input and step responses
fig = newfig(16, 6.5);  tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl);  hold(ax, 'on');
w40 = t <= 40;
plot(ax, t(w40), r(w40), '--', 'LineWidth', 1.2, 'Color', [0.3 0.3 0.3], 'DisplayName', 'input r(t) = e^{-0.5t}');
plot(ax, t(w40), y(w40), 'LineWidth', 1.0, 'Color', cols(2,:), 'DisplayName', 'output y(t)');
xlabel(ax, 'Time (s)');  ylabel(ax, 'Amplitude');  legend(ax, 'Location', 'northeast', 'FontSize', 7);
title(ax, '(a) Response to r(t) = e^{-0.5t}', 'FontWeight', 'normal');  style(ax);
ax = nexttile(tl);  hold(ax, 'on');
ts_ = (0:0.005:30)';
plot(ax, ts_, step(G, ts_), 'LineWidth', 1.2, 'Color', cols(1,:), 'DisplayName', 'G(s) alone, \zeta = 0.35');
plot(ax, ts_, step(T, ts_), 'LineWidth', 1.0, 'Color', cols(2,:), 'DisplayName', 'closed loop G/(1+GH)');
yline(ax, 5/6, ':k', 'HandleVisibility', 'off');
xlabel(ax, 'Time (s)');  ylabel(ax, 'Step response');  legend(ax, 'Location', 'northeast', 'FontSize', 7);
title(ax, '(b) Step responses', 'FontWeight', 'normal');  style(ax);
savepng(fig, 'ex2A_exp_step.png', figDir);

% I3/V: Bode and step response
fig = newfig(16, 6.8);  tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
[mn, pn] = bode(Hn, w);
ax = nexttile(tl, 1);  semilogx(ax, w, 20*log10(squeeze(mn)), 'LineWidth', 1.2, 'Color', cols(1,:));
ylabel(ax, 'Magnitude (dB)');  xlim(ax, [1e-2 1e2]);  title(ax, '(a) Bode diagram of I_3(s)/V(s)', 'FontWeight', 'normal');  style(ax);
ax = nexttile(tl, 3);  semilogx(ax, w, squeeze(pn), 'LineWidth', 1.2, 'Color', cols(2,:));
ylabel(ax, 'Phase (deg)');  xlabel(ax, 'Frequency (rad/s)');  xlim(ax, [1e-2 1e2]);  style(ax);
ax = nexttile(tl, 2, [2 1]);  plot(ax, tt(tt <= 200), i3(tt <= 200), 'LineWidth', 1.0, 'Color', cols(1,:));
xlabel(ax, 'Time (s)');  ylabel(ax, 'Capacitor current i_3(t) (A)');
title(ax, '(b) Response to a 1 V step', 'FontWeight', 'normal');  style(ax);
savepng(fig, 'ex2B_bode_step.png', figDir);
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
