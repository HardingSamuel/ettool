function ett_versioncheck

toolpath = fileparts(which('ettool.m'));
filename = dir(fullfile(toolpath, 'ETvers.m'));
try
    onlinevers = urlread('http://129.79.193.101:8000/ETTvers.txt');
catch err
    msg('Could not connect to Host - Sam''s computer is probably off');
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

