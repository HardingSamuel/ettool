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

switch mode
    case 1
        try
            save([ETT.PathName,ETT.FileName],'ETT')
            Status = 1;
        catch
            Status = 0;
        end
    case 2
        [newfile, newpath] = uiputfile(...
            {'*.etp', 'ETT Project Files (*.etp)'},...
            'Save As', [ETT.ProjectName, '.etp']);
        
        if ischar(newfile) && ischar(newpath)
            save([newpath,newfile],'ETT')
            ETT.PathName = newpath; ETT.FileName = newfile;
            Status = 1;
        else
            Status = 0;
        end
        
end

end
