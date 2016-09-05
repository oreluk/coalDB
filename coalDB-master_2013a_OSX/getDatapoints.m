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
        localH5 = urlwrite(link, [ids{i}{2}, '.hdf']);
        try
            data = hdf5read(localH5, ids{i}{2});
            dataTable{i}(4,:) = [];
            dataTable{i} = [dataTable{i}; num2cell(data')];
        catch  % dataPoint is [value,uncertainty]
            d = {};
            u = {};
            %             expDoc = ReactionLab.Util.gate2primeData('getDOM',{'primeID',ids{i}{1}});
            link = ['http://warehouse.primekinetics.org/depository/experiments/catalog/' ...
                ids{i}{1}, '.xml'];
            localXML = urlwrite(link, [ids{i}{1}, '.xml']);
            expDoc = xmlread(localXML);
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
        try
            delete(localXML)
        end
    elseif all(strcmpi(dataTable{i}(4,:), 'dataInXML'))
        % Download XML
        %expDoc = ReactionLab.Util.gate2primeData('getDOM',{'primeID',ids{i}{1}});
        link = ['http://warehouse.primekinetics.org/depository/experiments/catalog/' ...
            ids{i}{1}, '.xml'];
        localXML = urlwrite(link, [ids{i}{1}, '.xml']);
        expDoc = xmlread(localXML);
        
        dgGroups = expDoc.getElementsByTagName('dataGroup');
        for dgC = 1:dgGroups.getLength
            if strcmpi(char(dgGroups.item(dgC-1).getAttribute('id')), ids{i}{2})
                for numXs = 1:size(dataTable{i},2)
                    tagElements = dgGroups.item(dgC-1).getElementsByTagName(dataTable{i}{3,numXs});
                    for j = 1:tagElements.getLength
                        if strfind(char(tagElements.item(j-1).getTextContent), ',') ~= 0
                            temp = strsplit(char(tagElements.item(j-1).getTextContent), ',');
                            dataTable{i}{j+3,numXs} = str2double(temp{1});
                            [absUncVal, uncKind] = getUncertainty(expDoc, ids{i}{2}, dataTable{i}{3,numXs}, str2double(temp{1}), str2double(temp{2}));
                            uncertainty{i}{j+3,numXs} = absUncVal;
                        else
                            dataTable{i}{j+3,numXs} = str2double(char(tagElements.item(j-1).getTextContent));
                            [absUncVal, uncKind] = getUncertainty(expDoc, ids{i}{2}, dataTable{i}{3,numXs}, str2double(char(tagElements.item(j-1).getTextContent)));
                            uncertainty{i}{j+3,numXs} = absUncVal;
                        end
                    end
                end
            end
            
        end
        delete(localXML)
    end
    p = round(i/size(dataTable,2));
    waitbar(p,h,sprintf('Downloading Data From PrIMe Warehouse %.1f%% ', p*100))
end
close(h)

end

function [absUncertainty, kind] = getUncertainty(expDoc, dgID, propID, dataPoint, uncVal)
% Find kind of uncertainty (absolute/relative) for a given experimental
%  document (expDoc), datagroup id(dgID), property id(propID).  Using data
%  from (dataPoint) and uncertainty from (uncVal), this function will
%  return the absolute uncertainty bound (absUncertainty).

dgNodes = expDoc.getElementsByTagName('dataGroup');
for dgC = 1:dgNodes.getLength
    if strcmpi(char(dgNodes.item(dgC-1).getAttributeNode('id').getNodeValue), dgID)
        propNodes = dgNodes.item(dgC-1).getElementsByTagName('property');
        for pNC = 1:propNodes.getLength
            if strcmpi(char(propNodes.item(pNC-1).getAttributeNode('id').getTextContent), propID)
                uqNode = propNodes.item(pNC-1).getElementsByTagName('uncertainty');
                if uqNode.getLength > 0
                    kind = char(uqNode.item(0).getAttributeNode('kind').getNodeValue);
                    if nargin < 5 % uncVal is not known yet
                        uncVal = char(uqNode.item(0).getTextContent);
                    end
                else
                    kind = 0; % no uncertainty node present
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

