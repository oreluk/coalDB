function coalDB
% CCMSC Coal Application
%
% Jim Oreluk 2015.08.21
%
%  Purpose: Allow users to view table of coal results, plot weight-loss,
%  filter coal data by coal Name

%% Load Data Structure
f = load(fullfile(pwd, 'coalData.mat'));
data.original.table = f.coalApp.tableData;
data.original.click = f.coalApp.onClickData;
data.original.dp = f.coalApp.dataPoints;
data.original.gas = f.coalApp.gasMixture;
data.original.caTable = f.coalApp.caTable;

data.click = data.original.click;
data.dp = data.original.dp;
data.gas = data.original.gas;
data.caTable = data.original.caTable;
%% Create GUI

fSize = [1080 550];
screensize = get(0,'ScreenSize');
xpos = ceil((screensize(3)-fSize(1))/2); 
ypos = ceil((screensize(4)-fSize(2))/2); 

fig = figure('Name','CCMSC Coal Database', ...
    'Position',         [xpos ypos fSize(1) fSize(2)], ...
    'MenuBar',          'none', ...
    'NumberTitle',      'off', ...
    'Resize',           'on');

tablePanel = uipanel('Parent', fig, ...
    'Units',            'normalized', ...
    'Position',         [0, 0.2, 1, 1]);

buttonPanel = uipanel('Parent', fig, ...
    'Units',            'normalized', ...
    'Position',         [0, 0, 1, 0.2]);

tableDisplay = uitable('Parent', tablePanel, ...
    'Units', 'normalized',...
    'Position',         [0 0 1 0.8], ...
    'ColumnWidth',      {50 200 75 50 50 100 60 270 200}, ...
    'ColumnName',       {'Select', 'Coal Name',  'Coal Rank', '% O2', ...
                            '% H2O', 'Gas Mixture', 'Temp [K]', ...
                            'Properties', 'Ref'}, ...
    'ColumnFormat',     {'logical', 'char', 'char', 'char', 'char', 'char', 'char'}, ...
    'ColumnEditable',   [true, false, false, false, false, false, false, false], ...
    'RowName',          [] , ...
    'CellSelectionCallback', @onClickCall, ...
    'Data',             data.original.table);

% Menu Bar
menuBar = uimenu(fig,'Label','Options');
menuFilter = uimenu(menuBar, 'Label', 'Show Only...');
pyroOption = uimenu(menuFilter, 'Label', 'Pyrolysis Experiments', ...
    'Callback', {@filterButton, 'pyro'});
oxOption = uimenu(menuFilter, 'Label', 'Oxidation Experiments', ...
    'Callback', {@filterButton, 'oxidation'});

menuUpdate = uimenu(menuBar,'Label','Update Database', ...
    'Callback', {@updateDatabase, pwd});
menuClose = uimenu(menuBar,'Label','Exit Application', ...
    'Callback', 'close(gcf)');

% Buttons Below Table
plotB = uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.02,0.6,0.12,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Plot Data', ...
    'CallBack',         {@plotCall, tableDisplay});

exportB =  uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.17,0.6, 0.12,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Export Data', ...
    'CallBack',         {@exportCall, tableDisplay});

searchBox = uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.02,0.1,0.27,0.3], ...
    'Style',            'edit', ...
    'HorizontalAlignment', 'left', ...
    'FontSize',         10, ...
    'Callback',         @editBox, ...
    'String',           ' Filter ');

byText = uicontrol('Parent',buttonPanel,...
    'Units',            'normalized',...
    'Position',         [0.30,0.05,0.05,0.3], ...
    'Style',            'text', ...
    'HorizontalAlignment', 'left', ...
    'FontSize',         10, ...
    'String',           ' by');

resultsFoundText = uicontrol('Parent',buttonPanel,...
    'Units',            'normalized', ...
    'Position',         [0.85,0.6,0.2,0.4], ...
    'Style',            'text', ...
    'HorizontalAlignment', 'left', ...
    'FontSize',         10, ...
    'String',           sprintf('Data Groups Found: %s', num2str(size(tableDisplay.Data,1))));

filterByMenu = uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.335,0.08,0.20,0.3], ...
    'Style',            'popup', ...
    'HorizontalAlignment', 'left', ...
    'FontSize',         10, ...
    'String',           {'Coal Name', 'Coal Rank', ...
    'Coal - % Carbon Dry Ash Free (Greater Than Value)', ...
    '%O2 (Greater Than Value)', '%H2O (Greater Than Value)', 'Gas Mixture', ...
    'Temperature (Greater Than Value)'});

filterB = uicontrol('Parent',buttonPanel,...
    'Units',            'normalized', ...
    'Position',         [0.60,0.1,0.12,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Filter Table', ...
    'CallBack',          @filterButton);

resetB =  uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.73,0.1,0.12,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Reset Table', ...
    'CallBack',         @resetButton);

%% Call Back Functions

    function plotCall(h,d, Htable)
        plotButton(h, d, Htable, data)
    end

    function exportCall(h,d, Htable)
        s = exportButton(h, d, Htable, data);
    end

    function onClickCall(h, d)
        onClick(h,d,data)
    end

    function filterButton(h,d, varargin)
        if ~isempty(varargin)
            if strcmp(varargin{1},'pyro') == 1
                resetButton;
                searchGroup = 88;
            elseif strcmp(varargin{1}, 'oxidation') == 1
                resetButton;
                searchGroup = 55;
            end
        else
            searchTerm = searchBox.String;
            searchGroup = filterByMenu.Value;
        end
        
        % Reset if no Data Groups are shown.
        if size(tableDisplay.Data,1) == 0
            resetButton;
        end
        
        filtered.table = {};
        filtered.click = {};
        filtered.dp = {};
        filtered.gas = {};
        filtered.caTable = {};
        
        data.table = tableDisplay.Data;
        
        % Menu Options
        if searchGroup == 88
            filtered = filterSub( data, 'str2double(data.table(i,4)) == 0', [] );
        elseif searchGroup == 55
            filtered = filterSub(data, 'str2double(data.table(i,4)) > 0', [] );
        else
            %% Search Menu Cases
            switch filterByMenu.String{filterByMenu.Value}
                case 'Coal Name'
                    filtered = filterSub( data, ...
                        'strfind( lower(data.table{i,2}), strtrim(lower(searchTerm)) ) >= 1', ...
                        searchTerm);
                    
                case 'Coal Rank'
                    filtered = filterSub( data, ...
                        'strfind( lower(data.table{i,3}), strtrim(lower(searchTerm)) ) >= 1', ...
                        searchTerm);
                    
                case 'Coal - % Carbon Dry Ash Free (Greater Than Value)'
                    filtered = filterChem( data, ...
                        'data.caTable{index,2} >= value', searchTerm);

                case '%O2 (Greater Than Value)'
                    filtered = filterSub( data, ...
                        'str2double(data.table(i,4)) >= str2double(strtrim(searchTerm))', ...
                        searchTerm);
                    
                case '%H2O (Greater Than Value)'
                    filtered = filterSub( data, ...
                        'str2double(data.table(i,5)) >= str2double(strtrim(searchTerm))', ...
                        searchTerm);
                    
                case 'Gas Mixture',
                    searchTerm = strtrim(lower(searchTerm));
                    switch searchTerm
                        case 'nitrogen'
                            searchTerm = 'n2';
                        case 'helium'
                            searchTerm = 'he';
                        case 'argon'
                            searchTerm = 'ar';
                        case 'oxygen'
                            searchTerm = 'o2';
                        case 'water'
                            searchTerm = 'h2o';
                    end
                    count = 0;
                    for i = 1:size(data.table,1)
                        for i1 = 1:size(data.gas{i},1)
                            if strcmpi( strtrim(data.gas{i}(i1,:)), searchTerm ) == 1
                                count = count + 1;
                                for j = 1:size(data.table,2)
                                    filtered.table{count,j} = data.table{i,j};
                                    filtered.click{count,j} = data.click{i,j};
                                    filtered.dp{count} = data.dp{1,i};
                                    filtered.gas{count} = data.gas{1,i};
                                    if j == size(data.table,2)
                                        filtered.click{count,j+1} = data.click{i,j+1};
                                    end
                                end
                            end
                        end
                    end
                    
                case 'Temperature (Greater Than Value)'
                    searchTerm = str2double(strsplit(searchTerm,':'));
                    if size(searchTerm,2) == 1
                        filtered = filterSub( data, ...
                            'str2double(data.table(i,7)) >= searchTerm', ...
                            searchTerm);
                    else
                        filtered = filterSub( data, ...
                            'str2double(data.table(i,7)) >= searchTerm(1) && str2double(data.table(i,7)) <= searchTerm(2)', ...
                            searchTerm);
                    end
            end
        end
        
        tableDisplay.Data = filtered.table;
        data.table = filtered.table;
        data.dp = filtered.dp;
        data.click = filtered.click;
        data.gas = filtered.gas;
        resultsFoundText.String = sprintf('Data Groups Found: %s', num2str(size(tableDisplay.Data,1)));
    end

    function resetButton(h,d)
        tableDisplay.Data = data.original.table;
        data.dp = data.original.dp;
        data.click = data.original.click;
        data.gas = data.original.gas;
        resultsFoundText.String = sprintf('Data Groups Found: %s', num2str(size(tableDisplay.Data,1)));
    end

    function editBox(h,d)
        currChar = get(gcf,'CurrentCharacter');
        if isequal(currChar,char(13)) %char(13) == enter key
            filterButton();
        end
    end

end