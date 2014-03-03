function [rangename] = summ_sizetorange(startcell,data)
try
if ischar(startcell)
    startchar = startcell;
    startcell={startcell};
end
startchar = char(startcell);

alph = {'[A-Z]'};
alphlist = ['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R' 'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z'];
num = {'[0-9]'};

numsat = cell2mat(regexp(startcell,num));
letsat = cell2mat(regexp(startcell,alph));

rowoffset = str2double(startchar(numsat)) - 1;
coloffset = find(startchar(letsat) == alphlist) - 1;

rows = [str2double(startchar(numsat)), str2double(startchar(numsat)) + size(data,1) - 1];

alphloops = ceil((size(data,2)+coloffset)/26);
if alphloops > 1
    colstr = strcat(alphlist(alphloops-1), alphlist(mod(size(data,2)+coloffset,26)));
else
    colstr = alphlist(mod(size(data,2)+coloffset,26));
end
cols = [{startchar(letsat)}, {colstr}];

rangename = strcat(char(cols(1)),num2str(rows(1)),':',char(cols(2)),num2str(rows(2)));

catch
    keyboard
end