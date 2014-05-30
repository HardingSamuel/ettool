function ETT = ett_OpenProject

% ett_OpenProject
% Open an existing ETTool project from a saved location.  This will replace
% the currently-held project within the tool.
% 
% INPUTS:
% 
% OUTPUTS:
% ETT - structure containing the eye-tracking data for the loaded file
% 
%% Change Log
%   [SH] - 04/28/14:   v1 - Creation

%%
ETT = [];

[filename,pathname] = uigetfile(...
    {'*.etp', 'ETT Project FIles (*.etp)'},...
    'Select a File to Load');

if ischar(filename) && ischar(pathname)
    load([pathname,filename],'-mat')
else
    
end

end