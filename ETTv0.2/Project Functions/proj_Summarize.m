function [ETT] = proj_Summarize(ETT)
% 
% proj_Summarize
% Create and execute summarization routines such as averaging, plotting,
% and statistics.
% 
% INPUTS:
% ETT - project data
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 05/19/14:    v1 - Creation 

%%
summ_enable = 'On'; init_summlistenable = 'On';
init_style = 'Listbox'; 

if ~isfield(ETT, 'Subjects') || ETT.nSubjects == 0
    sub_text = '--No Subjects Found -- Please add subjects using ''Manage Subjects'' first.';
    init_style = 'Text';
    init_summlistenable = 'Off';
else
    sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
    if ~isempty(ETT.Subjects(1).Config.Summarize)
        summ_enable = 'on';        
    end
end

text_summlist =  {''};
if isempty(ETT.Config.Summarize)
    ETT.Config.Summarize = cell(2,0);
    summ_enable = 'off';
else
    text_summlist = cat(1,arrayfun(@(X) ETT.Config.Summarize{2,X}, 1:size(ETT.Config.Summarize,2),'uni',0));
end

SummarizeFig = figure('Name', 'Select Subjects to Summarize', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'color', [.65 .75 .65]);

uipanel('Title', 'Attached Subjects', 'Units', 'Pixels', 'Position', [20 70 200 250], 'Backgroundcolor', [.7 .8 .7], 'FontSize', 12, 'Foregroundcolor', [.1 .1 .1]);
Subslist = uicontrol('Style',init_style,'Position',[25 75 190 220],'Parent',SummarizeFig,'Backgroundcolor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',sub_text,'Max',length(sub_text));

uipanel('Title', 'Options', 'Units', 'Pixels', 'Position', [230 70 150 250], 'Backgroundcolor', [.7 .8 .7], 'FontSize', 12, 'Foregroundcolor', [.1 .1 .1]);

SummButton = uicontrol('Style', 'Pushbutton', 'String', 'Summarize', 'Position', [240 248.75 130 46.25],'FontSize', 12,...
    'Backgroundcolor',[.8 .8 .8],'Callback',@sub_Summarize,'Enable',summ_enable);
Summlist = uicontrol('Style','Listbox', 'String',text_summlist, 'Position', [240 120 130 118.75],'FontSize',8,'Value',[],'Max',2,'Min',0);

uicontrol('Style', 'Pushbutton', 'String', 'Add', 'Position', [240 80 60 30],'FontSize', 10,...
    'Backgroundcolor',[.8 .8 .8],'Callback',@add_summ,'Enable','On');
Rem_Button = uicontrol('Style', 'Pushbutton', 'String', 'Remove', 'Position', [310 80 60 30],'FontSize', 10,...
    'Backgroundcolor',[.8 .8 .8],'Callback',@remove_summ,'Enable',summ_enable);

uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 46.25], 'Foregroundcolor', [.1 .1 .1],...
    'Backgroundcolor',[.8 .8 .8],'FontSize',12,'Callback',@doneall)


    function sub_Summarize(~,~)
        selected = get(Subslist,'Value');
        [ETT] = proj_batch(ETT,selected,4);
        figure(SummarizeFig)
    end

    function add_summ(~,~)
        [newanafile, newanapath] = uigetfile(...
            {'*.m;', 'Matlab Scripts and Functions (*.m)'},...
            'Analyses Script or Function');
        ETT.Config.Summarize(:,end+1) = ...
            [{newanapath};{newanafile}];
        text_summlist = cat(1,arrayfun(@(X) ETT.Config.Summarize{2,X}, 1:size(ETT.Config.Summarize,2),'uni',0));
        set(Summlist,'String',text_summlist);
        set(Rem_Button,'Enable','On')
        set(SummButton,'Enable','On')
    end

    function remove_summ(~,~)
        selected = get(Summlist,'Value');
        ETT.Config.Summarize(:,selected) = [];
        text_summlist = '';
        set(Rem_Button,'Enable','Off')
        set(SummButton,'Enable','Off')
        if ~isempty(ETT.Config.Summarize)
            text_summlist = cat(1,arrayfun(@(X) ETT.Config.Summarize{2,X}, 1:size(ETT.Config.Summarize,2),'uni',0));
            set(Rem_Button,'Enable','On')
            set(SummButton,'Enable','On')
            set(Summlist,'Value',[])
        end
        set(Summlist,'String',text_summlist);
    end

    function doneall(~,~)
        close(SummarizeFig)
    end

waitfor(SummarizeFig)
end
