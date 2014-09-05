% function [] = vis_ScanPath(ETT,subslist)
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

%%
close(gcf)

text_sub = num2str(subslist(1)); val_sub = subslist(1);
text_tri = '1'; val_tri = 1; val_maxtri = 99;

%% Axes Config
GazeAxSize = [40 240 870 480];
GazeAxSize(3) = GazeAxSize(4) * (ETT.ScreenDim.PixX / ETT.ScreenDim.PixY);
GazeAxSize(1) = (930 - (GazeAxSize(3)+GazeAxSize(1)))/2 + 40;

ScanPathWin = figure('Position',[740 197.5 1120 757],'Menubar','none','Toolbar','none','NumberTitle','Off','Color',[.65 .75 .65],...
    'Name','Scan Path Visualization');

CoordAxes = axes('Parent',ScanPathWin,'Units','Pixels','Position',[40 30 870 140],...
    'ylim',[0 1],'xlim',[0 1000],'NextPlot','Add');
TagAxes = axes('Parent',ScanPathWin,'Units','Pixels','Position',[40 172 870 20],...
    'NextPlot','Add','xticklabel','','yticklabel','','xtick',[],'ytick',[],...
    'ylim',[0 1]);
GazeAxes = axes('Parent',ScanPathWin,'Units','Pixels','Position',GazeAxSize,...
    'ylim',[0 1],'xlim',[0 1],'NextPlot','Add');
rectangle('Position',[0 0 1 1],'FaceColor',[0 0 0]);
rectangle('Position',[ETT.ScreenDim.StimX(1)/ETT.ScreenDim.PixX,...
    ETT.ScreenDim.StimY(1)/ETT.ScreenDim.PixY,...
    (ETT.ScreenDim.StimX(2)-ETT.ScreenDim.StimX(1)+1)/ETT.ScreenDim.PixX,...
    (ETT.ScreenDim.StimY(2)-ETT.ScreenDim.StimY(1)+1)/ETT.ScreenDim.PixY],'FaceColor',[.9 .9 .9])

load(ETT.Subjects(subslist(1)).Data.Import)
if ~isfield(subdata,'Fixations')    
    text_nofix = text(.4, .5, ['No Fixations found for Subject ' ETT.Subjects(subslist(1)).Name]);
end

%% Sliders 
Sel_SubTri = uipanel('Units', 'Pixels', 'Position', [930 620 180 100],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
SubTxt = uicontrol('Style','Text','String',['Subject: ' ETT.Subjects(val_sub).Name],'Parent',Sel_SubTri,...
    'FontSize',10,'ForegroundColor',[.1 .1 .1],'Position',[5 75 100 20],'HorizontalAlignment','Left',...
    'BackgroundColor',[.7 .8 .7]);
TriTxt = uicontrol('Style','Text','String',['Trial: ' text_tri],'Parent',Sel_SubTri,...
    'FontSize',10,'ForegroundColor',[.1 .1 .1],'Position',[5 30 100 20],'HorizontalAlignment','Left',...
    'BackgroundColor',[.7 .8 .7]);

if length(subslist)>1
    Slide_Sub = uicontrol('Style','Slider','Parent',Sel_SubTri,'Min',1,'Max',length(subslist),...
        'Value',1,'SliderStep',[1/(length(subslist)-1), 1/(length(subslist)-1)],...
        'Position',[5 55 170 20],'Callback',@slide_sub);
end
Slide_Tri = uicontrol('Style','Slider','Min',1,'Max',99,...
    'Value',1,'SliderStep',[1 1],'Parent',Sel_SubTri,...
    'Position',[5 10 170 20],'Callback',@slide_tri,'Enable','Off');

%% Fixation Summary Panel
FixSumPan = uipanel('Title', 'Fixation Summary:', 'Units', 'Pixels', 'Position', [930 240 180 370],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

uicontrol('Style','Text','Parent',FixSumPan,'Position',[5 330 160 15],'String','No.  Start   End   Duration',...
    'FontSize',10,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontAngle','Italic');
FixSumList_No = uicontrol('Style','Text','Parent',FixSumPan,'Position',[5 5 35 320],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
FixSumList_Str = uicontrol('Style','Text','Parent',FixSumPan,'Position',[45 5 35 320],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
FixSumList_End = uicontrol('Style','Text','Parent',FixSumPan,'Position',[85 5 35 320],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
FixSumList_Dur = uicontrol('Style','Text','Parent',FixSumPan,'Position',[125 5 35 320],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');

%% Playback buttons
playpic = imread([pwd '/Misc/Play_Button.jpg']);
stoppic = imread([pwd '/Misc/Stop_Button.jpg']);

panel_play = uipanel('Units', 'Pixels', 'Title','Playback Controls','Position', [930 30 180 200],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
button_play = uicontrol('Style','Pushbutton','Parent',panel_play,'String','|>','Position',[95 130 75 40]);
set(button_play,'CData',playpic);
button_stop = uicontrol('Style','Pushbutton','Parent',panel_play,'String','|_|','Position',[10 130 75 40]);
set(button_stop,'CData',stoppic);

% end