function [arranged_columns,remove_cust] = sett_Import(colheadings,existingcolumns,hascustom)
% sett_Import
%
% sett_Import
% Sort user-defined custom column headings based on function for later use in organizing the
% data during import, preprocessing, etc...
%
% INPUTS:
% colheadings - names of the columns, read in from the subject's data file
%
% OUTPUTS:
% arranged_columns - columns with numerical identification
%
%% Change Log
%   [SH] - 04/30/14:   v1 - Creation
%   [SH] - 09/12/14:   Fixed bug in which empty columns were included at
%   the end of the list with empty 1 or 2 character names. 

%%
% set up some default values
trial_col = 0; phase_col = 0; ignore_col = 0;
edited_cols = colheadings;
% some UI text
text_trial = 'Trial Counter';
text_phase = 'Phase Indicator';
text_ignore = 'Ignore';
col_trial = [0 0 0]; col_phase = [0 0 0]; col_ignore = [0 0 0];
init_done = 'Off';

% if the user wants to specify import setting for this, and only this
% subject
init_cust = 'Off';
remove_cust = 0;
if hascustom
    init_cust = 'On';
end

% arrange the incoming columns on top of some zeros by default, to indicate
% that we don't want to use these columns. users will define important
% columns later and these 0s will change. this stores the column names and
% their classifications for displaying and importing down the line
arranged_columns = [colheadings;repmat({0},1,length(colheadings))];
% if we received from existing columns, and they appear to have been
% classified, update the "arranged_columns" to reflect the existing
% settings
if ~isempty(existingcolumns) && ~all(cat(2,existingcolumns{2,:})==0)
    text_trial = existingcolumns(1,cat(2,existingcolumns{2,:})==1);
    phase_trial = existingcolumns(1,cat(2,existingcolumns{2,:})==2);
    if length(find(cat(2,existingcolumns{2,:})==1))==1
        col_trial = [.25 .7 .25];
    end
    if length(find(cat(2,existingcolumns{2,:})==2))==1
        col_phase = [.25 .7 .25];
    end
    if length(find(cat(2,existingcolumns{2,:})==-1))==1
        col_ignore = [.25 .7 .25];
    end
    edited_cols = existingcolumns(1,cat(2,existingcolumns{2,:})==0);
    init_done = 'on'; phase_col = 1; trial_col = 1;
    arranged_columns = existingcolumns;
    
    
    if ~isempty(find(cat(2,existingcolumns{2,:})==-1))
        ignore_col = 1;
        text_ignore = existingcolumns{1,find(cat(2,existingcolumns{2,:})==-1)};
    end
    
end
% some interface stuff
ColConfigFig = figure('Name', 'Arrange Columns', 'Unit', 'Pixels', 'Position', [460 600 400 300], 'NumberTitle','Off','MenuBar','None',...
    'Color', [.65 .75 .65]);
uipanel('Title', 'Headings', 'Units', 'Pixels', 'Position', [20 20 195 270], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Headingslist = uicontrol('Style','Listbox','Position',[25 25 185 240],'Parent',ColConfigFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',edited_cols,'Max',1);

uipanel('Title', 'Functions', 'Units', 'Pixels', 'Position', [235 20 145 270], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Trial = uicontrol('Style','Pushbutton','Position',[245 232.5 125 30], 'String',text_trial,'FontSize',12,'BackgroundColor',[.8 .8 .8],...
    'Callback',@trial,'ForeGroundColor',col_trial);
Phase = uicontrol('Style','Pushbutton','Position',[245 192.5 125 30], 'String',text_phase,'FontSize',12,'BackgroundColor',[.8 .8 .8],...
    'Callback',@phase,'ForeGroundColor',col_phase);
Ignore = uicontrol('Style','Pushbutton','Position',[245 152.5 125 30], 'String',text_ignore,'FontSize',12,'BackgroundColor',[.8 .8 .8],...
    'Callback',@ignore,'ForeGroundColor',col_ignore);

ClearCustom = uicontrol('Style','Pushbutton','Position',[245 70 125 30], 'String','Clear Custom','FontSize',12,'BackgroundColor',[.8 .8 .8],...
    'Callback',@clear_cust,'ForeGroundColor',[0 0 0],'Enable',init_cust);
Done = uicontrol('Style','Pushbutton','Position',[245 30 125 30], 'String','Finished','FontSize',12,'BackgroundColor',[.8 .8 .8],...
    'Callback',@arrangedone,'Enable',init_done);

%   define a function to figure out which column in the data file will
%   contain a marker to delineate each trial. this fcn is triggered when
%   user presses the interface button labeled ("Trial Counter"). this swaps
%   the text to instead have the column name
    function trial(~,~)
%       if we don't have one yet
        if trial_col == 0;
            trial_col = 1;
            selected = get(Headingslist,'Value');
            selected_text = edited_cols{selected};
            set(Trial,'String',edited_cols{selected},'ForegroundColor',[.25 .7 .25]);
            edited_cols(selected) = []; edited_cols = cat(2,edited_cols,{''});
            set(Headingslist,'String',edited_cols)
            arranged_columns(2,strcmp(selected_text,colheadings)) = {1};
%       if we had previously classified a column, and we clicked this
%       button again, put the existing column title back into the main list
%       of titles, mark inside of "arranged_columns" that we DO NOT have a
%       trial column specified, and then but "Trial Counter" back into the
%       text of the button
        else
            trial_col = 0;
            text_revert = get(Trial,'String');
            if size(text_revert,1)>1
                text_revert = text_revert(1,:);
            end
            set(Trial,'String','Trial Counter','ForegroundColor',[0 0 0])
            edited_cols(strcmp(edited_cols,'')) = [];
            edited_cols = cat(2,edited_cols,text_revert);
            set(Headingslist,'String',edited_cols)
            arranged_columns(2,cat(2,arranged_columns{2,:})==1) = {0};
        end
        
        if phase_col && trial_col
            set(Done,'Enable','On')
        else
            set(Done,'Enable','Off')
        end
    end

%   same general principle as the trial button. If we haven't specified a
%   column to perform this role, then put whichever highlighted column name
%   into the button and store it in arranged_cols. If we have set one up
%   previously, take it out and reset the button
    function phase(~,~)
        if phase_col == 0;
            phase_col = 1;
            selected = get(Headingslist,'Value');
            selected_text = edited_cols{selected};
            set(Phase,'String',edited_cols{selected},'ForegroundColor',[.25 .7 .25]);
            edited_cols(selected) = []; edited_cols = cat(2,edited_cols,{''});
            set(Headingslist,'String',edited_cols)
            arranged_columns(2,strcmp(selected_text,colheadings)) = {2};
        else
            phase_col = 0;
            text_revert = get(Phase,'String');
            if size(text_revert,1)>1
                text_revert = text_revert(1,:);
            end
            set(Phase,'String','Phase Indicator','ForegroundColor',[0 0 0])
            edited_cols(strcmp(edited_cols,'')) = [];
            edited_cols = cat(2,edited_cols,text_revert);
            set(Headingslist,'String',edited_cols)
            arranged_columns(2,cat(2,arranged_columns{2,:})==2) = {0};
        end
        
        if phase_col && trial_col
            set(Done,'Enable','On')
        else
            set(Done,'Enable','Off')
        end
    end

%   sometimes there is a column that is being finicky for some reason or
%   another. I think we solved the majority of these, but in case one
%   column in being problematic, allow the user to skip it during the
%   import process
    function ignore(~,~)
        if ignore_col == 0;
            ignore_col = 1;
            selected = get(Headingslist,'Value');
            selected_text = edited_cols{selected};
            set(Ignore,'String',edited_cols{selected},'ForegroundColor',[.25 .7 .25]);
            edited_cols(selected) = []; edited_cols = cat(2,edited_cols,{''});
            set(Headingslist,'String',edited_cols)
            arranged_columns(2,strcmp(selected_text,colheadings)) = {-1};
        else
            ignore_col = 0;
            text_revert = get(Ignore,'String');
            if size(text_revert,1)>1
                text_revert = text_revert(1,:);
            end
            set(Ignore,'String','Ignore','ForegroundColor',[0 0 0])
            edited_cols(strcmp(edited_cols,'')) = [];
            edited_cols = cat(2,edited_cols,text_revert);
            set(Headingslist,'String',edited_cols)
            arranged_columns(2,cat(2,arranged_columns{2,:})==-1) = {0};
        end
        
        if ignore_col && trial_col
            set(Done,'Enable','On')
        else
            set(Done,'Enable','Off')
        end
    end

%   if we had set up custom import settings for this subject, remove them.
%   May not be 100% functional, haven't test it in a while
    function clear_cust(~,~)
        remove_cust = 1;
        set(ClearCustom, 'enable','off');
        set(Done,'Enable','On');
    end

%   we've finished specifying which columns do what, so go ahead and return
%   that information to the caller
    function arrangedone(~,~)
        arranged_columns(:,find(sum(cellfun(@isempty, arranged_columns),1))) = [];
        for colcheck = 1:size(arranged_columns,2)
            arranged_columns{1,colcheck} = strread(arranged_columns{1,colcheck},'%c')';
        end
        close(ColConfigFig)
    end

% hold this figure open until they click the finished button or exit out
waitfor(ColConfigFig)

end