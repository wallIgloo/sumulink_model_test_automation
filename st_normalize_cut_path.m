function cutPath = st_normalize_cut_path(cutPath, modelName)
%ST_NORMALIZE_CUT_PATH Normalize Excel CUT path to a Simulink full path.
%
% Examples normalized to TOP/A/B:
%   /TOP/A/B
%   TOP/A/B
%   TOP/TOP/A/B
%   A/B

cutPath = st_scalar_text(cutPath);
modelName = st_scalar_text(modelName);
cutPath = strtrim(cutPath);

% Convert Windows-style separator to Simulink separator.
cutPath(cutPath == char(92)) = '/';

% Remove leading slash characters.
while ~isempty(cutPath) && cutPath(1) == '/'
    cutPath(1) = [];
end

% Remove accidental TOP/TOP/... duplication.
doublePrefix = [modelName '/' modelName '/'];
while length(cutPath) >= length(doublePrefix) && ...
        strncmp(cutPath, doublePrefix, length(doublePrefix))
    cutPath = cutPath(length(modelName) + 2:end);
end

% Add top model only when the path is relative.
modelPrefix = [modelName '/'];
if ~strcmp(cutPath, modelName) && ...
        ~(length(cutPath) >= length(modelPrefix) && ...
          strncmp(cutPath, modelPrefix, length(modelPrefix)))
    cutPath = [modelName '/' cutPath];
end

end

function out = st_scalar_text(v)
if iscell(v)
    if isempty(v)
        out = '';
        return;
    end
    v = v{1};
end
if isstring(v)
    if isempty(v) || ismissing(v)
        out = '';
        return;
    end
    out = char(v(1));
elseif ischar(v)
    out = v;
elseif isnumeric(v) || islogical(v)
    out = char(string(v));
else
    out = char(string(v));
end
end
