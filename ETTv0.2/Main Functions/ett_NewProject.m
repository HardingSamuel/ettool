function [ETT,Status] = ett_NewProject

% ett_NewProject
% Called from the main ETTool window, allows users to create a new project
% for analysis.  Each project should have separate data files associated
% with it, typically one for each subject that will later be imported.
%
% It is intended for all analyses to be conducted at the project level, so it
% is recommended to create new projects for different data sets.
%
% INPUTS:
%
% OUTPUTS:
% ETT - new ETT structure
% Status - success/fail returned to caller
%
%% Changelog
%   [SH] - 04/28/14:   v1 - Creation
%   [SH] - 09/12/14:   Changed order of operations such that Subjects,
%   Default Directory, etc, appear before auto save.  Previously, the file
%   was saved before these fields were added, so if the user forgot to
%   save, the .etp became corrupted when searching for non-existent fields,
%   because they were added after having been saved.

%%

ETT = [];
Status = [];


NewProjectFig = figure('Name', 'Create a New Project', 'pos', [40 800 400 100], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uipanel('Title', 'Project Name (press enter to continue)', 'Position', [.05 .05 .9 .9], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style','Edit','Position',[30 25 340 35],'Parent',NewProjectFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'Callback',@savepass);

    function savepass(obj,~)
        ETT.ProjectName = get(obj,'String');
        ETT.nSubjects = 0;
        ETT.CreationDate = datestr(now);
        ETT.FileName = '';
        ETT.PathName = '';
        
        ETT.DefaultDirectory = ETT.PathName;
        ETT.Config.Import = [];
        ETT.Config.PreProcess = [1 80 500 15 2];
        ETT.Config.FixDetect = [];
        ETT.Config.AdditionalAnalyses = [];
        ETT.Subjects = [];
        
        ETT.ScreenDim.Width = 508;
        ETT.ScreenDim.Height = 287.75;
        ETT.ScreenDim.PixX = 1920;
        ETT.ScreenDim.PixY = 1080;
        ETT.ScreenDim.StimX = [0 1920];
        ETT.ScreenDim.StimY = [0 1080];
                
        [ETT,SaveStatus] = ett_SaveProject(ETT,2);
        
        if SaveStatus
            Status = 1;
            close(gcf)
        else
            Status = 0;
            delete(obj)
            uicontrol('Style','Pushbutton','String','Unable to Save File (Click to return)','pos',[30 25 340 35],'BackgroundColor',[.8 .8 .8],...
                'ForeGroundColor',[1 0 0],'Callback','close(gcf); clear ETT','FontSize',12);
        end
    end

waitfor(NewProjectFig)

end

