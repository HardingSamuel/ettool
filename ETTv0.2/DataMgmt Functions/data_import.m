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

%%
cols = ETT.ImportColumns; usedcustom = 0;
if ~isempty(ETT.Subjects(Subject).CustomColumns)
    cols = ETT.Subjects(Subject).CustomColumns;
    usedcustom = 1;
end

dataformat = strcat(['%*f %*f %*f %*f %*f %*f %*f %*f %f %f %f %*f '...
    '%*f %f %f %f %f %f %*f %*f %f %f %f '], repmat(' %s', 1, size(cols,2)));

rawdatafname = [ETT.DefaultDirectory,'RAWDATA\',ETT.Subjects(Subject).Name,'\RAWDATA_',ETT.Subjects(Subject).Name,'.mat'];

%% Retrieve the Data
datafid = fopen(ETT.Subjects(Subject).Data);
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
    emptymat = nan(size(trilist,1),maxlength);
    tmicro = emptymat; Leye = repmat(emptymat,[1,1,5]); Reye = Leye;
    
    nadditionalentries = find(cat(2,cols{2,:})==0);
    for nae = nadditionalentries        
        aerow{nae==nadditionalentries} = cat(1,datacell{:,11+nae})';
        subdata.(char(cols(1,nae))) = '';        
    end
    for torg = 1:length(trilist)
        torg = trilist(torg);
        tmicro(torg,1:tlens(torg)) = datacell{1}(begindices(torg):endices(torg))';
        Leye(torg,1:tlens(torg),1) = datacell{2}(begindices(torg):endices(torg))';
        Leye(torg,1:tlens(torg),2) = datacell{3}(begindices(torg):endices(torg))';
        Leye(torg,1:tlens(torg),3) = datacell{4}(begindices(torg):endices(torg))';
        Leye(torg,1:tlens(torg),4) = datacell{5}(begindices(torg):endices(torg))';
        Leye(torg,1:tlens(torg),5) = datacell{6}(begindices(torg):endices(torg))';
        
        Reye(torg,1:tlens(torg),1) = datacell{7}(begindices(torg):endices(torg))';
        Reye(torg,1:tlens(torg),2) = datacell{8}(begindices(torg):endices(torg))';
        Reye(torg,1:tlens(torg),3) = datacell{9}(begindices(torg):endices(torg))';
        Reye(torg,1:tlens(torg),4) = datacell{10}(begindices(torg):endices(torg))';
        Reye(torg,1:tlens(torg),5) = datacell{11}(begindices(torg):endices(torg))';
        
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
    subdata.TestD = ETT.Subjects(Subject).TestD;
    subdata.Import = datestr(now);
    subdata.LeftEye = Leye;
    subdata.RightEye = Reye;
    subdata.TMicroSeconds = tmicro;
    subdata.TrialOnOff = TBegin;
    
    subdata.WhatsOn.Names = wonames';
    subdata.WhatsOn.Begindices = wobegin';
    subdata.WhatsOn.Endices = woends';
    
    if ~exist([ETT.DefaultDirectory,'RAWDATA\'],'dir')
        mkdir(ETT.DefaultDirectory,'RAWDATA')
    end
    if ~exist([ETT.DefaultDirectory,'RAWDATA\',ETT.Subjects(Subject).Name],'dir')
        mkdir([ETT.DefaultDirectory,'RAWDATA\'],ETT.Subjects(Subject).Name)
    end
    
    save(rawdatafname,'subdata');
    status = 1; stattext = '';
    
    
else
    status = 0;
    stattext = (['Unable to parse trial counter column.  Check your column settings and try again, or consider changing this column in your data to'...
        ' only numbers']);
end
end