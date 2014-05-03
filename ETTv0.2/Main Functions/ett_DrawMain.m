function [] = ett_DrawMain(ETT,ETTFig)
%
% ett_DrawMain
% Redraws the main window with updated information, useful after running
% any type of process that affects the ETT structure.  This provides useful
% information in the main window for the user.
%
% INPUTS:
% ETT
%
% OUTPUTS:
%
%
%% Change Log
%   [SH] - 05/02/14:    v1 - Creation

%%
figure(ETTFig)

text_box = [{'Project Name:  '};{'Creation Date:  '};{'Attached Subjects:  '};{'Import Settings:  '}];
if isempty(ETT)
    col_box = [.6 .6 .6];
else
    col_box = [0 0 0];
    stat_colload = ~isempty(ETT.ImportColumns); text_col = 'Not Loaded';
    if stat_colload
        text_col = 'Loaded';
    end
    text_box = cat(2,text_box,[{ETT.ProjectName};{ETT.CreationDate};{num2str(ETT.nSubjects)};{text_col}]);    
end
text_box = arrayfun(@(X) strjoin(text_box(X,:)),1:size(text_box,1),'uni',0);
TitlePanel = uipanel('Title', 'ETTool v0.2', 'Position', [.05 .05 .9 .9], 'BackgroundColor', [.7 .8 .7],...
    'FontSize', 16, 'ForegroundColor', col_box);
LeftText = uicontrol('Style','Text','BackgroundColor',[.7 .8 .7],'FontSize',14,'Position',[25 25 340 320],'HorizontalAlignment','Left',...
    'String',text_box,'ForeGroundColor',col_box);
end