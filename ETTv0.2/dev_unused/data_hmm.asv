function [fixinfo] = data_hmm(velo,fixinfo,fixdetset)
% 
% data_hmm
% Hidden Markov Model estimation of Fixation/Saccade identification
% 
% INPUTS:
% subdata - subject info to estimate velocity distributions
% fixinfo - from data_ivt, indices of preliminary fixation points, onsets,
% offsets
% fixdetset - fixation detection settings
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 05/13/14:    v1 - Creation 

%%

keyboard
vthresh = fixdetset{1};
trmat = fixdetset{3};
binsize = fixdetset{4};
mode = fixdetset{5};

[counts,bins] = arrayfun(@(tri) hist(velo(tri,:),0:ceil(max(max(velo))/binsize)),1:size(velo,1),'uni',0);
bins = bins{1}; counts = cat(1,counts{:});

switch mode
    case 1
        fixdist = sum(counts,1)/sum(sum(counts));
    
        

end