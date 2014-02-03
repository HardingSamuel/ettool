function [status] = pop_SummaryV1_1(Direct, subslist, coldata)


% SummaryV1
%
% Summarizes processed data into Excel pivot-sheet format.

%   [SH] - 10/30/13:  Modified to run through ui



VersionNumber = 1.1;
VersionNumberString = '1_1';
currenttime = clock;


%Directory of PROC Files
s = [Direct '\MATLAB\INPUT\PROCDATA'];
D = dir(s);
CurrentDir = Direct;
sla = strfind(CurrentDir, '\');
StudyName = CurrentDir(sla(end)+1:end);


%load most-recently calculated file
disp('Loading PROC Data File')
cd(s)
D = dir('*.mat');
try 
    dates = [D.datenum];
    [~,mostrecent] = max(dates);
    load([s, '\', D(mostrecent).name])
catch
    status = 'Cannot Locate PROC data file in \MATLAB\INPUT\PROCDATA';
    return
end
    
% 
% disp('Loading Proc Data File')
% s = [Direct '\MATLAB\INPUT\PROCDATA\'];
% cd(s)
% D = dir('*.mat');
% if ~isempty(D)
%     dates = [D.datenum];
%     [~,mostrecent] = max(dates);
%     load([s, '\', D(mostrecent).name])
% end

ChangedSubs = 0;


%Directory of PROCDATA File
s = 'INPUT\PROCDATA';
D = dir(s);
CurrentDir = cd;
sla = strfind(CurrentDir, '\');
StudyName = CurrentDir(sla(end-1)+1:sla(end)-1);

writeme = [{'Subject'}, {'Trial'}, {'SOA'}, {'SampleRate'}, {'GoodDataBefore'}, {'GoodDataAfter'}, {'Stimulus'}, {'StimDirection'}, {'TargetSide'}, {'Congruence'}, {'Probe'}, {'AttGet'}, ...
    {'EP_inStim'}, {'US_inStim'}, {'EP_inTarg'}, {'US_inTarg'}, {'ReactionTime'}];

for writesub = 1:length(procdata.sub)
    if ~isempty(procdata.sub(writesub))
        
        sr = procdata.sub(writesub).SampleRate;
        subwrite = cell(length(procdata.sub(writesub).Trial), 17);
        subn = procdata.sub(writesub).SubjectNumber;
        
        for writetrial = 1:length(procdata.sub(writesub).Trial)
            
            gdb = 'na'; gda = 'na'; stim = 'na'; stimdir = 'na'; tside = 'na'; cong = 'na';
            probe = 'na'; ag = 'na'; instim_EP = 'na'; instim_US = 'na'; intarg_EP = 'na';
            intarg_US = 'na'; rt = 'na'; soa = 'na';
            
            gdb = procdata.sub(writesub).Trial(writetrial).GoodData.before;
            gda = procdata.sub(writesub).Trial(writetrial).GoodData.after;
            stim = procdata.sub(writesub).Trial(writetrial).Stimulus;
            stimdir = procdata.sub(writesub).Trial(writetrial).StimDirection;
            tside = procdata.sub(writesub).Trial(writetrial).TargetSide;
            cong = procdata.sub(writesub).Trial(writetrial).Congruence;
            probe = procdata.sub(writesub).Trial(writetrial).Probe;
            ag = procdata.sub(writesub).Trial(writetrial).AttGetter;
            
            if isempty(ag)
                ag = 1;
            end
            if isempty(probe)
                probe = 1;
            end
            
            instim_EP = procdata.sub(writesub).Trial(writetrial).InStimAOI(1);
            instim_US = procdata.sub(writesub).Trial(writetrial).InStimAOI(2);
            
            intarg_EP = procdata.sub(writesub).Trial(writetrial).InTargetAOI(1);
            intarg_US = procdata.sub(writesub).Trial(writetrial).InTargetAOI(2);
            
            rt = procdata.sub(writesub).Trial(writetrial).RT;
            soa = 100;
            
            subwrite(writetrial, 1:end) = [subn, writetrial, soa, sr, gdb, gda, {stim}, {stimdir}, {tside}, {cong}, probe, ag, instim_EP, instim_US, intarg_EP, intarg_US, rt];
            
        end
        
        writeme = [writeme; subwrite];
    end
end
    
keyboard

xlswrite([Direct '\EXCEL\StaticPointSUMMARY.xlsx'], writeme, 'MasterData')

fprintf('\n')
disp('#### SUMMARY COMPLETE! ####')

            