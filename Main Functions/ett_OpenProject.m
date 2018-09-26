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
% initialize
ETT = [];
% have user point to file
[filename,pathname] = uigetfile(...
  {'*.etp', 'ETT Project FIles (*.etp)'},...
  'Select a File to Load');
% only try to load if they actually pointed to a file
% % should probably also add a check here to make sure the file extension
% is .etp
if ischar(filename) && ischar(pathname)
  load([pathname,filename],'-mat')
else
  
end


% Check whether the default directory exists, and prompt the user to change
% it if not. Typically a problem when dealing with the same file on
% multiple computers.

if exist(ETT.DefaultDirectory) == 0
  defaultDirFig = questdlg('The Default Directory does not exist -- would you like to update it?',...
    'ERROR: Default Directory',...
    'Yes','No','Yes');
  switch defaultDirFig
    case 'Yes'
      [ddPathName] = uigetdir(pwd,...
        'Select a New Default Directory');
      ETT.DefaultDirectory = [ddPathName filesep];
    case 'No'
      
  end
end

end