function ic = index_of_coincidence(t)
%INDEX_OF_COINCIDENCE  Probability that two letters drawn at random (without
%   replacement) from the text are the same:  IC = sum n_i(n_i-1) / (N(N-1)).
%   English text gives about 0.066; uniformly random letters give 1/26 = 0.0385.
%   Any monoalphabetic cipher (including Caesar) leaves IC unchanged, because
%   it only relabels the letters; a cipher that flattens the profile lowers it.
    [~, counts, N] = letter_frequency(t);
    ic = sum(counts .* (counts - 1)) / (N * (N - 1));
end
