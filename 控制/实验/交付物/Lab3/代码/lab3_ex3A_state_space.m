%% lab3_ex3A_state_space.m
% Computer Lab Exercise 3: Exercise 3A (Section 2.0) and Section 3.0.
% State-space realisations of G(s) = (s+2)(s+4)/((s+1)(s+3)(s+5)), checks of
% each against the transfer function, and pole placement for the system of
% Section 3.0. Requires the Control System and Symbolic Math Toolboxes.

here   = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
figDir = fullfile(here, '..', 'figures');

num = conv([1 2], [1 4]);                    % s^2 + 6s + 8
den = conv(conv([1 1], [1 3]), [1 5]);       % s^3 + 9s^2 + 23s + 15
G   = tf(num, den);
fprintf('G(s) = (%s) / (%s)\n', strtrim(poly2str(num, 's')), strtrim(poly2str(den, 's')));

%% 2.1 / 2.2  phase-variable form obtained by hand, entered as A, B, C, D
A1 = [0 1 0; 0 0 1; -den(4) -den(3) -den(2)];
B1 = [0; 0; 1];  C1 = [num(3) num(2) num(1)];  D1 = 0;
sys_pv_manual = ss(A1, B1, C1, D1);
show('2.2  phase-variable form (manual, 2.1)', A1, B1, C1, D1);

%% 2.3  controller canonical form from MATLAB
[Ac, Bc, Cc, Dc] = tf2ss(num, den);
sys_cc = ss(Ac, Bc, Cc, Dc);
show('2.3  controller canonical form, tf2ss', Ac, Bc, Cc, Dc);

%% 2.4  phase-variable form by the similarity transformation P
P  = [0 0 1; 0 1 0; 1 0 0];
Ap = inv(P)*Ac*P;  Bp = inv(P)*Bc;  Cp = Cc*P;  Dp = Dc;
show('2.4  phase-variable form, inv(P)*A*P', Ap, Bp, Cp, Dp);
fprintf('     identical to the manual result of 2.1: %d\n', ...
        isequal(Ap, A1) && isequal(Bp, B1) && isequal(Cp, C1) && Dp == D1);

%% 2.5  parallel (modal) form
[sys_par, Tpar] = canon(sys_cc, 'modal');
[Apar, Bpar, Cpar, Dpar] = ssdata(sys_par);
show('2.5  parallel form, canon(sys_cc,''modal'')', Apar, Bpar, Cpar, Dpar);
[res, pol] = residue(num, den);
fprintf('     partial fractions: residues %s at poles %s\n', mat2str(res.', 6), mat2str(pol.', 6));
fprintf('     products B_i*C_i of the MATLAB form: %s (must equal the residues)\n', ...
        mat2str((Bpar.*Cpar.').', 6));

%% 2.6 / 2.7  observer canonical form (dual of the controller canonical form)
Ao = Ac.';  Bo = Cc.';  Co = Bc.';  Do = Dc;
show('2.6  observer canonical form, transpose of 2.3', Ao, Bo, Co, Do);
A7 = [-den(2) 1 0; -den(3) 0 1; -den(4) 0 0];  B7 = [num(1); num(2); num(3)];  C7 = [1 0 0];
fprintf('     identical to the manual result of 2.7: %d\n', isequal(Ao, A7) && isequal(Bo, B7) && isequal(Co, C7));

%% verification: every realisation must reproduce G(s)
forms = {'phase-variable (manual)', sys_pv_manual; 'controller canonical', sys_cc; ...
         'phase-variable (P)', ss(Ap, Bp, Cp, Dp); 'parallel (modal)', sys_par; ...
         'observer canonical', ss(Ao, Bo, Co, Do)};
fprintf('\nVerification against G(s):\n');
fprintf('  %-24s  max|coef error|  rank ctrb  rank obsv  max eigenvalue condition no.\n', 'form');
t = linspace(0, 6, 601)';  yG = step(G, t);
for i = 1:size(forms, 1)
    s_ = forms{i, 2};
    [n_, d_] = tfdata(tf(s_), 'v');
    e_ = max(abs([n_(end-2:end) - num, d_ - den]));
    fprintf('  %-24s  %13.1e  %9d  %9d  %8.3f   (step dev %.1e)\n', forms{i, 1}, e_, ...
        rank(ctrb(s_.A, s_.B)), rank(obsv(s_.A, s_.C)), max(condeig(s_.A)), max(abs(step(s_, t) - yG)));
end

%% Section 3.0: state space to transfer function and pole placement
A = [0 1 0; 0 0 1; -1 -2 -3];  B = [10; 0; 0];  C = [1 0 0];  D = 0;
sys3 = ss(A, B, C, D);                                       % 3.1
G3 = tf(sys3);                                               % 3.2
[n3, d3] = tfdata(G3, 'v');
fprintf('\n3.2  Y(s)/U(s) = (%s) / (%s)\n', strtrim(poly2str(round(n3, 10), 's')), strtrim(poly2str(d3, 's')));
fprintf('     zeros %s, poles %s\n', mat2str(zero(G3).', 5), mat2str(pole(G3).', 5));
fprintf('     rank of controllability matrix = %d\n', rank(ctrb(A, B)));

pdes = [-2+4j, -2-4j, -10];                                  % 3.3
K  = place(A, B, pdes);
Ka = acker(A, B, pdes);
fprintf('\n3.3  desired polynomial: %s\n', strtrim(poly2str(real(poly(pdes)), 's')));
fprintf('     K (place) = %s\n', mat2str(K, 8));
fprintf('     K (acker) = %s\n', mat2str(Ka, 8));
fprintf('     eig(A - B*K) = %s\n', mat2str(eig(A - B*K).', 6));

% independent check by coefficient matching (symbolic)
syms k1 k2 k3 s
cp  = collect(det(s*eye(3) - (A - B*[k1 k2 k3])), s);
eqs = coeffs(cp - expand((s + 10)*(s^2 + 4*s + 20)), s);
sol = solve(eqs == 0, [k1 k2 k3]);
fprintf('     det(sI - (A - BK)) = %s\n', char(cp));
fprintf('     coefficient matching: k1 = %s, k2 = %s, k3 = %s\n', char(sol.k1), char(sol.k2), char(sol.k3));

% the same design in phase-variable coordinates z, with x = T z
[Acz, Bcz, Ccz, Dcz] = tf2ss(n3(end-2:end), d3);
Az = P*Acz*P;  Bz = P*Bcz;  Cz = Ccz*P;
Kz = place(Az, Bz, pdes);
T  = ctrb(A, B)/ctrb(Az, Bz);
fprintf('     phase-variable form: Az = %s, Bz = %s, Cz = %s\n', mat2str(Az), mat2str(Bz.'), mat2str(round(Cz, 10)));
fprintf('     Kz = %s (= desired minus open-loop coefficients, reversed)\n', mat2str(Kz, 8));
fprintf('     Kz*inv(T) = %s (equals K)\n', mat2str(Kz/T, 8));

% closed-loop check: poles and normalised step responses
N   = -1/(C/(A - B*K)*B);                                    % reference gain for unit DC gain
scl = ss(A - B*K, B*N, C, D);
fprintf('     reference gain N = %.6f; closed-loop DC gain = %.6f\n', N, dcgain(scl));
S1 = stepinfo(G3/dcgain(G3));  S2 = stepinfo(scl);
fprintf('     open loop (normalised): ts = %.2f s, OS = %.2f %%;  closed loop: ts = %.3f s, OS = %.2f %%\n', ...
        S1.SettlingTime, S1.Overshoot, S2.SettlingTime, S2.Overshoot);

%% figures
cols = lines(6);
fig = newfig(16, 7);  ax = axes(fig);  hold(ax, 'on');
sty = {'-', '--', ':', '-.', '--'};  mk = {'none', 'none', 'o', 'none', 's'};
plot(ax, t, yG, 'k-', 'LineWidth', 3, 'Color', [0.8 0.8 0.8], 'DisplayName', 'transfer function G(s)');
for i = 1:size(forms, 1)
    plot(ax, t, step(forms{i, 2}, t), sty{i}, 'LineWidth', 1.2, 'Color', cols(i, :), ...
         'Marker', mk{i}, 'MarkerIndices', 1:60:numel(t), 'MarkerSize', 4, 'DisplayName', forms{i, 1});
end
xlabel(ax, 'Time (s)');  ylabel(ax, 'Step response c(t)');  legend(ax, 'Location', 'southeast');
title(ax, 'Step responses of the five realisations of G(s)', 'FontWeight', 'normal');  style(ax);
savepng(fig, 'ex3A_realisations_step.png', figDir);

fig = newfig(16, 6.5);  tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile(tl);  hold(ax, 'on');
po = pole(G3);  pc = eig(A - B*K);
plot(ax, real(po), imag(po), 'x', 'MarkerSize', 9, 'LineWidth', 1.5, 'Color', cols(1, :), 'DisplayName', 'open-loop poles');
plot(ax, real(pc), imag(pc), 'o', 'MarkerSize', 7, 'LineWidth', 1.5, 'Color', cols(2, :), 'DisplayName', 'closed-loop poles');
plot(ax, [-1 -2], [0 0], 's', 'MarkerSize', 6, 'LineWidth', 1.2, 'Color', [0.3 0.3 0.3], 'DisplayName', 'zeros (unchanged)');
xline(ax, 0, 'k-', 'HandleVisibility', 'off');  yline(ax, 0, 'k-', 'HandleVisibility', 'off');
xlim(ax, [-11 1]);  ylim(ax, [-5 5]);  xlabel(ax, 'Real axis (s^{-1})');  ylabel(ax, 'Imaginary axis (s^{-1})');
legend(ax, 'Location', 'southwest', 'FontSize', 7);  title(ax, '(a) Pole locations', 'FontWeight', 'normal');  style(ax);
ax = nexttile(tl);  hold(ax, 'on');
t2 = linspace(0, 15, 1501)';
plot(ax, t2, step(G3/dcgain(G3), t2), 'LineWidth', 1.3, 'Color', cols(1, :), 'DisplayName', 'open loop (normalised)');
plot(ax, t2, step(scl, t2), 'LineWidth', 1.3, 'Color', cols(2, :), 'DisplayName', 'state feedback, u = -Kx + Nr');
xlabel(ax, 'Time (s)');  ylabel(ax, 'Normalised output');  legend(ax, 'Location', 'southeast', 'FontSize', 7);
title(ax, '(b) Step responses', 'FontWeight', 'normal');  style(ax);
savepng(fig, 'ex3_3_pole_placement.png', figDir);
fprintf('\nFigures written to %s\n', figDir);

%% ================================================================ helpers
function show(name, A, B, C, D)
fprintf('\n%s\n', name);
fprintf('  A = %s\n  B = %s\n  C = %s\n  D = %s\n', mat2str(A, 6), mat2str(B, 6), mat2str(C, 6), mat2str(D, 6));
end

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
