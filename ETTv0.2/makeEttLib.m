clear all

%% Colors
ettLib.Colors.DarkGreen = [.65 .75 .65];
ettLib.Colors.LightGreen = [.85 .95 .85];



%% Figures

% Main Figure
ettLib.Figures.Main.Number = 1;
ettLib.Figures.Main.Properties.Units = 'Normalized';
ettLib.Figures.Main.Properties.Position = [.001 .6 .3 .35];
ettLib.Figures.Main.Properties.Name = 'Eyetracking Tool';
ettLib.Figures.Main.Properties.NumberTitle = 'Off';
ettLib.Figures.Main.Properties.MenuBar = 'None';
ettLib.Figures.Main.Properties.Color = ettLib.Colors.DarkGreen;

% ui menus
%   File
ettLib.Figures.Main.UIMenu(1).Parent = 'ettLib.Figures.Main.Handle';
ettLib.Figures.Main.UIMenu(1).Label = '&File';
ettLib.Figures.Main.UIMenu(1).Position = 1;
%   Project
ettLib.Figures.Main.UIMenu(2).Parent = 'ettLib.Figures.Main.Handle';
ettLib.Figures.Main.UIMenu(2).Label = '&Project';
ettLib.Figures.Main.UIMenu(2).Position = 2;
%   Tools
ettLib.Figures.Main.UIMenu(3).Parent = 'ettLib.Figures.Main.Handle';
ettLib.Figures.Main.UIMenu(3).Label = '&Tools';
ettLib.Figures.Main.UIMenu(3).Position = 3;
%   Help
ettLib.Figures.Main.UIMenu(4).Parent = 'ettLib.Figures.Main.Handle';
ettLib.Figures.Main.UIMenu(4).Label = '&Help';
ettLib.Figures.Main.UIMenu(4).Position = 4;

% submenus
%   File - New
ettLib.Figure.Main.UIMenu(5).Parent = 'ettLib.Figures.Main.UIMenu(1).Handle';
ettLib.Figure.Main.UIMenu(5).Label = '&New Project';
ettLib.Figure.Main.UIMenu(5).Position = 1;
ettLib.Figure.Main.UIMenu(5).Callback = ['ETT = ettNewProject; set(ProjectMenu'];

uimenu('Label','&New Project','Parent',FileMenu,'Position',1,...
    'Callback',['ETT = ett_NewProject;set(ProjectMenu,''Enable'',''On'');set(ToolsMenu,''Enable'',''On'');set(File_Save,''Enable'',''On'');'...
    'set(File_SaveAs,''Enable'',''On'');set(File_Clear,''Enable'',''on'');ett_DrawMain(ETT,ETTFig);']);
%   File - Open
ettLib.Figure.Main.UIMenu(6).Parent = 'ettLib.Figures.Main.UIMenu(1).Handle';
%   File - Save
ettLib.Figure.Main.UIMenu(7).Parent = 'ettLib.Figures.Main.UIMenu(1).Handle';
%   File - Save As
ettLib.Figure.Main.UIMenu(8).Parent = 'ettLib.Figures.Main.UIMenu(1).Handle';
%   File - Clear
ettLib.Figure.Main.UIMenu(9).Parent = 'ettLib.Figures.Main.UIMenu(1).Handle';

% New Project Figure
ettLib.Figures.NewProject.Properties.Number = 2;
ettLib.Figures.NewProject.Properties.Units = 'Normalized';
ettLib.Figures.NewProject.Properties.Position = [.302 .75 .3 .2];
ettLib.Figures.NewProject.Properties.Name = 'Make New Project';
ettLib.Figures.NewProject.Properties.NumberTitle = 'Off';
ettLib.Figures.NewProject.Properties.MenuBar = 'None';
ettLib.Figures.NewProject.Properties.Color = ettLib.Colors.DarkGreen;

%% Save settings
save ettLib ettLib

load ettLib

global ettLib