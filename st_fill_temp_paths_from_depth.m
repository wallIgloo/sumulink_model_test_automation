function R = st_fill_temp_paths_from_depth(overwriteExisting)
%ST_FILL_TEMP_PATHS_FROM_DEPTH Build temporary CUTPath values from Excel Depth.
%
% This helper intentionally does not search the Simulink model for matching
% subsystem names. It only uses the row order, CUTName, and Depth values in
% TestManagement.xlsx / Targets to build a temporary hierarchy path.
%
% Usage:
%   R = st_fill_temp_paths_from_depth();
%       Uses cfg.DepthPathOverwriteExisting.
%
%   R = st_fill_temp_paths_from_depth(true);
%       Overwrite existing CUTPath values with newly built temporary paths.
%
%   R = st_fill_temp_paths_from_depth(false);
%       Fill only blank CUTPath cells and preserve existing/manual paths.
%
% Example:
%
%   CUTName   Depth
%   A         0
%   B         1
%   C         1
%   D         2
%   E         1
%
% Temporary paths:
%
%   MODEL/A
%   MODEL/A/B
%   MODEL/A/C
%   MODEL/A/C/D
%   MODEL/A/E
%
% Notes:
% - Depth is only a temporary hint. Generated paths are written even when
%   the exact block does not exist so they can be corrected manually.
% - The nearest preceding row having a lower Depth is treated as the logical
%   ancestor. Depth gaps such as 1 -> 3 are therefore tolerated.
% - Rows with missing/invalid Depth are not written.
% - Disabled rows still participate in hierarchy construction because an
%   enabled child may be located below a disabled parent in Excel.
% - When cfg.OnlyEnabled is true, disabled rows are not written to CUTPath.

baseCfg = st_config();

if ~baseCfg.HasRuntimeTarget || ...
        isempty(baseCfg.ModelFile) || ...
        ~isfile(baseCfg.ModelFile)

    st_select_target_model(false);
end

cfg = st_require_runtime_target();

if nargin < 1
    overwriteExisting = cfg.DepthPathOverwriteExisting;
else
    overwriteExisting = logical(overwriteExisting);
end


%% ============================================================
% Management Excel
%% ============================================================

if ~isfile(cfg.ManagementExcel)
    error('Management Excel not found: %s', cfg.ManagementExcel);
end

raw = ...
    readcell( ...
        cfg.ManagementExcel, ...
        'Sheet', cfg.ManagementSheet);

if isempty(raw) || size(raw,1) < 2
    error('Targets sheet is empty: %s', cfg.ManagementSheet);
end

headers = string(raw(1,:));

idxCUTName = ...
    st_depth_find_column( ...
        headers, ...
        {'CUTName','ModelName','모델명','CUT','대상모델명'});

idxCUTPath = ...
    st_depth_find_column( ...
        headers, ...
        {'CUTPath','Path','path','경로','모델경로'});

idxDepth = ...
    st_depth_find_column( ...
        headers, ...
        {'Depth','depth','DEPTH','Level','level','깊이','레벨'});

idxEnabled = ...
    st_depth_find_column_optional( ...
        headers, ...
        {'Enabled','사용','사용여부','활성','활성화'});

rowCount = size(raw,1) - 1;

cutPathColumn = raw(2:end, idxCUTPath);

for k = 1:numel(cutPathColumn)
    if st_depth_cell_is_missing(cutPathColumn{k})
        cutPathColumn{k} = '';
    end
end


%% ============================================================
% Load model for optional exact-path check
%% ============================================================

if ~bdIsLoaded(cfg.TopModel)
    load_system(cfg.ModelFile);
end

st_force_model_stopped(cfg.TopModel);


%% ============================================================
% Result buffers
%% ============================================================

ExcelRow = zeros(rowCount,1);
CUTName = strings(rowCount,1);
Depth = nan(rowCount,1);
ExistingPath = strings(rowCount,1);
TemporaryPath = strings(rowCount,1);
WrittenPath = strings(rowCount,1);
PathExists = false(rowCount,1);
Status = strings(rowCount,1);
Message = strings(rowCount,1);
Timestamp = strings(rowCount,1);


%% ============================================================
% Hierarchy stack
%% ============================================================

stackDepth = [];
stackName = {};

fprintf('\n');
fprintf('============================================\n');
fprintf('Temporary CUTPath From Excel Depth\n');
fprintf('Model     : %s\n', cfg.TopModel);
fprintf('Overwrite : %d\n', overwriteExisting);
fprintf('============================================\n');

for dataRow = 1:rowCount

    excelRow = dataRow + 1;

    ExcelRow(dataRow) = excelRow;

    cutName = ...
        strtrim( ...
            st_depth_cell_text( ...
                raw{excelRow, idxCUTName}));

    CUTName(dataRow) = string(cutName);

    currentPath = ...
        strtrim( ...
            st_depth_cell_text( ...
                raw{excelRow, idxCUTPath}));

    ExistingPath(dataRow) = string(currentPath);

    enabled = true;

    if ~isempty(idxEnabled)
        enabled = ...
            st_depth_enabled_value( ...
                raw{excelRow, idxEnabled});
    end

    if isempty(cutName)
        Status(dataRow) = 'SKIP_EMPTY_NAME';
        Message(dataRow) = 'CUTName is empty';
        Timestamp(dataRow) = st_depth_timestamp();
        continue;
    end

    [depthValue, depthOK] = ...
        st_depth_numeric_value( ...
            raw{excelRow, idxDepth});

    if ~depthOK
        Status(dataRow) = 'NO_DEPTH';
        Message(dataRow) = 'Depth is missing or invalid';
        Timestamp(dataRow) = st_depth_timestamp();
        continue;
    end

    Depth(dataRow) = depthValue;

    %% Keep only ancestors having a lower Depth.
    keepCount = numel(stackDepth);

    while keepCount > 0 && ...
            stackDepth(keepCount) >= depthValue

        keepCount = keepCount - 1;
    end

    stackDepth = stackDepth(1:keepCount);
    stackName = stackName(1:keepCount);

    %% Build temporary path from current stack.
    components = ...
        [{cfg.TopModel} stackName {cutName}];

    escaped = cell(size(components));

    for c = 1:numel(components)
        escaped{c} = ...
            st_depth_escape_block_name( ...
                components{c});
    end

    tempPath = strjoin(escaped, '/');
    TemporaryPath(dataRow) = string(tempPath);

    %% Exact-path existence is informational only.
    pathExists = ...
        st_depth_subsystem_exists( ...
            tempPath);

    PathExists(dataRow) = pathExists;

    %% Disabled rows still become hierarchy anchors, but may not be written.
    shouldWrite = true;

    if cfg.OnlyEnabled && ~enabled
        shouldWrite = false;
        Status(dataRow) = 'SKIP_DISABLED';
        Message(dataRow) = 'Used as hierarchy context only';
    end

    if shouldWrite && ...
            ~overwriteExisting && ...
            ~isempty(currentPath)

        shouldWrite = false;
        Status(dataRow) = 'SKIP_EXISTING';
        Message(dataRow) = 'Existing CUTPath preserved';
    end

    if shouldWrite

        cutPathColumn{dataRow} = tempPath;
        WrittenPath(dataRow) = string(tempPath);

        if pathExists
            Status(dataRow) = 'OK_EXISTS';
            Message(dataRow) = 'Temporary path matches an existing Subsystem';
        else
            Status(dataRow) = 'TEMP_NOT_FOUND';
            Message(dataRow) = 'Temporary path written; manual correction may be required';
        end

    else

        WrittenPath(dataRow) = string(currentPath);
    end

    %% Current row becomes a possible ancestor for later rows regardless of
    % Enabled state or whether its CUTPath was written.
    stackDepth(end+1) = depthValue; %#ok<AGROW>
    stackName{end+1} = cutName; %#ok<AGROW>

    Timestamp(dataRow) = st_depth_timestamp();

    fprintf('[%d] %s | Depth=%g | %s\n', ...
        excelRow, ...
        cutName, ...
        depthValue, ...
        char(Status(dataRow)));
end


%% ============================================================
% Write CUTPath column only
%% ============================================================

range = ...
    sprintf( ...
        '%s2:%s%d', ...
        st_depth_excel_column_name(idxCUTPath), ...
        st_depth_excel_column_name(idxCUTPath), ...
        rowCount + 1);

writecell( ...
    cutPathColumn, ...
    cfg.ManagementExcel, ...
    'Sheet', cfg.ManagementSheet, ...
    'Range', range);


%% ============================================================
% Result table / log
%% ============================================================

R = table( ...
    ExcelRow, ...
    CUTName, ...
    Depth, ...
    ExistingPath, ...
    TemporaryPath, ...
    WrittenPath, ...
    PathExists, ...
    Status, ...
    Message, ...
    Timestamp);

try
    st_write_result(cfg.DepthPathResultSheet, R);
catch ME
    warning('Could not write DepthPathResult log: %s', ME.message);
end

fprintf('\n');
fprintf('============================================\n');
fprintf('Temporary CUTPath generation complete\n');
fprintf('Result sheet : %s\n', cfg.DepthPathResultSheet);

foundCount = sum(strcmp(Status, 'OK_EXISTS'));
notFoundCount = sum(strcmp(Status, 'TEMP_NOT_FOUND'));

fprintf('Existing path matches : %d\n', foundCount);
fprintf('Manual-check paths    : %d\n', notFoundCount);
fprintf('============================================\n');

end


%% ============================================================
% Exact Subsystem path check
%% ============================================================

function tf = st_depth_subsystem_exists(blockPath)

tf = false;

try
    handle = getSimulinkBlockHandle(blockPath);

    if handle == -1
        return;
    end

    tf = ...
        strcmp( ...
            get_param(handle, 'BlockType'), ...
            'SubSystem');
catch
    tf = false;
end

end


%% ============================================================
% Escape literal slash in a block name for a Simulink path
%% ============================================================

function out = st_depth_escape_block_name(value)

out = ...
    strrep( ...
        char(value), ...
        '/', ...
        '//');

end


%% ============================================================
% Header helpers
%% ============================================================

function idx = st_depth_find_column(headers, aliases)

idx = st_depth_find_column_optional(headers, aliases);

if isempty(idx)
    error( ...
        'Required Excel column not found. Accepted names: %s', ...
        strjoin(aliases, ', '));
end

end


function idx = st_depth_find_column_optional(headers, aliases)

idx = [];
normalizedHeaders = lower(strtrim(headers));

for i = 1:numel(aliases)

    alias = lower(strtrim(string(aliases{i})));

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

function text = st_depth_cell_text(value)

if st_depth_cell_is_missing(value)
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


function tf = st_depth_cell_is_missing(value)

tf = isempty(value);

if tf
    return;
end

try
    missingMask = ismissing(value);
    tf = all(missingMask(:));
catch
    tf = false;
end

end


function [value, ok] = st_depth_numeric_value(rawValue)

value = nan;
ok = false;

if st_depth_cell_is_missing(rawValue)
    return;
end

if isnumeric(rawValue)
    value = double(rawValue(1));
else
    value = str2double(strtrim(string(rawValue)));
end

if ~isscalar(value) || ...
        ~isfinite(value) || ...
        value < 0 || ...
        floor(value) ~= value

    value = nan;
    return;
end

ok = true;

end


function tf = st_depth_enabled_value(value)

if st_depth_cell_is_missing(value)
    tf = false;
    return;
end

if islogical(value)
    tf = value(1);
elseif isnumeric(value)
    tf = isfinite(value(1)) && value(1) ~= 0;
else
    s = lower(strtrim(string(value)));
    tf = ismember(s, {'true','1','yes','y','on','사용','o'});
end

end


%% ============================================================
% Excel column number -> A / B / AA ...
%% ============================================================

function name = st_depth_excel_column_name(index)

name = '';

while index > 0

    remainder = mod(index - 1, 26);

    name = ...
        [char(double('A') + remainder) name]; %#ok<AGROW>

    index = floor((index - 1) / 26);
end

end


function text = st_depth_timestamp()

text = ...
    string( ...
        datetime( ...
            'now', ...
            'Format', ...
            'yyyy-MM-dd HH:mm:ss'));

end
