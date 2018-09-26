function [Status,ErrorOutput] = data_grafix(ETT,Subject)
% 
% data_grafix
% 
% 
% INPUTS:
% 
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 06/25/14:   v1 - Creation 

%%
Status = 0; ErrorOutput = [];

% read in the subject's data
importfname = ETT.Subjects(Subject).Data.Import;
load(importfname)


try
datablock = nan(sum(subdata.TrialLengths),8);
segblock = nan(length(subdata.TrialLengths),3);


TVec = arrayfun(@(tri) (subdata.TMicroSeconds(tri,1:subdata.TrialLengths(tri))+repmat(100*(tri-1),1,subdata.TrialLengths(tri)))',...
    1:length(subdata.TrialLengths),'uni',0);
LEyeVecX = arrayfun(@(tri) subdata.LeftEye.GazeX(tri,1:subdata.TrialLengths(tri))', 1:length(subdata.TrialLengths),'uni',0);
LEyeVecY = arrayfun(@(tri) subdata.LeftEye.GazeY(tri,1:subdata.TrialLengths(tri))', 1:length(subdata.TrialLengths),'uni',0);
LEyeVecP = arrayfun(@(tri) subdata.LeftEye.Pupil(tri,1:subdata.TrialLengths(tri))', 1:length(subdata.TrialLengths),'uni',0);
REyeVecX = arrayfun(@(tri) subdata.RightEye.GazeX(tri,1:subdata.TrialLengths(tri))', 1:length(subdata.TrialLengths),'uni',0);
REyeVecY = arrayfun(@(tri) subdata.RightEye.GazeY(tri,1:subdata.TrialLengths(tri))', 1:length(subdata.TrialLengths),'uni',0);
REyeVecP = arrayfun(@(tri) subdata.RightEye.Pupil(tri,1:subdata.TrialLengths(tri))', 1:length(subdata.TrialLengths),'uni',0);

TVec = cat(1,TVec{:});

datablock(:,1) = TVec;
datablock(:,2) = zeros(size(datablock,1),1);
datablock(:,3) = cat(1,LEyeVecX{:});
datablock(:,4) = cat(1,LEyeVecY{:});
datablock(:,5) = cat(1,REyeVecX{:});
datablock(:,6) = cat(1,REyeVecY{:});
datablock(:,7) = cat(1,LEyeVecP{:});
datablock(:,8) = cat(1,REyeVecP{:});

segblock(:,1) = 1:length(subdata.TrialLengths);
segblock(:,2) = cat(1,1,arrayfun(@(tri) sum(subdata.TrialLengths(1:tri-1))+1,2:length(subdata.TrialLengths))');
segblock(:,3) = cat(1,subdata.TrialLengths(1),arrayfun(@(tri) sum(subdata.TrialLengths(1:tri)),2:length(subdata.TrialLengths))');

if ~exist(ETT.Config.GrafixExport{2},'dir')
    mkdir(ETT.Config.GrafixExport{2})
end

if ~exist([ETT.Config.GrafixExport{2},filesep,ETT.Subjects(Subject).Name],'dir')
    mkdir([ETT.Config.GrafixExport{2},filesep,ETT.Subjects(Subject).Name])
end

csvwrite([ETT.Config.GrafixExport{2},filesep,ETT.Subjects(Subject).Name,filesep,'GRAFIX_INPUT_DATA_' ETT.Subjects(Subject).Name '.csv'],datablock)
csvwrite([ETT.Config.GrafixExport{2},filesep,ETT.Subjects(Subject).Name,filesep,'GRAFIX_INPUT_SEGMENTS_' ETT.Subjects(Subject).Name '.csv'],segblock)
catch err
    Status = 0;
    ett_errorhandle(err);
end
Status = 1;

end