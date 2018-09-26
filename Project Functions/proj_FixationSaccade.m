function [ETT] = proj_FixationSaccade(ETT)
%
% proj_FixationSaccade
% Automatic and manual fixation detection through visualization
%
% INPUTS:
% ETT
%
% OUTPUTS:
% ETT
%
%% Change Log
%   [SH] - 05/08/14:   v1 - Creation
%   [SH] - 06/25/14:   v1.1 - Renamed variables for consistency, check
%   project at beginning to ensure existence of required fields.

%%

[ETT] = proj_CheckUpdate(ETT);

init_enable = 'On'; fix_enable = 'On';
init_style = 'Listbox'; fix_subbut = [0 0 0];

if ~isfield(ETT, 'Subjects') || ETT.nSubjects == 0
  sub_text = '--No Subjects Found -- Please add subjects using ''Manage Subjects'' first.';
  init_enable = 'off';
  init_style = 'Text';
elseif all(strcmp(cat(1,arrayfun(@(X) ETT.Subjects(X).Status.PreProcess, 1:length(ETT.Subjects),'uni',0)),'Not Processed'))
  sub_text = '-- No Subjects PreProcessed -- Please PreProcess subjects using ''PreProcess Data'' first';
  init_enable = 'off';
  init_style = 'Text';
else
  sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
  if ~isempty(ETT.Subjects(1).Config.FixDetect)
    fix_enable = 'on';
    fix_subbut = [.25 .7 .25];
  end
end

fix_projsett = [.25 .7 .25];

if isempty(ETT.Config.FixDetect)
  fix_enable = 'off';
  fix_projsett = [0 0 0];
end

FixationFig = figure('Name', 'Select Subjects to FixDetect', 'pos', [40 570 400 330], 'NumberTitle', 'Off', 'MenuBar', 'None',...
  'Color', [.65 .75 .65]);

uipanel('Title', 'Attached Subjects', 'Units', 'Pixels', 'Position', [20 70 200 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Subslist = uicontrol('Style',init_style,'Position',[25 75 190 220],'Parent',FixationFig,'BackgroundColor',[1 1 1],...
  'HorizontalAlignment','Center','FontSize',12,'String',sub_text,'Max',length(sub_text),'Callback',@updatecolors);

uipanel('Title', 'Options', 'Units', 'Pixels', 'Position', [230 70 150 250], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

FixDetButton = uicontrol('Style', 'Pushbutton', 'String', 'FixDetect', 'Position', [240 248.75 130 46.25],'FontSize', 12,...
  'BackgroundColor',[.8 .8 .8],'Callback',@sub_Fixation,'Enable',fix_enable);
SetProjBut = uicontrol('Style', 'Pushbutton', 'String', 'Settings (Project)', 'Position', [240 192.5 130 46.25],'FontSize', 10,...
  'BackgroundColor',[.8 .8 .8],'Callback',{@fixdet_manage,0},'ForeGroundColor',[0 0 0],'Enable',init_enable,...
  'ForegroundColor',fix_projsett);
SetSubBut = uicontrol('Style', 'Pushbutton', 'String', 'Settings (Selected)', 'Position', [240 136.25 130 46.25],'FontSize', 10,...
  'BackgroundColor',[.8 .8 .8],'Callback',{@fixdet_manage,1},'ForeGroundColor',[0 0 0],'Enable',init_enable,...
  'ForegroundColor',fix_subbut);

uicontrol('Style', 'Pushbutton', 'String', 'Details/Edit', 'Position', [240 80 130 46.25],'FontSize', 12,...
  'BackgroundColor',[.8 .8 .8],'Callback',{@fix_detail,1},'Enable',init_enable);
uicontrol('Style', 'PushButton', 'String', 'Finished', 'Position', [20 10 360 46.25], 'ForegroundColor', [.1 .1 .1],...
  'BackgroundColor',[.8 .8 .8],'FontSize',12,'Callback',@doneall)


  function sub_Fixation(~,~)
    selected = get(Subslist,'Value');
    [ETT] = vis_FixationSaccade(ETT,selected);
    figure(FixationFig)
  end

  function fix_detail(~,~,mode)
    selected = get(Subslist,'Value');
    [ETT] = sub_details(ETT,selected,mode);
    sub_text = cat(1,arrayfun(@(X) ETT.Subjects(X).Name, 1:length(ETT.Subjects),'uni',0));
    set(Subslist,'String',sub_text)
  end

  function fixdet_manage(~,~,mode)
    selected = get(Subslist,'Value');
    Settings = ETT.Config.FixDetect;
    if mode
      Settings = ETT.Subjects(selected).Config.FixDetect;
    end
    NewSettings = Settings;
    % so if you quit early it doesn't error.
    [NewSettings] = sett_FixDetect(ETT,0,Settings);
    if mode
      if ~isempty(NewSettings)
        if all(arrayfun(@(set) NewSettings{set}==ETT.Config.FixDetect{set},[1,2,4,5])) && all(all(NewSettings{3} == ETT.Config.FixDetect{3}));
          NewSettings = [];
        end
      end
      ETT.Subjects(selected).Config.FixDetect = NewSettings;
    else
      ETT.Config.FixDetect = NewSettings;
    end
    if ~isempty(NewSettings)
      set(FixDetButton,'Enable','On')
    end
    @updatecolors;
  end

  function updatecolors(~,~)
    selected = get(Subslist,'Value');
    anycustoms = cell2mat(arrayfun(@(X) ~isempty(ETT.Subjects(X).Config.FixDetect),selected,'uni',0));
    if any(anycustoms)
      set(FixDetButton,'Enable','On')
      set(SetSubBut,'ForeGroundColor',[.25 .7 .25]);
    else
      set(SetSubBut,'ForeGroundColor',[0 0 0]);
    end
    if ~isempty(ETT.Config.FixDetect)
      set(FixDetButton,'Enable','On')
      set(SetProjBut,'ForegroundColor',[.25 .7 .25]);
    else
      set(FixDetButton,'Enable','Off')
      set(SetProjBut,'ForegroundColor',[0 0 0]);
    end
  end

  function doneall(~,~)
    close(FixationFig)
  end

waitfor(FixationFig)
end