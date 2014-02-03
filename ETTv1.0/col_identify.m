function [coldata] = col_identify(direct, sublist)

DIRECT = dir([direct, '/MATLAB/INPUT/DATA/XLSDATA/']);
[num, ~, raw] = xlsread([direct, '/MATLAB/INPUT/DATA/XLSDATA/', DIRECT(sublist(1)+2).name]);

columns = raw(1,:);
for i = length(columns):-1:1
    if ~isnan(columns{i})
        break
    end
end
coln = i;
coln = i - 23;

collist = columns(24:23+coln);
numerical = ([raw(2:20,24:end)]);
for col_i = 1:length(collist)
    checknum = [numerical{:,col_i}];
    if all(isnumeric(checknum))
        coltypes(1,col_i) = 1;
    else
        coltypes(1,col_i) = 0;
    end
end

for findtrial = find(coltypes(1,:) == 1)
    [C, IA, IC] = unique(num(:,23 + findtrial),'stable');
    if all(sort(C) == C) %if they increment from low to high
        coltypes(2, findtrial) = 1;
    else
        coltypes(2, findtrial) = 0;
    end
end

for findphase = find(coltypes(2,:) == 0)
    
    
    

keyboard
end