function [status] = pop_SummaryV1_1(Direct, subslist, coldata)


% SummaryV1
%
% Summarizes processed data into Excel pivot-sheet format.

%   [SH] - 10/30/13:  Modified to run through ui
%   [SH] - 02/03/14:  Generalized for all studies


VersionNumber = 1.0;
VersionNumberString = '1_0';
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

if isempty(subslist)
    subslist = 1:length(procdata.sub);
end

fn = fieldnames(procdata.sub(subslist(1)).Trial(1));
ft = gettypes(procdata.sub(subslist(1)).Trial(1));
writeme = [{'Subject'}, {'TrialNum'}, {'SampleRate'}, fn(~cellfun(@(x) strcmp(x, 'struct'), ft) & ~cellfun(@(x) strcmp(x, 'Time'), fn) & ~cellfun(@(x) strcmp(x, 'usecustom'), fn))'];
writefixsac = [{'Subject'},{'TrialNum'},{'Count'},{'Type'},{'Number'},{'OnsetInd'},{'OnsetTime'},{'DurationPts'},{'DurationTime'},{'OffsetInd'},{'OffsetTime'},{'CentroidX'},{'CentroidY'},{'SaccadePeakVelo'},{'SmoothPutsuitDisplacement'}];
subfixsac = nan(0,15);
subfixt = single(zeros(0,3));


for subn = subslist
    
    if ~isempty(procdata.sub(subn)) & ~isempty(procdata.sub(subn).Trial(1))
        
        sr = procdata.sub(subn).SampleRate;
        subwrite = cell(length(procdata.sub(subn).Trial), 3+length(fn(~cellfun(@(x) strcmp(x, 'struct'), ft) & ~cellfun(@(x) strcmp(x, 'Time'), fn) & ~cellfun(@(x) strcmp(x, 'usecustom'), fn))));
        subjectnumber = procdata.sub(subn).SubjectNumber;
        disp(['Summarizing Subject Number:  ' num2str(subjectnumber)])
        for trinum = 1:length(procdata.sub(subn).Trial)
            
            fnt = fieldnames(procdata.sub(subn).Trial(trinum));
            if size(fn)==size(fnt) & all(cellfun(@isequal, sort(fn), sort(fnt)))
                
                ftt = gettypes(procdata.sub(subn).Trial(trinum));
                
                for writefield = 1:length(ftt)
                    if ~strcmp(fnt(writefield), 'Processed') && ~strcmp(fnt(writefield), 'Time') && ...
                            ~strcmp(fnt(writefield), 'WhatsOn') && ~strcmp(fnt(writefield), 'eye') && ...
                            ~strcmp(fnt(writefield), 'PointInfo') && ~strcmp(fnt(writefield), 'proportions') ...
                            && ~strcmp(fnt(writefield), 'usecustom') && ~strcmp(fnt(writefield), 'TrialNum')
                        if strcmp(ftt(writefield), 'struct')
%                             fieldout(writefield) = extractstruct(procdata.sub(subn).Trial(trinum).(char(fnt(writefield))));
                        else
                            fieldout(writefield) = {procdata.sub(subn).Trial(trinum).(char(fnt(writefield)))};
                        end
                    else
                        fieldout(writefield) = {[]};
                    end
                end
                
                fnt(cellfun(@isempty,fieldout)) = [];
                fieldout(cellfun(@isempty,fieldout)) = [];
                fnt(cellfun(@iscell,fieldout)) = [];
                fieldout(cellfun(@iscell,fieldout)) = [];
                
            else
                
                status = 'Inconsistent Trial Information.  ReProcess all subjects and try again';
                return
                
            end
            
            add_outputs = [isfield(procdata.sub(subn).Trial(trinum), 'Classifications'), isfield(procdata.sub(subn).Trial(trinum), 'proportions'), ...
                procdata.sub(subn).Trial(trinum).usecustom==1];
            
            if add_outputs(1)
                if ~isempty(procdata.sub(subn).Trial(trinum).Classifications);
                    [nitems,fixsacout] = summ_fixsac(procdata.sub(subn).Trial(trinum).Classifications);
                    fixsacout = [repmat(subjectnumber,nitems,1), repmat(trinum,nitems,1),fixsacout];
                    subfixsac = [subfixsac; fixsacout];
                end
%                 
            end
            if add_outputs(2)
                summ_props(procdata.sub(subn).Trial(trinum).proportions);
            end
%             if add_outputs(3)
%                 %                 custom_output = eval(
%             end
            subwrite(trinum, 1:3+size(fieldout,2)) = [subjectnumber, trinum, sr, fieldout];
            
        end
        writeme = [writeme; subwrite];
    end
end
% xlswrite([Direct '\EXCEL\' StudyName ' SUMMARY.xlsx'], writeme, 'MasterData')

% keyboard
summ_xlswrite(Direct,StudyName,'MasterData',writeme,summ_sizetorange('A1',writeme))
pause(1)
if ~isempty(subfixsac)
    summ_xlswrite(Direct,StudyName,'FixationSaccadeData', writefixsac, summ_sizetorange('A1',writefixsac))
    pause(1)
    summ_xlswrite(Direct,StudyName,'FixationSaccadeData', subfixsac, summ_sizetorange('A2',subfixsac))
end
if ~isempty(subfixt)
    summ_xlswrite(Direct,StudyName,'FixTarget', writefix, summ_sizetorange('B1',writefix))
    pause(1)
    summ_xlswrite(Direct,StudyName,'FixTarget', subfixt, summ_sizetorange('B2',subfixt))
end

status = 'Summary Complete';
fprintf('\n')
disp('#### SUMMARY COMPLETE! ####')




