function [Status,StatusText,usedcustom] = data_preprocess(ETT,Subject)
%
% data_preprocess
% Interpolates and filters the raw data, resaves the data
%
% INPUTS:
% ETT - project structure
% Subject - which subject to process
%
% OUTPUTS:
% status = did it compete successfully
% statustext - bonus text to explain why it didn't work (if it didn't)
% usedcustom - did we use custom import settings for this subject?
%
%% Change Log
%   [SH] - 05/06/14:    v1 - Creation
%   [SH] - 06/03/14:   Changed GoodData.Initial to GoodData.PreProcess

%%

Status = 0; StatusText = '';

procsettings = ETT.Config.PreProcess; usedcustom = 0;
if ~isempty(ETT.Subjects(Subject).Config.PreProcess)
    procsettings = ETT.Subjects(Subject).Config.PreProcess;
    usedcustom = 1;
end

%% Load the existing data (Imported)

try
importfname = ETT.Subjects(Subject).Data.Import;
load(importfname)

%% Bound the data (normalized)
subdata.LeftEye.Validity(subdata.LeftEye.GazeX > 1 | subdata.LeftEye.GazeX < 0 | ...
    subdata.LeftEye.GazeY > 1 | subdata.LeftEye.GazeY < 0) = 4;
subdata.RightEye.Validity(subdata.RightEye.GazeX > 1 | subdata.RightEye.GazeX < 0 | ...
    subdata.RightEye.GazeY > 1 | subdata.RightEye.GazeY < 0) = 4;

%% Discarding Bad Data, averaging
vec_leftvalid = nan(size(subdata.LeftEye.Validity));
vec_rightvalid = nan(size(subdata.RightEye.Validity));

vec_leftvalid(subdata.LeftEye.Validity == 0 | subdata.LeftEye.Validity == 1) = 1;
vec_rightvalid(subdata.RightEye.Validity == 0 | subdata.RightEye.Validity == 1) = 1;
vec_combvalid = cat(3,vec_leftvalid,vec_rightvalid);

CombX = nanmean(cat(3,subdata.LeftEye.GazeX.*vec_leftvalid,subdata.RightEye.GazeX.*vec_rightvalid),3);
CombY = nanmean(cat(3,subdata.LeftEye.GazeY.*vec_leftvalid,subdata.RightEye.GazeY.*vec_rightvalid),3);
CombP = nanmean(cat(3,subdata.LeftEye.Pupil.*vec_leftvalid,subdata.RightEye.Pupil.*vec_rightvalid),3);
CombD = nanmean(cat(3,subdata.LeftEye.Distance.*vec_leftvalid,subdata.RightEye.Distance.*vec_rightvalid),3);

vec_combvalid = (vec_combvalid(:,:,1) == 1 | vec_combvalid(:,:,2)==1);

subdata.Combined.CombX = CombX;
subdata.Combined.CombY = CombY;
subdata.Combined.CombD = CombD;
subdata.Combined.CombP = CombP;
subdata.Combined.GoodEyes = vec_combvalid;

GoodData.PreProcess = cell2mat(arrayfun(@(X) mean(vec_combvalid(X,1:subdata.TrialLengths(X))),1:size(vec_combvalid,1),'uni',0))';

%% Interpolating
[subdata] = data_interp(subdata,procsettings);

%% Filtering
[subdata] = data_filter(subdata,procsettings);

%% Save the output
subdata.Status.PreProcess = datestr(now);
save(importfname,'subdata')
Status = 1;
catch err
    status = 0;
   statustext = err.message;
end

end