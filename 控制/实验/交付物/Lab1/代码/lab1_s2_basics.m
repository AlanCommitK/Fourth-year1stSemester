%% LAB1_S2_BASICS  Section 2 - basic MATLAB commands.
%  UESTCHN4002 Control Engineering, Computer Lab Exercise 1.
%
%  Covers handout sections 2.1 to 2.6. Nothing here is assessed, but the
%  commands are the ones used throughout the rest of the lab.

clc;
fprintf('\n=== 2.1.1  Fundamental expressions ===\n');

a = 2 + 3;
fprintf('a = 2+3            -> %g\n', a);

% Handout: x = 6/4 - sqrt(2*(3+8))
x = 6/4 - sqrt(2*(3+8));
fprintf('x = 6/4 - sqrt(2*(3+8)) -> %.6f      (= 1.5 - sqrt(22))\n', x);

fprintf('\n=== 2.1.3  Predefined variables ===\n');
z = (3-5j) + (4+2i);
fprintf('(3-5j)+(4+2i)      -> %g %+gi\n', real(z), imag(z));
fprintf('pi                 -> %.6f\n', pi);
fprintf('5/0                -> %g   (Inf)\n', 5/0);
fprintf('0/0                -> %g   (NaN)\n', 0/0);

fprintf('\n=== 2.1.4  Built-in functions ===\n');
fprintf('abs(-3.7)   = %g\n',      abs(-3.7));
fprintf('sqrt(22)    = %.6f\n',    sqrt(22));
fprintf('round(2.67) = %g\n',      round(2.67));
fprintf('exp(1)      = %.6f\n',    exp(1));
fprintf('log(exp(2)) = %g     (natural log)\n', log(exp(2)));
fprintf('sin(pi/6)   = %.6f\n',    sin(pi/6));
fprintf('real(3-5j)  = %g\n',      real(3-5j));

fprintf('\n=== 2.4  Script file: area_cylinder.m ===\n');
area_cylinder;                     % defined in its own file, as the handout asks

fprintf('\n=== 2.6  Vectors and matrices ===\n');
A_row = [12 42 3 -27];
fprintf('row vector A      = [%s]\n', num2str(A_row));
fprintf('A.*2              = [%s]\n', num2str(A_row.*2));

% Celsius -> Fahrenheit, 5:5:50 degC, all at once (element-wise)
C = 5:5:50;
F = C*9/5 + 32;
fprintf('\n C (degC) : %s\n', num2str(C,  '%7.1f'));
fprintf(' F (degF) : %s\n',   num2str(F,  '%7.1f'));

A_col = [12; 42; 3; -27];
fprintf('\ncolumn vector A is %dx%d\n', size(A_col,1), size(A_col,2));

B = [2 3 -6; 4 8 1; -3 2 0];
fprintf('\nB =\n'); disp(B);
fprintf('ones(2), zeros(2), eye(3) exist; 5x5 matrix of 2.6:\n');
M = 2.6*ones(5);
disp(M);
