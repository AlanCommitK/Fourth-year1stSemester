function [candidates, chi2] = caesar_bruteforce(c)
%CAESAR_BRUTEFORCE  Try every key k = 0..25 on a Caesar ciphertext.
%   candidates{k+1} is the text decrypted with key k.  The correct key is
%   chosen by visual inspection (the one candidate that reads as English).
%   chi2(k+1) is an optional automatic score: the chi-squared distance
%   between the candidate's letter counts and English letter frequencies.
%   The smallest chi2 marks the most English-like candidate, so the visual
%   choice can be cross-checked without a human.
    candidates = cell(26, 1);
    chi2       = zeros(26, 1);
    E = english_frequency() / 100;
    for k = 0:25
        d = caesar_decrypt(c, k);
        candidates{k + 1} = d;
        [~, counts, n] = letter_frequency(d);
        expected = n * E;
        chi2(k + 1) = sum((counts - expected).^2 ./ expected);
    end
end
