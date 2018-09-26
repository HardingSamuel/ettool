function [ETT] = proj_CheckUpdate(ETT)
% 
% proj_CheckUpdate
% Run automatically at the beginning of various functions.  Allows older
% projects which were created before feature implementation to be updated
% with required fields or data
% 
% INPUTS:
% 
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 06/25/14:    v1 - Creation 

%%
% check ETT structure
if ~isfield(ETT.Config,'GrafixExport')
    ETT.Config.GrafixExport = [];
end

% check subjects
for subn = 1:ETT.nSubjects
    if ~isfield(ETT.Subjects(subn).Config,'GrafixExport')
        ETT.Subjects(subn).Config.GrafixExport = [];
    end
end

end