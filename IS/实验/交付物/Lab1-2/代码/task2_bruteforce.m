%TASK2_BRUTEFORCE  Task 2: brute-force cryptanalysis of the Task 1 ciphertext.
cfg = lab_config();
if ~exist(cfg.cipherFile, 'file'), task1_caesar; end
ciphertext = read_text(cfg.cipherFile);
[cands, chi2] = caesar_bruteforce(ciphertext);

fprintf('\n===== Task 2: brute force (all 26 keys) =====\n');
fprintf(' k   chi^2      first 60 characters of the candidate\n');
for k = 0:25
    c = cands{k + 1};
    fprintf('%2d %9.1f   %s\n', k, chi2(k + 1), c(1:min(60, end)));
end
[~, best] = min(chi2);
kFound = best - 1;
fprintf('\nVisual inspection: only one row reads as English.\n');
fprintf('Automatic cross-check (smallest chi^2): k = %d (chi^2 = %.1f; next best %.1f)\n', ...
        kFound, chi2(best), min(chi2([1:best-1, best+1:end])));
kUsed = k_from_guids(cfg.guid1, cfg.guid2);
fprintf('Key used for encryption in Task 1: k = %d  ->  match: %s\n', ...
        kUsed, mat2str(kFound == kUsed));
fprintf('\nRecovered plaintext (k = %d):\n%s\n', kFound, cands{best});
write_text(fullfile(cfg.outDir, 'bruteforce_candidates.txt'), ...
           strjoin(arrayfun(@(k) sprintf('%2d  %s', k, cands{k+1}), 0:25, ...
           'UniformOutput', false), newline));
