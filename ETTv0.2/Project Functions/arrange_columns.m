function [arranged_columns,remove_cust] = arrange_columns(colheadings,existingcolumns,hascustom)
% arrange_columns
%
% arrange_columns
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
%   [SH] - 04/30/14:    v1 - Creation

%%
trial_col = 0; phase_col = 0;
edited_cols = colheadings;

text_trial = 'Trial Counter';
text_phase = 'Phase Indicator';
col_trial = [0 0 0]; col_phase = [0 0 0];
init_done = 'Off';

init_cust = 'Off';
remove_cust = 0;
if hascustom
    init_cust = 'On';
end

arranged_columns = [colheadings;repmat({0},1,length(colheadings))];
if ~isempty(existingcolumns) && ~all(cat(2,existingcolumns{2,:})==0)
    text_trial = existingcolumns(1,cat(2,existingcolumns{2,:})==1);    
    phase_trial = existingcolumns(1,cat(2,existingcolumns{2,:})==2);
    col_trial = [.25 .7 .25];    col_phase = [.25 .7 .25];    
    edited_cols = existingcolumns(1,cat(2,existingcolumns{2,:})==0);    
    init_done = 'on'; phase_col = 1; trial_col = 1;
    arranged_columns = existingcolumns;
end



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
ClearCustom = uicontrol('Style','Pushbutton','Position',[245 152.5 125 30], 'String','Clear Custom','FontSize',12,'BackgroundColor',[.8 .8 .8],...
    'Callback',@clear_cust,'ForeGroundColor',[0 0 0],'Enable',init_cust);

Done = uicontrol('Style','Pushbutton','Position',[245 30 125 30], 'String','Finished','FontSize',12,'BackgroundColor',[.8 .8 .8],...
    'Callback',@arrangedone,'Enable',init_done);

    function trial(~,~)
        if trial_col == 0;
            trial_col = 1;
            selected = get(Headingslist,'Value');
            selected_text = edited_cols{selected};
            set(Trial,'String',edited_cols{selected},'ForegroundColor',[.25 .7 .25]);
            edited_cols(selected) = []; edited_cols = cat(2,edited_cols,{''});
            set(Headingslist,'String',edited_cols)
            arranged_columns(2,strcmp(selected_text,colheadings)) = {1};
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

    function clear_cust(~,~)
        remove_cust = 1;
        set(ClearCustom, 'enable','off');
    end

    function arrangedone(~,~)
        close(ColConfigFig)        
    end


waitfor(ColConfigFig)

end