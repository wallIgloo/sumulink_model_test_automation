function R = st_configure_assessments()
%ST_CONFIGURE_ASSESSMENTS Configure Test Assessment in existing harnesses.
%
% cfg.VerifyAllAssessmentInputs = false
%   - Compile Top Model once.
%   - Verify direct CUT Outports only.
%
% cfg.VerifyAllAssessmentInputs = true
%   - Do not compile Top Model for target collection.
%   - Verify every Input Data Symbol registered in Test Assessment.
%
% Common Assessment structure:
%   Scenario: UT_REQ_{CUTName}_001
%   step1 Action: empty
%   step1 -> step2 condition: true
%   step2 Action: verify statements, expected value = 0

cfg = st_config();
T = st_load_targets(cfg.OnlyEnabled);
load_system(cfg.TopModel);
st_force_model_stopped(cfg.TopModel);

n = height(T);

% Direct CUT Outport mode needs one Top Model compile.
directSpecs = [];
if ~cfg.VerifyAllAssessmentInputs
    fprintf('\n=== Collect direct CUT Outport information ===\n');
    directSpecs = st_collect_output_specs(T, cfg.TopModel);
end

CUTPath = strings(n,1);
AssessmentBlock = strings(n,1);
ScenarioName = strings(n,1);
VerifyMode = strings(n,1);
VerifyTargetCount = zeros(n,1);
VerifyCount = zeros(n,1);
Status = strings(n,1);
Message = strings(n,1);
Timestamp = strings(n,1);

fprintf('\n=== Configure Test Assessment ===\n');

for i = 1:n
    ownerPath = st_normalize_cut_path(T.CUTPath(i), cfg.TopModel);
    harnessName = char(T.HarnessName(i));
    scenarioName = st_scenario_name(T.CUTName(i));

    CUTPath(i) = string(ownerPath);
    ScenarioName(i) = string(scenarioName);

    if cfg.VerifyAllAssessmentInputs
        VerifyMode(i) = 'ALL_ASSESSMENT_INPUTS';
    else
        VerifyMode(i) = 'DIRECT_CUT_OUTPORTS';
    end

    % In direct mode, skip a CUT whose compile/spec collection failed.
    if ~cfg.VerifyAllAssessmentInputs && ~strcmp(directSpecs(i).Status, 'OK')
        Status(i) = 'FAIL';
        Message(i) = string(directSpecs(i).Message);
        Timestamp(i) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
        fprintf('[%d/%d] FAIL %s: %s\n', ...
            i, n, char(T.CUTName(i)), directSpecs(i).Message);
        continue;
    end

    try
        st_force_model_stopped(cfg.TopModel);
        sltest.harness.load(ownerPath, harnessName);

        assess = st_find_assessment_block(harnessName);
        AssessmentBlock(i) = string(assess);

        if cfg.VerifyAllAssessmentInputs
            % Every Input Data Symbol already registered in Assessment.
            targets = st_collect_assessment_input_specs(assess);
        else
            % Existing behavior: direct CUT Outports only.
            targets = directSpecs(i).Signals(:, {'Name','Width'});

            % The direct CUT output must actually be registered as an
            % Assessment Input symbol before it can be referenced in verify.
            inputSymbols = sltest.testsequence.findSymbol(assess, ...
                'Kind', 'Data', ...
                'Scope', 'Input');
            inputSymbols = normalize_cellstr(inputSymbols);

            for k = 1:height(targets)
                sigName = char(targets.Name(k));
                if ~any(strcmp(inputSymbols, sigName))
                    error('Assessment Input symbol not found for CUT Outport: %s', sigName);
                end
            end
        end

        VerifyTargetCount(i) = height(targets);
        [verifyAction, verifyCount] = st_build_verify_action(targets);
        VerifyCount(i) = verifyCount;

        st_prepare_assessment_scenario(assess, scenarioName, verifyAction);

        % Internal harness changes are saved in the main model.
        save_system(cfg.TopModel);
        st_close_harness_quiet(ownerPath, harnessName);

        Status(i) = 'OK';
        Message(i) = sprintf('targets=%d, verify=%d', height(targets), verifyCount);
        fprintf('[%d/%d] OK   %s: targets %d, verify %d\n', ...
            i, n, char(T.CUTName(i)), height(targets), verifyCount);

    catch ME
        st_close_harness_quiet(ownerPath, harnessName);
        Status(i) = 'FAIL';
        Message(i) = string(ME.message);
        fprintf('[%d/%d] FAIL %s: %s\n', ...
            i, n, char(T.CUTName(i)), ME.message);
    end

    Timestamp(i) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end

R = table(T.No, T.CUTName, CUTPath, T.HarnessName, AssessmentBlock, ...
    ScenarioName, VerifyMode, VerifyTargetCount, VerifyCount, ...
    Status, Message, Timestamp, ...
    'VariableNames', {'No','CUTName','CUTPath','HarnessName','AssessmentBlock', ...
    'ScenarioName','VerifyMode','VerifyTargetCount','VerifyCount', ...
    'Status','Message','Timestamp'});

st_write_result('AssessmentResult', R);
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

function st_close_harness_quiet(ownerPath, harnessName)
try
    sltest.harness.close(ownerPath, harnessName);
catch
end
end
