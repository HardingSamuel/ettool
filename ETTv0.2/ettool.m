
close all
clear all


%%
ETT = [];
ETTFig = figure('Position', [40 500 400 400], 'Name', 'Eyetracking Tool v0.2', 'NumberTitle', 'off', 'MenuBar', 'none',...
    'Color', [.65 .75 .65]);
ett_DrawMain(ETT,ETTFig);

% Main Figure Config
FileMenu = uimenu('Label','File','Parent',ETTFig,'Position',1);
ProjectMenu = uimenu('Label','Project','Parent',ETTFig,'Enable','Off','Position',2);
AboutMenu = uimenu('Label','About','Parent',ETTFig,'Enable','On','Position',3);

%FileMenu Config
File_New = uimenu('Label','New Project','Parent',FileMenu,'Position',1,...
    'Callback',['ETT = ett_NewProject;set(ProjectMenu,''Enable'',''On'');set(File_Save,''Enable'',''On'');'...
    'set(File_SaveAs,''Enable'',''On'');set(File_Clear,''Enable'',''on'');ett_DrawMain(ETT,ETTFig);']);
File_Open = uimenu('Label','Open Project','Parent',FileMenu,'Position',2,...
    'Callback',['ETT = ett_OpenProject;set(ProjectMenu,''Enable'',''On'');set(File_Save,''Enable'',''On'');'...
    'set(File_SaveAs,''Enable'',''On'');set(File_Clear,''Enable'',''on'');ett_DrawMain(ETT,ETTFig);']);
File_Save = uimenu('Label','Save Project','Parent',FileMenu,'Position',3,'Enable','Off','Callback','ETT = ett_SaveProject(ETT,1);ett_DrawMain(ETT,ETTFig);');
File_SaveAs = uimenu('Label','Save Project As','Parent',FileMenu,'Position',4,'Enable','Off','Callback','ETT = ett_SaveProject(ETT,2);ett_DrawMain(ETT,ETTFig);');
% -----------------------------------
File_Clear = uimenu('Label','Clear Project','Parent',FileMenu,'Position',5,'Separator','On','Enable','Off',...
    'Callback',['ETT = [];set(ProjectMenu,''Enable'',''Off'');set(File_Save,''Enable'',''Off'');'...
    'set(File_SaveAs,''Enable'',''Off'');set(File_Clear,''Enable'',''Off'');ett_DrawMain(ETT,ETTFig);']);
% -----------------------------------
File_Exit = uimenu('Label','Exit Tool','Parent',FileMenu,'Position',6,'Separator','On','Callback','close(ETTFig); clear ETT');

%ProjectMenu Config
Project_Information = uimenu('Label','Project Information','Parent',ProjectMenu,'Position',1,'Callback','ETT = proj_Info(ETT);ett_DrawMain(ETT,ETTFig);');
Project_Settings = uimenu('Label','Project Settings','Parent',ProjectMenu,'Position',2,'Callback','ETT = proj_Settings(ETT);ett_DrawMain(ETT,ETTFig);');
% -----------------------------------
Project_ManageSubjects = uimenu('Label','Manage Subjects','Parent',ProjectMenu,'Separator','On','Position',3,'Callback','ETT = proj_SubManage(ETT);ett_DrawMain(ETT,ETTFig);');
% -----------------------------------
Project_ImportData = uimenu('Label','Import Data','Parent',ProjectMenu,'Separator','On','Position',4,'Callback','ETT = proj_Import(ETT);ett_DrawMain(ETT,ETTFig);');
Project_PProcess = uimenu('Label','Pre-Process Data','Parent',ProjectMenu,'Position',5,'Callback','proj_PProcess');
Project_AAnalysis = uimenu('Label','Additional Analyses','Parent',ProjectMenu,'Position',6,'Callback','proj_AAnalysis');
Project_Summarize = uimenu('Label','Summarize Data','Parent',ProjectMenu,'Position',7,'Callback','proj_Summarize');

