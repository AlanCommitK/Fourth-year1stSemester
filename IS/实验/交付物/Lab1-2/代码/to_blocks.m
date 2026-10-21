function s = to_blocks(t, n)
%TO_BLOCKS  Upper-case letters only, written in groups of n (default 5).
%   This is the conventional way to transmit classical ciphertext: removing
%   spaces and punctuation hides the word lengths from an attacker.
    if nargin < 2, n = 5; end
    t = upper(char(t));
    t = t(t >= 'A' & t <= 'Z');
    s = strjoin(cellstr(reshape([t, repmat(' ', 1, mod(-numel(t), n))], n, []).'), ' ');
    s = strtrim(s);
end
