%% lab3_ex3B_build_models.m
% Computer Lab Exercise 3, Exercise 3B (Sections 4.1 and 4.4).
% Builds the two Simulink models of the ventilation-rate loop programmatically,
% saves them next to this script and exports the block diagrams as PNG files.
%
%   ventilation_P.slx : proportional controller, Gain block, Kp = 0.1          [4.1]
%   ventilation_I.slx : integral controller kI/(1 - z^-1), Discrete Filter,
%                       kI = 0.1                                               [4.4]
%
% Plant (fan voltage u -> ventilation rate y):  Gp(z) = 3 z^-1 / (1 - 0.6 z^-1)
% Sample time Ts = 1 s (not stated in the handout; assumed).
% Set-point: 300 m^3/h, applied as a step at t = 0.
% The gains stored in the models are the handout values; the study script
% (lab3_ex3B_simulate.m) overrides them run by run with SimulationInput objects.

here   = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
figDir = fullfile(here, '..', 'figures');
if ~exist(figDir, 'dir'), mkdir(figDir); end

build_loop('ventilation_P', 'P', here, figDir);
build_loop('ventilation_I', 'I', here, figDir);
fprintf('Models saved in %s\n', here);

%% ------------------------------------------------------------------ local
function build_loop(mdl, ctrlType, here, figDir)
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);
set_param(mdl, 'Creator', 'ChenKe', ...
    'Description', 'UESTCHN4002 Computer Lab 3, Exercise 3B: ventilation-rate control loop');
ws = get_param(mdl, 'ModelWorkspace');
ws.assignin('Ts', 1);        % sample time (s)
ws.assignin('r_set', 300);   % desired ventilation rate (m^3/h)

fs = 12;                     % block-name font size, for a legible diagram
add_block('simulink/Sources/Step', [mdl '/Desired rate'], ...
    'Time', '0', 'Before', '0', 'After', 'r_set', 'SampleTime', 'Ts', ...
    'Position', [40 190 80 230], 'FontSize', fs);
add_block('simulink/Math Operations/Sum', [mdl '/Sum'], ...
    'Inputs', '|+-', 'IconShape', 'round', ...
    'Position', [140 195 170 225], 'FontSize', fs);
switch ctrlType
    case 'P'
        ctrl = 'P controller';
        add_block('simulink/Math Operations/Gain', [mdl '/' ctrl], ...
            'Gain', '0.1', 'Position', [230 190 290 230], 'FontSize', fs);
    case 'I'
        ctrl = 'I controller';
        add_block('simulink/Discrete/Discrete Filter', [mdl '/' ctrl], ...
            'Numerator', '[0.1]', 'Denominator', '[1 -1]', 'SampleTime', 'Ts', ...
            'Position', [220 185 310 235], 'FontSize', fs);
end
add_block('simulink/Discrete/Discrete Filter', [mdl '/Fan and chamber Gp'], ...
    'Numerator', '[0 3]', 'Denominator', '[1 -0.6]', 'SampleTime', 'Ts', ...
    'Position', [400 185 510 235], 'FontSize', fs);
add_block('simulink/Sinks/Scope', [mdl '/Scope y'], ...
    'Position', [650 190 690 230], 'FontSize', fs);
add_block('simulink/Sinks/To Workspace', [mdl '/Log y'], ...
    'VariableName', 'y', 'SaveFormat', 'Timeseries', 'SampleTime', 'Ts', ...
    'Position', [640 275 720 305], 'FontSize', fs);
add_block('simulink/Sinks/Scope', [mdl '/Scope u'], ...
    'Position', [650 100 690 140], 'FontSize', fs);
add_block('simulink/Sinks/To Workspace', [mdl '/Log u'], ...
    'VariableName', 'u', 'SaveFormat', 'Timeseries', 'SampleTime', 'Ts', ...
    'Position', [640 35 720 65], 'FontSize', fs);

% signal lines
h = add_line(mdl, 'Desired rate/1', 'Sum/1');            set_param(h, 'Name', 'r');
h = add_line(mdl, 'Sum/1', [ctrl '/1']);                 set_param(h, 'Name', 'e');
h = add_line(mdl, [ctrl '/1'], 'Fan and chamber Gp/1');  set_param(h, 'Name', 'u (fan voltage)');
h = add_line(mdl, 'Fan and chamber Gp/1', 'Scope y/1');  set_param(h, 'Name', 'y (ventilation rate)');
add_line(mdl, [ctrl '/1'], 'Scope u/1', 'autorouting', 'smart');
add_line(mdl, [ctrl '/1'], 'Log u/1', 'autorouting', 'smart');
add_line(mdl, 'Fan and chamber Gp/1', 'Log y/1', 'autorouting', 'smart');
add_line(mdl, 'Fan and chamber Gp/1', 'Sum/2', 'autorouting', 'smart');

% fixed-step discrete solver with step Ts
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
    'FixedStep', 'Ts', 'StopTime', '60', 'ReturnWorkspaceOutputs', 'on');

save_system(mdl, fullfile(here, [mdl '.slx']));
print(['-s' mdl], '-dpng', '-r300', fullfile(figDir, ['ex3B_model_' ctrlType '.png']));
fprintf('Built %s (%s control)\n', mdl, ctrlType);
end
