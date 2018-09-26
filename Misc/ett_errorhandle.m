function ett_errorhandle(ERROR)
% 
% ett_errorhandle
% Default error handling script.  Provides information to the user about
% the error they encountered, faciltating debugging
% 
% INPUTS:
% ERROR - information from whichever script the error occurred in.
% 
% OUTPUTS:
% 
% 
%% Change Log
%   [SH] - 09/23/14:   v1 - Creation 

%%
errmsg = ['An ERROR has occurred in ' ERROR.stack(1).name ' at line ' num2str(ERROR.stack(1).line)...
    '.  Would you like to GoTo the error or Quit?'];
errordlg = questdlg(errmsg,'ETT - ERROR','GoTo','Quit','Quit');

QG = find(strcmp(errordlg,{'Quit','GoTo'}));

switch QG
    case 1
        error(['Stopping due to error in ' ERROR.stack(1).name ' at line ' num2str(ERROR.stack(1).line) ...
            ' with message: ' ERROR.message]) 
    case 2
        disp(['Error in Line ' num2str(ERROR.stack(1).line) ' of file ' ERROR.stack(1).name])
        disp(['With message: ' ERROR.message])
        edit(ERROR.stack(1).file)
        keyboard
end

end