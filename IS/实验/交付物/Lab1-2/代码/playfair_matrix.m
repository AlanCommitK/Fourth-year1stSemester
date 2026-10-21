function M = playfair_matrix(keyword)
%PLAYFAIR_MATRIX  5x5 Playfair key matrix (char array) from a keyword.
%   Rules (handout, Task 4):
%   1. upper case; drop spaces and every non-letter; J is treated as I;
%   2. keep only the first occurrence of each letter of the keyword;
%   3. fill row by row with the reduced keyword, then with the remaining
%      letters of the alphabet (no J) in alphabetical order.
    kw = upper(char(keyword));
    kw = kw(kw >= 'A' & kw <= 'Z');
    kw(kw == 'J') = 'I';
    alphabet = 'ABCDEFGHIKLMNOPQRSTUVWXYZ';          % 25 letters, no J
    seq = unique([kw, alphabet], 'stable');           % first occurrence wins
    M = reshape(seq, 5, 5).';                         % row by row
end
