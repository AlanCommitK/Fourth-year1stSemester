function test_lab()
%TEST_LAB  Self-test against independently computed reference results.
%   Run before the lab session; every line must print PASS.
    n = 0; bad = 0;
    function check(name, cond)
        n = n + 1;
        if cond, fprintf('PASS  %s\n', name);
        else,    fprintf('FAIL  %s\n', name); bad = bad + 1; end
    end
    [km, k] = k_from_guids(2429202, 2429222);
    check('handout k example (35 -> 9)', k == 35 && km == 9);
    [km, k, s] = k_from_guids(2959453, 2959466);
    check('group key: 5918919 -> 42 -> 16', s == 5918919 && k == 42 && km == 16);
    check('GUID given as text with letter', k_from_guids('2959453C', '2959466B') == 16);
    check('Caesar k=3: "Hello, World" -> "Khoor, Zruog"', ...
          strcmp(caesar_encrypt('Hello, World', 3), 'Khoor, Zruog'));
    check('Caesar wraps: xyz -> abc (k=3)', strcmp(caesar_encrypt('xyz', 3), 'abc'));
    check('Caesar inverse', strcmp(caesar_decrypt(caesar_encrypt('Attack at Dawn!', 16), 16), 'Attack at Dawn!'));
    [p, c, t] = letter_frequency('Aab!');
    check('letter_frequency counts', t == 3 && c(1) == 2 && c(2) == 1 && abs(sum(p) - 100) < 1e-9);
    check('English table sums to ~100', abs(sum(english_frequency()) - 100) < 0.1);
    check('monarchy matrix = Figure 2', isequal(playfair_matrix('monarchy'), ...
          ['MONAR'; 'CHYBD'; 'EFGIK'; 'LPQST'; 'UVWXZ']));
    check('exceeding matrix', isequal(playfair_matrix('exceeding'), ...
          ['EXCDI'; 'NGABF'; 'HKLMO'; 'PQRST'; 'UVWYZ']));
    check('KeChen matrix', isequal(playfair_matrix('KeChen'), ...
          ['KECHN'; 'ABDFG'; 'ILMOP'; 'QRSTU'; 'VWXYZ']));
    check('MingxiangBian matrix', isequal(playfair_matrix('Mingxiang Bian'), ...
          ['MINGX'; 'ABCDE'; 'FHKLO'; 'PQRST'; 'UVWYZ']));
    check('keyword with J is read as I', isequal(playfair_matrix('jam'), playfair_matrix('iam')));
    check('balloon -> IB SU PM NA', strcmp(playfair_encrypt('monarchy', 'balloon'), 'IB SU PM NA'));
    check('decrypt IBSUPMNA -> BA LX LO ON', strcmp(playfair_decrypt('monarchy', 'ibsupmna'), 'BA LX LO ON'));
    ref = {'hello world', 'HE LX LO WO RL DX', 'CF SU PM VN MT BZ'; ...
           'Jazz',        'IA ZX ZX',          'SB UZ UZ'; ...
           'instruments', 'IN ST RU ME NT SX', 'GA TL MZ CL RQ XA'; ...
           'Meet me at the school house', 'ME ET ME AT TH ES CH OX OL HO US EX', ...
                          'CL KL CL RS PD IL HY AV MP FH XL IU'; ...
           'ax',          'AX',                'BA'; ...
           'box',         'BO XX',             'HA ZZ'; ...
           'taxxi',       'TA XX XI',          'SR ZZ AS'; ...
           'xx',          'XX XX',             'ZZ ZZ'; ...
           'JJ',          'IX IX',             'SA SA'};
    for i = 1:size(ref, 1)
        [c, pr] = playfair_encrypt('monarchy', ref{i, 1});
        check(sprintf('prepare  "%s"', ref{i, 1}), strcmp(pairs_to_text(pr), ref{i, 2}));
        check(sprintf('encrypt  "%s"', ref{i, 1}), strcmp(c, ref{i, 3}));
        check(sprintf('decrypt  "%s"', ref{i, 1}), strcmp(playfair_decrypt('monarchy', c), ref{i, 2}));
    end
    [c, pr] = playfair_encrypt('monarchy', 'taxxi box', 'qfill');
    check('qfill mode uses Q for XX', strcmp(pairs_to_text(pr), 'TA XQ XI BO XQ') ...
          && strcmp(playfair_decrypt('monarchy', c), 'TA XQ XI BO XQ'));
    % random round trips
    rng(1);
    ok = true;
    for r = 1:500
        kw = char(randi([65 90], 1, randi(12)));
        pt = char(randi([65 90], 1, randi(40)));
        [c, pr] = playfair_encrypt(kw, pt);                 % handout rules
        same = pr(:, 1) == pr(:, 2);
        ok = ok && strcmp(playfair_decrypt(kw, c), pairs_to_text(pr)) ...
                && all(pr(same, 1) == 'X');                 % only XX may repeat
        [c, pr] = playfair_encrypt(kw, pt, 'qfill');        % optional variant
        ok = ok && strcmp(playfair_decrypt(kw, c), pairs_to_text(pr)) ...
                && ~any(pr(:, 1) == pr(:, 2));
    end
    check('500 random keyword/text pairs round-trip in both modes', ok);
    fprintf('\n%d checks, %d failed\n', n, bad);
    if bad > 0, error('test_lab:failed', '%d checks failed', bad); end
end
