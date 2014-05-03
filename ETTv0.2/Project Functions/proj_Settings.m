function [ETT] = proj_Settings(ETT)
% 
% proj_Settings
% Configure options such as screen size, population <Infant/Adult>, (more to
% come as needed)
% 
% INPUTS:
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 04/29/14:    v1 - Creation 

%%

SettingFig = figure('Name', 'Project Settings', 'pos', [40 580 400 320], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uipanel('Title', 'Screen Size', 'Units', 'Pixels', 'Position', [20 237.5 360 70], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style','Edit','Position',[25 252.5 77.5 30],'Parent',SettingFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',12,'String','X-Pixels:');
xval = uicontrol('Style','Edit','Position',[112.5 252.5 77.5 30],'Parent',SettingFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String','1920','Max',1);
uicontrol('Style','Edit','Position',[200 252.5 77.5 30],'Parent',SettingFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',12,'String','Y-Pixels:');
yval = uicontrol('Style','Edit','Position',[287.5 252.5 77.5 30],'Parent',SettingFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String','1080','Max',1);

uipanel('Title', 'Subject Population', 'Units', 'Pixels', 'Position', [20 162.5 360 70], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Population = uicontrol('Style','PopupMenu','Position',[30 175 340 30],'Parent',SettingFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',['Infants';'Adults ';'Both   '],'Max',1);

uipanel('Title','Default Directory','Units','Pixels','Position',[20 87.5 360 70], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style','PushButton','Position',[30 100 340 30],'Parent',SettingFig,'BackgroundColor',[.8 .8 .8],...
    'FontSize',12,'String','Change Default Directory','Callback',@defaultdir);

uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 20 360 50], 'ForegroundColor', [.1 .1 .1],...
    'FontSize',12,'BackgroundColor',[.8 .8 .8],'Callback',@addsettings)

    function addsettings(~,~)
        ETT.ScreenResX = str2double(get(xval,'String'));
        ETT.ScreenResY = str2double(get(yval,'String'));
        pop = get(Population,'String'); pop = pop(get(Population,'Value'),:);
        ETT.SubjectPopulation  = pop;
        close(SettingFig)
    end

    function defaultdir(~,~)
        ETT.DefaultDirectory = uigetdir(ETT.PathName,'Select a Default Directory');
    end

waitfor(SettingFig)
end
