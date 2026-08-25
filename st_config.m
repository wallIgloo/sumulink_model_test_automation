function cfg = st_config()
%ST_CONFIG Common settings for Simulink Test automation.
% Edit this file first.

rootDir = fileparts(mfilename('fullpath'));


%% ============================================================
% Model
%% ============================================================

cfg.TopModel = 'TEST_TARGET_MODEL_NAME';


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
% Assessment - Verify 대상
%% ============================================================

% true:
%   Harness 최상위 Outport에 연결된 신호 중
%   Test Assessment Input Symbol로 존재하는 신호만 verify
%
% false:
%   Test Assessment의 모든 Input Data Symbol을 verify
cfg.VerifyHarnessOutportsOnly = true;


%% ============================================================
% Assessment - Bus 배열 처리
%% ============================================================

% true:
%   동일 Bus 구조가 배열로 반복될 때 첫 번째 Bus 요소만 verify
%
% 예:
%   a(1,1).aa
%   a(1,1).ab
%
% false:
%   Bus 배열의 모든 요소를 verify
%
% 일반 numeric 배열에는 영향을 주지 않습니다.
cfg.VerifyFirstBusElementOnly = true;


%% ============================================================
% Assessment - Verify 시점
%% ============================================================

% false:
%   기존 방식 유지
%   step1 -> step2 transition = true
%
% true:
%   ExpectedValueSampleTime 이후 step2로 이동
%   step1 -> step2 transition = after(ExpectedValueSampleTime, sec)
%
% 주의:
%   true로 사용할 경우 HarnessStopTime은
%   ExpectedValueSampleTime보다 크게 두는 것을 권장합니다.
%   예: SampleTime=0.01이면 StopTime=0.02
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
% Test Execution
%% ============================================================

% true:
%   Test Manager 생성 후 Enabled Test Case 전체 실행
%
% false:
%   Test Manager 생성까지만 수행
cfg.RunGeneratedTests = false;


%% ============================================================
% Expected Value Auto Update
%% ============================================================

% true:
%   Test 실행 후 실패한 Iteration에서
%   ExpectedValueSampleTime 시점의 실제 Harness Outport 값을 읽고
%   verify(... == RHS)의 RHS가 실제값과 다를 때 자동 갱신
%
% false:
%   Expected value 자동 갱신 안 함
%
% 안전을 위해 기본값은 false를 권장합니다.
cfg.AutoUpdateExpectedOnFail = false;


% Expected value를 가져올 simulation time [sec]
cfg.ExpectedValueSampleTime = 0.01;


% Expected value가 갱신된 뒤 Test File 전체를 한 번 더 실행
cfg.RerunAfterExpectedUpdate = true;


%% ============================================================
% Execution
%% ============================================================

cfg.OnlyEnabled = true;


%% ============================================================
% Result
%% ============================================================

cfg.ResultDir = ...
    fullfile(rootDir, 'result');

end
