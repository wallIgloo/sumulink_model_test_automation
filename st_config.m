function cfg = st_config()
%ST_CONFIG Common settings for Simulink Test automation.
% Edit this file first.

rootDir = fileparts(mfilename('fullpath'));


%% ============================================================
% Runtime target model
%% ============================================================

cfg.RuntimeTargetFile = ...
    fullfile(rootDir, 'runtime_target.mat');

cfg.TopModel = ...
    'TEST_TARGET_MODEL_NAME';

cfg.ModelFile = '';
cfg.HasRuntimeTarget = false;

if isfile(cfg.RuntimeTargetFile)

    S = load(cfg.RuntimeTargetFile);

    if isfield(S, 'TopModel') && ...
            isfield(S, 'ModelFile')

        topModel = ...
            strtrim(char(string(S.TopModel)));

        modelFile = ...
            strtrim(char(string(S.ModelFile)));

        if ~isempty(topModel) && ...
                ~isempty(modelFile)

            cfg.TopModel = topModel;
            cfg.ModelFile = modelFile;
            cfg.HasRuntimeTarget = true;
        end
    end
end


%% ============================================================
% Target model / CUT path finder
%% ============================================================

% Default assumes this automation folder is placed one level below
% the folder that contains the target Simulink model(s).
% Change this when the model files live elsewhere.
cfg.ModelSearchRoot = ...
    fileparts(rootDir);

% true  : search subfolders recursively
% false : search only ModelSearchRoot
cfg.ModelSearchRecursive = true;

% Folder names ignored while searching for .slx / .mdl files.
cfg.ModelSearchExcludeFolders = { ...
    '.git', ...
    'slprj', ...
    'result'};


%% ============================================================
% Management Excel
%% ============================================================

cfg.ManagementExcel = ...
    fullfile(rootDir, 'TestManagement.xlsx');

cfg.ManagementSheet = 'Targets';


%% ============================================================
% Harness
%% ============================================================

cfg.HarnessStopTime = '0.01';


%% ============================================================
% Signal Editor
%% ============================================================

cfg.SignalEditorSampleTime = '0.01';


%% ============================================================
% Assessment - Verify target
%% ============================================================

% true:
%   Verify only Test Assessment Input symbols that correspond to
%   top-level Harness Outport signals.
%
% false:
%   Verify every Input Data Symbol registered in Test Assessment.
cfg.VerifyHarnessOutportsOnly = true;


%% ============================================================
% Assessment - Bus array handling
%% ============================================================

% true:
%   When the same Bus structure is repeated as an array, verify only
%   the first Bus instance.
%
% Example:
%   a(1,1).aa
%   a(1,1).ab
%
% false:
%   Verify every Bus array element.
%
% Numeric arrays inside a Bus leaf are still verified completely.
cfg.VerifyFirstBusElementOnly = true;


%% ============================================================
% Assessment - Verify timing
%% ============================================================

% false:
%   step1 -> step2 transition = true
%
% true:
%   step1 -> step2 transition = after(ExpectedValueSampleTime, sec)
%
% When true, HarnessStopTime should normally be greater than
% ExpectedValueSampleTime.
cfg.VerifyAtSampleTimeOnly = false;


%% ============================================================
% Test Manager
%% ============================================================

cfg.TestFile = ...
    fullfile(rootDir, [cfg.TopModel '.mldatx']);

cfg.TestSuiteName = ...
    'New Test Suite 1';

cfg.OverwriteTestFile = false;


%% ============================================================
% Test execution
%% ============================================================

% true  : Run all generated Enabled Test Cases after Test Manager creation.
% false : Stop after Test Manager creation.
cfg.RunGeneratedTests = false;


%% ============================================================
% Expected value auto update
%% ============================================================

% true:
%   After a failed test, read the actual Harness Outport value at
%   ExpectedValueSampleTime and update the RHS of verify(... == RHS).
%
% false:
%   Do not modify expected values automatically.
cfg.AutoUpdateExpectedOnFail = false;

% Simulation time used as the expected-value sample point [sec].
cfg.ExpectedValueSampleTime = 0.01;

% Run the Test File again after at least one expected value is updated.
cfg.RerunAfterExpectedUpdate = true;


%% ============================================================
% Execution
%% ============================================================

% If Enabled exists in TestManagement.xlsx:
% true  -> process Enabled rows only
% false -> process all rows
cfg.OnlyEnabled = true;


%% ============================================================
% Result
%% ============================================================

cfg.ResultDir = ...
    fullfile(rootDir, 'result');

end
