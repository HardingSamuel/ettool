%% Main function for running ettool

%   [SH] - 09/23/16:   Converted windows positions to relative coordinates,
%   changed figure settings to new formatting (e.g. handle.property = )

%% Initialize the shared data array

% close other figures, clear other data
close all
clear all

ETT = [];
%% Check version
ettVers = ett_versioncheck;
%% Get settings that are shared between functions (colors, positions etc...)
global ettLib
load('ettLib');


%% Make the main window
ETTFig = figure;
ETTFig.Units = 'Normalized';
ETTFig.Position = [.001 .6 .3 .35];
ETTFig.Name = ['Eyetracking Tool v' num2str(ettVers)];
ETTFig.NumberTitle = 'Off';
ETTFig.MenuBar = 'None';
ETTFig.Color = ettLib.Colors.LightGreen;

ett_DrawMain(ETT,ETTFig);

% Main Figure Config
FileMenu = uimenu('Label','&File','Parent',ETTFig,'Position',1);
ProjectMenu = uimenu('Label','&Project','Parent',ETTFig,'Enable','Off','Position',2);
ToolsMenu = uimenu('Label','&Tools','Parent',ETTFig,'Enable','Off','Position',3);
HelpMenu = uimenu('Label','&Help','Parent',ETTFig,'Enable','On','Position',4);

%FileMenu Config
File_New = uimenu('Label','&New Project','Parent',FileMenu,'Position',1,...
    'Callback',['ETT = ett_NewProject;set(ProjectMenu,''Enable'',''On'');set(ToolsMenu,''Enable'',''On'');set(File_Save,''Enable'',''On'');'...
    'set(File_SaveAs,''Enable'',''On'');set(File_Clear,''Enable'',''on'');ett_DrawMain(ETT,ETTFig);']);
File_Open = uimenu('Label','&Open Project','Parent',FileMenu,'Position',2,...
    'Callback',['ETT = ett_OpenProject; if ~isempty(ETT) set(ProjectMenu,''Enable'',''On'');set(ToolsMenu,''Enable'',''On'');set(File_Save,''Enable'',''On'');'...
    'set(File_SaveAs,''Enable'',''On'');set(File_Clear,''Enable'',''on'');ett_DrawMain(ETT,ETTFig); end']);
File_Save = uimenu('Label','&Save Project','Parent',FileMenu,'Position',3,'Enable','Off','Callback','ETT = ett_SaveProject(ETT,1);ett_DrawMain(ETT,ETTFig);');
File_SaveAs = uimenu('Label','Save Project &As','Parent',FileMenu,'Position',4,'Enable','Off','Callback','ETT = ett_SaveProject(ETT,2);ett_DrawMain(ETT,ETTFig);');
% -----------------------------------
File_Clear = uimenu('Label','&Clear Project','Parent',FileMenu,'Position',5,'Separator','On','Enable','Off',...
    'Callback',['ETT = [];set(ProjectMenu,''Enable'',''Off'');set(ToolsMenu,''Enable'',''Off'');set(File_Save,''Enable'',''Off'');'...
    'set(File_SaveAs,''Enable'',''Off'');set(File_Clear,''Enable'',''Off'');ett_DrawMain(ETT,ETTFig);']);
% -----------------------------------
File_Exit = uimenu('Label','E&xit Tool','Parent',FileMenu,'Position',6,'Separator','On','Callback','close(ETTFig); clear ETT');

%ProjectMenu Config
Project_Information = uimenu('Label','Project &Information','Parent',ProjectMenu,'Position',1,'Callback','ETT = proj_Info(ETT);ett_DrawMain(ETT,ETTFig);');
Project_Settings = uimenu('Label','Project &Settings','Parent',ProjectMenu,'Position',2,'Callback','ETT = proj_Settings(ETT); ett_DrawMain(ETT,ETTFig);');
% -----------------------------------
Project_ManageSubjects = uimenu('Label','&Manage Subjects','Parent',ProjectMenu,'Separator','On','Position',3,'Callback','ETT = proj_SubManage(ETT);ett_DrawMain(ETT,ETTFig);');
% -----------------------------------
Project_ImportData = uimenu('Label','&Import Data','Parent',ProjectMenu,'Separator','On','Position',4,'Callback','[ETT,ERRORS] = proj_Import(ETT);ett_DrawMain(ETT,ETTFig);');
Project_PreProcess = uimenu('Label','&Pre-Process Data','Parent',ProjectMenu,'Position',5,'Callback','[ETT,ERRORS] = proj_PreProcess(ETT);ett_DrawMain(ETT,ETTFig);');
Project_FixationSaccade = uimenu('Label','&Fixation Detection','Parent',ProjectMenu,'Position',6,'Callback','ETT = proj_FixationSaccade(ETT);ett_DrawMain(ETT,ETTFig);');
Project_Summarize = uimenu('Label','Summarize &Data','Parent',ProjectMenu,'Position',7,'Callback','proj_Summarize','Enable','Off');

%ToolsMenu Config
ToolsVisualize = uimenu('Label','&Visualize Data','Parent',ToolsMenu,'Position',1,'Callback','','Enable','Off');
Tools_VisScan = uimenu('Label','&Scan Paths','Parent',ToolsVisualize,'Position',1,'Callback','');
Tools_VisHeat = uimenu('Label','&Heat Maps','Parent',ToolsVisualize,'Position',2,'Callback','');
ToolsAdditional = uimenu('Label','&Additional Analyses','Parent',ToolsMenu,'Position',2,'Callback','ETT = proj_AdditionalAnalyses(ETT);ett_DrawMain(ETT,ETTFig);');
ToolsGrafix = uimenu('Label','Export to &Grafix','Parent',ToolsMenu,'Position',3,'Separator','On','Callback','[ETT,ERRORS] = proj_GrafixExport(ETT);ett_DrawMain(ETT,ETTFig);');

%AboutMenu Config
HelpAbout = uimenu('Label','&About','Parent',HelpMenu,'Position',1,'Callback','ett_About');

