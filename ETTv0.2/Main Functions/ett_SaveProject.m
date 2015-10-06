function [ETT,Status] = ett_SaveProject(ETT,mode)

% ett_SaveProject
% Save the currently-held project.  Allows two inputs, the current ETT
% project and the mode of operation.  Returns the edited ETT object to the
% caller.
%
% INPUTS:
% ETT - current project
% mode - (1)Save in existing path; (2)Save with new path i.e. SaveAs
%
% OUTPUTS:
% ETT - edited project (addition/change of savepath)
% Status - success / failure return to caller
%
%% ChangeLog
%   [SH] - 04/28/14:   v1 - Creation

%%

% if the file had not been saved before
if isempty(ETT.PathName)
    mode = 2;
end

% do save or saveas
switch mode
%   save
    case 1
      %    keep track of whether it saved or not
        try
%           store the last time it was saved and save to existing path
            ETT.LastSaved = datestr(now);
            save([ETT.PathName,ETT.FileName],'ETT')
            Status = 1;
        catch
%           if saving failed for some reason
            Status = 0;
        end
%   save as
    case 2
%       get a new path and file name
        [newfile, newpath] = uiputfile(...
            {'*.etp', 'ETT Project Files (*.etp)'},...
            'Save As', [ETT.ProjectName, '.etp']);
%         only if this succeeded, e.g. they didn't cancel early
        if ischar(newfile) && ischar(newpath)
%           save
            save([newpath,newfile],'ETT')
            ETT.LastSaved = datestr(now);
%             update the ETT to know the new location for future saving
            ETT.PathName = newpath; ETT.FileName = newfile;
            ETT.DefaultDirectory = ETT.PathName;
            Status = 1;
        else
            Status = 0;
        end
        
end

end
