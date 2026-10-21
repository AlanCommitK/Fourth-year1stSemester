%TASK3_FREQUENCY  Task 3: letter frequencies, bar charts, frequency attack.
cfg = lab_config();
if ~exist(cfg.cipherFile, 'file'), task1_caesar; end
plaintext  = read_text(cfg.plainFile);
ciphertext = read_text(cfg.cipherFile);
[pP, cP, nP] = letter_frequency(plaintext);
[pC, cC, nC] = letter_frequency(ciphertext);
pE = english_frequency();
letters = cellstr(('a':'z').');

fprintf('\n===== Task 3: frequency analysis =====\n');
fprintf('Letters counted: plaintext %d, ciphertext %d\n', nP, nC);
fprintf('letter  plain(n)  plain(%%)  cipher(n)  cipher(%%)  English(%%)\n');
for i = 1:26
    fprintf('  %s     %4d     %6.2f     %4d      %6.2f      %6.3f\n', ...
            letters{i}, cP(i), pP(i), cC(i), pC(i), pE(i));
end

% ---- frequency attack --------------------------------------------------------
[~, topL, topN] = frequency_attack(ciphertext);
fprintf('\nMost frequent ciphertext letters: ');
tmp = [num2cell(topL(1:6)); num2cell(topN(1:6))]; fprintf('%s(%d) ', tmp{:});
fprintf('\nMost frequent plaintext letters : ');
[sp, op] = sort(cP, 'descend');
tmp = [num2cell(char(op(1:6) + 96)); num2cell(sp(1:6))]; fprintf('%s(%d) ', tmp{:});
fprintf('\n');
trials = {'e', 1; 't', 1; 'e', 2};
for t = 1:size(trials, 1)
    kg = frequency_attack(ciphertext, trials{t, 1}, trials{t, 2});
    d  = caesar_decrypt(ciphertext, kg);
    fprintf('Assume cipher letter #%d (''%s'') = ''%s''  ->  k = %2d : %s\n', ...
            trials{t, 2}, topL(trials{t, 2}), trials{t, 1}, kg, d(1:min(50, end)));
end

% ---- bar charts (wrapped: a plotting problem must not stop the analysis) ------
try
    figs = {pP, 'plaintext',  'fig_task3_plaintext.png',  [0.18 0.44 0.62]; ...
            pC, 'ciphertext', 'fig_task3_ciphertext.png', [0.80 0.36 0.20]};
    for f = 1:2
        h = figure('Color', 'w', 'Position', [100 100 900 360]);
        bar(1:26, figs{f, 1}, 0.8, 'FaceColor', figs{f, 4});
        set(gca, 'XTick', 1:26, 'XTickLabel', letters, 'FontSize', 11);
        xlim([0.3 26.7]); grid on; box off;
        xlabel('Letter'); ylabel('Percentage of all letters (%)');
        title(sprintf('Letter frequency of the %s (%d letters)', figs{f, 2}, nP));
        [vals, idx] = sort(figs{f, 1}, 'descend');
        for j = 1:2
            text(idx(j), vals(j) + 0.3, sprintf('%.1f', vals(j)), ...
                 'HorizontalAlignment', 'center', 'FontSize', 9);
        end
        save_figure(h, fullfile(cfg.figDir, figs{f, 3}));
    end

    h = figure('Color', 'w', 'Position', [100 100 900 760]);
    data = {pE, 'General English text (Stallings, Ch. 3)', [0.45 0.45 0.45]; ...
            pP, 'Plaintext of this lab', [0.18 0.44 0.62]; ...
            pC, sprintf('Ciphertext (k = %d)', k_from_guids(cfg.guid1, cfg.guid2)), [0.80 0.36 0.20]};
    for s = 1:3
        subplot(3, 1, s);
        bar(1:26, data{s, 1}, 0.8, 'FaceColor', data{s, 3});
        set(gca, 'XTick', 1:26, 'XTickLabel', letters, 'FontSize', 10);
        xlim([0.3 26.7]); ylim([0 15]); grid on; box off;
        ylabel('%'); title(data{s, 2});
    end
    xlabel('Letter');
    save_figure(h, fullfile(cfg.figDir, 'fig_task3_comparison.png'));
    fprintf('\nFigures saved in the figures folder.\n');
catch err
    fprintf('\n[Plotting skipped: %s]\nThe numbers above are unaffected; saved figures are in the figures folder.\n', err.message);
end
