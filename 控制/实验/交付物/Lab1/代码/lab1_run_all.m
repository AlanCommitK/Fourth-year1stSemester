%% LAB1_RUN_ALL  Computer Lab Exercise 1 - run every section in order.
%  UESTCHN4002 Control Engineering
%
%  Usage:  >> lab1_run_all
%
%  Every script writes its figures to ../figures/ as PNG and prints a clean
%  transcript to the command window, so the output can be pasted straight
%  into the lab report.
%
%  Requires: MATLAB + Control System Toolbox.

clear; clc; close all;

scripts = { 'lab1_s2_basics', ...
            'lab1_s3_control_setup', ...
            'lab1_ex1A_vector_eval', ...
            'lab1_ex1B_root_locus' };

for k = 1:numel(scripts)
    fprintf('\n\n');
    fprintf('################################################################\n');
    fprintf('###  RUNNING %-50s ###\n', scripts{k});
    fprintf('################################################################\n');
    run(scripts{k});
end

fprintf('\n\nAll sections completed. Figures are in ../figures/\n');
