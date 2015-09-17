function [ETT] = vis_FixationSaccade(ETT,subslist)
%
% vis_FixationSaccade
% Visualize and edit fixation and saccade detection for a given
% subject/trial.
%
% INPUTS:
%
%
% OUTPUTS:
%
%
%% Change Log
%   [SH] - 05/08/14:   v1 - Creation
%   [SH] - 06/18/14:   v1.1 - Several changes since creation.  Corrected
%   merging of fixations incorrectly determining which had been brushed.
%   [SH] - 06/24/14:   v1.2 - Addition of raw data samples (reduced alpha)
%   and validity shading for each eye.
%   [SH] - 09/02/14:   More keyboard shortcuts to facilitate easier editing
%   of fixation edges.
%   [SH] - 07/11/15:    Swapped colors on raw and filtered data for
%   clarity.

%%
% get ML version to handle ui changes in 2014b
mlVer = version('-release'); mlVer = mlVer(1:4); mlVer = str2num(mlVer);

subdata = []; trilist = []; tri_segs = cell(0,0);
text_sub = num2str(subslist(1)); val_sub = subslist(1);
text_tri = '1'; val_tri = 1; val_maxtri = 99;
seg_vis = 1; seg_sizeP = []; fixdetset = ETT.Config.FixDetect; preprocset = ETT.Config.PreProcess;

xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
xplotraw = []; yplotraw = [];
plot_interp = []; plot_blink = []; plot_missing = []; text_phase = cell(2,0); hlx = []; hly = [];
fixinfo = []; plot_fix = []; text_fix = []; plot_fix_high = []; text_fix_high = []; velo = []; pix_deg = []; tempdata{val_sub==subslist} = [];

text_tint = []; text_tbli = []; text_tgap  = [];

brushed = []; fixselected = [];

curr_edge = 1; curr_len = 5; data=[];

tempdata = cell(1,length(subslist)); issaved = 1;

diagfig = [];

FixDetWin = figure('Position',[740 197.5 1120 702.5],'Menubar','none','Toolbar','Figure','NumberTitle','Off','Color',[.65 .75 .65],...
    'Name','Fixation Detection','WindowKeyPressFcn',@key_switch);
FileMenu = uimenu('Label','&Fixations','Parent',FixDetWin,'Position',1,'Enable','Off');

uimenu('Label','&Save Fixations','Parent',FileMenu,'Position',1,...
    'Callback',@pop_save);
uimenu('Label','&Quit Fixation Detection','Parent',FileMenu,'Position',3,...
    'Callback',@pop_quit,'Separator','On');
uimenu('Label','&Reset Fixations','Parent',FileMenu,'Position',2,...
    'Callback',@pop_reset);

Sel_Sub = uipanel('Title', ['Subject: ' text_sub], 'Units', 'Pixels', 'Position', [640 652 290 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Sel_Tri = uipanel('Title', ['Trial: ' text_tri], 'Units', 'Pixels', 'Position', [640 597 290 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Sel_Seg = uipanel('Title', ['Trial Segment: ' num2str(seg_vis), '/1'], 'Units', 'Pixels', 'Position', [640 542 180 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uipanel('Title', 'Length(ms):', 'Units', 'Pixels', 'Position', [825 542 105 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);


if length(subslist)>1
    Slide_Sub = uicontrol('Style','Slider','Min',1,'Max',length(subslist),...
        'Value',1,'SliderStep',[1/(length(subslist)-1), 1/(length(subslist)-1)],...
        'Position',[650 659.5 210 20],'Callback',@slide_sub);
end

Load_SubButton = uicontrol('Style','PushButton','String','Load','Position',[870 657 50 27.5],...
    'BackgroundColor',[.8 .8 .8],'Callback',@loadsub);
Slide_Tri = uicontrol('Style','Slider','Min',1,'Max',99,...
    'Value',1,'SliderStep',[1 1],...
    'Position',[650 604.5 270 20],'Callback',@slide_tri,'Enable','Off');

GazeAxes = axes('Parent',FixDetWin,'Units','Pixels','Position',[60 50 870 440],...
    'ylim',[0 1],'xlim',[0 1000],'NextPlot','Add');%,'ButtonDownFcn',@key_switch);
GazeText = text(400, .5, 'Load data from Subject to Continue');

ylabel('Relative Gaze Position','BackgroundColor',[.7 .8 .7])
xlabel('Trial Time','BackgroundColor',[.7 .8 .7])

TagAxes = axes('Parent',FixDetWin,'Units','Pixels','Position',[60 492 870 40],...
    'NextPlot','Add','xticklabel','','yticklabel','','xtick',[],'ytick',[],...
    'ylim',[0 1]);%,'ButtonDownFcn',@key_switch);

linkaxes([GazeAxes,TagAxes],'x')
set(zoom(GazeAxes),'ActionPostCallback',@fix_x); set(zoom(TagAxes),'ActionPostCallback',@fix_x);
set(pan(FixDetWin),'ActionPostCallback',@fix_x)

Scroll_Right = uicontrol('Style','PushButton','String','>>>','Parent',FixDetWin,...
    'Position',[735 547 75 25],'Backgroundcolor',[.8 .8 .8],'Enable','Off',...
    'Callback',@scroll_right);
Scroll_Left = uicontrol('Style','PushButton','String','<<<','Parent',FixDetWin,...
    'Position',[650 547 75 25],'Backgroundcolor',[.8 .8 .8],'Enable','Off',...
    'Callback',@scroll_left);
WinSize = uicontrol('Style','Edit','Enable','Off','String','3000',...
    'Position',[835 547 85 25],'FontSize',12,'Callback',@disp_trial_gui);

%% Settings Summary and Editing
PreSumm = uicontrol('Style','Text','Parent',FixDetWin,'Position',[110 645 290 40],'String',...
    '','CreateFcn',@pre_text,'BackgroundColor',[.7 .8 .7]);
PreEdit = uicontrol('Style','PushButton','String','Edit','Parent',FixDetWin,...
    'Position',[60 645 40 40],'BackgroundColor',[.8 .8 .8],'Callback',@pre_edit,'Enable','Off');
FixSumm = uicontrol('Style','Text','Parent',FixDetWin,'Position',[110 590 290 40],'String',...
    '','CreateFcn',@fix_text,'BackgroundColor',[.7 .8 .7]);
FixEdit = uicontrol('Style','PushButton','String','Edit','Parent',FixDetWin,...
    'Position',[60 590 40 40],'BackgroundColor',[.8 .8 .8],'Callback',@fix_edit,'Enable','Off');

%% Fixation Summary List
FixSumPan = uipanel('Title', 'Fixation Summary:', 'Units', 'Pixels', 'Position', [940 50 175 645],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

uicontrol('Style','Text','Parent',FixSumPan,'Position',[5 605 160 15],'String','No.  Start   End   Duration',...
    'FontSize',10,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontAngle','Italic');
FixSumList_No = uicontrol('Style','Text','Parent',FixSumPan,'Position',[5 5 35 595],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
FixSumList_Str = uicontrol('Style','Text','Parent',FixSumPan,'Position',[45 5 35 595],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
FixSumList_End = uicontrol('Style','Text','Parent',FixSumPan,'Position',[85 5 35 595],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');
FixSumList_Dur = uicontrol('Style','Text','Parent',FixSumPan,'Position',[125 5 35 595],'String','',...
    'FontSize',8,'BackgroundColor',[.7 .8 .7],'HorizontalAlignment','Left','FontWeight','Normal');

%% Gross Fixation Auditing
EB_New = uicontrol('Style','Pushbutton','String','New Fixation','BackgroundColor',[.8 .8 .8],...
    'Position',[60 542 77.5 38],'Enable','Off');
EB_Delete = uicontrol('Style','Pushbutton','String','Delete Fixation','BackgroundColor',[.8 .8 .8],...
    'Position',[147.5 542 77.5 38],'Enable','Off');
EB_Merge = uicontrol('Style','Pushbutton','String','Merge Fixations','BackgroundColor',[.8 .8 .8],...
    'Position',[235 542 77.5 38],'Enable','Off');
EB_Split = uicontrol('Style','Pushbutton','String','Split Fixations','BackgroundColor',[.8 .8 .8],...
    'Position',[322.5 542 77.5 38],'Enable','Off');

%% Fine Editing buttons
SE_Edge = uibuttongroup('Visible','On','units','Pixels','Position',[410 542 220 96],'BackGroundColor',[.7 .8 .7],...
    'Title','Refine Edges:','TitlePosition','LeftTop','FontSize',10,'SelectionChangefcn',@edge_select,'Parent',FixDetWin);
edge_left = uicontrol('Style','RadioButton','String','Left','Enable','On','Value',1,...
    'Position',[12.5 50 60 25],'FontSize',10,'Parent',SE_Edge,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_edge==1,'UserData',1);
edge_right = uicontrol('Style','RadioButton','String','Right','Enable','On','Value',0,...
    'Position',[62.5 50 60 25],'FontSize',10,'Parent',SE_Edge,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_edge==-1,'UserData',-1);
uicontrol('Style','Text','String','Size:','Parent',SE_Edge,'Position',[135 47.5 45 25],'FontSize',10,...
    'BackgroundColor',[.7 .8 .7])
uicontrol('Style','Edit','String','5','Parent',SE_Edge','Position',[180 50 30 25],'FontSize',10,...
    'Callback',@edge_size)
uipanel('Units', 'Pixels', 'Position', [540 590 2 39],...
    'BackgroundColor', [.7 .8 .7], 'ForegroundColor', [.1 .1 .1]);
uipanel('Units', 'Pixels', 'Position', [410 587.5 220 2],...
    'BackgroundColor', [.7 .8 .7], 'ForegroundColor', [.1 .1 .1]);

FineMMM = uicontrol('Style','PushButton','String','---','Parent',SE_Edge,'Position',[5 5 48.75 35],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Enable','Off','Callback',[]);
FineM = uicontrol('Style','PushButton','String','-','Parent',SE_Edge,'Position',[58.75 5 48.75 35],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Enable','Off','Callback',[]);
FineP = uicontrol('Style','PushButton','String','+','Parent',SE_Edge,'Position',[111.5 5 48.75 35],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Enable','Off','Callback',[]);
FinePPP = uicontrol('Style','PushButton','String','+++','Parent',SE_Edge,'Position',[164.25 5 48.75 35],...
    'BackgroundColor',[.8 .8 .8],'FontSize',12,'Enable','Off','Callback',[]);


fixbrush = brush(FixDetWin);
set(fixbrush,'ActionPostCallback',@fix_brush,'Color',[1 .7 .7])

    function fix_x(~,~)
        xticks = get(GazeAxes,'xtick');
        set(GazeAxes,'xticklabel',(1000/subdata.SampleRate)*xticks)
        set(TagAxes,'ylim',[0 1])
    end

    function slide_sub(~,~)
%         text_sub = num2str(subslist(fix(get(Slide_Sub,'Value'))));
        text_sub = ETT.Subjects(get(Slide_Sub,'Value')).Name;
        val_sub = str2double(text_sub);
        set(Sel_Sub,'Title',['Subject: ' text_sub])
    end

    function slide_tri(~,~)
        text_tri = num2str(trilist(fix(get(Slide_Tri,'Value'))));
        maxnext = 0;
        if seg_sizeP == length(find(~isnan(subdata.Filtered.FiltX(val_tri,:))))
            maxnext = 1;
        end
        val_tri = str2double(text_tri);
        seg_sizeP = fix(3000 / (1000/subdata.SampleRate));
        set(WinSize,'String','3000')
        if maxnext
            seg_sizeP = fix(length(find(~isnan(subdata.Filtered.FiltX(val_tri,:)))));
            set(WinSize,'String',num2str(fix(seg_sizeP * (1000/subdata.SampleRate))))
        end
        set(Sel_Tri,'Title',['Trial: ' text_tri])
        disp_trial
    end

    function loadsub(~,~)
        cla(GazeAxes); cla(TagAxes);
        xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
        xplotraw = []; yplotraw = [];
        plot_interp = []; plot_blink = []; plot_missing = []; text_phase = cell(2,0);
        hlx = []; hly = [];
        fixinfo = []; plot_fix = []; text_fix = []; velo = []; pix_deg = [];  plot_fix_high = []; text_fix_high = [];
        
        
        
        set(Load_SubButton,'Enable','Off')
        set(WinSize,'Enable','On')
        set(Slide_Tri,'Value',1);
        set(Sel_Tri,'Title', 'Trial: 1');
        set(FileMenu,'Enable','On')
        gen_diag(['Loading Subject ', ETT.Subjects(val_sub).Name])
        subdata = load(ETT.Subjects(val_sub).Data.Import);
        delete(diagfig)
        subdata = subdata.subdata;
        
        set(Slide_Tri','Enable','On')
        val_maxtri = size(subdata.TrialLengths,1);
        val_tri = 1;
        seg_sizeP = fix(str2double(get(WinSize,'String'))/(1000/subdata.SampleRate));
        set(Slide_Tri,'Max',val_maxtri,'SliderStep',...
            [1/(val_maxtri-1), 1/(val_maxtri-1)])
        trilist = 1:val_maxtri;
        
        try
            delete(GazeText)
        end
        fixdetset = ETT.Config.FixDetect;
        if ~isempty(ETT.Subjects(val_sub).Config.FixDetect)
            fixdetset = ETT.Subjects(val_sub).Config.FixDetect;
        end
        preprocset = ETT.Config.PreProcess;
        if ~isempty(ETT.Subjects(val_sub).Config.PreProcess)
            preprocset = ETT.Subjects(val_sub).Config.PreProcess;
        end
        pre_text
        fix_text
        
        set(PreEdit,'Enable','On'); set(FixEdit,'Enable','On')
        calc_velo
        if ~isfield(subdata,'Fixations')
            tempdata{val_sub==subslist} = [];
            estim_fixations
            newdata = organize_fixations;
            tempdata{val_sub==subslist} = newdata{val_sub==subslist};
            list_fix
        else
            tempdata{val_sub==subslist} = subdata.Fixations;
        end
        disp_trial
        
    end

    function disp_trial_gui(~,~)
        seg_sizeP = fix(min(str2double(get(WinSize,'String')),length(find(~isnan(subdata.Filtered.FiltX(val_tri,:))))*(1000/subdata.SampleRate))/(1000/subdata.SampleRate));
        if seg_sizeP < 500
          msgbox(['Warning: segment size too small, setting to 500ms'])
          seg_sizeP = 500;
        end
        set(WinSize,'String',num2str(fix(min(str2double(get(WinSize,'String')),size(subdata.Filtered.FiltX,2)*(1000/subdata.SampleRate)))))
        disp_trial
    end

    function disp_trial
        cla(GazeAxes); cla(TagAxes);
        xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
        xplotraw = []; yplotraw = [];
        plot_interp = []; plot_blink = []; plot_missing = []; text_phase = cell(2,0);
        hlx = []; hly = []; plot_fix = []; text_fix = []; plot_fix_high = []; text_fix_high = [];
        
        text_tint = []; text_tbli = []; text_tgap  = [];
        trilen = sum(~isnan(subdata.Filtered.FiltX(val_tri,:)));
        tri_segs = cell(0,0);
        if trilen > seg_sizeP
            for trispl = 1:ceil(trilen/(seg_sizeP))
                tri_segs{trispl} = fix(.75*seg_sizeP*(trispl-1)+1:.75*seg_sizeP*(trispl-1)+seg_sizeP+1);
            end
            set(Scroll_Right,'Enable','On');
        else
            tri_segs{1} = 1:seg_sizeP;
            set(Scroll_Right,'Enable','Off');
        end
        seg_vis = 1;
        set(Scroll_Left,'Enable','Off');
        set(Sel_Seg,'Title', ['Trial Segment: ' num2str(seg_vis), '/' num2str(length(tri_segs))])
        scroll_trial
        tag_phases
        if isempty(tempdata{val_sub==subslist})
            newdata = organize_fixations;
            tempdata{val_sub==subslist} = newdata{val_sub==subslist};
        end
        list_fix
        plot_fixations([])
        %         brush on
    end

    function scroll_right(~,~)
        seg_vis = min(seg_vis+1,length(tri_segs));
        set(Scroll_Left,'Enable','On')
        if seg_vis >= length(tri_segs)
            set(Scroll_Right,'Enable','Off')
        end
        set(Sel_Seg,'Title',['Trial Segment: ' num2str(seg_vis), '/' num2str(length(tri_segs))])
        scroll_trial
    end

    function scroll_left(~,~)
        seg_vis = max(seg_vis-1,1);
        set(Scroll_Right,'Enable','On')
        if seg_vis == 1
            set(Scroll_Left,'Enable','Off')
        end
        set(Sel_Seg,'Title',['Trial Segment: ' num2str(seg_vis), '/' num2str(length(tri_segs))])
        scroll_trial
    end

    function scroll_trial
        delete(xplot);delete(yplot);
        delete(xplotraw); delete(yplotraw);
        
        data.PlotX = subdata.Filtered.FiltX(val_tri,:); data.PlotY = subdata.Filtered.FiltY(val_tri,:);
        data.plotV = velo(val_tri,:);
        
        data.RawPlotX = subdata.Combined.CombX(val_tri,:); data.RawPlotY = 1 - subdata.Combined.CombY(val_tri,:);
        
        data.ShadeTop = subdata.LeftEye.Validity(val_tri,:); data.ShadeBottom = subdata.RightEye.Validity(val_tri,:);
        
        if max(tri_segs{end}) > length(data.PlotX)
            data.PlotX(end+1:end+max(tri_segs{end}) - length(data.PlotX)) = nan(1,max(tri_segs{end}) - length(data.PlotX));
            data.PlotY(end+1:end+max(tri_segs{end}) - length(data.PlotY)) = nan(1,max(tri_segs{end}) - length(data.PlotY));
            data.plotV(end+1:end+max(tri_segs{end}) - length(data.plotV)) = nan(1,max(tri_segs{end}) - length(data.plotV));
        end
        
        if max(tri_segs{end}) > length(data.RawPlotX)
            data.RawPlotX(end+1:end+max(tri_segs{end}) - length(data.RawPlotX)) = nan(1,max(tri_segs{end}) - length(data.RawPlotX));
            data.RawPlotY(end+1:end+max(tri_segs{end}) - length(data.RawPlotY)) = nan(1,max(tri_segs{end}) - length(data.RawPlotY));
        end
        
        if max(tri_segs{end}) > length(data.ShadeTop)
            data.ShadeTop(end+1:end+max(tri_segs{end}) - length(data.ShadeTop)) = nan(1,max(tri_segs{end}) - length(data.ShadeTop));
            data.ShadeBottom(end+1:end+max(tri_segs{end}) - length(data.ShadeBottom)) = nan(1,max(tri_segs{end}) - length(data.ShadeBottom));
        end
        
        axes(GazeAxes)
        
        [rectlist] = make_rectangles(data.ShadeTop,data.ShadeBottom);
        for eye = [{'top'},{'bottom'}]
            offset = double(strcmp(char(eye),'top')) / 2;
            for shader = 1:4
                thisrect = rectlist.(char(eye)).(['rect' num2str(shader)]);
                if ~isempty(thisrect)
                    for nboxes = 1:size(thisrect,2)
                        rectangle('Position',[thisrect(1,nboxes) offset thisrect(2,nboxes) - thisrect(1,nboxes) + 1, .5],...
                            'FaceColor',repmat(1-.1*shader,1,3),'EdgeColor',repmat(1-.1*shader,1,3))
                    end
                end
            end
        end
        
        xplotraw = plot(GazeAxes,tri_segs{seg_vis},data.RawPlotX(tri_segs{seg_vis}),'--o','Color',[1 1 1],'MarkerSize',2);
        yplotraw = plot(GazeAxes,tri_segs{seg_vis},data.RawPlotY(tri_segs{seg_vis}),'--o','Color',[1 0 0],'MarkerSize',2);
        
        xplot = plot(GazeAxes,tri_segs{seg_vis},data.PlotX(tri_segs{seg_vis}),'Color',[.7 .7 .7],'LineWidth',2);
        yplot = plot(GazeAxes,tri_segs{seg_vis},1-data.PlotY(tri_segs{seg_vis}),'Color',[.9 .6 .6],'LineWidth',2);
        
        plot_velo(data.plotV)
        legend([xplot,yplot,vplot],'X-Gaze','Y-Gaze','Velocity (scaled)','location','northeast');
        
        axes(GazeAxes)
        set(GazeAxes,'xlim',[tri_segs{seg_vis}(1), tri_segs{seg_vis}(end)])
        xticks = get(GazeAxes,'xtick');
        set(GazeAxes,'xticklabel',(1000/subdata.SampleRate)*xticks)
        tag_pre
    end

    function rectlist = make_rectangles(top,bottom)
        thiseye = [];
        for eye = [{'top'},{'bottom'}];
            eval(['thiseye = ' char(eye) ';'])
            for validity = 1:4
                vallist = find(thiseye==validity);
                if ~isempty(vallist)
                    valend = [vallist(find(diff(vallist)>1)),vallist(end)];
                end
                notvallist = find(thiseye~=validity);
                valbegin = notvallist(find(diff(notvallist)>1))+1;
                if thiseye(subdata.TrialLengths(val_tri)) == validity
                    valend = cat(2,valend,subdata.TrialLengths(val_tri));
                end
                if thiseye(1) == validity
                    valbegin = cat(2,1,valbegin);
                end
                if ~isempty(valbegin) & ~isempty(valend)
                    valbegin = unique(valbegin); valend = unique(valend);
                    try
                        rectlist.(char(eye)).(['rect' num2str(validity)]) = [valbegin;valend];
                    catch; keyboard
                    end
                else
                    rectlist.(char(eye)).(['rect' num2str(validity)]) = [];
                end
            end
        end
    end

    function calc_velo
        velo = [];
        dist = subdata.Filtered.FiltD;
        x = subdata.Filtered.FiltX * ETT.ScreenDim.PixX;
        y = subdata.Filtered.FiltY * ETT.ScreenDim.PixY;
        pix_deg = dist * (ETT.ScreenDim.PixX/ETT.ScreenDim.Width);
        xy = sqrt(diff(x,1,2).^2 + diff(y,1,2).^2); %linear distance from origin (0,0):  screen UL corner
        velo = (atand((xy/2)./(pix_deg(:,1:end-1)))*2)*subdata.SampleRate;
        velo = cat(2,velo,velo(:,end));
    end

    function plot_velo(plotV)
        delete(vplot);delete(vthresh);delete(vtext);
        vplot = plot(GazeAxes,tri_segs{seg_vis},plotV(tri_segs{seg_vis}) * .3/500,'b');
        vthresh = plot(GazeAxes,tri_segs{seg_vis},repmat(fixdetset{1}*.3/500,1,seg_sizeP+1*(seg_sizeP~=length(tri_segs{seg_vis}))));
        axes(GazeAxes)
        vtext = text(tri_segs{seg_vis}(10),(fixdetset{1}*.3/500)+.025,[num2str(fixdetset{1}) 'deg/sec'],'color',[0 0 1]);
    end

    function pre_text(obj,~)
        filtnames = [{'Savitzky–Golay'},{'Bilateral'},{'Moving Average'},{'Low-Pass'}];
        newtext = strcat([char(filtnames(preprocset(1))), ' Filter, ',...
            ' Interp. Max: ', num2str(preprocset(2)),...
            ', Blink Max: ', num2str(preprocset(3)),...
            ', Window Length ', num2str(preprocset(4))]);
        if preprocset(1)==1
            newtext = strcat(newtext,', Filter Order: ', num2str(preprocset(5)));
        end
        try
            set(PreSumm,'String',newtext);
        catch
            set(obj,'String',newtext);
        end
    end

    function fix_text(obj,~)
        estimnames = [{'All Trials'},{'Individual Trials'}];
        val_trm = fixdetset(3);
        text_trm = strcat('[', num2str(val_trm{1}(1,:)), ';     ', num2str(val_trm{1}(2,:)), ';     ', num2str(val_trm{1}(3,:)), ']');
        text_trm = strrep(text_trm,'        ', ' ');
        newtext = strcat('Velocity Threshold: ', num2str(fixdetset{1}), ...
            ', Minimum Fixation: ', num2str(fixdetset{2}),...
            ', Velocity Bins: ', num2str(fixdetset{4}),...
            ', Estimate Distributions on: ', char(estimnames(fixdetset{5})),...
            ', Transisition Matrix: ', text_trm);
        try
            set(FixSumm,'String',newtext)
        catch
            set(obj,'String',newtext)
        end
    end

    function pre_edit(~,~)
        set(PreEdit,'Enable','Off')
        NewSettings = sett_PreProcess(ETT,1,preprocset);
        if ~all(NewSettings == preprocset) && ~isempty(NewSettings)
            preprocset = NewSettings;
            subdatanew = data_interp(subdata,preprocset);
            subdata.Interpolation = subdatanew.Interpolation;
            subdatanew = data_filter(subdata,preprocset);
            subdata.Filtered = subdatanew.Filtered;
            
            subdata.Config.PreProcess = preprocset;
            ETT.Subjects(val_sub).Config.PreProcess = preprocset;
            
            pre_text
            calc_velo
            list_fix
            disp_trial
        end
        set(PreEdit,'Enable','On')
    end

    function fix_edit(~,~)
        set(FixEdit,'Enable','Off')
        NewSettings = sett_FixDetect(ETT,1,fixdetset);
        if ~all(cellfun(@isequal, NewSettings, fixdetset)) && ~any(cellfun(@isempty,NewSettings))
            fixdetset = NewSettings;
            
            subdata.Config.FixDetect = fixdetset;
            ETT.Subjects(val_sub).Config.FixDetect = fixdetset;
            
            fix_text
            calc_velo
            estim_fixations
            newdata = organize_fixations;
            tempdata{val_sub==subslist} = newdata{val_sub==subslist};
            list_fix
            disp_trial
        end
        set(FixEdit,'Enable','On')
    end

    function tag_pre
        delete(plot_interp); delete(plot_blink); delete(plot_missing);
        delete(hlx); delete(hly);
        delete(text_tint); delete(text_tbli); delete(text_tgap);
        
        interp_begin = subdata.Interpolation.Indices{val_tri,1};
        interp_end = subdata.Interpolation.Indices{val_tri,2};
        blink_begin = subdata.Interpolation.Blinks{val_tri,1};
        blink_end = subdata.Interpolation.Blinks{val_tri,2};
        missing_begin = subdata.Interpolation.MissingData{val_tri,1};
        missing_end = subdata.Interpolation.MissingData{val_tri,2};
        
        axes(TagAxes)
        text_tint = text(tri_segs{seg_vis}(5),.9,'Interp','Color',[.5 0 .9],'FontSize',8);
        text_tbli = text(tri_segs{seg_vis}(5),.7,'Blink','Color',[0 0 1],'FontSize',8);
        text_tgap = text(tri_segs{seg_vis}(5),.5,'Missing','Color',[1 0 .8],'FontSize',8);
        
        if ~isempty(interp_begin)
            plot_interp = line([interp_begin;interp_end],repmat(.9,2,length(interp_begin)),'linewidth',5,'Color',[.5 0 .9]);
            
            for HL = 1:length(interp_begin)
                hlx = plot(GazeAxes,interp_begin(HL):interp_end(HL),...
                    subdata.Filtered.FiltX(val_tri,interp_begin(HL):interp_end(HL)),'Color',[.5 0 .9],'linewidth',2);
                hly = plot(GazeAxes,interp_begin(HL):interp_end(HL),...
                    1-subdata.Filtered.FiltY(val_tri,interp_begin(HL):interp_end(HL)),'Color',[.5 0 .9],'linewidth',2);
            end
        else
            plot_interp = []; hlx = []; hly = [];
        end
        if ~isempty(blink_begin)
            plot_blink = line([blink_begin;blink_end],repmat(.7,2,length(blink_begin)),'linewidth',5,'Color',[0 0 1]);
        else
            plot_blink = [];
        end
        if ~isempty(missing_begin)
            plot_missing = line([missing_begin;missing_end],repmat(.5,2,length(missing_begin)),'linewidth',5,'Color',[1 0 .8]);
        else
            plot_missing = [];
        end
    end

    function tag_phases
        axes(GazeAxes);
        for phd = 1:size(text_phase,2)
            delete(text_phase{:,phd});
        end
        for phd = 1:size(subdata.WhatsOn.Names{val_tri})
            if subdata.WhatsOn.Begindices{val_tri}(phd) >= tri_segs{seg_vis}(1) && ...
                    subdata.WhatsOn.Begindices{val_tri}(phd) <= tri_segs{seg_vis}(end)
                text_phase{1,phd} = text(subdata.WhatsOn.Begindices{val_tri}(phd)+5,.95,...
                    subdata.WhatsOn.Names{val_tri}(phd),'FontSize',8);
                text_phase{2,phd} = line(repmat(subdata.WhatsOn.Begindices{val_tri}(phd),1,2),...
                    [0, 1],'Color',[0 0 0]);
            end
        end
    end

    function estim_fixations
        [fixinfo] = fix_ivt(velo,fixdetset{1});
        [fixinfo.ivtclean] = fix_rejectfix(fixinfo.ivt,floor(fixdetset{2}/(1000/subdata.SampleRate)));
        [fixinfo] = fix_hmm(velo,fixinfo,fixdetset,fixinfo.ivtclean.states);
        [fixinfo.hmmclean] = fix_rejectfix(fixinfo.hmm,floor(fixdetset{2}/(1000/subdata.SampleRate)));
    end

    function orgdata = organize_fixations
        orgdata = cell(1,length(subslist));
        for tri_n = 1:val_maxtri
            orgdata{val_sub==subslist}{tri_n}.fixbegin = find(fixinfo.hmmclean.fixbegin(tri_n,:));
            orgdata{val_sub==subslist}{tri_n}.fixend = find(fixinfo.hmmclean.fixend(tri_n,:));
            orgdata{val_sub==subslist}{tri_n}.fixdurations = (orgdata{val_sub==subslist}{tri_n}.fixend - orgdata{val_sub==subslist}{tri_n}.fixbegin + 1) * (1000/subdata.SampleRate);
        end
    end

    function list_fix
        try
            numbox = cellstr(num2str((1:length(tempdata{val_sub==subslist}{val_tri}.fixbegin))'));
            strbox = cellstr(num2str(tempdata{val_sub==subslist}{val_tri}.fixbegin'));
            endbox = cellstr(num2str(tempdata{val_sub==subslist}{val_tri}.fixend'));
            durbox = cellstr(num2str(fix(tempdata{val_sub==subslist}{val_tri}.fixdurations')));
            set(FixSumList_No,'String',numbox)
            set(FixSumList_Str,'String',strbox)
            set(FixSumList_End,'String',endbox)
            set(FixSumList_Dur,'String',durbox)
        catch
            keyboard
        end
    end

    function plot_fixations(selectedfix)
        if ~isempty(plot_fix_high)
            delete(plot_fix_high); delete(text_fix_high);
            plot_fix_high = []; text_fix_high = [];
        end
        axes(TagAxes)
        try
            delete(plot_fix); delete(text_fix)
            plot_fix = line([tempdata{val_sub==subslist}{val_tri}.fixbegin;tempdata{val_sub==subslist}{val_tri}.fixend],repmat(.2,2,length(tempdata{val_sub==subslist}{val_tri}.fixbegin)),'linewidth',5,'Color',[0 1 0]);
            fixlist = 1:length(tempdata{val_sub==subslist}{val_tri}.fixbegin); fixlist(selectedfix) = [];
            text_fix = text(tempdata{val_sub==subslist}{val_tri}.fixbegin(fixlist) + (tempdata{val_sub==subslist}{val_tri}.fixend(fixlist)...
                - tempdata{val_sub==subslist}{val_tri}.fixbegin(fixlist))/2,repmat(.2,1,length(tempdata{val_sub==subslist}{val_tri}.fixbegin(fixlist))),...
                cellstr(num2str((fixlist)')),'HorizontalAlignment','Center');
        catch
            error('Number of fixation beginnings and ends does not line up')
        end
        if ~isempty(selectedfix)
            plot_fix_high = line([tempdata{val_sub==subslist}{val_tri}.fixbegin(selectedfix);tempdata{val_sub==subslist}{val_tri}.fixend(selectedfix)],...
                repmat(.2,2,length(tempdata{val_sub==subslist}{val_tri}.fixbegin(selectedfix))),'linewidth',5,'Color',[0 1 1]);
            text_fix_high = text(tempdata{val_sub==subslist}{val_tri}.fixbegin(selectedfix) + (tempdata{val_sub==subslist}{val_tri}.fixend(selectedfix)...
                - tempdata{val_sub==subslist}{val_tri}.fixbegin(selectedfix))/2,repmat(.2,1,length(tempdata{val_sub==subslist}{val_tri}.fixbegin(selectedfix))),...
                cellstr(num2str((selectedfix)')),'HorizontalAlignment','Center','Color',[0 0 0]);
        end
        set(Load_SubButton,'Enable','On')
    end

%% Manual fixation editing

    function fix_brush(~,~)      
        brushothers = findobj(FixDetWin,'DisplayName','Y-Gaze','-or','DisplayName','X-Gaze','-or','DisplayName','Velocity (scaled)');
        wasbrushed = 0;
        minbrush = nan(1,3); maxbrush = nan(1,3);
        for brushes = 1:3
            bd = get(brushothers(brushes),'BrushData');
            if ~isempty(find(bd, 1))
                wasbrushed = 1;
                minbrush(brushes) = find(bd,1,'first'); maxbrush(brushes) = find(bd,1,'last');
            end
        end
        
        if wasbrushed
            indices = min(minbrush):max(maxbrush);
            brushes_update(indices)
            
            set(EB_New,'Enable','On','Callback',@new_fix);
            set(EB_Delete,'Enable','On','Callback',@delete_fix);
            set(EB_Merge,'Enable','On','Callback',@merge_fix);
            set(EB_Split,'Enable','On','Callback',@split_fix);
            fixselected = intersect(find(tempdata{val_sub==subslist}{val_tri}.fixend >= brushed.begin),find(tempdata{val_sub==subslist}{val_tri}.fixbegin <= brushed.end));
            plot_fixations(fixselected)
            if length(fixselected)==1
                set(FineMMM,'Enable','On'); set(FineM,'Enable','On'); set(FineP,'Enable','On'); set(FinePPP,'Enable','On');
                set(FineMMM,'Callback',{@edge_edit,1,fixselected}); set(FineM,'Callback',{@edge_edit,0,fixselected});
                set(FineP,'Callback',{@edge_edit,2,fixselected}); set(FinePPP,'Callback',{@edge_edit,3,fixselected});
            else
                set(FineMMM,'Enable','Off'); set(FineM,'Enable','Off'); set(FineP,'Enable','Off'); set(FinePPP,'Enable','Off');
                set(FineMMM,'Callback',[]); set(FineM,'Callback',[]); set(FineP,'Callback',[]); set(FinePPP,'Callback',[]);
            end
        else
            brushed = [];
            fixselected = [];
            set(EB_New,'Enable','On','Callback',[]);
            set(EB_Delete,'Enable','On','Callback',[]);
            set(EB_Merge,'Enable','On','Callback',[]);
            set(EB_Split,'Enable','On','Callback',[]);
            set(FineMMM,'Enable','Off'); set(FineM,'Enable','Off'); set(FineP,'Enable','Off'); set(FinePPP,'Enable','Off');
            set(FineMMM,'Callback',[]); set(FineM,'Callback',[]); set(FineP,'Callback',[]); set(FinePPP,'Callback',[]);
            plot_fixations([])
        end
        hManager = uigetmodemanager(gcf);
        if mlVer < 2014
          set(hManager.WindowListenerHandles,'Enable','Off')
        else
          hmWlElen = length(hManager.WindowListenerHandles);
          for eee = 1:hmWlElen
            hManager.WindowListenerHandles(eee).Enabled = 0;
          end
        end
        set(FixDetWin,'WindowKeyPressFcn',@key_switch)
    end

    function brush_end(~,~)
        disp('hi')
        brush off
    end

    function brushes_update(indices)
        brushothers = findobj(FixDetWin,'DisplayName','Y-Gaze','-or','DisplayName','X-Gaze','-or','DisplayName','Velocity (scaled)');
        newbd = zeros(1,length(get(brushothers(1),'BrushData')));
        newbd(indices) = 1;
        for brushes = 1:3
            set(brushothers(brushes),'BrushData',newbd)
        end
        xdata = get(brushothers(1),'XData');
        brushed.indices = xdata(indices);
        brushed.begin = brushed.indices(1);
        brushed.end = brushed.indices(end);
    end

    function new_fix(~,~)
        if ~isempty(brushed)
            issaved = 0;
            newfixnum = find(tempdata{val_sub==subslist}{val_tri}.fixbegin < brushed.begin,1,'last')+1;
            nextfixbegin = inf;
            if isempty(newfixnum)
                newfixnum = 1;
                lastfixend = 0;
            else
                lastfixend = tempdata{val_sub==subslist}{val_tri}.fixend(newfixnum-1);
                if newfixnum <= length(tempdata{val_sub==subslist}{val_tri}.fixbegin)
                    nextfixbegin = tempdata{val_sub==subslist}{val_tri}.fixbegin(newfixnum);
                end
            end
            if brushed.begin > lastfixend && brushed.end < nextfixbegin
                restoffixes = [tempdata{val_sub==subslist}{val_tri}.fixbegin(newfixnum:end);tempdata{val_sub==subslist}{val_tri}.fixend(newfixnum:end)];
                tempdata{val_sub==subslist}{val_tri}.fixbegin(newfixnum) = brushed.begin;
                tempdata{val_sub==subslist}{val_tri}.fixend(newfixnum) = brushed.end;
                if ~isempty(restoffixes)
                    tempdata{val_sub==subslist}{val_tri}.fixbegin(newfixnum+1:length(tempdata{val_sub==subslist}{val_tri}.fixbegin)+1) = restoffixes(1,:);
                    tempdata{val_sub==subslist}{val_tri}.fixend(newfixnum+1:length(tempdata{val_sub==subslist}{val_tri}.fixend)+1) = restoffixes(2,:);
                end
                tempdata{val_sub==subslist}{val_tri}.fixdurations = (tempdata{val_sub==subslist}{val_tri}.fixend - tempdata{val_sub==subslist}{val_tri}.fixbegin + 1) * (1000/subdata.SampleRate);
            end
        end
        set(FineMMM,'Enable','On'); set(FineM,'Enable','On'); set(FineP,'Enable','On'); set(FinePPP,'Enable','On');
        set(FineMMM,'Callback',{@edge_edit,1,newfixnum}); set(FineM,'Callback',{@edge_edit,0,newfixnum});
        set(FineP,'Callback',{@edge_edit,2,newfixnum}); set(FinePPP,'Callback',{@edge_edit,3,newfixnum});
        list_fix
        plot_fixations([])
    end

    function delete_fix(~,~)
        if ~isempty(brushed)
            issaved = 0;
            fixselected = intersect(find(tempdata{val_sub==subslist}{val_tri}.fixend >= brushed.begin),find(tempdata{val_sub==subslist}{val_tri}.fixbegin <= brushed.end));
            if ~isempty(fixselected)
                tempdata{val_sub==subslist}{val_tri}.fixbegin(fixselected) = [];
                tempdata{val_sub==subslist}{val_tri}.fixend(fixselected) = [];
                tempdata{val_sub==subslist}{val_tri}.fixdurations(fixselected) = [];
                list_fix
                plot_fixations([])
            end
        end
    end

    function merge_fix(~,~)
        if ~isempty(brushed)
            issaved = 0;
            fixselected = intersect(find(tempdata{val_sub==subslist}{val_tri}.fixend >= brushed.begin),find(tempdata{val_sub==subslist}{val_tri}.fixbegin <= brushed.end));
            newend = tempdata{val_sub==subslist}{val_tri}.fixend(fixselected(end));
            tempdata{val_sub==subslist}{val_tri}.fixbegin(fixselected(2:end)) = [];
            tempdata{val_sub==subslist}{val_tri}.fixend(fixselected(2:end)) = [];
            tempdata{val_sub==subslist}{val_tri}.fixend(fixselected(1)) = newend;
            tempdata{val_sub==subslist}{val_tri}.fixdurations = (tempdata{val_sub==subslist}{val_tri}.fixend - tempdata{val_sub==subslist}{val_tri}.fixbegin + 1) * (1000/subdata.SampleRate);
            list_fix
            plot_fixations([])
        end
    end
    function split_fix(~,~)
        if ~isempty(brushed)
            issaved = 0;
            if find(tempdata{val_sub==subslist}{val_tri}.fixbegin <= brushed.begin,1,'last') == find(tempdata{val_sub==subslist}{val_tri}.fixend >= brushed.end,1,'first')
                fixselected = find(tempdata{val_sub==subslist}{val_tri}.fixbegin <= brushed.begin,1,'last');
                restoffixes = [tempdata{val_sub==subslist}{val_tri}.fixbegin(fixselected+1:end);tempdata{val_sub==subslist}{val_tri}.fixend(fixselected+1:end)];
                tempdata{val_sub==subslist}{val_tri}.fixbegin(fixselected+1) = brushed.end;
                tempdata{val_sub==subslist}{val_tri}.fixend(fixselected+1) = tempdata{val_sub==subslist}{val_tri}.fixend(fixselected);
                tempdata{val_sub==subslist}{val_tri}.fixend(fixselected) = brushed.begin;
                if ~isempty(restoffixes)
                    tempdata{val_sub==subslist}{val_tri}.fixbegin(fixselected+2:length(tempdata{val_sub==subslist}{val_tri}.fixbegin)+1) = restoffixes(1,:);
                    tempdata{val_sub==subslist}{val_tri}.fixend(fixselected+2:length(tempdata{val_sub==subslist}{val_tri}.fixend)+1) = restoffixes(2,:);
                end
                tempdata{val_sub==subslist}{val_tri}.fixdurations = (tempdata{val_sub==subslist}{val_tri}.fixend - tempdata{val_sub==subslist}{val_tri}.fixbegin + 1) * (1000/subdata.SampleRate);
                list_fix
                plot_fixations([])
            end
        end
    end

%% Edge editing functions
    function edge_select(~,eventdata)
        curr_edge = get(eventdata.NewValue,'UserData');
    end

    function edge_size(source,~)
        curr_len = str2double(get(source,'String'));
    end

    function edge_edit(~,~,sname,efix)
        brushed.indices = tempdata{val_sub==subslist}{val_tri}.fixbegin(efix):tempdata{val_sub==subslist}{val_tri}.fixend(efix);
        try
            if sname == 0 || sname == 2
                mult = 1;
            else
                mult = curr_len;
            end
            el = mult * curr_edge * sign(2*curr_edge + 1) * -1 * sign(2*sname - 3);
            erbx = [];
            switch curr_edge
                case 1
                    if efix > 1
                        if tempdata{val_sub==subslist}{val_tri}.fixbegin(efix) + el > tempdata{val_sub==subslist}{val_tri}.fixend(efix-1)
                            tempdata{val_sub==subslist}{val_tri}.fixbegin(efix) = ...
                                tempdata{val_sub==subslist}{val_tri}.fixbegin(efix) + el;
                        else
                            erbx = errordlg('Cannot extend this fixation into an existing fixation. Use ''Merge Fixations'' instead',...
                                'Cannot Edit Fixation');
                            set(FineMMM,'Enable','Off'); set(FineM,'Enable','Off'); set(FineP,'Enable','Off'); set(FinePPP,'Enable','Off');
                            set(FineMMM,'Callback',[]); set(FineM,'Callback',[]); set(FineP,'Callback',[]); set(FinePPP,'Callback',[]);
                        end
                    else
                        if tempdata{val_sub==subslist}{val_tri}.fixbegin(efix) + el > 1
                            tempdata{val_sub==subslist}{val_tri}.fixbegin(efix) = ...
                                tempdata{val_sub==subslist}{val_tri}.fixbegin(efix) + el;
                        else
                            erbx = errordlg('Cannot extend this fixation beyond time 0',...
                                'Cannot Edit Fixation');
                            set(FineMMM,'Enable','Off'); set(FineM,'Enable','Off'); set(FineP,'Enable','Off'); set(FinePPP,'Enable','Off');
                            set(FineMMM,'Callback',[]); set(FineM,'Callback',[]); set(FineP,'Callback',[]); set(FinePPP,'Callback',[]);
                        end
                    end
                case -1
                    el = -1* el;
                    if efix < length(tempdata{val_sub==subslist}{val_tri}.fixbegin)
                        if tempdata{val_sub==subslist}{val_tri}.fixend(efix) + el < tempdata{val_sub==subslist}{val_tri}.fixbegin(efix+1)
                            tempdata{val_sub==subslist}{val_tri}.fixend(efix) = ...
                                tempdata{val_sub==subslist}{val_tri}.fixend(efix) + el;
                        else
                            erbx = errordlg('Cannot extend this fixation into an existing fixation. Use ''Merge Fixations'' instead',...
                                'Cannot Edit Fixation');
                            set(FineMMM,'Enable','Off'); set(FineM,'Enable','Off'); set(FineP,'Enable','Off'); set(FinePPP,'Enable','Off');
                            set(FineMMM,'Callback',[]); set(FineM,'Callback',[]); set(FineP,'Callback',[]); set(FinePPP,'Callback',[]);
                        end
                    else
                        if tempdata{val_sub==subslist}{val_tri}.fixbegin(efix) + el < length(data.PlotX)
                            tempdata{val_sub==subslist}{val_tri}.fixend(efix) = ...
                                tempdata{val_sub==subslist}{val_tri}.fixend(efix) + el;
                        else
                            erbx = errordlg('Cannot extend this fixation beyond end of trial',...
                                'Cannot Edit Fixation');
                            set(FineMMM,'Enable','Off'); set(FineM,'Enable','Off'); set(FineP,'Enable','Off'); set(FinePPP,'Enable','Off');
                            set(FineMMM,'Callback',[]); set(FineM,'Callback',[]); set(FineP,'Callback',[]); set(FinePPP,'Callback',[]);
                        end
                    end
            end
        catch
            keyboard
        end
        waitfor(erbx)
        list_fix
        plot_fixations(efix)
        indices = find(tri_segs{seg_vis}==tempdata{val_sub==subslist}{val_tri}.fixbegin(efix)):...
            find(tri_segs{seg_vis}==tempdata{val_sub==subslist}{val_tri}.fixend(efix));
        brushes_update(indices)
    end


%% Menu Controls
    function pop_save(~,~)
        SaveFig = questdlg('Which fixations would you like to save?',...
            'Save Fixations',...
            'Only this Subject', 'All Subjects, All Trials', 'Cancel', 'Only this Subject');
        switch SaveFig
            case 'Only this Subject'
                gen_diag('Saving Only this Subject, please wait')
                subdata.Fixations = tempdata{val_sub==subslist};
                save(ETT.Subjects(val_sub).Data.Import,'subdata')
                issaved = 1;
                delete(diagfig)
            case 'All Subjects, All Trials'
                gen_diag('Saving All Subjects, please wait')
                for subn = subslist
                    subdata = load(ETT.Subjects(subn).Data.Import);
                    subdata = subdata.subdata;
                    subdata.Fixations = tempdata{subn==subslist};
                    save(ETT.Subjects(subn).Data.Import)
                    issaved = 1;
                end
                delete(diagfig)
            case 'Cancel'
                issaved = 0;
        end
    end

    function pop_reset(~,~)
        ResetFig = questdlg('Reset Fixations for: ',...
            'Reset Fixations',...
            'Only this Trial', 'Only this Subject', 'All Subjects, All Trials', 'Only this Trial');
        switch ResetFig
            case 'Only this Trial'                
                estim_fixations
                newdata = organize_fixations;
                tempdata{val_sub==subslist}{val_tri} = newdata{val_sub==subslist}{val_tri};
            case 'Only this Subject'
                gen_diag('Recalculating this Subject, please wait')
                estim_fixations
                delete(diagfig)
                newdata = organize_fixations;
                tempdata{val_sub==subslist} = newdata{val_sub==subslist};
            case 'All Subjects, All Trials'
                ConfirmDiag = questdlg('WARNING! This will erase all fixations for all the subjects listed here.  Are you sure you want to continue?',...
                    'Confirm Clear',...
                    'No','Yes','No');
                switch ConfirmDiag
                    case 'Yes'
                        gen_diag('Recalculating All Subjects, please wait')
                        tempdata = cell(1,length(subslist));
                        delete(diagfig)
                end
        end
        list_fix
        disp_trial
        issaved = 0;
    end

    function pop_quit(~,~)
        if ~issaved
            DiagFig = questdlg('Fixations not saved.  Would you like to save now?',...
                'Quit Fixation Detection',...
                'Yes','No','Yes');
            switch DiagFig
                case 'Yes'
                    pop_save
            end
        end
        close(FixDetWin)
    end

    function gen_diag(in_str)
        diagfig=dialog('Color',[.7 .8 .7], 'Name', 'Please Wait','Position',[1200 498.75 200 100],'CloseRequestFcn','','Visible','On');
        uicontrol('Style','Text','Parent',diagfig,'String',in_str,'BackgroundColor',[.7 .8 .7],'FontSize',14,...
            'Position',[5 10 190 80])       
        pause(.1)
    end
        

%% Keyboard shortcuts
    function key_switch(obj,data)
%         disp('key')
        if ~isempty(data.Key)
%             ks = data.Key
            mood = data.Modifier;
            ks = data.Character;
            switch ks
                case 'b'
                    brush on
                case 'n'
                    new_fix
                case 'm'
                    merge_fix
                case 'd'
                    delete_fix
                case 's'
                    split_fix
                case 'q'
                    curr_edge = 1;
                    set(edge_right ,'Value',0)
                    set(edge_left ,'Value',1)
                case 'e'
                    curr_edge = -1;
                    set(edge_left ,'Value',0)
                    set(edge_right ,'Value',1)
                case {'-','+'}
                    if strcmp(get(FineMMM,'Enable'),'on')
                        if strcmp(ks,'+')
                            editnum = 2;
                        else
                            editnum = 0;
                        end
                        if ~isempty(mood)
                            editnum = editnum + 1;                                                       
                        end
%                         disp('now editing')
                        edge_edit([],[],editnum,fixselected)
                    end
                    
            end
        end
    end


% waitfor(FixDetWin)

end