function print_matrix(M, title)
%PRINT_MATRIX  Print a Playfair matrix, showing the I cell as I/J (Figure 2 style).
    if nargin > 1, fprintf('%s\n', title); end
    for r = 1:5
        cells = cellstr(M(r, :).');
        cells(strcmp(cells, 'I')) = {'I/J'};
        fprintf('    %s\n', strjoin(cellfun(@(x) sprintf('%-4s', x), cells, ...
                'UniformOutput', false), ''));
    end
end
