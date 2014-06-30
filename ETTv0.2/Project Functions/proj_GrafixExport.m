function [ETT,ERRORS] = proj_GrafixExport(ETT)
% 
% proj_GrafixExport
% Export raw or filtered data to Grafix format to calculate fixations.
% Alternative to built-in fixation detection algorithm.
% 
% INPUTS:
% ETT
% 
% OUTPUTS:
% ETT
% 
%% Change Log
%   [SH] - 06/25/14:  v1 - Creation 
%   [SH] - 06/25/14:   v1.1 - Renamed variables for consistency, check
%   project at beginning to ensure existence of required fields.

%%

[ETT] = proj_CheckUpdate(ETT);

ERRORS = [];
init_enable = 'On'; gra_enable = 'On';
init_style = 'Listbox';
curr_mode = 1;

if ~isfield(ETT, 'Subjects') || ETT.nSubjects == 0
    sub_text = '-- No Subjects Found -- Please add subjects using ''Manage Subjects'' first';
    init_enable = 'off';
    init_style = 'Text';
elseif all(strcmp(cat(1,arrayfun(@(X) ETT.Subjects(X).Status.Import, 1:length(ETT.Subjects),'uni',0)),'Not      Imported  '))
    sub_text = '-- No Subjects Imported -- Please Import subjects using ''Import Data'' first';
    init_enable = 'off';
    init_style = 'Text';
else
    sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
    if ~isempty(ETT.Subjects(1).Config.GrafixExport)
        gra_enable = 'on';
        
    end
end

curr_dir = ETT.DefaultDirectory;
if ~isempty(ETT.Config.GrafixExport)
    curr_mode = ETT.Config.GrafixExport{1};
    curr_dir = ETT.Config.GrafixExport{2};
end

GrafixFig = figure('Name', 'Select Subjects to Export', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uipanel('Title', 'Attached Subjects', 'Units', 'Pixels', 'Position', [20 70 200 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Subslist = uicontrol('Style',init_style,'Position',[25 75 190 220],'Parent',GrafixFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',sub_text,'Max',length(sub_text));

uipanel('Title', 'Options', 'Units', 'Pixels', 'Position', [230 70 150 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

GrafButton = uicontrol('Style', 'Pushbutton', 'String', 'Export', 'Position', [240 248.75 130 46.25],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',@sub_export,'Enable',gra_enable);


ModeButtonGroup = uibuttongroup('Visible','On','units','Pixels','Position',[240 175 130 68.75],'BackGroundColor',[.7 .8 .7],...
    'Title','Data Mode:','TitlePosition','lefttop','FontSize',12,'SelectionChangefcn',@mode_select);
uicontrol('Style','RadioButton','String','Raw','Enable','On','Value',1,...
    'Position',[2.5 25 120 25],'FontSize',10,'Parent',ModeButtonGroup,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_mode==1,'UserData',1);
uicontrol('Style','RadioButton','String','PreProcessed','Enable','On','Value',0,...
    'Position',[2.5 5 120 25],'FontSize',10,'Parent',ModeButtonGroup,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_mode==2,'UserData',2);

uicontrol('Style', 'Pushbutton', 'String', 'Output Directory', 'Position', [240 118.75 130 46.25],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',@select_outputdir,'Enable',init_enable);
uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 46.25], 'ForegroundColor', [.1 .1 .1],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Callback',@doneall)
DirectText = uicontrol('Style','Edit','Enable','On','String',curr_dir,'Position',[240 80 130 28.75]);

    function mode_select(~,eventdata)
        curr_mode = get(eventdata.NewValue,'UserData');
    end

    function sub_export(~,~)
        ETT.Config.GrafixExport{1} = curr_mode;
        ETT.Config.GrafixExport{2} = curr_dir;
        selected = get(Subslist,'Value');
        [ETT,ERRORS] = proj_batch(ETT,selected,4);
        figure(GrafixFig)
    end

    function select_outputdir(~,~)
        curr_dir = uigetdir(curr_dir,'Select Grafix output directory location');        
        set(DirectText,'String',curr_dir)
    end       

    function doneall(~,~)
        ETT.Config.GrafixExport{1} = curr_mode;
        ETT.Config.GrafixExport{2} = curr_dir;
        close(GrafixFig)
    end

waitfor(GrafixFig)


end