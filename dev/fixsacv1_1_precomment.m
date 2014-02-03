function [fixinfo, sacinfo, pointinfo] = fixsac(x,y,d,sr,gapdata,fff)
%FixDetectDev
%
%Developing a procedure / algorithm to do fixation detection from raw ET
%data.
%   [SH] - 10/29/13:  for use in ETTool
%   [SH] - 10/31/13:  commenting
%% Deal with incoming gap information
% make new structure 'blink' containing information about blink beginnings
% and durations based on input 'gapdata,' defined as gapdata(1,2, ==2).
% See clean_interp for more info.
blink.begin = gapdata(1,gapdata(3,:)==2);
blink.duration = gapdata(2,gapdata(3,:)==2);
% make new struc 'other' where the gaps are not blinks but still need to be
% removed, rather than classified
other.begin = gapdata(1,gapdata(3,:)==3);
other.duration = gapdata(2,gapdata(3,:)==3);
% initialize empty array into which all points between a blink begin and
% end will be placed
blink_index = [];
% for each blink.begin, interpolate indices until blink.
for bfill = 1:length(blink.begin)
    blink_index = [blink_index, blink.begin(bfill):blink.begin(bfill) + blink.duration(bfill) - 1];
end
        
other_index = [];
for ofill = 1:length(other.begin)   
    other_index = [other_index, other.begin(ofill):other.begin(ofill) + other.duration(ofill) - 1];
end

%% Create new matrices without gaps

fx = x(~isnan(x));
fy = y(~isnan(y));
fd = d(~isnan(x));

gap_index = unique([blink_index, other_index]);



%% Original index -> new index conversion matrix
original_indices = 1:length(x);
new_indices = original_indices(find(~isnan(x)));


vthresh = 30; %velocity thresh %30 for adults / 50 for babies?
minsactime = 30; %sac duration thresh
minfixtime = 150; %fix duration thresh
minaccelspeed = 4000;
windowsize = 25; %for smoothing; should be odd to guarantee 0 phase (convolution); must be odd for sgolay
% sr = mean(diff(t)); %sampling rate
sr = 1000/sr;
pix_to_angle_const = 2202.9/583.84;
bin_velocities_by = 5; % to do velocity probability calculations.  smaller = more bins
% conf_threshold = .5; % how confident a new state selection must be to be considered real



if length(fx)< 400 | length(fy)< 400 | length(fd) < 400
%     disp('Not enough data')    
    fixinfo.nfix = [];
    fixinfo.durations = [];
    
    sacinfo.nsac = [];
    sacinfo.durations = [];
    
    pointinfo.initial = [];
    pointinfo.hmm = [];
    pointinfo.bayes = [];    
    return
end

switch fff 
    case 1
        fx = filtfilt(fir1(10,[0.1]), 1, x(~isnan(x)));
        fy = filtfilt(fir1(10,[0.1]), 1, y(~isnan(y)));
        fd = d(~isnan(x));
    case 0
%         buffer
        fx = x(~isnan(x)); fx = [repmat(fx(1), [1 floor(windowsize/2)]), fx, repmat(fx(end), [1 floor(windowsize/2)])];
        fy = y(~isnan(y)); fy = [repmat(fy(1), [1 floor(windowsize/2)]), fy, repmat(fy(end), [1 floor(windowsize/2)])];
        fd = d(~isnan(x)); fd = [repmat(fd(1), [1 floor(windowsize/2)]), fd, repmat(fd(end), [1 floor(windowsize/2)])];
%         filter
        fx = conv(fx, ones(1, windowsize), 'valid')/windowsize; %smoothed fx
        fy = conv(fy, ones(1, windowsize), 'valid')/windowsize; %smoothed fy
        fd = conv(fd, ones(1, windowsize), 'valid')/windowsize; %smoothed distance

        
    case 2
        
%         fx = x;
%         fy = y;
%         fd = d;
        
        fx = sgolayfilt(fx, 2, windowsize); 
        fy = sgolayfilt(fy, 2, windowsize);
        fd = sgolayfilt(fd, 2, windowsize);
end
     


% keyboard
%%



%(dx^2 + dy^2) ^.5 == change in pixels / point
xy = sqrt(fx.^2 + fy.^2); %euclidian distance
xyu = sqrt(x.^2 + y.^2); %euclidian distance UNFILTERED
dxy = sqrt(diff(fx).^2 + diff(fy).^2); %difference of xy
dxyu = sqrt(diff(x).^2 + diff(y).^2); %difference of xy
%smooth dxy, smooth distance
% xy = conv(xy, ones(1, windowsize), 'valid')/windowsize; %smoothed xy
% dxy = conv(dxy, ones(1,windowsize), 'valid')/windowsize; %smoothed difference of xy


%convert pixels/point to pixels/second based on distance and sample-rate
ds = (atand((dxy/2)./(fd(1:end-1)*pix_to_angle_const))*2)*1000/sr; %xy distance in (degrees / second)
dsu = (atand((dxyu/2)./(d(1:end-1)*pix_to_angle_const))*2)*1000/sr; %xy distance in (degrees / second) UNFILTERED
ds = [ds, dxy(end)];
dsu = [dsu, dxyu(end)];



% keyboard
% VT(1) = max(ds)/2;
% 
% for i = 2:100
%     p(i) = length(ds(ds<VT(i-1)))/length(ds);
%     s(i) = std(ds(ds < VT(i-1)));
%     m(i) = mean(ds(ds < VT(i-1)));
%     VT(i) = m(i) + 6 * s(i);
%     if abs(VT(i)-VT(i-1)) < 1
%         VT(1:i)
%         break
%     end
% end
% 
% diff(m)
% %    keyboard
%    
% vthresh = VT(end);

%find fixations and saccades as any times where velocity (dxy) >= velocity
%threshold
sac_index = find(ds>=vthresh);
fix_index = find(ds<=vthresh); 

% % keyboard

% combine nearby fixations

while length(find(diff(fix_index) >1 & diff(fix_index) <= floor(minsactime/sr)))>0
    for first_fill_fix = find(diff(fix_index)>1 & diff(fix_index) <= floor(minsactime/sr))
        fix_index(first_fill_fix):fix_index(first_fill_fix+1);
        fix_index = sort(unique([fix_index, fix_index(first_fill_fix):fix_index(first_fill_fix+1)]));       
    end
end
sac_index(ismember(sac_index, fix_index)) = [];


if ~length(sac_index) > 0 || ~length(fix_index) > 0 
%     disp('Solitary output')
    fixinfo.nfix = [];
    fixinfo.durations = [];
    
    sacinfo.nsac = [];
    sacinfo.durations = [];
    
    pointinfo.initial = [];
    pointinfo.hmm = [];
    pointinfo.bayes = [];
    return
end

%begin filtering fixations based on minimum duration criteria (minfixtime)
fix_thresh = [find(diff(fix_index)>1), fix_index(end)] - [fix_index(1), find(diff(fix_index)>1)+1] + 1 >= floor(minfixtime/sr); %index of fixation beginnings where duration >= threshold
fix_nothresh = [find(diff(fix_index)>1), fix_index(end)] - [fix_index(1), find(diff(fix_index)>1)+1] + 1 < floor(minfixtime/sr); %index of fixation beginnings where duration < threshold
fix_begin = [1, find(diff(fix_index)>1)+1]; %location of beginning of fixations
fix_end = [find(diff(fix_index)>1), length(fix_index)]; %location of end of fixations
fix_keep = fix_index(fix_begin(fix_thresh)); %fix_begin when above threshold
fix_unknown = fix_index(fix_begin(fix_nothresh)); %fix_begin when below threshold

fkp = [];
fix_centroid = [];
fix_keep_begin = [];
fix_keep_end = [];

%categorize all points between start and end
for fixfill = 1:length(fix_begin)
    if ismember(fix_index(fix_begin(fixfill)), fix_keep)
        fkp = fix_index(fix_begin(fixfill):fix_end(fixfill));
        fix_centroid(1, fixfill) = mean(fx(fkp), 2);
        fix_centroid(2, fixfill) = mean(fy(fkp), 2);
        fkp_distancetocentroid_indegrees = (atand(sqrt((fx(fkp)-fix_centroid(1,fixfill)).^2 + (fy(fkp)-fix_centroid(2, fixfill)).^2)/2)./fd(fkp) * pix_to_angle_const) * 2; %convert to degrees
        fix_keep = [fix_keep, fkp(fkp_distancetocentroid_indegrees <= 1.05)];
        fix_keep_begin = [fix_keep_begin, fix_index(fix_begin(fixfill))];
        fix_keep_end = [fix_keep_end, fix_index(fix_end(fixfill))];
    else
        fkp = [];
    end
end
% keyboard
if ~isempty(fix_centroid)
    fix_centroid(3,:) = sqrt(fix_centroid(1,:).^2 + fix_centroid(2,:).^2);
end
fix_keep = [fix_keep, fkp];
fix_keep = unique(fix_keep);
fix_unknown = unique([fix_unknown, fix_index(~ismember(fix_index, fix_keep))]);
% keyboard

%begin filtering saccades based on minimum duration criteria (minsactime)
sac_thresh = [find(diff(sac_index)>1), length(sac_index)] - [1, find(diff(sac_index)>1)+1] + 1 >= floor(minsactime/sr); %points where fixation duration is > threshold
sac_nothresh = [find(diff(sac_index)>1), length(sac_index)] - [1, find(diff(sac_index)>1)+1] + 1 < floor(minsactime/sr); %points where fixation duration is > threshold
sac_begin = [1, find(diff(sac_index)>1)+1]; %beginning of saccades
sac_end = [find(diff(sac_index)>1), length(sac_index)]; %end of saccades
sac_keep = sac_index(sac_begin(sac_thresh));% - [1, zeros(1,length(fixb(sac_begin(sac_thresh)))-1)]; %beginning of saccades when above threshold
sac_unknown = sac_index(sac_begin(sac_nothresh));

%begin filtering saccades based on acceleration
da = [diff(ds) * 1000 / sr, ds(end)]; %acceleration in (degrees / sec^2)
dau = [diff(dsu) * 1000 / sr, dsu(end)]; %acceleration in (degrees / sec^2) UNFILTERED

skp = [];

for sacfill = 1:length(sac_begin)
    if ismember(sac_index(sac_begin(sacfill)), sac_keep) && any(abs(da(sac_index(sac_begin(sacfill))-0*(sac_index(sac_begin(sacfill))>2):sac_index(sac_end(sacfill))+0*(sac_index(sac_end(sacfill))<length(da)-2))) >= minaccelspeed)
        skp = sac_index(sac_begin(sacfill):sac_end(sacfill));
    else
        skp = [];
    end
    
    sac_keep = [sac_keep, skp];    
end

sac_keep = unique(sac_keep);
sac_unknown = unique([sac_unknown, sac_index(~ismember(sac_index, sac_keep))]);

if length(fix_keep) < 1
%     disp('Only Saccades')
    fixinfo.nfix = [];
    fixinfo.durations = [];
    
    sacinfo.nsac = 1;
    sacinfo.durations = [length(sac_index);length(sac_index) * sr];
    
    pointinfo.initial = [];
    pointinfo.hmm = [];
    pointinfo.bayes = [];
    return
elseif length(sac_keep) < 1
%     disp('Only Fixations')
    fixinfo.nfix = 1;
    fixinfo.durations = [length(fix_index);length(fix_index) * sr];
    
    sacinfo.nsac = [];
    sacinfo.durations = [];
    
    pointinfo.initial = [];
    pointinfo.hmm = [];
    pointinfo.bayes = [];
    return
else
    
% 
% 
% close all
% figure('Position', [1 41 1920 964])
% subplot(413)
% plot(dsu,'b')
% hold on
% plot(repmat(vthresh, 1, length(ds)), 'Color', [0 0 0.7])
% AX = axis;
% axis([0 length(ds) AX(3) AX(4)])
% subplot(4,1,1:2)
% plot(xy, 'k')
% hold on
% plot(fix_keep, xy(fix_keep), 's', 'MarkerSize', 5, 'MarkerEdgeColor', [0 .5 0])
% plot(sac_keep, xy(sac_keep), 'v', 'MarkerSize', 5, 'MarkerEdgeColor', [0 0 .7])
% plot(fix_unknown, xy(fix_unknown), 's', 'MarkerSize', 10, 'MarkerEdgeColor', [.3 1 0])
% plot(sac_unknown, xy(sac_unknown), 'v', 'MarkerSize', 10, 'MarkerEdgeColor', [.3 0 1])
% AX = axis;
% axis([0 length(ds) AX(3) AX(4)])
% leg1 = legend('\surd(x^2+y^2)', 'Good Fixations', 'Good Saccades', 'Fixations?', 'Saccades?', 'Location', 'Northeast');
% title('Initial Based on Velocity, Dispersion, Acceleration')
% subplot(414)
% plot(da, 'm')
% hold on
% axis tight
% plot(repmat(minaccelspeed, 1, length(da)), 'Color', [0.7 0 .7])
% plot(repmat(-1*minaccelspeed, 1, length(da)), 'Color', [0.7 0 .7])
% 
% % waitforbuttonpress;
% % keyboard
% % %initialize matrices before looping

loop_iter = 1;
states = ones(1,length(xy));
states(fix_keep) = 2;
states(sac_keep) = 3;
% states(blink_index) = 1;


% comparison values (for loop i, compare against these (i-1))
st_hold = states;
% fig = figure;
% color = ['b', 'r', 'g', 'k'];
% keyboard
while loop_iter <= 10 && ~isempty(find(st_hold == 1, 1))

      
    % find transition and observation probabilities based on our data
    [trans, obs] = hmmestimate(ceil(ds/bin_velocities_by), st_hold);

    trans = [.05, .475, .475;
        .01, .94, .05;
        .01, .05, .94];
%         .00, .4, .4];

    likely_states = hmmviterbi(ceil(ds/bin_velocities_by), trans, obs);
    
% points that are already 2 or 3 cannot be re-assessed
%     st_hold(st_hold-likely_states ~= 0 & likely_states ~= 1 & (st_hold ~= 2 | st_hold ~= 3)) = likely_states(st_hold-likely_states ~= 0 & likely_states ~= 1 & (st_hold ~= 2 | st_hold ~= 3));

% all points
    st_hold(st_hold-likely_states ~= 0 & likely_states ~= 1) = likely_states(st_hold-likely_states ~= 0 & likely_states ~= 1);

    

    loop_iter = loop_iter + 1;
 
end

hmmstuckinone = length(find(st_hold == 1));

[mu2, sig2] = normfit(ceil(ds(st_hold ==2)/bin_velocities_by));
[mu3, sig3] = normfit(ceil(ds(st_hold ==3)/bin_velocities_by));
[muall, sigall] = normfit(ceil(ds/bin_velocities_by));
% keyboard
pdf2 = normpdf(unique(ceil(ds(st_hold ==2)/bin_velocities_by)), mu2, sig2);
pdf3 = normpdf(unique(ceil(ds(st_hold ==3)/bin_velocities_by)), mu3, sig3);
pdfall = normpdf(unique(ceil(ds/bin_velocities_by)), muall, sigall);

% keyboard
%Bayesian joint probability to force any 1s to 2s or 3s
for stuck_in_one = find(st_hold == 1)
    if stuck_in_one == 1
        st_hold(stuck_in_one) = mode(st_hold(2:10));
    else
        for check_states = 2:3
            eval(['pdfcurr = pdf', num2str(check_states), ';']);
            velocurr = max(ceil(ds(stuck_in_one)/bin_velocities_by), 1);
            velocurr = min(velocurr, length(pdfcurr));        
            P(check_states) = pdfcurr(velocurr) * trans(st_hold(stuck_in_one-1), check_states) / pdfall(velocurr);        
        end
        st_hold(stuck_in_one) = find(max(P)==P);
    end
end
        
        
st_hold(end) = st_hold(end-1);

fix_keep = find(st_hold == 2);
sac_keep = find(st_hold == 3);
still_unknown = find(st_hold == 1);

% merge nearby fixations over saccades of duration > thresh
% keyboard

while length(find(diff(fix_keep) >1 & diff(fix_keep) <= floor(minsactime/sr)))>0 | length(find(diff(sac_keep) >1 & diff(sac_keep) <= floor(minfixtime/sr)))>0
    for final_fill_fix = find(diff(fix_keep)>1 & diff(fix_keep) <= floor(minsactime/sr))
        st_hold(fix_keep(final_fill_fix):fix_keep(final_fill_fix+1)) = 2;
    end
    for final_fill_sac = find(diff(sac_keep)>1 & diff(sac_keep) <= floor(minfixtime/sr))
        st_hold(sac_keep(final_fill_sac):sac_keep(final_fill_sac+1)) = 3;
    end
    fix_keep = find(st_hold == 2);
    sac_keep = find(st_hold == 3);
end

% preallocate matrices
fix_durations = [];
sac_durations = [];

fix_keep_begin = [];
fix_keep_end = [];
sac_keep_begin = [];
sac_keep_end = [];

% keyboard
if length(fix_keep) > 0
    fix_keep_begin = [fix_keep(1), fix_keep(find(diff(fix_keep)>1)+1)]; %location of beginning of fixations
    fix_keep_end = [fix_keep(diff(fix_keep)>1), fix_keep(end)]; %location of end of fixations
    fix_durations = [fix_keep_end - fix_keep_begin + 1];
    fix_durations(2,:) = fix_durations * sr;
end
if length(sac_keep) > 0
    sac_keep_begin = [sac_keep(1), sac_keep(find(diff(sac_keep)>1)+1)]; %location of beginning of saccades
    sac_keep_end = [sac_keep(diff(sac_keep)>1), sac_keep(end)]; %location of end of saccades
    sac_durations = [sac_keep_end - sac_keep_begin + 1];
    sac_durations(2,:) = sac_durations * sr;
end
% keyboard

%% Re-index all values with the re-inclusion of blinks and gaps
xyfinal = zeros(1, length(x));
xyfinal(find(~isnan(x))) = xy;

xplot = zeros(1, length(x)); xplot(find(~isnan(x))) = fx;
yplot = zeros(1, length(y)); yplot(find(~isnan(y))) = fy;
cplot = zeros(1, length(x)); cplot(find(~isnan(x))) = st_hold; cplot(blink_index) = 4; cplot(cplot==0) = 4;
colors = ['r', 'g', 'b', 'y'];

dsfinal = nan(1, length(x));
dsfinal(find(~isnan(x))) = ds;

dafinal = nan(1, length(x));
dafinal(find(~isnan(x))) = da;

fix_keep_final = new_indices(fix_keep);
sac_keep_final = new_indices(sac_keep);
still_unknown_final = new_indices(still_unknown);

fix_keep_begin_final = new_indices(fix_keep_begin);


% %% 
% % keyboard
% figure('Position', [1 41 1920 964])
% subplot(413)
% plot(dsfinal,'b')
% hold on
% plot(repmat(vthresh, 1, length(dsfinal)), 'Color', [0 0 0.7])
% AX = axis;
% axis([0 length(dsfinal) AX(3) AX(4)])
% 
% % ###################
% subplot(414)
% plot(dafinal, 'm')
% hold on
% axis([0 length(dafinal) -20000 20000])
% plot(repmat(minaccelspeed, 1, length(dafinal)), 'Color', [0.7 0 .7])
% plot(repmat(-1*minaccelspeed, 1, length(dafinal)), 'Color', [0.7 0 .7])
% 
% % ###################
% subplot(4,1,1:2)
% plot(xyfinal, 'k')
% axis([0 length(xyfinal), min(500, min(xyfinal)- 100), max(1500, max(xyfinal) + 100)])
% hold on
% plot(fix_keep_final, xyfinal(fix_keep_final), 's', 'MarkerSize', 5, 'MarkerEdgeColor', [0 .7 0])
% plot(sac_keep_final, xyfinal(sac_keep_final), 'v', 'MarkerSize', 5, 'MarkerEdgeColor', [0 0 .7])
% plot(fix_keep_begin_final, xyfinal(fix_keep_begin_final), 'o', 'MarkerSize', 15, 'MarkerEdgeColor', [1 0 1])
% if ~isempty(blink_index)
%     plot(blink_index, xyfinal(blink_index), 'o', 'MarkerSize', 5, 'MarkerEdgeColor', [.9 .9 0])
% end
% if ~isempty(other_index)
%     plot(other_index, xyfinal(other_index), 'o', 'MarkerSize', 5, 'MarkerEdgeColor', [.1 .1 0.1])
% end
% plot(still_unknown_final, xyfinal(still_unknown_final), 'o', 'MarkerSize', 15, 'MarkerEdgeColor', [.9 .9 0])
% AX = axis;
% axis([0 length(dsfinal) AX(3) AX(4)])
% leg1 = legend('\surd(x^2+y^2)', 'Good Fixations', 'Good Saccades', 'Fix Begins', 'Blinks', 'Missing Data', 'Location', 'Best');
% title('HMM Estimates')
% 
% for fixd_text = 1:length(fix_keep_begin_final)
%     text(fix_keep_begin_final(fixd_text)+5, xyfinal(fix_keep_begin_final(fixd_text))+50, num2str(round(fix_durations(2, fixd_text))))
% end
% pause
% %% Time-series plotting
% figure(2)
% axis([0 1920 0 1080])
% axis ij
% hold on
% 
% tail_length = 10;
% for tplot = 1:length(xplot)
%     if tplot > tail_length
%         xv = xplot(tplot-tail_length+1:1:tplot);
%         yv = yplot(tplot-tail_length+1:1:tplot);
%         cv = cplot(tplot-tail_length+1:1:tplot);
%     else
%         xv = xplot(1:tplot);
%         yv = yplot(1:tplot);
%         cv = cplot(1:tplot);
%     end
%     for j = 1:length(xv)
%         eval(['plot(xv(j), yv(j), '' ', colors(cv(j)), '+'' )'])
%     end
%    
%     drawnow
%     pause(.001)
%     cla
%     
% end
% 





fix_lengths = [fix_end - fix_begin];
sac_lengths = [sac_end - sac_begin];

fixinfo.nfix = length(fix_keep_begin);
fixinfo.durations = fix_durations;

sacinfo.nsac = length(sac_keep_begin);
sacinfo.durations = sac_durations;

pointinfo.initial = length(fix_unknown) + length(sac_unknown);
pointinfo.hmm = hmmstuckinone;
pointinfo.bayes = still_unknown;
% keyboard
% keyboard
% waitforbuttonpress
% close all
return
end