function R = st_find_target_paths()
%ST_FIND_TARGET_PATHS Select one Simulink model and resolve CUT paths.
%
% Workflow:
%   1. Search ModelSearchRoot for .slx / .mdl files.
%   2. Let the user select exactly one target model.
%   3. Load the selected model.
%   4. Search the selected model for each CUTName in TestManagement.xlsx.
%   5. One match     -> select automatically.
%      Multiple      -> let the user select the correct CUT path.
%      No match      -> mark FAIL.
%   6. Write resolved paths to the existing CUTPath column.
%   7. Save the selected model to runtime_target.mat.
%
% Excel does not need a ModelName column. One selected model is shared by
% every CUT in the current automation run.

cfg = st_config();


%% ============================================================
% Search model files
%% ============================================================

modelFiles = ...
    st_find_model_files( ...
        cfg.ModelSearchRoot, ...
        cfg.ModelSearchRecursive, ...
        cfg.ModelSearchExcludeFolders);

if isempty(modelFiles)

    error( ...
        'No .slx or .mdl files found under: %s', ...
        cfg.ModelSearchRoot);
end


%% ============================================================
% Select one model
%% ============================================================

displayNames = ...
    st_relative_display_names( ...
        modelFiles, ...
        cfg.ModelSearchRoot);

[index, ok] = ...
    listdlg( ...
        'PromptString', 'Select the target Simulink model', ...
        'SelectionMode', 'single', ...
        'ListString', displayNames, ...
        'ListSize', [650 320], ...
        'Name', 'Target Model Selection');

if ~ok || isempty(index)

    error('Target model selection was cancelled.');
end

modelFile = ...
    modelFiles{index};

[~, modelName] = ...
    fileparts(modelFile);


%% ============================================================
% Load selected model safely
%% ============================================================

if bdIsLoaded(modelName)

    loadedFile = ...
        get_param(modelName, 'FileName');

    if ~isempty(loadedFile) && ...
            ~st_same_path(loadedFile, modelFile)

        error( ...
            ['A different model with the same name is already loaded. ' ...
             'Loaded=%s, Selected=%s'], ...
            loadedFile, ...
            modelFile);
    end

else

    load_system(modelFile);
end


%% ============================================================
% Save runtime target
%% ============================================================

TopModel = modelName; %#ok<NASGU>
ModelFile = modelFile; %#ok<NASGU>
SelectedAt = char(datetime( ...
    'now', ...
    'Format', 'yyyy-MM-dd HH:mm:ss')); %#ok<NASGU>

save( ...
    cfg.RuntimeTargetFile, ...
    'TopModel', ...
    'ModelFile', ...
    'SelectedAt');


fprintf('\n');
fprintf('============================================\n');
fprintf('Target Model Selected\n');
fprintf('============================================\n');
fprintf('Model : %s\n', modelName);
fprintf('File  : %s\n', modelFile);
fprintf('============================================\n');


%% ============================================================
% Read management Excel without losing physical row numbers
%% ============================================================

if ~isfile(cfg.ManagementExcel)

    error( ...
        'Management Excel not found: %s', ...
        cfg.ManagementExcel);
end

raw = ...
    readcell( ...
        cfg.ManagementExcel, ...
        'Sheet', cfg.ManagementSheet);

if isempty(raw) || size(raw,1) < 2

    error( ...
        'Targets sheet is empty: %s', ...
        cfg.ManagementSheet);
end

headers = ...
    string(raw(1,:));

idxCUTName = ...
    st_find_column( ...
        headers, ...
        {'CUTName','ModelName','모델명','CUT','대상모델명'});

idxCUTPath = ...
    st_find_column( ...
        headers, ...
        {'CUTPath','Path','path','경로','모델경로'});

idxEnabled = ...
    st_find_column_optional( ...
        headers, ...
        {'Enabled','사용','사용여부','활성','활성화'});


%% ============================================================
% Search every subsystem once
%% ============================================================

subsystems = ...
    find_system( ...
        modelName, ...
        'LookUnderMasks', 'all', ...
        'FollowLinks', 'off', ...
        'Type', 'Block', ...
        'BlockType', 'SubSystem');

subsystemNames = ...
    cell(size(subsystems));

for k = 1:numel(subsystems)

    subsystemNames{k} = ...
        get_param(subsystems{k}, 'Name');
end


%% ============================================================
% Prepare CUTPath column update
%% ============================================================

rowCount = ...
    size(raw,1) - 1;

cutPathColumn = ...
    raw(2:end, idxCUTPath);

for k = 1:numel(cutPathColumn)

    if st_cell_is_missing(cutPathColumn{k})
        cutPathColumn{k} = '';
    end
end


%% ============================================================
% Result buffers
%% ============================================================

ExcelRow = zeros(0,1);
CUTName = strings(0,1);
MatchCount = zeros(0,1);
SelectedCUTPath = strings(0,1);
Status = strings(0,1);
Message = strings(0,1);
Timestamp = strings(0,1);


%% ============================================================
% Resolve CUT paths
%% ============================================================

resultIndex = 0;

for dataRow = 1:rowCount

    excelRow = ...
        dataRow + 1;

    cutName = ...
        strtrim( ...
            st_cell_text( ...
                raw{excelRow, idxCUTName}));

    if isempty(cutName)
        continue;
    end

    if cfg.OnlyEnabled && ...
            ~isempty(idxEnabled)

        if ~st_enabled_value( ...
                raw{excelRow, idxEnabled})

            continue;
        end
    end

    resultIndex = ...
        resultIndex + 1;

    ExcelRow(resultIndex,1) = ...
        excelRow;

    CUTName(resultIndex,1) = ...
        string(cutName);

    Timestamp(resultIndex,1) = ...
        string(datetime( ...
            'now', ...
            'Format', 'yyyy-MM-dd HH:mm:ss'));


    %% --------------------------------------------------------
    % Exact subsystem name match
    %% --------------------------------------------------------

    mask = ...
        strcmp( ...
            subsystemNames, ...
            cutName);

    matches = ...
        subsystems(mask);

    MatchCount(resultIndex,1) = ...
        numel(matches);


    %% --------------------------------------------------------
    % Not found
    %% --------------------------------------------------------

    if isempty(matches)

        Status(resultIndex,1) = ...
            'FAIL';

        Message(resultIndex,1) = ...
            'CUT subsystem not found in selected model';

        fprintf( ...
            '[%d] FAIL %s : not found\n', ...
            excelRow, ...
            cutName);

        continue;
    end


    %% --------------------------------------------------------
    % Single match
    %% --------------------------------------------------------

    if numel(matches) == 1

        selectedPath = ...
            matches{1};


    %% --------------------------------------------------------
    % Multiple matches
    %% --------------------------------------------------------

    else

        currentPath = ...
            strtrim( ...
                st_cell_text( ...
                    raw{excelRow, idxCUTPath}));

        currentNormalized = '';

        if ~isempty(currentPath)

            try

                currentNormalized = ...
                    st_normalize_cut_path( ...
                        currentPath, ...
                        modelName);

            catch
                currentNormalized = '';
            end
        end


        %% Existing CUTPath is still one of the matches -> reuse it

        existingIndex = [];

        if ~isempty(currentNormalized)

            existingIndex = ...
                find( ...
                    strcmp(matches, currentNormalized), ...
                    1, ...
                    'first');
        end

        if ~isempty(existingIndex)

            selectedPath = ...
                matches{existingIndex};

        else

            [matchIndex, matchOk] = ...
                listdlg( ...
                    'PromptString', { ...
                        sprintf('CUTName: %s', cutName), ...
                        'Multiple subsystem paths were found. Select one.'}, ...
                    'SelectionMode', 'single', ...
                    'ListString', matches, ...
                    'ListSize', [720 320], ...
                    'Name', 'CUT Path Selection');

            if ~matchOk || isempty(matchIndex)

                Status(resultIndex,1) = ...
                    'FAIL';

                Message(resultIndex,1) = ...
                    'CUT path selection was cancelled';

                fprintf( ...
                    '[%d] FAIL %s : selection cancelled\n', ...
                    excelRow, ...
                    cutName);

                continue;
            end

            selectedPath = ...
                matches{matchIndex};
        end
    end


    %% --------------------------------------------------------
    % Update CUTPath in memory
    %% --------------------------------------------------------

    cutPathColumn{dataRow} = ...
        selectedPath;

    SelectedCUTPath(resultIndex,1) = ...
        string(selectedPath);

    Status(resultIndex,1) = ...
        'OK';

    if numel(matches) == 1

        Message(resultIndex,1) = ...
            'Resolved automatically';

    else

        Message(resultIndex,1) = ...
            'Resolved from multiple matches';
    end

    fprintf( ...
        '[%d] OK   %s -> %s\n', ...
        excelRow, ...
        cutName, ...
        selectedPath);
end


%% ============================================================
% Write CUTPath column only
%% ============================================================

startCell = ...
    sprintf( ...
        '%s2', ...
        st_excel_column_name(idxCUTPath));

writecell( ...
    cutPathColumn, ...
    cfg.ManagementExcel, ...
    'Sheet', cfg.ManagementSheet, ...
    'Range', startCell);


%% ============================================================
% Result
%% ============================================================

R = table( ...
    ExcelRow, ...
    CUTName, ...
    MatchCount, ...
    SelectedCUTPath, ...
    Status, ...
    Message, ...
    Timestamp);

st_write_result( ...
    'PathFinderResult', ...
    R);


fprintf('\n');
fprintf('============================================\n');
fprintf('CUT Path Finder Result\n');
fprintf('============================================\n');
fprintf('OK   : %d\n', sum(Status == 'OK'));
fprintf('FAIL : %d\n', sum(Status == 'FAIL'));
fprintf('Total: %d\n', height(R));
fprintf('============================================\n');
fprintf('Runtime target saved: %s\n', cfg.RuntimeTargetFile);
fprintf('============================================\n');

end


%% ============================================================
% Find .slx / .mdl files
%% ============================================================

function modelFiles = ...
    st_find_model_files( ...
        rootDir, ...
        recursive, ...
        excludeFolders)

if ~isfolder(rootDir)

    error( ...
        'ModelSearchRoot does not exist: %s', ...
        rootDir);
end

if recursive

    slxInfo = dir(fullfile(rootDir, '**', '*.slx'));
    mdlInfo = dir(fullfile(rootDir, '**', '*.mdl'));

else

    slxInfo = dir(fullfile(rootDir, '*.slx'));
    mdlInfo = dir(fullfile(rootDir, '*.mdl'));
end

info = [ ...
    slxInfo(:); ...
    mdlInfo(:)];

modelFiles = {};

for i = 1:numel(info)

    filePath = ...
        fullfile( ...
            info(i).folder, ...
            info(i).name);

    if st_path_contains_excluded_folder( ...
            filePath, ...
            excludeFolders)

        continue;
    end

    modelFiles{end+1,1} = ...
        filePath; %#ok<AGROW>
end

if ~isempty(modelFiles)

    modelFiles = ...
        unique( ...
            modelFiles, ...
            'stable');

    modelFiles = ...
        sort(modelFiles);
end

end


function tf = ...
    st_path_contains_excluded_folder( ...
        filePath, ...
        excludeFolders)

normalized = ...
    strrep( ...
        char(filePath), ...
        char(92), ...
        '/');

parts = ...
    strsplit(normalized, '/');

tf = false;

for i = 1:numel(excludeFolders)

    if any(strcmpi( ...
            parts, ...
            excludeFolders{i}))

        tf = true;
        return;
    end
end

end


%% ============================================================
% Display paths relative to search root
%% ============================================================

function names = ...
    st_relative_display_names( ...
        files, ...
        rootDir)

names = files;

rootNormalized = ...
    st_normalize_file_path(rootDir);

for i = 1:numel(files)

    fileNormalized = ...
        st_normalize_file_path(files{i});

    prefix = ...
        [rootNormalized '/'];

    if length(fileNormalized) >= length(prefix) && ...
            strncmpi(fileNormalized, prefix, length(prefix))

        names{i} = ...
            fileNormalized(length(prefix)+1:end);

    else

        names{i} = ...
            fileNormalized;
    end
end

end


%% ============================================================
% Header helpers
%% ============================================================

function idx = ...
    st_find_column( ...
        headers, ...
        aliases)

idx = ...
    st_find_column_optional( ...
        headers, ...
        aliases);

if isempty(idx)

    error( ...
        'Required Excel column not found: %s', ...
        strjoin(aliases, ', '));
end

end


function idx = ...
    st_find_column_optional( ...
        headers, ...
        aliases)

idx = [];

normalizedHeaders = ...
    lower(strtrim(headers));

for i = 1:numel(aliases)

    alias = ...
        lower(strtrim(string(aliases{i})));

    match = ...
        find( ...
            normalizedHeaders == alias, ...
            1, ...
            'first');

    if ~isempty(match)

        idx = match;
        return;
    end
end

end


%% ============================================================
% Cell helpers
%% ============================================================

function text = ...
    st_cell_text(value)

if st_cell_is_missing(value)

    text = '';
    return;
end

if ischar(value)

    text = value;

elseif isstring(value)

    if isempty(value) || ismissing(value)
        text = '';
    else
        text = char(value(1));
    end

else

    text = char(string(value));
end

end


function tf = ...
    st_cell_is_missing(value)

tf = isempty(value);

if tf
    return;
end

try

    missingMask = ...
        ismissing(value);

    tf = ...
        all(missingMask(:));

catch

    tf = false;
end

end


function tf = ...
    st_enabled_value(value)

if st_cell_is_missing(value)

    tf = false;
    return;
end

if islogical(value)

    tf = value(1);

elseif isnumeric(value)

    tf = ...
        isfinite(value(1)) && ...
        value(1) ~= 0;

else

    s = ...
        lower(strtrim(string(value)));

    tf = ...
        ismember( ...
            s, ...
            {'true','1','yes','y','on','사용','o'});
end

end


%% ============================================================
% Excel column number -> A / B / AA ...
%% ============================================================

function name = ...
    st_excel_column_name(index)

name = '';

while index > 0

    remainder = ...
        mod(index - 1, 26);

    name = ...
        [char(double('A') + remainder) name]; %#ok<AGROW>

    index = ...
        floor((index - 1) / 26);
end

end


%% ============================================================
% File path helpers
%% ============================================================

function tf = ...
    st_same_path(a, b)

tf = ...
    strcmpi( ...
        st_normalize_file_path(a), ...
        st_normalize_file_path(b));

end


function out = ...
    st_normalize_file_path(value)

out = ...
    strrep( ...
        char(value), ...
        char(92), ...
        '/');

while length(out) > 1 && ...
        out(end) == '/'

    out(end) = [];
end

end
