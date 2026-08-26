function st_run_from_harness()
%ST_RUN_FROM_HARNESS Full workflow starting before Harness creation.
%
% Recommended preparation:
%   st_find_target_paths
%
% Workflow:
%   1. Pre-Validate CUT paths
%   2. Create Harnesses
%   3. Configure Harnesses
%   4. Configure Signal Editor
%   5. Configure Test Assessment
%   6. Create Test Manager
%   7. Optionally run generated tests

cfg = st_require_runtime_target();


fprintf('\n');
fprintf('============================================\n');
fprintf('Simulink Test Full Automation\n');
fprintf('Model : %s\n', cfg.TopModel);
fprintf('============================================\n');


%% ============================================================
% 1. Pre-Validate
%% ============================================================

fprintf('\n============================================\n');
fprintf('[1/7] Pre-Validate CUT Paths\n');
fprintf('============================================\n');

R0 = st_pre_validate_targets();

if st_result_has_fail(R0)

    error( ...
        ['Pre-Validation failed. ' ...
         'Check PreValidationResult.']);
end


%% ============================================================
% 2. Harness creation
%% ============================================================

fprintf('\n============================================\n');
fprintf('[2/7] Create Harnesses\n');
fprintf('============================================\n');

R1 = st_create_harnesses();

if st_result_has_fail(R1)

    error( ...
        ['Harness creation failed. ' ...
         'Check HarnessCreateResult.']);
end


%% ============================================================
% 3. Harness configuration
%% ============================================================

fprintf('\n============================================\n');
fprintf('[3/7] Configure Harnesses\n');
fprintf('============================================\n');

R2 = st_configure_harnesses();

if st_result_has_fail(R2)

    error( ...
        ['Harness configuration failed. ' ...
         'Check HarnessConfigResult.']);
end


%% ============================================================
% 4. Signal Editor
%% ============================================================

fprintf('\n============================================\n');
fprintf('[4/7] Configure Signal Editor\n');
fprintf('============================================\n');

R3 = st_configure_signal_editors();

if st_result_has_fail(R3)

    error( ...
        ['Signal Editor configuration failed. ' ...
         'Check SignalEditorResult.']);
end


%% ============================================================
% 5. Test Assessment
%% ============================================================

fprintf('\n============================================\n');
fprintf('[5/7] Configure Test Assessment\n');
fprintf('============================================\n');

R4 = st_configure_assessments();

if st_result_has_fail(R4)

    error( ...
        ['Test Assessment configuration failed. ' ...
         'Check AssessmentResult.']);
end


%% ============================================================
% 6. Test Manager
%% ============================================================

fprintf('\n============================================\n');
fprintf('[6/7] Create Test Manager\n');
fprintf('============================================\n');

R5 = st_create_test_manager();

if st_result_has_fail(R5)

    error( ...
        ['Test Manager creation failed. ' ...
         'Check TestManagerResult.']);
end


%% ============================================================
% 7. Optional test execution
%% ============================================================

fprintf('\n============================================\n');
fprintf('[7/7] Run Generated Tests\n');
fprintf('============================================\n');

if cfg.RunGeneratedTests

    st_run_generated_tests();

else

    fprintf('cfg.RunGeneratedTests = false\n');
    fprintf('Generated test execution skipped.\n');
end


fprintf('\n');
fprintf('============================================\n');
fprintf('Full Automation Complete\n');
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
