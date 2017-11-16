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


%% SHARED VARS
G = []; % graphics
V = []; % video
D = []; % data
F = []; % filter
M = []; % movie

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
  D.trialString = cat(1,repmat(char(' '),1,size(D.trialString,2)),D.trialString);
end

%% GRAPHICS
% figure
G.FIG.H = fig(100,'cf');
G.FIG.H.MenuBar = 'none';
G.FIG.H.Color = [1 1 1];
% G.FIG.H.CloseRequestFcn = 'LOOP = 0;';


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
G.AX.H.XLim = [0 1];
G.AX.H.YLim = [0 1];
G.AX.H.XTick = [];
G.AX.H.YTick = [];
G.AX.H.Box = 'on';
G.AX.H.UserData.gazePlot = [];
G.AX.H.UserData.mapPlot = [];


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
drawnow


%% FUNCTIONS
% Interface
% % set up
  function loadImages
    drawPlayPause
    G.BUT(2).H.CData = G.IMAGES(3).image;
  end

  function setupV
    V.tWin = 15; % how far back to look
    V.colorMap = [1:V.tWin];
    V.sizeMap = 3.^(linspace(2,6,V.tWin));
    % setup empty gaze
    V.gaze.X.raw = nan;
    V.gaze.Y.raw = nan;
    % setup empty heatmap
    V.map.size = [600,800];
    V.map.image = zeros(V.map.size);
    V.map.imageFilt = zeros(V.map.size);
  end

  function setupA
    G.AX.H.XLim = [1,V.map.size(2)];
    G.AX.H.YLim = [1,V.map.size(1)];
    G.AX.H.ColorOrder = colormap('jet');
  end

  function setupF
    % setup the filter
    F.dDeg = 5; % desired standard deviation of the kernel in degrees
    F.dPix = vac_pix(F.dDeg,'h'); % desired standard deviation of the kern in pix
    
    F.scaledSig = F.dPix * (V.map.size(2) ./ 1920);
    F.xLims = floor(norminv(.01,0,F.scaledSig));
    % how far out should we go to get 98% of the normal
    F.xVals = F.xLims:-F.xLims;
    F.xLen = length(F.xVals);
    %
    [F.xDat,F.yDat] = meshgrid(F.xVals,F.xVals);
    F.X = [F.xDat(:),F.yDat(:)];
    F.mu = [0,0];
    F.sigma = F.scaledSig * eye(2);
    F.kern = mvnpdf(F.X,F.mu,F.sigma);
    F.kern2 = reshape(F.kern,[F.xLen,F.xLen]);
  end

  function setupM
    M = [];
  end

% % selection
  function selectTrial(O,~)
    % get the data from this subject
    D.currentTrial = D.trialNums(O.Value,:);
    D.X = subdata.Filtered.FiltX(D.currentTrial,:);
    D.Y = subdata.Filtered.FiltY(D.currentTrial,:);
    D.totalData = max(sum(~isnan(D.X)),sum(~isnan(D.Y)));
    % stop playback
    videoStop
    % clear the plotting axes
    clearAxes
    setupV
    setupA
    setupF
    setupM
    checkReady
  end

  function checkReady
    if ~isempty(D) && isfield(D, 'currentTrial')
      D.ready = 1;
    else
      D.ready = 0;
    end
  end

% % playback
  function mainDraw
    % don't try to draw if trial hasn't been selected
    if D.ready
      V.lastDraw = GetSecs;
      while V.isPlaying
        V.drawNow = shouldDraw;
        if V.drawNow
          V.lastDraw = drawNow;
          V.Frame = V.Frame + 1;
        end
        try
          drawnow
        end
      end
    end
  end

  function drawBin = shouldDraw
    elapsedTime = (GetSecs - V.lastDraw);
    tEnough = elapsedTime >= V.FrameTime;
    lastFrame = 1;
    drawBin = tEnough & lastFrame;
  end

  function drawTime = drawNow
    % remove the last plotted points
    clearAxes
    % get the gaze data
    getGaze;
    % update the background heatmap data
    updateMap;
    % draw the heatmap
    drawMap;
    % draw the gaze
    drawGaze;
    % timestamp the update
    drawTime = GetSecs;
    % add to movie
    M{V.Frame} = getframe(G.FIG.H);
  end

  function getGaze
    % get the time indices
    V.tInds = V.Frame-(V.tWin-1):V.Frame; % indices
    V.tInds(V.tInds<1) = []; % don't try to get data before frame 1
    if V.Frame < D.totalData
      % get the appropriate gaze points
      V.gaze.X.raw = D.X(V.tInds);
      V.gaze.Y.raw = D.Y(V.tInds);
      if ~isnan(V.gaze.X.raw)
        % prevent over/under
        V.gaze.X.norm = min(1,max(0,V.gaze.X.raw));
        % scale
        V.gaze.X.scale = V.gaze.X.norm .* V.map.size(2);
        % round
        V.gaze.X.round = round(V.gaze.X.scale);
      else
        V.gaze.X.norm = nan;
        V.gaze.X.scale = nan;
        V.gaze.X.round = nan;
      end
      
      if ~isnan(V.gaze.Y.raw)
        % prevent over/under
        V.gaze.Y.norm = min(1,max(0,V.gaze.Y.raw));
        % scale
        V.gaze.Y.scale = V.gaze.Y.norm .* V.map.size(1);
        % round
        V.gaze.Y.round = round(V.gaze.Y.scale);
      else
        V.gaze.Y.norm = nan;
        V.gaze.Y.scale = nan;
        V.gaze.Y.round = nan;
      end
    else
      writeM
    end
  end

  function updateMap
    % only the most recent point
    lastX = V.gaze.X.round(end);
    lastY = V.gaze.Y.round(end);
    % don't do anything if there isn't any data at this point
    if ~isnan(lastX) && ~isnan(lastY)
      V.map.image(lastY,lastX) = V.map.image(lastY,lastX) + 1;
      V.map.imageNorm = V.map.image ./ sum(sum(V.map.image));
      V.map.imageFilt = conv2(V.map.image,F.kern2,'same');
      G.AX.H.CLim = [0 sum(sum(V.map.imageFilt))/10000];
    end
  end

  function updateColor
    V.colorMap = linspace(0,G.AX.H.CLim * [0;1],V.tWin);
  end

  function drawGaze
    if any(~isnan(V.gaze.X.scale)) && any(~isnan(V.gaze.Y.scale))
      % truncate the master color / size maps
      updateColor
      gazeSize = V.sizeMap(1:length(V.tInds));
      gazeColor = V.colorMap(1:length(V.tInds));
      G.AX.H.UserData.gazePlot = scatter(V.gaze.X.scale,V.gaze.Y.scale,...
        gazeSize,gazeColor,'filled');
      % format the gaze
      G.AX.H.UserData.gazePlot.LineWidth = 1.5;
      G.AX.H.UserData.gazePlot.MarkerFaceAlpha = .25;
      G.AX.H.UserData.gazePlot.MarkerEdgeColor = [.15 .15 .15];
      G.AX.H.UserData.gazePlot.MarkerEdgeAlpha = .5;
    end
  end

  function drawMap
    G.AX.H.UserData.mapPlot = imagesc(V.map.imageFilt);
    G.AX.H.UserData.mapPlot.Parent = G.AX.H;
  end

  function drawRand
    G.AX.H.UserData.randPlot = plot(G.AX.H,rand(100),rand(100));
  end

  function videoPlayPause(~,~)
    checkReady
    if D.ready
      V.isPlaying = ~V.isPlaying;
      drawPlayPause
      if V.isPlaying
        mainDraw
      end
    end
  end


  function videoStop(~,~)
    V.isPlaying = 0;
    V.Frame = 1;
    %
    drawPlayPause
    %
    clearAxes
    %
    V.lastDraw = nan;
    % clear the video data
    setupV
  end

% % basic graphics
  function clearAxes
    % gaze
    if ~isempty(G.AX.H.UserData.gazePlot)
      G.AX.H.UserData.gazePlot.delete;
    end
    % heatmap
    if ~isempty(G.AX.H.UserData.mapPlot)
      G.AX.H.UserData.mapPlot.delete;
    end
  end

  function drawPlayPause
    switch V.isPlaying
      case 0
        G.BUT(1).H.CData = G.IMAGES(1).image;
      case 1
        G.BUT(1).H.CData = G.IMAGES(2).image;
    end
  end

  function writeM
    choice = questdlg('Save Video?',...
      'Save', 'Yes','No','Yes');
    switch choice
      case 'Yes'
        vName = ['VIDEO_' num2str(D.currentTrial) '.avi'];
        [file,path] = uiputfile(vName,'Save Video As');
        V = VideoWriter([path file]);
        V.FrameRate = V.FrameRate;
        V.Quality = 100;
        open(V)
        for f = 1:length(M)
          writeVideo(V,M{f});
        end
        close(V)
    end
  end
end
