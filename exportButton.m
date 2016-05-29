function expData = exportButton(hh, dd, Htable, data)
% Collects relevant data from any database entry into a struct expData. 
%  This struct then can be used to initialize simulations at the
%  desired initial conditions and used to report the nominal QOI value 
%  and its respective bounds.

count = 0;
for i = 1:size(Htable.Data,1)
    if Htable.Data{i,1} == 1
        count = 1;
    end
end

if count ~= 1
    errordlg('Requires only one experiment selected for export to B2BDC')
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

%% Gathers xs data  
%expData.xs.Tp = 
%expData.xs


%% Save to Workspace
assignin('base','expData',expData) 
fprintf('The entry has been saved to the workspace as expData.')

end