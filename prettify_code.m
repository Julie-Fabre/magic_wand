function prettyCode = prettify_code(rawCode, xmlFile)

    % Parse the XML file
    xDoc = xmlread(xmlFile);
    
    % Get indentation settings
    indentNode = xDoc.getElementsByTagName('indent').item(0);
    spaceCount = str2double(indentNode.getElementsByTagName('spaceCount').item(0).getFirstChild.getData);
    increaseIndentation_java = split(indentNode.getElementsByTagName('increaseIndentation').item(0).getFirstChild.getData, ',');
    decreaseIndentation_java = split(indentNode.getElementsByTagName('decreaseIndentation').item(0).getFirstChild.getData, ',');
    increaseIndentation = arrayfun(@(x)  increaseIndentation_java(x).toCharArray', 1:size(increaseIndentation_java,1), 'UniformOutput', false);
    decreaseIndentation = arrayfun(@(x)  decreaseIndentation_java(x).toCharArray', 1:size(decreaseIndentation_java,1), 'UniformOutput', false);
    increaseIndentation_single_java = split(indentNode.getElementsByTagName('singleIncreaseIndentation').item(0).getFirstChild.getData, ',');
    increaseIndentation_single = arrayfun(@(x)  increaseIndentation_single_java(x).toCharArray', 1:size(increaseIndentation_single_java,1), 'UniformOutput', false);
    
    % Get spacing settings
    spacingNode = xDoc.getElementsByTagName('spacing').item(0);
    aroundOperators = strcmp(spacingNode.getElementsByTagName('aroundOperators').item(0).getFirstChild.getData, 'true');
    afterCommentOperator = strcmp(spacingNode.getElementsByTagName('afterCommentOperator').item(0).getFirstChild.getData, 'true');
    afterComma = strcmp(spacingNode.getElementsByTagName('afterComma').item(0).getFirstChild.getData, 'true');
    
    % Get blank lines settings
    blankLinesNode = xDoc.getElementsByTagName('blankLines').item(0);
    afterKeywords_java = split(blankLinesNode.getElementsByTagName('afterKeywords').item(0).getFirstChild.getData, ',');
    beforeKeywords_java = split(blankLinesNode.getElementsByTagName('beforeKeywords').item(0).getFirstChild.getData, ',');
    afterKeywords = arrayfun(@(x)  afterKeywords_java(x).toCharArray', 1:size(afterKeywords_java,1), 'UniformOutput', false);
    beforeKeywords = arrayfun(@(x)  beforeKeywords_java(x).toCharArray', 1:size(beforeKeywords_java,1), 'UniformOutput', false);
    singleBlankLines = strcmp(blankLinesNode.getElementsByTagName('singleBlankLines').item(0).getFirstChild.getData, 'true');
   
    % Apply beautification
    lines = split(rawCode, newline);
    indentLevel = 0;
    i = 1;
    single_indent = false;

    while i <= numel(lines)
        
        % get line 
        line = strtrim(lines{i});

        % remove any leading or trailing white space
        line = regexprep(line, '^[ \t]+', ''); % leading white space
        line = regexprep(line, '^[ \t]+$', ''); % trailing white space 

        % add indent after keywords 
        if any(endsWith(line, decreaseIndentation)) || any(startsWith(line, decreaseIndentation))
            indentLevel = indentLevel - 1;
        end
        
        line = regexprep(line, '\s{2,}', ' '); % remove any double (or more) spaces
  
        lines{i} = [repmat(' ', 1, spaceCount * indentLevel),  line]; % store line
        
        % remove indent for next line if it's of type single line 
        if single_indent
            indentLevel = indentLevel - 1;
            single_indent = false;
        end

        % add indent if keyword
        if any(startsWith(line, increaseIndentation))
            indentLevel = indentLevel + 1;
        end
        
        % remove indent if it was a single line indent 
        if any(endsWith(line, increaseIndentation_single))
            indentLevel = indentLevel + 1;
            single_indent = true;
        end

        % Add blank lines after specific keywords
        if any(startsWith(line, afterKeywords)) && (i == numel(lines) || ~isempty(lines{i+1}))
            lines = [lines(1:i); ""; lines(i+1:end)];
            i = i + 1;
        end
        
        % Add blank lines before specific keywords
        if any(startsWith(line, beforeKeywords)) && (i == 1 || ~isempty(lines{i-1}))
            lines = [lines(1:i-1); ""; lines(i:end)];
            i = i + 1;
        end
        
        i = i + 1;
    end

    % Remove surplus blank lines
    lines = regexprep(lines, '^\s*$', '');
    lines(cellfun(@isempty, lines) & [true; cellfun(@isempty, lines(1:end-1))]) = [];
    
    prettyCode = strjoin(lines, newline);

    if aroundOperators % add a space around operators, if there isn't one already
        operatorsPattern = '(?<!\s)(=|<|>|~|&|\||-|\+|\*|/|\^)(?!\s)';
        specialCases = {'& &', '| |', '= =', '~ =', '. /', '. \', '. ^', '&  &', '|  |', '=  =', '~  =', '.  /', '.  \', '.  ^'};
        specialCases_replace = {'&&', '||', '==', '~=', './', '.\', '.^','&&', '||', '==', '~=', './', '.\', '.^'};
        prettyCode = regexprep(prettyCode, operatorsPattern, ' $1 ');
        for i = 1:length(specialCases)
            prettyCode = strrep(prettyCode, specialCases{i}, specialCases_replace{i});
        end
    end

    if afterCommentOperator % add a space after comment operators, if there isn't one already
       commentOperatorPattern = '(%)(?!\s)';
       specialCases = {'% %','%   %'};
       specialCases_replace = {'%%', '%%'};
       prettyCode = regexprep(prettyCode, commentOperatorPattern, '$1 ');
       for i = 1:length(specialCases)
           prettyCode = strrep(prettyCode, specialCases{i}, specialCases_replace{i});
       end
    end
    
    if afterComma % add a space after commas, if there isn't one already
        prettyCode = regexprep(prettyCode, '(?<!\s)(,)(?!\s)', ', ');
    end

    if singleBlankLines % remove any double (or more) blank lines
        prettyCode = regexprep(prettyCode, '^(\s*\r\n){2,}', '\r\n');
    end

end