function st_run_from_harness()
%ST_RUN_FROM_HARNESS
% Harness 생성부터 Test Manager 구성 및 테스트 실행까지
% 전체 자동화를 순서대로 수행합니다.
%
% 실행 순서:
%
%   1. Pre-Validate
%      - CUTPath 존재 여부 확인
%      - 대상이 Subsystem인지 확인
%
%   2. Harness 생성
%
%   3. Harness 설정
%
%   4. Signal Editor 설정
%
%   5. Test Assessment 설정
%
%   6. Test Manager 생성
%
%   7. cfg.RunGeneratedTests == true인 경우
%      생성된 Enabled Test Case 전체 실행
%
%
% 사용:
%
%   st_run_from_harness
%
%
% 주의:
%
%   이 함수는 Harness가 아직 생성되지 않은 상태에서
%   시작하는 전체 자동화용입니다.
%
%   Harness가 이미 존재하는 경우에는
%
%       st_run_after_harness
%
%   를 사용합니다.


cfg = st_config();


fprintf('\n');
fprintf('============================================\n');
fprintf('Simulink Test Full Automation\n');
fprintf('Model : %s\n', cfg.TopModel);
fprintf('============================================\n');


%% ============================================================
% 1. Pre-Validate
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('[1/7] Pre-Validate CUT Paths\n');
fprintf('============================================\n');


R0 = ...
    st_pre_validate_targets();


if st_result_has_fail(R0)

    error( ...
        ['Pre-Validation에 실패한 CUT가 있습니다. ' ...
         'PreValidationResult를 확인하세요.']);
end


fprintf('\n');
fprintf('Pre-Validation 완료\n');


%% ============================================================
% 2. Harness 생성
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('[2/7] Create Harnesses\n');
fprintf('============================================\n');


R1 = ...
    st_create_harnesses();


if st_result_has_fail(R1)

    error( ...
        ['Harness 생성에 실패한 CUT가 있습니다. ' ...
         'HarnessCreateResult를 확인하세요.']);
end


fprintf('\n');
fprintf('Harness 생성 완료\n');


%% ============================================================
% 3. Harness 설정
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('[3/7] Configure Harnesses\n');
fprintf('============================================\n');


R2 = ...
    st_configure_harnesses();


if st_result_has_fail(R2)

    error( ...
        ['Harness 설정에 실패한 CUT가 있습니다. ' ...
         'HarnessConfigResult를 확인하세요.']);
end


fprintf('\n');
fprintf('Harness 설정 완료\n');


%% ============================================================
% 4. Signal Editor 설정
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('[4/7] Configure Signal Editor\n');
fprintf('============================================\n');


R3 = ...
    st_configure_signal_editors();


if st_result_has_fail(R3)

    error( ...
        ['Signal Editor 설정에 실패한 CUT가 있습니다. ' ...
         'SignalEditorResult를 확인하세요.']);
end


fprintf('\n');
fprintf('Signal Editor 설정 완료\n');


%% ============================================================
% 5. Test Assessment 설정
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('[5/7] Configure Test Assessment\n');
fprintf('============================================\n');


R4 = ...
    st_configure_assessments();


if st_result_has_fail(R4)

    error( ...
        ['Test Assessment 설정에 실패한 CUT가 있습니다. ' ...
         'AssessmentResult를 확인하세요.']);
end


fprintf('\n');
fprintf('Test Assessment 설정 완료\n');


%% ============================================================
% 6. Test Manager 생성
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('[6/7] Create Test Manager\n');
fprintf('============================================\n');


R5 = ...
    st_create_test_manager();


if st_result_has_fail(R5)

    error( ...
        ['Test Manager 생성에 실패한 항목이 있습니다. ' ...
         'TestManagerResult를 확인하세요.']);
end


fprintf('\n');
fprintf('Test Manager 생성 완료\n');


%% ============================================================
% 7. 생성된 Test Case 실행
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('[7/7] Run Generated Tests\n');
fprintf('============================================\n');


if cfg.RunGeneratedTests

    fprintf('cfg.RunGeneratedTests = true\n');
    fprintf('생성된 Enabled Test Case를 실행합니다.\n');


    try

        resultObj = ...
            st_run_generated_tests(); %#ok<NASGU>


        fprintf('\n');
        fprintf('생성된 Test Case 실행 완료\n');


    catch ME

        fprintf('\n');
        fprintf('Test 실행 실패\n');
        fprintf('Message : %s\n', ME.message);


        error( ...
            '생성된 Test Case 실행 중 오류가 발생했습니다.');
    end


else

    fprintf('cfg.RunGeneratedTests = false\n');
    fprintf('Test Case 실행을 건너뜁니다.\n');

end


%% ============================================================
% 완료
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('Full Automation Complete\n');
fprintf('============================================\n');

fprintf('Model              : %s\n', ...
    cfg.TopModel);

fprintf('Pre-Validation     : COMPLETE\n');
fprintf('Harness Creation   : COMPLETE\n');
fprintf('Harness Configure  : COMPLETE\n');
fprintf('Signal Editor      : COMPLETE\n');
fprintf('Test Assessment    : COMPLETE\n');
fprintf('Test Manager       : COMPLETE\n');


if cfg.RunGeneratedTests

    fprintf('Test Execution      : COMPLETE\n');

else

    fprintf('Test Execution      : SKIPPED\n');
end


fprintf('============================================\n');

end


%% ============================================================
% Result FAIL 여부 확인
%% ============================================================

function tf = st_result_has_fail(R)
%ST_RESULT_HAS_FAIL
% 각 자동화 함수가 반환한 Result Table에
% FAIL 상태가 존재하는지 안전하게 확인합니다.


tf = false;


%% 결과가 없는 경우

if isempty(R)

    return;
end


%% Table이 아닌 경우

if ~istable(R)

    return;
end


%% Status 컬럼이 없는 경우

if ~ismember( ...
        'Status', ...
        R.Properties.VariableNames)

    return;
end


%% FAIL 확인

tf = ...
    any( ...
        strcmp( ...
            R.Status, ...
            'FAIL'));

end