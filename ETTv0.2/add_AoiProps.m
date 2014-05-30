function [ETT] = add_AoiProps(ETT,Subject)
%
% add_AoiProps
%
%
% INPUTS:
%
%
% OUTPUTS:
%
%
%% Change Log
%   [SH] - 05/20/14:    v1 - Creation

%%
% keyboard
currdir = pwd;
cd(ETT.DefaultDirectory)
if ~isfield(ETT, 'AOICoords')
    ETT.AOICoords.XLS.Filename = [];
    ETT.AOICoords.XLS.WkstCount = [];
    ETT.AOICoords.Coordinates = [];    
elseif isempty(ETT.AOICoords)
    ETT.AOICoords.XLS.Filename = [];
    ETT.AOICoords.XLS.WkstCount = [];
    ETT.AOICoords.Coordinates = [];    
end

if isempty(ETT.AOICoords.XLS.Filename)
    [aoifname, aoifdir] = uigetfile(...
        {'*.xlsx;', 'Excel Files (*.xlsx)'},...
        'Excel File Containing AOIs');
    ETT.AOICoords.XLS.Filename = [aoifdir,aoifname];
    disp('Opening Excel File')
    e = actxserver ('Excel.Application');
    efile = e.Workbooks.Open(ETT.AOICoords.XLS.Filename);
    ETT.AOICoords.XLS.WkstCount = efile.Worksheets.Count;
    efile.Close;
    
    [~,ETT.AOICoords.XLS.SheetNames] = xlsfinfo(ETT.AOICoords.XLS.Filename);
    maxaois = 0;
    for sheet = 1:ETT.AOICoords.XLS.WkstCount
        [num,~,raw] = xlsread(ETT.AOICoords.XLS.Filename,sheet);
        ETT.AOICoords.Coordinates(sheet).SheetName = ETT.AOICoords.XLS.SheetNames{sheet};
        ncols = size(raw,2); naois = (ncols - 1) / 4;
        if naois > maxaois
            maxaois = naois;
        end
        for aoi = 1:naois
            ETT.AOICoords.Coordinates(sheet).Corners{aoi} = fix((num(:,[1:4]+4*(aoi-1)) ./ repmat([800 600 800 600],size(num,1),1)) .* ...
                repmat([ETT.ScreenDim.StimX(2) - ETT.ScreenDim.StimX(1), ETT.ScreenDim.StimY(2) - ETT.ScreenDim.StimY(1)], size(num,1),2)...
                + repmat([ETT.ScreenDim.StimX(1) ETT.ScreenDim.StimY(1) ETT.ScreenDim.StimX(1) ETT.ScreenDim.StimY(1)],size(num,1),1));
        end
    end
    ETT.AOICoords.XLS.MaxAOIs = maxaois;
end
cd(currdir)

subdatname = ETT.Subjects(Subject).Data.PreProcess;
load(subdatname)

ntrials = size(subdata.TrialLengths,1);
subdata.Proportions.AllData.ByAOI = nan(ntrials,ETT.AOICoords.XLS.MaxAOIs);
subdata.Proportions.GoodData.ByAOI = nan(ntrials,ETT.AOICoords.XLS.MaxAOIs);
subdata.ProportionsBuff.AllData.ByAOI = nan(ntrials,ETT.AOICoords.XLS.MaxAOIs);
subdata.ProportionsBuff.GoodData.ByAOI = nan(ntrials,ETT.AOICoords.XLS.MaxAOIs);

for trinum = 1:ntrials
    vidnum = find(strcmp(subdata.VideoType(trinum), ETT.AOICoords.XLS.SheetNames));
    phasebegin = subdata.WhatsOn.Begindices{trinum}(strcmp(subdata.WhatsOn.Names{trinum},'Video'));    
    lastdata = find(~isnan(subdata.Filtered.FiltX(trinum,:)),1,'last');
    repeye = fix(repmat([subdata.Filtered.FiltX(trinum,phasebegin:lastdata);subdata.Filtered.FiltY(trinum,phasebegin:lastdata)],2,1) .* ...
        repmat([ETT.ScreenDim.PixX; ETT.ScreenDim.PixY],2,length(subdata.Filtered.FiltX(trinum,phasebegin:lastdata))))';
    framelist = sort(repmat(1:length(ETT.AOICoords.Coordinates(vidnum).Corners{1}),1,subdata.SampleRate/30));
    sharedlength = min(size(repeye,1),size(framelist,2));
    repeye = repeye(1:sharedlength,:); framelist = framelist(1:sharedlength);
    ulxlog = cat(2,cell2mat(arrayfun(@(aoi) repeye(:,1) >= cat(2,ETT.AOICoords.Coordinates(vidnum).Corners{aoi}(framelist,1)), ...
        1:length(ETT.AOICoords.Coordinates(vidnum).Corners),'uni',0)));
    ulylog = cat(2,cell2mat(arrayfun(@(aoi) repeye(:,2) >= cat(2,ETT.AOICoords.Coordinates(vidnum).Corners{aoi}(framelist,2)), ...
        1:length(ETT.AOICoords.Coordinates(vidnum).Corners),'uni',0)));
    lrxlog = cat(2,cell2mat(arrayfun(@(aoi) repeye(:,3) >= cat(2,ETT.AOICoords.Coordinates(vidnum).Corners{aoi}(framelist,3)), ...
        1:length(ETT.AOICoords.Coordinates(vidnum).Corners),'uni',0)));
    lrylog = cat(2,cell2mat(arrayfun(@(aoi) repeye(:,4) >= cat(2,ETT.AOICoords.Coordinates(vidnum).Corners{aoi}(framelist,4)), ...
        1:length(ETT.AOICoords.Coordinates(vidnum).Corners),'uni',0)));
    allcorns = cat(3,ulxlog,ulylog,lrxlog,lrylog);
    inaoi = sum(allcorns,3)==4; onesum = sum(inaoi,2)>0;
    
    subdata.Proportions.AllData.AnyAOI(trinum,1) = mean(onesum,1);
    subdata.Proportions.GoodData.AnyAOI(trinum,1) = sum(onesum,1) / length(find(~isnan(subdata.Filtered.FiltX(trinum,phasebegin:lastdata))));
    
    subdata.Proportions.AllData.ByAOI(trinum,1:size(inaoi,2)) = mean(inaoi,1);
    subdata.Proportions.GoodData.ByAOI(trinum,1:size(inaoi,2)) = sum(inaoi,1) / length(find(~isnan(subdata.Filtered.FiltX(trinum,phasebegin:lastdata))));
end

save(subdatname,'subdata')

end