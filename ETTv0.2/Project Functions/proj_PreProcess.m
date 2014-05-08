function [ETT] = proj_PreProcess(ETT)
%
% proj_PreProcess
% To be run after importing, will do basics such as interpolation and
% smoothing
%
% INPUTS:
% ETT
%
% OUTPUTS:
% ETT
%
%% Change Log
%   [SH] - 05/05/14:    v1 - Creation

%%
init_enable = 'On'; imp_enable = 'On'; init_colenable = 'On';
init_style = 'Listbox'; col_subbut = [0 0 0];

if ~isfield(ETT, 'Subjects') || ETT.nSubjects == 0
    sub_text = '--No Subjects Found -- Please add subjects using ''Manage Subjects'' first.';
    init_enable = 'off';
    init_style = 'Text';
    init_colenable = 'Off';
else
    sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
    if ~isempty(ETT.Subjects(1).Config.PreProcess)
        imp_enable = 'on';
        col_subbut = [.25 .7 .25];
    end
end

col_projsett = [.25 .7 .25];
if isempty(ETT.Config.PreProcess)
    imp_enable = 'off';
    col_projsett = [0 0 0];
end

ProcessFig = figure('Name', 'Select Subjects to PreProcess', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uipanel('Title', 'Attached Subjects', 'Units', 'Pixels', 'Position', [20 70 200 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Subslist = uicontrol('Style',init_style,'Position',[25 75 190 220],'Parent',ProcessFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',sub_text,'Max',length(sub_text),'Callback',@updatecolors);

uipanel('Title', 'Options', 'Units', 'Pixels', 'Position', [230 70 150 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

ProcButton = uicontrol('Style', 'Pushbutton', 'String', 'PreProcess', 'Position', [240 248.75 130 46.25],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',@sub_process,'Enable',imp_enable);
SetProjBut = uicontrol('Style', 'Pushbutton', 'String', 'Settings (Project)', 'Position', [240 192.5 130 46.25],'FontSize', 10,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@procset_manage,0},'ForeGroundColor',[0 0 0],'Enable',init_enable,...
    'ForegroundColor',col_projsett);
SetSubBut = uicontrol('Style', 'Pushbutton', 'String', 'Settings (Selected)', 'Position', [240 136.25 130 46.25],'FontSize', 10,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@procset_manage,1},'ForeGroundColor',[0 0 0],'Enable',init_enable,...
    'ForegroundColor',col_subbut);

uicontrol('Style', 'Pushbutton', 'String', 'Details/Edit', 'Position', [240 80 130 46.25],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@imp_detail,1},'Enable',init_enable);
uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 46.25], 'ForegroundColor', [.1 .1 .1],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Callback',@doneall)


    function sub_process(~,~)
        selected = get(Subslist,'Value');
        [ETT] = proj_batch(ETT,selected,2);
        figure(ProcessFig)
    end

    function imp_detail(~,~,mode)
        selected = get(Subslist,'Value');
        [ETT] = sub_details(ETT,selected,mode);
        sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
        set(Subslist,'String',sub_text)
    end

    function procset_manage(~,~,mode)
        selected = get(Subslist,'Value');
        Settings = ETT.Config.PreProcess;
        if mode
            Settings = ETT.Subjects(selected).Config.PreProcess;
        end            
        [NewSettings] = sett_PreProcess(ETT,0,Settings);
        if mode
            if all(NewSettings == ETT.Config.PreProcess);
                NewSettings = [];
            end
            ETT.Subjects(selected).Config.PreProcess = NewSettings;
        else
            ETT.Config.PreProcess = NewSettings;
        end            
    end

    function updatecolors(~,~)
        selected = get(Subslist,'Value');
        anycustoms = cell2mat(arrayfun(@(X) ~isempty(ETT.Subjects(X).Config.PreProcess),selected,'uni',0));
        if any(anycustoms)
            set(SetProjBut,'Enable','On')
            set(SetSubBut,'ForeGroundColor',[.25 .7 .25]);
        else
            set(SetSubBut,'ForeGroundColor',[0 0 0]);
        end
        if ~isempty(ETT.Config.PreProcess)
            set(ProcButton,'Enable','On')
            set(SetProjBut,'ForegroundColor',[.25 .7 .25]);
        else
            set(ProcButton,'Enable','Off')
            set(SetProjBut,'ForegroundColor',[0 0 0]);
        end
    end

    function doneall(~,~)
        close(ProcessFig)
    end

waitfor(ProcessFig)
end