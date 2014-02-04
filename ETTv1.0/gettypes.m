function [typearray] = gettypes(structure)

typearray = [];
fn = fieldnames(structure);
for i = 1:length(fn)
    typearray = [typearray; {class(structure.(char(fn(i))))}];
end
end