function [fTable, fOn, fDp] = filterSub(tData, oData, dPoint, expression, searchTerm)
% Filtering Subroutine
%
% Jim Oreluk 2016.02.22
%
%  Purpose: Repeated task for filtering table information.

count = 0;
for i = 1:size(tData,1)
    if eval(expression)
        count = count + 1;
        for j = 1:size(tData,2)
            fTable{count,j} = tData{i,j};
            fOn{count,j} = oData{i,j};
            fDp{count} = dPoint{1,i};
        end
    end
end
