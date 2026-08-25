function st_run_from_harness()
%ST_RUN_FROM_HARNESS
% Harness 생성부터 Test Manager까지 전체 실행

fprintf('\n=== 0/5 Validate Targets ===\n');

R0 = st_validate_targets();

if any(strcmp(R0.Status, 'FAIL'))
    error('Validation failed. Check ValidationResult.');
end


fprintf('\n=== 1/5 Create Harnesses ===\n');

R1 = st_create_harnesses();

if any(strcmp(R1.Status, 'FAIL'))
    error('Harness creation failed. Check HarnessCreateResult.');
end


fprintf('\n=== 2/5 Configure Harnesses ===\n');

R2 = st_configure_harnesses();

if any(strcmp(R2.Status, 'FAIL'))
    error('Harness configuration failed.');
end


fprintf('\n=== 3/5 Configure Signal Editor ===\n');

R3 = st_configure_signal_editors();

if any(strcmp(R3.Status, 'FAIL'))
    error('Signal Editor configuration failed.');
end


fprintf('\n=== 4/5 Configure Assessment ===\n');

R4 = st_configure_assessments();

if any(strcmp(R4.Status, 'FAIL'))
    error('Assessment configuration failed.');
end


fprintf('\n=== 5/5 Create Test Manager ===\n');

R5 = st_create_test_manager();

if any(strcmp(R5.Status, 'FAIL'))
    error('Test Manager creation failed.');
end

%% Test 실행 옵션

cfg = st_config();

if cfg.RunGeneratedTests

    fprintf('\n=== Run Generated Tests ===\n');

    st_run_generated_tests();

else

    fprintf('\nTest execution skipped.\n');
end

fprintf('\n========================================\n');
fprintf('Full automation complete\n');
fprintf('========================================\n');

end