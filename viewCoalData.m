function strOut = viewCoalData(strIn)
%  outputXMLstring = viewCoalData(inputXMLstring)
% Modified: 2015.08.24 Jim Oreluk

try
    comp = Component(strIn);
    if exist(fullfile(comp.OutputDirectory, 'coalApp.mat')) == 2
        coalDatabaseApp(comp);
    else
        updateDatabase([], [], comp); % handle and data empty
    end
    strOut = comp.OutputString;
catch ME
    comp = Component();
    comp.status = '0';
    comp.errorMessage = getReport(ME);
end

end