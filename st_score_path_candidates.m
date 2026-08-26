function ranking = st_score_path_candidates( ...
        candidatePaths, ...
        excelRow, ...
        resolvedAnchors, ...
        modelName, ...
        anchorCount)
%ST_SCORE_PATH_CANDIDATES Rank ambiguous CUT paths using resolved paths.
%
% The algorithm does not assume that the previous Excel row is the parent.
% Instead, already resolved CUT paths are used as anchors.
%
% Strong structural hints:
%   - candidate is inside an already resolved CUT
%   - candidate contains an already resolved CUT
%   - candidate shares the same parent / deep common ancestor
%   - candidate is close to an anchor in Excel row order
%
% Inputs
%   candidatePaths  : cell array / string array of full Simulink paths
%   excelRow        : physical Excel row number of the current CUT
%   resolvedAnchors : table with ExcelRow, CUTName, CUTPath
%   modelName       : selected top model name
%   anchorCount     : number of strongest anchors used in final score
%
% Output table
%   CandidatePath
%   RelativePath
%   Parent
%   Grandparent
%   Score
%   BestAnchor
%   BestAnchorRow
%   BestRelation

if nargin < 5 || isempty(anchorCount)
    anchorCount = 3;
end

candidatePaths = st_to_cellstr(candidatePaths);

n = numel(candidatePaths);

CandidatePath = strings(n,1);
RelativePath = strings(n,1);
Parent = strings(n,1);
Grandparent = strings(n,1);
Score = zeros(n,1);
BestAnchor = strings(n,1);
BestAnchorRow = nan(n,1);
BestRelation = strings(n,1);

for i = 1:n

    candidate = candidatePaths{i};

    CandidatePath(i) = string(candidate);
    RelativePath(i) = string(st_relative_model_path(candidate, modelName));

    [parentName, grandparentName] = st_parent_names(candidate);

    Parent(i) = string(parentName);
    Grandparent(i) = string(grandparentName);

    if isempty(resolvedAnchors) || height(resolvedAnchors) == 0
        continue;
    end

    anchorScores = zeros(height(resolvedAnchors),1);
    anchorRelations = strings(height(resolvedAnchors),1);

    for a = 1:height(resolvedAnchors)

        anchorPath = char(resolvedAnchors.CUTPath(a));
        rowDelta = abs(excelRow - double(resolvedAnchors.ExcelRow(a)));

        [structuralScore, relation] = ...
            st_path_relation_score(candidate, anchorPath, modelName);

        % Excel order is a hint, never a parent/child assumption.
        % Nearby resolved rows matter more, but distant structural anchors
        % can still contribute.
        rowWeight = 1 / (1 + 0.35 * max(rowDelta - 1, 0));

        % A resolved CUT immediately above the current row is useful as a
        % navigation hint, but only a small bonus is added.
        directionBonus = 0;

        if double(resolvedAnchors.ExcelRow(a)) < excelRow

            if rowDelta == 1
                directionBonus = 8;
            elseif rowDelta == 2
                directionBonus = 4;
            end
        end

        anchorScores(a) = ...
            structuralScore * rowWeight + directionBonus;

        anchorRelations(a) = string(relation);
    end

    [sortedScores, order] = sort(anchorScores, 'descend');

    keepCount = min(anchorCount, numel(sortedScores));

    if keepCount > 0

        % The best anchor dominates. Additional anchors provide supporting
        % evidence without allowing many weak anchors to overwhelm it.
        weights = [1.00 0.45 0.20];

        if keepCount > numel(weights)
            extra = 0.10 * ones(1, keepCount - numel(weights));
            weights = [weights extra]; %#ok<AGROW>
        end

        weights = weights(1:keepCount);

        Score(i) = ...
            sum(sortedScores(1:keepCount).' .* weights);

        bestIndex = order(1);

        BestAnchor(i) = string( ...
            st_relative_model_path( ...
                char(resolvedAnchors.CUTPath(bestIndex)), ...
                modelName));

        BestAnchorRow(i) = ...
            double(resolvedAnchors.ExcelRow(bestIndex));

        BestRelation(i) = ...
            anchorRelations(bestIndex);
    end
end

ranking = table( ...
    CandidatePath, ...
    RelativePath, ...
    Parent, ...
    Grandparent, ...
    Score, ...
    BestAnchor, ...
    BestAnchorRow, ...
    BestRelation);

[~, order] = sortrows( ...
    [ranking.Score, -double((1:height(ranking)).')], ...
    [-1 -1]);

ranking = ranking(order,:);

end


%% ============================================================
% Structural relation score
%% ============================================================

function [score, relation] = ...
    st_path_relation_score( ...
        candidatePath, ...
        anchorPath, ...
        modelName)

candidateParts = st_path_parts(candidatePath);
anchorParts = st_path_parts(anchorPath);

commonDepth = st_common_prefix_depth(candidateParts, anchorParts);

% The selected model name is common to every path, so it provides no
% discrimination. Remove that constant level from the depth score.
commonBelowModel = max(commonDepth - 1, 0);

treeDistance = ...
    (numel(candidateParts) - commonDepth) + ...
    (numel(anchorParts) - commonDepth);

candidateIsDescendant = ...
    numel(candidateParts) > numel(anchorParts) && ...
    commonDepth == numel(anchorParts);

candidateIsAncestor = ...
    numel(anchorParts) > numel(candidateParts) && ...
    commonDepth == numel(candidateParts);

sameParent = ...
    numel(candidateParts) >= 2 && ...
    numel(anchorParts) >= 2 && ...
    st_parts_equal( ...
        candidateParts(1:end-1), ...
        anchorParts(1:end-1));

sameGrandparent = false;

if numel(candidateParts) >= 3 && ...
        numel(anchorParts) >= 3

    sameGrandparent = ...
        st_parts_equal( ...
            candidateParts(1:end-2), ...
            anchorParts(1:end-2));
end

score = ...
    commonBelowModel * 12 - ...
    treeDistance * 3;

relation = 'COMMON_ANCESTOR';

if candidateIsDescendant

    depthDifference = ...
        numel(candidateParts) - numel(anchorParts);

    score = score + 110 + max(0, 30 - 5 * (depthDifference - 1));
    relation = 'DESCENDANT_OF_ANCHOR';

elseif candidateIsAncestor

    depthDifference = ...
        numel(anchorParts) - numel(candidateParts);

    score = score + 90 + max(0, 20 - 5 * (depthDifference - 1));
    relation = 'ANCESTOR_OF_ANCHOR';

elseif sameParent

    score = score + 65;
    relation = 'SAME_PARENT';

elseif sameGrandparent

    score = score + 35;
    relation = 'SAME_GRANDPARENT';

elseif commonBelowModel == 0

    relation = 'MODEL_ONLY';
end

% Avoid negative totals. A zero score simply means that no useful anchor
% relationship was found.
score = max(score, 0);

end


%% ============================================================
% Path helpers
%% ============================================================

function parts = st_path_parts(pathValue)

pathValue = strrep(char(pathValue), char(92), '/');
pathValue = strtrim(pathValue);

while ~isempty(pathValue) && pathValue(1) == '/'
    pathValue(1) = [];
end

while ~isempty(pathValue) && pathValue(end) == '/'
    pathValue(end) = [];
end

if isempty(pathValue)
    parts = {};
else
    parts = strsplit(pathValue, '/');
end

end


function depth = st_common_prefix_depth(a, b)

limit = min(numel(a), numel(b));
depth = 0;

for i = 1:limit

    if strcmp(a{i}, b{i})
        depth = depth + 1;
    else
        break;
    end
end

end


function tf = st_parts_equal(a, b)

if numel(a) ~= numel(b)
    tf = false;
    return;
end

tf = all(strcmp(a, b));

end


function [parentName, grandparentName] = st_parent_names(pathValue)

parts = st_path_parts(pathValue);

parentName = '';
grandparentName = '';

if numel(parts) >= 2
    parentName = parts{end-1};
end

if numel(parts) >= 3
    grandparentName = parts{end-2};
end

end


function relativePath = st_relative_model_path(pathValue, modelName)

pathValue = strrep(char(pathValue), char(92), '/');
modelName = char(modelName);

prefix = [modelName '/'];

if length(pathValue) >= length(prefix) && ...
        strncmp(pathValue, prefix, length(prefix))

    relativePath = pathValue(length(prefix)+1:end);

elseif strcmp(pathValue, modelName)

    relativePath = '';

else

    relativePath = pathValue;
end

end


function c = st_to_cellstr(value)

if isempty(value)
    c = {};
elseif iscell(value)
    c = cellfun(@char, value(:), 'UniformOutput', false);
elseif isstring(value)
    c = cellstr(value(:));
elseif ischar(value)
    c = {value};
else
    c = cellstr(string(value(:)));
end

end
