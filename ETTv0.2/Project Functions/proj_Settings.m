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
SettingFig = figure('Name', 'Project Settings', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uipanel('Title', 'Screen Size', 'Units', 'Pixels', 'Position', [20 237.5 360 70], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style','PushButton','Position',[30 250 340 30],'Parent',SettingFig,'BackgroundColor',[.8 .8 .8],...
    'FontSize',12,'String','Configure Screen Properties','Callback',@configscreen);

uipanel('Title', 'Subject Population', 'Units', 'Pixels', 'Position', [20 162.5 360 70], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Population = uicontrol('Style','PopupMenu','Position',[30 175 340 30],'Parent',SettingFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',['Infants';'Adults ';'Both   '],'Max',1);

uipanel('Title','Default Directory','Units','Pixels','Position',[20 87.5 360 70], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style','PushButton','Position',[30 100 340 30],'Parent',SettingFig,'BackgroundColor',[.8 .8 .8],...
    'FontSize',12,'String','Change Default Directory','Callback',@defaultdir);

uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 20 360 50], 'ForegroundColor', [.1 .1 .1],...
    'FontSize',12,'BackgroundColor',[.8 .8 .8],'Callback',@addsettings)

    function configscreen(~,~)
        ETT = sett_ScreenDims(ETT);
    end

    function addsettings(~,~)        
        pop = get(Population,'String'); pop = pop(get(Population,'Value'),:);
        ETT.SubjectPopulation  = pop;
        close(SettingFig)
    end

    function defaultdir(~,~)
        ETT.DefaultDirectory = strcat(uigetdir(ETT.PathName,'Select a Default Directory'),filesep);
    end

waitfor(SettingFig)
end
