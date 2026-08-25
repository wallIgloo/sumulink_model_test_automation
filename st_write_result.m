function st_write_result(sheetName, T)
%ST_WRITE_RESULT Save result to Excel when possible and always to CSV.

cfg = st_config();

if ~isfolder(cfg.ResultDir)
    mkdir(cfg.ResultDir);
end

csvPath = fullfile(cfg.ResultDir, [char(sheetName) '.csv']);
writetable(T, csvPath);

try
    writetable(T, cfg.ManagementExcel, ...
        'Sheet', char(sheetName), ...
        'WriteMode', 'overwritesheet');
catch ME
    warning('Could not write result sheet to Excel. CSV was saved instead. %s', ME.message);
end
end
