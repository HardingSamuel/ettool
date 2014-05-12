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
%   [SH] - 05/08/14:    v1 - Creation

%%
try
    close(gcf)
end
subdata = []; trilist = []; tri_segs = cell(0,0);
text_sub = num2str(subslist(1)); val_sub = subslist(1);
text_tri = '1'; val_tri = 1; val_maxtri = 99;
seg_vis = 1; fixdetset = ETT.Config.FixDetect; preprocset = ETT.Config.PreProcess;

xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
plot_interp = []; plot_blink = []; text_phase = cell(2,0); hlx = []; hly = [];

FixDetWin = figure('Position',[740 197.5 960 702.5],'Menubar','Figure','NumberTitle','Off','Color',[.65 .75 .65],...
    'Name','Fixation Detection');
Sel_Sub = uipanel('Title', ['Subject: ' text_sub], 'Units', 'Pixels', 'Position', [640 645 290 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Sel_Tri = uipanel('Title', ['Trial: ' text_tri], 'Units', 'Pixels', 'Position', [640 590 290 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Sel_Seg = uipanel('Title', ['Trial Segment: ' num2str(seg_vis), '/1'], 'Units', 'Pixels', 'Position', [640 535 290 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

Slide_Sub = uicontrol('Style','Slider','Min',1,'Max',length(subslist),...
    'Value',1,'SliderStep',[1/(length(subslist)-1), 1/(length(subslist)-1)],...
    'Position',[650 652.5 210 20],'Callback',@slide_sub);
uicontrol('Style','PushButton','String','Load','Position',[870 650 50 27.5],...
    'BackgroundColor',[.8 .8 .8],'Callback',@loadsub);
Slide_Tri = uicontrol('Style','Slider','Min',1,'Max',99,...
    'Value',1,'SliderStep',[1/(length(subslist)-1), 1/(length(subslist)-1)],...
    'Position',[650 597.5 270 20],'Callback',@slide_tri,'Enable','Off');

GazeWin = axes('Parent',FixDetWin,'Units','Pixels','Position',[60 50 870 440],...
    'ylim',[0 1],'xlim',[0 1000],'NextPlot','Add');
GazeText = text(400, .5, 'Load data from Subject to Continue');

ylabel('Relative Gaze Position','BackgroundColor',[.7 .8 .7])
xlabel('Trial Time','BackgroundColor',[.7 .8 .7])

TagWin = axes('Parent',FixDetWin,'Units','Pixels','Position',[60 492 870 40],...
    'NextPlot','Add','xticklabel','','yticklabel','','xtick',[],'ytick',[],...
    'ylim',[0 1]);

linkaxes([GazeWin,TagWin],'x')

Scroll_Right = uicontrol('Style','PushButton','String','>>>','Parent',FixDetWin,...
    'Position',[820 540 100 25],'Backgroundcolor',[.8 .8 .8],'Enable','Off',...
    'Callback',@scroll_right);

Scroll_Left = uicontrol('Style','PushButton','String','<<<','Parent',FixDetWin,...
    'Position',[650 540 100 25],'Backgroundcolor',[.8 .8 .8],'Enable','Off',...
    'Callback',@scroll_left);

PreSumm = uicontrol('Style','Text','Parent',FixDetWin,'Position',[110 645 290 40],'String',...
    '','CreateFcn',@pre_text,'BackgroundColor',[.7 .8 .7]);
PreEdit = uicontrol('Style','PushButton','String','Edit','Parent',FixDetWin,...
    'Position',[60 645 40 40],'BackgroundColor',[.8 .8 .8],'Callback',@pre_edit,'Enable','Off');
FixSumm = uicontrol('Style','Text','Parent',FixDetWin,'Position',[110 590 290 40],'String',...
    '','CreateFcn',@fix_text,'BackgroundColor',[.7 .8 .7]);
FixEdit = uicontrol('Style','PushButton','String','Edit','Parent',FixDetWin,...
    'Position',[60 590 40 40],'BackgroundColor',[.8 .8 .8],'Callback',@fix_edit,'Enable','Off');



    function slide_sub(~,~)
        text_sub = num2str(subslist(fix(get(Slide_Sub,'Value'))));
        val_sub = str2num(text_sub);
        set(Sel_Sub,'Title',['Subject: ' text_sub])
    end

    function slide_tri(~,~)
        text_tri = num2str(trilist(fix(get(Slide_Tri,'Value'))));
        val_tri = str2num(text_tri);
        set(Sel_Tri,'Title',['Trial: ' text_tri])
        disp_trial
    end

    function loadsub(~,~)
        cla(GazeWin); cla(TagWin);
        xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
        plot_interp = []; plot_blink = []; text_phase = cell(2,0);
        hlx = []; hly = [];
        
        set(Slide_Tri,'Value',1);
        set(Sel_Tri,'Title', ['Trial: 1']);
        subdata = load(ETT.Subjects(val_sub).Data.Import);
        subdata = subdata.subdata;
        set(Slide_Tri','Enable','On')
        val_maxtri = size(subdata.TrialLengths,1);
        val_tri = 1;
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
        set(PreEdit,'Enable','On'); set(FixEdit,'Enable','On')
        disp_trial
    end

    function disp_trial(~,~)
        cla(GazeWin); cla(TagWin);
        xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
        plot_interp = []; plot_blink = []; text_phase = cell(2,0);
        hlx = []; hly = [];
        
        trilen = size(subdata.Filtered.FiltX,2);
        tri_segs = cell(0,0);
        if trilen > 1000
            for trispl = 1:ceil(trilen/1250)
                tri_segs{trispl} = [750*(trispl-1)+1:750*(trispl-1)+1001];
            end
            set(Scroll_Right,'Enable','On'); set(Scroll_Left,'Enable','On');
        else
            set(Scroll_Right,'Enable','Off'); set(Scroll_Left,'Enable','Off');
        end
        seg_vis = 1;
        set(Sel_Seg,'Title', ['Trial Segment: ' num2str(seg_vis), '/' num2str(length(tri_segs))])
        scroll_trial
        tag_phases
    end

    function scroll_right(~,~)
        seg_vis = min(seg_vis+1,length(tri_segs));
        set(Sel_Seg,'Title',['Trial Segment: ' num2str(seg_vis), '/' num2str(length(tri_segs))])
        scroll_trial
    end

    function scroll_left(~,~)
        seg_vis = max(seg_vis-1,1);
        set(Sel_Seg,'Title',['Trial Segment: ' num2str(seg_vis), '/' num2str(length(tri_segs))])
        scroll_trial
    end

    function scroll_trial
        delete(xplot);delete(yplot);
        xplot = plot(GazeWin,tri_segs{seg_vis},subdata.Filtered.FiltX(val_tri,tri_segs{seg_vis}),'k');
        yplot = plot(GazeWin,tri_segs{seg_vis},1-subdata.Filtered.FiltY(val_tri,tri_segs{seg_vis}),'r') ;
        
        calc_velo
        leg1 = legend([xplot,yplot,vplot],'X-Gaze','Y-Gaze','Velocity (scaled)','location','northeast');
        
        axes(GazeWin)
        set(GazeWin,'xlim',[tri_segs{seg_vis}(1), tri_segs{seg_vis}(end)])
        xticks = get(GazeWin,'xtick');
        set(GazeWin,'xticklabel',(1000/subdata.SampleRate)*xticks)
        tag_pre
    end

    function calc_velo
        delete(vplot);delete(vthresh);delete(vtext);
        dist = subdata.Filtered.FiltD(val_tri,:);
        x = subdata.Filtered.FiltX(val_tri,:) * ETT.ScreenDim.PixX;
        y = subdata.Filtered.FiltY(val_tri,:) * ETT.ScreenDim.PixY;
        pix_deg = dist * (ETT.ScreenDim.PixX/ETT.ScreenDim.Width);
        xy = sqrt(diff(x).^2 + diff(y).^2); %linear distance from origin (0,0):  screen UL corner
        velo = (atand((xy/2)./(pix_deg(1:end-1)))*2)*subdata.SampleRate;
        velo = cat(2,velo,velo(end));
        vplot = plot(GazeWin,tri_segs{seg_vis},velo(tri_segs{seg_vis}) * .3/500,'b');
        vthresh = plot(GazeWin,tri_segs{seg_vis},repmat(fixdetset{1}*.3/500,1,1001));
        axes(GazeWin)
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
        NewSettings = sett_PreProcess(ETT,1,preprocset);
        if ~all(NewSettings == preprocset) && ~isempty(NewSettings)
            preprocset = NewSettings;
            subdata = data_interp(subdata,preprocset);
            tag_pre
            pre_text
        end
    end

    function fix_edit(~,~)
        NewSettings = sett_FixDetect(ETT,1,fixdetset);
        if ~all(cellfun(@isequal, NewSettings, fixdetset)) && ~any(cellfun(@isempty,NewSettings))
            fixdetset = NewSettings;
            fix_text
        end
    end

    function tag_pre
        delete(plot_interp); delete(plot_blink);
        delete(hlx); delete(hly);
        
        interp_begin = subdata.Interpolation.Indices{val_tri,1};
        interp_end = subdata.Interpolation.Indices{val_tri,2};
        blink_begin = subdata.Interpolation.Blinks{val_tri,1};
        blink_end = subdata.Interpolation.Blinks{val_tri,2};
        axes(TagWin)
        if length(interp_begin)>0
            plot_interp = line([interp_begin;interp_end],repmat(.90,2,length(interp_begin)),'linewidth',5,'Color',[0 1 0]);
            plot_blink = line([blink_begin;blink_end],repmat(.75,2,length(blink_begin)),'linewidth',5,'Color',[0 0 1]);
            for HL = 1:length(interp_begin)
                hlx = plot(GazeWin,interp_begin(HL):interp_end(HL),...
                    subdata.Filtered.FiltX(val_tri,interp_begin(HL):interp_end(HL)),'g','linewidth',2);
                hly = plot(GazeWin,interp_begin(HL):interp_end(HL),...
                    1-subdata.Filtered.FiltY(val_tri,interp_begin(HL):interp_end(HL)),'c','linewidth',2);
            end
        else
            plot_interp = []; plot_blink = []; hlx = []; hly = [];
        end
    end

    function tag_phases
        axes(GazeWin);
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

waitfor(FixDetWin)

end