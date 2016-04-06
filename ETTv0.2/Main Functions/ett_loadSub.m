function subdata = ett_loadSub(ETT,subN)
% loads a subject from the ETT project by looking at the default directory

rawFName = ETT.Subjects(subN).Data.PreProcess;
subName = ETT.Subjects(subN).Name;
defDir = ETT.DefaultDirectory;

firstGood = strfind(rawFName,['SubjectData_' subName]);

updateName = [defDir subName filesep rawFName(firstGood:end)];

subdata = load(updateName);
subdata = subdata.subdata;
end