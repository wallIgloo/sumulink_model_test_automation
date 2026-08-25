function cfg = st_config()
%ST_CONFIG Common settings for Simulink Test automation.
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

%% Test execution

% true  : Test Manager 생성 후 Enabled Test Case 전체 실행
% false : Test Manager까지만 생성
cfg.RunGeneratedTests = false;

%% Harness / Scenario
cfg.HarnessStopTime = '0.01';
cfg.SignalEditorSampleTime = '0.01';

% Assessment verify target mode
% true  : Verify only Assessment Input symbols that correspond to
%         top-level Harness Outport blocks/signals.
% false : Verify every Input Data Symbol registered in Test Assessment.
cfg.VerifyHarnessOutportsOnly = true;

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