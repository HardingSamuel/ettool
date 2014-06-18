function [ETT] = proj_SubManage(ETT)
%
% proj_SubManage
% Allows users to display, add, and remove subjects from their project and
% find additional information about that subject's status in processing.
%
% INPUTS:
% ETT - current ETT project
%
% OUTPUTS:
% ETT - ETT with adjusted subject information
%
%% Change Log
%   [SH] - 04/29/14:    v1 - Creation

%%
subwinpos = [460 670 400 230];

init_enable = 'on';
if ~isfield(ETT, 'Subjects') || ETT.nSubjects == 0
    sub_text = cell(0,0);
    init_enable = 'off';
else
    sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
end


SubjectFig = figure('Name', 'Manage Subjects', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);
uipanel('Title', 'Current Subjects', 'Units', 'Pixels', 'Position', [20 70 200 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Subslist = uicontrol('Style','Listbox','Position',[25 75 190 220],'Parent',SubjectFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',sub_text,'Max',1);

uipanel('Title', 'Options', 'Units', 'Pixels', 'Position', [230 70 150 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style', 'Pushbutton', 'String', 'Add Subject', 'Position', [240 226 130 63],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@sub_adddetail,0});
butt_rem = uicontrol('Style', 'Pushbutton', 'String', 'Remove Subject', 'Position', [240 153 130 63],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',@sub_rem,'Enable',init_enable);
butt_det = uicontrol('Style', 'Pushbutton', 'String', 'Details/Edit', 'Position', [240 80 130 63],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@sub_adddetail,1},'Enable',init_enable);

uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 50], 'ForegroundColor', [.1 .1 .1],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Callback',@done_all)


%%

    function sub_rem(~,~)
        selected = get(Subslist,'Value');
        ETT.Subjects(selected) = [];
        sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
        set(Subslist,'String',sub_text,'Value',1)
        ETT.nSubjects = ETT.nSubjects - 1;
        if ETT.nSubjects <= 0
            set(butt_rem, 'Enable', 'Off');
            set(butt_det, 'Enable', 'Off');
            ETT.Config.Import = [];
            ETT.Config.PreProcess = [];
        else
            set(butt_rem, 'Enable', 'On');
            set(butt_det, 'Enable', 'On');
        end
    end

    function sub_adddetail(~,~,mode)
        selected = get(Subslist,'Value');
        [ETT,subwinpos] = sub_details(ETT,selected,mode,subwinpos);
        sub_text = '';
        if isfield(ETT,'Subjects')
            sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
            set(Subslist,'String',sub_text)
            set(butt_rem,'Enable','On')
            set(butt_det,'Enable','On')
        end
        figure(SubjectFig)
    end

    function done_all(~,~)
        close(SubjectFig)
    end

waitfor(SubjectFig)
end