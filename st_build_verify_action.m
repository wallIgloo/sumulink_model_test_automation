function [verifyAction, verifyCount] = st_build_verify_action(targets)
%ST_BUILD_VERIFY_ACTION Build step2 verify statements from Name/Width table.
%
% Scalar:
%   verify(A == 0);
%
% Width > 1:
%   verify(A(1) == 0);
%   verify(A(2) == 0);
%   ...

if isempty(targets)
    verifyAction = '';
    verifyCount = 0;
    return;
end

required = {'Name','Width'};
for k = 1:numel(required)
    if ~ismember(required{k}, targets.Properties.VariableNames)
        error('Verify target table is missing column: %s', required{k});
    end
end

lines = {};

for i = 1:height(targets)
    name = char(targets.Name(i));
    width = double(targets.Width(i));

    if ~isvarname(name)
        error('Assessment symbol is not a valid MATLAB identifier: %s', name);
    end

    if isempty(width) || ~isfinite(width) || width < 1 || mod(width,1) ~= 0
        error('Invalid verify width for symbol %s: %g', name, width);
    end

    if width == 1
        lines{end+1,1} = sprintf('verify(%s == 0);', name); %#ok<AGROW>
    else
        for m = 1:width
            lines{end+1,1} = sprintf('verify(%s(%d) == 0);', name, m); %#ok<AGROW>
        end
    end
end

verifyCount = numel(lines);
if verifyCount == 0
    verifyAction = '';
else
    verifyAction = strjoin(lines, sprintf('\n'));
end
end
