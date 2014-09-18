function ett_versioncheck

toolpath = fileparts(which('ettool.m'));
filename = dir(fullfile(toolpath, 'ETvers.m'));

onlinevers = urlread('http://129.79.193.101:8000/ETTvers.txt');
fid = fopen(filename.name);
fgets(fid);
fgets(fid);
myvers = fgets(fid);
fclose(fid);

if ~strcmp(myvers,onlinevers)
    msgbox('Your ETTool is out of date.  Update before continuing','ETT-Out of Date');
end

end

