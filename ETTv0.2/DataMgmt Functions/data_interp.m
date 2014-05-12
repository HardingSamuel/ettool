function [subdata] = data_interp(subdata,procsettings)
% 
% data_interp
% Interpolation step to be called from the PreProcess script or other
% processes later on that allow more flexibility.
% 
% INPUTS:
% subdata - the subject's data to be interpolated 
% procsettings - subject's settings, can be from the ETT project settings
% or an individual's Custom configuration.
% 
% OUTPUTS:
% Interpolation - structure containing the interpolated data.
% 
%% Change Log
%   [SH] - 05/08/14:    v1 - Creation 

%%
max_interp = floor(procsettings(2)/(1000/subdata.SampleRate));
max_blink = floor(procsettings(3)/(1000/subdata.SampleRate));

gapstart = arrayfun(@(X) find(diff(subdata.Combined.GoodEyes(X,:),1,2)==-1)+1,1:size(subdata.Combined.GoodEyes,1),'uni',0);
gapend = arrayfun(@(X) find(diff(subdata.Combined.GoodEyes(X,:),1,2)==1),1:size(subdata.Combined.GoodEyes,1),'uni',0);
point1 = [subdata.Combined.GoodEyes(:,1)==0,subdata.Combined.GoodEyes(:,end)==0];

InterpX = subdata.Combined.CombX; InterpY = subdata.Combined.CombY; InterpD = subdata.Combined.CombD; InterpP = subdata.Combined.CombP;

for trinum = 1:size(gapstart,2)
    
    if ismember(trinum,find(point1(:,1)))
        gapstart{trinum} = cat(2,1,gapstart{trinum});
    end
    if ismember(trinum,find(point1(:,2)))
        gapstart{trinum}(end) = [];
    end
    
    gapdata{trinum} = [gapstart{trinum};gapend{trinum};...
        gapend{trinum}-gapstart{trinum}+1;...
        (gapend{trinum}-gapstart{trinum}+1>max_interp) + (gapend{trinum}-gapstart{trinum}+1>max_blink)];
    gapdata{trinum}(:,gapdata{trinum}(1,:) == 1) = [];
    gapdata{trinum}(:,gapdata{trinum}(2,:) == subdata.TrialLengths(trinum)) = [];
    interps = find(gapdata{trinum}(4,:) == 0);
    interpstart{trinum} = gapdata{trinum}(1,interps)-1; interpend{trinum} = gapdata{trinum}(2,interps)+1;    
    blinks = find(gapdata{trinum}(4,:) == 1);
    blinkstart{trinum} = gapdata{trinum}(1,blinks)-1; blinkend{trinum} = gapdata{trinum}(2,blinks)+1;
    for interp_iter = interps
        
        InterpX(trinum,gapdata{trinum}(1,interp_iter)-1:gapdata{trinum}(2,interp_iter)+1) = ...
            linspace(subdata.Combined.CombX(trinum,gapdata{trinum}(1,interp_iter)-1),subdata.Combined.CombX(trinum,gapdata{trinum}(2,interp_iter)+1),...
            gapdata{trinum}(3,interp_iter)+2);
        InterpY(trinum,gapdata{trinum}(1,interp_iter)-1:gapdata{trinum}(2,interp_iter)+1) = ...
            linspace(subdata.Combined.CombY(trinum,gapdata{trinum}(1,interp_iter)-1),subdata.Combined.CombY(trinum,gapdata{trinum}(2,interp_iter)+1),...
            gapdata{trinum}(3,interp_iter)+2);
        InterpD(trinum,gapdata{trinum}(1,interp_iter)-1:gapdata{trinum}(2,interp_iter)+1) = ...
            linspace(subdata.Combined.CombD(trinum,gapdata{trinum}(1,interp_iter)-1),subdata.Combined.CombD(trinum,gapdata{trinum}(2,interp_iter)+1),...
            gapdata{trinum}(3,interp_iter)+2);
        InterpP(trinum,gapdata{trinum}(1,interp_iter)-1:gapdata{trinum}(2,interp_iter)+1) = ...
            linspace(subdata.Combined.CombP(trinum,gapdata{trinum}(1,interp_iter)-1),subdata.Combined.CombP(trinum,gapdata{trinum}(2,interp_iter)+1),...
            gapdata{trinum}(3,interp_iter)+2);
    end
end

subdata.Interpolation.InterpX = InterpX;
subdata.Interpolation.InterpY = InterpY;
subdata.Interpolation.InterpD = InterpD;
subdata.Interpolation.InterpP = InterpP;
subdata.Interpolation.Indices = [interpstart;interpend]';
subdata.Interpolation.Blinks = [blinkstart;blinkend]';

subdata.GoodData.Interpolation = cell2mat(arrayfun(@(X) length(find(~isnan(InterpX(X,1:subdata.TrialLengths(X)))))/subdata.TrialLengths(X),1:size(InterpX,1),'uni',0))';

end