%% LAB2_RUN_ALL  Computer Lab Exercise 2 - run every section in order.
%  UESTCHN4002 Control Engineering
%
%  Usage:  >> lab2_run_all
%
%  Every script writes its figures to ../figures/ as PNG and prints a clean
%  transcript to the command window, so the output can be pasted straight
%  into the lab report.
%
%  Requires: MATLAB + Control System Toolbox (+ Symbolic Math Toolbox for 2B).

clear; clc; close all;

scripts = { 'lab2_s2_freq', ...
            'lab2_ex2A_dynamics', ...
            'lab2_ex2B_network' };

for k = 1:numel(scripts)
    fprintf('\n\n');
    fprintf('################################################################\n');
    fprintf('###  RUNNING %-50s ###\n', scripts{k});
    fprintf('################################################################\n');
    run(scripts{k});
end

fprintf('\n\nAll sections completed. Figures are in ../figures/\n');
