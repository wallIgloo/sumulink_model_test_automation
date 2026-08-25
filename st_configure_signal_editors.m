function R = st_configure_signal_editors()
%ST_CONFIGURE_SIGNAL_EDITORS Configure existing harness Signal Editor blocks.
% - Direct CUT Inport exists: SampleTime=0.01 and first scenario rename.
% - Input values/waveforms are not changed.

cfg = st_config();
T = st_load_targets(cfg.OnlyEnabled);
load_system(cfg.TopModel);
st_force_model_stopped(cfg.TopModel);

n = height(T);
SignalEditorBlock = strings(n,1);
DataFile = strings(n,1);
OldScenario = strings(n,1);
NewScenario = strings(n,1);
Status = strings(n,1);
Message = strings(n,1);
Timestamp = strings(n,1);

for i = 1:n
    ownerPath = st_normalize_cut_path(T.CUTPath(i), cfg.TopModel);
    harnessName = char(T.HarnessName(i));
    scenarioName = st_scenario_name(T.CUTName(i));
    NewScenario(i) = string(scenarioName);

    try
        inports = find_system(ownerPath, ...
            'SearchDepth', 1, ...
            'Type', 'Block', ...
            'BlockType', 'Inport');

        if isempty(inports)
            Status(i) = 'SKIP_NO_INPORT';
            Message(i) = 'CUT has no direct Inport';
            Timestamp(i) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
            fprintf('[%d/%d] SKIP %s: no direct Inport\n', i, n, char(T.CUTName(i)));
            continue;
        end

        st_force_model_stopped(cfg.TopModel);
        sltest.harness.load(ownerPath, harnessName);

        sigBlock = st_find_signal_editor_block(harnessName);
        SignalEditorBlock(i) = string(sigBlock);
        set_param(sigBlock, 'SampleTime', cfg.SignalEditorSampleTime);

        options = st_normalize_options(get_param(sigBlock, 'options@ActiveScenario'));
        if isempty(options)
            error('Signal Editor has no scenario: %s', sigBlock);
        end

        oldName = options{1};
        OldScenario(i) = string(oldName);

        fileName = get_param(sigBlock, 'Filename');
        matPath = st_resolve_data_file(fileName, cfg.TopModel);
        DataFile(i) = string(matPath);

        if ~strcmp(oldName, scenarioName)
            dc = Simulink.data.connect(matPath);
            vars = who(dc);

            if any(strcmp(vars, scenarioName))
                error('Scenario already exists in MAT file: %s', scenarioName);
            end

            ok = rename(dc, oldName, scenarioName);
            if ~all(ok)
                error('Failed to rename Signal Editor scenario: %s -> %s', oldName, scenarioName);
            end
            saveChanges(dc);
        end

        set_param(sigBlock, 'ActiveScenario', scenarioName);
        save_system(cfg.TopModel);
        st_close_harness_quiet(ownerPath, harnessName);

        Status(i) = 'OK';
        Message(i) = ['SampleTime=' cfg.SignalEditorSampleTime];
        fprintf('[%d/%d] OK   %s -> %s\n', i, n, harnessName, scenarioName);

    catch ME
        st_close_harness_quiet(ownerPath, harnessName);
        Status(i) = 'FAIL';
        Message(i) = string(ME.message);
        fprintf('[%d/%d] FAIL %s: %s\n', i, n, harnessName, ME.message);
    end

    Timestamp(i) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end

R = table(T.No, T.CUTName, T.HarnessName, SignalEditorBlock, DataFile, ...
    OldScenario, NewScenario, Status, Message, Timestamp, ...
    'VariableNames', {'No','CUTName','HarnessName','SignalEditorBlock','DataFile', ...
    'OldScenario','NewScenario','Status','Message','Timestamp'});

st_write_result('SignalEditorResult', R);
end

function st_close_harness_quiet(ownerPath, harnessName)
try
    sltest.harness.close(ownerPath, harnessName);
catch
end
end
