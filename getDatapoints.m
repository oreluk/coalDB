function [dataTable, uncertainty] = getDatapoints(h, d, dataTable, ids)
%  getData will gather dataPoints from PrIMe Warehouse and return a cell
%  array for the experiment and datagroup queried.
%
% Jim Oreluk 2016.05.29
%
% dataTable: {'Property Name'; 'units'; 'propertyID'; 'location'}
%  where location is 'dataInXml' || 'dataInHDF'.
%
%  ids: a n-by-1 cell array of {'experiment PrIMe ID' 'dataGroup ID'} cells.
% where n is the number of selected datagroups.
%

uncertainty = dataTable;
h = waitbar(0);
waitbar(0,h,sprintf('Downloading Data From PrIMe Warehouse'))
for i = 1:size(dataTable,2)
    % All HDF5
    if all(strcmpi(dataTable{i}(4,:), 'dataInHDF'))
        link = ['http://warehouse.primekinetics.org/depository/experiments/data/' ...
            ids{i}{1}, '/' ids{i}{2}, '.hdf'];
        localH5 = websave( [ids{i}{2}, '.hdf'], link);
        try
            data = hdf5read(localH5, ids{i}{2});
            dataTable{i}(4,:) = [];
            dataTable{i} = [dataTable{i}; num2cell(data')];
        catch  % dataPoint is [value,uncertainty]
            d = {};
            u = {};
            expDoc = ReactionLab.Util.gate2primeData('getDOM',{'primeID',ids{i}{1}});
            for j = 1:size(dataTable{i},2)
                h5s = hdf5read(localH5, strcat(ids{i}{2}, '/', dataTable{i}{3,j}));
                for j1 = 1:length(h5s)
                    temp = strsplit(h5s(j1).Data, ',');
                    d{j1,j} = str2double(temp{1});
                    if length(temp) > 1
                        % Get absolute uncertainty bound (providing uncVal)
                        [absUncVal, uncKind] = getUncertainty(expDoc, ids{i}{2}, dataTable{i}{3,j}, d{j1,j}, str2double(temp{2}));
                        u{j1,j} = absUncVal;
                    else
                        % No uncVal (no comma deliminator)
                        [absUncVal, uncKind] = getUncertainty(expDoc, ids{i}{2}, dataTable{i}{3,j}, d{j1,j});
                        u{j1,j} = absUncVal;
                    end
                end
            end
            dataTable{i}(4,:) = [];
            dataTable{i} = [dataTable{i}; d];
            uncertainty{i}(4,:) = [];
            uncertainty{i} = [uncertainty{i}; u];
        end
        delete(localH5)
    elseif all(strcmpi(dataTable{i}(4,:), 'dataInXML'))
        % Download XML
        expDoc = ReactionLab.Util.gate2primeData('getDOM',{'primeID',ids{i}{1}});
        dgGroups = expDoc.GetElementsByTagName('dataGroup');
        for dgC = 1:dgGroups.Count
            if strcmpi(char(dgGroups.Item(dgC-1).GetAttribute('id')), ids{i}{2})
                for numXs = 1:size(dataTable{i},2)
                    tagElements = dgGroups.Item(dgC-1).GetElementsByTagName(dataTable{i}{3,numXs});
                    for j = 1:tagElements.Count
                        if strfind(char(tagElements.Item(j-1).InnerText), ',') ~= 0
                            temp = strsplit(char(tagElements.Item(j-1).InnerText), ',');
                            dataTable{i}{j+3,numXs} = str2double(temp{1});
                            if length(temp) > 1
                                [absUncVal, uncKind] = getUncertainty(expDoc, ids{i}{2}, dataTable{i}{3,numXs}, str2double(temp{1}), str2double(temp{2}));
                                uncertainty{i}{j+3,numXs} = absUncVal;
                            else
                                [absUncVal, uncKind] = getUncertainty(expDoc, ids{i}{2}, dataTable{i}{3,numXs}, str2double(temp{1}));
                                uncertainty{i}{j+3,numXs} = absUncVal;
                            end
                        else
                            dataTable{i}{j+3,numXs} = str2double(char(tagElements.Item(j-1).InnerText));
                            
                            [absUncVal, uncKind] = getUncertainty(expDoc, ids{i}{2}, dataTable{i}{3,numXs}, str2double(char(tagElements.Item(j-1).InnerText)));
                            uncertainty{i}{j+3,numXs} = absUncVal;
                        end
                    end
                end
            end
            
        end
    end
    p = round(i/size(dataTable,2),3);
    waitbar(p,h,sprintf('Downloading Data From PrIMe Warehouse %.1f%% ', p*100))
end
close(h)

end

function [absUncertainty, kind] = getUncertainty(expDoc, dgID, propID, dataPoint, uncVal)
% Find kind of uncertainty (absolute/relative) for a given experimental
%  document (expDoc), datagroup id(dgID), property id(propID).  Using data
%  from (dataPoint) and uncertainty from (uncVal), this function will
%  return the absolute uncertainty bound (absUncertainty).

dgNodes = expDoc.GetElementsByTagName('dataGroup');
for dgC = 1:dgNodes.Count
    if strcmpi(char(dgNodes.Item(dgC-1).GetAttributeNode('id').Value), dgID)
        propNodes = dgNodes.Item(dgC-1).GetElementsByTagName('property');
        for pNC = 1:propNodes.Count
            if strcmpi(char(propNodes.Item(pNC-1).GetAttributeNode('id').Value), propID)
                uqNode = propNodes.Item(pNC-1).GetElementsByTagName('uncertainty');
                if uqNode.Count > 0
                    kind = char(uqNode.Item(0).GetAttributeNode('kind').Value);
                    if nargin < 5 % uncValue is not known yet
                        uncVal = char(uqNode.Item(0).InnerText);
                    end
                else
                    kind = 0; % No Uncertainty Node Present
                end
            end
        end
    end
end

switch lower(kind)
    case 'absolute'
        absUncertainty = uncVal;
    case 'relative'
        absUncertainty = (uncVal * dataPoint); % convert from relative to absolute
    case 0
        absUncertainty = 0; % no uncertainty node present
end

end

