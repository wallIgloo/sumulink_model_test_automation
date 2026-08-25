function st_prepare_assessment_scenario(assessmentBlock, scenarioName, verifyAction)
%ST_PREPARE_ASSESSMENT_SCENARIO Normalize to one scenario and two steps.
%
%   scenarioName
%      step1 --true--> step2
%      step1 Action: empty
%      step2 Action: verifyAction

assessmentBlock = char(assessmentBlock);
scenarioName = char(scenarioName);
verifyAction = char(verifyAction);

if ~sltest.testsequence.isUsingScenarios(assessmentBlock)
    sltest.testsequence.useScenario(assessmentBlock, scenarioName);
else
    scenarios = sltest.testsequence.getAllScenarios(assessmentBlock);
    scenarios = normalize_cellstr(scenarios);
    if isempty(scenarios)
        error('Scenario mode is enabled but no scenario exists: %s', assessmentBlock);
    end

    keepScenario = scenarios{1};
    for k = numel(scenarios):-1:2
        sltest.testsequence.deleteScenario(assessmentBlock, scenarios{k});
    end

    if ~strcmp(keepScenario, scenarioName)
        sltest.testsequence.editScenario(assessmentBlock, keepScenario, ...
            'Name', scenarioName);
    end
end

sltest.testsequence.activateScenario(assessmentBlock, scenarioName);

prefix = [scenarioName '.'];
steps = normalize_cellstr(sltest.testsequence.findStep(assessmentBlock));
scenarioSteps = steps(strncmp_many(steps, prefix));

topSteps = {};
for i = 1:numel(scenarioSteps)
    rest = scenarioSteps{i}(length(prefix)+1:end);
    if isempty(strfind(rest, '.')) %#ok<STREMP>
        topSteps{end+1,1} = scenarioSteps{i}; %#ok<AGROW>
    end
end

if isempty(topSteps)
    step1Path = [prefix 'step1'];
    sltest.testsequence.addStep(assessmentBlock, step1Path, ...
        'Action', '', 'IsWhenStep', false);
else
    keepStep = topSteps{1};

    % Delete all other top-level steps. Their children are deleted with them.
    for k = numel(topSteps):-1:2
        sltest.testsequence.deleteStep(assessmentBlock, topSteps{k});
    end

    % Delete children of the step that will become step1.
    steps = normalize_cellstr(sltest.testsequence.findStep(assessmentBlock));
    childPrefix = [keepStep '.'];
    children = steps(strncmp_many(steps, childPrefix));
    [~, order] = sort(cellfun(@length, children), 'descend');
    children = children(order);
    for k = 1:numel(children)
        try
            sltest.testsequence.deleteStep(assessmentBlock, children{k});
        catch
        end
    end

    % Delete transitions on the retained step.
    transitionCount = sltest.testsequence.readStep(assessmentBlock, ...
        keepStep, 'TransitionCount');
    for k = double(transitionCount):-1:1
        sltest.testsequence.deleteTransition(assessmentBlock, keepStep, k);
    end

    sltest.testsequence.editStep(assessmentBlock, keepStep, ...
        'Name', 'step1', ...
        'Action', '', ...
        'IsWhenStep', false);

    step1Path = [prefix 'step1'];
end

step2Path = [prefix 'step2'];
sltest.testsequence.addStepAfter(assessmentBlock, step2Path, step1Path, ...
    'Action', verifyAction, ...
    'IsWhenStep', false);
sltest.testsequence.addTransition(assessmentBlock, step1Path, 'true', step2Path);
end

function c = normalize_cellstr(v)
if isempty(v)
    c = {};
elseif iscell(v)
    c = cellfun(@char, v(:), 'UniformOutput', false);
elseif isstring(v)
    c = cellstr(v(:));
elseif ischar(v)
    c = {v};
else
    c = cellstr(string(v(:)));
end
end

function mask = strncmp_many(c, prefix)
mask = false(size(c));
for i = 1:numel(c)
    mask(i) = length(c{i}) >= length(prefix) && ...
        strncmp(c{i}, prefix, length(prefix));
end
end
