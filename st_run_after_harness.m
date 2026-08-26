function st_run_after_harness()
%ST_RUN_AFTER_HARNESS Workflow when Harnesses already exist.
%
% Recommended preparation:
%   st_find_target_paths
%
% Workflow:
%   1. Validate CUT / Harness mapping
%   2. Configure Harnesses
%   3. Configure Signal Editor
%   4. Configure Test Assessment
%   5. Create Test Manager
%   6. Optionally run generated tests

cfg = st_require_runtime_target();


fprintf('\n');
fprintf('============================================\n');
fprintf('Existing-Harness Automation\n');
fprintf('Model : %s\n', cfg.TopModel);
fprintf('============================================\n');


%% ============================================================
% 1. Existing mapping validation
%% ============================================================

fprintf('\n============================================\n');
fprintf('[1/6] Validate CUT / Harness Mapping\n');
fprintf('============================================\n');

R0 = st_validate_targets();

if st_result_has_fail(R0)

    error( ...
        'Validation failed. Check ValidationResult.');
end


%% ============================================================
% 2. Harness configuration
%% ============================================================

fprintf('\n============================================\n');
fprintf('[2/6] Configure Harnesses\n');
fprintf('============================================\n');

R1 = st_configure_harnesses();

if st_result_has_fail(R1)

    error( ...
        'Harness configuration failed. Check HarnessConfigResult.');
end


%% ============================================================
% 3. Signal Editor
%% ============================================================

fprintf('\n============================================\n');
fprintf('[3/6] Configure Signal Editor\n');
fprintf('============================================\n');

R2 = st_configure_signal_editors();

if st_result_has_fail(R2)

    error( ...
        'Signal Editor configuration failed. Check SignalEditorResult.');
end


%% ============================================================
% 4. Test Assessment
%% ============================================================

fprintf('\n============================================\n');
fprintf('[4/6] Configure Test Assessment\n');
fprintf('============================================\n');

R3 = st_configure_assessments();

if st_result_has_fail(R3)

    error( ...
        'Test Assessment configuration failed. Check AssessmentResult.');
end


%% ============================================================
% 5. Test Manager
%% ============================================================

fprintf('\n============================================\n');
fprintf('[5/6] Create Test Manager\n');
fprintf('============================================\n');

R4 = st_create_test_manager();

if st_result_has_fail(R4)

    error( ...
        'Test Manager creation failed. Check TestManagerResult.');
end


%% ============================================================
% 6. Optional test execution
%% ============================================================

fprintf('\n============================================\n');
fprintf('[6/6] Run Generated Tests\n');
fprintf('============================================\n');

if cfg.RunGeneratedTests

    st_run_generated_tests();

else

    fprintf('cfg.RunGeneratedTests = false\n');
    fprintf('Generated test execution skipped.\n');
end


fprintf('\n');
fprintf('============================================\n');
fprintf('Existing-Harness Automation Complete\n');
fprintf('============================================\n');

end


function tf = st_result_has_fail(R)

if isempty(R) || ...
        ~istable(R) || ...
        ~ismember('Status', R.Properties.VariableNames)

    tf = false;
    return;
end

tf = ...
    any(strcmp(R.Status, 'FAIL'));

end
