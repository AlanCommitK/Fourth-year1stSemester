%% LAB2_S2_FREQ  Section 2 - Bode diagrams, Nyquist and Nichols plots.
%  UESTCHN4002 Control Engineering, Computer Lab Exercise 2, section 2.
%
%  2.1  G(s) = (s+1)(s+2)/[s(s+3)(s+4)]
%       (a) Bode log-magnitude and phase
%       (b) Nyquist plot
%       (c) real-axis crossings
%       (d) Nichols chart with grid
%  2.2  unity feedback, G(s) = K(s-1)(s-2)/(s^2+4s+16)
%       (a) Bode log-magnitude and phase
%       (b) Nyquist plot, gain and phase margins and their frequencies
%
%  NOTE  Both plants are the two systems from Computer Lab Exercise 1,
%        section 5 - the same G1 and G2, now examined in the frequency
%        domain instead of on the root locus.

figDir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(figDir, 'dir'); mkdir(figDir); end

%% ================================================================ 2.1
fprintf('\n=== 2.1  G(s) = (s+1)(s+2)/[s(s+3)(s+4)] ===\n');

G1 = tf(conv([1 1],[1 2]), conv([1 0], conv([1 3],[1 4])));
G1                                                      %#ok<NOPTS>
fprintf('open-loop zeros : %s\n', mat2str(zero(G1)'));
fprintf('open-loop poles : %s\n', mat2str(pole(G1)'));
fprintf('one pole at the origin -> type 1 -> |G| rises like 1/w as w -> 0\n');

% ---- (a) Bode -----------------------------------------------------------
figure('Name','2.1a Bode of G1');
bode(G1); grid on;
title('2.1(a)  Bode diagram of (s+1)(s+2)/[s(s+3)(s+4)]');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig2_1a_bode.png'), 'Resolution', 200);

% Corner frequencies, printed so they can be checked against the asymptotes.
fprintf('\ncorner frequencies (rad/s): zeros at 1 and 2, poles at 3 and 4\n');
w_check = [0.1 1 2 3 4 10 100];
fprintf('  %8s  %12s  %12s\n','w','|G| (dB)','phase (deg)');
for w = w_check
    g = evalfr(G1, 1j*w);
    fprintf('  %8g  %12.4f  %12.4f\n', w, 20*log10(abs(g)), rad2deg(angle(g)));
end

% ---- (b) Nyquist --------------------------------------------------------
% MATLAB's default view is useless here: the integrator sends the w -> 0 end to
% infinity, so autoscaling picks a range around 1e19 and the whole interesting
% arc collapses onto the origin. Plot the curve by hand over a sensible window.
wN  = logspace(-2, 4, 4000);
gN  = squeeze(freqresp(G1, wN));
figure('Name','2.1b Nyquist of G1');
plot(real(gN), imag(gN), 'LineWidth', 1.8); hold on;
plot(real(gN), -imag(gN), '--', 'LineWidth', 1.0);      % the w < 0 mirror image
plot(0, 0, 'k.', 'MarkerSize', 12);
% mark the point of least phase lag
wq   = fzero(@(x) 1./(1+x.^2) + 2./(4+x.^2) - 3./(9+x.^2) - 4./(16+x.^2), [0.5 10]);
gq   = evalfr(G1, 1j*wq);
plot(real(gq), imag(gq), 'o', 'MarkerSize', 8, 'LineWidth', 1.6);
text(real(gq)-0.012, imag(gq)-0.022, ...
     sprintf('\\omega = %.3f, \\angleG = %.2f\\circ', wq, rad2deg(angle(gq))), ...
     'FontSize', 9, 'HorizontalAlignment','right');
text(real(gq)-0.012, imag(gq)-0.046, '(least phase lag on the whole curve)', ...
     'FontSize', 8.5, 'HorizontalAlignment','right');
text(11/72+0.012, -0.012, sprintf('Re \\rightarrow 11/72 = %.4f  as \\omega \\rightarrow 0^+', 11/72), ...
     'FontSize', 9);
% The critical point -1 is far outside this window - say so rather than draw a
% legend entry for a marker nobody can see.
text(0.04, -0.305, 'critical point -1 lies far off to the LEFT, outside this window', ...
     'FontSize', 9, 'Color', [.7 .1 .1]);
hold off; grid on; axis equal;
xlim([-0.06 0.32]); ylim([-0.34 0.22]);
title({'2.1(b)  Nyquist plot of (s+1)(s+2)/[s(s+3)(s+4)]', ...
       'the \omega > 0 branch never leaves the fourth quadrant'});
xlabel('Real Axis'); ylabel('Imaginary Axis');
legend('\omega > 0','\omega < 0 (mirror)','Location','northwest');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig2_1b_nyquist.png'), 'Resolution', 200);
fprintf('\n(the w -> 0 end runs off to -j*infinity; the plot window is clipped to\n');
fprintf(' show the arc. The critical point -1 is nowhere near the curve.)\n');

% ---- (c) real-axis crossings -------------------------------------------
% The handout asks for these to be found by CLICKING on the Nyquist plot.
% Clicking is not reproducible in a script, so the same question is answered
% by sweeping the frequency and looking for a sign change in Im{G(jw)}.
fprintf('\n--- 2.1(c) real-axis crossings ---\n');
w  = logspace(-4, 5, 200001);
gr = squeeze(freqresp(G1, w));
fprintf('min Im{G(jw)} = %.6g   max Im{G(jw)} = %.6g\n', min(imag(gr)), max(imag(gr)));
fprintf('number of sign changes in Im{G(jw)} : %d\n', sum(diff(sign(imag(gr))) ~= 0));
fprintf('min Re{G(jw)} = %.6g   max Re{G(jw)} = %.6g\n', min(real(gr)), max(real(gr)));
ph = rad2deg(unwrap(angle(gr)));
fprintf('phase stays inside [%.4f, %.4f] deg\n', min(ph), max(ph));
fprintf(['\nIm{G(jw)} = -(w^4 + 7w^2 + 24) / [w(w^4 + 25w^2 + 144)].\n' ...
         'The quartic w^4 + 7w^2 + 24 has discriminant 49 - 96 < 0 in w^2, so it\n' ...
         'has NO real root and Im{G(jw)} < 0 for every w > 0.\n' ...
         '=> the Nyquist plot lies strictly in the fourth quadrant and NEVER\n' ...
         '   crosses the real axis at any finite non-zero frequency.\n' ...
         'It leaves -j*infinity at w -> 0+ and returns to the origin at\n' ...
         'w -> infinity, approaching along the negative imaginary direction.\n' ...
         'Re{G(j0+)} -> 11/72 = %.8f (the plot starts at that abscissa).\n'], 11/72);
fprintf('numerically, Re{G(jw)} at the lowest sampled w = %.8f\n', real(gr(1)));

% ---- (d) Nichols --------------------------------------------------------
figure('Name','2.1d Nichols of G1');
nichols(G1); ngrid; grid on;
title('2.1(d)  Nichols chart of (s+1)(s+2)/[s(s+3)(s+4)]');
xlabel('Open-Loop Phase (deg)'); ylabel('Open-Loop Gain (dB)');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig2_1d_nichols.png'), 'Resolution', 200);

%% ================================================================ 2.2
fprintf('\n\n=== 2.2  G(s) = K(s-1)(s-2)/(s^2+4s+16),  K = 1 ===\n');
fprintf(['The handout leaves K unspecified. Margins are quoted for K = 1;\n' ...
         'the closing paragraph shows how each margin scales with K.\n']);

K  = 1;
G2 = tf(K*conv([1 -1],[1 -2]), [1 4 16]);
G2                                                      %#ok<NOPTS>
fprintf('open-loop zeros : %s   <- BOTH in the right half plane\n', mat2str(zero(G2)'));
fprintf('open-loop poles : %s\n', mat2str(round(pole(G2)',4)));
fprintf('relative degree 0 -> |G| does NOT roll off; it tends to K at high w.\n');

% ---- (a) Bode -----------------------------------------------------------
figure('Name','2.2a Bode of G2');
bode(G2); grid on;
title('2.2(a)  Bode diagram of (s-1)(s-2)/(s^2+4s+16)');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig2_2a_bode.png'), 'Resolution', 200);

fprintf('\n|G| at the two ends:  |G(j0)| = %.6f (= K/8),  |G(j inf)| -> %.6f (= K)\n', ...
        abs(evalfr(G2,0)), K);

% ---- (b) Nyquist and the margins ---------------------------------------
% Draw it by hand so the two things that matter are visible and labelled:
% where the curve cuts the negative real axis (-0.75), and where -1 sits.
wN2 = logspace(-2, 3, 6000);
gN2 = squeeze(freqresp(G2, wN2));
th  = linspace(0, 2*pi, 400);
figure('Name','2.2b Nyquist of G2');
plot(cos(th), sin(th), ':', 'LineWidth', 1.0, 'Color', [.5 .5 .5]); hold on;  % unit circle
plot(real(gN2), imag(gN2), 'LineWidth', 1.7);
plot(real(gN2), -imag(gN2), '--', 'LineWidth', 1.0);                          % w < 0 mirror
plot(-1, 0, 'r+', 'MarkerSize', 14, 'LineWidth', 2);
plot(-0.75, 0, 'o', 'MarkerSize', 8, 'LineWidth', 1.6);
text(-0.75, 0.13, sprintf('  \\omega_{pc} = 2\\surd2, G = -0.75'), 'FontSize', 9);
text(-1, -0.16, '  -1', 'FontSize', 10, 'Color', 'r');
gq2 = evalfr(G2, 1j*2*sqrt(3));
plot(real(gq2), imag(gq2), 's', 'MarkerSize', 9, 'LineWidth', 1.8);
text(real(gq2)+0.07, imag(gq2)+0.10, ...
     sprintf('\\omega_{gc} = 2\\surd3, |G| = 1'), 'FontSize', 9);
text(real(gq2)+0.07, imag(gq2)+0.02, ...
     sprintf('\\angleG = %.1f\\circ  \\Rightarrow  PM = %.1f\\circ', ...
             rad2deg(angle(gq2))-360, 180+rad2deg(angle(gq2))-360), 'FontSize', 8.5);
hold off; grid on; axis equal;
xlim([-1.35 1.35]); ylim([-1.45 1.45]);
title({'2.2(b)  Nyquist plot of (s-1)(s-2)/(s^2+4s+16)', ...
       'the curve cuts the real axis at -0.75, to the RIGHT of -1: no encirclement'});
xlabel('Real Axis'); ylabel('Imaginary Axis');
legend('unit circle','\omega > 0','\omega < 0 (mirror)','critical point -1', ...
       'Location','southeast');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig2_2b_nyquist.png'), 'Resolution', 200);

figure('Name','2.2b margins');
margin(G2); grid on;
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig2_2b_margin.png'), 'Resolution', 200);

[gm, pm, wcg, wcp] = margin(G2);
fprintf('\n--- 2.2(b) margins from margin() ---\n');
fprintf('gain margin  Gm = %.8f  (= %.4f dB)   at w = %.8f rad/s\n', gm, 20*log10(gm), wcg);
fprintf('phase margin Pm = %.8f deg            at w = %.8f rad/s\n', pm, wcp);
fprintf('exact values : w_pc = 2*sqrt(2) = %.8f,  w_gc = 2*sqrt(3) = %.8f\n', ...
        2*sqrt(2), 2*sqrt(3));
fprintf('G(j*2sqrt2) = %.8f  (exactly -3/4, on the negative real axis)\n', ...
        real(evalfr(G2, 1j*2*sqrt(2))));

% The trap: negative phase margin, yet the closed loop is stable.
T2 = feedback(G2, 1);
fprintf('\nclosed-loop poles at K = 1 : %s\n', mat2str(round(pole(T2)',4)));
fprintf('closed loop stable? %d   <-- despite Pm = %.2f deg being NEGATIVE\n', ...
        isstable(T2), pm);
fprintf(['\nWhy the phase margin lies: the usual "Pm > 0 means stable" rule assumes\n' ...
         'the Nyquist curve approaches -1 the ordinary way. Here both zeros are in\n' ...
         'the right half plane, the curve reaches |G| = 1 while its phase has already\n' ...
         'swung past -180 deg, yet it still does not encircle -1 (its real-axis\n' ...
         'crossing sits at -0.75, to the RIGHT of -1). With P = 0 open-loop RHP poles\n' ...
         'and N = 0 encirclements, Z = N + P = 0: no closed-loop RHP poles.\n' ...
         'Read the encirclements, not the sign of Pm.\n']);

% Cross-check against Lab 1.
fprintf('--- consistency with Computer Lab Exercise 1 ---\n');
fprintf(['Gm = 4/3 says K may be multiplied by 4/3 before the curve reaches -1.\n' ...
         'Lab 1 found the same limit from the root locus: 1 + K*G2 = 0 gives\n' ...
         '(1+K)s^2 + (4-3K)s + (16+2K), stable exactly while 4 - 3K > 0, i.e. K < 4/3.\n' ...
         'The two methods agree to the last digit.\n']);
for Ktest = [1 4/3-1e-6 4/3+1e-6 2]
    Tk = feedback(tf(Ktest*conv([1 -1],[1 -2]),[1 4 16]), 1);
    fprintf('  K = %-10.6f -> stable = %d\n', Ktest, isstable(Tk));
end
