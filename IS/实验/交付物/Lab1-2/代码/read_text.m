function t = read_text(file)
%READ_TEXT  Read a text file as one char row; line breaks become spaces.
    t = fileread(file);
    t = regexprep(t, '\r?\n', ' ');
    t = strtrim(t);
end
