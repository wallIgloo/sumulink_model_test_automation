function st_run_after_harness()
%ST_RUN_AFTER_HARNESS Main workflow when harnesses already exist.
%
% 0. Validate mapping
% 1. Harness StopTime
% 2. Signal Editor
% 3. Test Assessment
% 4. Test Manager

fprintf('\n=== 0/4 Validate CUT / Harness mapping ===\n');
R0 = st_validate_targets();
if any(strcmp(R0.Status, 'FAIL'))
    error('Validation failed. Check ValidationResult.');
end

fprintf('\n=== 1/4 Harness settings ===\n');
R1 = st_configure_harnesses();
if any(strcmp(R1.Status, 'FAIL'))
    error('Harness configuration failed. Check HarnessConfigResult.');
end

fprintf('\n=== 2/4 Signal Editor settings ===\n');
R2 = st_configure_signal_editors();
if any(strcmp(R2.Status, 'FAIL'))
    error('Signal Editor configuration failed. Check SignalEditorResult.');
end

fprintf('\n=== 3/4 Test Assessment settings ===\n');
R3 = st_configure_assessments();
if any(strcmp(R3.Status, 'FAIL'))
    error('Test Assessment configuration failed. Check AssessmentResult.');
end

fprintf('\n=== 4/4 Test Manager creation ===\n');
R4 = st_create_test_manager();
if any(strcmp(R4.Status, 'FAIL'))
    error('Test Manager creation failed. Check TestManagerResult.');
end

fprintf('\n========================================\n');
fprintf('Existing-harness automation completed.\n');
fprintf('========================================\n');
end
