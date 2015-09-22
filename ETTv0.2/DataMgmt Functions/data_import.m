function [Status,ErrorOutput,usedcustom] = data_import(ETT,Subject)
%
% data_import
% Imports the raw eye tracking data and returns a status and updates the
% ETT with information about the save location of the file.
%
% INPUTS:
% ETT
%
% OUTPUTS:
%
%
%% Change Log
%   [SH] - 05/01/14:    v1 - Creation
%   [SH] - 06/03/14:   Added GoodData.Raw calculation
%   [SH] - 06/19/14:   Flipped orientation of GoodData.Raw
%   [SH] - 06/23/14:   Corrected miscalculation of GoodData.Raw. Was only
%   counting instances of -1, however bad dad can also include values < -1
%   or >1.
%   [SH] - 06/25/14:   v1.1 - Time column changed from "TimestampMicrosec"
%   to "TETTime" during import.  Prevents overflows back to 0 for correct
%   extended time stamping.
%   [SH] - 08/01/14:   Fixed time column to be column 5, not 4 (which has
%   all identical values).  Adjusted SR calculation to use mode of the time
%   vector to match against expected differences, rather than data point 1,
%   and 2.
%   [SH] - 09/05/14:   Returned t column to 4, rather than 5.  Not sure
%   which situation the reported identical values were found, but it was
%   not AT or FaceEyes.  Will continue looking for.  
%   [SH] - 09/12/14:   Simplified SR calculation significantly.  No longer
%   assumes multiple of 60 Hz, included option for 50 Hz.
%   [SH] - 09/19/14:   Referring to previous change from t column from
%   5->4, this apparently was incorrect.  Miscellaneous files with strange
%   properties were configured to use col 4 instead of 5.  This change had
%   caused problems with normal data format, so reverting.  Should fix SR
%   calculations.
%   [SH] - 09/23/14:   Defaulted to placing values for additional entries
%   into cells.  Should prevent errors when a given trial has strange
%   properties, such as 1 value instead of many when previous had many.

%%

Status = 0; ErrorOutput = [];

cols = ETT.Config.Import; usedcustom = 0;
if ~isempty(ETT.Subjects(Subject).Config.Import)
    cols = ETT.Subjects(Subject).Config.Import;
    usedcustom = 1;
end

dataformat = strcat(['%*f %*f %*f %*f %f %*f %*f %*f %*f %f %f %*f '...
    '%*f %f %f %f %f %f %*f %*f %f %f %f '], repmat(' %s', 1, size(cols,2)));

rawdatafname = [ETT.DefaultDirectory,'ProjectData\',ETT.Subjects(Subject).Name,'\SubjectData_',ETT.Subjects(Subject).Name,'.mat'];

%% Retrieve the Data
try
    datafid = fopen(ETT.Subjects(Subject).Data.Raw);
    fgets(datafid);
    [datacell,position] = textscan(...
        datafid,dataformat,'delimiter','\t','treatAsEmpty',{'-1.#INF','1.#INF','-1.#IND','1.#IND','-1.#QNAN','1.#QNAN','NF','ND'},'emptyvalue',-1,'CommentStyle','#');
    if ~fgets(datafid)==-1
        keyboard
    end
    fclose(datafid);
    
    %% Split the Data
    trials = cat(1,datacell{:,11+find(cat(2,cols{2,:})==1)});
    trilist = cellfun(@str2num, trials);
    if isempty(trilist)
        disp('Characters found in Trial Column, consider removing to increase speed')
        for trinum = 1:size(trials,1)
            findnums = cell2mat(arrayfun(@(X) ~isempty(str2num(trials{trinum}(X))), 1:size(trials{trinum},2),'uni',0));
            trilist(trinum,1) = str2num(trials{trinum}(findnums));
        end
    end
    
    begindices = [1;find(diff(trilist)~=0)+1]; endices = [begindices(2:end) - 1; size(trials,1)];
    trilist = 1:length(begindices);
    
    if ~isempty(trilist)
        tlens = (1 + endices - begindices);
        maxlength = max(tlens);
        emptymat = nan(length(trilist),maxlength);
        tmicro = emptymat;
        
        Leye.GazeX = emptymat; Reye.GazeX = emptymat;
        Leye.GazeY = emptymat; Reye.GazeY = emptymat;
        Leye.Pupil = emptymat; Reye.Pupil = emptymat;
        Leye.Distance = emptymat; Reye.Distance = emptymat;
        Leye.Validity = emptymat; Reye.Validity = emptymat;
        
        nadditionalentries = find(cat(2,cols{2,:})==0);
        if isempty(cols{1,end}); nadditionalentries(end) = [];end
        for nae = nadditionalentries
            aerow{nae==nadditionalentries} = cat(1,datacell{:,11+nae})';
            % remove parens from column names and replace with -
            colName = (char(cols(1,nae)));
            colName = strrep(strrep(colName,'(','_'),')','_');
            subdata.(colName) = '';
        end
        for torg = 1:length(trilist)
            torg = trilist(torg);
            tmicro(torg,1:tlens(torg)) = datacell{1}(begindices(torg):endices(torg))';
            Leye.GazeX(torg,1:tlens(torg)) = datacell{2}(begindices(torg):endices(torg))';
            Leye.GazeY(torg,1:tlens(torg)) = datacell{3}(begindices(torg):endices(torg))';
            Leye.Pupil(torg,1:tlens(torg)) = datacell{4}(begindices(torg):endices(torg))';
            Leye.Distance(torg,1:tlens(torg)) = datacell{5}(begindices(torg):endices(torg))';
            Leye.Validity(torg,1:tlens(torg)) = datacell{6}(begindices(torg):endices(torg))';
            
            Reye.GazeX(torg,1:tlens(torg)) = datacell{7}(begindices(torg):endices(torg))';
            Reye.GazeY(torg,1:tlens(torg)) = datacell{8}(begindices(torg):endices(torg))';
            Reye.Pupil(torg,1:tlens(torg)) = datacell{9}(begindices(torg):endices(torg))';
            Reye.Distance(torg,1:tlens(torg)) = datacell{10}(begindices(torg):endices(torg))';
            Reye.Validity(torg,1:tlens(torg)) = datacell{11}(begindices(torg):endices(torg))';
            
            TBegin(torg,1:2) = [begindices(torg),endices(torg)];
            for nae = nadditionalentries
                add_vec = aerow{nae==nadditionalentries}(begindices(torg):endices(torg));
                if length(unique(add_vec,'stable')) == 1
                    try
                        subdata.(colName){torg,1} = unique(add_vec,'stable');
                    catch err 
                        ett_errorhandle(err);
                    end
                else
                    try
                        subdata.(colName){torg,1} = add_vec;
                    catch err
                        ett_errorhandle(err);
                    end
                end
                clear add_vec
            end
            [wonames{torg},wobegin{torg}] = unique(cat(1,datacell{11+find(cat(2,cols{2,:})==2)}(begindices(torg):endices(torg))),'stable');
            woends{torg} = [wobegin{torg}(2:end);tlens(torg)];
        end
        
        
        %% Save the Data, update the ETT
        subdata.Name = ETT.Subjects(Subject).Name;
        subdata.DOB = ETT.Subjects(Subject).DOB;
        subdata.TestDate = ETT.Subjects(Subject).TestDate;
        
        SRmat = [50 60 120 180 240 300];
        
%         SR = find(min(abs(SRmat-(1000/mode(diff(tmicro(1,:))))))==abs(SRmat-(1000/mode(diff(tmicro(1,:)))))) ...
%             * 60;
        
        SR = SRmat(find(min(abs(SRmat-1000/mode(diff(tmicro(1,:)))))==abs(SRmat-1000/mode(diff(tmicro(1,:))))));
        if length(SR)>1
            keyboard
        end
        
        subdata.SampleRate = SR;
        
        subdata.Status.Import = datestr(now);
        subdata.LeftEye = Leye;
        subdata.RightEye = Reye;
        subdata.TMicroSeconds = tmicro;
        subdata.TrialOnOff = TBegin;
        subdata.TrialLengths = tlens;
        
        subdata.GoodData.Raw = arrayfun(@(tri) length(find(subdata.LeftEye.Validity(tri,1:subdata.TrialLengths(tri))<2 &...
            subdata.RightEye.Validity(tri,1:subdata.TrialLengths(tri))<2))/...
            subdata.TrialLengths(tri), 1:length(tlens))';
        
        subdata.WhatsOn.Names = wonames';
        subdata.WhatsOn.Begindices = wobegin';
        subdata.WhatsOn.Endices = woends';
        
        if ~exist([ETT.DefaultDirectory,'ProjectData\'],'dir')
            mkdir(ETT.DefaultDirectory,'ProjectData')
        end
        if ~exist([ETT.DefaultDirectory,'ProjectData\',ETT.Subjects(Subject).Name],'dir')
            mkdir([ETT.DefaultDirectory,'ProjectData\'],ETT.Subjects(Subject).Name)
        end
        
        save(rawdatafname,'subdata');
        Status = 1;        
        
    else
        Status = 0;
%         ErrorOutput = (['Unable to parse trial counter column.  Check your column settings and try again, or consider changing this column in your data to'...
%             ' only numbers']);
    end
    
catch err
    Status = 0;
    ett_errorhandle(err);
end
end