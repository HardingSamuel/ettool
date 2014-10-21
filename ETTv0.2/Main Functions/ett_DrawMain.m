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

text_box = [{'Project Name:  '};{'Creation Date:  '};{'Attached Subjects:  '};{'Import Settings:  '};{'PreProcess Settings:  '}];
if isempty(ETT)
    col_box = [.6 .6 .6];
else
    col_box = [0 0 0];
    cust_anyimp = any(cell2mat(arrayfun(@(X) ~isempty(ETT.Subjects(X).Config.Import),1:length(ETT.Subjects),'uni',0)));
    text_Icust = '';
    if cust_anyimp
        text_Icust = '[C] ';
    end
    stat_colload = ~isempty(ETT.Config.Import); text_col = 'Not Loaded';    
    if stat_colload
        text_col = 'Loaded';
    end
    cust_anyproc = any(cell2mat(arrayfun(@(X) ~isempty(ETT.Subjects(X).Config.PreProcess),1:length(ETT.Subjects),'uni',0)));
    text_Pcust = '';
    if cust_anyproc
        text_Pcust = '[C] ';
    end
    text_pre = 'Default'; stat_preproc = 1;
    if ~isempty(ETT.Config.PreProcess)
        stat_preproc = all(ETT.Config.PreProcess == [1 80 500 15 2]);
    end    
    if ~stat_preproc
        text_pre = 'User Defined';
    end
    text_pre = [text_Pcust, text_pre];    
    text_col = [text_Icust, text_col];
    
    text_box = cat(2,text_box,[{ETT.ProjectName};{ETT.CreationDate};{num2str(ETT.nSubjects)};{text_col};{text_pre}]);    
    text_box = arrayfun(@(X) strjoin(text_box(X,:)),1:size(text_box,1),'uni',0);
end

TitlePanel = uipanel('Title', 'ETTool v0.2', 'Position', [.05 .05 .9 .9], 'BackgroundColor', [.7 .8 .7],...
    'FontSize', 16, 'ForegroundColor', col_box);
LeftText = uicontrol('Style','Text','BackgroundColor',[.7 .8 .7],'FontSize',14,'Position',[25 25 340 250],'HorizontalAlignment','Left',...
    'String',text_box,'ForeGroundColor',col_box);
end