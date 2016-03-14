function updateDatabase(hh, dd, curDir)
%% Download List of Experimental Records Dealing with Coal

h = waitbar(0);
waitbar(0,h,sprintf('Searching PrIMe Warehouse for Coal Data'))
s = ReactionLab.Util.PrIMeData.ExperimentDepot.PrIMeExperiments;
[coalList, ~] = s.warehouseSearch({'additionalDataItem', 'coal'});
close(h)

%% Create PrimeExperiment Object for Each Record
h = waitbar(0);
n = length(coalList);
coalData = ReactionLab.Util.PrIMeData.ExperimentDepot.PrIMeExperiments.empty(0,n);
h = waitbar(0);
for i = 1:n
    if i == 1
        tic
    end
    coalData(i) = ReactionLab.Util.PrIMeData.ExperimentDepot.PrIMeExperiments(coalList{i});
    if i == 10
        a = toc;
    end
    if i < 10
       waitbar(0,h,sprintf('Downloading experiments from PrIMe Warehouse \n 0%% complete'))
        
    else
        p = round(i/n,3);
        waitbar(p,h,sprintf('Downloading experiments from PrIMe Warehouse \n %.1f%% complete (%.1f sec)',p*100, (n-i)*a/10))
        
    end
end
close(h)

%% Preallocate Space

n = length(coalData);
dGCount = 0;
for i = 1:n
    dG = coalData(i).Doc.GetElementsByTagName('dataGroup');
    dGCount = dGCount + dG.Count;
end

bibPrimeID  = cell(1,dGCount);
bibPrefKey  = cell(1,dGCount);
fuelPrimeID = cell(1,dGCount);
fuelPrefKey = cell(1,dGCount);
initialO2   = cell(1,dGCount);
initialH2O = cell(1,dGCount);
commonTemp  = cell(1,dGCount);
dataPoints  = cell(1,dGCount);
gasMixture  = cell(1,dGCount);
expPrimeID = cell(1,dGCount);
dataGroupID = cell(1,dGCount);
fuelRank = cell(1,dGCount);

%% Process Data
dGCount = 0;
h = waitbar(0);
for i = 1:n
    if i == 1
        tic
    end
    xmlDocument = coalData(i).Doc;
    dG = xmlDocument.GetElementsByTagName('dataGroup');
    for dList = 1:dG.Count
        dGCount = dGCount + 1;
        dataGroupID{dGCount} = char(dG.Item(dList-1).GetAttribute('id'));
        if dList == 1
            % Bibliography and Fuel Information
            addNode = xmlDocument.GetElementsByTagName('additionalDataItem');
            if addNode.Count == 2
                if strfind(char(addNode.Item(1).InnerText), 'IFRF') >= 1
                    % For IFRF Data:
                    % First Bibliography -> initial conditions/experiment
                    % Second Bibliography -> experiment procedure
                    % Third Bibliography -> Facility (not added if duplicate of above
                    % references)
                    bibPrimeID{dGCount} = coalData(i).Biblio{1};
                    bibPrefKey{dGCount} = coalData(i).Biblio{1,2};
                else
                    bibPrimeID{dGCount} = coalData(i).Biblio{1};
                    bibPrefKey{dGCount} = coalData(i).Biblio{2};
                end
            else
                bibPrimeID{dGCount} = coalData(i).Biblio{1};
                bibPrefKey{dGCount} = coalData(i).Biblio{2};
            end
            
            fuelPrefKey{dGCount} = coalData(i).Fuel;
            expPrimeID{dGCount} = coalData(i).PrimeId;
                
            % Get O2 Volume Fraction from XML
            done = 0;
            sLinks = xmlDocument.GetElementsByTagName('speciesLink');          
            for sList = 1:sLinks.Count
                if sLinks.Item(sList-1).Attributes.Item(0).Value == 'O2'
                    if isempty(sLinks.Item(sList-1).NextSibling) % if there is no amount node
                        initialO2{dGCount} = '-';
                        done = done + 1;
                    else
                        o2String = char(sLinks.Item(sList-1).NextSibling.InnerText);
                        o2String = str2double(o2String) * 100;
                        initialO2{dGCount} = num2str(round( o2String, 3 ));
                        done = done + 1;
                    end
                end
                if sLinks.Item(sList-1).Attributes.Item(0).Value == fuelPrefKey{dGCount}
                    fuelPrimeID{dGCount} = char(sLinks.Item(sList-1).Attributes.Item(1).Value);
                    done = done + 1;
                end
                if sLinks.Item(sList-1).Attributes.Item(0).Value == 'H2O'
                    if isempty(sLinks.Item(sList-1).NextSibling) % if there is no amount node
                        initialH2O{dGCount} = '-';
                        done = done + 1;
                    else
                        h2oString = char(sLinks.Item(sList-1).NextSibling.InnerText);
                        h2oString = str2double(h2oString) * 100;
                        initialH2O{dGCount} = num2str(round( h2oString, 3));
                        done = done + 1;
                    end
                end
                if done == 3
                    break
                end
            end
            
            % Get Coal Rank Information
            t = {};
            speDoc = ReactionLab.Util.PrIMeData.SpeciesDepot.PrIMeSpecies(fuelPrimeID{dGCount});
            nameElem = speDoc.Doc.GetElementsByTagName('name');
            for nE = 1:nameElem.Count
                if strcmpi(char(nameElem.Item(nE-1).GetAttribute('type')), 'FuelType')
                    t{end+1} = {char(nameElem.Item(nE-1).InnerText)};
                end
            end
            fuelRank{dGCount} = t;
            
            % Get Common Temperature
            c = 0;
            commonProp = xmlDocument.GetElementsByTagName('commonProperties');
            for cList = 1:commonProp.Count
                prop = commonProp.Item(cList-1).GetElementsByTagName('property');
                for pList = 1:prop.Count
                    for aList = 1:prop.Item(pList-1).Attributes.Count
                        if prop.Item(pList-1).Attributes.Item(aList-1).Value == 'temperature'
                            if any(strcmpi(char(prop.Item(pList-1).GetAttribute('label')), {'T_furnace' 'T_gas'}))
                                T = str2double(char(prop.Item(pList-1).ChildNodes.Item(0).InnerXml));
                                commonTemp{dGCount} = num2str(round( T, 1 ));
                                c = 1;
                            end
                        end
                        if c == 1
                            break
                        end
                    end
                    if c == 1
                        break
                    end
                end
            end
            if isempty(commonTemp{dGCount}) == 1
                commonTemp{dGCount} = '-';
            end
            
            % Gas mixtures
            gasNodes = ReactionLab.Util.getnode(xmlDocument,'property','name','initial composition');
            compNodes = gasNodes.GetElementsByTagName('component');
            for i1 = 1:double(compNodes.Count)
                item = compNodes.Item(i1-1);
                pKey = char(item.GetElementsByTagName('speciesLink').Item(0).GetAttribute('preferredKey'));
                if any(strcmpi(pKey,{'Ar' 'N2' 'O2' 'He' 'CO2' 'CO' 'H2O'})) && str2double(char(item.InnerText)) ~= 0
                    if size(pKey,2) == 2
                        pKey = [pKey, ' '];
                    end
                    gasMixture{dGCount} = [ gasMixture{dGCount}; pKey];
                end
            end
        else
            % Copy if Repeat
            bibPrimeID{dGCount} = bibPrimeID{dGCount-1};
            bibPrefKey{dGCount} = bibPrefKey{dGCount-1};
            fuelPrimeID{dGCount} = fuelPrimeID{dGCount-1};
            fuelPrefKey{dGCount} = fuelPrefKey{dGCount-1};
            initialO2{dGCount} = initialO2{dGCount-1};
            initialH2O{dGCount} = initialH2O{dGCount-1};
            commonTemp{dGCount} = commonTemp{dGCount-1};
            gasMixture{dGCount} = gasMixture{dGCount-1};
            expPrimeID{dGCount} = expPrimeID{dGCount-1};
            fuelRank{dGCount} = fuelRank{dGCount-1};
        end
        
        
        % Pull Data Node Information 
        prop = dG.Item(dList-1).GetElementsByTagName('property');
        for pList = 1:prop.Count
            propDescription = char(prop.Item(pList-1).GetAttribute('description'));
            propUnits = char(prop.Item(pList-1).GetAttribute('units'));
            propId = char(prop.Item(pList-1).GetAttribute('id'));
            dataPoints{dGCount}{1,pList} = propDescription;
            dataPoints{dGCount}{2,pList} = propUnits;
            dataPoints{dGCount}{3,pList} = propId;
        end
        
        % Marker for HDF or XML Storage
        if strcmpi(char(dG.Item(dList-1).GetAttribute('dataPointForm')), 'HDF5')
            for j = 1:size(dataPoints{dGCount},2)
                dataPoints{dGCount}{4,j} = 'dataInHDF';
            end
        else
            for j = 1:size(dataPoints{dGCount},2)
                dataPoints{dGCount}{4,j} = 'dataInXML';
            end
        end
        if i == 10
            a = toc;
        end
    end
    if i < 10
        waitbar(0,h,sprintf('Processing Data \n 0%% complete'))
    else 
        p = round(i/n,3);
        waitbar(p,h,sprintf('Processing Data \n %.1f%% complete (%.1f sec)',p*100, (n-i)*a/10))
    end
end
close(h)

%% Table Data

formattedGasMix = cell(1,dGCount);
propertyName = cell(1,dGCount);
% Create Strings for gas Mixture display & properties
for i = 1:length(gasMixture)
    for i1 = 1:size(gasMixture{i},1)
        if i1 < size(gasMixture{i},1)
            formattedGasMix{i} = [formattedGasMix{i}, gasMixture{i}(i1,:), ' / '];
        else
            formattedGasMix{i} = [formattedGasMix{i}, gasMixture{i}(i1,:)];
        end
    end
    propertyName{i} = strjoin(dataPoints{i}(1,1:end),', ');
end

formattedFuelRank = cell(1,dGCount);
% create strings for Fuel Rank to display 
for i = 1:length(fuelRank)
    for i1 = 1:size(fuelRank{i},2)
        if i1 < size(fuelRank{i},2)
            formattedFuelRank{i} = [formattedFuelRank{i}, fuelRank{i}{i1}{1}, ' / '];
        else
            formattedFuelRank{i} = [formattedFuelRank{i}, fuelRank{i}{i1}{1}];
        end
    end
end

emptyH2O = cellfun('isempty', initialH2O);
initialH2O(emptyH2O) = {'-'};

checkBoxData = zeros(1,length(fuelPrefKey)); checkBoxData = num2cell(logical(checkBoxData));
tableData =     [checkBoxData', fuelPrefKey', formattedFuelRank', initialO2', initialH2O', formattedGasMix', commonTemp', propertyName', bibPrefKey'];
onClickData =   [checkBoxData', fuelPrimeID', tableData(:,3), tableData(:,4), tableData(:,5), tableData(:,6), tableData(:,7), expPrimeID', bibPrimeID' dataGroupID' ];

coalApp.tableData = tableData;
coalApp.onClickData = onClickData;
coalApp.dataPoints = dataPoints;
coalApp.gasMixture = gasMixture;
coalApp.fuelRank = fuelRank;

%%

save(fullfile(curDir, 'coalData.mat'), 'coalApp')

%% Restart Application
close(gcf)
coalDB;