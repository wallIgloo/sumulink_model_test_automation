function st_run_after_harness()
%ST_RUN_AFTER_HARNESS
% Harness가 이미 생성되어 있는 상태에서
% 이후 단계들을 순서대로 실행합니다.
%
% 1. Harness 설정
% 2. Signal Editor 설정
% 3. Test Assessment 설정
% 4. Test Manager 생성
% 5. 옵션에 따라 생성된 Test Case 전체 실행
%
% cfg.RunGeneratedTests
%   false : Test Manager 생성까지만 수행
%   true  : Test Manager 생성 후 Enabled Test Case 전체 실행

cfg = st_config();


%% ============================================================
% 1. Harness 설정
%% ============================================================

fprintf('\n=== 1/4 Harness 설정 ===\n');

R1 = st_configure_harnesses();

if any(strcmp(R1.Status, 'FAIL'))

    error( ...
        ['Harness 설정에서 실패 항목이 있습니다. ' ...
         'HarnessConfigResult를 확인하세요.']);
end


%% ============================================================
% 2. Signal Editor 설정
%% ============================================================

fprintf('\n=== 2/4 Signal Editor 설정 ===\n');

R2 = st_configure_signal_editors();

if any(strcmp(R2.Status, 'FAIL'))

    error( ...
        ['Signal Editor 설정에서 실패 항목이 있습니다. ' ...
         'SignalEditorResult를 확인하세요.']);
end


%% ============================================================
% 3. Test Assessment 설정
%% ============================================================

fprintf('\n=== 3/4 Test Assessment 설정 ===\n');

R3 = st_configure_assessments();

if any(strcmp(R3.Status, 'FAIL'))

    error( ...
        ['Test Assessment 설정에서 실패 항목이 있습니다. ' ...
         'AssessmentResult를 확인하세요.']);
end


%% ============================================================
% 4. Test Manager 생성
%% ============================================================

fprintf('\n=== 4/4 Test Manager 생성 ===\n');

R4 = st_create_test_manager();

if any(strcmp(R4.Status, 'FAIL'))

    error( ...
        ['Test Manager 생성에서 실패 항목이 있습니다. ' ...
         'TestManagerResult를 확인하세요.']);
end


%% ============================================================
% 5. 생성된 Test Case 실행
%% ============================================================

if cfg.RunGeneratedTests

    fprintf('\n=== Generated Test Cases 실행 ===\n');

    try

        resultObj = st_run_generated_tests(); %#ok<NASGU>

    catch ME

        error( ...
            '생성된 Test Case 실행 중 오류가 발생했습니다: %s', ...
            ME.message);
    end

else

    fprintf('\n=== Test 실행 SKIP ===\n');
    fprintf('cfg.RunGeneratedTests = false\n');

end


%% ============================================================
% 완료
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('After-Harness 자동화 완료\n');
fprintf('============================================\n');

if cfg.RunGeneratedTests

    fprintf('Test execution : RUN\n');

else

    fprintf('Test execution : SKIP\n');

end

fprintf('============================================\n');

end