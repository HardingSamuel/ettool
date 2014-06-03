function [status,stattext,usedcustom] = data_import(ETT,Subject)
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

%%
cols = ETT.Config.Import; usedcustom = 0;
if ~isempty(ETT.Subjects(Subject).Config.Import)
    cols = ETT.Subjects(Subject).Config.Import;
    usedcustom = 1;
end

dataformat = strcat(['%*f %*f %*f %*f %*f %*f %*f %*f %f %f %f %*f '...
    '%*f %f %f %f %f %f %*f %*f %f %f %f '], repmat(' %s', 1, size(cols,2)));

rawdatafname = [ETT.DefaultDirectory,'ProjectData\',ETT.Subjects(Subject).Name,'\SubjectData_',ETT.Subjects(Subject).Name,'.mat'];

%% Retrieve the Data
datafid = fopen(ETT.Subjects(Subject).Data.Raw);
fgets(datafid);
[datacell] = textscan(...
    datafid,dataformat,'delimiter','\t','treatasempty',{'-1.#INF','1.#INF','-1.#IND','1.#IND'},'emptyvalue',-1);
if ~feof(datafid)
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
    for nae = nadditionalentries        
        aerow{nae==nadditionalentries} = cat(1,datacell{:,11+nae})';
        subdata.(char(cols(1,nae))) = '';        
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
                subdata.(char(cols(1,nae))) = cat(1,subdata.(char(cols(1,nae))),unique(add_vec,'stable'));
                catch
                    keyboard
                end
            else
                try
                subdata.(char(cols(1,nae))) = cat(2,subdata.(char(cols(1,nae))),add_vec);
                catch
                    keyboard
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
    
    SRmat = [60 120 180 240 300];
    SR = SRmat(find(min(abs(SRmat-1000/((tmicro(1,2) - tmicro(1,1))/1000)))==...
        abs(SRmat-1000/((tmicro(1,2) - tmicro(1,1))/1000))));
    
    subdata.SampleRate = SR;
    
    subdata.Status.Import = datestr(now);
    subdata.LeftEye = Leye;
    subdata.RightEye = Reye;
    subdata.TMicroSeconds = tmicro;
    subdata.TrialOnOff = TBegin;
    subdata.TrialLengths = tlens;
    
    subdata.GoodData.Raw = arrayfun(@(tri) 1-(length(find(subdata.LeftEye.GazeX(tri,:)==-1))/length(find(~isnan(subdata.LeftEye.GazeX(tri,:))))), 1:length(tlens));
    
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
    status = 1; stattext = '';
    
    
else
    status = 0;
    stattext = (['Unable to parse trial counter column.  Check your column settings and try again, or consider changing this column in your data to'...
        ' only numbers']);
end
end