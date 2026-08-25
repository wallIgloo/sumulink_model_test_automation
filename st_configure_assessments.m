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
% Assessment 구조:
%
%   Scenario:
%       UT_REQ_{CUTName}_001
%
%   step1
%       Action 없음
%
%       true
%        |
%        v
%
%   step2
%       verify(...)
%
%
% Expected value:
%   현재 기본값은 모두 0


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


%% 모델 상태 정리

st_force_model_stopped( ...
    cfg.TopModel);


n = height(T);


%% ============================================================
% 대상 없음
%% ============================================================

if n == 0

    warning( ...
        '처리할 CUT가 없습니다.');

    R = table();

    return;
end


%% ============================================================
% 결과 변수
%% ============================================================

CUTPath = strings(n,1);

AssessmentBlock = strings(n,1);

ScenarioName = strings(n,1);

VerifyMode = strings(n,1);

BusArrayMode = strings(n,1);

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


    %% Verify Mode

    if cfg.VerifyHarnessOutportsOnly

        VerifyMode(i) = ...
            'HARNESS_OUTPORTS_ONLY';

    else

        VerifyMode(i) = ...
            'ALL_ASSESSMENT_INPUTS';
    end


    %% Bus Array Mode

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

    fprintf('  CUT      : %s\n', ...
        ownerPath);

    fprintf('  Harness  : %s\n', ...
        harnessName);

    fprintf('  Scenario : %s\n', ...
        scenarioName);


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


        fprintf('  Assessment : %s\n', ...
            assess);


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

            %% Harness 최상위 Outport

            harnessOutputs = ...
                st_collect_harness_output_signals( ...
                    harnessName);


            HarnessOutportCount(i) = ...
                height(harnessOutputs);


            %% Harness Outport와 Assessment Input 교집합

            targets = ...
                select_harness_output_targets( ...
                    assessmentSpecs, ...
                    harnessOutputs);


            %% Outport는 있는데 Assessment와 하나도 매칭 안 됨

            if height(harnessOutputs) > 0 && ...
                    isempty(targets)

                error( ...
                    ['Harness Outport 신호와 일치하는 ' ...
                     'Test Assessment Input Symbol을 찾지 못했습니다.']);
            end

        else

            %% Assessment Input 전체 사용

            targets = ...
                assessmentSpecs;


            HarnessOutportCount(i) = ...
                0;
        end


        %% ====================================================
        % Verify Target 개수
        %% ====================================================

        VerifyTargetCount(i) = ...
            height(targets);


        %% ====================================================
        % verify Action 생성
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
            verifyAction);


        %% ====================================================
        % 저장
        %% ====================================================

        save_system( ...
            cfg.TopModel);


        %% ====================================================
        % Harness Close
        %% ====================================================

        st_close_harness_quiet( ...
            ownerPath, ...
            harnessName);


        %% ====================================================
        % 성공
        %% ====================================================

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

        %% Harness Close 시도

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
        'HarnessOutportCount', ...
        'VerifyTargetCount', ...
        'VerifyCount', ...
        'Status', ...
        'Message', ...
        'Timestamp'});


%% ============================================================
% 결과 저장
%% ============================================================

st_write_result( ...
    'AssessmentResult', ...
    R);


%% ============================================================
% Summary
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('Test Assessment Result\n');
fprintf('============================================\n');
fprintf('OK   : %d\n', ...
    sum(Status == 'OK'));
fprintf('FAIL : %d\n', ...
    sum(Status == 'FAIL'));
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


%% Signal line 이름 + Outport block 이름 모두 후보로 사용

candidateNames = [ ...
    harnessOutputs.SignalName; ...
    harnessOutputs.OutportBlock];


%% 빈 이름 제거

candidateNames = ...
    candidateNames( ...
        strlength(candidateNames) > 0);


%% 중복 제거

candidateNames = ...
    unique( ...
        candidateNames, ...
        'stable');


%% Assessment Input과 교집합

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