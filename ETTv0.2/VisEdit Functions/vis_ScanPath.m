function [] = vis_ScanPath(subdata)
%
% vis_ScanPath
% Visualize scan path including fixation information
%
% INPUTS:
%
%
% OUTPUTS:
%
%
%% Change Log
%   [SH] - 07/01/14:   v1 - Creation
%   [SH] - 11/15/17:   Updated, after long wait


%% LOCAL VARS
G = [];
V = [];
D = [];
LOOP = 1;

%% CHECK DATA
% make sure this subdata has fixations
if ~isfield(subdata,'Fixations')
  %%
  uiwait(msgbox('Error: No fixations in input ''subdata''','Check Fixations','modal'));
  return;
else
  D.nTrials = length(subdata.Fixations);
  D.trialNums = [1:D.nTrials]';
  D.trialString = num2str(D.trialNums);
end

%% GRAPHICS
% figure
G.FIG.H = fig(100,'cf');
G.FIG.H.MenuBar = 'none';
G.FIG.H.Color = [1 1 1];
G.FIG.H.CloseRequestFcn = 'LOOP = 0;';


% interface
% % top menu
% % % trial selection label
G.UI(1).H = uicontrol();
G.UI(1).H.Parent = G.FIG.H;
G.UI(1).H.Style = 'text';
G.UI(1).H.Units = 'normalized';
G.UI(1).H.Position = [.01 .95 .15 .025];
G.UI(1).H.String = 'Trial Number:';
G.UI(1).H.FontSize = 12;
G.UI(1).H.BackgroundColor = [1 1 1];
% % % trial selection
G.UI(2).H = uicontrol();
G.UI(2).H.Parent = G.FIG.H;
G.UI(2).H.Style = 'popupmenu';
G.UI(2).H.String = D.trialString;
G.UI(2).H.Units = 'normalized';
G.UI(2).H.Position = [.01 .895 .15 .05];
G.UI(2).H.Callback = @selectTrial;

% % buttons
% % % play/pause
G.BUT(1).H = uicontrol();
G.BUT(1).H.Parent = G.FIG.H;
G.BUT(1).H.Style = 'pushbutton';
G.BUT(1).H.CData = [];
G.BUT(1).H.Units = 'normalized';
G.BUT(1).H.Position = [.3 .02 .15 .06];
G.BUT(1).H.Callback = @videoPlayPause;
% % % stop
G.BUT(2).H = uicontrol();
G.BUT(2).H.Parent = G.FIG.H;
G.BUT(2).H.Style = 'pushbutton';
G.BUT(2).H.CData = [];
G.BUT(2).H.Units = 'normalized';
G.BUT(2).H.Position = [.55 .02 .15 .06];
G.BUT(2).H.Callback = @videoStop;


% slider
G.SLIDE(1).H = uicontrol();
G.SLIDE(1).H.Parent = G.FIG.H;
G.SLIDE(1).H.Style = 'slider';
G.SLIDE(1).H.Units = 'normalized';
G.SLIDE(1).H.Position = [.025 .1 .95 .025];
G.SLIDE(1).H.Enable = 'off';


% axes
delete(gca)
G.AX.H = gca;
G.AX.H.Units = 'normalized';
G.AX.H.Position = [.01 .15 .98 .75];
% G.AX.H.Visible = 'off';
G.AX.H.NextPlot = 'add';
G.AX.H.UserData.gazePlot = [];
G.AX.H.XLim = [0 1];
G.AX.H.YLim = [0 1];
G.AX.H.XTick = [];
G.AX.H.YTick = [];
G.AX.H.Box = 'on';


% images
G.IMAGES(1).name = 'Play_Button.jpg';
G.IMAGES(1).image = imread(G.IMAGES(1).name);
%
G.IMAGES(2).name = 'Pause_Button.jpg';
G.IMAGES(2).image = imread(G.IMAGES(2).name);
%
G.IMAGES(3).name = 'Stop_Button.jpg';
G.IMAGES(3).image = imread(G.IMAGES(3).name);


%% VIDEO CONTROLS
V = [];
V.isPlaying = 0;
V.Frame = 1;
V.FrameRate = 30;
V.FrameTime = 1/V.FrameRate;


%% SETUP
loadImages

%% MAIN LOOP
V.lastDraw = GetSecs;
while 1
  % stop looping when figure is closed
  if ~ishghandle(G.FIG.H)
    break
  end
  if V.isPlaying
    V.drawNow = shouldDraw;
    if V.drawNow
      V.lastDraw = drawNow;
      V.Frame = V.Frame + 1;
    end
    drawnow
  end
end

%% FUNCTIONS
% Interface
% % set up
  function loadImages
    drawPlayPause
    G.BUT(2).H.CData = G.IMAGES(3).image;
  end
% % selection
  function selectTrial(O,~)
    % get the data from this subject
    D.currentTrial = D.trialNums(O.Value,:);
    D.X = subdata.Filtered.FiltX(D.currentTrial,:);
    D.Y = subdata.Filtered.FiltY(D.currentTrial,:);
    % clear the plotting axes
    clearAxes
  end

% % playback
  function drawBin = shouldDraw
    elapsedTime = (GetSecs - V.lastDraw);
    drawBin = elapsedTime >= V.FrameTime;
  end

  function drawTime = drawNow
    drawGaze;
    drawTime = GetSecs;
  end

  function drawGaze
    G.AX.H.UserData.gazePlot = scatter(D.X(V.Frame),D.Y(V.Frame));
  end

  function drawRand
    G.AX.H.UserData.randPlot = plot(G.AX.H,rand(100),rand(100));
  end

  function videoPlayPause(~,~)
    V.isPlaying = ~V.isPlaying
    drawPlayPause
  end


  function videoStop(~,~)
    V.isPlaying = 0;
    V.Frame = 0;
    %
    drawPlayPause
    %
    clearAxes
    %
    V.lastDraw = nan;
  end

% % basic graphics
  function clearAxes
    G.AX.H.UserData.randPlot.delete;
  end

  function drawPlayPause
    switch V.isPlaying
      case 0
        G.BUT(1).H.CData = G.IMAGES(1).image;
      case 1
        G.BUT(1).H.CData = G.IMAGES(2).image;
    end
  end
end


%% PRECOMPUTE
%% ANIMATE


%
% %% Axes Config
% GazeAxSize = [40 240 870 480];
% GazeAxSize(3) = GazeAxSize(4) * (ETT.ScreenDim.PixX / ETT.ScreenDim.PixY);
% GazeAxSize(1) = (930 - (GazeAxSize(3)+GazeAxSize(1)))/2 + 40;
%
% ScanPathWin = figure('Position',[740 197.5 1120 757],'Menubar','none','Toolbar','none','NumberTitle','Off','Color',[.65 .75 .65],...
%     'Name','Scan Path Visualization');
%
% CoordAxes = axes('Parent',ScanPathWin,'Units','Pixels','Position',[40 30 870 140],...
%     'ylim',[0 1],'xlim',[0 1000],'NextPlot','Add');
% TagAxes = axes('Parent',ScanPathWin,'Units','Pixels','Position',[40 172 870 20],...
%     'NextPlot','Add','xticklabel','','yticklabel','','xtick',[],'ytick',[],...
%     'ylim',[0 1]);
% GazeAxes = axes('Parent',ScanPathWin,'Units','Pixels','Position',GazeAxSize,...
%     'ylim',[0 1],'xlim',[0 1],'NextPlot','Add');
% rectangle('Position',[0 0 1 1],'FaceColor',[0 0 0]);
% rectangle('Position',[ETT.ScreenDim.StimX(1)/ETT.ScreenDim.PixX,...
%     ETT.ScreenDim.StimY(1)/ETT.ScreenDim.PixY,...
%     (ETT.ScreenDim.StimX(2)-ETT.ScreenDim.StimX(1)+1)/ETT.ScreenDim.PixX,...
%     (ETT.ScreenDim.StimY(2)-ETT.ScreenDim.StimY(1)+1)/ETT.ScreenDim.PixY],'FaceColor',[.9 .9 .9])
%
% load(ETT.Subjects(subslist(1)).Data.Import)
% if ~isfield(subdata,'Fixations')
%     text_nofix = text(.4, .5, ['No Fixations found for Subject ' ETT.Subjects(subslist(1)).Name]);
% end
%
% %% Sliders
% Sel_SubTri = uipanel('Units', 'Pixels', 'Position', [930 620 180 100],...
%     'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
% SubTxt = uicontrol('Style','Text','String',['Subject: ' ETT.Subjects(val_sub).Name],'Parent',Sel_SubTri,...
%     'FontSize',10,'ForegroundColor',[.1 .1 .1],'Position',[5 75 100 20],'HorizontalAlignment','Left',...
%     'BackgroundColor',[.7 .8 .7]);
% TriTxt = uicontrol('Style','Text','String',['Trial: ' text_tri],'Parent',Sel_SubTri,...
%     'FontSize',10,'ForegroundColor',[.1 .1 .1],'Position',[5 30 100 20],'HorizontalAlignment','Left',...
%     'BackgroundColor',[.7 .8 .7]);
%
% if length(subslist)>1
%     Slide_Sub = uicontrol('Style','Slider','Parent',Sel_SubTri,'Min',1,'Max',length(subslist),...
%         'Value',1,'SliderStep',[1/(length(subslist)-1), 1/(length(subslist)-1)],...
%         'Position',[5 55 170 20],'Callback',@slide_sub);
% end
% Slide_Tri = uicontrol('Style','Slider','Min',1,'Max',99,...
%     'Value',1,'SliderStep',[1 1],'Parent',Sel_SubTri,...
%     'Position',[5 10 170 20],'Callback',@slide_tri,'Enable','Off');
%
% %% Fixation Summary Panel
% FixSumPan = uipanel('Title', 'Fixation Summary:', 'Units', 'Pixels', 'Position', [930 240 180 370],...
%     'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
%
% uicontrol('Style','Text','Parent',FixSumPan,'Position',[5 330 160 15],'String','No.  Start   End   Duration',...
%     'FontSize',10,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontAngle','Italic');
% FixSumList_No = uicontrol('Style','Text','Parent',FixSumPan,'Position',[5 5 35 320],'String','',...
%     'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
% FixSumList_Str = uicontrol('Style','Text','Parent',FixSumPan,'Position',[45 5 35 320],'String','',...
%     'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
% FixSumList_End = uicontrol('Style','Text','Parent',FixSumPan,'Position',[85 5 35 320],'String','',...
%     'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
% FixSumList_Dur = uicontrol('Style','Text','Parent',FixSumPan,'Position',[125 5 35 320],'String','',...
%     'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
%
% %% Playback buttons
% playpic = imread([pwd '/Misc/Play_Button.jpg']);
% stoppic = imread([pwd '/Misc/Stop_Button.jpg']);
%
% panel_play = uipanel('Units', 'Pixels', 'Title','Playback Controls','Position', [930 30 180 200],...
%     'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
% button_play = uicontrol('Style','Pushbutton','Parent',panel_play,'String','|>','Position',[95 130 75 40]);
% set(button_play,'CData',playpic);
% button_stop = uicontrol('Style','Pushbutton','Parent',panel_play,'String','|_|','Position',[10 130 75 40]);
% set(button_stop,'CData',stoppic);
%
% % end