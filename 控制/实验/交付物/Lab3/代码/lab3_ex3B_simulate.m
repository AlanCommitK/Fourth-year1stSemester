%% lab3_ex3B_simulate.m
% Computer Lab Exercise 3, Exercise 3B (Sections 4.2 to 4.6).
% Runs the Simulink models built by lab3_ex3B_build_models.m, measures each
% design, cross-checks every simulated response against the closed-loop
% z-domain transfer function, and writes the figures used in the report.
% Sample time Ts = 1 s; set-point r = 300 m^3/h applied at t = 0.

here   = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
figDir = fullfile(here, '..', 'figures');
load_system(fullfile(here, 'ventilation_P.slx'));
load_system(fullfile(here, 'ventilation_I.slx'));

r = 300;  Ts = 1;  Tlong = 600;  Tplot = 40;
plant0 = {[0 3], [1 -0.6]};                       % Gp numerator / denominator in z^-1
Gz = tf(plant0{1}, plant0{2}, Ts, 'Variable', 'z^-1');
fprintf('Plant DC gain Gp(1) = %.4f (m^3/h per V); voltage needed for 300 m^3/h = %.2f V\n', ...
        dcgain(Gz), r/dcgain(Gz));

%% 4.2  proportional control, Kp = 0.1
S = simP(0.1, Tlong, plant0);
M = metrics(S, r, false);
fprintf('\n4.2  P control, Kp = 0.1\n');
fprintf('  first samples y(0..5) = %s m^3/h\n', mat2str(S.y(1:6).', 5));
fprintf('  first samples u(0..5) = %s V\n', mat2str(S.u(1:6).', 5));
fprintf('  final y = %.3f m^3/h  (steady-state error %.2f %%), final u = %.3f V\n', M.yf, M.ess, M.uf);
fprintf('  analytic: pole z = 0.6-3K = %.2f, y_ss = 300*7.5K/(1+7.5K) = %.3f\n', ...
        0.6-3*0.1, r*7.5*0.1/(1+7.5*0.1));
fprintf('  max |y_Simulink - y_tf| = %.2e\n', S.err);

%% 4.3  proportional gain by trial and error
Kset = [0.02 0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.53 0.55];
fprintf('\n4.3  P gain sweep (Simulink, %d s horizon)\n', Tlong);
fprintf('   Kp    pole    y_final  y_ss(an)  e_ss%%   OS%%    t90(s)  ts2%%(s)  u(0)(V)  u_final(V)  stable\n');
P = struct([]);
for K = Kset
    S = simP(K, Tlong, plant0);   M = metrics(S, r, false);
    P(end+1).K = K; P(end).S = S; P(end).M = M; %#ok<SAGROW>
    fprintf('  %5.2f  %6.2f  %8.2f  %8.2f  %6.2f  %6.2f  %6g  %7g  %7.1f  %9.2f    %d   (|dy|=%.1e)\n', ...
        K, 0.6-3*K, M.yf, r*7.5*K/(1+7.5*K), M.ess, M.OS, M.t90, M.ts, M.u0, M.uf, M.stable, S.err);
end
fprintf('  stability limit |0.6-3K|<1  ->  K < %.4f ;  deadbeat (pole at 0) at K = 0.2\n', 1.6/3);

%% 4.4 / 4.5  integral control
kIstar = (1.6 - sqrt(2.4))/3;          % double real pole of z^2-(1.6-3kI)z+0.6
fprintf('\n4.5  analytic: characteristic polynomial z^2 - (1.6-3kI) z + 0.6\n');
fprintf('     real (non-oscillatory) poles for kI <= %.6f ; stable for 0 < kI < %.4f\n', kIstar, 3.2/3);
kIset = [0.005 0.01 0.015 kIstar 0.018 0.02 0.025 0.03 0.05 0.1 0.2 0.3 0.5 1.0 1.1];
fprintf('\n4.5  I gain sweep (Simulink)\n');
fprintf('    kI       poles                 |z|    OS%%      t90(s) ts2%%(s) u_peak(V) E60/E_hold  stable\n');
I = struct([]);
for kI = kIset
    S = simC(kI, [1 -1], Tlong, plant0);   M = metrics(S, r, true);
    p = roots([1 -(1.6-3*kI) 0.6]);
    I(end+1).kI = kI; I(end).S = S; I(end).M = M; %#ok<SAGROW>
    fprintf('  %7.4f  %-22s  %5.3f  %8.4f  %6g  %6g  %8.2f  %8.3f   %d  (|dy|=%.1e)\n', ...
        kI, num2str(p.', '%.3f '), max(abs(p)), M.OS, M.t90, M.ts, M.upk, M.E60/(40^2*60), M.stable, S.err);
end

% dense overshoot curve from the transfer-function route (independent of Simulink)
kIfine = unique([logspace(log10(0.002), log10(1.0), 400) kIstar]);
OSfine = zeros(size(kIfine));
tl = (0:Tlong)';
for i = 1:numel(kIfine)
    T = feedback(tf(kIfine(i), [1 -1], Ts, 'Variable', 'z^-1')*Gz, 1);
    yv = r*step(T, tl);
    OSfine(i) = max(0, 100*(max(yv) - r)/r);
end
fprintf('\n  overshoot (TF route): kI = 0.0169 -> %.2e %%, 0.018 -> %.2e %%, 0.02 -> %.3f %%, 0.025 -> %.3f %%, 0.03 -> %.3f %%\n', ...
    interp1(kIfine, OSfine, kIstar), interp1(kIfine, OSfine, 0.018), interp1(kIfine, OSfine, 0.02), ...
    interp1(kIfine, OSfine, 0.025), interp1(kIfine, OSfine, 0.03));
k1 = kIfine(find(OSfine > 1, 1));  k5 = kIfine(find(OSfine > 5, 1));
fprintf('  overshoot first exceeds 1 %% at kI = %.4f and 5 %% at kI = %.4f\n', k1, k5);

%% 4.6  integral (kI = 0.1) versus proportional (Kp = 0.1)
Sp = simP(0.1, Tlong, plant0);              Mp = metrics(Sp, r, false);
Si = simC(0.1, [1 -1], Tlong, plant0);      Mi = metrics(Si, r, true);
fprintf('\n4.6  Kp = 0.1: y_final %.1f, OS %.1f %%, t90 %g s, ts %g s, u(0) %.1f V, u_peak %.1f V\n', ...
        Mp.yf, Mp.OS, Mp.t90, Mp.ts, Mp.u0, Mp.upk);
fprintf('     kI = 0.1: y_final %.1f, OS %.1f %%, t90 %g s, ts %g s, u(0) %.1f V, u_peak %.1f V\n', ...
        Mi.yf, Mi.OS, Mi.t90, Mi.ts, Mi.u0, Mi.upk);

%% candidate designs and robustness to plant uncertainty
% PI extension: zero of Kp + kI/(1-z^-1) placed on the plant pole (Kp = 1.5 kI),
% leaving a first-order loop with pole 1 - 7.5 kI; kI = 1/15 puts it at z = 0.5.
kIpi = 1/15;  Kppi = 1.5*kIpi;
cand = { 'P,  Kp = 0.2 (deadbeat)',          'P',  0.2,             1;
         'I,  kI = 0.1 (handout)',           'C',  0.1,             [1 -1];
         'I,  kI = 0.0169 (real-pole limit)','C',  kIstar,          [1 -1];
         'I,  kI = 0.015',                   'C',  0.015,           [1 -1];
         'PI, Kp = 0.1, kI = 0.0667',        'C',  [Kppi+kIpi -Kppi], [1 -1] };
fprintf('\nCandidates, nominal plant:\n');
fprintf('  %-34s y_final  e_ss%%   OS%%    t90  ts2%%  u(0)  u_peak  E60/E_hold  V60/V_ideal\n', 'design');
C = struct([]);
for c = 1:size(cand, 1)
    if cand{c,2} == 'P', S = simP(cand{c,3}, Tlong, plant0); M = metrics(S, r, false);
    else, S = simC(cand{c,3}, cand{c,4}, Tlong, plant0); M = metrics(S, r, true); end
    C(c).name = cand{c,1}; C(c).S = S; C(c).M = M; %#ok<SAGROW>
    fprintf('  %-34s %7.1f  %5.1f  %6.2f  %4g  %4g  %5.1f  %6.1f   %6.3f      %6.3f\n', ...
        cand{c,1}, M.yf, M.ess, M.OS, M.t90, M.ts, M.u0, M.upk, M.E60/(40^2*60), M.V60);
end

fprintf('\nRobustness: plant gain b in {2.4, 3, 3.6} (+-20 %%), plant pole a in {0.5, 0.6, 0.7}\n');
bset = [2.4 3 3.6];  aset = [0.5 0.6 0.7];
for c = 2:size(cand, 1)
    OS = []; ts = []; st = true;
    for b = bset
        for a = aset
            S = simC(cand{c,3}, cand{c,4}, Tlong, {[0 b], [1 -a]});  M = metrics(S, r, true);
            OS(end+1) = M.OS; ts(end+1) = M.ts; st = st && M.stable; %#ok<SAGROW>
        end
    end
    fprintf('  %-34s OS max %6.2f %% (worst b,a idx %d), ts %g..%g s, all stable %d\n', ...
        cand{c,1}, max(OS), find(OS == max(OS), 1), min(ts), max(ts), st);
end

%% figures
cols = lines(6);
% Fig 1: P gain sweep (4.2-4.3)
fig = newfig(16, 11);  tl2 = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
show = [0.05 0.1 0.2 0.3 0.5];
ax1 = nexttile(tl2); hold(ax1, 'on');  ax2 = nexttile(tl2); hold(ax2, 'on');
for i = 1:numel(show)
    j = find(abs([P.K] - show(i)) < 1e-12);  S = P(j).S;  w = S.t <= Tplot;
    lw = 1.1 + 0.8*(show(i) == 0.1);
    stairs(ax1, S.t(w), S.y(w), 'LineWidth', lw, 'Color', cols(i,:), 'DisplayName', sprintf('K_p = %.2f', show(i)));
    stairs(ax2, S.t(w), S.u(w), 'LineWidth', lw, 'Color', cols(i,:), 'DisplayName', sprintf('K_p = %.2f', show(i)));
end
yline(ax1, r, '--k', 'Set-point 300 m^3/h', 'LabelHorizontalAlignment', 'right', ...
      'LabelVerticalAlignment', 'top', 'FontSize', 8, 'HandleVisibility', 'off');
ylabel(ax1, 'Ventilation rate y (m^3/h)');  legend(ax1, 'Location', 'eastoutside');
ylabel(ax2, 'Fan voltage u (V)');  xlabel(ax2, 'Time (s)');  legend(ax2, 'Location', 'eastoutside');
title(ax1, 'Proportional control: effect of K_p (Simulink, T_s = 1 s)', 'FontWeight', 'normal');
style(ax1); style(ax2); xlim(ax1, [0 Tplot]); xlim(ax2, [0 Tplot]); ylim(ax1, [0 450]);
savepng(fig, 'ex3B_P_sweep.png', figDir);

% Fig 2: integral kI = 0.1 versus proportional Kp = 0.1 (4.4-4.6)
fig = newfig(16, 10);  tl2 = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile(tl2); hold(ax1, 'on');  ax2 = nexttile(tl2); hold(ax2, 'on');
w = Sp.t <= Tplot;
stairs(ax1, Sp.t(w), Sp.y(w), 'LineWidth', 1.4, 'Color', cols(1,:), 'DisplayName', 'P, K_p = 0.1');
stairs(ax1, Si.t(w), Si.y(w), 'LineWidth', 1.4, 'Color', cols(2,:), 'DisplayName', 'I, k_I = 0.1');
stairs(ax2, Sp.t(w), Sp.u(w), 'LineWidth', 1.4, 'Color', cols(1,:), 'DisplayName', 'P, K_p = 0.1');
stairs(ax2, Si.t(w), Si.u(w), 'LineWidth', 1.4, 'Color', cols(2,:), 'DisplayName', 'I, k_I = 0.1');
yline(ax1, r, '--k', 'HandleVisibility', 'off');  yline(ax2, 40, ':k', '40 V holds 300 m^3/h', ...
      'LabelHorizontalAlignment', 'right', 'FontSize', 8, 'HandleVisibility', 'off');
ylabel(ax1, 'Ventilation rate y (m^3/h)');  ylabel(ax2, 'Fan voltage u (V)');  xlabel(ax2, 'Time (s)');
legend(ax1, 'Location', 'southeast');  legend(ax2, 'Location', 'northeast');
title(ax1, 'Integral versus proportional control, equal gain 0.1', 'FontWeight', 'normal');
style(ax1); style(ax2); xlim(ax1, [0 Tplot]); xlim(ax2, [0 Tplot]);
savepng(fig, 'ex3B_I_vs_P.png', figDir);

% Fig 3: integral gain sweep (4.5)
fig = newfig(16, 11);  tl2 = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
show = [0.005 kIstar 0.03 0.1 0.3];  lab = {'0.005', '0.0169', '0.03', '0.1', '0.3'};
ax1 = nexttile(tl2); hold(ax1, 'on');  ax2 = nexttile(tl2); hold(ax2, 'on');
for i = 1:numel(show)
    j = find(abs([I.kI] - show(i)) < 1e-12);  S = I(j).S;  w = S.t <= 60;
    lw = 1.1 + 0.8*(i == 2);
    stairs(ax1, S.t(w), S.y(w), 'LineWidth', lw, 'Color', cols(i,:), 'DisplayName', ['k_I = ' lab{i}]);
    stairs(ax2, S.t(w), S.u(w), 'LineWidth', lw, 'Color', cols(i,:), 'DisplayName', ['k_I = ' lab{i}]);
end
yline(ax1, r, '--k', 'HandleVisibility', 'off');  yline(ax2, 40, ':k', 'HandleVisibility', 'off');
ylabel(ax1, 'Ventilation rate y (m^3/h)');  ylabel(ax2, 'Fan voltage u (V)');  xlabel(ax2, 'Time (s)');
legend(ax1, 'Location', 'eastoutside');  legend(ax2, 'Location', 'eastoutside');
title(ax1, 'Integral control: effect of k_I (Simulink)', 'FontWeight', 'normal');
style(ax1); style(ax2); xlim(ax1, [0 60]); xlim(ax2, [0 60]);
savepng(fig, 'ex3B_I_sweep.png', figDir);

% Fig 4: closed-loop poles versus kI, and overshoot versus kI
fig = newfig(16, 7.2);  tl2 = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile(tl2); hold(ax1, 'on');
th = linspace(0, 2*pi, 400);
plot(ax1, cos(th), sin(th), 'k-', 'LineWidth', 0.6, 'HandleVisibility', 'off');
plot(ax1, sqrt(0.6)*cos(th), sqrt(0.6)*sin(th), ':', 'Color', [0.4 0.4 0.4], 'HandleVisibility', 'off');
kl = linspace(0, 1.2, 3000);  pl = zeros(2, numel(kl));
for i = 1:numel(kl), pl(:, i) = roots([1 -(1.6-3*kl(i)) 0.6]); end
plot(ax1, real(pl(:)), imag(pl(:)), '.', 'MarkerSize', 3, 'Color', cols(1,:), 'HandleVisibility', 'off');
plot(ax1, [1 0.6], [0 0], 'kx', 'MarkerSize', 8, 'LineWidth', 1.2, 'HandleVisibility', 'off');
mk = {kIstar, 'k_I = 0.0169'; 0.1, 'k_I = 0.1'; 3.2/3, 'k_I = 1.067'};
mc = [cols(2,:); cols(3,:); cols(4,:)];
for i = 1:3
    p = roots([1 -(1.6-3*mk{i,1}) 0.6]);
    plot(ax1, real(p), imag(p), 'o', 'MarkerSize', 6, 'LineWidth', 1.2, 'Color', mc(i,:), 'DisplayName', mk{i,2});
end
axis(ax1, 'equal');  xlim(ax1, [-1.15 1.15]);  ylim(ax1, [-1.15 1.15]);
xlabel(ax1, 'Re(z)');  ylabel(ax1, 'Im(z)');  legend(ax1, 'Location', 'southwest', 'FontSize', 7);
title(ax1, '(a) Closed-loop poles, 0 < k_I < 1.2', 'FontWeight', 'normal');
text(ax1, -0.05, 0.86, '|z| = 0.775', 'FontSize', 7, 'Color', [0.3 0.3 0.3]);
style(ax1);
ax2 = nexttile(tl2);
semilogx(ax2, kIfine, OSfine, '-', 'LineWidth', 1.3, 'Color', cols(1,:), 'DisplayName', 'TF route'); hold(ax2, 'on');
semilogx(ax2, [I.kI], arrayfun(@(s) s.M.OS, I), 'o', 'MarkerSize', 4, 'Color', cols(2,:), 'DisplayName', 'Simulink runs');
xline(ax2, kIstar, '--k', 'k_I = 0.0169', 'FontSize', 7, 'LabelVerticalAlignment', 'middle', 'HandleVisibility', 'off');
xlabel(ax2, 'Integral gain k_I');  ylabel(ax2, 'Overshoot (%)');  xlim(ax2, [0.003 0.5]);  ylim(ax2, [0 70]);
legend(ax2, 'Location', 'northwest', 'FontSize', 7);
title(ax2, '(b) Overshoot of the step response', 'FontWeight', 'normal');
style(ax2);
savepng(fig, 'ex3B_I_poles_overshoot.png', figDir);

% Fig 5: candidate designs
fig = newfig(16, 11);  tl2 = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile(tl2); hold(ax1, 'on');  ax2 = nexttile(tl2); hold(ax2, 'on');
pick = [1 2 3 5];
for i = 1:numel(pick)
    S = C(pick(i)).S;  w = S.t <= Tplot;
    nm = strrep(strrep(C(pick(i)).name, 'Kp', 'K_p'), 'kI', 'k_I');
    stairs(ax1, S.t(w), S.y(w), 'LineWidth', 1.3, 'Color', cols(i,:), 'DisplayName', nm);
    stairs(ax2, S.t(w), S.u(w), 'LineWidth', 1.3, 'Color', cols(i,:), 'DisplayName', nm);
end
yline(ax1, r, '--k', 'HandleVisibility', 'off');  yline(ax2, 40, ':k', 'HandleVisibility', 'off');
ylabel(ax1, 'Ventilation rate y (m^3/h)');  ylabel(ax2, 'Fan voltage u (V)');  xlabel(ax2, 'Time (s)');
legend(ax1, 'Location', 'southeast', 'FontSize', 7);
title(ax1, 'Candidate controllers (Simulink, nominal plant)', 'FontWeight', 'normal');
style(ax1); style(ax2); xlim(ax1, [0 Tplot]); xlim(ax2, [0 Tplot]); ylim(ax2, [0 70]);
savepng(fig, 'ex3B_candidates.png', figDir);

fprintf('\nFigures written to %s\n', figDir);

%% ================================================================ helpers
function S = simP(K, Tstop, plant)
mdl = 'ventilation_P';
in = Simulink.SimulationInput(mdl);
in = in.setBlockParameter([mdl '/P controller'], 'Gain', num2str(K, 17));
in = in.setBlockParameter([mdl '/Fan and chamber Gp'], 'Numerator', mat2str(plant{1}, 17));
in = in.setBlockParameter([mdl '/Fan and chamber Gp'], 'Denominator', mat2str(plant{2}, 17));
in = in.setModelParameter('StopTime', num2str(Tstop));
S = collect(sim(in), tf(K, 1, 1, 'Variable', 'z^-1'), plant);
end

function S = simC(num, den, Tstop, plant)
mdl = 'ventilation_I';
in = Simulink.SimulationInput(mdl);
in = in.setBlockParameter([mdl '/I controller'], 'Numerator', mat2str(num, 17));
in = in.setBlockParameter([mdl '/I controller'], 'Denominator', mat2str(den, 17));
in = in.setBlockParameter([mdl '/Fan and chamber Gp'], 'Numerator', mat2str(plant{1}, 17));
in = in.setBlockParameter([mdl '/Fan and chamber Gp'], 'Denominator', mat2str(plant{2}, 17));
in = in.setModelParameter('StopTime', num2str(Tstop));
S = collect(sim(in), tf(num, den, 1, 'Variable', 'z^-1'), plant);
end

function S = collect(out, Cz, plant)
% logged signals, plus the deviation from the transfer-function prediction
S.t = out.y.Time(:);  S.y = squeeze(out.y.Data);  S.u = squeeze(out.u.Data);
G = tf(plant{1}, plant{2}, 1, 'Variable', 'z^-1');
yt = 300*step(feedback(Cz*G, 1), S.t);  ut = 300*step(feedback(Cz, G), S.t);
ok = isfinite(S.y) & abs(S.y) < 1e6;
S.err = max([abs(S.y(ok) - yt(ok)); abs(S.u(ok) - ut(ok))]);
end

function M = metrics(S, r, toSetpoint)
t = S.t;  y = S.y;  u = S.u;  n = numel(y);
tail = y(n-20:n);  head = y(1:21);
M.stable = all(isfinite(y)) && (max(tail) - min(tail)) <= (max(head) - min(head));
M.yf = y(end);  M.uf = u(end);  M.u0 = u(1);  M.upk = max(u);
M.ess = 100*(r - M.yf)/r;
ref = M.yf;  if toSetpoint, ref = r; end
M.OS = max(0, 100*(max(y) - ref)/ref);
M.t90 = t(find(y >= 0.9*ref, 1));
o = find(abs(y - ref) > 0.02*ref, 1, 'last');
if isempty(o), M.ts = t(1); elseif o < n, M.ts = t(o+1); else, M.ts = NaN; end
M.E60 = sum(u(t < 60).^2);                     % sum of u^2 over the first 60 s (Ts = 1 s)
M.V60 = sum(y(t < 60))/(r*60);                 % air delivered in 60 s / ideal 300 m^3/h x 60 s
if ~M.stable, [M.OS, M.t90, M.ts] = deal(NaN); end
if isempty(M.t90), M.t90 = NaN; end
end

function fig = newfig(w, h)
fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [2 2 w h]);
theme(fig, 'light');                % independent of the desktop colour theme
set(fig, 'Color', 'w');
end

function style(ax)
set(ax, 'FontName', 'Helvetica', 'FontSize', 9, 'LineWidth', 0.6, 'Box', 'on');
grid(ax, 'on');  ax.GridAlpha = 0.15;  ax.MinorGridAlpha = 0.08;
end

function savepng(fig, name, figDir)
exportgraphics(fig, fullfile(figDir, name), 'Resolution', 300);
close(fig);
end
