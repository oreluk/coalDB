function expData = parseExp(hh, dd, expData, dataTable, ids)
% Parses out the initial conditions (xs), datapoints (data) and its 
%  reported uncertainty (uncertainty) from a particular experiment (ids).
%  This information is stored inside the structure named expData. 
%
% Jim Oreluk 2016.05.30
%

%% Download Experiment Document
expDoc = ReactionLab.Util.gate2primeData('getDOM',{'primeID',expData.id.expID});

%% Get Data Points from Selected Experiment
[dataTable, uncertainty] = getDatapoints(hh, dd, dataTable, ids);
expData.data = dataTable{1};
expData.uncertainty = uncertainty{1};  % uncertainty is reported as absolute error. 0 indicates no uncertainty is stored

%% Download inital conditions
commonProp = expDoc.GetElementsByTagName('commonProperties').Item(0).GetElementsByTagName('property');
for i = 1:commonProp.Count
    commonName = char(commonProp.Item(i-1).GetAttributeNode('name').Value);
    switch lower(commonName)
        
        case 'initial composition'
            compNode = commonProp.Item(i-1).GetElementsByTagName('component');
            for j = 1:compNode.Count
                speID = char(compNode.Item(j-1).GetElementsByTagName('speciesLink').Item(0).GetAttributeNode('primeID').Value);
                switch lower(speID)
                    case 's00010295' % O2
                        amountNode = compNode.Item(j-1).GetElementsByTagName('amount');
                        expData.xs.O2 = str2double(char(amountNode.Item(0).InnerText));
                    case 's00009881' % H2O
                        amountNode = compNode.Item(j-1).GetElementsByTagName('amount');
                        expData.xs.H2O = str2double(char(amountNode.Item(0).InnerText));
                    case 's00010231' % N2
                        amountNode = compNode.Item(j-1).GetElementsByTagName('amount');
                        expData.xs.N2 = str2double(char(amountNode.Item(0).InnerText));
                    case 's00009360' % CO2
                        amountNode = compNode.Item(j-1).GetElementsByTagName('amount');
                        expData.xs.CO2 = str2double(char(amountNode.Item(0).InnerText));
                    case 's00009358' % CO
                        amountNode = compNode.Item(j-1).GetElementsByTagName('amount');
                        expData.xs.CO = str2double(char(amountNode.Item(0).InnerText));
                end
            end
            
        case 'temperature'  % Temperature in Kelvin
            if any(strcmpi(char(commonProp.Item(i-1).GetAttributeNode('label').Value), {'T_furnace' 'T_gas'}))
                tValue = str2double(char(commonProp.Item(i-1).GetElementsByTagName('value').Item(0).InnerText));
                tUnits = char(commonProp.Item(i-1).GetAttributeNode('units').Value);
                expData.xs.T = ReactionLab.Units.units2units(tValue, tUnits, 'K');
            end
        case 'pressure' % Pressure in atm
            pValue = str2double(char(commonProp.Item(i-1).GetElementsByTagName('value').Item(0).InnerText));
            pUnits = char(commonProp.Item(i-1).GetAttributeNode('units').Value);
            expData.xs.P = ReactionLab.Units.units2units(pValue, pUnits, 'atm');
    end
end


