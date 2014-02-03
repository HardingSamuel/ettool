function [subslist] = pop_subselect(direct)

    directory = dir([direct, '/MATLAB/INPUT/DATA/XLSDATA/']);
    
    subfig = figure('Position', [340 660 250 230], 'Name', 'Select Subjects', 'NumberTitle', 'off', 'MenuBar', 'none');
%     set(subfig, 'Name', 'Select Subjects')
%     set(subfig, 'NumberTitle', 'off')
%     set(subfig, 'MenuBar', 'none')
    
    for i = 3:length(directory)
        sublist(i-2) = str2num(directory(i).name(end-9:end-7));
    end
    
    OkayButton = uicontrol('Style', 'pushbutton', 'Position', [5 5 115 40], 'String', 'Okay', 'Parent', subfig, 'Callback', 'uiresume(gcbf)');    
    SubsList = uicontrol('Style', 'listbox', 'Max', length(sublist), 'Min', 1, 'String', {sublist'}, 'Position', [5 50 240 180], 'Parent', subfig);
    
    uiwait(gcf)
    subslist = get(SubsList, 'Value');
    close
end


    

    