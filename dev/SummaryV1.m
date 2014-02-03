% SummaryV1
%
% Summarizes processed data into Excel pivot-sheet format.


clear all

VersionNumber = 1.1;
AOIVersionNumber = 1.1;

%Directory of RAWDATA File
s = 'INPUT\PROCDATA';
D = dir(s);
CurrentDir = cd;
sla = strfind(CurrentDir, '\');
StudyName = CurrentDir(sla(end-1)+1:sla(end)-1);

disp('Loading PROC Data File')
load([cd, '\', s, '\', D(3).name])

writeme = [{'Subject'}, {'Trial'}, {'SOA'}, {'SampleRate'}, {'GoodData'}, {'Stimulus'}, {'StimDirection'}, {'TargetSide'}, {'Congruence'}, {'Probe'}, {'AttGet'}, ...
    {'EP_inStim'}, {'US_inStim'}, {'EP_inTarg'}, {'US_inTarg'}, {'ReactionTime'}];

for writesub = 1:length(procdata.sub)
    if ~isempty(procdata.sub(writesub))
        
        sr = procdata.sub(writesub).SampleRate;
        subwrite = cell(length(procdata.sub(writesub).Trial), 16);
        subn = procdata.sub(writesub).SubjectNumber;
        
        for writetrial = 1:length(procdata.sub(writesub).Trial)
            
            gd = procdata.sub(writesub).Trial(writetrial).GoodData;
            stim = procdata.sub(writesub).Trial(writetrial).Stimulus;
            stimdir = procdata.sub(writesub).Trial(writetrial).StimDir;
            tside = procdata.sub(writesub).Trial(writetrial).TargetSide;
            cong = procdata.sub(writesub).Trial(writetrial).Congruence;
            probe = procdata.sub(writesub).Trial(writetrial).Probe;
            ag = procdata.sub(writesub).Trial(writetrial).AG;
            
            instim_EP = procdata.sub(writesub).Trial(writetrial).InStimAOI(1);
            instim_US = procdata.sub(writesub).Trial(writetrial).InStimAOI(2);
            
            intarg_EP = procdata.sub(writesub).Trial(writetrial).InTargetAOI(1);
            intarg_US = procdata.sub(writesub).Trial(writetrial).InTargetAOI(2);
            
            rt = procdata.sub(writesub).Trial(writetrial).RT;
            soa = 100;
            
            subwrite(writetrial, 1:end) = [subn, writetrial, soa, sr, gd, {stim}, {stimdir}, {tside}, {cong}, probe, ag, instim_EP, instim_US, intarg_EP, intarg_US, rt];
            
        end
        
        writeme = [writeme; subwrite];
    end
end
    

xlswrite([CurrentDir(1:sla(end)) 'EXCEL\StaticPointSUMMARY.xlsx'], writeme, 'MasterData')

fprintf('\n')
disp('#### SUMMARY COMPLETE! ####')

            