function ETT = ett_changeFileLocations(ETT,oldstr,newstr)

nSubs = length(ETT.Subjects);
for s = 1:nSubs  
  ETT.Subjects(s).Data.Raw = ...
    strrep(ETT.Subjects(s).Data.Raw,oldstr,newstr);
  ETT.Subjects(s).Data.Import = ...
    strrep(ETT.Subjects(s).Data.Raw,oldstr,newstr);
  ETT.Subjects(s).Data.PreProcess = ...
    strrep(ETT.Subjects(s).Data.Raw,oldstr,newstr);
end