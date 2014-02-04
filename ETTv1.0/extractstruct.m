function [strucout] = extractstruct(structure)

fn = fieldnames(structure);
ft = gettypes(structure);
fv = cell(length(fn),1);

for getfield = 1:length(fn)
    if ~strcmp(ft(getfield), 'struct')
        fv(getfield) = {structure.(char(fn(getfield)))};
    end
end
% keyboard
fn(cellfun(@isempty,fv)) = [];
fv(cellfun(@isempty,fv)) = [];
strucout = {[fn,fv]};