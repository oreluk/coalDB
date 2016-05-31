function expData = parseExp(hh, dd, expData, dataTable, ids)
% Parses out the initial conditions and datapoints from a particular
% experiment.

%% Download Experiment Document
expDoc = ReactionLab.Util.gate2primeData('getDOM',{'primeID',expData.id.expID});

%% Get Data Points from Selected Experiment
dataTable = getDatapoints(hh, dd, dataTable, ids)
expData.data = dataTable{1};

%% Download inital conditions
commonProp = expDoc.GetElementsByTagName('commonProperties').Item(0).GetElementsByTagName('property');
for i = 1:commonProp.Count
    if strcmpi(char(commonProp.Item(i-1).GetAttributeNode('name').Value), 'initial composition')
        compNode = commonProp.Item(i-1).GetElementsByTagName('component');
        for j = 1:compNode.Count
            speID = char(compNode.Item(j-1).GetElementsByTagName('speciesLink').Item(0).GetAttributeNode('primeID').Value);
            switch speID
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
            end
        end
    end
end

