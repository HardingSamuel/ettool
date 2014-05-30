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
seg_vis = 1; seg_sizeT = 3000; seg_sizeP = []; fixdetset = ETT.Config.FixDetect; preprocset = ETT.Config.PreProcess;

xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
plot_interp = []; plot_blink = []; plot_missing = []; text_phase = cell(2,0); hlx = []; hly = [];
fixinfo = []; plot_fix = []; text_fix = []; velo = []; pix_deg = []; orgfix = [];

text_tint = []; text_tbli = []; text_tgap  = [];

FixDetWin = figure('Position',[740 197.5 1120 702.5],'Menubar','none','Toolbar','Figure','NumberTitle','Off','Color',[.65 .75 .65],...
    'Name','Fixation Detection');
Sel_Sub = uipanel('Title', ['Subject: ' text_sub], 'Units', 'Pixels', 'Position', [640 645 290 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Sel_Tri = uipanel('Title', ['Trial: ' text_tri], 'Units', 'Pixels', 'Position', [640 590 290 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
Sel_Seg = uipanel('Title', ['Trial Segment: ' num2str(seg_vis), '/1'], 'Units', 'Pixels', 'Position', [640 535 180 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uipanel('Title', 'Length(ms):', 'Units', 'Pixels', 'Position', [825 535 105 50],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);

Slide_Sub = uicontrol('Style','Slider','Min',1,'Max',length(subslist),...
    'Value',1,'SliderStep',[1/(length(subslist)-1), 1/(length(subslist)-1)],...
    'Position',[650 652.5 210 20],'Callback',@slide_sub);
uicontrol('Style','PushButton','String','Load','Position',[870 650 50 27.5],...
    'BackgroundColor',[.8 .8 .8],'Callback',@loadsub);
Slide_Tri = uicontrol('Style','Slider','Min',1,'Max',99,...
    'Value',1,'SliderStep',[1/(length(subslist)-1), 1/(length(subslist)-1)],...
    'Position',[650 597.5 270 20],'Callback',@slide_tri,'Enable','Off');

GazeAxes = axes('Parent',FixDetWin,'Units','Pixels','Position',[60 50 870 440],...
    'ylim',[0 1],'xlim',[0 1000],'NextPlot','Add');
GazeText = text(400, .5, 'Load data from Subject to Continue');

ylabel('Relative Gaze Position','BackgroundColor',[.7 .8 .7])
xlabel('Trial Time','BackgroundColor',[.7 .8 .7])

TagAxes = axes('Parent',FixDetWin,'Units','Pixels','Position',[60 492 870 40],...
    'NextPlot','Add','xticklabel','','yticklabel','','xtick',[],'ytick',[],...
    'ylim',[0 1]);

linkaxes([GazeAxes,TagAxes],'x')
set(zoom(GazeAxes),'ActionPostCallback',@fix_x); set(zoom(TagAxes),'ActionPostCallback',@fix_x);
set(pan(FixDetWin),'ActionPostCallback',@fix_x)

Scroll_Right = uicontrol('Style','PushButton','String','>>>','Parent',FixDetWin,...
    'Position',[735 540 75 25],'Backgroundcolor',[.8 .8 .8],'Enable','Off',...
    'Callback',@scroll_right);
Scroll_Left = uicontrol('Style','PushButton','String','<<<','Parent',FixDetWin,...
    'Position',[650 540 75 25],'Backgroundcolor',[.8 .8 .8],'Enable','Off',...
    'Callback',@scroll_left);
WinSize = uicontrol('Style','Edit','Enable','Off','String','3000',...
    'Position',[835 540 85 25],'FontSize',12,'Callback',@disp_trial_gui);

PreSumm = uicontrol('Style','Text','Parent',FixDetWin,'Position',[110 645 290 40],'String',...
    '','CreateFcn',@pre_text,'BackgroundColor',[.7 .8 .7]);
PreEdit = uicontrol('Style','PushButton','String','Edit','Parent',FixDetWin,...
    'Position',[60 645 40 40],'BackgroundColor',[.8 .8 .8],'Callback',@pre_edit,'Enable','Off');
FixSumm = uicontrol('Style','Text','Parent',FixDetWin,'Position',[110 590 290 40],'String',...
    '','CreateFcn',@fix_text,'BackgroundColor',[.7 .8 .7]);
FixEdit = uicontrol('Style','PushButton','String','Edit','Parent',FixDetWin,...
    'Position',[60 590 40 40],'BackgroundColor',[.8 .8 .8],'Callback',@fix_edit,'Enable','Off');

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

EB_New = uicontrol('Style','Pushbutton','String','New Fixation','BackgroundColor',[.8 .8 .8],...
    'Position',[60 542 77.5 38],'Enable','Off','Callback',@new_fix);
EB_Delete = uicontrol('Style','Pushbutton','String','Delete Fixation','BackgroundColor',[.8 .8 .8],...
    'Position',[147.5 542 77.5 38],'Enable','Off','Callback',@delete_fix);
EB_Merge = uicontrol('Style','Pushbutton','String','Merge Fixations','BackgroundColor',[.8 .8 .8],...
    'Position',[235 542 77.5 38],'Enable','Off','Callback',@merge_fix);
EB_Split = uicontrol('Style','Pushbutton','String','Split Fixations','BackgroundColor',[.8 .8 .8],...
    'Position',[322.5 542 77.5 38],'Enable','Off','Callback',@split_fix);


fixbrush = brush(FixDetWin); set(brush,'ActionPostCallback',@fix_brush)

    function fix_x(~,~)
        xticks = get(GazeAxes,'xtick');        
        set(GazeAxes,'xticklabel',(1000/subdata.SampleRate)*xticks)
        set(TagAxes,'ylim',[0 1])
    end

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
        cla(GazeAxes); cla(TagAxes);
        xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
        plot_interp = []; plot_blink = []; plot_missing = []; text_phase = cell(2,0);
        hlx = []; hly = [];
        fixinfo = []; plot_fix = []; text_fix = []; velo = []; pix_deg = [];
        orgfix = [];
        
        set(WinSize,'Enable','On')
        set(Slide_Tri,'Value',1);
        set(Sel_Tri,'Title', ['Trial: 1']);
        subdata = load(ETT.Subjects(val_sub).Data.Import);
        subdata = subdata.subdata;
        set(Slide_Tri','Enable','On')
        val_maxtri = size(subdata.TrialLengths,1);
        val_tri = 1;
        seg_sizeP = fix(str2num(get(WinSize,'String'))/(1000/subdata.SampleRate));
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
        calc_velo
        estim_fixations
        disp_trial
    end

    function disp_trial_gui(~,~)        
        seg_sizeP = fix(str2num(get(WinSize,'String'))/(1000/subdata.SampleRate));
        disp_trial
    end

    function disp_trial
        cla(GazeAxes); cla(TagAxes);
        xplot = []; yplot = []; vplot = []; vtext = []; vthresh = [];
        plot_interp = []; plot_blink = []; plot_missing = []; text_phase = cell(2,0);
        hlx = []; hly = []; plot_fix = []; text_fix = [];
        
        text_tint = []; text_tbli = []; text_tgap  = [];        
        trilen = size(subdata.Filtered.FiltX,2);
        tri_segs = cell(0,0);        
        if trilen > seg_sizeP
            for trispl = 1:ceil(trilen/(1.25*seg_sizeP))
                tri_segs{trispl} = fix([.75*seg_sizeP*(trispl-1)+1:.75*seg_sizeP*(trispl-1)+seg_sizeP+1]);
            end
            set(Scroll_Right,'Enable','On');
        else
            set(Scroll_Right,'Enable','Off');
        end
        seg_vis = 1;
        set(Scroll_Left,'Enable','Off');
        set(Sel_Seg,'Title', ['Trial Segment: ' num2str(seg_vis), '/' num2str(length(tri_segs))])
        scroll_trial
        tag_phases                
        organize_fixations
        list_fix
        plot_fixations
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
        xplot = plot(GazeAxes,tri_segs{seg_vis},subdata.Filtered.FiltX(val_tri,tri_segs{seg_vis}),'k');
        yplot = plot(GazeAxes,tri_segs{seg_vis},1-subdata.Filtered.FiltY(val_tri,tri_segs{seg_vis}),'r') ;
        
        plot_velo
        legend([xplot,yplot,vplot],'X-Gaze','Y-Gaze','Velocity (scaled)','location','northeast');
        
        axes(GazeAxes)
        set(GazeAxes,'xlim',[tri_segs{seg_vis}(1), tri_segs{seg_vis}(end)])
        xticks = get(GazeAxes,'xtick');        
        set(GazeAxes,'xticklabel',(1000/subdata.SampleRate)*xticks)
        tag_pre        
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

    function plot_velo 
        delete(vplot);delete(vthresh);delete(vtext);
        velo_t = velo(val_tri,:);        
        vplot = plot(GazeAxes,tri_segs{seg_vis},velo_t(tri_segs{seg_vis}) * .3/500,'b');        
        vthresh = plot(GazeAxes,tri_segs{seg_vis},repmat(fixdetset{1}*.3/500,1,seg_sizeP+1));
        axes(GazeAxes)
        vtext = text(tri_segs{seg_vis}(10),(fixdetset{1}*.3/500)+.025,[num2str(fixdetset{1}) 'deg/sec'],'color',[0 0 1]);
    end

    function pre_text(obj,~)
        filtnames = [{'Savitzky�Golay'},{'Bilateral'},{'Moving Average'},{'Low-Pass'}];
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
            subdata = data_interp(subdata,preprocset);
            subdata = data_filter(subdata,preprocset);
            pre_text
            calc_velo
            estim_fixations
            disp_trial
        end
        set(PreEdit,'Enable','On')
    end

    function fix_edit(~,~)
        set(FixEdit,'Enable','Off')
        NewSettings = sett_FixDetect(ETT,1,fixdetset);
        if ~all(cellfun(@isequal, NewSettings, fixdetset)) && ~any(cellfun(@isempty,NewSettings))
            fixdetset = NewSettings;
            fix_text
            calc_velo
            estim_fixations
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
        [fixinfo] = fix_hmm(velo,fixinfo,fixdetset,fixinfo.ivtclean.states,subdata.SampleRate);
        [fixinfo.hmmclean] = fix_rejectfix(fixinfo.hmm,floor(fixdetset{2}/(1000/subdata.SampleRate)));
        organize_fixations
    end

    function organize_fixations
        orgfix.begin = find(fixinfo.hmmclean.fixbegin(val_tri,:));
        orgfix.end = find(fixinfo.hmmclean.fixend(val_tri,:));
        orgfix.duration = (orgfix.end - orgfix.begin + 1) * (1000/subdata.SampleRate);
        list_fix
    end
        
    function list_fix        
        numbox = cellstr(num2str((1:length(orgfix.begin))'));
        strbox = cellstr(num2str(orgfix.begin'));
        endbox = cellstr(num2str(orgfix.end'));
        durbox = cellstr(num2str(fix(orgfix.duration')));
        set(FixSumList_No,'String',numbox)
        set(FixSumList_Str,'String',strbox)
        set(FixSumList_End,'String',endbox)
        set(FixSumList_Dur,'String',durbox)
    end

    function plot_fixations          
        delete(plot_fix); delete(text_fix)
        axes(TagAxes)
        try
        plot_fix = line([find(fixinfo.hmmclean.fixbegin(val_tri,:));find(fixinfo.hmmclean.fixend(val_tri,:))],repmat(.2,2,length(find(fixinfo.hmmclean.fixend(val_tri,:)))),'linewidth',5,'Color',[0 1 0]);        
        text_fix = text(orgfix.begin + (orgfix.end - orgfix.begin)/2,repmat(.2,1,length(orgfix.begin)),cellstr(num2str((1:length(orgfix.begin))')),'HorizontalAlignment','Center');        
        catch
            error('Number of fixation beginnings and ends does not line up')
        end
    end

    function fix_brush(~,~)        
        Handle = findobj(gcf,'-property','BrushData');
        for i = 1:length(Handle)
            CH = get(Handle(i));
            CH.DisplayName
            if strcmp(CH.DisplayName,'X-Gaze') || strcmp(CH.DisplayName,'Y-Gaze')
                if ~all(CH.BrushData == 0)                    
                    break
                end
            end
        end
        if ~all(CH.BrushData == 0)
            brushed.indices = CH.XData(CH.BrushData==1)
            brushed.begin = brushed.indices(1)
            brushed.end = brushed.indices(end)
        else
            brushed = [];
        end
        
        set(EB_New,'Enable','On')
        set(EB_Delete,'Enable','On')
        set(EB_Merge,'Enable','On')
        set(EB_Split,'Enable','On')
        
        function new_fix
        end
        function delete_fix
        end
        function merge_fix
        end
        function split_fix
        end
        
    end

waitfor(FixDetWin)

end