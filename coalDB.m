function coalDB
% PrIMe Coal Application
%
% Jim Oreluk 2015.08.21
%
%  Purpose: Allow users to view table of coal results, plot weight-loss,
%  filter coal data by coal name

%% Load Data
f = load(fullfile(pwd, 'coalData.mat'));
tableDataOriginal = f.coalApp.tableData;
onClickDataOriginal = f.coalApp.onClickData;
dataPointsOriginal = f.coalApp.dataPoints;
gasMixture = f.coalApp.gasMixture;
onClickData = onClickDataOriginal;
dataPoints = dataPointsOriginal;

%% Create GUI

fig = figure('Name','PrIMe Coal Database', ...
    'Position',         [150 200 990 550], ...
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
    'ColumnWidth',      {50 200 50 100 60 300 200}, ...
    'ColumnName',       {'Select', 'Coal Name',  '% O2', 'Gas Mixture', 'Temp [K]', 'Properties', 'Ref'}, ...
    'ColumnFormat',     {'logical', 'char', 'char', 'char', 'char', 'char', 'char'}, ...
    'ColumnEditable',   [true, false, false, false, false, false, false], ...
    'RowName',          [] , ...
    'CellSelectionCallback', @onClick, ...
    'Data',             tableDataOriginal);

% Menu Bar
menuBar = uimenu(fig,'Label','Options');

menuFilter = uimenu(menuBar, 'Label', 'Show Only...');
pyroOption = uimenu(menuFilter, 'Label', 'Pyrolysis Experiments', ...
    'Callback', {@filterButton, 'pyro'});
oxOption = uimenu(menuFilter, 'Label', 'Oxidation Experiments', ...
    'Callback', {@filterButton, 'oxidation'});

% ifrfOption = uimenu(menuFilter, 'Label', 'IFRF Experiments');
% sandiaOption = uimenu(menuFilter, 'Label', 'Sandia''s CCL Experiments');


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
    'CallBack',         {@plotButton, tableDisplay});

searchBox = uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.02,0.1,0.27,0.3], ...
    'Style',            'edit', ...
    'HorizontalAlignment', 'left', ...
    'FontSize',         10, ...
    'Callback',         @editBox, ...
    'String',           ' Search ');

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
    'String',           sprintf('Datasets Found: %s', num2str(size(tableDisplay.Data,1))));

filterByMenu = uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.335,0.08,0.20,0.3], ...
    'Style',            'popup', ...
    'HorizontalAlignment', 'left', ...
    'FontSize',         10, ...
    'String',           {'Coal Name', '%O2 (Greater Than Value)', 'Gas Mixture', 'Temperature (Greater Than Value)'});

filterB = uicontrol('Parent',buttonPanel,...
    'Units',            'normalized', ...
    'Position',         [0.60,0.1,0.12,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Search Table', ...
    'CallBack',          @filterButton);

resetB =  uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.73,0.1,0.12,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Reset Table', ...
    'CallBack',         @resetButton);

b2bdcB =  uicontrol('Parent',buttonPanel, ...
    'Units',            'normalized', ...
    'Position',         [0.86,0.1,0.12,0.3], ...
    'Style',            'pushbutton', ...
    'FontSize',         10, ...
    'String',           'Create Targets', ...
    'CallBack',         {@createTargetList, tableDisplay});


%% Call Back Functions

    function onClick(h, d)
        NET.addAssembly('System.Xml');
        if size(d.Indices,1) == 1
            if d.Indices(2) ~= 1 && d.Indices(2) ~= 3 && d.Indices(2) ~= 4 && d.Indices(2) ~= 5
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
        
        % Reset if no datasets are shown.
        if size(tableDisplay.Data,1) == 0
            resetButton;
        end
        
        filterTable = {};
        filterOnClick = {};
        filterDataPoints = {};
        
        tData = tableDisplay.Data;
        oData = onClickData;
        dPoint = dataPoints;
        
        % Match Coal Name
        if searchGroup == 1
            [filterTable, filterOnClick, filterDataPoints] = filterSub( ...
                tData, oData, dPoint, ...
                'strfind( lower(tData{i,2}), strtrim(lower(searchTerm)) ) >= 1', ...
                searchTerm);
            
            % Match %O2
        elseif searchGroup == 2
            [filterTable, filterOnClick, filterDataPoints] = filterSub( ...
                tData, oData, dPoint, ...
                'str2double(tData(i,3)) >= str2double(strtrim(searchTerm))', ...
                searchTerm);
            
            % Match Gas Mixture
        elseif searchGroup == 3
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
            for i = 1:size(tData,1)
                for i1 = 1:size(gasMixture{i},1)
                    if strcmpi( strtrim(gasMixture{i}(i1,:)), searchTerm ) == 1
                        count = count + 1;
                        for j = 1:size(tData,2)
                            filterTable{count,j} = tData{i,j};
                            filterOnClick{count,j} = oData{i,j};
                            filterDataPoints{count} = dPoint{1,i};
                        end
                    end
                end
            end
            
            % Match Temperature (looks for temperature greater than string
        elseif searchGroup == 4
            count = 0;
            temperatureRange = str2double(strsplit(searchTerm,':'));
            if size(temperatureRange,2) == 1
                for i = 1:size(tData,1)
                    if str2double(tData(i,5)) >= temperatureRange
                        count = count + 1;
                        for j = 1:size(tData,2)
                            filterTable{count,j} = tData{i,j};
                            filterOnClick{count,j} = oData{i,j};
                            filterDataPoints{count} = dPoint{1,i};
                        end
                    end
                end
            else
                for i = 1:size(tData,1)
                    if str2double(tData(i,5)) >= temperatureRange(1) && str2double(tData(i,5)) <= temperatureRange(2)
                        count = count + 1;
                        for j = 1:size(tData,2)
                            filterTable{count,j} = tData{i,j};
                            filterOnClick{count,j} = oData{i,j};
                            filterDataPoints{count} = dPoint{1,i};
                        end
                    end
                end
            end
            
        elseif searchGroup == 88
            [filterTable, filterOnClick, filterDataPoints] = filterSub( ...
                tData, oData, dPoint, 'str2double(tData(i,3)) == 0', [] );
        elseif searchGroup == 55
            [filterTable, filterOnClick, filterDataPoints] = filterSub( ...
                tData, oData, dPoint, 'str2double(tData(i,3)) > 0', [] );
        end
        
        % Update shown table
        dataPoints = filterDataPoints;
        onClickData = filterOnClick;
        tableDisplay.Data = filterTable;
        resultsFoundText.String = sprintf('Datasets Found: %s', num2str(size(tableDisplay.Data,1)));
    end

    function resetButton(h,d)
        dataPoints = dataPointsOriginal;
        onClickData = onClickDataOriginal;
        tableDisplay.Data = tableDataOriginal;
        resultsFoundText.String = sprintf('Datasets Found: %s', num2str(size(tableDisplay.Data,1)));
    end

    function editBox(h,d)
        currChar = get(gcf,'CurrentCharacter');
        if isequal(currChar,char(13)) %char(13) == enter key
            filterButton();
        end
    end

    function plotButton(h, d, Htable)
        count = 0;
        for i = 1:size(Htable.Data,1)
            if Htable.Data{i,1} == 1
                count = 1;
            end
        end
        
        if count == 0
            errordlg('Requires at least one experiment selected to plot Show Data')
        else
            % Figure and Tabs
            plotFig = figure('Name','PrIMe Coal Database - Plot Data', ...
                'Position',     [150 200 750 500], ...
                'MenuBar',      'none', ...
                'NumberTitle',  'off', ...
                'Resize',       'on');
            tabgp = uitabgroup(plotFig,'Position',[0 0 1 1]);
            tab1 = uitab(tabgp,'Title','   Plot   ');
            tab2 = uitab(tabgp,'Title',' Data Table ');
            
            plotArea = uipanel('Parent', tab1, ...
                'Units',        'normalized',...
                'BorderType',   'none', ...
                'Position',     [0, 0.1, 1, 0.90]);
            
            % Plot Tab
            legendNames = {};
            dataTable = {};
            columnNames = {};
            numProps = {};
            count = 0;
            for i = 1:size(Htable.Data,1)
                if Htable.Data{i,1} == 1
                    count = count + 1;
                    legendNames{count} = [Htable.Data{i,2}, ' @ ', Htable.Data{i,5}, 'K (', num2str(Htable.Data{i,3}),'% O2)'];
                    columnNames{count} = dataPoints{i}(1,:);
                    dataTable{count} = dataPoints{i}(:,1:size(columnNames{count},2));
                    numProps{count} = size(dataPoints{i},2);
                end
            end
            
            menuName = unique([columnNames{:}]);
            ax = axes('Parent', plotArea);
            
            xMenuText = uicontrol('Parent',tab1,...
                'Units',        'normalized',...
                'Position',     [0.04, 0.005, 0.1, 0.05],...
                'Style',        'text',...
                'HorizontalAlignment', 'left', ...
                'FontSize',     11,...
                'String',       ' X Axis:');
            
            xMenu = uicontrol('Parent', tab1, ...
                'Units',        'normalized',...
                'Position',     [0.13, 0.01, 0.3, 0.05],...
                'Style',        'popup',...
                'HorizontalAlignment', 'left', ...
                'FontSize',     10,...
                'String',       menuName, ...
                'Value',        2, ...
                'CallBack',     @setPlot);
            
            yMenuText = uicontrol('Parent',tab1,...
                'Units',        'normalized',...
                'Position',     [0.58, 0.005, 0.1, 0.05],...
                'Style',        'text',...
                'HorizontalAlignment', 'left', ...
                'FontSize',     11,...
                'String',       'Y Axis:');
            
            yMenu = uicontrol('Parent',tab1, ...
                'Units',        'normalized', ...
                'Position',     [0.66, 0.01, 0.3, 0.05], ...
                'Style',        'popup', ...
                'HorizontalAlignment', 'left', ...
                'FontSize',     10, ...
                'String',       menuName, ...
                'Value',        1, ...
                'CallBack',     @setPlot);
            
            showLine = uicontrol('Parent', tab1, ...
                'Units',        'normalized', ...
                'Position',     [0.82, 0.08, 0.2, 0.05], ...
                'Style',        'checkbox', ...
                'HorizontalAlignment', 'left', ...
                'FontSize',     10, ...
                'String',       menuName, ...
                'Value',        1, ...
                'String',       'Display Line', ...
                'CallBack',         @setPlot);
            
            [xUnits, yUnits] = setPlot;
            grid(ax, 'on')
            xlabel(ax, strcat(xMenu.String{xMenu.Value}, ' [', xUnits, ']'))
            ylabel(ax, strcat(yMenu.String{yMenu.Value}, ' [', yUnits, ']'))
            
            dcm = datacursormode(plotFig);
            datacursormode on
            dcm.updatefcn =  @dataPointInfo;
            
            % Data Tab
            nTable = [];
            for j = 1:length(dataTable)
                s = dataTable{j};  s(1:3,:) = [];
                temp{j} = cell2mat(s);
                sx = size(nTable);
                sy = size(temp{j});
                aa = max(sx(1), sy(1));
                z = [[nTable; NaN(abs([aa 0]-sx))],[temp{j}; NaN(abs([aa 0]-sy))]];
                nTable = z;
            end
            
            dataTableDisplay = uitable('Parent', tab2, ...
                'Units',        'normalized', ...
                'Position',     [0 0 1 0.9], ...
                'ColumnName',   [columnNames{:}], ...
                'RowName',      [] , ...
                'Data',         nTable);
            % position legend name above columns
            width = dataTableDisplay.Extent(3)/size(legendNames, 2);
            for ii = 1:size(legendNames, 2)
                uicontrol('Parent',     tab2, ...
                    'Units',            'normalized', ...
                    'Position',         [(width*(ii-1))+0.005, 0.9, width*(ii), 0.03], ...
                    'Style',            'text', ...
                    'HorizontalAlignment', 'left', ...
                    'FontSize',         9, ...
                    'String',           legendNames{ii});
            end
            
            exportButton = uicontrol('Parent', tab2,...
                'Units',            'normalized', ...
                'Position',         [0.85, 0.95, 0.15, 0.05], ...
                'Style',            'pushbutton', ...
                'FontSize',         10, ...
                'String',           'Save to Excel', ...
                'CallBack',         @exportExcel);
        end
        
        %%
        function dataLabel = dataPointInfo(obj, event_obj)
            pos = event_obj.Position;
            dataLabel = {[xMenu.String{xMenu.Value}, ': ', num2str(pos(1),4)], ...
                [yMenu.String{yMenu.Value}, ': ', num2str(pos(2), 4)]};
            if length(pos) > 2
                dataLabel{end+1} = ['Z: ', num2str(pos(3), 4)];
            end
        end
        
        function [xUnits, yUnits] = setPlot(hh,dd)
            cla(ax)
            for ii = 1:size(dataTable,2)
                c = 0;
                for jj = 1:size(dataTable{ii},2)
                    if strcmpi(xMenu.String{xMenu.Value}, dataTable{ii}{1,jj})
                        xValues = dataTable{ii}(:,jj);
                        s = xValues;  s(1:3,:) = [];
                        xValues = cell2mat(s);
                        xUnits = dataTable{ii}(2,jj);
                        xName = dataTable{ii}(1,jj);
                        c = c + 1;
                    end
                    if strcmpi(yMenu.String{yMenu.Value}, dataTable{ii}{1,jj})
                        yValues = dataTable{ii}(:,jj);
                        s = yValues;  s(1:3,:) = [];
                        yValues = cell2mat(s);
                        yUnits = dataTable{ii}(2,jj);
                        yName = dataTable{ii}(1,jj);
                        c = c + 1;
                    end
                end
                
                % Sort in Ascending Order of xValues
                [xValues, ind] = sort(xValues);
                yValues = yValues(ind);
                
                % Plot Values
                if c == 2  % Both xValues && yValues matched
                    if size(xValues,2) ~= 1 && size(yValues,2) ~= 1
                        errorbarxy(ax,xValues(:,1), yValues(:,1), xValues(:,2), yValues(:,2), {'ko', 'k', 'k'});
                    elseif size(xValues,2) ~= 1
                        % ISSUE: considers the error as y-E y+E not x-E x+E
                        
                        % for the time being
                        plot(ax, xValues(:,1), yValues(:,1), 'o')
                    elseif size(yValues,2) ~= 1
                        errorbar(ax,xValues(:,1), yValues(:,1), yValues(:,2), 'ko');
                    else
                        if showLine.Value == 1
                            plot(ax, xValues(:,1), yValues(:,1), 'o-')
                        else
                            plot(ax, xValues(:,1), yValues(:,1), 'o')
                        end
                    end
                else
                    warndlg('Please select coals with similar properties to plot')
                end
                hold(ax, 'on')
            end
            % ISSUE: if unable to match Menu (property) names, legend will
            % mislabel names (currently displaying a warndlg
            legend(ax, legendNames, 'Location', 'Best')
            xlabel(ax, strcat(xMenu.String{xMenu.Value}, ' [', xUnits, ']'))
            ylabel(ax, strcat(yMenu.String{yMenu.Value}, ' [', yUnits, ']'))
            grid(ax, 'on')
        end
        
        function exportExcel(hh, dd)
            % File Name
            t = date; s1 = datestr(t,'yyyymmdd'); s2 = datestr(now, 'HHMMSS');
            filename = strcat('exportData_', s1, '_', s2, '.xlsx');
            % Position legend names above starting cell
            for iter = 1:size(numProps,2)
                prevN = 1;
                if iter == 1
                    xlswrite(filename, legendNames(iter), 'Sheet1', 'A1');
                else
                    for k = (iter-1):-1:1
                        currentN = prevN + numProps{k};
                        prevN = currentN;
                    end
                    inputPosition = strcat(xlscol(currentN), '1');
                    xlswrite(filename, legendNames(iter), 'Sheet1', inputPosition);
                end
            end
            % Write File and Data
            xlswrite(filename, [columnNames{:}], 'Sheet1', 'A2');
            xlswrite(filename, nTable, 'Sheet1', 'A3'); % array under the header.
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