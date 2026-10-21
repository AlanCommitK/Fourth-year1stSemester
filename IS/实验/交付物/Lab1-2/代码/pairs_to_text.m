function s = pairs_to_text(pairs)
%PAIRS_TO_TEXT  N x 2 char array of digrams -> 'AB CD EF'.
    s = strjoin(cellstr(pairs), ' ');
end
