function [status] = pop_SummaryV1_1(Direct, subslist, coldata)


% SummaryV1
%
% Summarizes processed data into Excel pivot-sheet format.

%   [SH] - 10/30/13:  Modified to run through ui
%   [SH] - 02/03/14:  Generalized for all studies


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

ChangedSubs = 0;


fn = fieldnames(procdata.sub(1).Trial(1));
ft = gettypes(procdata.sub(1).Trial(1));
writeme = [{'Subject'}, {'TrialNum'}, {'SampleRate'}, fn(~cellfun(@(x) strcmp(x, 'struct'), ft) & ~cellfun(@(x) strcmp(x, 'Time'), fn))'];

for writesub = 2:length(procdata.sub)
    
    if ~isempty(procdata.sub(writesub)) & ~isempty(procdata.sub(writesub).Trial(1))
        
        sr = procdata.sub(writesub).SampleRate;
        subwrite = cell(length(procdata.sub(writesub).Trial), 3+length(fn(~cellfun(@(x) strcmp(x, 'struct'), ft) & ~cellfun(@(x) strcmp(x, 'Time'), fn))));
        subn = procdata.sub(writesub).SubjectNumber;
        
        for writetrial = 1:length(procdata.sub(writesub).Trial)
%             writetrial
            fnt = fieldnames(procdata.sub(writesub).Trial(writetrial));
%             keyboard
            if size(fn)==size(fnt) & all(cellfun(@isequal, fn, fnt))
                
                ft = gettypes(procdata.sub(writesub).Trial(writetrial));
                
                for writefield = 1:length(ft)
                    if ~strcmp(fn(writefield), 'Processed') && ~strcmp(fn(writefield), 'Time') && ...
                            ~strcmp(fn(writefield), 'WhatsOn') && ~strcmp(fn(writefield), 'eye') && ...
                            ~strcmp(fn(writefield), 'PointInfo') && ~strcmp(fn(writefield), 'proportions')
                        if strcmp(ft(writefield), 'struct')
                            fieldout(writefield) = extractstruct(procdata.sub(writesub).Trial(writetrial).(char(fn(writefield))));
                        else
                            fieldout(writefield) = {procdata.sub(writesub).Trial(writetrial).(char(fn(writefield)))};
                        end
                    else
                        fieldout(writefield) = {[]};
                    end
                end
                
                cellout = fieldout(cellfun(@iscell,fieldout));
                cn = fnt(find(cellfun(@iscell,fieldout)));
                fnt(cellfun(@isempty,fieldout)) = []; 
                fieldout(cellfun(@isempty,fieldout)) = []; 
                fnt(cellfun(@iscell,fieldout)) = [];
                fieldout(cellfun(@iscell,fieldout)) = [];
                fnt = fnt';
                
            else
                if ~exist('user_can_cont')
                    user_can_cont = input(['Error: Detected inconsistencies between subject procdata for Subject: ' num2str(writesub) ' Trial: ' num2str(writetrial) '.' ...
                    '\n' 'Recommend aborting & reprocessing all subjects.' '\n' 'Continue summarizing, but skipping this inconsistency? [(A)bort and Fix || (C)ontinue but skip]' '\n'],'s');
                end
                keyboard
                switch user_can_cont
                    case ['a','A',a]
                        Disp('Aborting Summary.  Reprocess all subjects and try again')
                        status = 'Summary Aborted, Rerun Process';
                        return
                    case ['c','C',c]
                        Disp('Continuing Summary but skipping inconsistent trials.  You will not see this message again')
                        continue
                end
                    
            end
                        
            subwrite(writetrial, 1:3+size(fieldout,2)) = [subn, writetrial, sr, fieldout];
        end
        writeme = [writeme; subwrite];
    end
end
keyboard
xlswrite([Direct '\EXCEL\' StudyName ' SUMMARY.xlsx'], writeme, 'MasterData')
% for add_sheets = 1:length(cn)
%     if ~cellfun(@isempty, cellout)
%         keyboard
%         xlswrite([Direct '\EXCEL\' StudyName ' SUMMARY.xlsx'], cellout{add_sheets}, char(cn(add_sheets)))
%     end
% end

status = 'Summary Complete';
fprintf('\n')
disp('#### SUMMARY COMPLETE! ####')




