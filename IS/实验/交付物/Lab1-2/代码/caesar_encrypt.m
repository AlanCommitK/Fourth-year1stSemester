function c = caesar_encrypt(p, k)
%CAESAR_ENCRYPT  General Caesar cipher  C = E(k,p) = (p + k) mod 26.
%   Letters are numbered a=0 ... z=25 (handout, Figure 1) and shifted by k.
%   Upper/lower case is preserved; spaces, digits and punctuation are copied
%   unchanged so that brute-force candidates stay readable (Task 2).
%   k may be any integer, including negative values (used for decryption).
    p  = char(p);
    c  = p;
    up = p >= 'A' & p <= 'Z';
    lo = p >= 'a' & p <= 'z';
    c(up) = char(mod(double(p(up)) - double('A') + k, 26) + double('A'));
    c(lo) = char(mod(double(p(lo)) - double('a') + k, 26) + double('a'));
end
