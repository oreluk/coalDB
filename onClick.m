function onClick(h, d, onClickData)
NET.addAssembly('System.Xml');
if size(d.Indices,1) == 1
    if all(d.Indices(2) ~= [1, 3, 4, 5, 6, 7])
        % Clicking Coal Name
        if d.Indices(2) == 2
            ReactionLab.Util.gate2primeData('show',{'primeId',onClickData{d.Indices(1),d.Indices(2)}});
            % Get DOM XML of Chemical Analysis File
            speciesPrimeID = onClickData{d.Indices(1),d.Indices(2)};
            s = strcat('species/data/',speciesPrimeID,'/ca00000001.xml');
            url = strcat('http://warehouse.primekinetics.org/depository/', s);
            rawXML = urlread(url);
            
            cleanStr = strrep(rawXML,' xmlns=""','');
            cleanExpDoc = System.Xml.XmlDocument;
            cleanExpDoc.LoadXml(cleanStr);
            % View DOM
            xv = PrimeKinetics.PrimeHandle.XmlViewer(cleanExpDoc);
            xv.Show();
        else
            ReactionLab.Util.gate2primeData('show',{'primeId',onClickData{d.Indices(1),d.Indices(2)}});
        end
    end
end
