function plotButton(h, d, Htable, onClickData, dataPoints)
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
    ids = {};
    
    
    count = 0;
    for i = 1:size(Htable.Data,1)
        if Htable.Data{i,1} == 1
            count = count + 1;
            legendNames{count} = [Htable.Data{i,2}, ' @ ', Htable.Data{i,7}, 'K (', num2str(Htable.Data{i,4}),'% O2)'];
            columnNames{count} = dataPoints{i}(1,:);
            dataTable{count} = dataPoints{i}(:,1:size(columnNames{count},2));
            numProps{count} = size(dataPoints{i},2);
            ids{count} = [onClickData(i,8), onClickData(i,10)];
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
    for i3 = 1:size(legendNames, 2)
        uicontrol('Parent',     tab2, ...
            'Units',            'normalized', ...
            'Position',         [(width*(i3-1))+0.005, 0.9, width*(i3), 0.03], ...
            'Style',            'text', ...
            'HorizontalAlignment', 'left', ...
            'FontSize',         9, ...
            'String',           legendNames{i3});
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
            if all(isnan([dataTable{1}{4,:}]))
                %download url
                link = ['http://warehouse.primekinetics.org/depository/experiments/data/' ...
                    ids{ii}{1}, '/' ids{ii}{2}, '.hdf'];
                localH5 = websave( [ids{ii}{2}, '.hdf'], link);
                % check if is matrix of values...or contains set of strings
                
                hinf = hdf5info(localH5);
                if strcmpi(hinf.GroupHierarchy.Groups.Datasets(1).Datatype.Class, ...
                        'H5T_STRING')
                    % WEHAVE TO PARSE BY STRING INPUT
                    
                else
                    
                   % Parse by matrix 
                end
                
                % add values to xname, yname and values
                
            else
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
        fprintf('Saving table as: %s \n', filename);
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