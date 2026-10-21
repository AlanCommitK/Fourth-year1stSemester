function pairs = playfair_prepare(plaintext, mode)
%PLAYFAIR_PREPARE  Turn plaintext into Playfair digrams (N x 2 char array).
%   Rules (handout, Task 4):
%   1. upper case; drop spaces, punctuation and digits; J -> I;
%   2. pair letters left to right; if the two letters of a pair would be the
%      same, insert X after the first letter and continue pairing from the
%      second letter;
%   3. if one letter is left at the end, add X to complete the last pair.
%
%   MODE 'handout' (default) applies these rules word for word.  When the
%   repeated letter or the final single letter is itself X, this produces the
%   pair XX (e.g. BOX -> BO XX, TAXXI -> TA XX XI); XX is encrypted by the
%   same-row rule like any other pair and decrypts back correctly.
%   MODE 'qfill' is an optional variant: in exactly that case it uses Q as
%   the filler instead, so that no pair ever contains two equal letters.
    if nargin < 2 || isempty(mode), mode = 'handout'; end
    switch lower(char(mode))
        case {'handout', 'literal'}, useQ = false;
        case {'qfill', 'standard'},  useQ = true;
        otherwise
            error('playfair_prepare:mode', 'mode must be ''handout'' or ''qfill''.');
    end
    t = upper(char(plaintext));
    t = t(t >= 'A' & t <= 'Z');
    t(t == 'J') = 'I';
    if isempty(t)
        error('playfair_prepare:empty', 'The plaintext contains no letters.');
    end
    pairs = repmat(' ', 0, 2);
    i = 1;
    n = numel(t);
    while i <= n
        a = t(i);
        if i == n || t(i + 1) == a           % lone last letter, or a doubled letter
            if a == 'X' && useQ
                filler = 'Q';
            else
                filler = 'X';
            end
            pairs(end + 1, :) = [a, filler]; %#ok<AGROW>
            i = i + 1;                       % continue from the second letter
        else
            pairs(end + 1, :) = t(i:i + 1);  %#ok<AGROW>
            i = i + 2;
        end
    end
end
