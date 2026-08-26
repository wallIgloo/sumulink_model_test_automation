function R = st_configure_harnesses()
%ST_CONFIGURE_HARNESSES Set StopTime on existing harnesses.

cfg = st_require_runtime_target();
T = st_load_targets(cfg.OnlyEnabled);
st_force_model_stopped(cfg.TopModel);

n = height(T);
Status = strings(n,1);
Message = strings(n,1);
Timestamp = strings(n,1);

for i = 1:n
    ownerPath = st_normalize_cut_path(T.CUTPath(i), cfg.TopModel);
    harnessName = char(T.HarnessName(i));

    try
        st_force_model_stopped(cfg.TopModel);
        sltest.harness.load(ownerPath, harnessName);
        set_param(harnessName, 'StopTime', cfg.HarnessStopTime);

        % Internal harness changes are stored in the main model SLX.
        save_system(cfg.TopModel);
        st_close_harness_quiet(ownerPath, harnessName);

        Status(i) = 'OK';
        Message(i) = ['StopTime=' cfg.HarnessStopTime];
        fprintf('[%d/%d] OK   %s StopTime=%s\n', i, n, harnessName, cfg.HarnessStopTime);
    catch ME
        st_close_harness_quiet(ownerPath, harnessName);
        Status(i) = 'FAIL';
        Message(i) = string(ME.message);
        fprintf('[%d/%d] FAIL %s: %s\n', i, n, harnessName, ME.message);
    end

    Timestamp(i) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end

R = table(T.No, T.CUTName, T.HarnessName, Status, Message, Timestamp, ...
    'VariableNames', {'No','CUTName','HarnessName','Status','Message','Timestamp'});
st_write_result('HarnessConfigResult', R);
end

function st_close_harness_quiet(ownerPath, harnessName)
try
    sltest.harness.close(ownerPath, harnessName);
catch
end
end
