function R = st_configure_assessments()
%ST_CONFIGURE_ASSESSMENTS Configure Test Assessment in existing harnesses.
%
% cfg.VerifyHarnessOutportsOnly = true
%   - No Top Model compile is required for verify target collection.
%   - Collect top-level Harness Outport blocks/signals.
%   - Verify only Assessment Input symbols that match those Harness outputs.
%
% cfg.VerifyHarnessOutportsOnly = false
%   - Verify every Input Data Symbol registered in Test Assessment.
%
% Common Assessment structure:
%   Scenario: UT_REQ_{CUTName}_001
%   step1 Action: empty
%   step1 -> step2 condition: true
%   step2 Action: verify statements, expected value = 0

cfg = st_config();

T = st_load_targets( ...
    cfg.OnlyEnabled);

load_system(cfg.TopModel);

st_force_model_stopped( ...
    cfg.TopModel);

n = height(T);


%% ============================================================
% 결과 변수
%% ============================================================

CUTPath = strings(n,1);

AssessmentBlock = strings(n,1);

ScenarioName = strings(n,1);

VerifyMode = strings(n,1);

HarnessOutportCount = zeros(n,1);

VerifyTargetCount = zeros(n,1);

VerifyCount = zeros(n,1);

Status = strings(n,1);

Message = strings(n,1);

Timestamp = strings(n,1);


fprintf( ...
    '\n=== Configure Test Assessment ===\n');


%% ============================================================
% CUT 반복
%% ============================================================

for i = 1:n

    ownerPath = st_normalize_cut_path( ...
        T.CUTPath(i), ...
        cfg.TopModel);

    harnessName = char( ...
        T.HarnessName(i));

    scenarioName = st_scenario_name( ...
        T.CUTName(i));


    CUTPath(i) = string(ownerPath);

    ScenarioName(i) = string(scenarioName);


    if cfg.VerifyHarnessOutportsOnly

        VerifyMode(i) = ...
            'HARNESS_OUTPORTS_ONLY';

    else

        VerifyMode(i) = ...
            'ALL_ASSESSMENT_INPUTS';
    end


    try

        %% ----------------------------------------------------
        % Model 상태 정리
        %% ----------------------------------------------------

        st_force_model_stopped( ...
            cfg.TopModel);


        %% ----------------------------------------------------
        % Harness Load
        %% ----------------------------------------------------

        sltest.harness.load( ...
            ownerPath, ...
            harnessName);


        %% ----------------------------------------------------
        % Assessment 찾기
        %% ----------------------------------------------------

        assess = st_find_assessment_block( ...
            harnessName);

        AssessmentBlock(i) = ...
            string(assess);


        %% ----------------------------------------------------
        % Assessment에서 실제 사용 가능한 Input Data
        %% ----------------------------------------------------

        assessmentSpecs = ...
            st_collect_assessment_input_specs( ...
                assess);


        %% ----------------------------------------------------
        % Verify 대상 결정
        %% ----------------------------------------------------

        if cfg.VerifyHarnessOutportsOnly

            % Harness 최상위 Outport가 기준입니다.
            harnessOutputs = ...
                st_collect_harness_output_signals( ...
                    harnessName);

            HarnessOutportCount(i) = ...
                height(harnessOutputs);


            % Assessment Input
            %      ∩
            % Harness Outport
            %
            % 만 verify 대상으로 사용

            targets = ...
                select_harness_output_targets( ...
                    assessmentSpecs, ...
                    harnessOutputs);


            %% Outport는 있는데 일치 대상이 하나도 없음

            if height(harnessOutputs) > 0 && ...
                    isempty(targets)

                error( ...
                    ['No Harness Outport signal matched an Assessment Input symbol. ' ...
                     'Check Harness Outport names/line names and Assessment Input symbol names.']);
            end

        else

            targets = assessmentSpecs;
        end


        %% ----------------------------------------------------
        % verify 생성
        %% ----------------------------------------------------

        VerifyTargetCount(i) = ...
            height(targets);


        [verifyAction, verifyCount] = ...
            st_build_verify_action( ...
                targets, ...
                cfg.TopModel);


        VerifyCount(i) = ...
            verifyCount;


        %% ----------------------------------------------------
        % Assessment Scenario 구성
        %% ----------------------------------------------------

        st_prepare_assessment_scenario( ...
            assess, ...
            scenarioName, ...
            verifyAction);


        %% ----------------------------------------------------
        % 저장
        %% ----------------------------------------------------

        save_system( ...
            cfg.TopModel);


        st_close_harness_quiet( ...
            ownerPath, ...
            harnessName);


        %% ----------------------------------------------------
        % 성공
        %% ----------------------------------------------------

        Status(i) = 'OK';


        Message(i) = sprintf( ...
            'outports=%d, targets=%d, verify=%d', ...
            HarnessOutportCount(i), ...
            height(targets), ...
            verifyCount);


        fprintf( ...
            '[%d/%d] OK   %s: outports %d, targets %d, verify %d\n', ...
            i, ...
            n, ...
            char(T.CUTName(i)), ...
            HarnessOutportCount(i), ...
            height(targets), ...
            verifyCount);


    catch ME

        st_close_harness_quiet( ...
            ownerPath, ...
            harnessName);


        Status(i) = 'FAIL';

        Message(i) = ...
            string(ME.message);


        fprintf( ...
            '[%d/%d] FAIL %s: %s\n', ...
            i, ...
            n, ...
            char(T.CUTName(i)), ...
            ME.message);
    end


    Timestamp(i) = string( ...
        datetime( ...
            'now', ...
            'Format', ...
            'yyyy-MM-dd HH:mm:ss'));

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
        'HarnessOutportCount', ...
        'VerifyTargetCount', ...
        'VerifyCount', ...
        'Status', ...
        'Message', ...
        'Timestamp'});


st_write_result( ...
    'AssessmentResult', ...
    R);

end


%% ============================================================
% Harness Outport ↔ Assessment Input 매칭
%% ============================================================

function targets = select_harness_output_targets( ...
        assessmentSpecs, ...
        harnessOutputs)

if isempty(assessmentSpecs) || ...
        isempty(harnessOutputs)

    targets = assessmentSpecs([],:);

    return;
end


%% Outport 연결 line name + block name 모두 후보

candidateNames = [ ...
    harnessOutputs.SignalName; ...
    harnessOutputs.OutportBlock];


%% 빈 이름 제거

candidateNames = candidateNames( ...
    strlength(candidateNames) > 0);


%% 중복 제거

candidateNames = unique( ...
    candidateNames, ...
    'stable');


%% Assessment Input과 교집합

mask = ismember( ...
    assessmentSpecs.Name, ...
    candidateNames);

targets = assessmentSpecs(mask,:);

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