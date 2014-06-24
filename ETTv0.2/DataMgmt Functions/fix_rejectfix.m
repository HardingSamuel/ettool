function [fixinfo_subout] = fix_rejectfix(fixinfo_sub,minduration)
%
% fix_rejectfix
% Perform some basic checks on fixations as calculated from the IVT filter
% and marks for rejection those which fail.  This information is fed into
% the data_hmm to be re-estimated
%
% INPUTS:
% fixinfo_sub - a subfield of fixinfo e.g. fixinfo.hmm  Allows you to
% reject fixations based on some criteria after calculation.
%
% OUTPUTS:
% fixinfo_subout - a new subfield of the fixinfo structure, e.g.
% fixinfo.hmmclean
%
%% Change Log
%   [SH] - 05/15/14:    v1 - Creation

%%
if ~isfield(fixinfo_sub,'states')
    states = nan(size(fixinfo_sub.isfix));
    states(fixinfo_sub.isfix==1) = 2;
    states(fixinfo_sub.isfix==0) = 3;
    newvalue = 1;
else
    states = fixinfo_sub.states;
    newvalue = 3;
end
try
    for trinum = 1:size(states,1)
        fixons = find(fixinfo_sub.fixbegin(trinum,:)); fixoffs = find(fixinfo_sub.fixend(trinum,:)); fixdur = fixoffs - fixons + 1; fixrej = find(fixdur<minduration);
        rejecdices = arrayfun(@(rej) fixons(rej):fixoffs(rej),fixrej,'uni',0); rejecdices = cat(2,rejecdices{:});
        states(trinum,rejecdices) = newvalue;
    end
catch
    keyboard
end

fixinfo_subout.isfix = zeros(size(states)); fixinfo_subout.fixbegin = zeros(size(states)); fixinfo_subout.fixend = zeros(size(states)); fixinfo_subout.fixdurations = zeros(size(states));
fixinfo_subout.isfix(states==2) = 1;
fixinfo_subout.fixbegin(find(diff(states,1,2)==-1 | diff(states,1,2)==-997)+size(states,1)) = 1;
fixinfo_subout.fixend(find(diff(states,1,2)==1 | diff(states,1,2)==997)) = 1;
firstfix = arrayfun(@(tri) find(states(tri,:)==2,1,'first'),1:size(fixinfo_subout.isfix),'uni',0);

try
if ~size(cat(2,firstfix{:}),2)==0
    fixinfo_subout.fixbegin(sub2ind([size(states,1),size(states,2)],find(arrayfun(@(tri) ~isempty(firstfix{tri}),1:length(firstfix))),...
        cell2mat(firstfix))) = 1;
end

lastfix = arrayfun(@(tri) find(states(tri,:)==2,1,'last'),1:size(fixinfo_subout.isfix),'uni',0);
if ~size(cat(2,lastfix{:}),2)==0
    fixinfo_subout.fixend(sub2ind([size(states,1),size(states,2)],find(arrayfun(@(tri) ~isempty(lastfix{tri}),1:length(lastfix))),...
        cell2mat(lastfix))) = 1;
end
fixinfo_subout.states = states;
catch
    keyboard
end

end