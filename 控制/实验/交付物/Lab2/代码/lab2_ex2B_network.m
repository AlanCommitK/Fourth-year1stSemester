%% LAB2_EX2B_NETWORK  Exercise 2B - analysis of an electrical network.
%  UESTCHN4002 Control Engineering, Computer Lab Exercise 2, section 4.
%
%  The network of Figure 3, with the Laplace-domain impedances printed on it:
%
%     top wire  -------------------o-------------------o
%                |                 |                   |
%              V(s)              R = 1              C = 1/s
%                |                 |                   |
%     mid wire   o--- L=2s --- R=1 -o                   |
%                |                 |                   |
%                |               L = 4s                |
%                |                 |                   |
%     bottom     o----- L = 3s ----o-------------------o
%
%  Three meshes, all currents taken CLOCKWISE:
%    I1  upper-left  : source V, the vertical R = 1, and the 2s + 1 branch
%    I2  lower-left  : the 2s + 1 branch, the 4s branch and the bottom 3s
%    I3  right       : the vertical R = 1, the 4s branch and the capacitor 1/s
%  I3 is therefore the current through the capacitor, which is what 4.3 asks for.
%
%  4.1  mesh equations
%  4.2  solve for all three mesh currents
%  4.3  transfer function I3(s)/V(s)

figDir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(figDir, 'dir'); mkdir(figDir); end

%% ---------------------------------------------------------------- 4.1
fprintf('\n=== 4.1  mesh equations ===\n');
fprintf([ ...
 '  Going clockwise round each mesh and summing the impedance drops:\n\n' ...
 '   mesh 1 :  (2s + 2) I1  -  (2s + 1) I2  -        1  I3  =  V\n' ...
 '   mesh 2 : -(2s + 1) I1  +  (9s + 1) I2  -       4s  I3  =  0\n' ...
 '   mesh 3 : -       1 I1  -       4s  I2  + (4s + 1 + 1/s) I3  =  0\n\n' ...
 '  self impedances   Z11 = 1 + (1 + 2s)        = 2s + 2\n' ...
 '                    Z22 = (2s + 1) + 4s + 3s  = 9s + 1\n' ...
 '                    Z33 = 1 + 4s + 1/s\n' ...
 '  shared            Z12 = 2s + 1  (the 2s and the 1 in the middle branch)\n' ...
 '                    Z13 = 1       (the vertical resistor)\n' ...
 '                    Z23 = 4s      (the vertical inductor)\n' ...
 '  Only mesh 1 touches the source. Traversed clockwise the source is a RISE,\n' ...
 '  so V sits on the right-hand side of the mesh-1 equation.\n\n']);

%% ---------------------------------------------------------------- 4.2
fprintf('=== 4.2  solving for the mesh currents ===\n');

if exist('sym','file') ~= 2
    error(['Symbolic Math Toolbox not found. Install it, or solve the 3x3 ' ...
           'system numerically frequency by frequency.']);
end

syms s V real
Z = [ 2*s+2,   -(2*s+1),  -1            ;
     -(2*s+1),  9*s+1,    -4*s          ;
     -1,       -4*s,       4*s+1+1/s   ];
b = [V; 0; 0];

fprintf('\nimpedance matrix Z(s):\n'); disp(Z);

I = simplify(Z\b);
I1 = simplify(I(1)/V);  I2 = simplify(I(2)/V);  I3 = simplify(I(3)/V);

fprintf('I1(s)/V(s) = %s\n', char(simplifyFraction(I1)));
fprintf('I2(s)/V(s) = %s\n', char(simplifyFraction(I2)));
fprintf('I3(s)/V(s) = %s\n', char(simplifyFraction(I3)));

detZ = simplify(det(Z)*s);
fprintf('\ns*det(Z) = %s\n', char(expand(detZ)));

%% ---------------------------------------------------------------- 4.3
fprintf('\n=== 4.3  transfer function I3(s)/V(s) ===\n');

T43 = simplifyFraction(I3);
[numS, denS] = numden(T43);
% sym2poly returns coefficients in DESCENDING powers, which is what tf() wants.
% (coeffs(...,'All') would also work but its ordering is easy to get backwards.)
numC = sym2poly(expand(numS));
denC = sym2poly(expand(denS));

Gi3 = tf(numC, denC);
fprintf('\nI3/V as a transfer function:\n'); Gi3            %#ok<NOPTS>

fprintf('  numerator   coefficients: %s\n', mat2str(numC));
fprintf('  denominator coefficients: %s\n', mat2str(denC));
fprintf('  by hand:  I3/V = (8 s^3 + 13 s^2 + s) / (24 s^4 + 30 s^3 + 17 s^2 + 16 s + 1)\n');

fprintf('\n  poles : %s\n', mat2str(round(pole(Gi3)',6)));
fprintf('  zeros : %s\n', mat2str(round(zero(Gi3)',6)));
fprintf('  all poles in the left half plane? %d  -> the network is stable\n', isstable(Gi3));
fprintf('  DC gain I3/V at s = 0 : %.10g  (zero - the capacitor blocks DC)\n', dcgain(Gi3));

[wnI, zetaI, pI] = damp(Gi3);
fprintf('\n  %-26s %-14s %-12s\n','pole','wn (rad/s)','zeta');
for k = 1:numel(pI)
    fprintf('  %+10.6f %+10.6fi   %-14.6f %-12.6f\n', ...
            real(pI(k)), imag(pI(k)), wnI(k), zetaI(k));
end

% A picture helps the discussion: where does this network respond?
figure('Name','4.3 Bode of I3/V');
bode(Gi3); grid on;
title('4.3  Bode diagram of I_3(s)/V(s)');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig4_3_bode_i3v.png'), 'Resolution', 200);

figure('Name','4.3 step response of I3/V');
step(Gi3, 200); grid on;
title('4.3  Step response of I_3(s)/V(s)  (unit step of V)');
xlabel('Time (seconds)'); ylabel('Capacitor current i_3(t)');
if exist('theme','file'), theme(gcf,'light'); end
exportgraphics(gcf, fullfile(figDir,'fig4_3_step_i3v.png'), 'Resolution', 200);

% stepinfo cannot give a settling time here: the final value is exactly zero
% (the capacitor blocks DC), so the usual +/-2% band around it has zero width.
% Measure instead when |i3| has fallen below 2% of its own peak and stays there.
ts3 = 0:0.01:400;  ys3 = step(Gi3, ts3);
pk  = max(abs(ys3));
out = find(abs(ys3) > 0.02*pk, 1, 'last');
settle = ts3(min(out+1, numel(ts3)));
[pkv, ipk] = max(ys3);
fprintf('\n  step response: peak %.6f at t = %.3f s\n', pkv, ts3(ipk));
fprintf('  decays below 2%% of its own peak after %.1f s\n', settle);
fprintf('  (stepinfo would return NaN for the settling time - the final value is\n');
fprintf('   exactly 0, so a 2%% band around it has zero width. Not an error.)\n');
fprintf('  slowest pole is at %.6f -> time constant %.2f s\n', ...
        max(real(pole(Gi3))), -1/max(real(pole(Gi3))));

%% ---- numerical cross-check, independent of the symbolic solve -----------
fprintf('\n--- cross-check: solve Z(jw) I = [1;0;0] numerically at a few w ---\n');
for w = [0.05 0.2 1 5 20]
    Zn = [ 2*(1j*w)+2,      -(2*(1j*w)+1),  -1 ;
          -(2*(1j*w)+1),     9*(1j*w)+1,    -4*(1j*w) ;
          -1,               -4*(1j*w),       4*(1j*w)+1+1/(1j*w) ];
    In = Zn \ [1;0;0];
    fromTF = evalfr(Gi3, 1j*w);
    fprintf('  w = %-6g  I3 (linear solve) = %+.8f%+.8fi   I3/V (tf) = %+.8f%+.8fi   |diff| = %.2e\n', ...
            w, real(In(3)), imag(In(3)), real(fromTF), imag(fromTF), abs(In(3)-fromTF));
end
