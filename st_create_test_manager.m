function R = st_create_test_manager()
%ST_CREATE_TEST_MANAGER Create Test Manager test cases from management Excel.
%
% Test File : {TopModel}.mldatx
% Suite     : New Test Suite 1
% Test Case : Excel TestCaseName
% SUT       : TopModel + existing Harness
%
% Test Case Inputs:
%   Signal Editor Scenario : OFF at base Test Case level
%   Test Sequence Block    : Test Assessment block
%   Override with Scenario : not set at base Test Case level
%
% Table Iteration: one 'Iteration 1'
%   SignalEditorScenario = UT_REQ_{CUTName}_001
%   TestSequenceScenario = UT_REQ_{CUTName}_001
%
% Coverage:
%   RecordCoverage = true at Test File level and Test Case level.

cfg = st_config();
T = st_load_targets(cfg.OnlyEnabled);
load_system(cfg.TopModel);
st_force_model_stopped(cfg.TopModel);

if isfile(cfg.TestFile) && ~cfg.OverwriteTestFile
    error(['Test File already exists: ' cfg.TestFile sprintf('\n') ...
        'Set cfg.OverwriteTestFile = true in st_config.m to recreate it.']);
end

tf = sltest.testmanager.TestFile(cfg.TestFile, logical(cfg.OverwriteTestFile));

% Coverage must be enabled at the Test File level first.
covFile = getCoverageSettings(tf);
covFile.RecordCoverage = true;

ts = getTestSuiteByName(tf, cfg.TestSuiteName);
if isempty(ts)
    ts = createTestSuite(tf, cfg.TestSuiteName);
end

% Keep coverage enabled throughout the hierarchy.
covSuite = getCoverageSettings(ts);
covSuite.RecordCoverage = true;

% Keep the requested suite, remove its default/existing test cases.
existingCases = getTestCases(ts);
for k = 1:numel(existingCases)
    remove(existingCases(k));
end

n = height(T);
AssessmentBlock = strings(n,1);
ScenarioName = strings(n,1);
Status = strings(n,1);
Message = strings(n,1);
Timestamp = strings(n,1);

for i = 1:n
    ownerPath = st_normalize_cut_path(T.CUTPath(i), cfg.TopModel);
    harnessName = char(T.HarnessName(i));
    testCaseName = char(T.TestCaseName(i));
    scenarioName = st_scenario_name(T.CUTName(i));
    ScenarioName(i) = string(scenarioName);
    tc = [];

    try
        if isempty(testCaseName)
            error('TestCaseName is empty. Row No=%d', T.No(i));
        end

        st_force_model_stopped(cfg.TopModel);
        sltest.harness.load(ownerPath, harnessName);
        assess = st_find_assessment_block(harnessName);
        AssessmentBlock(i) = string(assess);

        tc = createTestCase(ts, 'simulation', testCaseName);

        % Base Test Case Inputs intentionally do NOT select either scenario.
        % Scenarios are selected only by Table Iteration below.
        setProperty(tc, ...
            'Model', cfg.TopModel, ...
            'HarnessOwner', ownerPath, ...
            'HarnessName', harnessName, ...
            'UseSignalEditorScenarios', false, ...
            'TestSequenceBlock', assess);

        iter = sltest.testmanager.TestIteration;
        iter.Enabled = true;
        setTestParam(iter, 'SignalEditorScenario', scenarioName);
        setTestParam(iter, 'TestSequenceScenario', scenarioName);
        addIteration(tc, iter, 'Iteration 1');

        % Explicitly keep test-case coverage enabled as well.
        covCase = getCoverageSettings(tc);
        covCase.RecordCoverage = true;

        st_close_harness_quiet(ownerPath, harnessName);
        Status(i) = 'OK';
        Message(i) = 'Test Case + Iteration 1 + Coverage created';
        fprintf('[%d/%d] OK   %s\n', i, n, testCaseName);

    catch ME
        st_close_harness_quiet(ownerPath, harnessName);
        if ~isempty(tc)
            try
                remove(tc);
            catch
            end
        end
        Status(i) = 'FAIL';
        Message(i) = string(ME.message);
        fprintf('[%d/%d] FAIL %s: %s\n', i, n, testCaseName, ME.message);
    end

    Timestamp(i) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end

saveToFile(tf);

R = table(T.No, T.CUTName, T.TestCaseName, T.HarnessName, AssessmentBlock, ...
    ScenarioName, Status, Message, Timestamp, ...
    'VariableNames', {'No','CUTName','TestCaseName','HarnessName','AssessmentBlock', ...
    'ScenarioName','Status','Message','Timestamp'});

st_write_result('TestManagerResult', R);
fprintf('Test Manager saved: %s\n', cfg.TestFile);
end

function st_close_harness_quiet(ownerPath, harnessName)
try
    sltest.harness.close(ownerPath, harnessName);
catch
end
end
