function [ETT] = proj_batch(ETT,selected,mode)
%
% proj_batch
% Process multiple entries of ETT (subjects, trials, etc. . .) with visual
% feedback for the user
%
% INPUTS:
% ETT - input project
%
% OUTPUTS:
% ETT - project with operaion complete
%
%% Change Log
%   [SH] - 05/01/14:    v1 - Creation

%%
switch mode
    case 1
        text_mode = 'Import';
    case 2
        text_mode = 'PreProcess';
end

batch_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, selected,'uni',0));

BatchFig = figure('Name', ['Batch Process:  ' text_mode], 'Unit', 'Pixels', 'Position', [40 542.5 400 330], 'NumberTitle','Off','MenuBar','None',...
    'Color', [.65 .75 .65]);
uipanel('Title', 'Batch List', 'Units', 'Pixels', 'Position', [20 70 170 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Batchlist = uicontrol('Style','Text','Position',[25 75 140 220],'Parent',BatchFig,'BackgroundColor',[.7 .8 .7],...
    'HorizontalAlignment','Left','FontSize',12,'String',batch_text);

uipanel('Title', 'Status', 'Units', 'Pixels', 'Position', [210 70 170 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
DoneButton = uicontrol('Style','PushButton','String','Finished','Position',[20 10 360 50],'Backgroundcolor',[.8 .8 .8],'FontSize',12,...
    'Callback',@done_batch,'Enable','Off');

stat_y = 275;
pause(1)
for batchi = 1:length(selected)
    BatchText = uicontrol('Style','Text','Position',[215 stat_y 140 20],'Parent',BatchFig,'BackgroundColor',[.7 .8 .7],...
        'HorizontalAlignment','Left','FontSize',12,'String',ETT.Subjects(batchi).Name,'ForeGroundColor',[.9 .9 0]);
    batch_text(1) = [];
    set(Batchlist,'String',batch_text)
    stat_y = stat_y - 20;
    pause(.1)
    [status] = batch_proc(batchi,mode);
    if status
        set(BatchText,'ForeGroundColor',[.25 .7 .25]);
    else
        set(BatchText,'ForeGroundColor',[1 0 0]);
    end
    
end


set(DoneButton,'Enable','On')


    function status = batch_proc(batchi,mode)
        switch mode
            case 1
                [status,statustext,usedcustom] = data_import(ETT,selected(batchi));
                importdatafname = [ETT.DefaultDirectory,'ProjectData\',ETT.Subjects(selected(batchi)).Name,'\SubjectData_',ETT.Subjects(selected(batchi)).Name,'.mat'];
                ETT.Subjects(selected(batchi)).Data.Import = importdatafname;
                addtext = '';
                if usedcustom
                    addtext = ' [C]';
                end
                ETT.Subjects(selected(batchi)).Status.Import = [datestr(now), addtext];
            case 2
                [status,statustext,usedcustom] = data_preprocess(ETT,selected(batchi));
                procdatafname = [ETT.DefaultDirectory,'ProjectData\',ETT.Subjects(selected(batchi)).Name,'\SubjectData_',ETT.Subjects(selected(batchi)).Name,'.mat'];
                ETT.Subjects(selected(batchi)).Data.PreProcess = procdatafname;
                addtext = '';
                if usedcustom
                    addtext = ' [C]';
                end
                ETT.Subjects(selected(batchi)).Status.PreProcess = [datestr(now), addtext];                
        end
    end

    function done_batch(~,~)
        close(BatchFig)
    end

waitfor(BatchFig)
end