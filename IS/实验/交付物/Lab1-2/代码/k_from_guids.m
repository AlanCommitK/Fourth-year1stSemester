function [kmod, k, guidSum] = k_from_guids(guid1, guid2)
%K_FROM_GUIDS  Caesar key from the two group members' GUIDs (lab handout, Task 1).
%   Step 1: add the two GUIDs.  Step 2: k = sum of the decimal digits of that
%   sum, and kmod = mod(k, 26).
%   GUIDs may be given as numbers (2959453) or as text ('2959453C'); any
%   non-digit characters such as the trailing surname letter are ignored.
%
%   Example (handout):  k_from_guids(2429202, 2429222)  ->  kmod = 9, k = 35
    g1 = local_digits(guid1);
    g2 = local_digits(guid2);
    guidSum = g1 + g2;
    digits  = num2str(guidSum, '%d') - '0';
    k       = sum(digits);
    kmod    = mod(k, 26);
end

function g = local_digits(guid)
    if isnumeric(guid)
        g = double(guid);
    else
        s = char(guid);
        g = str2double(s(s >= '0' & s <= '9'));
    end
    if isnan(g) || g < 0 || g ~= fix(g)
        error('k_from_guids:badGuid', 'GUID must contain a non-negative integer.');
    end
end
