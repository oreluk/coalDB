function updateDatabase(hh,dd, comp)
%% Download List of Experimental Records Dealing with Coal
% IFRF data is 763 experiments

% Update 2016.01.19  - onClickData now has experimentalIDs

h = waitbar(0);
waitbar(0,h,sprintf('Searching Warehouse for Coal Data'))
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
    if i == 1
        a = toc;
    end
    p = round(i/n,3);
    waitbar(p,h,sprintf('Downloading experiments from Warehouse \n %.1f%% complete (%.1f sec)',p*100, (n-i)*a))
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
commonTemp  = cell(1,dGCount);
dataPoints  = cell(1,dGCount);
gasMixture  = cell(1,dGCount);
expPrimeID = cell(1,dGCount);

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
                end
            else
                %need to test this...
                bibPrimeID{dGCount} = coalData(i).Biblio{1};
                bibPrefKey{dGCount} = coalData(i).Biblio{2};
            end
            
            fuelPrefKey{dGCount} = coalData(i).Fuel;
            expPrimeID{dGCount} = coalData(i).PrimeId;
            
            % Get O2 Volume Fraction from XML
            %     commonProp = xmlDocument.GetElementsByTagName('commonProperties');
            %     property = commonProp.Item(0).GetElementsByTagName('property');
            
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
                if done == 2
                    break
                end
            end
            
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
            
            % gas mixtures
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
            % copy repeated calculations
            bibPrimeID{dGCount} = bibPrimeID{dGCount-1};
            bibPrefKey{dGCount} = bibPrefKey{dGCount-1};
            fuelPrimeID{dGCount} = fuelPrimeID{dGCount-1};
            fuelPrefKey{dGCount} = fuelPrefKey{dGCount-1};
            initialO2{dGCount} = initialO2{dGCount-1};
            commonTemp{dGCount} = commonTemp{dGCount-1};
            gasMixture{dGCount} = gasMixture{dGCount-1};
            expPrimeID{dGCount} = expPrimeID{dGCount-1};
        end
        
        
        % Pull data structure for datapoints
        
        prop = dG.Item(dList-1).GetElementsByTagName('property');
        for pList = 1:prop.Count
            propDescription = char(prop.Item(pList-1).GetAttribute('description'));
            propUnits = char(prop.Item(pList-1).GetAttribute('units'));
            propId = char(prop.Item(pList-1).GetAttribute('id'));
            dataPoints{dGCount}{1,pList} = propDescription;
            dataPoints{dGCount}{2,pList} = propUnits;
            dataPoints{dGCount}{3,pList} = propId;
        end
        for numXs = 1:size(dataPoints{dGCount},2)
            tagElements = xmlDocument.GetElementsByTagName(dataPoints{dGCount}{3,numXs});
            for j = 1:tagElements.Count
                if strfind(char(tagElements.Item(j-1).InnerText), ',') ~= 0
                    accValue = strsplit(char(tagElements.Item(j-1).InnerText), ',');
                    dataPoints{dGCount}{j+3,numXs} = str2double(accValue);
                else
                    dataPoints{dGCount}{j+3,numXs} = str2double(char(tagElements.Item(j-1).InnerText));
                end
            end
        end
        
        
        if i == 1
            a = toc;
        end
    end
    p = round(i/n,3);
    waitbar(p,h,sprintf('Processing Data \n %.1f%% complete (%.1f sec)',p*100, (n-i)*a))
end
close(h)

%% Table Data

formattedGasMix = cell(1,dGCount);
propertyName = cell(1,dGCount);
% create strings for gas Mixture display & properties
for i = 1:length(gasMixture)
    for i1 = 1:size(gasMixture{i},1)
        if i1 < size(gasMixture{i},1)
            formattedGasMix{i} = [formattedGasMix{i}, gasMixture{i}(i1,:), ' / '];
        else
            formattedGasMix{i} = [formattedGasMix{i}, gasMixture{i}(i1,:)];
        end
    end
    propertyName{i} = [sprintf('%s, ',dataPoints{i}{1,end-1}),dataPoints{i}{1,end}];
end

checkBoxData = zeros(1,length(fuelPrefKey)); checkBoxData = num2cell(logical(checkBoxData));
tableData =     [checkBoxData', fuelPrefKey' initialO2' formattedGasMix' commonTemp'  propertyName' bibPrefKey'];
onClickData =   [checkBoxData', fuelPrimeID', tableData(:,3), tableData(:,4), tableData(:,5), expPrimeID', bibPrimeID' ];

coalApp.tableData = tableData;
coalApp.onClickData = onClickData;
coalApp.dataPoints = dataPoints;
coalApp.gasMixture = gasMixture;

%%
keyboard
% save(fullfile(comp.OutputDirectory, 'coalApp.mat'), 'coalApp')

%% Restart Application

close(gcf)
coalDB;