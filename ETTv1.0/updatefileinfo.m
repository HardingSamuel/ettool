function [DatafileName, lastchange] = updatefileinfo(Direct,StudyName,mode)

switch mode
    case 1
        modestr = 'RAWDATA';
    case 2
        modestr = 'PROCDATA';
end

currenttime = clock; currenttime = strcat(num2str(currenttime(4)), '-', num2str(currenttime(5)));
currentdate = date; currentdate = strcat(currentdate(end-3:end), '-', currentdate(1:end-5));
DatafileName = [Direct, '\MATLAB\INPUT\', modestr, '\', currentdate, '_' currenttime, '_', StudyName '_' modestr, '.mat'];

lastchange = currenttime;


end
