function ETT = proj_Info(ETT)

% proj_Info
% Allows user to edit and save detailed project information, comments,
% etc...
%
% INPUTS:
%
% OUTPUTS:
% ETT - structure containing the data with the additional comment
%
%% Change Log
%   [SH] - 04/29/14:   v1 - Creation

%%
InfoSize = [40 500 400 400];

if ~isfield(ETT, 'ProjectTitle')
    ETT.ProjectTitle = '';
    ETT.ProjectDescription = '';
end

title_text = ETT.ProjectName;
desc_text = ETT.ProjectDescription;

InfoFig = figure('Name', 'Project Information', 'pos', InfoSize, 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uipanel('Title', 'Project Name', 'Units', 'Pixels', 'Position', [20 310 360 70], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Title = uicontrol('Style','Edit','Position',[30 320 340 35],'Parent',InfoFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',title_text);

uipanel('Title', 'Project Description', 'Units', 'Pixels', 'Position', [20 70 360 230], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Description = uicontrol('Style','Edit','Position',[30 80 340 195],'Parent',InfoFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',desc_text,'Max',10,'Min',1);

uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 50], 'ForegroundColor', [.1 .1 .1],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Callback',@addinfo)


    function addinfo(~,~)
        ETT.ProjectName = get(Title, 'String');
        ETT.ProjectDescription = get(Description,'String');
        close(InfoFig)
    end

waitfor(InfoFig)

end