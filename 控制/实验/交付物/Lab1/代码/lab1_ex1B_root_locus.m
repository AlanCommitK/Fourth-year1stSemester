%% LAB1_EX1B_ROOT_LOCUS  Exercise 1B - root locus analysis.
%  UESTCHN4002 Control Engineering, Computer Lab Exercise 1, section 5.
%
%  5.1  root locus of  G1(s) = (s+1)(s+2)/[s(s+3)(s+4)]
%  5.2  unity feedback with G2(s) = K(s-1)(s-2)/(s^2+4s+16):
%       (a) sketch the root locus
%       (b) imaginary-axis crossing and the gain there
%       (c) the 0.45 damping-ratio line and the gain where the locus crosses it
%       (d) range of K for stability
%       (e) both loci on one diagram

figDir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(figDir, 'dir'); mkdir(figDir); end

%% ---------------------------------------------------------------- 5.1
fprintf('\n=== 5.1  G1(s) = (s+1)(s+2)/[s(s+3)(s+4)] ===\n');

G1 = tf(conv([1 1],[1 2]), conv([1 0], conv([1 3],[1 4])));
fprintf('open-loop zeros : %s\n', mat2str(zero(G1)'));
fprintf('open-loop poles : %s\n', mat2str(pole(G1)'));

n = numel(pole(G1)); m = numel(zero(G1));
fprintf('n - m = %d  -> %d asymptote(s) at %g deg, centroid sigma_a = %g\n', ...
        n-m, n-m, 180/(n-m), (sum(pole(G1)) - sum(zero(G1)))/(n-m));

figure('Name','5.1 root locus of G1');
rlocus(G1); grid on; sgrid;
title('5.1  Root locus of (s+1)(s+2)/[s(s+3)(s+4)]');
xlabel('Real Axis (seconds^{-1})'); ylabel('Imaginary Axis (seconds^{-1})');
if exist('theme','file'), theme(gcf,'light'); end   % white background for the report
exportgraphics(gcf, fullfile(figDir,'fig5_1_rlocus_G1.png'), 'Resolution', 200);

% Where do the closed-loop poles actually go? Sample a few gains.
fprintf('\nclosed-loop poles of 1 + K*G1 = 0:\n');
for K = [1e-6 0.5 2 10 100]        % K = 0 exactly makes the loop gain zero, so start just above
    fprintf('  K = %-6g : %s\n', K, mat2str(round(pole(feedback(K*G1,1)),4)'));
end
fprintf(['\nAll three branches stay on the real axis for every K > 0:\n' ...
         '  0 -> -1,   -3 -> -2,   -4 -> -infinity.\n' ...
         'So this locus has NO breakaway or break-in point.\n' ...
         '(The reciprocal-sum equation does return sigma = -3.3996 and -1.5567,\n' ...
         ' but neither lies on a real-axis segment of the locus - they belong to\n' ...
         ' the complementary locus for K < 0. Always screen the roots with the\n' ...
         ' odd-count real-axis rule before quoting them.)\n']);

%% ---------------------------------------------------------------- 5.2 (a)
fprintf('\n=== 5.2(a)  G2(s) = K(s-1)(s-2)/(s^2+4s+16) ===\n');

G2 = tf(conv([1 -1],[1 -2]), [1 4 16]);     % the K is supplied by rlocus
fprintf('open-loop zeros : %s   <- both in the RHP\n', mat2str(zero(G2)'));
fprintf('open-loop poles : %s\n', mat2str(round(pole(G2),4)'));

figure('Name','5.2(a) root locus of G2');
rlocus(G2); grid on;
title('5.2(a)  Root locus of K(s-1)(s-2)/(s^2+4s+16)');
xlabel('Real Axis (seconds^{-1})'); ylabel('Imaginary Axis (seconds^{-1})');
if exist('theme','file'), theme(gcf,'light'); end   % white background for the report
exportgraphics(gcf, fullfile(figDir,'fig5_2a_rlocus_G2.png'), 'Resolution', 200);

%% ---------------------------------------------------------------- 5.2 (b)
fprintf('\n--- 5.2(b)  imaginary-axis crossing ---\n');

% Characteristic equation: (1+K)s^2 + (4-3K)s + (16+2K) = 0.
% A pure imaginary pair needs the s^1 coefficient to vanish: 4 - 3K = 0.
K_cross = 4/3;
w_cross = sqrt((16 + 2*K_cross)/(1 + K_cross));
fprintf('analytic : 4 - 3K = 0  ->  K = %.6f,  omega = sqrt((16+2K)/(1+K)) = %.6f rad/s\n', ...
        K_cross, w_cross);
fprintf('           (omega = 2*sqrt(2) = %.6f)\n', 2*sqrt(2));
fprintf('check    : poles at K = 4/3 are %s\n', ...
        mat2str(round(pole(feedback((4/3)*G2,1)),6)'));

% rlocfind can be called non-interactively by handing it the point.
% In the lab you are asked to click on the crossing instead:
%     figure; rlocus(G2); [K_click, poles_click] = rlocfind(G2)
[K_rlf, p_rlf] = rlocfind(G2, 1j*w_cross);
fprintf('rlocfind at s = j%.4f -> K = %.6f, poles = %s\n', ...
        w_cross, K_rlf, mat2str(round(p_rlf,4)'));

%% ---------------------------------------------------------------- 5.2 (c)
fprintf('\n--- 5.2(c)  0.45 damping-ratio line ---\n');

zeta_target = 0.45;

% zeta of the closed-loop pair as a function of K:
%   wn    = sqrt((16+2K)/(1+K)),   2*zeta*wn = (4-3K)/(1+K)
%   zeta  = (4-3K) / (2*sqrt((16+2K)*(1+K)))
zfun  = @(K) (4-3*K) ./ (2*sqrt((16+2*K).*(1+K))) - zeta_target;
K_zeta = fzero(zfun, [0 4/3-1e-9]);

p_zeta = roots([1+K_zeta, 4-3*K_zeta, 16+2*K_zeta]);
wn_z   = abs(p_zeta(1));
fprintf('K at zeta = 0.45 : %.6f\n', K_zeta);
fprintf('closed-loop poles: %s\n', mat2str(round(p_zeta,4)'));
fprintf('wn = %.4f rad/s, zeta = %.4f (check)\n', wn_z, -real(p_zeta(1))/wn_z);

figure('Name','5.2(c) root locus with 0.45 damping line');
rlocus(G2); grid on; hold on;
sgrid(zeta_target, []);                      % draw the 0.45 damping line
                                             % (R2026a rejects a 0 here: the
                                             %  wn argument must be empty or positive)
plot(real(p_zeta), imag(p_zeta), 'rs', 'MarkerSize', 9, 'LineWidth', 1.8);
title(sprintf('5.2(c)  \\zeta = 0.45 line crosses the locus at K = %.4f', K_zeta));
xlabel('Real Axis (seconds^{-1})'); ylabel('Imaginary Axis (seconds^{-1})');
if exist('theme','file'), theme(gcf,'light'); end   % white background for the report
exportgraphics(gcf, fullfile(figDir,'fig5_2c_sgrid045.png'), 'Resolution', 200);

%% ---------------------------------------------------------------- 5.2 (d)
fprintf('\n--- 5.2(d)  range of K for stability ---\n');
fprintf(['characteristic equation : (1+K)s^2 + (4-3K)s + (16+2K) = 0\n' ...
         'a second-order polynomial is stable iff all three coefficients share a sign:\n' ...
         '    1+K  > 0  ->  K > -1\n' ...
         '    4-3K > 0  ->  K < 4/3\n' ...
         '   16+2K > 0  ->  K > -8\n' ...
         '=> stable for  -1 < K < 4/3 ;  with K >= 0 the usable range is\n' ...
         '   0 <= K < 4/3 = %.6f\n'], 4/3);
fprintf('spot checks:\n');
for K = [0.5 1.3 4/3 1.4 2]
    pp = roots([1+K, 4-3*K, 16+2*K]);
    if max(real(pp)) < -1e-12
        verdict = 'stable';
    elseif max(real(pp)) > 1e-12
        verdict = 'unstable';
    else
        verdict = 'marginally stable (poles on the imaginary axis)';
    end
    fprintf('  K = %-8.4f poles %s  -> %s\n', K, mat2str(round(pp,4)'), verdict);
end

%% ---------------------------------------------------------------- 5.2 (e)
fprintf('\n--- 5.2(e)  both loci on one diagram ---\n');
figure('Name','5.2(e) both root loci');
rlocus(G1, 'b', G2, 'r'); grid on;
legend('5.1:  (s+1)(s+2)/[s(s+3)(s+4)]', '5.2:  (s-1)(s-2)/(s^2+4s+16)', ...
       'Location','southwest');
title('5.2(e)  Root loci of both systems');
xlabel('Real Axis (seconds^{-1})'); ylabel('Imaginary Axis (seconds^{-1})');
if exist('theme','file'), theme(gcf,'light'); end   % white background for the report
exportgraphics(gcf, fullfile(figDir,'fig5_2e_both.png'), 'Resolution', 200);

fprintf(['\nThe contrast is the point of putting them together: the first system\n' ...
         'is minimum phase and stays on the real axis for every gain, so it is\n' ...
         'stable for all K > 0. The second has two RHP zeros, its branches bend\n' ...
         'straight towards them and cross the imaginary axis at K = 4/3, so its\n' ...
         'usable gain range is bounded from above.\n']);
