function [fixinfo] = data_ivt(velo,vthresh)
% 
% data_ivt
% Velocity vthreshold estimation
% 
% INPUTS:
% velo - calculated velocity
% vthresh - velocity vthreshold
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 05/13/14:    v1 - Creation 

%%
fixinfo.isfix = zeros(size(velo)); fixinfo.fixbegin = zeros(size(velo)); fixinfo.fixend = zeros(size(velo)); fixinfo.fixdurations = zeros(size(velo));
fixinfo.isfix(velo<=vthresh) = 1;
fixinfo.fixbegin(find(diff(fixinfo.isfix,1,2)==1)+size(fixinfo.isfix,1)) = 1;
fixinfo.fixend(find(diff(fixinfo.isfix,1,2)==-1)) = 1;
fixinfo.fixbegin(sub2ind([size(fixinfo.isfix,1),size(fixinfo.isfix,2)],1:size(fixinfo.isfix,1),arrayfun(@(tri) find(fixinfo.isfix(tri,:)==1,1,'first'),1:size(fixinfo.isfix)))) = 1;
fixinfo.fixend(sub2ind([size(fixinfo.isfix,1),size(fixinfo.isfix,2)],1:size(fixinfo.isfix,1),arrayfun(@(tri) find(fixinfo.isfix(tri,:)==1,1,'last'),1:size(fixinfo.isfix)))) = 1;
fixinfo.fixdurations = find(fixinfo.fixend) - find(fixinfo.fixbegin);
end