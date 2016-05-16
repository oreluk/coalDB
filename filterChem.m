function filtered = filterChem(data, query, value)


count = 0;
value = str2double(value)/100;  %input is \%  These are stored as decimal values. 
for i = 1:size(data.click,1)
    if  ~isempty(strfind([data.caTable{:,1}], data.click(i,2)))
        index = find(strcmpi(data.caTable(:,1), data.click(i,2)));
        if eval(query)   % 'data.caTable{index,2} >= value'  Carbon_DAF
            count = count + 1;
            for j = 1:size(data.table,2)
                filtered.table{count,j} = data.table{i,j};
                filtered.dp{count} = data.dp{1,i};
                filtered.gas{count} = data.gas{1,i};
                filtered.click{count,j} = data.click{i,j};
                if j == size(data.table,2)
                    filtered.click{count,j+1} = data.click{i,j+1};
                end
            end
        end
    end
end

% Return empty when filter critera does not find any matching data
if ~logical(exist('filtered'))
    filtered.table = {};
    filtered.click = {};
    filtered.dp = {};
    filtered.gas = {};
end



end