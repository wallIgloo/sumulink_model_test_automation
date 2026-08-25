function cfg = st_config()
%ST_CONFIG Existing-harness automation common settings.
% Edit this file first.

rootDir = fileparts(mfilename('fullpath'));

%% Model
cfg.TopModel = 'TEST_TARGET_MODEL_NAME';

%% Management Excel
% Required logical columns:
%   CUTName, CUTPath, HarnessName, TestCaseName
% Optional:
%   No, Enabled
cfg.ManagementExcel = fullfile(rootDir, 'TestManagement.xlsx');
cfg.ManagementSheet = 'Targets';

%% Harness / Scenario
cfg.HarnessStopTime = '0.01';
cfg.SignalEditorSampleTime = '0.01';

% Assessment verify target mode
% false : Verify only direct CUT Outports that also exist as Assessment Inputs.
% true  : Verify every Input Data Symbol registered in the Test Assessment block.
cfg.VerifyAllAssessmentInputs = true;

%% Test Manager
cfg.TestFile = fullfile(rootDir, [cfg.TopModel '.mldatx']);
cfg.TestSuiteName = 'New Test Suite 1';

% false: protect an existing test file.
% true : recreate/overwrite the test file.
cfg.OverwriteTestFile = false;

%% Execution
% If the Excel file has an Enabled column, only true rows are processed.
% If the column does not exist, all rows are processed.
cfg.OnlyEnabled = true;

%% Result folder
cfg.ResultDir = fullfile(rootDir, 'result');

end
