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
%   [SH] - 06/24/14:   v1.2.1 - Disabled 'Load' button while still drawing
%   to prevent error from trying to load too soon.

%%

vthresh = fixdetset{1};
trmat = fixdetset{3};
binsize = fixdetset{4};
mode = fixdetset{5};

veloest = max(ceil(velo/binsize),1); veloest(isnan(velo)) = [];
stateest = states; stateest(isnan(velo)) = [];
% velo2 = velo(~isnan(velo));
% keyboard
switch mode
    case 1
      for sta = 1:3
        myVelo{sta} = velo(states==sta);% myVelo(isnan(myVelo)) = [];
        counts(sta,:) = histc(myVelo{sta},1:max(max(velo)));
        nvals(sta,:) = length(myVelo{sta});
        stds(sta,1) = std(myVelo{sta},1);
        iqrs(sta,1) = iqr(myVelo{sta})/1.34;
      end
%       figure
%       plot(counts')
%         [counts] = arrayfun(@(state) histc(veloest(stateest==state),1:max(max(veloest))),1:3,'uni',0);
%         velodist = arrayfun(@(state) cell2mat(counts(state))/sum(cell2mat(counts(state))),1:3,'uni',0);
%         velodist = cat(1,velodist{:}); velodist = max(1e-5,velodist); velodist = arrayfun(@(state) velodist(state,:)/sum(velodist(state,:),2),1:size(velodist,1),'uni',0);
%         velodist = cat(1,velodist{:});
                
%         [ESTTR, ESTEMIT] = hmmtrain(veloest,trmat,velodist,'verbose','true','tolerance',1e-2);
%         distcent = nan(1,3);
%         for sta = 1:3
%             if ~all(velodist(sta,:)==0)
%                 distcent(sta) = find(max(velodist(sta,:))==(velodist(sta,:)));
%             end
%         end
        n = 10;
        bins  = linspace(0,max(max(velo)),2^n);        
        hMat = .9 * min(stds,iqrs) .* (nvals.^(-1/5));
        ESTEMIT = [];        
        mufits = nan(3,1); sdfits = mufits;
        for sta = 1:3
          [epa,bin] = ksdensity(myVelo{sta},bins,'kernel','epanechnikov','width',hMat(sta));
          ESTEMIT(sta,:) = epa;
        end
%         figure
        ESTEMIT = max(ESTEMIT,1e-5);
        ESTEMIT = ESTEMIT ./ (sum(ESTEMIT,2) * ones(1,length(bins)));
%         plot(bins,ESTEMIT')    
        
%         velodist = mean(cat(3,ESTEMIT,velodist),3);

        
        for trinum = 1:size(states,1)
            try
                trivec = velo(trinum,:); nonnandex = find(~isnan(velo(trinum,:)));
                for v = 1:length(trivec)
                  if ~isnan(trivec(v))
                    trivecBin(v) = find(trivec(v)>=bins,1,'last');
                  else
                    trivecBin(v) = nan;
                  end
                end
                
                [stateout] = hmmviterbi(trivecBin(nonnandex),trmat,ESTEMIT);
                nanrow = nan(1,length(trivec)); nanrow(~isnan(velo(trinum,:))) = stateout;
                estim_states(trinum,:) = nanrow;
            catch err
                disp(['Error on Trial ' num2str(trinum)])
                keyboard
            end
        end
        
%         figure
%         plot(stateout)
%         keyboard
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
trialswithfix = find(arrayfun(@(tri) any(fixinfo.hmm.isfix(tri,:)==1),1:size(fixinfo.hmm.isfix)));
fixinfo.hmm.fixbegin(sub2ind([size(estim_states,1),size(estim_states,2)],trialswithfix,arrayfun(@(tri) find(estim_states(tri,:)==2,1,'first'),trialswithfix))) = 1;
fixinfo.hmm.fixend(sub2ind([size(estim_states,1),size(estim_states,2)],trialswithfix,arrayfun(@(tri) find(estim_states(tri,:)==2,1,'last'),trialswithfix))) = 1;
fixinfo.hmm.states = estim_states;

end