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


clear all

VersionNumber = 1.2;
AOIVersionNumber = 1.1;

%Directory of RAWDATA File
s = 'INPUT\RAWDATA';
D = dir(s);
CurrentDir = cd;
sla = strfind(CurrentDir, '\');
StudyName = CurrentDir(sla(2)+1:sla(3)-1);

disp('Loading RAW Data File')
load([cd, '\', s, '\', D(3).name])

ChangedSubs = 0;

% AOI_definelocations(CurrentDir(1:sla(3)))
tlen = [];
variance = [];
tcounter = 1;

for subn = 1:length(rawdata.sub)
    
    ChangedSubs = ChangedSubs + 1;
    procdata.sub(subn).SampleRate = rawdata.sub(subn).SampleRate;
    procdata.sub(subn).SubjectNumber = rawdata.sub(subn).SubjectNumber;
    disp(['Processing Subject ', num2str(subn)])
    
    for trinum = 1:length(rawdata.sub(subn).Trial)       
        
        if ~isempty(rawdata.sub(subn).Trial)
            
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
                
            %Define the values to pass along to the clean-up/interpolation script

            time = rawdata.sub(subn).Trial(trinum).Time;
            eye1 = rawdata.sub(subn).Trial(trinum).eye(1);
            eye2 = rawdata.sub(subn).Trial(trinum).eye(2);
            sr = rawdata.sub(subn).SampleRate;

            %Begin cleaning / interpolation
            %   :final value is window over which to interpolate (in pts)
            [processed, gooddata, gapdata] = clean_interp(time, eye1, eye2, sr);
        
            processed.GazeX = processed.GazeX * 1920;
            processed.GazeY = processed.GazeY * 1080;
            
            procdata.sub(subn).Trial(trinum).eye = processed;
            procdata.sub(subn).Trial(trinum).Time = rawdata.sub(subn).Trial(trinum).Time;
            procdata.sub(subn).Trial(trinum).GoodData = gooddata;
            
            procdata.sub(subn).Trial(trinum).WhatsOn = rawdata.sub(subn).Trial(trinum).WhatsOn;
            procdata.sub(subn).Trial(trinum).Stimulus = rawdata.sub(subn).Trial(trinum).Stimulus;
            procdata.sub(subn).Trial(trinum).StimDir = rawdata.sub(subn).Trial(trinum).StimDir;
            procdata.sub(subn).Trial(trinum).TargetSide = rawdata.sub(subn).Trial(trinum).TargetSide;
            procdata.sub(subn).Trial(trinum).Congruence = rawdata.sub(subn).Trial(trinum).Congruence;
            procdata.sub(subn).Trial(trinum).Probe = rawdata.sub(subn).Trial(trinum).Probe;
            procdata.sub(subn).Trial(trinum).AG = rawdata.sub(subn).Trial(trinum).AG;
            
            x = processed.GazeX;
            y = processed.GazeY;
            d = processed.Distance;
            V = processed.Validity;
            p = processed.Pupil;
            t = procdata.sub(subn).Trial(trinum).Time;
%             keyboard
            [inStim, inTarget, RT] = StimRT(x,y,d,t(2,:),procdata.sub(subn).Trial(trinum).WhatsOn, procdata.sub(subn).Trial(trinum).TargetSide, 1000/sr);
            
            procdata.sub(subn).Trial(trinum).InStimAOI = inStim;
            procdata.sub(subn).Trial(trinum).InTargetAOI = inTarget;
            procdata.sub(subn).Trial(trinum).RT = RT;


            [fixinfo, sacinfo, pointinfo, variance(tcounter)] = fixsac(x,y,d,sr,gapdata,2);
            procdata.sub(subn).Trial(trinum).Fixations = fixinfo;
            procdata.sub(subn).Trial(trinum).Saccades = sacinfo;
            
            tlen(tcounter) = procdata.sub(subn).Trial(trinum).Time(2,end);
%             keyboard
%             aoi_calc
            tcounter = tcounter + 1;

        end

    end
   
    %     keyboard
    fprintf('\n')
end


% figure
% plot(tlen,variance,'+')


currenttime = clock;
if ~isfield(procdata, 'version.CreationDate')
    procdata.version.CreationDate = [date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))];
    procdata.version.EditLog = {[date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))], VersionNumber, ChangedSubs};
else
procdata.version.EditLog = [procdata.version.EditLog; {[date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))], VersionNumber, ChangedSubs}];
end
procdata.version.LastEdit = [date, '-', num2str(currenttime(4)), ':', num2str(currenttime(5)), ':', num2str(currenttime(6))];

fprintf('\n')
fprintf('\n')
disp('Saving')

DatafileName = [cd, '\INPUT\PROCDATA\PROCDATA_', StudyName];
save(DatafileName, 'procdata')     

fprintf('\n')
disp('#### PROCESS COMPLETE! ####')