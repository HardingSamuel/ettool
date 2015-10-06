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
% pull up the figure by the handle provided as input. makes sure we edit
% the existing figure and not something else the user might have had open
figure(ETTFig)

% text labels for the left side of the box
text_box = [{'Project Name:  '};{'Creation Date:  '};{'Attached Subjects:  '};{'Import Settings:  '};{'PreProcess Settings:  '}];
if isempty(ETT)
%   if we have not loaded an .etp file yet, make the font color gray
    col_box = [.6 .6 .6];
else
%   if we have loaded one, then
    col_box = [0 0 0]; %text black
    
%     determine if, for any subject, we defined custom import settings or
%     if we will be importing all of the subjects with the same column
%     definitions (trial and phase indicators). cut_anyimp is binary
    cust_anyimp = any(cell2mat(arrayfun(@(X) ~isempty(ETT.Subjects(X).Config.Import),1:length(ETT.Subjects),'uni',0)));
%     initialize some blank text
    text_Icust = '';
    if cust_anyimp
%       if we have used any custom column settings for import, add a [c] to
%       the window so we know.
        text_Icust = '[C] ';
    end
% stat_colload is 0,1 to say whether we've defined import columns or not.
% initialize text by default that says we haven't
    stat_colload = ~isempty(ETT.Config.Import); text_col = 'Not Loaded';    
    if stat_colload
%       if we have defined these settings, then change the text to tell us
%       so
        text_col = 'Loaded';
    end
%     cust_anyproc. similar to the above -- did we use any custom import
%     settings
    cust_anyproc = any(cell2mat(arrayfun(@(X) ~isempty(ETT.Subjects(X).Config.PreProcess),1:length(ETT.Subjects),'uni',0)));
    text_Pcust = '';
    if cust_anyproc
%       if so add a C to tell us
        text_Pcust = '[C] ';
    end
%     by default, assume that we haven't changed the default import
%     settings
    text_pre = 'Default'; stat_preproc = 1;
    if ~isempty(ETT.Config.PreProcess)
%       check pairwise that our current preprocessing settings are exactly
%       equal to the default. if they all are, then tell us so.
        stat_preproc = all(ETT.Config.PreProcess == [1 80 500 15 2]);
    end    
    if ~stat_preproc
%       if not, then inform us that we have user-defined import settings
        text_pre = 'User Defined';
    end
%     append the default texts with their additional [C] strings or empty
%     strings, based on the above decisions
    text_pre = [text_Pcust, text_pre];    
    text_col = [text_Icust, text_col];
    
%     concatenate the matrices containing the labels with the values found
%     in ETT
    text_box = cat(2,text_box,[{ETT.ProjectName};{ETT.CreationDate};{num2str(ETT.nSubjects)};{text_col};{text_pre}]);    
%     different versions of ML handle concatenating strings differently.
%     This is one of the most problematic lines of code in general. We
%     found that two different versions of this concatenation would work,
%     but it was seemingly random depending on ML versions (though I'm sure
%     there is structure). The quick and dirty workaround that we
%     eventually used was to try one version and if that didn't work, use a
%     not so pretty-looking version. There is a simple loop that would make
%     this pretty stable, but I kept trying single commands.
    try; text_box = arrayfun(@(X) strjoin(' ',text_box(X,:)),1:size(text_box,1),'uni',0); catch
        text_box = strcat(text_box(:,1),text_box(:,2)); end
end

% add some graphics to the figure, first the panel with some text and
% different colors, then the text we just made above.
TitlePanel = uipanel('Title', 'ETTool v0.2', 'Position', [.05 .05 .9 .9], 'BackgroundColor', [.7 .8 .7],...
    'FontSize', 16, 'ForegroundColor', col_box);
LeftText = uicontrol('Style','Text','BackgroundColor',[.7 .8 .7],'FontSize',14,'Position',[25 25 340 250],'HorizontalAlignment','Left',...
    'String',text_box,'ForeGroundColor',col_box);
end