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
%   [SH] - 05/13/14:   v1 - Creation
%   [SH] - 06/18/14:   v1.1 - Hmm debugging.  Bins should properly group
%   the observed velocities.  In addition, average observed data with
%   normal distrbution of mean = max(observed) at each state and sd =
%   2*max.  Allows emission probabilites to be >0 at ranges beyond the
%   observed values.
%   [SH] - 06/20/14:   v1.2 - Bounded values of veloest, and trivec to be
%   greater than 1. (Was previously in there, but removed at some point!)

%%

vthresh = fixdetset{1};
trmat = fixdetset{3};
binsize = fixdetset{4};
mode = fixdetset{5};

veloest = max(ceil(velo/binsize),1); veloest(isnan(velo)) = [];
stateest = states; stateest(isnan(velo)) = [];


switch mode
    case 1
        [counts] = arrayfun(@(state) histc(veloest(stateest==state),1:max(max(veloest))),1:3,'uni',0);
        velodist = arrayfun(@(state) cell2mat(counts(state))/sum(cell2mat(counts(state))),1:3,'uni',0);
        velodist = cat(1,velodist{:}); velodist(velodist==0) = .00001; velodist = arrayfun(@(state) velodist(state,:)/sum(velodist(state,:),2),1:size(velodist,1),'uni',0);
        velodist = cat(1,velodist{:});
                
%         [ESTTR, ESTEMIT] = hmmtrain(veloest,trmat,velodist,'verbose','true','tolerance',1e-2);
        distcent = arrayfun(@(sta) find(max(velodist(sta,:))==(velodist(sta,:))),1:3);  
        ESTEMIT = [velodist(1,:);...
            pdf('normal',1:length(velodist),distcent(2),2*distcent(2));
            pdf('normal',1:length(velodist),distcent(3),2*distcent(3))];
        velodist = mean(cat(3,ESTEMIT,velodist),3);
        figure
        hold on
        plot(velodist(2,:))
        plot(velodist(3,:))
        
        for trinum = 1:size(states,1)
            try
                trivec = max(ceil(velo(trinum,:)/binsize),1); nonnandex = find(~isnan(velo(trinum,:)));
                
                [stateout] = hmmviterbi(trivec(nonnandex),trmat,velodist);
                nanrow = nan(1,length(trivec)); nanrow(~isnan(trivec)) = stateout;
                estim_states(trinum,:) = nanrow;
            catch err
                disp(['Error on Trial ' num2str(trinum)])
                keyboard
            end
        end                
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