function resultObj = st_run_generated_tests()
%ST_RUN_GENERATED_TESTS
% 생성된 Test File의 Enabled Test Case를 모두 실행합니다.
%
% 직접 실행:
%   resultObj = st_run_generated_tests();
%
% TestFile.run은 해당 Test File의 Enabled Test Case들을 실행합니다.

cfg = st_config();

testFilePath = cfg.TestFile;

if ~isfile(testFilePath)

    error( ...
        'Test File을 찾을 수 없습니다: %s', ...
        testFilePath);
end


fprintf('\n');
fprintf('========================================\n');
fprintf('Run Generated Tests\n');
fprintf('Test File : %s\n', testFilePath);
fprintf('========================================\n');


%% Test File 열기

tf = sltest.testmanager.TestFile( ...
    testFilePath);


%% 테스트 실행

fprintf('Enabled Test Case 실행 시작...\n');

try

    resultObj = run(tf);

catch ME

    fprintf( ...
        'Test 실행 중 오류 발생: %s\n', ...
        ME.message);

    rethrow(ME);
end


fprintf('Test 실행 완료\n');

end