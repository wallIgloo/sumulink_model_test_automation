function R = st_create_harnesses()
%ST_CREATE_HARNESSES
% TestManagement.xlsx의 CUTPath / HarnessName을 사용하여
% 존재하지 않는 Harness만 생성합니다.
%
% 기존 Harness가 이미 있으면 SKIP합니다.

cfg = st_config();
T = st_load_targets(true);

modelName = cfg.TopModel;

if ~bdIsLoaded(modelName)
    load_system(modelName);
end

n = height(T);

Status    = strings(n,1);
Message   = strings(n,1);
Elapsed   = zeros(n,1);
Timestamp = strings(n,1);

fprintf('\n');
fprintf('========================================\n');
fprintf('Create Test Harnesses\n');
fprintf('Model : %s\n', modelName);
fprintf('Count : %d\n', n);
fprintf('========================================\n');

for i = 1:n

    cutName = char(T.CUTName(i));

    ownerPath = st_normalize_cut_path( ...
        T.CUTPath(i), ...
        modelName);

    harnessName = char(T.HarnessName(i));

    fprintf('\n[%d/%d] %s\n', i, n, cutName);
    fprintf('  CUT     : %s\n', ownerPath);
    fprintf('  Harness : %s\n', harnessName);

    tStart = tic;

    try

        %% CUT 존재 확인
        h = getSimulinkBlockHandle(ownerPath);

        if h == -1
            error('CUT를 찾을 수 없습니다: %s', ownerPath);
        end

        if ~strcmp(get_param(h, 'BlockType'), 'SubSystem')
            error('CUT가 SubSystem이 아닙니다: %s', ownerPath);
        end


        %% 기존 Harness 확인
        existing = sltest.harness.find( ...
            ownerPath, ...
            'SearchDepth', 0, ...
            'Name', harnessName);

        if ~isempty(existing)

            Status(i) = "SKIP";
            Message(i) = "Harness already exists";

            fprintf('  -> SKIP : already exists\n');

            Elapsed(i) = toc(tStart);

            Timestamp(i) = string(datetime( ...
                'now', ...
                'Format', 'yyyy-MM-dd HH:mm:ss'));

            continue;
        end


        %% 이전 상태 정리
        st_force_model_stopped(modelName);


        %% Harness 생성
        sltest.harness.create( ...
            ownerPath, ...
            'Name', harnessName, ...
            'Source', 'Signal Editor', ...
            'Sink', 'Outport', ...
            'AutoShapeInputs', false, ...
            'SchedulerBlock', 'Test Sequence', ...
            'SeparateAssessment', true, ...
            'CreateWithoutCompile', false, ...
            'VerificationMode', 'Normal', ...
            'LogOutputs', false, ...
            'RebuildOnOpen', false, ...
            'RebuildModelData', false, ...
            'SaveExternally', false, ...
            'SynchronizationMode', 'SyncOnOpenAndClose');


        %% 생성 결과 재확인
        created = sltest.harness.find( ...
            ownerPath, ...
            'SearchDepth', 0, ...
            'Name', harnessName);

        if isempty(created)
            error( ...
                'Harness 생성 후 Harness를 찾지 못했습니다: %s', ...
                harnessName);
        end


        %% 저장
        save_system(modelName);

        Status(i) = "OK";
        Message(i) = "Harness created";

        fprintf('  -> OK\n');


    catch ME

        Status(i) = "FAIL";
        Message(i) = string(ME.message);

        fprintf('  -> FAIL : %s\n', ME.message);

    end


    Elapsed(i) = toc(tStart);

    Timestamp(i) = string(datetime( ...
        'now', ...
        'Format', 'yyyy-MM-dd HH:mm:ss'));
end


%% 결과
R = table( ...
    T.No, ...
    T.CUTName, ...
    T.CUTPath, ...
    T.HarnessName, ...
    Status, ...
    Message, ...
    Elapsed, ...
    Timestamp, ...
    'VariableNames', { ...
        'No', ...
        'CUTName', ...
        'CUTPath', ...
        'HarnessName', ...
        'Status', ...
        'Message', ...
        'ElapsedSec', ...
        'Timestamp'});


st_write_result( ...
    'HarnessCreateResult', ...
    R);


fprintf('\n========================================\n');
fprintf('Harness creation complete\n');
fprintf('OK   : %d\n', sum(Status == "OK"));
fprintf('SKIP : %d\n', sum(Status == "SKIP"));
fprintf('FAIL : %d\n', sum(Status == "FAIL"));
fprintf('========================================\n');

end