%% LAB1_S3_CONTROL_SETUP  Section 3 - setting up control problems in MATLAB.
%  UESTCHN4002 Control Engineering, Computer Lab Exercise 1.
%
%  Part 1: build G(s) = 5(s+1)(s+2) / [(s+3)(s+4)(s+5)] from polynomial
%          coefficient vectors, print it, plot its unit-step response.
%  Part 2: close the loop with feedback() for H = 1 and H = (s+6)/(s+10),
%          then compare the step responses at K = 500.
%  Part 3: partial-fraction expansion of G(s) with residue().
%  Part 4: a second loop,  K(s+1) / [s(s-1)(s+6)], poles and zeros vs K.

figDir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(figDir, 'dir'); mkdir(figDir); end

%% ---------------------------------------------------------------- Part 1
fprintf('\n=== 3.0 Part 1 : G(s) = 5(s+1)(s+2)/[(s+3)(s+4)(s+5)] ===\n');

num = 5*conv([1 1], [1 2]);                 % 5*(s+1)(s+2)
den = conv(conv([1 3], [1 4]), [1 5]);      % (s+3)(s+4)(s+5)

fprintf('num = [%s]\n', num2str(num));
fprintf('den = [%s]\n', num2str(den));

% printsys() still works in R2026a, but it lives in toolbox/control/ctrlobsolete,
% i.e. MathWorks has marked it obsolete and it may disappear in a future
% release. tf() is the supported way to display a transfer function and is
% what the handout offers as the alternative. The try/catch keeps the script
% running on releases where printsys has finally been removed.
try
    printsys(num, den, 's');
catch ME
    fprintf(['printsys is not available in this release (%s).\n' ...
             'Using tf() instead, exactly as the handout suggests.\n'], ME.identifier);
end

G = tf(num, den);
fprintf('\nG(s) =\n'); G                                          %#ok<NOPTS>

fprintf('DC gain G(0) = %.6f   (= 10/60)\n', dcgain(G));

figure('Name','3.0 Part1 step response of G');
step(G); grid on;
title('Unit-step response of G(s) = 5(s+1)(s+2)/[(s+3)(s+4)(s+5)]');
xlabel('Time (seconds)'); ylabel('Amplitude');
if exist('theme','file'), theme(gcf,'light'); end   % white background for the report
exportgraphics(gcf, fullfile(figDir,'fig3_1_step_G.png'), 'Resolution', 200);

%% ---------------------------------------------------------------- Part 2
fprintf('\n=== 3.0 Part 2 : closed loop, T = feedback(K*G, H) ===\n');

H1 = tf(1, 1);                  % H(s) = 1
H2 = tf([1 6], [1 10]);         % H(s) = (s+6)/(s+10)

for K = [1 500]
    for h = 1:2
        if h == 1, H = H1; hname = 'H = 1';
        else,      H = H2; hname = 'H = (s+6)/(s+10)'; end

        T = feedback(K*G, H);
        fprintf('\n--- K = %g,  %s ---\n', K, hname);
        T                                                          %#ok<NOPTS>
        fprintf('closed-loop poles : %s\n', mat2str(round(pole(T),4)));
        fprintf('DC gain           : %.6f\n', dcgain(T));
    end
end

% Step responses at K = 500, both H cases on one axis
figure('Name','3.0 Part2 step response at K=500');
step(feedback(500*G,H1), feedback(500*G,H2)); grid on;
legend('H(s) = 1', 'H(s) = (s+6)/(s+10)', 'Location','southeast');
title('Closed-loop step response, K = 500');
xlabel('Time (seconds)'); ylabel('Amplitude');
if exist('theme','file'), theme(gcf,'light'); end   % white background for the report
exportgraphics(gcf, fullfile(figDir,'fig3_2_step_K500.png'), 'Resolution', 200);

%% ---------------------------------------------------------------- Part 3
fprintf('\n=== 3.0 Part 3 : partial fractions of G(s) via residue ===\n');

[r, p, k] = residue(num, den);
for i = 1:numel(r)
    fprintf('  residue %+10.4f  at pole %+8.4f\n', r(i), p(i));
end
if isempty(k)
    fprintf('  direct term k is empty (G is strictly proper)\n');
end
fprintf('\n  => G(s) = %.4f/(s%+.0f) %+.4f/(s%+.0f) %+.4f/(s%+.0f)\n', ...
        r(1), -p(1), r(2), -p(2), r(3), -p(3));

% Numerical check: rebuild the transfer function from the residues
try
    [nc, dc_] = residue(r, p, k);
    fprintf('  rebuilt num = [%s]\n', num2str(round(nc,10)));
    fprintf('  rebuilt den = [%s]\n', num2str(round(dc_,10)));
catch
    fprintf('  (inverse residue call skipped)\n');
end

%% ---------------------------------------------------------------- Part 4
fprintf('\n=== 3.0 Part 4 : T = feedback(K*(s+1)/[s(s-1)(s+6)], 1) ===\n');

Gp = tf([1 1], conv([1 0], conv([1 -1], [1 6])));   % (s+1)/[s(s-1)(s+6)]
fprintf('open-loop poles : %s   <- s = +1 is in the RHP\n', mat2str(pole(Gp)'));
fprintf('open-loop zeros : %s\n', mat2str(zero(Gp)'));

for K = [1 7.5 13 25]
    T = feedback(K*Gp, 1);
    pp = pole(T);
    fprintf('\n K = %-5g  zeros: %s\n', K, mat2str(round(zero(T),4)'));
    fprintf('           poles: %s\n', mat2str(round(pp,4)'));
    if max(real(pp)) < 0
        fprintf('           STABLE   (max Re = %+.4f)\n', max(real(pp)));
    else
        fprintf('           UNSTABLE (max Re = %+.4f)\n', max(real(pp)));
    end
end
fprintf(['\n Note: the stability boundary of this loop is K = 7.5, which is\n' ...
         ' why the handout asks for K = 1 (below), 7.5 (on it), 13 and 25 (above).\n']);
