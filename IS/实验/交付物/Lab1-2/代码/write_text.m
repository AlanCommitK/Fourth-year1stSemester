function write_text(file, t)
%WRITE_TEXT  Write a char row to a text file (UTF-8, no trailing newline).
    fid = fopen(file, 'w', 'n', 'UTF-8');
    if fid < 0, error('write_text:open', 'Cannot open %s', file); end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', t);
end
