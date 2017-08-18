function doc = getXML(location)
% used to get DOM object from URL

% check if ending has xml. if so...okay. else add it. 

url = strcat('http://warehouse.cki-know.org/depository/', location, '.xml');
options = weboptions('ContentType', 'xmldom');
doc = webread(url, options);