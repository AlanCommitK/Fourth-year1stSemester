function p = caesar_decrypt(c, k)
%CAESAR_DECRYPT  Inverse Caesar cipher  p = D(k,C) = (C - k) mod 26.
    p = caesar_encrypt(c, -k);
end
