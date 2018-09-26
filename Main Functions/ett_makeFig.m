function handle = ett_makeFig(figName)
% creates a figure according to the specification provided in the ettLib
% file

%% Access the configuration library
global ettLib

%% Make the figure
ettLib.Figures.(figName).Handle = figure(ettLib.Figures.(figName).Number);
% loop through each of the specified properties for this figure
props = fieldnames(ettLib.Figures.(figName).Properties);

% Number if the first property, so skip that and go to the 2nd 
for p = 1:length(props)
  handle.(props{p}) = ettLib.Figures.(figName).Properties.(props{p});
end

%% Add Menu items
if isfield(ettLib.Figures.(figName),'UIMenu');
  nMenus = length(ettLib.Figures.(figName).UIMenu);
  for m = 1:nMenus
    menuProps = fieldnames(ettLib.Figures.(figName).UIMenu(m));
    ettLib.Figures.(figName).UIMenu(m).Handle = uimenu;
    % make sure it gets attached to the right parent
    attach(ettLib.Figures.(figName).UIMenu(m).Handle,...
      ettLib.Figures.(figName).UIMenu(m).Parent)
    % first property is the parent definition, so skip that and do the rest
    for p = 2:length(menuProps)
      U.(menuProps{p}) = ettLib.Figures.(figName).UIMenu(m).(menuProps{p});
    end    
  end
end


function attach(obj,parStr)
% attaches an object, obj, to its parent by evaluating parStr
eval(['obj.Parent = ' parStr])
end