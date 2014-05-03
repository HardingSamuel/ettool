function [ETT] = proj_SubAdd(ETT)
%
% proj_SubAdd
% Add a new subject to the ETT structure and return to the caller
%
% INPUTS:
% ETT - existing ETT data file
%
% OUTPUTS:
% ETT - modified ETT data
%
%% Change Log
%   [SH] - 04/29/14:    v1 - Creation

%%


% NOT USED AS FUNCTIONALITY WRITTEN DIRECTLY INTO PROJ_SUBMANAGE INSTEAD OF
% BEING SEPARATE AS HERE.

temp_dataloc = '';
AddSubjectFig = figure('Name', 'Add Subject', 'Unit', 'Pixels', 'Position', [460 670 400 230], 'NumberTitle','Off','MenuBar','None',...
    'Color', [.65 .75 .65]);
uipanel('Title', 'Subject Number', 'Units', 'Pixels', 'Position', [20 170 225 55], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
SubN = uicontrol('Style','Edit','String','','Position',[25 177.5 215 27.5],'Backgroundcolor',[1 1 1],'FontSize',10);
uipanel('Title', 'Date of Birth', 'Units', 'Pixels', 'Position', [20 110 225 55], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
DOB = uicontrol('Style','Edit','String','','Position',[25 117.5 215 27.5],'Backgroundcolor',[1 1 1],'FontSize',10);
uipanel('Title', 'Date Tested', 'Units', 'Pixels', 'Position', [20 50 225 55], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
TestD = uicontrol('Style','Edit','String','','Position',[25 57.5 215 27.5],'Backgroundcolor',[1 1 1],'FontSize',10);

uipanel('Title', 'Status', 'Units', 'Pixels', 'Position', [265 50 115 175], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
DatafileText = uicontrol('Style','Text','Position',[270 157.5 105 45],'Backgroundcolor',[.7 .8 .7],'FontSize',13,'ForegroundColor',[1 0 0],'HorizontalAlignment','Left',...
    'String','Data File Not Found');
uicontrol('Style','Text','Position',[270 107.5 105 45],'Backgroundcolor',[.7 .8 .7],'FontSize',13,'ForegroundColor',[1 0 0],'HorizontalAlignment','Left',...
    'String','Not      Imported  ');
uicontrol('Style','Text','Position',[270 57.5 105 45],'Backgroundcolor',[.7 .8 .7],'FontSize',13,'ForegroundColor',[1 0 0],'HorizontalAlignment','Left',...
    'String','Not Processed');


uicontrol('Style','PushButton','String','Locate Data File','Position',[20 10 225 30],'FontSize',12,'Callback',@pick_data)
uicontrol('Style','PushButton','String','Finished','Position',[265 10 115 30],'FontSize',12,'Callback',@done)


    function pick_data(~,~)
        subn = get(SubN,'String');
        [filename, filepath] = uigetfile(...
            {'*.gazedata', 'Gazedata Files (*.gazedata)';...
            '*.csv', '.CSV Files (*.csv)';...
            '*.xlsx', 'Excel Files (.xlsx)'},...
            ['Select a Data file for Subject ' subn]);
        set(DatafileText,'ForegroundColor',[.2 .75 .2],'String','Data File Loaded')
        temp_dataloc = [filepath,filename];        
    end

    function done(~,~)
        existingsubs = ETT.nSubjects;
        temp_subn = get(SubN,'String');
        temp_dob = get(DOB,'String');
        temp_testd = get(TestD,'String');
        if ~isempty(temp_subn) && ~strcmp(temp_subn,'')
            ETT.nSubjects = ETT.nSubjects + 1;
            ETT.SubjectsList{existingsubs+1} = {temp_subn};
            ETT.SubjectsData{existingsubs+1} = {temp_dataloc};
            ETT.SubjectsDOB{existingsubs+1} = {temp_dob};
            ETT.SubjectsTestD{existingsubs+1} = {temp_testd};
            close(AddSubjectFig)            
        end
    end

waitfor(AddSubjectFig)
end