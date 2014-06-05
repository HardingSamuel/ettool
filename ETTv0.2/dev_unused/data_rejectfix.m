function [states] = data_rejectfix(fixinfo,minduration)
% 
% data_rejectfix
% Perform some basic checks on fixations as calculated from the IVT filter
% and marks for rejection those which fail.  This information is fed into
% the data_hmm to be re-estimated
% 
% INPUTS:
% fixinfo - estimated fixations from velocity threshold
% 
% OUTPUTS:
% states - states sequence to be fed into HMM.
% 
%% Change Log
%   [SH] - 05/15/14:    v1 - Creation 

%%

states = nan(size(fixinfo.isfix));

states(fixinfo.isfix==1) = 2;
states(fixinfo.isfix==0) = 3;

for trinum = 1:size(states,1)
    fixons = find(fixinfo.fixbegin(trinum,:)); fixoffs = find(fixinfo.fixend(trinum,:)); fixdur = fixoffs - fixons; fixrej = fixdur<minduration;
    rejecdices = arrayfun(@(rej) fixons(fixrej(rej)):fixoffs(fixrej(rej)),1:length(fixrej),'uni',0); rejecdices = cat(2,rejecdices{:});
    states(trinum,rejecdices) = 1;
end       
    

end