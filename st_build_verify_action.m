function [verifyAction, verifyCount] = ...
    st_build_verify_action( ...
        targets, ...
        modelName, ...
        verifyFirstBusElementOnly)
%ST_BUILD_VERIFY_ACTION
% Test Assessment step2에 들어갈 verify 문을 생성합니다.
%
%
% 일반 Scalar:
%
%   verify(A == 0);
%
%
% 일반 Array:
%
%   verify(A(1) == 0);
%   verify(A(2) == 0);
%   ...
%
%
% Bus:
%
%   verify(data(1,1).NAME == 0);
%   verify(data(1,1).VALUE == 0);
%
%
% Bus Array:
%
% verifyFirstBusElementOnly == false
%
%   verify(a(1,1).aa == 0);
%   verify(a(1,1).ab == 0);
%
%   verify(a(1,2).aa == 0);
%   verify(a(1,2).ab == 0);
%
%
% verifyFirstBusElementOnly == true
%
%   verify(a(1,1).aa == 0);
%   verify(a(1,1).ab == 0);
%
%
% 일반 numeric array에는
% verifyFirstBusElementOnly 옵션이 영향을 주지 않습니다.


%% ============================================================
% Default Arguments
%% ============================================================

if nargin < 2

    modelName = '';
end


if nargin < 3

    verifyFirstBusElementOnly = false;
end


modelName = ...
    char(modelName);


%% ============================================================
% 대상 없음
%% ============================================================

if isempty(targets)

    verifyAction = '';
    verifyCount = 0;

    return;
end


%% ============================================================
% 필수 컬럼 확인
%% ============================================================

requiredColumns = { ...
    'Name', ...
    'Width'};


for k = 1:numel(requiredColumns)

    if ~ismember( ...
            requiredColumns{k}, ...
            targets.Properties.VariableNames)

        error( ...
            'Verify target table에 필요한 컬럼이 없습니다: %s', ...
            requiredColumns{k});
    end
end


%% ============================================================
% Verify Statement 생성
%% ============================================================

lines = {};


for i = 1:height(targets)

    %% --------------------------------------------------------
    % Symbol Name
    %% --------------------------------------------------------

    symbolName = ...
        char(targets.Name(i));


    if ~isvarname(symbolName)

        error( ...
            ['Assessment Symbol이 MATLAB 변수명으로 ' ...
             '사용할 수 없는 형태입니다: %s'], ...
            symbolName);
    end


    %% --------------------------------------------------------
    % Width
    %% --------------------------------------------------------

    width = ...
        double(targets.Width(i));


    if isempty(width) || ...
            ~isfinite(width) || ...
            width < 1 || ...
            mod(width,1) ~= 0

        error( ...
            '잘못된 Width입니다. Symbol=%s, Width=%g', ...
            symbolName, ...
            width);
    end


    %% --------------------------------------------------------
    % Dimensions
    %% --------------------------------------------------------

    dims = ...
        get_target_dimensions( ...
            targets, ...
            i, ...
            width);


    %% --------------------------------------------------------
    % Data Type
    %% --------------------------------------------------------

    dataType = ...
        get_target_datatype( ...
            targets, ...
            i);


    %% --------------------------------------------------------
    % Bus 여부 확인
    %% --------------------------------------------------------

    busName = ...
        parse_bus_name( ...
            dataType);


    %% ========================================================
    % 일반 Data
    %% ========================================================

    if isempty(busName)

        %% Scalar

        if width == 1

            lines{end+1,1} = ...
                sprintf( ...
                    'verify(%s == 0);', ...
                    symbolName); %#ok<AGROW>


        %% Array

        else

            for m = 1:width

                lines{end+1,1} = ...
                    sprintf( ...
                        'verify(%s(%d) == 0);', ...
                        symbolName, ...
                        m); %#ok<AGROW>
            end
        end


        continue;
    end


    %% ========================================================
    % Bus Data
    %% ========================================================

    if isempty(modelName)

        error( ...
            'Bus Type %s를 확인하려면 Top Model 이름이 필요합니다.', ...
            busName);
    end


    %% Bus Object 조회

    busObj = ...
        resolve_bus_object( ...
            modelName, ...
            busName);


    %% --------------------------------------------------------
    % Bus Array Expression 생성
    %% --------------------------------------------------------

    if verifyFirstBusElementOnly

        %% Bus 배열이라도 첫 번째 Bus 인스턴스만 사용
        %
        % [1 1]   -> a(1,1)
        % [1 4]   -> a(1,1)
        % [3 4]   -> a(1,1)
        % [2 3 4] -> a(1,1,1)

        busExpressions = { ...
            build_first_bus_expression( ...
                symbolName, ...
                dims)};

    else

        %% 모든 Bus 인스턴스 사용

        busExpressions = ...
            build_indexed_expressions( ...
                symbolName, ...
                dims, ...
                true);
    end


    %% --------------------------------------------------------
    % Bus Leaf 확장
    %% --------------------------------------------------------

    for b = 1:numel(busExpressions)

        busLines = ...
            expand_bus_leaves( ...
                busExpressions{b}, ...
                busObj, ...
                modelName, ...
                verifyFirstBusElementOnly);


        lines = [ ...
            lines; ...
            busLines(:)]; %#ok<AGROW>
    end
end


%% ============================================================
% 최종 Action
%% ============================================================

verifyCount = ...
    numel(lines);


if verifyCount == 0

    verifyAction = '';

else

    verifyAction = ...
        strjoin( ...
            lines, ...
            sprintf('\n'));
end

end


%% ============================================================
% Target Dimensions
%% ============================================================

function dims = ...
    get_target_dimensions( ...
        targets, ...
        row, ...
        width)


if ismember( ...
        'Dimensions', ...
        targets.Properties.VariableNames)

    value = ...
        targets.Dimensions{row};


    if isnumeric(value) && ...
            ~isempty(value)

        dims = ...
            double(value(:).');

        return;
    end
end


%% 이전 형식 fallback

if width == 1

    dims = [1 1];

else

    dims = [1 width];
end

end


%% ============================================================
% Target DataType
%% ============================================================

function dataType = ...
    get_target_datatype( ...
        targets, ...
        row)


if ismember( ...
        'DataType', ...
        targets.Properties.VariableNames)

    dataType = ...
        char(targets.DataType(row));

else

    dataType = '';
end

end


%% ============================================================
% Bus 이름 추출
%% ============================================================

function busName = ...
    parse_bus_name( ...
        dataType)


dataType = ...
    strtrim( ...
        char(dataType));


busName = '';


if isempty(dataType)

    return;
end


%% 예:
%
% Bus: SOME_BUS
% Bus: <SOME_BUS>

token = ...
    regexp( ...
        dataType, ...
        '^Bus:\s*(.+)$', ...
        'tokens', ...
        'once');


if isempty(token)

    return;
end


busName = ...
    strtrim(token{1});


%% <NAME> 형식 처리

if length(busName) >= 2 && ...
        busName(1) == '<' && ...
        busName(end) == '>'

    busName = ...
        busName(2:end-1);
end

end


%% ============================================================
% Bus Object 조회
%% ============================================================

function busObj = ...
    resolve_bus_object( ...
        modelName, ...
        busName)


try

    busObj = ...
        Simulink.data.evalinGlobal( ...
            modelName, ...
            busName);

catch ME

    error( ...
        'Bus Object %s를 찾을 수 없습니다: %s', ...
        busName, ...
        ME.message);
end


if ~isa(busObj, 'Simulink.Bus')

    error( ...
        '조회된 값이 Simulink.Bus가 아닙니다: %s', ...
        busName);
end

end


%% ============================================================
% Bus Leaf 재귀 탐색
%% ============================================================

function lines = ...
    expand_bus_leaves( ...
        parentExpr, ...
        busObj, ...
        modelName, ...
        verifyFirstBusElementOnly)


lines = {};


elements = ...
    busObj.Elements;


for i = 1:numel(elements)

    elem = ...
        elements(i);


    fieldName = ...
        char(elem.Name);


    fieldExpr = [ ...
        parentExpr ...
        '.' ...
        fieldName];


    fieldDims = ...
        normalize_bus_dimensions( ...
            elem.Dimensions);


    nestedBusName = ...
        parse_bus_name( ...
            elem.DataType);


    %% ========================================================
    % Nested Bus
    %% ========================================================

    if ~isempty(nestedBusName)

        nestedBus = ...
            resolve_bus_object( ...
                modelName, ...
                nestedBusName);


        %% Nested Bus Scalar

        if prod(fieldDims) == 1

            nestedExprs = { ...
                fieldExpr};


        %% Nested Bus Array - first element only

        elseif verifyFirstBusElementOnly

            nestedExprs = { ...
                build_first_bus_expression( ...
                    fieldExpr, ...
                    fieldDims)};


        %% Nested Bus Array - all elements

        else

            nestedExprs = ...
                build_indexed_expressions( ...
                    fieldExpr, ...
                    fieldDims, ...
                    true);
        end


        %% 재귀

        for n = 1:numel(nestedExprs)

            nestedLines = ...
                expand_bus_leaves( ...
                    nestedExprs{n}, ...
                    nestedBus, ...
                    modelName, ...
                    verifyFirstBusElementOnly);


            lines = [ ...
                lines; ...
                nestedLines(:)]; %#ok<AGROW>
        end


        continue;
    end


    %% ========================================================
    % 일반 Bus Leaf
    %% ========================================================

    leafWidth = ...
        prod(fieldDims);


    %% Scalar Leaf

    if leafWidth == 1

        lines{end+1,1} = ...
            sprintf( ...
                'verify(%s == 0);', ...
                fieldExpr); %#ok<AGROW>


    %% Array Leaf
    %
    % 중요:
    %
    % VerifyFirstBusElementOnly은
    % Bus 인스턴스 배열 반복만 줄입니다.
    %
    % Bus 내부 numeric array는 전부 verify합니다.
    %% ========================================================

    else

        for m = 1:leafWidth

            lines{end+1,1} = ...
                sprintf( ...
                    'verify(%s(%d) == 0);', ...
                    fieldExpr, ...
                    m); %#ok<AGROW>
        end
    end
end

end


%% ============================================================
% Bus Element Dimensions 정규화
%% ============================================================

function dims = ...
    normalize_bus_dimensions( ...
        value)


if isempty(value)

    dims = [1 1];


elseif isnumeric(value)

    dims = ...
        double(value(:).');


else

    s = ...
        strtrim( ...
            char(string(value)));


    clean = ...
        regexprep( ...
            s, ...
            '[\[\],;]', ...
            ' ');


    dims = ...
        double( ...
            sscanf( ...
                clean, ...
                '%d').');
end


if isempty(dims)

    dims = [1 1];
end


if any(~isfinite(dims)) || ...
        any(dims < 1) || ...
        any(mod(dims,1) ~= 0)

    error( ...
        '지원하지 않는 Bus Element Dimensions입니다.');
end


if numel(dims) == 1 && ...
        dims(1) == 1

    dims = [1 1];
end

end


%% ============================================================
% Bus 배열 첫 요소 Expression 생성
%% ============================================================

function expr = ...
    build_first_bus_expression( ...
        baseName, ...
        dims)
%BUILD_FIRST_BUS_EXPRESSION
%
% [1 1]   -> a(1,1)
% [1 3]   -> a(1,1)
% [2 4]   -> a(1,1)
% [2 3 4] -> a(1,1,1)


dims = ...
    double(dims(:).');


if isempty(dims)

    dims = [1 1];
end


indices = ...
    repmat( ...
        {'1'}, ...
        1, ...
        numel(dims));


expr = ...
    sprintf( ...
        '%s(%s)', ...
        baseName, ...
        strjoin( ...
            indices, ...
            ','));

end


%% ============================================================
% 모든 Array Index Expression 생성
%% ============================================================

function expressions = ...
    build_indexed_expressions( ...
        baseName, ...
        dims, ...
        forceIndex)


if nargin < 3

    forceIndex = false;
end


dims = ...
    double(dims(:).');


if isempty(dims)

    dims = [1 1];
end


width = ...
    prod(dims);


%% Scalar이면서 index 강제하지 않음

if width == 1 && ...
        ~forceIndex

    expressions = { ...
        baseName};

    return;
end


expressions = ...
    cell( ...
        width, ...
        1);


numDims = ...
    numel(dims);


for linearIndex = 1:width

    subs = ...
        cell( ...
            1, ...
            numDims);


    [subs{:}] = ...
        ind2sub( ...
            dims, ...
            linearIndex);


    subText = ...
        cell( ...
            1, ...
            numDims);


    for d = 1:numDims

        subText{d} = ...
            num2str( ...
                subs{d});
    end


    expressions{linearIndex} = ...
        sprintf( ...
            '%s(%s)', ...
            baseName, ...
            strjoin( ...
                subText, ...
                ','));
end

end