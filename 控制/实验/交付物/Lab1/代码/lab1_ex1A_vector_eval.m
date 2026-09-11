%% LAB1_EX1A_VECTOR_EVAL  Exercise 1A - evaluate a complex function via vectors.
%  UESTCHN4002 Control Engineering, Computer Lab Exercise 1, section 4.
%
%  G(s) = (s+1)(s+2) / [s(s+3)(s+4)],  evaluated at s = -3 + j4.
%  4.1  define s and G(s)
%  4.2  magnitude M and angle theta (in degrees) from MATLAB
%  4.3  the same result by hand, from the vector magnitudes and angles

figDir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(figDir, 'dir'); mkdir(figDir); end

%% 4.1  Define the point and the transfer function
s_pt = -3 + 4j;
G    = tf(conv([1 1],[1 2]), conv([1 0], conv([1 3],[1 4])));

fprintf('\n=== Exercise 1A ===\n');
fprintf('G(s) = (s+1)(s+2)/[s(s+3)(s+4)]\n');
fprintf('test point s = %g %+gj\n\n', real(s_pt), imag(s_pt));

%% 4.2  MATLAB evaluation
Gval = evalfr(G, s_pt);                 % evaluate a tf at a complex point
M     = abs(Gval);
theta = rad2deg(angle(Gval));

fprintf('4.2  MATLAB:\n');
fprintf('     G(s) = %.6f %+.6fj\n', real(Gval), imag(Gval));
fprintf('     M     = %.6f\n', M);
fprintf('     theta = %.4f deg\n\n', theta);

% polyval on the coefficient vectors gives the same thing
Gval2 = polyval(conv([1 1],[1 2]), s_pt) / ...
        polyval(conv([1 0], conv([1 3],[1 4])), s_pt);
fprintf('     cross-check with polyval: M = %.6f, theta = %.4f deg\n\n', ...
        abs(Gval2), rad2deg(angle(Gval2)));

%% 4.3  By hand: one vector from every zero and every pole to the test point
zeros_G = [-1 -2];                      % actual zero locations
poles_G = [ 0 -3 -4];                   % actual pole locations

vz = s_pt - zeros_G;                    % vector = end point - start point
vp = s_pt - poles_G;

fprintf('4.3  Vector construction (vector = test point - zero/pole):\n');
labels_z = {'s+1 (zero at -1)', 's+2 (zero at -2)'};
labels_p = {'s   (pole at  0)', 's+3 (pole at -3)', 's+4 (pole at -4)'};
for i = 1:numel(vz)
    fprintf('     %-18s = %6.3f %+6.3fj   |.| = %8.6f   angle = %9.4f deg\n', ...
            labels_z{i}, real(vz(i)), imag(vz(i)), abs(vz(i)), rad2deg(angle(vz(i))));
end
for i = 1:numel(vp)
    fprintf('     %-18s = %6.3f %+6.3fj   |.| = %8.6f   angle = %9.4f deg\n', ...
            labels_p{i}, real(vp(i)), imag(vp(i)), abs(vp(i)), rad2deg(angle(vp(i))));
end

M_hand     = prod(abs(vz)) / prod(abs(vp));
theta_hand = sum(rad2deg(angle(vz))) - sum(rad2deg(angle(vp)));

fprintf('\n     M     = (%.4f x %.4f) / (%.4f x %.4f x %.4f) = %.6f\n', ...
        abs(vz(1)), abs(vz(2)), abs(vp(1)), abs(vp(2)), abs(vp(3)), M_hand);
fprintf('     theta = %.4f + %.4f - %.4f - %.4f - %.4f = %.4f deg\n', ...
        rad2deg(angle(vz(1))), rad2deg(angle(vz(2))), ...
        rad2deg(angle(vp(1))), rad2deg(angle(vp(2))), rad2deg(angle(vp(3))), theta_hand);
fprintf('\n     agreement: dM = %.3e, dtheta = %.3e deg\n', ...
        abs(M-M_hand), abs(theta-theta_hand));

%% Figure: the five vectors drawn on the s-plane
figure('Name','Exercise 1A vectors'); hold on; grid on; axis equal;
plot(real(zeros_G), imag(zeros_G), 'o', 'MarkerSize', 9, 'LineWidth', 1.8, 'Color', [0 0 0]);
plot(real(poles_G), imag(poles_G), 'x', 'MarkerSize', 11, 'LineWidth', 1.8, 'Color', [0 0 0]);
plot(real(s_pt), imag(s_pt), 'p', 'MarkerSize', 13, 'MarkerFaceColor', [0.75 0.2 0.2], ...
     'MarkerEdgeColor', [0.75 0.2 0.2]);
allpts = [zeros_G poles_G];
for i = 1:numel(allpts)
    quiver(real(allpts(i)), imag(allpts(i)), ...
           real(s_pt)-real(allpts(i)), imag(s_pt)-imag(allpts(i)), 0, ...
           'LineWidth', 1.2, 'MaxHeadSize', 0.25);
end
xline(0, 'Color', [0.6 0.6 0.6]); yline(0, 'Color', [0.6 0.6 0.6]);
xlabel('Re(s)'); ylabel('Im(s)');
title(sprintf('Vectors to s = -3+j4:  M = %.4f, \\theta = %.2f^\\circ', M, theta));
legend('zeros', 'poles', 'test point', 'Location', 'southwest');
xlim([-5.5 1.5]); ylim([-1.5 5.5]);
if exist('theme','file'), theme(gcf,'light'); end   % white background for the report
exportgraphics(gcf, fullfile(figDir,'fig4_ex1A_vectors.png'), 'Resolution', 200);
