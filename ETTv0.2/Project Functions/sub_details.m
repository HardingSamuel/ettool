function [ETT,subwinpos] = sub_details(ETT,selected,mode,subwinpos)
%
% sub_details
% Get additional details about a subject from Manage Subjects, Import, or
% Process window.  Helpful for determining if each step has
% been completed before re-importing, processing etc. . .
%
% INPUTS:
% ETT - current project
%
% OUTPUTS:
% ETT - project, potentially with new information, depending on the mode of
% operation.
%
%% Change Log
%   [SH] - 05/01/14:    v1 - Creation

%%

switch mode
    case 0
        title_addedit = 'Add Subject';
        
        temp_subn = '';
        temp_dataloc = '';
        temp_dob = '';
        temp_TestDate = '';
        
        text_data = 'Data File Not Found';
        text_import = 'Not      Imported  ';
        text_process = 'Not Processed';
    case 1
        title_addedit = 'Edit Subject';
        
        temp_subn = ETT.Subjects(selected).Name;
        temp_dataloc = ETT.Subjects(selected).Data.Raw;
        temp_dob = ETT.Subjects(selected).DOB;
        temp_TestDate = ETT.Subjects(selected).TestDate;
        
        text_data = 'Data File Loaded';
        text_import = ETT.Subjects(selected).Status.Import;
        text_process = ETT.Subjects(selected).Status.PreProcess;
end

col_dataloc = [1 0 0];
col_import = [1 0 0];
col_process = [1 0 0];

if ~strcmp(temp_dataloc,'')
    col_dataloc = [.2 .75 .2];
end
if ~strcmp(text_import,'Not      Imported  ')
    col_import = [.2 .75 .2];
end
if ~strcmp(text_process,'Not Processed')
    col_process = [.2 .75 .2];
end

AddSubjectFig = figure('Name', title_addedit, 'Unit', 'Pixels', 'Position', subwinpos, 'NumberTitle','Off','MenuBar','None',...
    'Color', [.65 .75 .65]);
uipanel('Title', 'Subject Number', 'Units', 'Pixels', 'Position', [20 170 225 55], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
SubN = uicontrol('Style','Edit','String',temp_subn,'Position',[25 177.5 215 27.5],'Backgroundcolor',[1 1 1],'FontSize',10);
uipanel('Title', 'Date of Birth', 'Units', 'Pixels', 'Position', [20 110 225 55], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
DOB = uicontrol('Style','Edit','String',temp_dob,'Position',[25 117.5 215 27.5],'Backgroundcolor',[1 1 1],'FontSize',10);
uipanel('Title', 'Date Tested', 'Units', 'Pixels', 'Position', [20 50 225 55], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
TestDate = uicontrol('Style','Edit','String',temp_TestDate,'Position',[25 57.5 215 27.5],'Backgroundcolor',[1 1 1],'FontSize',10);

uipanel('Title', 'Status', 'Units', 'Pixels', 'Position', [265 50 115 175], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
DatafileText = uicontrol('Style','Text','Position',[270 157.5 105 45],'Backgroundcolor',[.7 .8 .7],'FontSize',13,'ForegroundColor',col_dataloc,'HorizontalAlignment','Left',...
    'String',text_data);
uicontrol('Style','Text','Position',[270 107.5 105 45],'Backgroundcolor',[.7 .8 .7],'FontSize',13,'ForegroundColor',col_import,'HorizontalAlignment','Left',...
    'String',text_import);
uicontrol('Style','Text','Position',[270 57.5 105 45],'Backgroundcolor',[.7 .8 .7],'FontSize',13,'ForegroundColor',col_process,'HorizontalAlignment','Left',...
    'String',text_process);


uicontrol('Style','PushButton','String','Locate Data File','Position',[20 10 225 30],'FontSize',12,'Callback',{@pick_data,mode},...
    'BackGroundColor',[.8 .8 .8])
uicontrol('Style','PushButton','String','Finished','Position',[265 10 115 30],'FontSize',12,'Callback',{@done_adddetail,mode},...
    'BackGroundColor',[.8 .8 .8])

    function pick_data(~,~,mode)
        subn = get(SubN,'String');
        opdir = pwd;
        switch mode
            case 0
                cd(ETT.DefaultDirectory)
                [filename, filepath] = uigetfile(...
                    {'*.gazedata', 'Gazedata Files (*.gazedata)';...
                    '*.csv', '.CSV Files (*.csv)';...
                    '*.xlsx', 'Excel Files (.xlsx)'},...
                    ['Select a Data file for Subject ' subn]);
                set(DatafileText,'ForegroundColor',[.2 .75 .2],'String','Data File Loaded')
                temp_dataloc = [filepath,filename];
            case 1                
                sub_currdir = ETT.Subjects(selected).Data.Raw; sla = strfind(sub_currdir,'\');
                if length(sla)>0
                    sub_currfile = sub_currdir(sla(end)+1:end); sub_currdir = sub_currdir(1:sla(end));
                else
                    sub_currdir = ETT.DefaultDirectory;
                    sub_currfile = '';
                end
                cd(sub_currdir)
                [filename, filepath] = uigetfile(...
                    {'*.gazedata', 'Gazedata Files (*.gazedata)';...
                    '*.csv', '.CSV Files (*.csv)';...
                    '*.xlsx', 'Excel Files (.xlsx)'},...
                    ['Select a Data file for Subject ' subn],...
                    sub_currfile);
                set(DatafileText,'ForegroundColor',[.2 .75 .2],'String','Data File Loaded')
                temp_dataloc = [filepath,filename];
        end
        cd(opdir);
    end

    function done_adddetail(~,~,mode)        
        temp_subn = get(SubN,'String');
        temp_dob = get(DOB,'String');
        temp_TestDate = get(TestDate,'String');
        switch mode
            case 0
                if ~strcmp(temp_subn,'')
                    edit_sub = ETT.nSubjects + 1;
                    ETT.nSubjects = ETT.nSubjects + 1;
                    ETT.Subjects(edit_sub).Status.Import = 'Not      Imported  ';
                    ETT.Subjects(edit_sub).Status.PreProcess = 'Not Processed';
                    ETT.Subjects(edit_sub).Config.Import = [];                    
                    ETT.Subjects(edit_sub).Config.PreProcess = [];
                    ETT.Subjects(edit_sub).Config.FixDetect = [];
                    ETT.Subjects(edit_sub).Config.AdditionalAnalyses = [];
                end
            case 1
                edit_sub = selected;
        end
        if ~isempty(temp_subn) && ~strcmp(temp_subn,'')
            ETT.Subjects(edit_sub).Name = temp_subn;
            ETT.Subjects(edit_sub).Data.Raw = temp_dataloc;
            ETT.Subjects(edit_sub).DOB = temp_dob;
            ETT.Subjects(edit_sub).TestDate = temp_TestDate;
        end
        subwinpos = get(AddSubjectFig,'Position');
        close(AddSubjectFig)
    end


waitfor(AddSubjectFig)
end
