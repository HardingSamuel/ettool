function [status] = pop_ReadIn(Direct, subslist, coldata)

%% EPrime Read-In.
%   Reads in Raw Data from EPrime format, organizes, saves to RAWDATA.mat
%
%
%   [SH] - 10/25/13:  Generalization for all studies.  Certain parameters
%   will vary widely from study-to-study such as the organization of
%   gaze-data files.  These differences should be determined without
%   additional user input.

%   [SH] - 10/28/13:  Pop functionality to be called from ui
%   [SH] - 10/28/13:  Importing columns from coldata
%   [SH] - 11/08/13:  Fixed to read Summary based on study name (line32)
%   [SH] - 01/14/14:  Corrected path issue for \INPUT\RAWDATA




VersionNumber = 1.2;
VersionNumberString = '1_2_2';
currenttime = clock;

%Directory of XLS Files
s = [Direct '\MATLAB\INPUT\DATA\XLSDATA'];
D = dir(s);
CurrentDir = Direct;
sla = strfind(CurrentDir, '\');
StudyName = CurrentDir(sla(end)+1:end);


try
    [subnum, substr, subraw] = xlsread([CurrentDir, '\EXCEL\' StudyName 'SUMMARY.xlsx'], 'Participants');
catch
    status = 'Unable to locate Subject Info File';
    return
end

%load most-recently calculated file
s = [Direct '\MATLAB\INPUT\RAWDATA\'];
cd(s)
D = dir('*.mat');
if ~isempty(D)
    dates = [D.datenum];
    [~,mostrecent] = max(dates);
    
    
    disp('Loading Existing Data File')
    load([s, '\', D(mostrecent).name])
end

s = [Direct '\MATLAB\INPUT\DATA\XLSDATA'];
D = dir(s);

%Trial-Number column
tnc = find(coldata(2,:) == 1);
%Phase column
phc = find(coldata(2,:) == 2);


%Loop through every subject
ChangedSubs = 0;
for sub = subslist+2
    
    %     if sub >= 3 %> length(rawdata.sub) || isempty(rawdata.sub(sub).Trial)
    
    subn = sub - 2;
    ChangedSubs = ChangedSubs + 1;
    %Open the respective Data File
    disp(['Loading Subject Data ' num2str(subn)])
    num = []; str = []; raw = [];
    
    [num, str, raw] = xlsread([s, '\', D(sub).name]);
    vcn = [str(1,24:end)];
    
    %Fix random instances of weird values??
    %left eye
    [BLR, BLC] = find(isnan(num(:,10:15)));
    num(BLR, 10:15) = repmat([-1 -1 -1 -1 -1 -1], length(BLR), 1);
    %right eye
    [BRR, BRC] = find(isnan(num(:, 17:22)));
    num(BRR, 17:22) = repmat([-1 -1 -1 -1 -1 -1], length(BRR), 1);
    
    %Find Indices where new trials begin
    NewTrialIndex = [2, find(diff(num(1:end, 23+tnc)) ~= 0)'+2];
    TotalTrials = length(NewTrialIndex);
    
    FullSubN = str2num(D(sub).name(end-9:end-7));
    PartIndex = find(subnum(:,1) == FullSubN);
    
    srchoice = [1000/60, 1000/120, NaN, NaN, 1000/300];
    tdiff = mean(diff(num(1:end, 5)));
    
    rawdata.sub(subn).SampleRate = 60 * find(min(abs(tdiff - srchoice))==abs(abs(tdiff - srchoice)));
    rawdata.sub(subn).SubjectNumber = FullSubN;
    
    %Grabbing Values
    for t_iter = 1:TotalTrials
        
        if t_iter == TotalTrials
            fprintf(['[', num2str(TotalTrials), ']'])
        else
            if rem(t_iter,10) ~= 0
                fprintf('.')
            else
                fprintf(num2str(t_iter))
            end
            if rem(t_iter,50)+1 == 1
                fprintf('\n')
            end
        end
        
        %start & stop values
        bgn = NewTrialIndex(t_iter);
        if t_iter ~= TotalTrials
            ennd = NewTrialIndex(t_iter+1)-1;
        else
            ennd = length(num);
        end
        
        %Record Version History
        rawdata.sub(subn).version = VersionNumber;
        
        %Subject Info
        rawdata.sub(subn).AgeMonths = subnum(PartIndex,6);
        rawdata.sub(subn).AgeDays = subnum(PartIndex,7);
        
        %Grab Time Column
        rawdata.sub(subn).Trial(t_iter).Time = num(bgn-1:ennd, 5)';
        %Generate a second row of times, relative to the first point (i.e.
        %how much time has elapsed so far in THIS trial)
        rawdata.sub(subn).Trial(t_iter).Time = cat(1, rawdata.sub(subn).Trial(t_iter).Time, rawdata.sub(subn).Trial(t_iter).Time - rawdata.sub(subn).Trial(t_iter).Time(1));
        
        rawdata.sub(subn).Trial(t_iter).TrialNum = t_iter;
        
        %Grab the 'WhatsOn / PhaseOfTheTrial' Information
        PhaseVec = str(bgn:ennd, 23+phc)';
        %Separate out only unique instances (removes repitition), find
        %indices where uniques first occur
        [~, PhaseIndex] = unique(PhaseVec, 'first');
        
        %Place Names and Indices in a Structure for reference in the
        %future
        rawdata.sub(subn).Trial(t_iter).WhatsOn.Names = PhaseVec(sort(PhaseIndex))';
        rawdata.sub(subn).Trial(t_iter).WhatsOn.Indices = sort(PhaseIndex);
        
        %Place condition information into matrix
        for input_conditions = 1:size(coldata, 2)
            if coldata(2, input_conditions)==3
                if coldata(3, input_conditions) == 1
                    rawdata.sub(subn).Trial(t_iter).(char(vcn(input_conditions))) = num(bgn-1, 23+input_conditions);
                elseif coldata(3, input_conditions) == 2
                    rawdata.sub(subn).Trial(t_iter).(char(vcn(input_conditions))) = char(str(bgn, 23+input_conditions));
                end
            end
        end        
        
        rawdata.sub(subn).Trial(t_iter).eye(1).GazeX = num(bgn-1:ennd, 10)';
        rawdata.sub(subn).Trial(t_iter).eye(1).GazeY = num(bgn-1:ennd, 11)';
        rawdata.sub(subn).Trial(t_iter).eye(1).Distance = num(bgn-1:ennd, 15)';
        rawdata.sub(subn).Trial(t_iter).eye(1).Validity = single(num(bgn-1:ennd, 16)');
        rawdata.sub(subn).Trial(t_iter).eye(1).Pupil = num(bgn-1:ennd, 14)';
        rawdata.sub(subn).Trial(t_iter).eye(2).GazeX = num(bgn-1:ennd, 17)';
        rawdata.sub(subn).Trial(t_iter).eye(2).GazeY = num(bgn-1:ennd, 18)';
        rawdata.sub(subn).Trial(t_iter).eye(2).Distance = num(bgn-1:ennd, 22)';
        rawdata.sub(subn).Trial(t_iter).eye(2).Validity = single(num(bgn-1:ennd, 23)');
        rawdata.sub(subn).Trial(t_iter).eye(2).Pupil = num(bgn-1:ennd, 21)';
    end
    
    fprintf('\n')
    disp(['Done Processing Subject ', num2str(subn)])
    %     end
end

DatafileName = [Direct, '\MATLAB\INPUT\RAWDATA\RAWDATA_', StudyName '_VersionNumber_', VersionNumberString, '_', date, '_', num2str(currenttime(4)), num2str(currenttime(5))];
if ~isfield(rawdata, 'version')
    rawdata.version.CreationDate = [date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))];
    rawdata.version.EditLog = {[date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))], VersionNumber, ChangedSubs};
else
    rawdata.version.EditLog = [rawdata.version.EditLog; {[date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))], VersionNumber, ChangedSubs}];
end
rawdata.version.LastEdit = [date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))];

fprintf('\n')
fprintf('\n')
disp('Saving')

save(DatafileName, 'rawdata')

fprintf('\n')
disp('#### READ-IN COMPLETE! ####')

status = 'Read-In Complete!';
return