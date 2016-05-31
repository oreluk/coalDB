function expData = exportButton(hh, dd, Htable, data)
% Collects relevant data from any database entry into a struct expData. 
%  This struct then can be used to initialize simulations at the
%  desired initial conditions and used to report the nominal QOI value 
%  and its respective bounds.

count = 0;
for i = 1:size(Htable.Data,1)
    if Htable.Data{i,1} == 1
        count = 1;
        columnNames{count} = data.dp{i}(1,:);
        dataTable{count} = data.dp{i}(:,1:size(columnNames{count},2));
        ids{count} = [data.click(i,8), data.click(i,10)];
    end
end

if count ~= 1
    errordlg('Only a single experiment can be selected for export.')
end

%% Grabs Data of Checked Column
for i = 1:size(Htable.Data,1)
    if Htable.Data{i,1} == 1
        expData.id.speID = data.click{i,2};
        expData.id.expID = data.click{i,8};
        expData.id.bibID = data.click{i,9};
        expData.id.dgID = data.click{i,10};
        break
    end
end

%% Parses experimental data - returns all datapoints and xs
expData = parseExp(hh, dd, expData, dataTable, ids);

%% select QOI from data
% plot data and select QOI from data points returned


%% keep or change bounds

%if bounds are present, report those. allow modification

%% Save to Workspace
assignin('base','expData',expData) 
fprintf('The entry has been saved to the workspace as expData.')

end