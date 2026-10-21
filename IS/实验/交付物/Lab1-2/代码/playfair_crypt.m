function out = playfair_crypt(M, pairs, direction)
%PLAYFAIR_CRYPT  Apply the Playfair rules to digrams.
%   direction = +1 encrypts (right / down), -1 decrypts (left / up).
%   For each pair:
%   - same row:    each letter -> the letter to its right (left), wrapping;
%   - same column: each letter -> the letter below (above) it, wrapping;
%   - otherwise:   each letter -> the letter in its own row and in the column
%                  of the other letter (the opposite corners of the rectangle).
    out = pairs;
    for n = 1:size(pairs, 1)
        [r1, c1] = find(M == pairs(n, 1));
        [r2, c2] = find(M == pairs(n, 2));
        if isempty(r1) || isempty(r2)
            error('playfair_crypt:letter', 'Letter not in matrix: %s', pairs(n, :));
        end
        if r1 == r2
            out(n, 1) = M(r1, mod(c1 - 1 + direction, 5) + 1);
            out(n, 2) = M(r2, mod(c2 - 1 + direction, 5) + 1);
        elseif c1 == c2
            out(n, 1) = M(mod(r1 - 1 + direction, 5) + 1, c1);
            out(n, 2) = M(mod(r2 - 1 + direction, 5) + 1, c2);
        else
            out(n, 1) = M(r1, c2);
            out(n, 2) = M(r2, c1);
        end
    end
end
