function [status] = pop_ProcessV1_3_1(Direct, subslist, analyoutput, customfileexe)

%% EPrime Process.
%   Processes organized raw data and resaves it into procdata.mat
% 
%   Version Log:
%     V1.0 - Sam Harding
%       :creation and design - based loosely off InfantPointingReadInV6 (Ty
%       W. Boyer)
%     V1.1 - SH (10/2/13)
%       :editing to fit into new folder oganization, vectorized
%     V1.2 - SH (TBD)
%       :generalization for generic study design
%   [SH] - 10/29/13:  Pop functionality to be called from ui 
%   [SH] - 12/12/13:  Small edits, like updated folder names, making AOI
%   information work.
%   [SH] - 01/24/14:  FixSac now runs +SmoothPursuit version.
%   [SH] - 01/27/14:  FixSac now offers two options from
%   pop_analysisselect:  1 returns Fix/Sac, no SP
%                        4 returns Fix/Sac, + SP
%   [SH] - 01/28/14:  Added custom Processing for study-specific analyses.

VersionNumber = 1.0;
VersionNumberString = '1_0';
currenttime = clock;

sla = strfind(Direct, '\');
StudyName = Direct(sla(end)+1:end);

%load most-recently calculated RAWDATA file
disp('Loading RAW Data File')
s = [Direct '\MATLAB\INPUT\RAWDATA'];
cd(s)
D = dir('*.mat');
try 
    dates = [D.datenum];
    [~,mostrecent] = max(dates);    
    load([s, '\', D(mostrecent).name])
catch
    status = 'Cannot Locate RAW data file in \MATLAB\INPUT\RAWDATA';
    return
end
    
disp('Loading Proc Data File')
s = [Direct '\MATLAB\INPUT\PROCDATA\'];
cd(s)
D = dir('*.mat');
if ~isempty(D)
    dates = [D.datenum];
    [~,mostrecent] = max(dates);
    load([s, '\', D(mostrecent).name])
end

ChangedSubs = 0;

for subn = subslist
    
    ChangedSubs = ChangedSubs + 1;
    procdata.sub(subn).SampleRate = rawdata.sub(subn).SampleRate;
    procdata.sub(subn).SubjectNumber = rawdata.sub(subn).SubjectNumber;
    procdata.sub(subn).version = VersionNumber;
    procdata.sub(subn).AgeMonths = rawdata.sub(subn).AgeMonths;
    procdata.sub(subn).AgeDays = rawdata.sub(subn).AgeDays;
    
    disp(['Processing Subject ', num2str(subn)])
    
    for trinum = 1:length(rawdata.sub(subn).Trial)       
        
        
        
        if ~isempty(rawdata.sub(subn).Trial(trinum))
            
            if trinum == length(rawdata.sub(subn).Trial)       
                fprintf([ '[', num2str(length(rawdata.sub(subn).Trial)), ']'])
            else
                if rem(trinum,10) ~= 0
                    fprintf('.')
                else
                    fprintf(num2str(trinum))
                end
                if rem(trinum,50)+1 == 1
                    fprintf('\n')
                end
            end
                
            procdata.sub(subn).Trial(trinum).usecustom = 0;
            %Define the values to pass along to the clean-up/interpolation script

            time = rawdata.sub(subn).Trial(trinum).Time;
            eye1 = rawdata.sub(subn).Trial(trinum).eye(1);
            eye2 = rawdata.sub(subn).Trial(trinum).eye(2);
            sr = rawdata.sub(subn).SampleRate;

            %Begin cleaning / interpolation
            %   
            [processed, gooddata, gapdata] = clean_interpV1_1(time, eye1, eye2, sr);

            processed.GazeX = processed.GazeX * 1920;
            processed.GazeY = processed.GazeY * 1080;
            
            procdata.sub(subn).Trial(trinum).Processed = processed;
            procdata.sub(subn).Trial(trinum).Time = rawdata.sub(subn).Trial(trinum).Time;
            procdata.sub(subn).Trial(trinum).GoodData = gooddata;
            
            procdata.sub(subn).Trial(trinum).WhatsOn = rawdata.sub(subn).Trial(trinum).WhatsOn;
            
%           find field names from rawdata and move them to procdata
            fn = fieldnames(rawdata.sub(subn).Trial);

            for fillfield = 1:length(fn)                
                procdata.sub(subn).Trial(trinum).(char(fn(fillfield))) = rawdata.sub(subn).Trial(trinum).(char(fn(fillfield)));
            end
            
            % define new variables that are easier to send off to other
            % scripts
            x = processed.GazeX;
            y = processed.GazeY;
            d = processed.Distance;
            V = processed.Validity;
            p = processed.Pupil;
            t = procdata.sub(subn).Trial(trinum).Time;
            wo = procdata.sub(subn).Trial(trinum).WhatsOn;   
            
            
            if analyoutput(1) || analyoutput(5)
%                 keyboard
                [classinfo, pointinfo] = fixsacv1_1_2FORVALID_SPattmpt(x,y,d,sr,gapdata,2,40,150,procdata.sub(subn).Trial(trinum).WhatsOn, analyoutput(5));
                procdata.sub(subn).Trial(trinum).Classifications = classinfo;  
                procdata.sub(subn).Trial(trinum).PointInfo = pointinfo;
            else
                if isfield(procdata.sub(subn).Trial(trinum), 'Classifications')
                    classinfo = procdata.sub(subn).Trial(trinum).Classifications;
                    pointinfo = procdata.sub(subn).Trial(trinum).PointInfo;
                end
            end
            
            if analyoutput(2)
                [inStim, inTarget, RT] = StimRT(x,y,d,t(2,:),wo, procdata.sub(subn).Trial(trinum).TargetSide, 1000/sr);                
                procdata.sub(subn).Trial(trinum).InStimAOI = inStim;
                procdata.sub(subn).Trial(trinum).InTargetAOI = inTarget;
                procdata.sub(subn).Trial(trinum).RT = RT;
            end
            
            if analyoutput(3)
                
                [aoimat] = AOI_definelocations(Direct);
%                 [studydata] = ActionTracking(fn);
                % stimcode = index for reference within the aoimat
                % structure.  When we make it (in AOI_definelocations), we
                % use indices for different stims.  Within each stim,
                % unique aois are defined.  We need to tell aoi_calc which
                % stimulus we ran on this trial, so it can look at the
                % appropriate locations for calculating proportions.
                vidnames = [{'Bear1'}, {'Bear2'}, {'Bear3'}, {'Crayons1'}, {'Cup1'}, {'Cup2'}, {'Cup4'}, {'Cup5'}, {'Present2'}, {'Present3'}, {'Puzzle1'}, ...
                    {'Rings1'}, {'Rings2'}, {'Rings4'}, {'Scissors4'}, {'Shapes4'}];
                stimcode = find(strcmp(procdata.sub(subn).Trial(trinum).VideoType, vidnames));
                
                vfr = 30;                
                procdata.sub(subn).Trial(trinum).proportions = aoi_calcV1_0(x,y,t(2,:),wo,stimcode,aoimat,sr,vfr);
                                
            end
            
            if analyoutput(4) && ~isempty(customfileexe)
                try
                eval(customfileexe)
                procdata.sub(subn).Trial(trinum).usecustom = 1;
                catch
                    keyboard
                end
            end

        end

    end
   
    fprintf('\n')
end


[filename,currenttime] = updatefileinfo(Direct, StudyName, 2); 

if ~isfield(procdata, 'version')
    procdata.version.CreationDate = currenttime;
    procdata.version.EditLog = {currenttime, VersionNumber, ChangedSubs};
else
    procdata.version.EditLog = [procdata.version.EditLog; {currenttime, VersionNumber, ChangedSubs}];
end
procdata.version.LastEdit = currenttime;

fprintf('\n')
fprintf('\n')
disp('Saving')

save(filename, 'procdata')     

fprintf('\n')
disp('#### PROCESS COMPLETE! ####')


status = 'Process Complete!';
return