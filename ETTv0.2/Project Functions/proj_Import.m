function [ETT,ERRORS] = proj_Import(ETT)
%
% proj_Import
% Import raw eye-tracking data for a subject and link it to the project
% structure.  The data for each subject will be stored as separate .mat
% files and loaded on-demand when needed down the line.
%
% INPUTS:
% ETT - an existing ETT Project
%
% OUTPUTS:
% ETT - ETT updated with information about the date/time of import and
% status of the import process for each subject.
%
%% Change Log
%   [SH] - 04/30/14:   v1 - Creation
%   [SH] - 06/25/14:   v1.1 - Renamed variables for consistency, check
%   project at beginning to ensure existence of required fields.

%%
ERRORS = [];
datafid = []; col_arrange = []; redraw = 0;
init_enable = 'On'; imp_enable = 'On'; init_colenable = 'On';
init_style = 'Listbox'; 

col_subbut = [0 0 0];
if ~isfield(ETT, 'Subjects') || ETT.nSubjects == 0
    sub_text = '-- No Subjects Found -- Please add subjects using ''Manage Subjects'' first';
    init_enable = 'off';
    init_style = 'Text';
    init_colenable = 'Off';
else
    sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
    if ~isempty(ETT.Subjects(1).Config.Import)
        imp_enable = 'on';
        col_subbut = [.25 .7 .25];
    end
end

col_projcol = [.25 .7 .25];
if isempty(ETT.Config.Import)
    imp_enable = 'off';
    col_projcol = [0 0 0];
end


ImportFig = figure('Name', 'Select Subjects to Import', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uipanel('Title', 'Attached Subjects', 'Units', 'Pixels', 'Position', [20 70 200 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Subslist = uicontrol('Style',init_style,'Position',[25 75 190 220],'Parent',ImportFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',sub_text,'Max',length(sub_text),'Callback',@updatecolors);

uipanel('Title', 'Options', 'Units', 'Pixels', 'Position', [230 70 150 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

ImpButton = uicontrol('Style', 'Pushbutton', 'String', 'Import', 'Position', [240 248.75 130 46.25],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',@sub_import,'Enable',imp_enable);
SetProjBut = uicontrol('Style', 'Pushbutton', 'String', 'Settings (Project)', 'Position', [240 192.5 130 46.25],'FontSize', 10,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@col_manage,0},'ForeGroundColor',col_projcol,'Enable',init_colenable);
SetSubBut = uicontrol('Style', 'Pushbutton', 'String', 'Settings (Selected)', 'Position', [240 136.25 130 46.25],'FontSize', 10,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@col_manage,1},'ForeGroundColor',col_subbut,'Enable',init_colenable);

uicontrol('Style', 'Pushbutton', 'String', 'Details/Edit', 'Position', [240 80 130 46.25],'FontSize', 12,...
    'BackgroundColor',[.8 .8 .8],'Callback',{@imp_detail,1},'Enable',init_enable);

uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 46.25], 'ForegroundColor', [.1 .1 .1],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Callback',@doneall)

    function col_manage(~,~,mode)
        selected = get(Subslist,'Value');
        col_cust = ETT.Subjects(selected(1)).Config.Import;
        col_proj = ETT.Config.Import;
        
        hascustom = ~isempty(col_cust);
        datafid = fopen(ETT.Subjects(selected(1)).Data.Raw);
        colheadings = strsplit(fgets(datafid),'\t');
        fclose(datafid);
        
        switch mode
            case 0
                col_arrange = col_proj;
            case 1
                col_arrange = col_cust;
        end
        [col_arrange_out,remove_cust] = sett_Import(colheadings(24:end),col_arrange,hascustom);                    
        switch mode
            case 0
                ETT.Config.Import = col_arrange_out;
                set(SetProjBut,'ForeGroundColor',[.25 .7 .25])
            case 1
                for subi = selected                    
                    ETT.Subjects(subi).Config.Import = col_arrange_out;                    
                    if remove_cust
                        ETT.Subjects(subi).Config.Import = [];
                        @updatecolors;
                    end
                end                
        end
        if ~isempty(col_arrange_out)
            set(ImpButton,'Enable','On')
        end
        clear col_arrange_out
        
    end

    function sub_import(~,~)
        selected = get(Subslist,'Value');
        [ETT,ERRORS] = proj_batch(ETT,selected,1);
        figure(ImportFig)
    end

    function imp_detail(~,~,mode)
        selected = get(Subslist,'Value');
        [ETT] = sub_details(ETT,selected,mode);
        sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
        set(Subslist,'String',sub_text)
    end

    function doneall(~,~)
        close(ImportFig)                   
    end

    function updatecolors(~,~)
        selected = get(Subslist,'Value');
        anycustoms = cell2mat(arrayfun(@(X) ~isempty(ETT.Subjects(X).Config.Import),selected,'uni',0));
        if any(anycustoms)
            set(ImpButton,'Enable','On')
            set(SetSubBut,'ForeGroundColor',[.25 .7 .25]);
        else
            set(SetSubBut,'ForeGroundColor',[0 0 0]);
        end
        if ~isempty(ETT.Config.Import)
            set(ImpButton,'Enable','On')
            set(SetProjBut,'ForegroundColor',[.25 .7 .25]);
        else
            set(ImpButton,'Enable','Off')
            set(SetProjBut,'ForegroundColor',[0 0 0]);
        end
    end


waitfor(ImportFig)

end