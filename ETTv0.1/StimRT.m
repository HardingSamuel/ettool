function [inStim, inTarget, RT] = StimRT(x,y,d,t,WhatsOn,tside, sr)
% OnStim
% 
% Detect if gaze landed in Stimulus AOI within the correct timeframe
% keyboard
%When the stim appears
StimAppear = find(strcmp(WhatsOn.Names, 'PointStim'));
StimAppear = WhatsOn.Indices(StimAppear);

TargetAppear = find(strcmp(WhatsOn.Names, 'AnimatedProbe'));
TargetAppear = WhatsOn.Indices(TargetAppear);

TrialEnd = length(t);

if strcmp(tside, 'Left')
    tx = 125;
else
    tx = 1795;
end

ty = 540;

StimAOI.UL.X = 704; StimAOI.UL.Y = 0;
StimAOI.LR.X = 1216; StimAOI.LR.Y = 1080;

TargAOI.UL.X = tx - 125; TargAOI.UL.Y = ty-200;
TargAOI.LR.X = tx + 125; TargAOI.LR.Y = ty+200;

%Determine if landed in Stim
xstim = x(StimAppear:TargetAppear-1);
ystim = y(StimAppear:TargetAppear-1);
tstim = t(StimAppear:TargetAppear-1);

Stim.in = find( xstim >= StimAOI.UL.X & xstim <= StimAOI.LR.X & ystim >= StimAOI.UL.Y & ystim <= StimAOI.LR.Y); %All points inside the stimulus
Stim.out = 1:length(xstim); Stim.out(Stim.in) = []; %All points outside the stimulus
if ~isempty(Stim.in)
    Stim.enter = [Stim.in(1), Stim.in(find(diff(Stim.in)>3) + 1)]; %indices of entering
    Stim.leave = [Stim.in(diff(Stim.in)>3), Stim.in(end)]; %indices of last point inside
    Stim.duration = Stim.leave - Stim.enter + 1; %leave - enter
    Stim.duration(2,:) = Stim.duration(1,:) * sr; %leave - enter * time

    
if t(TargetAppear+1) - tstim(Stim.enter(Stim.duration(2,:) == max(Stim.duration(2,:)))) < 1000
    inStim = 1; %E-Prime appears to have detected it    
    if  max(Stim.duration(2,:)) >=75 
        inStim = [1,1]; %we also see it
    else
        inStim = [1,0]; % we disagree
    end
else
    inStim = 0; %prime didn't see it
    if  max(Stim.duration(2,:)) >=75 
        inStim = [inStim,1]; %we did though
    else
        inStim = [inStim, 0]; %we didn't either
    end
end
stimELAP = [num2str([t(TargetAppear+1) - tstim(Stim.enter(Stim.duration(2,:) == max(Stim.duration(2,:))))]), ',', num2str([max(Stim.duration(2,:))])];
else
    inStim = [0,0];
    stimELAP = 'NA';
end

xtarg = x(TargetAppear:TrialEnd);
ytarg = y(TargetAppear:TrialEnd);
ttarg = t(TargetAppear:TrialEnd);

Targ.in = find( xtarg >= TargAOI.UL.X & xtarg <= TargAOI.LR.X & ytarg >= TargAOI.UL.Y & ytarg <= TargAOI.LR.Y); 
Targ.out = 1:length(xtarg); Targ.out(Targ.in) = [];
if ~isempty(Targ.in)
    Targ.enter = [Targ.in(1), Targ.in(find(diff(Targ.in)>3) + 1)];
    Targ.leave = [Targ.in(diff(Targ.in) >3), Targ.in(end)];
    Targ.duration = Targ.leave - Targ.enter + 1;
    Targ.duration(2,:) = Targ.duration(1,:) * sr;
    
if t(TrialEnd) - ttarg(Targ.enter(Targ.duration(2,:) == max(Targ.duration(2,:)))) < 4000
    inTarget = 1; %E-Prime appears to have detected it    
    if  max(Targ.duration(2,:)) >=200 
        inTarget = [1,1]; %we also see it
    else
        inTarget = [1,0]; % we disagree
    end
else
    inTarget = 0; %prime didn't see it
    if  max(Targ.duration(2,:)) >=200
        inTarget = [inTarget,1]; %we did though
    else
        inTarget = [inTarget, 0]; %we didn't either
    end
end
RT = ttarg(Targ.in(1)) - ttarg(1);
targELAP = [num2str([t(TrialEnd) - ttarg(Targ.enter(Targ.duration(2,:) == max(Targ.duration(2,:))))]), ',', num2str([max(Targ.duration(2,:))])];
else
    inTarget = [0,0];
    RT = NaN;
    targELAP = 'NA';
end



% % keyboard
% 
% figure('Position', [1 41 1920 964])
% plot(xstim,ystim,'o')
% hold on
% axis([0 1920 0 1080])
% rectangle('Position', [690 360 1230-690 1080-360])
% axis ij
% 
% title([num2str(inStim), ' (', stimELAP, ')   ', num2str(inTarget), ' (', targELAP, ')   ', num2str(RT)]) 
% 
% plot(xtarg,ytarg,'go')
% rectangle('Position', [TargAOI.UL.X 340 250 400])
% 
% 
% 
% pause
% close all
return
