function cfg = lab_config()
%LAB_CONFIG  Group data used by the task scripts.  Edit here only.
    cfg.guid1    = 2959453;            % Ke Chen
    cfg.guid2    = 2959466;            % Mingxiang Bian
    cfg.name1    = 'KeChen';           % first name + last name, no space
    cfg.name2    = 'MingxiangBian';
    here         = fileparts(mfilename('fullpath'));
    cfg.codeDir  = here;
    cfg.figDir   = fullfile(here, '..', 'figures');
    cfg.outDir   = fullfile(here, '..', 'output');
    cfg.plainFile  = fullfile(here, 'plaintext.txt');
    cfg.cipherFile = fullfile(cfg.outDir, 'ciphertext.txt');
    if ~exist(cfg.figDir, 'dir'), mkdir(cfg.figDir); end
    if ~exist(cfg.outDir, 'dir'), mkdir(cfg.outDir); end
end
