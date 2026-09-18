%% LAB2_EX2A_DYNAMICS  Exercise 2A - analysis of dynamic models.
%  UESTCHN4002 Control Engineering, Computer Lab Exercise 2, section 3.
%
%  3.1  eigenvalues, natural frequencies and damping factors of
%       H(s) = (4s+1)/(s^2+3s+5)
%  3.2  define the 2x2 MIMO model and find its DC gain
%  3.3  Bode plot of that MIMO model
%  3.4  build G(s) with zeta = 0.35 and wn = 3.4 rad/s
%  3.5  close the loop of Figure 2: forward path G, feedback path H
%  3.6  closed-loop pole-zero map (with grid) and impulse response
%  3.7  response to r(t) = exp(-0.5t), and the assessment that follows

figDir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(figDir, 'dir'); mkdir(figDir); end

%% ---------------------------------------------------------------- 3.1
fprintf('\n=== 3.1  H(s) = (4s+1)/(s^2+3s+5) ===\n');
H = tf([4 1], [1 3 5]);
H                                                       %#ok<NOPTS>

[wnH, zetaH, pH] = damp(H);
fprintf('\n  %-26s %-14s %-12s\n', 'eigenvalue (pole)', 'wn (rad/s)', 'zeta');
for k = 1:numel(pH)
    fprintf('  %+10.6f %+10.6fi   %-14.6f %-12.6f\n', ...
            real(pH(k)), imag(pH(k)), wnH(k), zetaH(k));
end
fprintf(['\n  check by hand: s^2 + 3s + 5 = s^2 + 2*zeta*wn*s + wn^2\n' ...
         '    wn   = sqrt(5)      = %.6f\n' ...
         '    zeta = 3/(2*sqrt5)  = %.6f   -> underdamped, 0 < zeta < 1\n' ...
         '  the zero at s = -1/4 does not move the poles; it only reweights them.\n'], ...
        sqrt(5), 3/(2*sqrt(5)));

%% ---------------------------------------------------------------- 3.2
fprintf('\n=== 3.2  MIMO model and its DC gain ===\n');
%        [        1         ,   (s-1)/(s^2+s+3)  ]
%        [   1/(s+1)        ,     (s+2)/(s-3)    ]
Hmimo = [ tf(1,1),        tf([1 -1],[1 1 3]) ;
          tf(1,[1 1]),    tf([1  2],[1 -3])   ];
Hmimo                                                   %#ok<NOPTS>

Kdc = dcgain(Hmimo);
fprintf('\nDC gain matrix H(0):\n');
disp(Kdc);
fprintf('by hand: [ 1, -1/3 ; 1, -2/3 ] = [ %g, %g ; %g, %g ]\n', 1, -1/3, 1, -2/3);

fprintf(['\n  WARNING  the (2,2) entry (s+2)/(s-3) has a pole at s = +3.\n' ...
         '  This MIMO model is open-loop UNSTABLE, so its "DC gain" is a formal\n' ...
         '  substitution s = 0, not a steady state the system would ever reach.\n' ...
         '  poles of the whole array: %s\n'], mat2str(round(pole(Hmimo)',4)));

%% ---------------------------------------------------------------- 3.3
fprintf('\n=== 3.3  Bode plot of the MIMO model ===\n');
figure('Name','3.3 MIMO Bode');
bode(Hmimo); grid on;
title('3.3  Bode diagram of the 2x2 MIMO model');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig3_3_mimo_bode.png'), 'Resolution', 200);
fprintf('a 2x2 array of Bode plots: row = output, column = input.\n');

%% ---------------------------------------------------------------- 3.4
fprintf('\n=== 3.4  G(s) with zeta = 0.35, wn = 3.4 rad/s ===\n');
zeta_G = 0.35;  wn_G = 3.4;
G = tf(wn_G^2, [1, 2*zeta_G*wn_G, wn_G^2]);
G                                                       %#ok<NOPTS>
fprintf('  denominator: s^2 + %.4f s + %.4f\n', 2*zeta_G*wn_G, wn_G^2);
[wnG, zetaG] = damp(G);
fprintf('  damp() confirms wn = %.6f, zeta = %.6f\n', wnG(1), zetaG(1));
fprintf('  G(0) = %.6f (unit DC gain, as the standard second-order form gives)\n', dcgain(G));

%% ---------------------------------------------------------------- 3.5
fprintf('\n=== 3.5  closed loop of Figure 2:  T = G/(1 + G*H) ===\n');
T = feedback(G, H);
T                                                       %#ok<NOPTS>
fprintf('\n  numerator  : %s\n', mat2str(round(T.Numerator{1},4)));
fprintf('  denominator: %s\n', mat2str(round(T.Denominator{1},4)));
fprintf(['  by hand, T = G*(s^2+3s+5) / [ (s^2+2.38s+11.56)(s^2+3s+5) + 11.56(4s+1) ]\n' ...
         '            = (11.56 s^2 + 34.68 s + 57.8)\n' ...
         '              / (s^4 + 5.38 s^3 + 23.7 s^2 + 92.82 s + 69.36)\n']);
fprintf('  T(0) = %.10f   (exactly G(0)/(1+G(0)H(0)) = 1/(1+1/5) = 5/6 = %.10f)\n', ...
        dcgain(T), 5/6);

%% ---------------------------------------------------------------- 3.6
fprintf('\n=== 3.6  closed-loop poles and zeros, and the impulse response ===\n');

figure('Name','3.6a pole-zero map');
pzmap(T); grid on; sgrid;
title('3.6  Closed-loop pole-zero map');
xlabel('Real Axis (seconds^{-1})'); ylabel('Imaginary Axis (seconds^{-1})');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig3_6a_pzmap.png'), 'Resolution', 200);

[wnT, zetaT, pT] = damp(T);
fprintf('\n  %-26s %-14s %-12s %-12s\n','closed-loop pole','wn (rad/s)','zeta','1/(zeta*wn)');
for k = 1:numel(pT)
    fprintf('  %+10.6f %+10.6fi   %-14.6f %-12.6f %-12.6f\n', ...
            real(pT(k)), imag(pT(k)), wnT(k), zetaT(k), 1/(zetaT(k)*wnT(k)));
end
fprintf('  closed-loop zeros: %s  (these are exactly the poles of H)\n', ...
        mat2str(round(zero(T)',4)));

[~, idom] = min(abs(real(pT)));                 % slowest-decaying mode dominates
fprintf(['\n  DOMINANT pair: %.6f %+.6fi -> wn = %.6f, zeta = %.6f\n' ...
         '  Closing the loop has dropped the damping from %.3f (the G you designed)\n' ...
         '  to %.4f. That is the single most important number on this page.\n'], ...
        real(pT(idom)), imag(pT(idom)), wnT(idom), zetaT(idom), zeta_G, zetaT(idom));

figure('Name','3.6b impulse response');
impulse(T, 60); grid on;
title('3.6  Closed-loop impulse response');
xlabel('Time (seconds)'); ylabel('Amplitude');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig3_6b_impulse.png'), 'Resolution', 200);

% Step information, for the discussion.
si = stepinfo(T);
tfine = 0:1e-4:80;  yfine = step(T, tfine);
sif = stepinfo(yfine, tfine, dcgain(T), 'SettlingTimeThreshold', 0.02);
fprintf('\n  step response (fine grid, 2%% band):\n');
fprintf('    overshoot      = %.4f %%\n', sif.Overshoot);
fprintf('    settling time  = %.4f s\n', sif.SettlingTime);
fprintf('    peak time      = %.4f s\n', sif.PeakTime);
fprintf('    steady state   = %.6f  (offset %.2f %% from r = 1)\n', ...
        dcgain(T), 100*(1-dcgain(T)));
fprintf('    (stepinfo default sampling would say %.4f %% - it under-samples the peak)\n', ...
        si.Overshoot);

%% ---------------------------------------------------------------- 3.7
fprintf('\n=== 3.7  response to r(t) = exp(-0.5 t) ===\n');
dt = 0.001;              % fine grid: on a 0.01 grid the peak reads 0.7685 at
t  = 0:dt:60;            % t = 0.670 instead of 0.7686 at t = 0.666.
r  = exp(-0.5*t);
y  = lsim(T, r, t);

figure('Name','3.7 response to exponential input');
plot(t, r, '--', 'LineWidth', 1.4); hold on;
plot(t, y, 'LineWidth', 1.8); hold off; grid on;
legend('input  r(t) = e^{-0.5t}', 'output  y(t)', 'Location','northeast');
title('3.7  Response to a decaying exponential input');
xlabel('Time (seconds)'); ylabel('Amplitude');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig3_7_expinput.png'), 'Resolution', 200);

fprintf('  input decays with time constant 2 s; it is down to 1%% by t = %.2f s\n', ...
        log(100)/0.5);
[ymax, imax] = max(abs(y));
fprintf('  |y| peaks at %.6f at t = %.3f s\n', ymax, t(imax));
% Index arithmetic rather than t==20: exact equality on a floating-point grid
% is not reliable.
idx = @(tt) round(tt/dt) + 1;
fprintf('  y at t = 10, 20, 40 s : %.6f, %.6f, %.6f\n', ...
        y(idx(10)), y(idx(20)), y(idx(40)));
fprintf(['  the input is essentially gone after ~10 s, yet y is still ringing:\n' ...
         '  the ringing is the lightly damped closed-loop mode, not the input.\n']);

fprintf(['\n--- assessment asked for in the box after 3.7 ---\n' ...
         'zeta of the dominant pair  = %.4f\n' ...
         'wn   of the dominant pair  = %.4f rad/s\n' ...
         'overshoot                  = %.1f %%\n' ...
         'settling time (2%%)         = %.1f s\n' ...
         'steady-state offset        = %.1f %%\n'], ...
        zetaT(idom), wnT(idom), sif.Overshoot, sif.SettlingTime, 100*(1-dcgain(T)));
