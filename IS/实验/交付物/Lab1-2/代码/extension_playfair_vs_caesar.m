%EXTENSION_PLAYFAIR_VS_CAESAR  Extra comparison for the discussion (not a set task):
%   encrypt the same lab plaintext with Playfair (keyword = first member's name)
%   and compare its single-letter statistics with the Caesar ciphertext.
cfg = lab_config();
if ~exist(cfg.cipherFile, 'file'), task1_caesar; end
plaintext = read_text(cfg.plainFile);
caesarCt  = read_text(cfg.cipherFile);
[pfCt, pfPairs] = playfair_encrypt(cfg.name1, plaintext);
write_text(fullfile(cfg.outDir, 'playfair_ciphertext_labtext.txt'), pfCt);

pP = letter_frequency(plaintext);
pC = letter_frequency(caesarCt);
pF = letter_frequency(pfCt);
fprintf('\n===== Extension: Playfair vs Caesar on the same plaintext =====\n');
fprintf('Playfair keyword ''%s'': %d digrams (%d fillers inserted)\n', cfg.name1, ...
        size(pfPairs, 1), 2 * size(pfPairs, 1) - numel(regexprep(upper(plaintext), '[^A-Z]', '')));
fprintf('Index of coincidence: plaintext %.4f | Caesar %.4f | Playfair %.4f | English ~0.066 | random %.4f\n', ...
        index_of_coincidence(plaintext), index_of_coincidence(caesarCt), ...
        index_of_coincidence(pfCt), 1/26);
fprintf('Largest single-letter share: plaintext %.2f%% | Caesar %.2f%% | Playfair %.2f%%\n', ...
        max(pP), max(pC), max(pF));

try
    % sorted frequency profiles: a substitution can relabel letters but cannot change
    % the shape of the sorted profile; Playfair changes the shape.
    h = figure('Color', 'w', 'Position', [100 100 900 420]);
    hold on;
    plot(1:26, sort(english_frequency(), 'descend'), 'k--', 'LineWidth', 1.4);
    plot(1:26, sort(pP, 'descend'), '-o', 'Color', [0.18 0.44 0.62], 'LineWidth', 1.6, 'MarkerSize', 5);
    plot(1:26, sort(pC, 'descend'), 'x', 'Color', [0.80 0.36 0.20], 'LineWidth', 1.6, 'MarkerSize', 9);
    plot(1:26, sort(pF, 'descend'), '-s', 'Color', [0.30 0.60 0.30], 'LineWidth', 1.6, 'MarkerSize', 5);
    plot([1 26], [100/26 100/26], ':', 'Color', [0.4 0.4 0.4]);
    text(1.3, 100/26 + 0.35, 'Uniform 3.85%', 'FontSize', 9);
    hold off; grid on; box off; xlim([1 26]);
    xlabel('Rank (most frequent letter = 1)'); ylabel('Percentage of all letters (%)');
    title('Sorted letter-frequency profiles of the same text');
    legend({'General English', 'Plaintext', sprintf('Caesar ciphertext (k = %d)', k_from_guids(cfg.guid1, cfg.guid2)), ...
            sprintf('Playfair ciphertext (keyword %s)', upper(cfg.name1))}, 'Location', 'northeast');
    save_figure(h, fullfile(cfg.figDir, 'fig_ext_sorted_profiles.png'));
catch err
    fprintf('[Plotting skipped: %s]\n', err.message);
end
