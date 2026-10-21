function [cipher, pairs] = playfair_encrypt(keyword, plaintext, mode)
%PLAYFAIR_ENCRYPT  Encrypt plaintext with the Playfair cipher.
%   cipher is returned as space-separated digrams, e.g. 'IB SU PM NA'.
%   pairs are the prepared plaintext digrams (N x 2 char).  MODE: see
%   playfair_prepare ('handout' by default).
    if nargin < 3 || isempty(mode), mode = 'handout'; end
    M      = playfair_matrix(keyword);
    pairs  = playfair_prepare(plaintext, mode);
    cipher = pairs_to_text(playfair_crypt(M, pairs, +1));
end
