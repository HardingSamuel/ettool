function [classinfo, pointinfo] = fixsacv1_1_2FORVALID_SPattmpt(x,y,d,sr,gapdata,fff,vthresh,minfixtime,whatson,includesp)
%FixDetectDev
%
%Developing a procedure / algorithm to do fixation detection from raw ET
%data.
%   [SH] - 10/29/13:  for use in ETTool
%   [SH] - 10/31/13:  commenting
%   [SH] - 11/11/13:  debuging / error fixing
%   [SH] - 12/16/13:  added additional inputs for easy validation looping.
%   [SH] - 12/19/13:  changed to time axis;
%   [SH] - 01/10/14:  enable access to flagging periods of potential
%   'smooth pursuit'
%   [SH] - 01/23/14:  adjusted fix and sac index updating, incorporated
%   smooth as overwriting fix & sac.
%   [SH] - 02/03/14:  removed sustructures from outputs (fixinfo,
%   sacinfo...).  Replaced with matrices:  1st row = means, 2nd = variance,
%   3rd = max

classinfo = [];
pointinfo = [];


%% Deal with incoming gap information
% make new structure 'blink' containing information about blink beginnings
% and durations based on input 'gapdata,' defined as gapdata(1,2, ==2).
% See clean_interp for more info.
% keyboard
blink.begin = gapdata(1,gapdata(3,:)==2);
blink.duration = gapdata(2,gapdata(3,:)==2);
% make new struc 'other' where the gaps are not blinks but still need to be
% removed, rather than classified
other.begin = gapdata(1,gapdata(3,:)==3);
other.duration = gapdata(2,gapdata(3,:)==3);
% initialize empty array into which all points between a blink begin and
% end will be placed
blink_index = [];
% for each blink.begin, interpolate indices across the entire duration
for bfill = 1:length(blink.begin)
    blink_index = [blink_index, blink.begin(bfill):blink.begin(bfill) + blink.duration(bfill) - 1];
end
% for each other.begin, interpolate indices across the entire duration
other_index = [];
for ofill = 1:length(other.begin)
    other_index = [other_index, other.begin(ofill):other.begin(ofill) + other.duration(ofill) - 1];
end

%% Create new matrices without gaps
% now that we know where the gaps are, remove them so we can filter.
% n.b. all gap data should be nans, so this is the same as removing based
% on gap indices
fx = x(~isnan(x));
fy = y(~isnan(y));
fd = d(~isnan(x));
% make index of all points we removed.
gap_index = unique([blink_index, other_index]);

% at the end, we want to be able to put the points back in where the
% originally came from.  the easiest way is to make a matrix to convert new
% to old.
original_indices = 1:length(x);
new_indices = original_indices(find(~isnan(x)));

%% User-defined values
% these are the most important part of this whole process.  These values
% are everything that is used at any point throughout the categorization

% % % vthresh = 50; %velocity thresh %30 for adults / 50 for babies?
minsactime = 15; %%%% was 40%saccades must last at least this long (ms) or they cannot have been true saccades and are likely noise
% % % minfixtime = 150; %fixations must last at least this long (ms) or they cannot have been true fixations and are likely noise
minaccelspeed = 4000; %acceleration threshold
max_dispersion = 1.05; %how many degress of visual angle can a point exceed from the centroid of a fixation before being removed.
windowsize = 25; %for smoothing; should be odd to guarantee 0 phase (convolution); must be odd for sgolay (see fff below)
st = 1000/sr; %convert sample rate to sample time #####################################################this changed recently make sure it works
pix_to_angle_const = 2202.9/583.84; %we need to convert pixels to visual angle, this is ratio of pix to cm for tx-300
bin_velocities_by = 5; % to do velocity probability calculations.  smaller = more bins, used in HMM process

%% Up-front check that we have enough data in this trial to even try to classify
% 50 is arbitrary
if length(fx)< 50 | length(fy)< 50 | length(fd) < 50
    %     disp('Not enough data')
    fixinfo = []; sacinfo = []; spinfo = []; blinkinfo = []; otherinfo = []; unknowninfo = [];     
    
    classinfo.fixations = fixinfo;
    classinfo.saccades = sacinfo;
    classinfo.smoothpursuit = spinfo;
    classinfo.blinks = blinkinfo;
    classinfo.others = otherinfo;
    classinfo.unknown = unknowninfo;
    
    pointinfo.initial = [];
    pointinfo.hmm = [];
    pointinfo.bayes = [];
    return
end

%% Define which filter to use
% 1-low-pass
% 0-no filter
% 2-savitzky olay filter of 2nd order polynomial (RECOMMENDED)
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
        
        fx = sgolayfilt(fx, 2, windowsize);
        fy = sgolayfilt(fy, 2, windowsize);
        fd = sgolayfilt(fd, 2, windowsize);
end


%% Find distances and velocities

xy = sqrt(fx.^2 + fy.^2); %linear distance from origin (0,0):  screen UL corner
xyu = sqrt(x.^2 + y.^2); %linear distance from origin (0,0):  screen UL corner of ULFILTERED data
dxy = sqrt(diff(fx).^2 + diff(fy).^2); %euclidian distance traveled from point-to-point
dxyu = sqrt(diff(x).^2 + diff(y).^2); %euclidian distance traveled from point-to-point ULFILTERED

%convert pixels/point to pixels/second based on distance and sample-rate
ds = (atand((dxy/2)./(fd(1:end-1)*pix_to_angle_const))*2)*1000/st; %xy distance in (degrees / second)
dsu = (atand((dxyu/2)./(d(1:end-1)*pix_to_angle_const))*2)*1000/st; %xy distance in (degrees / second) UNFILTERED
ds = [ds, dxy(end)]; %append the final location to DS to make size(ds) == size(dxy)
dsu = [dsu, dxyu(end)];

dx = (atand((diff(x)/2)./(d(1:end-1)*pix_to_angle_const))*2)*1000/st; %x distance in (degrees / second)
dy = (atand((diff(y)/2)./(d(1:end-1)*pix_to_angle_const))*2)*1000/st; %x distance in (degrees / second)


%% Velocity thresholding

sac_index = find(ds>=vthresh);
fix_index = find(ds<vthresh);


% any fixations separated by a physiologically-impossible saccade (defined
% as

%% Check to see if the distance between successive fixations is too small to
% be plausable (< minsacdur)
while length(find(diff(fix_index) >1 & diff(fix_index) <= floor(minsactime/st)))>0
    %     for every point in these too-small gaps, replace their categorization
    %     as 'saccades' with 'fixation' and remove any overlap
    for first_fill_fix = find(diff(fix_index)>1 & diff(fix_index) <= floor(minsactime/st))
        fix_index(first_fill_fix):fix_index(first_fill_fix+1);
        fix_index = sort(unique([fix_index, fix_index(first_fill_fix):fix_index(first_fill_fix+1)]));
    end
end
% remove all the points that were just reclassified from the saccade index
sac_index(ismember(sac_index, fix_index)) = [];

%% Check if all points fall entirely into one big fixation or one big saccade
% further calculations assume that there will be at least one of each so if
% this isn't the case, return to the caller
if ~length(sac_index) > 0 || ~length(fix_index) > 0
    %     disp('Solitary output')
    fixinfo = []; sacinfo = []; spinfo = []; blinkinfo = []; otherinfo = []; unknowninfo = [];     
    
    classinfo.fixations = fixinfo;
    classinfo.saccades = sacinfo;
    classinfo.smoothpursuit = spinfo;
    classinfo.blinks = blinkinfo;
    classinfo.others = otherinfo;
    classinfo.unknown = unknowninfo;
    return
end

%% begin filtering fixations based on minimum duration criteria (minfixtime)
% some fixations will be only a few points long, too short to be a real
% fixation so we have to get rid of them (for now).  We want to only keep
% the fixations (and eventually saccades) that are highly-reliably
% classified by the simple velocity algorithm.

% This uses logical indexing. see demo_log_indx.m

% find where the gaps between subsequent fixation points is > 1 (these are the ends of fixations), append the
% last point.  subtract from these end-times, the beginning times (to
% determine the length of each fixation.  logical check if this duration
% >= the defined minimum time that a fixation MUST last (minfixtime)


fix_thresh = [find(diff(fix_index)>1), fix_index(end)] - [fix_index(1), find(diff(fix_index)>1)+1] + 1 >= floor(minfixtime/st); %index of fixation beginnings where duration >= threshold
fix_nothresh = [find(diff(fix_index)>1), fix_index(end)] - [fix_index(1), find(diff(fix_index)>1)+1] + 1 < floor(minfixtime/st); %index of fixation beginnings where duration < threshold
fix_begin = [1, find(diff(fix_index)>1)+1]; %location of beginning of fixations
fix_end = [find(diff(fix_index)>1), length(fix_index)]; %location of end of fixations
fix_keep = fix_index(fix_begin(fix_thresh)); %fix_begin when above threshold
fix_unknown = fix_index(fix_begin(fix_nothresh)); %fix_begin when below threshold

%%  Check dispersion of all fixations that met minimum length requirements
fkp = [];
fix_centroid = [];
fix_keep_begin = [];
fix_keep_end = [];

% iterate through all fixation beginnings
for fixfill = 1:length(fix_begin)
    %     if this fixation met the length requirements above
    if ismember(fix_index(fix_begin(fixfill)), fix_keep)
        %         fkp = all indices of points between the beginning and end of this
        %         fixation
        fkp = fix_index(fix_begin(fixfill):fix_end(fixfill));
        %         centroid x and y values are defined as the mean of all points
        %         within the fixation
        fix_centroid(1, fixfill) = mean(fx(fkp), 2);
        fix_centroid(2, fixfill) = mean(fy(fkp), 2);
        %         calculate the distance of each point from the centroid and
        %         convert to degrees
        fkp_distancetocentroid_indegrees = (atand(sqrt((fx(fkp)-fix_centroid(1,fixfill)).^2 + (fy(fkp)-fix_centroid(2, fixfill)).^2)/2)./fd(fkp) * pix_to_angle_const) * 2; %convert to degrees
        %         keep all the points that didn't get too far away
        fix_keep = [fix_keep, fkp(fkp_distancetocentroid_indegrees <= max_dispersion)];
        %         continue holding onto this starting point
        fix_keep_begin = [fix_keep_begin, fix_index(fix_begin(fixfill))];
        %         and this end point
        fix_keep_end = [fix_keep_end, fix_index(fix_end(fixfill))];
    else
        fkp = [];
    end
end
% if we successfully found centroids in the above process, add a 3rd row
% that describes their distance from the origin (for plotting)
if ~isempty(fix_centroid)
    fix_centroid(3,:) = sqrt(fix_centroid(1,:).^2 + fix_centroid(2,:).^2);
end
%
% fix_keep = [fix_keep, fkp]; I think this is unnecessary

% remove any duplicated
fix_keep = unique(fix_keep);
% make array of all points that have fallen out of original classification
% as fixations, remove duplicates
fix_unknown = unique([fix_unknown, fix_index(~ismember(fix_index, fix_keep))]);


%% begin filtering saccades based on minimum duration criteria (minsactime)
% see 154-173
sac_thresh = [find(diff(sac_index)>1), length(sac_index)] - [1, find(diff(sac_index)>1)+1] + 1 >= floor(minsactime/st); %points where fixation duration is > threshold
sac_nothresh = [find(diff(sac_index)>1), length(sac_index)] - [1, find(diff(sac_index)>1)+1] + 1 < floor(minsactime/st); %points where fixation duration is > threshold
sac_begin = [1, find(diff(sac_index)>1)+1]; %beginning of saccades
sac_end = [find(diff(sac_index)>1), length(sac_index)]; %end of saccades
sac_keep = sac_index(sac_begin(sac_thresh));% - [1, zeros(1,length(fixb(sac_begin(sac_thresh)))-1)]; %beginning of saccades when above threshold
sac_unknown = sac_index(sac_begin(sac_nothresh));

%% begin filtering saccades based on acceleration
% calculate acceleration
da = [diff(ds) * 1000 / st, ds(end)]; %acceleration in (degrees / sec^2)
dau = [diff(dsu) * 1000 / st, dsu(end)]; %acceleration in (degrees / sec^2) UNFILTERED

skp = [];

% filter by acceleration
for sacfill = 1:length(sac_begin)
    %     if this saccade was long enough, and any of the points within the
    %     saccade go above the acceleration threshold, identify all the points
    %     in between as good.
    %     n.b. the -0* etc... and +0* etc were, I believe, originally inteded
    %     to extend the window beyond just the saccade points themselves, but
    %     removed, hence the '0s'.  If this was >0, it would look a few points
    %     ahead and behind as well.
    if ismember(sac_index(sac_begin(sacfill)), sac_keep) && any(abs(da(sac_index(sac_begin(sacfill))-0*(sac_index(sac_begin(sacfill))>2):sac_index(sac_end(sacfill))+0*(sac_index(sac_end(sacfill))<length(da)-2))) >= minaccelspeed)
        skp = sac_index(sac_begin(sacfill):sac_end(sacfill));
    else
        skp = [];
    end
    
    sac_keep = [sac_keep, skp];
end

% remove duplicates
sac_keep = unique(sac_keep);
% all points fallen out of sac_index are put here
sac_unknown = unique([sac_unknown, sac_index(~ismember(sac_index, sac_keep))]);

%% Again, further calculations assume both fixations and saccades, so we break out now if that's no longer the case
if length(fix_keep) < 1
    %     disp('Only Saccades')
    fixinfo.nfix = [];
    fixinfo.durations = [];
    
    sacinfo.nsac = 1;
    sacinfo.durations = [length(sac_index);length(sac_index) * st];
    
    pointinfo.initial = [];
    pointinfo.hmm = [];
    pointinfo.bayes = [];
    return
elseif length(sac_keep) < 1
    %     disp('Only Fixations')
    fixinfo.nfix = 1;
    fixinfo.durations = [length(fix_index);length(fix_index) * st];
    
    sacinfo.nsac = [];
    sacinfo.durations = [];
    
    pointinfo.initial = [];
    pointinfo.hmm = [];
    pointinfo.bayes = [];
    return
else
    %%  Plotting, for debug and checking
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
    
    
    
    %% HMM state sequence generation
    % By converging measures of velocity, acceleration, and dispersion we have
    % classified many of our points into either fixations or saccades with high
    % confidence.  But what do we do with the rest?
    %
    % Using Hidden Markov modeling, we can generate a sequence of states
    % ('unknown', 'fixations', 'saccades') with two properties:  transition and
    % observation.  Transition is simply the likelihood of moving from one
    % state to another.  Observation is the likelihood of observing/measuring
    % some value.  It is assumed that the states themselves are not
    % directly-observable but the 'observations' are so if we have a-priori
    % assumptions about the likelihood of switching states, and those states
    % properties, we can figure out what the most-likely sequence of
    % state-events has generated our sequence of observed events.
    %
    % We will do this process iteratively 10 times, recalculating observed
    % probabilities (in our case, binned velocity values) each time.
    
    
    loop_iter = 1; %counter
    states = ones(1,length(xy)); %initial state sequence chain, all 1s (unknown)
    states(fix_keep) = 2; %all good fixations are set as state 2
    states(sac_keep) = 3; %all good saccades are state 3
    
    %hold on to the sequence of states from the PREVIOUS iteration, against
    %which to compare each loop and find changes
    st_hold = states;
    
    %as long as we haven't done 10 loops yet and we still have unclassified
    %data points
    % keyboard
    while loop_iter <= 10 && ~isempty(find(st_hold == 1, 1))
        
        
        % find transition and observation probabilities based on our data
        %     n.b. '/bin_velocity_by' accounts for fact that observed velocities
        %     are continuous but we need discreet bins
        
        [~, obs] = hmmestimate(ceil(ds/bin_velocities_by), st_hold);
        
        %   we have just estimated the likelihood of transitioning between states,
        %   but we have come into this with expectations:  a fixation is ~95%
        %   likely to stay a fixation and a saccade is ~95% likely to stay a
        %   saccade (see Salvucci & Goldberg 2000).  We adjust this slightly
        %   because matlab requires all transition probabilities be >0.  We do not
        %   know if an unknown point will go to a fix or sac so their likelihood is
        %   the same, with a 5% chance to stay unknown.
        trans = [.05, .475, .475;
            .01, .94, .05;
            .01, .05, .94];
        
        %    using Viterbi algorith, estimate most likely sequence of states given
        %    our transition and observation probabilities
        likely_states = hmmviterbi(ceil(ds/bin_velocities_by), trans, obs);
        
        %    update values in 'hold' state sequence with anything that has changed
        %    in this loop.
        st_hold(st_hold-likely_states ~= 0 & likely_states ~= 1) = likely_states(st_hold-likely_states ~= 0 & likely_states ~= 1);
        
        loop_iter = loop_iter + 1;
    end
    
    %% Bayesian
    % even after nicely giving points the chance to leave their unknown state,
    % some will be stuck.  This is usually because they have extreme velocity
    % values that don't fall into the saccade bin.  We need to reclassify them
    
    % find their locations
    hmmstuckinone = length(find(st_hold == 1));
    
    % we will fit a theoretical continuous distribution of velocities for all
    % state groups
    [mu2, sig2] = normfit(ceil(ds(st_hold ==2)/bin_velocities_by)); %fixations
    [mu3, sig3] = normfit(ceil(ds(st_hold ==3)/bin_velocities_by)); %saccades
    [muall, sigall] = normfit(ceil(ds/bin_velocities_by)); %all points together
    
    % probabilities of the above distributions
    pdf2 = normpdf(unique(ceil(ds(st_hold ==2)/bin_velocities_by)), mu2, sig2);
    pdf3 = normpdf(unique(ceil(ds(st_hold ==3)/bin_velocities_by)), mu3, sig3);
    pdfall = normpdf(unique(ceil(ds/bin_velocities_by)), muall, sigall);
    
    % find the maximum conditional probability
    % n.b.  we are essentially doing the HMM process point-by-point with
    % continuous, rather than discreet distributions, so it may be smart to
    % simply do this for everything.
    
    for stuck_in_one = find(st_hold == 1)
        if stuck_in_one == 1
            %         we base our 'given' on the previous point, so if it is the first
            %         point in the sequence, we just use the most-common state from
            %         points 2:10.
            st_hold(stuck_in_one) = mode(st_hold(2:10));
        else
            for check_states = 2:3
                %             set pdfcurr = pdf2 or pdf3
                eval(['pdfcurr = pdf', num2str(check_states), ';']);
                %             velocity bin at this point, force into range represented by
                %             the continuous distributions.
                velocurr = max(ceil(ds(stuck_in_one)/bin_velocities_by), 1);
                velocurr = min(velocurr, length(pdfcurr));
                %             conditional probability
                P(check_states) = pdfcurr(velocurr) * trans(st_hold(stuck_in_one-1), check_states) / pdfall(velocurr);
            end
            %         which ever probability is higher is the new state.
            st_hold(stuck_in_one) = find(max(P)==P);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%2
    % the last state is forced to match the 2nd to last
    st_hold(end) = st_hold(end-1);
    
    % all points are new defined, place them into the correct category.
    fix_keep = find(st_hold == 2);
    sac_keep = find(st_hold == 3);
    still_unknown = find(st_hold == 1);% this SHHHHOULD be empty but just in
    % case
    
    %% merge nearby fixations over saccades of duration > thresh
    % similar to 124-136, but now for both
    while ~isempty(find(diff(fix_keep) >1 & diff(fix_keep) <= floor(minsactime/st), 1)) || ~isempty(find(diff(sac_keep) >1 & diff(sac_keep) <= floor(minfixtime/st), 1))
        for final_fill_fix = find(diff(fix_keep)>1 & diff(fix_keep) <= floor(minsactime/st))
            st_hold(fix_keep(final_fill_fix):fix_keep(final_fill_fix+1)) = 2;
        end
        for final_fill_sac = find(diff(sac_keep)>1 & diff(sac_keep) <= floor(minfixtime/st))
            st_hold(sac_keep(final_fill_sac):sac_keep(final_fill_sac+1)) = 3;
        end
        %     update indices
        fix_keep = find(st_hold == 2);
        sac_keep = find(st_hold == 3);
    end
    

    %% Tag and Audit Smooth Pursuit
    % correct indices for velo and accel
    dsfinal = nan(1, length(x));
    dsfinal(find(~isnan(x))) = ds;
    dafinal = nan(1, length(x));
    dafinal(find(~isnan(x))) = da;
    
    classified_final = zeros(1, length(x));
    classified_final(new_indices(fix_keep)) = 1; %fixations
    classified_final(new_indices(sac_keep)) = 2; %saccades
    classified_final(blink_index) = 4; %blink
    classified_final(other_index) = 5; %other (missing)
    classified_final(new_indices(still_unknown)) = 9;
    
    % find smooth pursuit
    %     keyboard
    switch includesp
        case 1
            [sp_keep] = sp_tagv2(x, y, d, dsfinal, sr, vthresh, pix_to_angle_const, new_indices(fix_keep), new_indices(sac_keep),whatson);
            classified_final(sp_keep) = 3; %smooth
        case 0
            sp_keep = [];
    end
    
    % final classification for each type, including updating indices
    
    % used below to calculate some stuff
    fix_keep = find(classified_final==1);
    sac_keep = find(classified_final==2);
    blink_keep = find(classified_final==4);
    other_keep = find(classified_final==5);
    unknown_keep = find(classified_final==9);
    
    %% Calculate some basic measures
    % beginning time, ending time, duration (both in pts and time)
    % preallocate matrices
    fix_durations = [];
    sac_durations = [];
    %     keyboard
    if ~isempty(fix_keep)
        fix_keep_begin = [fix_keep(1), fix_keep(find(diff(fix_keep)>1)+1)]; %location of beginning of fixations
        fix_keep_end = [fix_keep(diff(fix_keep)>1), fix_keep(end)]; %location of end of fixations
        fix_durations = [fix_keep_end - fix_keep_begin + 1];
        fix_durations(2,:) = fix_durations * st;
        fix_centroids = zeros(length(fix_keep_begin), 2);
        fix_avg_velos = zeros(length(fix_keep_begin), 1);
        fix_avg_velos_var = zeros(length(fix_keep_begin), 1);
        fix_avg_accel = zeros(length(fix_keep_begin), 1);
        fix_avg_accel_var = zeros(length(fix_keep_begin), 1);
        for fcent = 1:length(fix_keep_begin)
            fix_centroids(fcent,1:2) = [mean(x(fix_keep_begin(fcent):fix_keep_end(fcent))), mean(y(fix_keep_begin(fcent):fix_keep_end(fcent)))];
            fix_avg_velos(fcent) = mean(dsfinal(fix_keep_begin(fcent):fix_keep_end(fcent)));
            fix_avg_velos_var(fcent) = var(dsfinal(fix_keep_begin(fcent):fix_keep_end(fcent)));
            fix_avg_accel(fcent) = mean(dafinal(fix_keep_begin(fcent):fix_keep_end(fcent)));
            fix_avg_accel_var(fcent) = var(dafinal(fix_keep_begin(fcent):fix_keep_end(fcent)));
        end
        fix_centroids = fix_centroids';
    end
    if ~isempty(sac_keep)
        sac_keep_begin = [sac_keep(1), sac_keep(find(diff(sac_keep)>1)+1)]; %location of beginning of saccades
        sac_keep_end = [sac_keep(diff(sac_keep)>1), sac_keep(end)]; %location of end of saccades
        sac_durations = [sac_keep_end - sac_keep_begin + 1];
        sac_durations(2,:) = sac_durations * st;
        
        sac_centroids = zeros(length(sac_keep_begin), 2);
        sac_avg_velos = zeros(length(sac_keep_begin), 1);
        sac_max_velos = zeros(length(sac_keep_begin), 1);
        sac_avg_velos_var = zeros(length(sac_keep_begin), 1);
        sac_avg_accel = zeros(length(sac_keep_begin), 1);
        sac_max_accel = zeros(length(sac_keep_begin), 1);
        sac_avg_accel_var = zeros(length(sac_keep_begin), 1);
        sac_displacement = zeros(length(sac_keep_begin), 1);
        
        for scent = 1:length(sac_keep_begin)
            sac_centroids(scent,1:2) = [mean(x(sac_keep_begin(scent):sac_keep_end(scent))), mean(y(sac_keep_begin(scent):sac_keep_end(scent)))];
            sac_avg_velos(scent) = mean(dsfinal(sac_keep_begin(scent):sac_keep_end(scent)));
            sac_max_velos(scent) = max(dsfinal(sac_keep_begin(scent):sac_keep_end(scent)));
            sac_avg_velos_var(scent) = var(dsfinal(sac_keep_begin(scent):sac_keep_end(scent)));
            sac_avg_accel(scent) = mean(dafinal(sac_keep_begin(scent):sac_keep_end(scent)));
            sac_max_accel(scent) = max(abs(dafinal(sac_keep_begin(scent):sac_keep_end(scent))));
            sac_avg_accel_var(scent) = var(dafinal(sac_keep_begin(scent):sac_keep_end(scent)));
            %             sac_displacement(scent) = max(abs(xy(sac_keep_begin(scent):sac_keep_end(scent)) - xy(sac_keep_begin(scent))));
        end
    end
    if ~isempty(sp_keep)
        sp_keep_begin = [sp_keep(1), sp_keep(find(diff(sp_keep)>1)+1)]; %location of beginning of spations
        sp_keep_end = [sp_keep(diff(sp_keep)>1), sp_keep(end)]; %location of end of spations
        sp_durations = [sp_keep_end - sp_keep_begin + 1];
        sp_durations(2,:) = sp_durations * st;
        sp_avg_velos = zeros(length(sp_keep_begin), 1);
        sp_avg_velos_var = zeros(length(sp_keep_begin), 1);
        sp_avg_accel = zeros(length(sp_keep_begin), 1);
        sp_avg_accel_var = zeros(length(sp_keep_begin), 1);
        for fcent = 1:length(sp_keep_begin)
            sp_avg_velos(fcent) = mean(dsfinal(sp_keep_begin(fcent):sp_keep_end(fcent)));
            sp_avg_velos_var(fcent) = var(dsfinal(sp_keep_begin(fcent):sp_keep_end(fcent)));
            sp_avg_accel(fcent) = mean(dafinal(sp_keep_begin(fcent):sp_keep_end(fcent)));
            sp_avg_accel_var(fcent) = var(dafinal(sp_keep_begin(fcent):sp_keep_end(fcent)));
        end
    end
    if ~isempty(blink_keep)
        blink_keep_begin = [blink_keep(1), blink_keep(find(diff(blink_keep)>1)+1)]; %location of beginning of blinkations
        blink_keep_end = [blink_keep(diff(blink_keep)>1), blink_keep(end)]; %location of end of blinkations
        blink_durations = [blink_keep_end - blink_keep_begin + 1];
        blink_durations(2,:) = blink_durations * st;
        blink_avg_velos = zeros(length(blink_keep_begin), 1);
        blink_avg_velos_var = zeros(length(blink_keep_begin), 1);
        blink_avg_accel = zeros(length(blink_keep_begin), 1);
        blink_avg_accel_var = zeros(length(blink_keep_begin), 1);
        for fcent = 1:length(blink_keep_begin)
            blink_avg_velos(fcent) = mean(dsfinal(blink_keep_begin(fcent):blink_keep_end(fcent)));
            blink_avg_velos_var(fcent) = var(dsfinal(blink_keep_begin(fcent):blink_keep_end(fcent)));
            blink_avg_accel(fcent) = mean(dafinal(blink_keep_begin(fcent):blink_keep_end(fcent)));
            blink_avg_accel_var(fcent) = var(dafinal(blink_keep_begin(fcent):blink_keep_end(fcent)));
        end
    end
    if ~isempty(other_keep)
        other_keep_begin = [other_keep(1), other_keep(find(diff(other_keep)>1)+1)]; %location of beginning of otherations
        other_keep_end = [other_keep(diff(other_keep)>1), other_keep(end)]; %location of end of otherations
        other_durations = [other_keep_end - other_keep_begin + 1];
        other_durations(2,:) = other_durations * st;
        other_avg_velos = zeros(length(other_keep_begin), 1);
        other_avg_velos_var = zeros(length(other_keep_begin), 1);
        other_avg_accel = zeros(length(other_keep_begin), 1);
        other_avg_accel_var = zeros(length(other_keep_begin), 1);
        for fcent = 1:length(other_keep_begin)
            other_avg_velos(fcent) = mean(dsfinal(other_keep_begin(fcent):other_keep_end(fcent)));
            other_avg_velos_var(fcent) = var(dsfinal(other_keep_begin(fcent):other_keep_end(fcent)));
            other_avg_accel(fcent) = mean(dafinal(other_keep_begin(fcent):other_keep_end(fcent)));
            other_avg_accel_var(fcent) = var(dafinal(other_keep_begin(fcent):other_keep_end(fcent)));
        end
    end
    if ~isempty(unknown_keep)
        unknown_keep_begin = [unknown_keep(1), unknown_keep(find(diff(unknown_keep)>1)+1)]; %location of beginning of unknownations
        unknown_keep_end = [unknown_keep(diff(unknown_keep)>1), unknown_keep(end)]; %location of end of unknownations
        unknown_durations = [unknown_keep_end - unknown_keep_begin + 1];
        unknown_durations(2,:) = unknown_durations * st;
        unknown_avg_velos = zeros(length(unknown_keep_begin), 1);
        unknown_avg_velos_var = zeros(length(unknown_keep_begin), 1);
        unknown_avg_accel = zeros(length(unknown_keep_begin), 1);
        unknown_avg_accel_var = zeros(length(unknown_keep_begin), 1);
        for fcent = 1:length(unknown_keep_begin)
            unknown_avg_velos(fcent) = mean(dsfinal(unknown_keep_begin(fcent):unknown_keep_end(fcent)));
            unknown_avg_velos_var(fcent) = var(dsfinal(unknown_keep_begin(fcent):unknown_keep_end(fcent)));
            unknown_avg_accel(fcent) = mean(dafinal(unknown_keep_begin(fcent):unknown_keep_end(fcent)));
            unknown_avg_accel_var(fcent) = var(dafinal(unknown_keep_begin(fcent):unknown_keep_end(fcent)));
        end
    end
    
    
    %% Some Calculations
    
    if ~isempty(fix_keep)
        fixinfo.nfix = length(fix_keep_begin);
        fixinfo.durations = fix_durations;
        fixinfo.onsets = fix_keep_begin;
        fixinfo.centroids = fix_centroids;
        fixinfo.velocities(1,1:fixinfo.nfix) = fix_avg_velos;
        fixinfo.velocities(2,1:fixinfo.nfix) = fix_avg_velos_var;
        fixinfo.accelerations(1,1:fixinfo.nfix) = fix_avg_accel;
        fixinfo.accelerations(2,1:fixinfo.nfix) = fix_avg_accel_var;
    else
        fixinfo.nfix = [];
        fixinfo.durations = [];
        fixinfo.onsets = [];
    end
    if ~isempty(sac_keep)
        sacinfo.nsac = length(sac_keep_begin);
        sacinfo.durations = sac_durations;
        sacinfo.onsets = sac_keep_begin;
        sacinfo.velocities(1,1:sacinfo.nsac) = sac_avg_velos;        
        sacinfo.velocities(2,1:sacinfo.nsac) = sac_avg_velos_var;
        sacinfo.velocities(3,1:sacinfo.nsac) = sac_max_velos;
        sacinfo.accelerations(1,1:sacinfo.nsac) = sac_avg_accel;
        sacinfo.accelerations(2,1:sacinfo.nsac) = sac_avg_accel_var;
        sacinfo.accelerations(3,1:sacinfo.nsac) = sac_max_accel;        
        sacinfo.displacement = sac_displacement';
        sacinfo.displacement_degrees = (atand((sac_displacement'/2)./(d(sac_keep_begin)*pix_to_angle_const))*2)*1000/st;
    else
        sacinfo.nsac = [];
        sacinfo.durations = [];
        sacinfo.onsets = [];
    end
    if ~isempty(sp_keep)
        spinfo.nsp = length(sp_keep_begin);
        spinfo.durations = sp_durations;
        spinfo.onsets = sp_keep_begin;
        spinfo.velocities(1,1:spinfo.nsp) = sp_avg_velos;
        spinfo.velocities(2,1:spinfo.nsp) = sp_avg_velos_var;
        spinfo.accelerations(1,1:spinfo.nsp) = sp_avg_accel;
        spinfo.accelerations(2,1:spinfo.nsp) = sp_avg_accel_var;
    else
        spinfo.nsp = [];
        spinfo.durations = [];
        spinfo.onsets = [];
    end
    if ~isempty(blink_keep)
        blinkinfo.nblink = length(blink_keep_begin);
        blinkinfo.durations = blink_durations;
        blinkinfo.onsets = blink_keep_begin;
        blinkinfo.velocities(1,1:blinkinfo.nblink) = blink_avg_velos;
        blinkinfo.velocities(2,1:blinkinfo.nblink) = blink_avg_velos_var;
        blinkinfo.accelerations(1,1:blinkinfo.nblink) = blink_avg_accel;
        blinkinfo.accelerations(2,1:blinkinfo.nblink) = blink_avg_accel_var;
    else
        blinkinfo.nblink = [];
        blinkinfo.durations = [];
        blinkinfo.onsets = [];
    end
    if ~isempty(other_keep)
        otherinfo.nother = length(other_keep_begin);
        otherinfo.durations = other_durations;
        otherinfo.onsets = other_keep_begin;
        otherinfo.velocities(1,1:otherinfo.nother) = other_avg_velos;
        otherinfo.velocities(2,1:otherinfo.nother) = other_avg_velos_var;
        otherinfo.accelerations(1,1:otherinfo.nother) = other_avg_accel;
        otherinfo.accelerations(2,1:otherinfo.nother) = other_avg_accel_var;
    else
        otherinfo.nother = [];
        otherinfo.durations = [];
        otherinfo.onsets = [];
    end
    if ~isempty(unknown_keep)
        unknowninfo.nunknown = length(unknown_keep_begin);
        unknowninfo.durations = unknown_durations;
        unknowninfo.onsets = unknown_keep_begin;
        unknowninfo.velocities(1,1:unknowninfo.nunknown) = unknown_avg_velos;
        unknowninfo.velocities(2,1:unknowninfo.nunknown) = unknown_avg_velos_var;
        unknowninfo.accelerations(1,1:unknowninfo.nunknown) = unknown_avg_accel;
        unknowninfo.accelerations(2,1:unknowninfo.nunknown) = unknown_avg_accel_var;
    else
        unknowninfo.nunknown = [];
        unknowninfo.durations = [];
        unknowninfo.onsets = [];
    end
    
    classinfo.fixations = fixinfo;
    classinfo.saccades = sacinfo;
    classinfo.smoothpursuit = spinfo;
    classinfo.blinks = blinkinfo;
    classinfo.others = otherinfo;
    classinfo.unknown = unknowninfo;
    
    pointinfo.initial = length(fix_unknown) + length(sac_unknown);
    pointinfo.hmm = hmmstuckinone;
    pointinfo.bayes = still_unknown;
    
    
    %% Re-combine gap data with our resultant values
    % xyfinal = zeros(1, length(x));
    % xyfinal(find(~isnan(x))) = xy;
    %
    % xplot = zeros(1, length(x)); xplot(find(~isnan(x))) = fx;
    % yplot = zeros(1, length(y)); yplot(find(~isnan(y))) = fy;
    % cplot = zeros(1, length(x)); cplot(find(~isnan(x))) = st_hold; cplot(blink_index) = 4; cplot(cplot==0) = 4;
    % colors = ['r', 'g', 'b', 'y'];
    %
    %
    %
    % dafinal = nan(1, length(x));
    % dafinal(find(~isnan(x))) = da;
    %
    % fix_keep_final = new_indices(fix_keep);
    % sac_keep_final = new_indices(sac_keep);
    % still_unknown_final = new_indices(still_unknown);
    %
    % fix_keep_begin_final = new_indices(fix_keep_begin);
    % sac_keep_begin_final = new_indices(sac_keep_begin);
    %
    % %
    % % Plot final output
    % % keyboard
    % figure('Position', [1 41 1920 964])
    % subplot(413)
    % plot(0:st:length(dsfinal)*st-1,dsfinal,'b')
    % hold on
    % plot(repmat(vthresh, 1, ceil(length(dsfinal)*st)), 'Color', [0 0 0.7])
    % AX = axis;
    % axis([0 length(dsfinal)*st AX(3) AX(4)])
    %
    % % ###################
    % subplot(414)
    % plot(0:st:length(dafinal)*st-1,dafinal, 'm')
    % hold on
    % axis([0 length(dafinal)*st -20000 20000])
    % plot(repmat(minaccelspeed, 1, ceil(length(dafinal)*st)), 'Color', [0.7 0 .7])
    % plot(repmat(-1*minaccelspeed, 1, ceil(length(dafinal)*st)), 'Color', [0.7 0 .7])
    %
    % % ###################
    % subplot(4,1,1:2)
    % plot(0:st:length(xyfinal)*st-1,xyfinal, 'k')
    % % currlab = get(gca, 'xticklabel');
    % % set(gca, 'xticklabel', arrayfun(@(x) st*str2num(currlab(x,:)), [1:length(currlab)]))
    % axis([0 length(xyfinal)*st, min(500, min(xyfinal)- 100), max(1500, max(xyfinal) + 100)])
    % hold on
    % plot(fix_keep_final*st, xyfinal(fix_keep_final), 's', 'MarkerSize', 5, 'MarkerEdgeColor', [0 .7 0])
    % plot(sac_keep_final*st, xyfinal(sac_keep_final), 'v', 'MarkerSize', 5, 'MarkerEdgeColor', [0 0 .7])
    % plot(fix_keep_begin_final*st, xyfinal(fix_keep_begin_final), 'o', 'MarkerSize', 15, 'MarkerEdgeColor', [1 0 1])
    % if ~isempty(blink_index)
    %     plot(blink_index*st, xyfinal(blink_index), 'o', 'MarkerSize', 5, 'MarkerEdgeColor', [.9 .9 0])
    % end
    % if ~isempty(other_index)
    %     plot(other_index*st, xyfinal(other_index), 'o', 'MarkerSize', 5, 'MarkerEdgeColor', [.1 .1 0.1])
    % end
    % plot(still_unknown_final*st, xyfinal(still_unknown_final), 'o', 'MarkerSize', 15, 'MarkerEdgeColor', [.9 .9 0])
    % AX = axis;
    % axis([0 length(dsfinal)*st AX(3) AX(4)])
    % leg1 = legend('\surd(x^2+y^2)', 'Good Fixations', 'Good Saccades', 'Fix Begins', 'Blinks', 'Missing Data', 'Location', 'Best');
    % title('HMM Estimates')
    %
    % for fixd_text = 1:length(fix_keep_begin_final)
    %     text(fix_keep_begin_final(fixd_text)*st+5, xyfinal(fix_keep_begin_final(fixd_text))+50, num2str(round(fix_durations(2, fixd_text))))
    % end
    % pause
    % %%
    % % keyboard
    % close
    % % %% Time-series plotting
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
    %     text(1820, 100, num2str(tplot*st))
    %     drawnow
    %     pause(.001)
    %     cla
    %
    % end
    % pause
    
    
    
    %% Measures to send back to caller
    
    %     fix_lengths = [fix_keep_end - fix_keep_begin];
    %     sac_lengths = [sac_keep_end - sac_keep_begin];
    
    
    %% Smooth Pursuit Tagging
    % We will use two methods here, but both will work with a moving window.
    % The first method will look for low variance periods.  The second will
    % look for variance in the same direction, e.g. moving right/left or
    % up/down consistently during this period.
    
    % keyboard
    
    
    
    
    % keyboard
    
    % sp_variance_threshold = 5; %deg/sec
    % sp_velo_min = 8;
    % sp_max_sac_time = 100;
    %
    % % 1. Find periods where variance of velocity is below sp_variance_threshold
    % sp_flag = arrayfun(@(x) var(ds(x:x+sp_windowsize))<=sp_variance_threshold & ...
    %     mean(ds(x:x+sp_windowsize))>=sp_velo_min,  [1:length(ds)-sp_windowsize]);
    % sp_indx = find(sp_flag);
    % for i = sp_indx
    %     sp_flag(i:i+sp_windowsize) = 1;
    % end
    % sp_indx = find(sp_flag);
    %
    % sp_begin = [1, find(diff(sp_indx)>1)+1]; %beginning of sp epochs
    % sp_end = [find(diff(sp_indx)>1), length(sp_indx)]; %end of sp epochs
    %
    % for sp_iter = 1:length(sp_begin)
    %     [xm(sp_iter), xr(sp_iter)] = findslope(st*(1:sp_end(sp_iter)-sp_begin(sp_iter)+1), x(sp_begin(sp_iter):sp_end(sp_iter)),1);
    %     [ym(sp_iter), yr(sp_iter)] = findslope(st*(1:sp_end(sp_iter)-sp_begin(sp_iter)+1), y(sp_begin(sp_iter):sp_end(sp_iter)),1);
    % end
    % xqual = zeros(1, length(xm));
    % yqual = zeros(1, length(ym));
    %
    % xqual(abs(xm)>2 & xr>.5)=1;
    % yqual(abs(ym)>2 & yr>.5)=1;
    %
    % % 2. Find points when x or y (independently) move consistently in one
    % % direction over a length of time greater than a saccade duration.
    % % dx = diff(x);
    % % dy = diff(y);
    
    % 3. Try just a moving window, finding the slope and r^2, keeping only
    % those above threshs
    % Initilize some global parameters
    % close all
    % mthresh_low = 1.5;
    % mthresh_high = vthresh;
    % rthresh = .75;
    % sp_windowsize = 100;
    % loop = 1;
    % % for sp_windowsize = [100, 150, 200]; %points
    % %     sp_windowsize = floor(sp_windowsize/st);
    % %     for mthresh = [1.5, 2]
    % %         for rthresh = [.75 .8]
    %
    %
    %
    %
    % for sp_win = 1:length(x)-sp_windowsize
    %     if all(~isnan(x(sp_win:sp_win+sp_windowsize-1)))
    %         [xm(sp_win), xr(sp_win)] = findslope((0:sp_windowsize-1), x(sp_win:sp_win+sp_windowsize-1), 1);
    %     else
    %         xm(sp_win) = NaN; xr(sp_win) = NaN;
    %     end
    %     if all(~isnan(y(sp_win:sp_win+sp_windowsize-1)))
    %         [ym(sp_win), yr(sp_win)] = findslope((0:sp_windowsize-1), y(sp_win:sp_win+sp_windowsize-1), 1);
    %     else
    %         ym(sp_win) = NaN; yr(sp_win) = NaN;
    %     end
    % end
    %
    % xm(end+1:length(d)) = NaN; %xm = xm * 1000;
    % xr(end+1:length(d)) = NaN; %ym = ym * 1000;
    % xm = (atand((xm/2)./(d*pix_to_angle_const))*2)*1000/st; %x distance in (degrees / second)
    %
    % xqual = zeros(1, length(xm));
    % xnqi = xqual;
    %
    % xqi = find(abs(xm)>=mthresh_low & xr>=rthresh & abs(xm) <= mthresh_high);
    % xnqi(abs(xm)<mthresh_low) = 2;
    % xnqi(abs(xm)>mthresh_high) = 3;
    % xnqi(xr<rthresh) = 4;
    % % keyboard
    % % xqi = unique(cell2mat(arrayfun(@(x) x:x+sp_windowsize, xqi, 'uni', 0)));
    %
    % xq_begin = [xqi(1), xqi(find(diff(xqi)>1)+1)]; %location of beginning of fixations
    % xq_end = [xqi(find(diff(xqi)>1)), length(xqi)]; %location of end of fixations
    % xq_thresh = xq_end - xq_begin + 1 >= floor(sp_windowsize/st); %index of fixation beginnings where duration >= threshold
    % xq_keep_begin = xq_begin(xq_thresh); %fix_begin when above threshold
    % xq_keep_end = xq_end(xq_thresh); %fix_begin when above threshold
    % xq_keep_all = unique(cell2mat(arrayfun(@(x) xq_keep_begin(x):xq_keep_end(x), [1:length(xq_keep_begin)], 'uni', 0)));
    %
    % xqual(xq_keep_all) = 1;
    %
    % ym(end+1:length(d)) = NaN;
    % yr(end+1:length(d)) = NaN;
    % ym = (atand((ym/2)./(d*pix_to_angle_const))*2)*1000/st; %x distance in (degrees / second)
    %
    % yqual = zeros(1, length(ym));
    % ynqi = yqual;
    %
    % yqi = find(abs(ym)>=mthresh_low & yr>=rthresh & abs(ym) <= mthresh_high);
    % ynqi(abs(ym)<mthresh_low) = 2;
    % ynqi(abs(ym)>mthresh_high) = 3;
    % ynqi(yr<rthresh) = 4;
    %
    % % yqi = unique(cell2mat(arrayfun(@(y) y:y+sp_windowsize, yqi, 'uni', 0)));
    %
    % yq_begin = [yqi(1), yqi(find(diff(yqi)>1)+1)]; %location of beginning of fiyations
    % yq_end = [yqi(find(diff(yqi)>1)), length(yqi)]; %location of end of fiyations
    % yq_thresh = yq_end - yq_begin + 1 >= floor(sp_windowsize/st); %indey of fiyation beginnings where duration >= threshold
    % yq_keep_begin = yq_begin(yq_thresh); %fiy_begin when above threshold
    % yq_keep_end = yq_end(yq_thresh); %fiy_begin when above threshold
    % yq_keep_all = unique(cell2mat(arrayfun(@(y) yq_keep_begin(y):yq_keep_end(y), [1:length(yq_keep_begin)], 'uni', 0)));
    %
    % yqual(yq_keep_all) = 1;
    %
    % xyqual = xqual | yqual;
    %
    %
    %
    % figure(loop)
    % % plot(ds)
    %
    % subplot(211)
    %
    %
    % % plot(find(xnqi==2), x(xnqi==2), 'bo', 'markersize', 3) %too slow
    % % plot(find(xnqi==4), x(xnqi==4), 'go', 'markersize', 3) %poor fit
    % % plot(find(xqual), x(find(xqual)), 'ro', 'markersize', 3)
    % plot(find(xqual), x(find(xqual)), 'ro', 'markersize', 3)
    % hold on
    % plot(x, 'k')
    %
    % subplot(212)
    %
    % % plot(find(yqual), y(find(yqual)), 'mo', 'markersize', 3)
    % plot(find(yqual), y(find(yqual)), 'go', 'markersize', 3)
    % hold on
    % hold on
    % plot(y, 'b')
    %
    % figure(2)
    % subplot(211)
    % plot(xm, 'k')
    % hold on
    % plot(ym)
    % subplot(212)
    % plot(xr, 'k')
    % hold on
    % plot(yr)
    %
    % figure(3)
    % subplot(211)
    % hist(xnqi, 0:4)
    % subplot(212)
    % hist(ynqi, 0:4)
    %
    %
    % keyboard
    % loop = loop + 1;
    %         end
    %     end
    % end
    return
end









