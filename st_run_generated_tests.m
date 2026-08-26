function [resultObj, updateResult] = st_run_generated_tests()
%ST_RUN_GENERATED_TESTS
% 생성된 Test File의 Enabled Test Case를 실행합니다.
%
% cfg.AutoUpdateExpectedOnFail == false
%   1회 실행 후 종료
%
% cfg.AutoUpdateExpectedOnFail == true
%   1. Harness Outport signal logging 준비
%   2. Test File 실행
%   3. 실패한 Iteration에서 0.01초 등의 기준 시점 실제값 추출
%   4. verify(... == RHS)의 RHS 자동 갱신
%   5. cfg.RerunAfterExpectedUpdate == true이고 갱신값이 있으면 재실행
%
% 첫 번째 출력 resultObj는 최종 실행 결과입니다.
% 재실행하지 않으면 최초 실행 결과를 반환합니다.

cfg = st_require_runtime_target();

updateResult = table();


%% ============================================================
% Test File 확인
%% ============================================================

if ~isfile(cfg.TestFile)

    error( ...
        'Test File을 찾을 수 없습니다: %s', ...
        cfg.TestFile);
end


tf = ...
    sltest.testmanager.TestFile( ...
        cfg.TestFile);


fprintf('\n');
fprintf('============================================\n');
fprintf('Run Generated Tests\n');
fprintf('Test File : %s\n', cfg.TestFile);
fprintf('============================================\n');


%% ============================================================
% Auto Expected Update를 위한 logging 준비
%% ============================================================

if cfg.AutoUpdateExpectedOnFail

    fprintf('\nExpected value auto update 준비\n');
    fprintf('Sample time : %.17g sec\n', ...
        cfg.ExpectedValueSampleTime);

    st_prepare_expected_value_logging( ...
        cfg, ...
        tf);
end


%% ============================================================
% 1차 실행
%% ============================================================

fprintf('\nEnabled Test Case 실행 시작...\n');

resultObj = ...
    run(tf);

fprintf('Enabled Test Case 실행 완료\n');


%% ============================================================
% Auto Expected Update OFF
%% ============================================================

if ~cfg.AutoUpdateExpectedOnFail

    return;
end


%% ============================================================
% Expected value 갱신
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('Update Expected Values From Test Results\n');
fprintf('============================================\n');


updateResult = ...
    st_update_expected_from_results( ...
        resultObj);


if isempty(updateResult)

    updatedTotal = 0;

else

    updatedTotal = ...
        sum(updateResult.UpdatedCount);
end


fprintf('\nExpected value updated lines : %d\n', ...
    updatedTotal);


if ~isempty(updateResult) && ...
        any(strcmp(updateResult.Status, 'FAIL'))

    warning( ...
        ['Expected value 자동 갱신에 실패한 Test Case가 있습니다. ' ...
         'ExpectedUpdateResult를 확인하세요.']);
end


%% ============================================================
% 재실행
%% ============================================================

if updatedTotal > 0 && ...
        cfg.RerunAfterExpectedUpdate

    fprintf('\n');
    fprintf('============================================\n');
    fprintf('Rerun After Expected Value Update\n');
    fprintf('============================================\n');

    resultObj = ...
        run(tf);

    fprintf('재실행 완료\n');

elseif updatedTotal == 0

    fprintf('변경할 Expected value가 없어 재실행하지 않습니다.\n');

else

    fprintf('cfg.RerunAfterExpectedUpdate = false\n');
    fprintf('Expected value 갱신 후 재실행을 건너뜁니다.\n');
end

end


%% ============================================================
% Expected Value Logging 준비
%% ============================================================

function st_prepare_expected_value_logging( ...
        cfg, ...
        tf)

T = ...
    st_load_targets( ...
        cfg.OnlyEnabled);


st_force_model_stopped( ...
    cfg.TopModel);


for i = 1:height(T)

    ownerPath = ...
        st_normalize_cut_path( ...
            T.CUTPath(i), ...
            cfg.TopModel);

    harnessName = ...
        char(T.HarnessName(i));

    try

        sltest.harness.load( ...
            ownerPath, ...
            harnessName);


        logResult = ...
            st_enable_harness_output_logging( ...
                harnessName);


        if any(strcmp(logResult.Status, 'FAIL'))

            failed = ...
                logResult( ...
                    strcmp(logResult.Status, 'FAIL'), ...
                    :);

            error( ...
                'Harness Outport logging 설정 실패: %s', ...
                char(strjoin(failed.Message, ' | ')));
        end


        save_system( ...
            cfg.TopModel);


        st_close_harness_quiet( ...
            ownerPath, ...
            harnessName);


    catch ME

        st_close_harness_quiet( ...
            ownerPath, ...
            harnessName);

        error( ...
            'Expected value logging 준비 실패 [%s]: %s', ...
            harnessName, ...
            ME.message);
    end
end


%% Test Case에서 signal logging 강제 활성화

suites = ...
    getTestSuites(tf);

for s = 1:numel(suites)

    testCases = ...
        getTestCases( ...
            suites(s));

    for c = 1:numel(testCases)

        setProperty( ...
            testCases(c), ...
            'OverrideModelOutputSettings', ...
            true, ...
            'SignalLogging', ...
            true);
    end
end


saveToFile(tf);

end


function st_close_harness_quiet( ...
        ownerPath, ...
        harnessName)

try

    sltest.harness.close( ...
        ownerPath, ...
        harnessName);

catch
end

end
