function plain = playfair_decrypt(keyword, ciphertext)
%PLAYFAIR_DECRYPT  Decrypt Playfair ciphertext (spaces / case are ignored).
%   The output keeps the inserted filler letters and I in place of J, as the
%   handout allows; it is returned as space-separated digrams.
    M = playfair_matrix(keyword);
    t = upper(char(ciphertext));
    t = t(t >= 'A' & t <= 'Z');
    if mod(numel(t), 2) ~= 0
        error('playfair_decrypt:odd', ...
              'Ciphertext must have an even number of letters (got %d).', numel(t));
    end
    if any(t == 'J')
        error('playfair_decrypt:J', 'Valid Playfair ciphertext never contains J.');
    end
    pairs = reshape(t, 2, []).';
    plain = pairs_to_text(playfair_crypt(M, pairs, -1));
end
