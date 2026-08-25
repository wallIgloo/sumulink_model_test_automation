function name = st_scenario_name(cutName)
%ST_SCENARIO_NAME Return UT_REQ_{CUTName}_001.

cutName = char(string(cutName));
name = ['UT_REQ_' cutName '_001'];

if ~isvarname(name)
    error('Scenario name is not a valid MATLAB variable name: %s', name);
end
end
