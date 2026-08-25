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
%
% Required columns:
%   CUTName
%   CUTPath
%   HarnessName
%   TestCaseName
%
% Optional columns:
%   No
%   Enabled
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
%
% 권장:
%   true
cfg.VerifyHarnessOutportsOnly = true;


%% ============================================================
% Assessment - Bus 배열 처리
%% ============================================================

% false:
%   Bus 배열의 모든 요소를 verify
%
% 예:
%
%   a(1,1).aa
%   a(1,1).ab
%   a(1,2).aa
%   a(1,2).ab
%
%
% true:
%   동일한 Bus 구조가 배열로 반복되는 경우
%   첫 번째 Bus 요소만 verify
%
% 예:
%
%   a(1,1).aa
%   a(1,1).ab
%
%
% 주의:
%   일반 numeric 배열에는 영향을 주지 않습니다.
%
%   예:
%       b = [1 x 3 double]
%
%   는 true인 경우에도:
%
%       verify(b(1) == 0);
%       verify(b(2) == 0);
%       verify(b(3) == 0);
%
%   모두 생성됩니다.
%
% Nested Bus 배열에도 동일한 규칙을 적용합니다.
cfg.VerifyFirstBusElementOnly = true;


%% ============================================================
% Test Manager
%% ============================================================

cfg.TestFile = ...
    fullfile(rootDir, [cfg.TopModel '.mldatx']);

cfg.TestSuiteName = ...
    'New Test Suite 1';


% false:
%   기존 Test File 보호
%
% true:
%   기존 Test File을 새로 생성
cfg.OverwriteTestFile = false;


%% ============================================================
% Test Execution
%% ============================================================

% true:
%   Test Manager 생성 후
%   생성된 Enabled Test Case 전체 실행
%
% false:
%   Test Manager 생성까지만 수행
cfg.RunGeneratedTests = false;


%% ============================================================
% Execution
%% ============================================================

% Excel에 Enabled 컬럼이 존재하는 경우:
%
% true:
%   Enabled == true 행만 처리
%
% false:
%   전체 행 처리
%
% Enabled 컬럼 자체가 없으면 전체 행 처리
cfg.OnlyEnabled = true;


%% ============================================================
% Result
%% ============================================================

cfg.ResultDir = ...
    fullfile(rootDir, 'result');

end