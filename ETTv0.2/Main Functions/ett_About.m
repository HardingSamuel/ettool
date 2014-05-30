function ett_About
% 
% ett_About
% 
% 
% INPUTS:
% 
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 05/30/14:    v1 - Creation 

%%

AboutStr = 'ETTool v0.2: Developed by Sam Harding, Indiana University in collaboration with the Developmental Cognitive Neuroscience Lab under direction of Dr. Bennett I. Bertenthal.';

InfoFig = figure('Name', 'About ETT v0.2', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'Color', [.65 .75 .65]);

uicontrol('Style','Text','Position',[20 20 360 290],'String',AboutStr,'BackgroundColor',[.7 .8 .7],'FontSize',12)

end