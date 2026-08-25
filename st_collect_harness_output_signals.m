function outputs = st_collect_harness_output_signals(harnessName)
%ST_COLLECT_HARNESS_OUTPUT_SIGNALS Collect top-level Harness Outport signals.
%
% Only Outport blocks directly under the harness root are collected.
% Outports inside nested subsystems are ignored.
%
% Output table columns:
%   Port         - Harness Outport port number
%   SignalName   - Name of the line connected to the Outport input
%                  (empty line name falls back to Outport block name)
%   OutportBlock - Harness Outport block name
%
% This function does not compile the model.

harnessName = char(harnessName);

if ~bdIsLoaded(harnessName)
    error('Harness is not loaded: %s', harnessName);
end

outportBlocks = find_system(harnessName, ...
    'SearchDepth', 1, ...
    'Type', 'Block', ...
    'BlockType', 'Outport');

n = numel(outportBlocks);

Port = zeros(n,1);
SignalName = strings(n,1);
OutportBlock = strings(n,1);

for i = 1:n

    blockPath = outportBlocks{i};

    Port(i) = str2double( ...
        get_param(blockPath, 'Port'));

    OutportBlock(i) = string( ...
        get_param(blockPath, 'Name'));

    portHandles = get_param( ...
        blockPath, ...
        'PortHandles');

    if isempty(portHandles.Inport) || ...
            portHandles.Inport == -1

        error( ...
            'Harness Outport has no input port handle: %s', ...
            blockPath);
    end

    lineHandle = get_param( ...
        portHandles.Inport, ...
        'Line');

    if lineHandle == -1

        % 연결되지 않은 Outport는 verify 대상에서 제외됩니다.
        SignalName(i) = '';

        continue;
    end

    lineName = get_param( ...
        lineHandle, ...
        'Name');

    if isempty(lineName)

        % 자동 생성된 Harness에서는 line name이 비어 있어도
        % Outport block name이 실제 signal name과 같은 경우가 많습니다.
        lineName = get_param( ...
            blockPath, ...
            'Name');
    end

    SignalName(i) = string(lineName);
end


%% Port 순으로 정렬

[Port, idx] = sort(Port);

SignalName = SignalName(idx);
OutportBlock = OutportBlock(idx);


%% 결과

outputs = table( ...
    Port, ...
    SignalName, ...
    OutportBlock);

end