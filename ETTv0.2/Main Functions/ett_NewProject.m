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
% initialize
ETT = [];
Status = [];

% make the figure
NewProjectFig = figure('Name', 'Create a New Project', 'pos', [40 800 400 100], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);
% add the text label
uipanel('Title', 'Project Name (press enter to continue)', 'Position', [.05 .05 .9 .9], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
% add the editable text box with callback to execute local function called
% savepass
uicontrol('Style','Edit','Position',[30 25 340 35],'Parent',NewProjectFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'Callback',@savepass);
  
    function savepass(obj,~)
%       run this when user hits enter, update ETT with relevant info
        ETT.ProjectName = get(obj,'String'); %extract the text they typed into the box
        ETT.nSubjects = 0; %set nsubs = 0
        ETT.CreationDate = datestr(now); %keep track of creation
        ETT.FileName = '';
        ETT.PathName = '';
%         set the default directory to the same place the .etp file is
%         saved. though to be fair, it doesn't have a path name until it is
%         actually saved
        ETT.DefaultDirectory = ETT.PathName;
        ETT.Config.Import = [];
%         these are default settings for the preprocess step
        ETT.Config.PreProcess = [1 80 500 15 2];
        ETT.Config.FixDetect = [];
        ETT.Config.AdditionalAnalyses = [];
        ETT.Subjects = [];
%         default screen properties
        ETT.ScreenDim.Width = 508;
        ETT.ScreenDim.Height = 287.75;
        ETT.ScreenDim.PixX = 1920;
        ETT.ScreenDim.PixY = 1080;
        ETT.ScreenDim.StimX = [0 1920];
        ETT.ScreenDim.StimY = [0 1080];
%         send this ETT to the saving function. get out whether it
%         succeeded or failed
        [ETT,SaveStatus] = ett_SaveProject(ETT,2);
        
        if SaveStatus
%           if is saved successfully close the figure
            Status = 1;
            close(gcf)
        else
%           if it failed for some reason, make a button that tells the user
%           it failed which closes the figure when clicked
            Status = 0;
            delete(obj)
            uicontrol('Style','Pushbutton','String','Unable to Save File (Click to return)','pos',[30 25 340 35],'BackgroundColor',[.8 .8 .8],...
                'ForeGroundColor',[1 0 0],'Callback','close(gcf); clear ETT','FontSize',12);
        end
    end

%   dont execute any other commands until this figure is closed
waitfor(NewProjectFig)

end

