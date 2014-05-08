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
    [ETT,SaveStatus] = ett_SaveProject(ETT,2);
    ETT.DefaultDirectory = ETT.PathName;
    ETT.Config.Import = [];
    ETT.Config.PreProcess = [];
    ETT.Config.FixDetect = [];
    ETT.Subjects = [];
    
    if SaveStatus
        Status = 1;
        close(gcf)
    else
        Status = 0; 
        delete(obj)
        uicontrol('Style','Pushbutton','String','Unable to Save File (Click to return)','pos',[30 25 340 35],'BackgroundColor',[1 1 1],...
            'ForeGroundColor',[1 0 0],'Callback','close(gcf); clear ETT','FontSize',12);
    end
end

waitfor(NewProjectFig)

end

