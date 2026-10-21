function out = playfair(keyword, text, action, mode)
%PLAYFAIR  One-line entry point for the lab session (TA tests).
%   playfair('monarchy', 'balloon')
%       prints the matrix, the prepared digrams, the ciphertext, and the
%       decryption of that ciphertext (round-trip check).
%   playfair('monarchy', 'IB SU PM NA', 'decrypt')
%       prints the matrix and the decrypted text.
%   playfair('monarchy')
%       prints the matrix only.
%   Optional 4th argument 'qfill': when a pair would be XX (a doubled X, or a
%   final single X), use Q as the filler instead of the handout's X.
    if nargin < 3 || isempty(action), action = 'encrypt'; end
    if nargin < 4 || isempty(mode),   mode   = 'handout'; end
    M = playfair_matrix(keyword);
    print_matrix(M, sprintf('Playfair matrix for keyword ''%s'':', keyword));
    out = '';
    if nargin < 2 || isempty(char(text)), return; end
    switch lower(action)
        case {'encrypt', 'enc', 'e'}
            [out, pairs] = playfair_encrypt(keyword, text, mode);
            back = playfair_decrypt(keyword, out);
            fprintf('Plaintext        : %s\n', text);
            fprintf('Prepared digrams : %s\n', pairs_to_text(pairs));
            fprintf('Ciphertext       : %s\n', out);
            fprintf('Decrypted back   : %s\n', back);
            ok = strcmp(back, pairs_to_text(pairs));
            fprintf('Round trip OK    : %s\n', mat2str(ok));
        case {'decrypt', 'dec', 'd'}
            out = playfair_decrypt(keyword, text);
            fprintf('Ciphertext       : %s\n', text);
            fprintf('Decrypted        : %s\n', out);
        otherwise
            error('playfair:action', 'action must be ''encrypt'' or ''decrypt''.');
    end
end
