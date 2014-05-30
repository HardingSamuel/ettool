function [fixinfo] = fix_ivt(velo,vthresh)
% 
% fix_ivt
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
fixinfo.ivt.isfix = zeros(size(velo)); fixinfo.ivt.fixbegin = zeros(size(velo)); fixinfo.ivt.fixend = zeros(size(velo)); fixinfo.ivt.fixdurations = zeros(size(velo));
fixinfo.ivt.isfix(velo<=vthresh) = 1;
fixinfo.ivt.fixbegin(find(diff(fixinfo.ivt.isfix,1,2)==1)+size(fixinfo.ivt.isfix,1)) = 1;
fixinfo.ivt.fixend(find(diff(fixinfo.ivt.isfix,1,2)==-1)) = 1;
fixinfo.ivt.fixbegin(sub2ind([size(fixinfo.ivt.isfix,1),size(fixinfo.ivt.isfix,2)],1:size(fixinfo.ivt.isfix,1),arrayfun(@(tri) find(fixinfo.ivt.isfix(tri,:)==1,1,'first'),1:size(fixinfo.ivt.isfix)))) = 1;
fixinfo.ivt.fixend(sub2ind([size(fixinfo.ivt.isfix,1),size(fixinfo.ivt.isfix,2)],1:size(fixinfo.ivt.isfix,1),arrayfun(@(tri) find(fixinfo.ivt.isfix(tri,:)==1,1,'last'),1:size(fixinfo.ivt.isfix)))) = 1;
fixinfo.ivt.fixdurations = find(fixinfo.ivt.fixend) - find(fixinfo.ivt.fixbegin);
end