function ett_versioncheck
% 09/22/15:   updated to check PC/Mac because Geno!
global sla 
if ispc; sla = '\'; elseif ismac; sla = '/'; else msgbox('What kind of computer are you using?'); end

toolpath = fileparts(which('ettool.m'));
filename = dir(fullfile(toolpath, 'ETvers.m'));
try
    onlinevers = urlread('http://www.indiana.edu/~dcnlab/ETTversion/ETTvers.txt','Timeout',2);
catch err
    msgbox('Could not connect to Host - contact Sam');
    return
end
try
    fid = fopen(filename.name);
    fgets(fid);
    fgets(fid);
    myvers = fgets(fid);
    fclose(fid);
    if ~strcmp(myvers,onlinevers)
        msgbox('Your ETTool is out of date.  Update before continuing','ETT-Out of Date');
    end
catch err
    msgbox('Your ETTool is out of date.  Update before continuing','ETT-Out of Date');
end



end

