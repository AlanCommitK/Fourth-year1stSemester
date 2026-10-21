function [pct, counts, total] = letter_frequency(t)
%LETTER_FREQUENCY  Frequency of a..z in a text, case-insensitive.
%   counts(i) is the number of occurrences of the i-th letter (1 = a),
%   pct(i) = 100*counts(i)/total, total = number of letters (non-letters ignored).
    t = lower(char(t));
    t = t(t >= 'a' & t <= 'z');
    counts = accumarray(double(t(:)) - double('a') + 1, 1, [26 1]).';
    total  = numel(t);
    if total == 0
        pct = zeros(1, 26);
    else
        pct = 100 * counts / total;
    end
end
