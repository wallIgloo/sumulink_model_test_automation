function R = st_pre_validate_targets()
%ST_PRE_VALIDATE_TARGETS
% Harness 생성 전에 CUT 경로만 검증합니다.
%
% 검사 항목:
%   1. CUTPath가 비어 있지 않은가
%   2. CUTPath를 정상적으로 정규화할 수 있는가
%   3. 해당 블록이 실제로 존재하는가
%   4. 해당 블록이 Subsystem인가
%
% 검사하지 않는 항목:
%   - Harness 존재 여부
%   - Signal Editor 존재 여부
%   - Test Assessment 존재 여부
%   - Scenario 존재 여부
%   - Test Manager / Test Case 존재 여부
%
% 사용:
%   R = st_pre_validate_targets();

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


%% ============================================================
% 대상 없음
%% ============================================================

n = height(T);

if n == 0

    warning( ...
        '검증할 CUT가 없습니다.');

    R = table();

    return;
end


%% ============================================================
% 결과 변수
%% ============================================================

InputCUTPath = strings(n,1);

NormalizedCUTPath = strings(n,1);

Status = strings(n,1);

Message = strings(n,1);

Timestamp = strings(n,1);


fprintf('\n');
fprintf('============================================\n');
fprintf('Pre-Validate CUT Paths\n');
fprintf('Model : %s\n', cfg.TopModel);
fprintf('Count : %d\n', n);
fprintf('============================================\n');


%% ============================================================
% CUT 반복
%% ============================================================

for i = 1:n

    rawPath = ...
        string(T.CUTPath(i));


    InputCUTPath(i) = ...
        rawPath;


    fprintf('\n[%d/%d] %s\n', ...
        i, ...
        n, ...
        char(T.CUTName(i)));

    fprintf('  Input Path : %s\n', ...
        char(rawPath));


    try

        %% ----------------------------------------------------
        % CUTPath Empty Check
        %% ----------------------------------------------------

        if strlength(strtrim(rawPath)) == 0

            error( ...
                'CUTPath가 비어 있습니다.');
        end


        %% ----------------------------------------------------
        % Path Normalize
        %% ----------------------------------------------------

        ownerPath = ...
            st_normalize_cut_path( ...
                rawPath, ...
                cfg.TopModel);


        NormalizedCUTPath(i) = ...
            string(ownerPath);


        fprintf('  Normalized : %s\n', ...
            ownerPath);


        %% ----------------------------------------------------
        % Block 존재 확인
        %% ----------------------------------------------------

        blockHandle = ...
            getSimulinkBlockHandle( ...
                ownerPath);


        if blockHandle == -1

            error( ...
                'CUTPath에 해당하는 블록을 찾을 수 없습니다: %s', ...
                ownerPath);
        end


        %% ----------------------------------------------------
        % Subsystem 여부 확인
        %% ----------------------------------------------------

        blockType = ...
            get_param( ...
                blockHandle, ...
                'BlockType');


        if ~strcmp( ...
                blockType, ...
                'SubSystem')

            error( ...
                ['대상 블록은 존재하지만 Subsystem이 아닙니다. ' ...
                 'BlockType=%s'], ...
                blockType);
        end


        %% ----------------------------------------------------
        % Success
        %% ----------------------------------------------------

        Status(i) = ...
            'OK';


        Message(i) = ...
            'Valid CUT path';


        fprintf('  -> OK\n');


    catch ME

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
% Result Table
%% ============================================================

R = table( ...
    T.No, ...
    T.CUTName, ...
    InputCUTPath, ...
    NormalizedCUTPath, ...
    Status, ...
    Message, ...
    Timestamp, ...
    'VariableNames', { ...
        'No', ...
        'CUTName', ...
        'InputCUTPath', ...
        'NormalizedCUTPath', ...
        'Status', ...
        'Message', ...
        'Timestamp'});


%% ============================================================
% 결과 저장
%% ============================================================

st_write_result( ...
    'PreValidationResult', ...
    R);


%% ============================================================
% Summary
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('Pre-Validation Result\n');
fprintf('============================================\n');
fprintf('OK   : %d\n', ...
    sum(Status == 'OK'));
fprintf('FAIL : %d\n', ...
    sum(Status == 'FAIL'));
fprintf('Total: %d\n', ...
    n);
fprintf('============================================\n');

end