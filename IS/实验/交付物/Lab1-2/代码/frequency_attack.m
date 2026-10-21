function [kGuess, topLetters, topCounts] = frequency_attack(c, assumed, rank)
%FREQUENCY_ATTACK  Caesar key from the most frequent ciphertext letter.
%   Assume the rank-th most frequent ciphertext letter is the plaintext
%   letter ASSUMED (e.g. 'e' or 't').  Because every letter is shifted by
%   the same k, k = (cipher letter - assumed letter) mod 26.
%   rank defaults to 1 (the most frequent letter).
%   topLetters / topCounts list the ciphertext letters by decreasing count.
    if nargin < 2, assumed = 'e'; end
    if nargin < 3, rank = 1; end
    [~, counts] = letter_frequency(c);
    [topCounts, order] = sort(counts, 'descend');
    topLetters = char(order + double('a') - 1);
    kGuess = mod(double(topLetters(rank)) - double(lower(assumed)), 26);
end
