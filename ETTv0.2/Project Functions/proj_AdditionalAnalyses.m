function [ETT] = proj_AdditionalAnalyses(ETT)
% 
% proj_AdditionalAnalyses
% Manage which subjects and additinal analyses to run in additional
% analyses besides those included by default.
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
ana_enable = 'On'; init_aalistenable = 'On';
init_style = 'Listbox'; 

if ~isfield(ETT, 'Subjects') || ETT.nSubjects == 0
    sub_text = '--No Subjects Found -- Please add subjects using ''Manage Subjects'' first.';
    init_style = 'Text';
    init_aalistenable = 'Off';
else
    sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
    if ~isempty(ETT.Subjects(1).Config.AdditionalAnalyses)
        ana_enable = 'on';
        
    end
end

text_aalist =  {''};
if isempty(ETT.Config.AdditionalAnalyses)
    ETT.Config.AdditionalAnalyses = cell(2,0);
    ana_enable = 'off';
else
    text_aalist = cat(1,arrayfun(@(X) ETT.Config.AdditionalAnalyses{2,X}, 1:size(ETT.Config.AdditionalAnalyses,2),'uni',0));
end

AdditionalFig = figure('Name', 'Select Subjects for Additional Analyses', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
    'color', [.65 .75 .65]);

uipanel('Title', 'Attached Subjects', 'Units', 'Pixels', 'Position', [20 70 200 250], 'Backgroundcolor', [.7 .8 .7], 'FontSize', 12, 'Foregroundcolor', [.1 .1 .1]);
Subslist = uicontrol('Style',init_style,'Position',[25 75 190 220],'Parent',AdditionalFig,'Backgroundcolor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',12,'String',sub_text,'Max',length(sub_text));

uipanel('Title', 'Options', 'Units', 'Pixels', 'Position', [230 70 150 250], 'Backgroundcolor', [.7 .8 .7], 'FontSize', 12, 'Foregroundcolor', [.1 .1 .1]);

AnaButton = uicontrol('Style', 'Pushbutton', 'String', 'Analyze', 'Position', [240 248.75 130 46.25],'FontSize', 12,...
    'Backgroundcolor',[.8 .8 .8],'Callback',@sub_Additional,'Enable',ana_enable);
Analist = uicontrol('Style','Listbox', 'String',text_aalist, 'Position', [240 120 130 118.75],'FontSize',8,'Value',[],'Max',2,'Min',0);

uicontrol('Style', 'Pushbutton', 'String', 'Add', 'Position', [240 80 60 30],'FontSize', 10,...
    'Backgroundcolor',[.8 .8 .8],'Callback',@add_aa,'Enable','On');
Rem_Button = uicontrol('Style', 'Pushbutton', 'String', 'Remove', 'Position', [310 80 60 30],'FontSize', 10,...
    'Backgroundcolor',[.8 .8 .8],'Callback',@remove_aa,'Enable',ana_enable);

uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 46.25], 'Foregroundcolor', [.1 .1 .1],...
    'Backgroundcolor',[.8 .8 .8],'FontSize',12,'Callback',@doneall)


    function sub_Additional(~,~)
        selected = get(Subslist,'Value');
        [ETT] = proj_batch(ETT,selected,3);
        figure(AdditionalFig)
    end

    function add_aa(~,~)
        [newanafile, newanapath] = uigetfile(...
            {'*.m;', 'Matlab Scripts and Functions (*.m)'},...
            'Analyses Script or Function');
        ETT.Config.AdditionalAnalyses(:,end+1) = ...
            [{newanapath};{newanafile}];
        text_aalist = cat(1,arrayfun(@(X) ETT.Config.AdditionalAnalyses{2,X}, 1:size(ETT.Config.AdditionalAnalyses,2),'uni',0));
        set(Analist,'String',text_aalist);
        set(Rem_Button,'Enable','On')
        set(AnaButton,'Enable','On')
    end

    function remove_aa(~,~)
        selected = get(Analist,'Value');
        ETT.Config.AdditionalAnalyses(:,selected) = [];
        text_aalist = '';
        set(Rem_Button,'Enable','Off')
        set(AnaButton,'Enable','Off')
        if ~isempty(ETT.Config.AdditionalAnalyses)
            text_aalist = cat(1,arrayfun(@(X) ETT.Config.AdditionalAnalyses{2,X}, 1:size(ETT.Config.AdditionalAnalyses,2),'uni',0));
            set(Rem_Button,'Enable','On')
            set(AnaButton,'Enable','On')
            set(Analist,'Value',[])
        end
        set(Analist,'String',text_aalist);
    end

    function doneall(~,~)
        close(AdditionalFig)
    end

waitfor(AdditionalFig)
end
