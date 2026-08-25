function specs = st_collect_assessment_input_specs(assessmentBlock)
%ST_COLLECT_ASSESSMENT_INPUT_SPECS Collect all Input Data Symbols.
%
% Output table columns:
%   Name      - Assessment Input symbol name
%   Width     - Number of elements used for verify generation
%   SizeText  - Raw Size property from readSymbol
%   DataType  - Raw DataType property from readSymbol
%
% Size handling:
%   empty Size -> scalar assumption (Width=1)
%   numeric Size or simple numeric text such as '[2 3]' -> prod(Size)
%   nonnumeric/expression Size -> error, because safe element count cannot be
%   determined without compiling the harness.

assessmentBlock = char(assessmentBlock);

symbols = sltest.testsequence.findSymbol(assessmentBlock, ...
    'Kind', 'Data', ...
    'Scope', 'Input');
symbols = normalize_cellstr(symbols);

n = numel(symbols);
Name = strings(n,1);
Width = zeros(n,1);
SizeText = strings(n,1);
DataType = strings(n,1);

for i = 1:n
    symbolName = symbols{i};
    info = sltest.testsequence.readSymbol(assessmentBlock, symbolName);

    Name(i) = string(symbolName);

    if isfield(info, 'DataType')
        DataType(i) = string(info.DataType);
    end

    if isfield(info, 'Size')
        SizeText(i) = string(size_to_text(info.Size));
        Width(i) = size_to_width(info.Size, symbolName);
    else
        SizeText(i) = '';
        Width(i) = 1;
    end
end

specs = table(Name, Width, SizeText, DataType);
end

function width = size_to_width(value, symbolName)
if isempty(value)
    width = 1;
    return;
end

if isnumeric(value)
    dims = double(value(:));
    if isempty(dims)
        width = 1;
        return;
    end
    if any(~isfinite(dims)) || any(dims < 1) || any(mod(dims,1) ~= 0)
        error('Unsupported Assessment Size for symbol %s.', symbolName);
    end
    width = prod(dims);
    return;
end

s = strtrim(char(string(value)));
if isempty(s)
    width = 1;
    return;
end

% Accept only simple integer dimension text, for example:
%   '1', '4', '[1 4]', '[2,3]', '[2;3]'
if isempty(regexp(s, '^[\[\]\d\s,;]+$', 'once'))
    error(['Cannot determine element count from Assessment Size for symbol %s: %s. ' ...
        'Use an explicit numeric Size in the Assessment symbol or use direct CUT Outport mode.'], ...
        symbolName, s);
end

clean = regexprep(s, '[\[\],;]', ' ');
dims = sscanf(clean, '%d');
if isempty(dims) || any(dims < 1)
    error('Invalid Assessment Size for symbol %s: %s', symbolName, s);
end

width = prod(double(dims));
end

function text = size_to_text(value)
if isempty(value)
    text = '';
elseif isnumeric(value)
    text = mat2str(value);
else
    text = char(string(value));
end
end

function c = normalize_cellstr(v)
if isempty(v)
    c = {};
elseif iscell(v)
    c = cellfun(@char, v(:), 'UniformOutput', false);
elseif isstring(v)
    c = cellstr(v(:));
elseif ischar(v)
    c = {v};
else
    c = cellstr(string(v(:)));
end
end
