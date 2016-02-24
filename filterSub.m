function [fTable, fOn, fDp] = filterSub(varargin)
% Filtering Subroutine
%
% Jim Oreluk 2016.02.22
%
%  Purpose: Repeated task for filtering table information.

if length(varargin) >= 5
    tData = varargin{1};
    oData = varargin{2};
    dPoint = varargin{3};
    expression = varargin{4};
    searchTerm = varargin{5};
end

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

% Return empty when filter critera does not find any matching data
if ~logical(exist('fTable'))
 fTable = {};
 fOn = {};
 fDp = {};
end

