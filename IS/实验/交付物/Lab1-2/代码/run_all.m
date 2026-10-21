%RUN_ALL  Run Tasks 1-4 in order and save a log of the console output.
cfg = lab_config();
logFile = fullfile(cfg.outDir, 'run_all_log.txt');
if exist(logFile, 'file'), delete(logFile); end
diary(logFile);
cleanupDiary = onCleanup(@() diary('off'));
fprintf('UESTCHN4009 Information Security - Lab sessions 1 & 2\n');
fprintf('MATLAB %s, %s\n', version, datestr(now, 'yyyy-mm-dd HH:MM'));
fprintf('\n===== Self-test =====\n');
test_lab;
task1_caesar;
task2_bruteforce;
task3_frequency;
task4_playfair;
extension_playfair_vs_caesar;
diary('off');
fprintf('\nLog saved to output/run_all_log.txt\n');
