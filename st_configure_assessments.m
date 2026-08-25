function R = st_configure_assessments()
%ST_CONFIGURE_ASSESSMENTS
% Existing Harness의 Test Assessment를 자동 구성합니다.
%
% Verify 대상:
%
% cfg.VerifyHarnessOutportsOnly == true
%   Harness 최상위 Outport에 연결된 신호
%       ∩
%   Test Assessment Input Data Symbol
%
% cfg.VerifyHarnessOutportsOnly == false
%   Test Assessment의 모든 Input Data Symbol
%
%
% Bus 배열:
%
% cfg.VerifyFirstBusElementOnly == true
%   Bus 배열에서는 첫 번째 Bus 요소만 verify
%
% cfg.VerifyFirstBusElementOnly == false
%   Bus 배열 전체를 verify
%
%
% Verify 시점:
%
% cfg.VerifyAtSampleTimeOnly == false
%   step1 --true--> step2
%
% cfg.VerifyAtSampleTimeOnly == true
%   step1 --after(ExpectedValueSampleTime, sec)--> step2
%
%
% Expected value:
%   초기 생성값은 0
%   AutoUpdateExpectedOnFail 옵션은 Test 실행 후 별도 처리

cfg = st_config();

T = st_load_targets( ...
    cfg.OnlyEnabled);


%% ============================================================
% Top Model Load
%% ============================================================

if ~bdIsLoaded(cfg.TopModel)

    load_system( ...
        cfg.TopModel);
end


st_force_model_stopped( ...
    cfg.TopModel);


n = height(T);


if n == 0

    warning( ...
        '처리할 CUT가 없습니다.');

    R = table();

    return;
end


%% ============================================================
% Transition condition
%% ============================================================

if cfg.VerifyAtSampleTimeOnly

    transitionCondition = ...
        sprintf( ...
            'after(%.17g, sec)', ...
            cfg.ExpectedValueSampleTime);

    stopTime = ...
        str2double( ...
            cfg.HarnessStopTime);

    if isfinite(stopTime) && ...
            stopTime <= cfg.ExpectedValueSampleTime

        warning( ...
            ['VerifyAtSampleTimeOnly=true인데 HarnessStopTime이 ' ...
             'ExpectedValueSampleTime 이하입니다. ' ...
             '안정적인 평가를 위해 StopTime을 SampleTime보다 크게 두는 것을 권장합니다.']);
    end

else

    transitionCondition = ...
        'true';
end


%% ============================================================
% 결과 변수
%% ============================================================

CUTPath = strings(n,1);
AssessmentBlock = strings(n,1);
ScenarioName = strings(n,1);
VerifyMode = strings(n,1);
BusArrayMode = strings(n,1);
TransitionCondition = strings(n,1);
HarnessOutportCount = zeros(n,1);
VerifyTargetCount = zeros(n,1);
VerifyCount = zeros(n,1);
Status = strings(n,1);
Message = strings(n,1);
Timestamp = strings(n,1);


fprintf('\n');
fprintf('============================================\n');
fprintf('Configure Test Assessment\n');
fprintf('============================================\n');


%% ============================================================
% CUT 반복
%% ============================================================

for i = 1:n

    ownerPath = ...
        st_normalize_cut_path( ...
            T.CUTPath(i), ...
            cfg.TopModel);

    harnessName = ...
        char(T.HarnessName(i));

    cutName = ...
        char(T.CUTName(i));

    scenarioName = ...
        st_scenario_name( ...
            T.CUTName(i));


    CUTPath(i) = ...
        string(ownerPath);

    ScenarioName(i) = ...
        string(scenarioName);

    TransitionCondition(i) = ...
        string(transitionCondition);


    if cfg.VerifyHarnessOutportsOnly

        VerifyMode(i) = ...
            'HARNESS_OUTPORTS_ONLY';

    else

        VerifyMode(i) = ...
            'ALL_ASSESSMENT_INPUTS';
    end


    if cfg.VerifyFirstBusElementOnly

        BusArrayMode(i) = ...
            'FIRST_ELEMENT_ONLY';

    else

        BusArrayMode(i) = ...
            'ALL_ELEMENTS';
    end


    fprintf('\n');
    fprintf('[%d/%d] %s\n', ...
        i, ...
        n, ...
        cutName);

    fprintf('  CUT        : %s\n', ...
        ownerPath);

    fprintf('  Harness    : %s\n', ...
        harnessName);

    fprintf('  Scenario   : %s\n', ...
        scenarioName);

    fprintf('  Transition : %s\n', ...
        transitionCondition);


    try

        %% ====================================================
        % Model 상태 정리
        %% ====================================================

        st_force_model_stopped( ...
            cfg.TopModel);


        %% ====================================================
        % Harness Load
        %% ====================================================

        sltest.harness.load( ...
            ownerPath, ...
            harnessName);


        %% ====================================================
        % Test Assessment 찾기
        %% ====================================================

        assess = ...
            st_find_assessment_block( ...
                harnessName);

        AssessmentBlock(i) = ...
            string(assess);


        %% ====================================================
        % Assessment Input Symbol 정보
        %% ====================================================

        assessmentSpecs = ...
            st_collect_assessment_input_specs( ...
                assess);


        %% ====================================================
        % Verify 대상 결정
        %% ====================================================

        if cfg.VerifyHarnessOutportsOnly

            harnessOutputs = ...
                st_collect_harness_output_signals( ...
                    harnessName);

            HarnessOutportCount(i) = ...
                height(harnessOutputs);


            targets = ...
                select_harness_output_targets( ...
                    assessmentSpecs, ...
                    harnessOutputs);


            if height(harnessOutputs) > 0 && ...
                    isempty(targets)

                error( ...
                    ['Harness Outport 신호와 일치하는 ' ...
                     'Test Assessment Input Symbol을 찾지 못했습니다.']);
            end

        else

            targets = ...
                assessmentSpecs;

            HarnessOutportCount(i) = ...
                0;
        end


        VerifyTargetCount(i) = ...
            height(targets);


        %% ====================================================
        % Verify Action 생성
        %% ====================================================

        [verifyAction, verifyCount] = ...
            st_build_verify_action( ...
                targets, ...
                cfg.TopModel, ...
                cfg.VerifyFirstBusElementOnly);

        VerifyCount(i) = ...
            verifyCount;


        %% ====================================================
        % Assessment Scenario 구성
        %% ====================================================

        st_prepare_assessment_scenario( ...
            assess, ...
            scenarioName, ...
            verifyAction, ...
            transitionCondition);


        %% ====================================================
        % 저장
        %% ====================================================

        save_system( ...
            cfg.TopModel);


        st_close_harness_quiet( ...
            ownerPath, ...
            harnessName);


        Status(i) = ...
            'OK';

        Message(i) = ...
            sprintf( ...
                ['outports=%d, ' ...
                 'targets=%d, ' ...
                 'verify=%d'], ...
                HarnessOutportCount(i), ...
                height(targets), ...
                verifyCount);


        fprintf( ...
            ['  -> OK : ' ...
             'outports=%d, ' ...
             'targets=%d, ' ...
             'verify=%d\n'], ...
            HarnessOutportCount(i), ...
            height(targets), ...
            verifyCount);


    catch ME

        st_close_harness_quiet( ...
            ownerPath, ...
            harnessName);

        Status(i) = ...
            'FAIL';

        Message(i) = ...
            string(ME.message);

        fprintf( ...
            '  -> FAIL : %s\n', ...
            ME.message);
    end


    Timestamp(i) = ...
        string( ...
            datetime( ...
                'now', ...
                'Format', ...
                'yyyy-MM-dd HH:mm:ss'));
end


%% ============================================================
% Top Model 저장
%% ============================================================

try

    save_system( ...
        cfg.TopModel);

catch ME

    warning( ...
        'Top Model 저장 중 오류: %s', ...
        ME.message);
end


%% ============================================================
% 결과 Table
%% ============================================================

R = table( ...
    T.No, ...
    T.CUTName, ...
    CUTPath, ...
    T.HarnessName, ...
    AssessmentBlock, ...
    ScenarioName, ...
    VerifyMode, ...
    BusArrayMode, ...
    TransitionCondition, ...
    HarnessOutportCount, ...
    VerifyTargetCount, ...
    VerifyCount, ...
    Status, ...
    Message, ...
    Timestamp, ...
    'VariableNames', { ...
        'No', ...
        'CUTName', ...
        'CUTPath', ...
        'HarnessName', ...
        'AssessmentBlock', ...
        'ScenarioName', ...
        'VerifyMode', ...
        'BusArrayMode', ...
        'TransitionCondition', ...
        'HarnessOutportCount', ...
        'VerifyTargetCount', ...
        'VerifyCount', ...
        'Status', ...
        'Message', ...
        'Timestamp'});


st_write_result( ...
    'AssessmentResult', ...
    R);


fprintf('\n');
fprintf('============================================\n');
fprintf('Test Assessment Result\n');
fprintf('============================================\n');
fprintf('OK   : %d\n', ...
    sum(strcmp(Status, 'OK')));
fprintf('FAIL : %d\n', ...
    sum(strcmp(Status, 'FAIL')));
fprintf('Total: %d\n', ...
    n);
fprintf('============================================\n');

end


%% ============================================================
% Harness Outport <-> Assessment Input Matching
%% ============================================================

function targets = select_harness_output_targets( ...
        assessmentSpecs, ...
        harnessOutputs)

if isempty(assessmentSpecs) || ...
        isempty(harnessOutputs)

    targets = ...
        assessmentSpecs([],:);

    return;
end


candidateNames = [ ...
    harnessOutputs.SignalName; ...
    harnessOutputs.OutportBlock];

candidateNames = ...
    candidateNames( ...
        strlength(candidateNames) > 0);

candidateNames = ...
    unique( ...
        candidateNames, ...
        'stable');

mask = ...
    ismember( ...
        assessmentSpecs.Name, ...
        candidateNames);

targets = ...
    assessmentSpecs(mask,:);

end


%% ============================================================
% Harness Close
%% ============================================================

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
