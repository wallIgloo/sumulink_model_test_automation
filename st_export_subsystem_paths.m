function R = st_export_subsystem_paths(forceSelectModel)
%ST_EXPORT_SUBSYSTEM_PATHS Export every subsystem in one model to Excel.
%
% This is the manual-path matching helper.
%
% Usage:
%   R = st_export_subsystem_paths();
%       Reuse runtime_target.mat when it points to an existing model file.
%       Otherwise show the target-model selection dialog.
%
%   R = st_export_subsystem_paths(true);
%       Always show the model-selection dialog and replace runtime_target.mat.
%
% Output:
%   TestManagement.xlsx / cfg.SubsystemInventorySheet
%
% Columns:
%   No
%   CUTName       - display name with actual model depth indentation
%   RawCUTName    - exact Simulink subsystem name
%   Depth         - actual hierarchy depth from the model root
%   ParentName
%   RelativePath
%   FullPath
%
% Example CUTName display:
%
%   - A
%     - B
%     - C
%       - D
%     - E
%
% Important:
%   Depth is calculated from the actual Simulink hierarchy. It does not use
%   any depth/indent information from TestManagement.xlsx / Targets.
%
%   This function does not modify Targets.CUTPath. The intended workflow is
%   to copy the required FullPath values manually into Targets.CUTPath and
%   then run st_pre_validate_targets before Harness creation.

if nargin < 1
    forceSelectModel = false;
end

cfg = st_config();


%% ============================================================
% Resolve target model
%% ============================================================

[modelName, modelFile] = ...
    st_inventory_resolve_model( ...
        cfg, ...
        logical(forceSelectModel));


%% ============================================================
% Load selected model
%% ============================================================

if bdIsLoaded(modelName)

    loadedFile = ...
        get_param(modelName, 'FileName');

    if ~isempty(loadedFile) && ...
            ~st_inventory_same_path(loadedFile, modelFile)

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
% Collect every subsystem
%% ============================================================

subsystems = ...
    find_system( ...
        modelName, ...
        'LookUnderMasks', 'all', ...
        'FollowLinks', 'off', ...
        'Type', 'Block', ...
        'BlockType', 'SubSystem');

% find_system does not include the block diagram itself for BlockType
% SubSystem, but keep this guard in case model/version behavior differs.
subsystems = ...
    subsystems( ...
        ~strcmp(subsystems, modelName));


%% ============================================================
% Build records from actual hierarchy
%% ============================================================

n = numel(subsystems);

RawCUTName = strings(n,1);
Depth = zeros(n,1);
ParentName = strings(n,1);
RelativePath = strings(n,1);
FullPath = strings(n,1);

for i = 1:n

    blockPath = ...
        char(subsystems{i});

    RawCUTName(i) = ...
        string(get_param(blockPath, 'Name'));

    Depth(i) = ...
        st_inventory_depth( ...
            blockPath, ...
            modelName);

    parentPath = ...
        char(get_param(blockPath, 'Parent'));

    if isempty(parentPath)

        ParentName(i) = '';

    else

        try

            ParentName(i) = ...
                string(get_param(parentPath, 'Name'));

        catch

            ParentName(i) = ...
                string(parentPath);
        end
    end

    RelativePath(i) = ...
        string( ...
            st_inventory_relative_path( ...
                blockPath, ...
                modelName));

    FullPath(i) = ...
        string(blockPath);
end


%% ============================================================
% Sort in path order so hierarchy is easy to read
%% ============================================================

[~, order] = ...
    sort( ...
        lower(FullPath));

RawCUTName = RawCUTName(order);
Depth = Depth(order);
ParentName = ParentName(order);
RelativePath = RelativePath(order);
FullPath = FullPath(order);


%% ============================================================
% Build depth-indented CUTName display
%% ============================================================

CUTName = strings(n,1);

indentUnit = ...
    char(cfg.SubsystemInventoryIndent);

prefix = ...
    char(cfg.SubsystemInventoryPrefix);

for i = 1:n

    indent = ...
        repmat( ...
            indentUnit, ...
            1, ...
            max(Depth(i) - 1, 0));

    CUTName(i) = ...
        string([ ...
            indent ...
            prefix ...
            char(RawCUTName(i))]);
end


%% ============================================================
% Result table
%% ============================================================

No = (1:n).';

R = table( ...
    No, ...
    CUTName, ...
    RawCUTName, ...
    Depth, ...
    ParentName, ...
    RelativePath, ...
    FullPath);


%% ============================================================
% Write / recreate inventory sheet
%% ============================================================

if ~isfile(cfg.ManagementExcel)

    error( ...
        'Management Excel not found: %s', ...
        cfg.ManagementExcel);
end

writetable( ...
    R, ...
    cfg.ManagementExcel, ...
    'Sheet', cfg.SubsystemInventorySheet, ...
    'WriteMode', 'overwritesheet');


%% ============================================================
% Result log
%% ============================================================

try

    st_write_result( ...
        'SubsystemInventoryResult', ...
        R);

catch ME

    warning( ...
        'Could not write SubsystemInventoryResult log: %s', ...
        ME.message);
end


fprintf('\n');
fprintf('============================================\n');
fprintf('Subsystem Inventory Export Complete\n');
fprintf('============================================\n');
fprintf('Model : %s\n', modelName);
fprintf('File  : %s\n', modelFile);
fprintf('Sheet : %s\n', cfg.SubsystemInventorySheet);
fprintf('Count : %d\n', height(R));
fprintf('============================================\n');
fprintf('Copy FullPath values into Targets.CUTPath as needed.\n');
fprintf('Then run st_pre_validate_targets before Harness creation.\n');
fprintf('============================================\n');

end


%% ============================================================
% Resolve model from runtime target or selection dialog
%% ============================================================

function [modelName, modelFile] = ...
    st_inventory_resolve_model( ...
        cfg, ...
        forceSelectModel)

useRuntime = false;

if ~forceSelectModel && ...
        cfg.HasRuntimeTarget && ...
        ~isempty(cfg.ModelFile) && ...
        isfile(cfg.ModelFile)

    useRuntime = true;
end


if useRuntime

    modelName = ...
        char(cfg.TopModel);

    modelFile = ...
        char(cfg.ModelFile);

    fprintf('\n');
    fprintf('Using runtime target model: %s\n', modelName);

    return;
end


%% Search model files

modelFiles = ...
    st_inventory_find_model_files( ...
        cfg.ModelSearchRoot, ...
        cfg.ModelSearchRecursive, ...
        cfg.ModelSearchExcludeFolders);

if isempty(modelFiles)

    error( ...
        'No .slx or .mdl files found under: %s', ...
        cfg.ModelSearchRoot);
end


displayNames = ...
    st_inventory_relative_display_names( ...
        modelFiles, ...
        cfg.ModelSearchRoot);

[index, ok] = ...
    listdlg( ...
        'PromptString', 'Select the target Simulink model', ...
        'SelectionMode', 'single', ...
        'ListString', displayNames, ...
        'ListSize', [650 320], ...
        'Name', 'Subsystem Inventory - Target Model');

if ~ok || isempty(index)

    error('Target model selection was cancelled.');
end

modelFile = ...
    modelFiles{index};

[~, modelName] = ...
    fileparts(modelFile);


%% Save runtime target so the rest of the automation uses the same model

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

end


%% ============================================================
% Actual hierarchy depth
%% ============================================================

function depth = ...
    st_inventory_depth( ...
        blockPath, ...
        modelName)

currentPath = ...
    char(blockPath);

depth = 0;

maxIterations = 10000;

for k = 1:maxIterations

    if strcmp(currentPath, modelName)
        return;
    end

    depth = depth + 1;

    parentPath = ...
        char(get_param(currentPath, 'Parent'));

    if isempty(parentPath)

        error( ...
            'Could not trace subsystem hierarchy to model root: %s', ...
            blockPath);
    end

    currentPath = parentPath;
end

error( ...
    'Subsystem hierarchy exceeded safety limit: %s', ...
    blockPath);

end


%% ============================================================
% Relative Simulink path
%% ============================================================

function relativePath = ...
    st_inventory_relative_path( ...
        fullPath, ...
        modelName)

fullPath = ...
    char(fullPath);

prefix = ...
    [char(modelName) '/'];

if length(fullPath) >= length(prefix) && ...
        strncmp(fullPath, prefix, length(prefix))

    relativePath = ...
        fullPath(length(prefix)+1:end);

else

    relativePath = ...
        fullPath;
end

end


%% ============================================================
% Find .slx / .mdl files
%% ============================================================

function modelFiles = ...
    st_inventory_find_model_files( ...
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

    if st_inventory_path_contains_excluded_folder( ...
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
    st_inventory_path_contains_excluded_folder( ...
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
% Display model files relative to search root
%% ============================================================

function names = ...
    st_inventory_relative_display_names( ...
        files, ...
        rootDir)

names = files;

rootNormalized = ...
    st_inventory_normalize_file_path(rootDir);

for i = 1:numel(files)

    fileNormalized = ...
        st_inventory_normalize_file_path(files{i});

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


function normalized = ...
    st_inventory_normalize_file_path(value)

normalized = ...
    strrep( ...
        char(value), ...
        char(92), ...
        '/');

while length(normalized) > 1 && ...
        normalized(end) == '/'

    normalized(end) = [];
end

end


function tf = ...
    st_inventory_same_path( ...
        a, ...
        b)

A = ...
    st_inventory_normalize_file_path(a);

B = ...
    st_inventory_normalize_file_path(b);

if ispc
    tf = strcmpi(A, B);
else
    tf = strcmp(A, B);
end

end
