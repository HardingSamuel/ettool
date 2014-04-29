% an_ettgfconvert

% To convert data in ETTool (V1.0) format for use in GraFIX manual coding
% method

function an_ettgfconvert(DIRECT,SUBJECT,TRIALS,mode,procdata)


%% Checks and Initial errors
if isempty(DIRECT) || ~exist([DIRECT, '\MATLAB\INPUT\PROCDATA\'],'dir')
    error('Please specify a valid ETTool Directory')
end
startdir = pwd;

if isempty(procdata)
    disp('Loading most recent procdata file')
    s = [DIRECT '\MATLAB\INPUT\PROCDATA\'];
    cd(s)
    D = dir('*.mat');
    if ~isempty(D)
        dates = [D.datenum];
        [~,mostrecent] = max(dates);
        load([s, '\', D(mostrecent).name])
    end
end
cd(startdir)

if isempty(SUBJECT) || SUBJECT > length(procdata.sub)
    error('Please specify a subject to convert.  Subject Number is based on the index in ''PROCDATA''')
end

if isempty(TRIALS)
    disp('Trials not defined, analyzing all trials for this subject')
    TRIALS = (1:length(procdata.sub(SUBJECT).Trial));
end

if max(TRIALS) > length(procdata.sub(SUBJECT).Trial)
    error('Trial numbers given exceeds trials found in PROCDATA')
end

%% Prepare outputs

if ~exist([DIRECT, '\MATLAB\INPUT\GRAFIX\'], 'dir')
    [SUCCESS,MESSAGE,MESSAGEID] = mkdir([DIRECT, '\MATLAB\INPUT\'], 'GRAFIX');
    if SUCCESS ~= 1
        error([MESSAGE, '-', MESSAGEID])
    end
end
if ~exist([DIRECT, '\MATLAB\INPUT\GRAFIX\' num2str(SUBJECT),'\'],'dir')
    [SUCCESS,MESSAGE,MESSAGEID] = mkdir([DIRECT, '\MATLAB\INPUT\GRAFIX'], num2str(SUBJECT));
    if SUCCESS ~= 1
        error([MESSAGE, '-', MESSAGEID])
    end
end


rawinputfile = zeros(0,8); segmentsinputfile = zeros(0,3);
smoothinputfile = zeros(0,11); newfix = zeros(0,8);

%% Start Converting
disp('Beginning Conversion')

t_firstrow = 1;
t_lastrow = 0;
seg_count = 0;
lastlen = 0;

for trinum = TRIALS
    % Check rial integrity
    try
        rawthistrial = [procdata.sub(SUBJECT).Trial(trinum).Time(1,:)',...
            zeros(length(procdata.sub(SUBJECT).Trial(trinum).Time(1,:)),1),...
            procdata.sub(SUBJECT).Trial(trinum).eye(1).GazeX(1,:)',...
            procdata.sub(SUBJECT).Trial(trinum).eye(1).GazeY(1,:)',...
            procdata.sub(SUBJECT).Trial(trinum).eye(2).GazeX(1,:)',...
            procdata.sub(SUBJECT).Trial(trinum).eye(2).GazeY(1,:)',...
            procdata.sub(SUBJECT).Trial(trinum).eye(1).Pupil(1,:)',...
            procdata.sub(SUBJECT).Trial(trinum).eye(2).Pupil(1,:)'];
        t_lastrow = t_lastrow + size(rawthistrial,1);
        rawinputfile = cat(1,rawinputfile,rawthistrial);
        seg_count = seg_count + 1;
        segmentsinputfile = cat(1,segmentsinputfile,[seg_count,t_firstrow,t_lastrow]);
        t_firstrow = t_firstrow + size(rawthistrial,1);
        
    catch
        disp(['The lengths of the various segments may not be valid, skipping trial ', num2str(trinum)])
    end
    
    switch mode
        case 1
            time = procdata.sub(SUBJECT).Trial(trinum).Time;
            eye1 = procdata.sub(SUBJECT).Trial(trinum).eye(1);
            eye2 = procdata.sub(SUBJECT).Trial(trinum).eye(2);
            sr = procdata.sub(SUBJECT).SampleRate;
            
            %Begin cleaning / interpolation
            %
            [processed, ~, gapdata] = clean_interpV1_1(time, eye1, eye2, sr);
            
            time = procdata.sub(SUBJECT).Trial(trinum).Time(1,:)-procdata.sub(SUBJECT).Trial(trinum).Time(1,1);
            x = processed.GazeX * 1920;
            y = processed.GazeY * 1080;
            d = processed.Distance;
            sr = procdata.sub(SUBJECT).SampleRate;
            fff = 2;
            wo = procdata.sub(SUBJECT).Trial(trinum).WhatsOn;
            
            [classinfo,~,velo,outx,outy,outd] = FS_GFport(x,y,d,sr,gapdata,fff,40,50,wo,0,0);
            
            outx(isnan(outx)) = 0; outy(isnan(outy)) = 0; outd(isnan(outd)) = 0; velo(isnan(velo)) = 0;
            
            allsacs = zeros(length(outx),1);
            allsacs(cat(2,cell2mat(arrayfun(@(X) classinfo.saccades.onsets(1,X):classinfo.saccades.offsets(1,X), 1:classinfo.saccades.count,'uni',0)))) = 1;
            
            smooththistrial = [time',...
                zeros(length(time),1),...
                outx',...
                outy',...
                velo',...
                allsacs,...
                zeros(length(outx),5)];
            
            smoothinputfile = cat(1,smoothinputfile,smooththistrial);
            
            fixthistrial = [(classinfo.fixations.onsets(1,:)+lastlen)',...
                (classinfo.fixations.offsets(1,:)+lastlen)',...
                (classinfo.fixations.durations(2,:)/1000)',...
                classinfo.fixations.centroids(1,:)',...
                classinfo.fixations.centroids(2,:)',...
                zeros(classinfo.fixations.count,3)];
            
            newfix = cat(1,newfix,fixthistrial);
            lastlen = lastlen + length(time);
    end
end

%% Save the output csvs
datafname = strcat(DIRECT, '\MATLAB\INPUT\GRAFIX\', num2str(SUBJECT), '\S', num2str(SUBJECT), '_INPUT_DATA.csv');
segfname = strcat(DIRECT, '\MATLAB\INPUT\GRAFIX\', num2str(SUBJECT), '\S', num2str(SUBJECT), '_INPUT_SEGMENTS.csv');

csvwrite(datafname,rawinputfile);
csvwrite(segfname,segmentsinputfile);

switch mode
    case 1
        smoothfname = strcat(DIRECT, '\MATLAB\INPUT\GRAFIX\', num2str(SUBJECT), '\smooth_', num2str(SUBJECT), '.csv');
        fixfname = strcat(DIRECT, '\MATLAB\INPUT\GRAFIX\', num2str(SUBJECT), '\fix_auto_', num2str(SUBJECT), '.csv');
        csvwrite(smoothfname,smoothinputfile);
        csvwrite(fixfname,newfix);
end

disp(['Finished Converting Trials ' num2str(TRIALS(1)) ':' num2str(TRIALS(end)) ' for Subject ' num2str(SUBJECT)])
end

