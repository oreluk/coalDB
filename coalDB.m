function coalDB
% PrIMe Coal Application
%
% Jim Oreluk 2015.08.21
%
%  Purpose: Allow users to view table of coal results, plot weight-loss,
%  filter coal data by coal Name

%% Load Data
f = load(fullfile(pwd, 'coalData.mat'));
data.original.table = f.coalApp.tableData;
data.original.click = f.coalApp.onClickData;
data.original.dp = f.coalApp.dataPoints;
data.original.gas = f.coalApp.gasMixture;

onClickData = data.original.click;
dataPoints = data.original.dp;
gasMixture = data.original.gas;

%% Create GUI

fig = figure('Name','PrIMe Coal Database', ...
    'Position',         [150 200 1080 550], ...
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
    'ColumnName',       {'Select', 'Coal Name',  'Coal Rank', '% O2', '% H2O', 'Gas Mixture', 'Temp [K]', 'Properties', 'Ref'}, ...
    'ColumnFormat',     {'logical', 'char', 'char', 'char', 'char', 'char', 'char'}, ...
    'ColumnEditable',   [true, false, false, false, false, false, false, false], ...
    'RowName',          [] , ...
    'CellSelectionCallback', @onClick, ...
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
    'Callback', 'close(fig)');

% Buttons Below Table
plotB = uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.02,0.6,0.17,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Plot Data', ...
    'CallBack',         {@plotButton, tableDisplay, onClickData, dataPoints});

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
    'String',           {'Coal Name', 'Coal Rank', '%O2 (Greater Than Value)', '%H2O (Greater Than Value)', 'Gas Mixture', 'Temperature (Greater Than Value)'});

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
        
        data.table = tableDisplay.Data;
        data.click = onClickData;
        data.dp = dataPoints;
        data.gas = gasMixture;
        
        % Menu Options
        if searchGroup == 88
            filtered = filterSub( data, 'str2double(data.table(i,4)) == 0', [] );
        elseif searchGroup == 55
            filtered = filterSub(data, 'str2double(data.table(i,4)) > 0', [] );
        end
        
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
                    for i1 = 1:size(gasMixture{i},1)
                        if strcmpi( strtrim(gasMixture{i}(i1,:)), searchTerm ) == 1
                            count = count + 1;
                            for j = 1:size(data.table,2)
                                filtered.table{count,j} = data.table{i,j};
                                filtered.click{count,j} = data.click{i,j};
                                filtered.dp{count} = data.dp{1,i};
                                filtered.gas{count} = data.gas{1,i};
                            end
                        end
                    end
                end
                
            case 'Temperature (Greater Than Value)'
                searchTerm = str2double(strsplit(searchTerm,':'));
                if size(searchTerm,2) == 1
                    filtered = filterSub( data, ...
                        'str2double(data.table(i,6)) >= searchTerm', ...
                        searchTerm);
                else
                    filtered = filterSub( data, ...
                        'str2double(data.table(i,6)) >= searchTerm(1) && str2double(data.table(i,5)) <= searchTerm(2)', ...
                        searchTerm);
                end
        end
        dataPoints = filtered.dp;
        onClickData = filtered.click;
        tableDisplay.Data = filtered.table;
        gasMixture = filtered.gas;
        resultsFoundText.String = sprintf('Data Groups Found: %s', num2str(size(tableDisplay.Data,1)));
    end

    function onClick(h, d)
        NET.addAssembly('System.Xml');
        if size(d.Indices,1) == 1
            if all(d.Indices(2) ~= [1, 3, 4, 5, 6, 7])
                % Clicking Coal Name
                if d.Indices(2) == 2
                    ReactionLab.Util.gate2primeData('show',{'primeId',onClickData{d.Indices(1),d.Indices(2)}});
                    % Get DOM XML of Chemical Analysis File
                    speciesPrimeID = onClickData{d.Indices(1),d.Indices(2)};
                    s = strcat('species/data/',speciesPrimeID,'/ca00000001.xml');
                    url = strcat('http://warehouse.primekinetics.org/depository/', s);
                    rawXML = urlread(url);
                    
                    cleanStr = strrep(rawXML,' xmlns=""','');
                    cleanExpDoc = System.Xml.XmlDocument;
                    cleanExpDoc.LoadXml(cleanStr);
                    % View DOM
                    xv = PrimeKinetics.PrimeHandle.XmlViewer(cleanExpDoc);
                    xv.Show();
                else
                    ReactionLab.Util.gate2primeData('show',{'primeId',onClickData{d.Indices(1),d.Indices(2)}});
                end
            end
        end
    end

    function resetButton(h,d)
        dataPoints = data.original.dp;
        onClickData = data.original.click;
        tableDisplay.Data = data.original.table;
        gasMixture = data.original.gas;
        resultsFoundText.String = sprintf('Data Groups Found: %s', num2str(size(tableDisplay.Data,1)));
    end

    function editBox(h,d)
        currChar = get(gcf,'CurrentCharacter');
        if isequal(currChar,char(13)) %char(13) == enter key
            filterButton();
        end
    end

    function createTargetList(hh,dd, Htable)
        selectedExp = {};
        for i = 1:size(Htable.Data,1)
            if Htable.Data{i,1} == 1
                % issue when used with filters.
                selectedExp{end+1} = [onClickData(i,2), onClickData(i,6), onClickData(i,8)];
            end
        end
        selectedExp{:}
    end
end