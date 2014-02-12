function [done] = pri_init(DIRECT, mode, subslist, varargin)
    status = figure('Position', [72 604 494 132], 'Name', 'Calculating, Please Wait', 'NumberTitle', 'off', 'MenuBar', 'none', 'Color', [.1 .5 .1]);

    directory = dir([DIRECT, '/MATLAB/INPUT/DATA/XLSDATA/']);
    
      
    switch mode
        case 1
        modetext = 'Reading In';
        coldata = varargin{1};
        case 2
        modetext = 'Processing';
        analyoutput = varargin{1};
        customfileexe = varargin{2};
        case 3
        modetext = 'Summarizing';
    end
    
    for i = 3:length(directory)
        sublist(i-2) = str2num(directory(i).name(end-9:end-7));
    end
    
    if ~isempty(subslist)
        sub_text = sublist(subslist);
    else
        sub_text = 'All Subjects';
    end
    switch mode
        case {1,2}
            sub_text = [modetext, ' Subjects: ', num2str(sub_text)];
        case 3
            sub_text = [modetext, ' All Subjects: '];
    end
    
    statustext = uicontrol('Style', 'text', 'Position', [10 10 474 112], 'String', sub_text, 'BackgroundColor', [.2 .7 .2], 'FontSize', 12, 'ForegroundColor', [1 1 1]);
    pause(.5)
    switch mode
        case 1
            [status] = pop_ReadInV1_2_3(DIRECT, subslist, coldata);
        case 2
            [status] = pop_ProcessV1_4_1(DIRECT,subslist,analyoutput,customfileexe);
        case 3
            [status] = pop_SummaryV1_1(DIRECT);
    end
    
    set(statustext, 'String', status);
    
    Finished = uicontrol('Style', 'pushbutton', 'Position', [150 20 194 40], 'String', 'Return', 'BackgroundColor', [.7 .7 .7], 'FontSize', 16, 'ForegroundColor', [.2 .2 .2], 'Callback', 'close');
    
    
end