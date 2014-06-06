function [fixinfo] = fix_hmm(velo,fixinfo,fixdetset,states)
%
% fix_hmm
% Hidden Markov Model estimation of Fixation/Saccade identification
%
% INPUTS:
% subdata - subject info to estimate velocity distributions
% fixinfo - from data_hmm, indices of preliminary fixation points, onsets,
% offsets
% fixdetset - fixation detection settings
%
% OUTPUTS:
%
%
%% Change Log
%   [SH] - 05/13/14:    v1 - Creation

%%

vthresh = fixdetset{1};
trmat = fixdetset{3};
binsize = fixdetset{4};
mode = fixdetset{5};
veloest = ceil(velo/binsize);
% keyboard
switch mode
    case 1
        counts = arrayfun(@(state) histc(velo(states==state),0:binsize:binsize*ceil(max(max(velo))/binsize)),1:3,'uni',0);
        velodist = arrayfun(@(state) cell2mat(counts(state))/sum(cell2mat(counts(state))),1:3,'uni',0);
        velodist = cat(2,velodist{:})';
        veloest(isnan(velo)) = length(velodist);        
        for trinum = 1:size(states,1)
            [estim_states(trinum,:)] = hmmviterbi(ceil(veloest(trinum,:)/binsize),trmat,velodist);
        end
%         [estTR,estE] = hmmestimate(veloest,estim_states);
%         figure
%         estE(end) = nan;
%         plot(estE')
        
    case 2
        for trinum = 1:size(states,1)
            counts{trinum} = arrayfun(@(state) histc(velo(states(trinum,:)==state),0:binsize:binsize*ceil(max(max(velo))/binsize)),1:3,'uni',0);
            velodist{trinum} = arrayfun(@(state) cell2mat(counts{trinum}(state))/sum(cell2mat(counts{trinum}(state))),1:3,'uni',0);
        end
        
end

estim_states(isnan(velo)) = 999; estim_states(estim_states==1) = 3;
fixinfo.hmm.isfix = zeros(size(velo)); fixinfo.hmm.fixbegin = zeros(size(velo)); fixinfo.hmm.fixend = zeros(size(velo)); fixinfo.hmm.fixdurations = zeros(size(velo));
fixinfo.hmm.isfix(estim_states==2) = 1;
fixinfo.hmm.fixbegin(find(diff(estim_states,1,2)==-1 | diff(estim_states,1,2)==-997)+size(estim_states,1)) = 1;
fixinfo.hmm.fixend(find(diff(estim_states,1,2)==1 | diff(estim_states,1,2)==997)) = 1;
fixinfo.hmm.fixbegin(sub2ind([size(estim_states,1),size(estim_states,2)],1:size(estim_states,1),arrayfun(@(tri) find(estim_states(tri,:)==2,1,'first'),1:size(fixinfo.hmm.isfix)))) = 1;
fixinfo.hmm.fixend(sub2ind([size(estim_states,1),size(estim_states,2)],1:size(estim_states,1),arrayfun(@(tri) find(estim_states(tri,:)==2,1,'last'),1:size(fixinfo.hmm.isfix)))) = 1;
fixinfo.hmm.states = estim_states;

end