%TASK1_CAESAR  Task 1: Caesar encryption of the given text with k from GUIDs.
cfg = lab_config();
[kmod, k, s] = k_from_guids(cfg.guid1, cfg.guid2);
fprintf('\n===== Task 1: Caesar cipher =====\n');
fprintf('Step 1: GUID sum   %d + %d = %d\n', cfg.guid1, cfg.guid2, s);
fprintf('Step 2: digit sum  %s = %d\n', ...
        strjoin(cellstr((num2str(s, '%d')).'), '+'), k);
fprintf('        k_mod = mod(%d, 26) = %d\n', k, kmod);
[chk, chkK] = k_from_guids(2429202, 2429222);          % handout example
fprintf('Check against handout example: k = %d, k_mod = %d (expected 35, 9)\n', chkK, chk);

plaintext  = read_text(cfg.plainFile);
ciphertext = caesar_encrypt(plaintext, kmod);
write_text(cfg.cipherFile, ciphertext);
write_text(fullfile(cfg.outDir, 'ciphertext_blocks.txt'), to_blocks(ciphertext));

fprintf('\nPlaintext (%d characters, loaded from plaintext.txt):\n%s\n', ...
        numel(plaintext), plaintext);
fprintf('\nCiphertext, k = %d (case and punctuation kept):\n%s\n', kmod, ciphertext);
fprintf('\nCiphertext in conventional form (letters only, groups of 5):\n%s\n', ...
        to_blocks(ciphertext));
fprintf('\nDecryption check: D(k, E(k, p)) == p  ->  %s\n', ...
        mat2str(strcmp(caesar_decrypt(ciphertext, kmod), plaintext)));
