%TASK4_PLAYFAIR  Task 4: Playfair cipher demonstrations required by the handout.
cfg = lab_config();
fprintf('\n===== Task 4: Playfair cipher =====\n');

% 1) keyword 'monarchy' must reproduce Figure 2 of the handout
M = playfair_matrix('monarchy');
print_matrix(M, 'Matrix for keyword ''monarchy'':');
fig2 = ['MONAR'; 'CHYBD'; 'EFGIK'; 'LPQST'; 'UVWXZ'];
fprintf('Matches Figure 2 of the handout: %s\n\n', mat2str(isequal(M, fig2)));

% 2) 'balloon' with 'monarchy' -> IB SU PM NA, then decrypt
c = playfair('monarchy', 'balloon');
fprintf('Expected IB SU PM NA: %s\n\n', mat2str(strcmp(c, 'IB SU PM NA')));

% 3) matrices for 'exceeding' and for both members' full names
print_matrix(playfair_matrix('exceeding'), 'Matrix for keyword ''exceeding'':');
fprintf('\n');
print_matrix(playfair_matrix(cfg.name1), sprintf('Matrix for keyword ''%s'':', cfg.name1));
fprintf('\n');
print_matrix(playfair_matrix(cfg.name2), sprintf('Matrix for keyword ''%s'':', cfg.name2));

% 4) the special cases the TA will test
fprintf('\nRule checks with keyword ''monarchy'':\n');
cases = {'hello world', 'LL split by X; now odd, so final X added'; ...
         'Jazz',        'J becomes I; ZZ split; now odd, so final X added'; ...
         'instruments', 'odd length: final X added'; ...
         'Meet me at the school house', 'OO split (EE, TT fall across pairs); spaces removed'; ...
         'box',         'final single letter is X: handout rule gives XX'; ...
         'taxxi',       'XX inside one pair: handout rule gives XX again'};
for i = 1:size(cases, 1)
    [ct, pr] = playfair_encrypt('monarchy', cases{i, 1});
    back = playfair_decrypt('monarchy', ct);
    fprintf('  %-28s  %-35s -> %-35s  round trip %s   [%s]\n', cases{i, 1}, ...
            pairs_to_text(pr), ct, mat2str(strcmp(back, pairs_to_text(pr))), cases{i, 2});
end
