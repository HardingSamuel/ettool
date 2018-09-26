function [ETT] = sett_ScreenDims(ETT)
%
% sett_ScreenDims
% Set up the stimulus screen's physical size, display resolution, and
% stimulus presentation area.
%
% INPUTS:
% ETT
%
% OUTPUTS:
% ETT
%
%% Change Log
%   [SH] - 05/20/14:    v1 - Creation

%%
screen_left = 20; screen_width = 360;

ScreenFig = figure('Name', 'Screen Configuration', 'Unit', 'Pixels', 'Position', [460 570 400 330], 'NumberTitle','Off','MenuBar','None',...
    'Color', [.65 .75 .65]);

ScreenDiag = axes('Parent',ScreenFig,'Units','Pixels','Position',...
    [screen_left 50 screen_width 202.5],...
    'NextPlot','Add','xticklabel','','yticklabel','','xtick',[],'ytick',[],...
    'ylim',[0 1], 'xlim',[0 1],'Color',[0 0 0]);
axis ij
screen_rect = rectangle('position',[0 0 1 1],'EdgeColor',[1 1 1]);
region_rect = [];


uicontrol('Style','Edit','Position',[20 292.5 80 30],'Parent',ScreenFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',10,'String','Width(mm):');
xvalmm = uicontrol('Style','Edit','Position',[100 292.5 50 30],'Parent',ScreenFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',10,'String',num2str(ETT.ScreenDim.Width),'Max',1,'Callback',@updatebox);
uicontrol('Style','Edit','Position',[20 262.5 80 30],'Parent',ScreenFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',10,'String','Height(mm):');
yvalmm = uicontrol('Style','Edit','Position',[100 262.5 50 30],'Parent',ScreenFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',10,'String',num2str(ETT.ScreenDim.Height),'Max',1,'Callback',@updatebox);

uicontrol('Style','Edit','Position',[150 292.5 60 30],'Parent',ScreenFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',10,'String','X-Pixels:');
xvalpix = uicontrol('Style','Edit','Position',[210 292.5 40 30],'Parent',ScreenFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',10,'String',num2str(ETT.ScreenDim.PixX),'Max',1,'Callback',@updatebox);
uicontrol('Style','Edit','Position',[150 262.5 60 30],'Parent',ScreenFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',10,'String','Y-Pixels:');
yvalpix = uicontrol('Style','Edit','Position',[210 262.5 40 30],'Parent',ScreenFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',10,'String',num2str(ETT.ScreenDim.PixY),'Max',1,'Callback',@updatebox);

uicontrol('Style','Edit','Position',[250 292.5 60 30],'Parent',ScreenFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',10,'String','X-Extent:');
xextent = uicontrol('Style','Edit','Position',[310 292.5 70 30],'Parent',ScreenFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',10,'String',['[' num2str(ETT.ScreenDim.StimX), ']'],'Max',1,'Callback',@updateregion);
uicontrol('Style','Edit','Position',[250 262.5 60 30],'Parent',ScreenFig,'Enable','inactive','BackgroundColor',[.75 .85 .75],...
    'HorizontalAlignment','Center','FontSize',10,'String','Y-Extent:');
yextent = uicontrol('Style','Edit','Position',[310 262.5 70 30],'Parent',ScreenFig,'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','Center','FontSize',10,'String',['[' num2str(ETT.ScreenDim.StimY), ']'],'Max',1,'Callback',@updateregion);

donebutton = uicontrol('Style','Pushbutton','String','Save and Return','Position',...
    [20 10 360 30],'BackgroundColor',[.8 .8 .8],'FontSize',12,'Callback',@done);

    function updatebox(~,~)
        xmm = str2num(get(xvalmm,'String'));
        ymm = str2num(get(yvalmm,'String'));
        xpx = str2num(get(xvalpix,'String'));
        ypx = str2num(get(yvalpix,'String'));
        xtnt = str2num(get(xextent,'String'));
        ytnt = str2num(get(yextent,'String'));
        scrat = xpx/ypx;
        screen_width = (202.5/ypx)*xpx;
        screen_left  = (400 - screen_width)/2;
        delete(ScreenDiag);
        ScreenDiag = axes('Parent',ScreenFig,'Units','Pixels','Position',...
            [screen_left 50 screen_width 202.5],...
            'NextPlot','Add','xticklabel','','yticklabel','','xtick',[],'ytick',[],...
            'ylim',[0 1], 'xlim',[0 1],'Color',[0 0 0]);
        screen_rect = rectangle('position',[0 0 1 1],'EdgeColor',[1 1 1]);
        set(xextent,'String',['[' num2str(xtnt(1)), '  ' num2str(min(xtnt(2), xpx)), ']'])
        set(yextent,'String',['[' num2str(ytnt(1)), '  ' num2str(min(ytnt(2), ypx)), ']'])
        updateregion
    end

    function updateregion(~,~)
        xpx = str2num(get(xvalpix,'String'));
        ypx = str2num(get(yvalpix,'String'));
        xtnt = str2num(get(xextent,'String'));
        ytnt = str2num(get(yextent,'String'));
        if ishandle(region_rect); delete(region_rect); end
        region_rect = rectangle('Position',[xtnt(1)/xpx, ytnt(1)/ypx (xtnt(2)-xtnt(1))/xpx ...
            (ytnt(2)-ytnt(1))/ypx],'EdgeColor',[1 0 0]);
    end

    function done(~,~)
        updatebox
        ETT.ScreenDim.Width = str2num(get(xvalmm,'String'));
        ETT.ScreenDim.Height = str2num(get(yvalmm,'String'));
        ETT.ScreenDim.PixX = str2num(get(xvalpix,'String'));
        ETT.ScreenDim.PixY = str2num(get(yvalpix,'String'));
        ETT.ScreenDim.StimX = str2num(get(xextent,'String'));
        ETT.ScreenDim.StimY = str2num(get(yextent,'String'));
        close(ScreenFig)
    end


uiwait(ScreenFig)

end