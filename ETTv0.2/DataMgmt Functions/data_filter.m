function [subdata] = data_filter(subdata,procsettings)
% 
% data_filter
% Filter the data based on the PreProcessings settings.
% 
% INPUTS:
% subdata - current subject data
% procsettings - filter and interp settings
% 
% OUTPUTS:
% Filtered - structure with the new filtered data
% subdata - update subdata structure
% 
%% Change Log
%   [SH] - 05/08/14:    v1 - Creation 

%%
filt_type = procsettings(1);
switch filt_type
    case 1 %SG Olay
        filt_order = procsettings(5); filt_wind = procsettings(4); filt_wind = 5 + 2*(subdata.SampleRate/60);
        FiltX = nan(size(subdata.Interpolation.InterpX)); FiltY = nan(size(subdata.Interpolation.InterpY)); FiltD = nan(size(subdata.Interpolation.InterpD)); FiltP = nan(size(subdata.Interpolation.InterpP));
        for trinum = 1:size(subdata.Interpolation.InterpX,1)
            notnans = find(~isnan(subdata.Interpolation.InterpX(trinum,:)));
            segstart = [notnans(1),notnans(find(diff(notnans)>1)+1)];
            segend = [notnans(find(diff(notnans)>1)),notnans(end)];
            segstartfilt = segstart(segend-segstart+1>=filt_wind); segstartnof = segstart(segend-segstart+1<filt_wind);
            segendfilt = segend(segend-segstart+1>=filt_wind); segendnof = segend(segend-segstart+1<filt_wind);
            for segfilt = 1:length(segstartfilt)
                FiltX(trinum,segstartfilt(segfilt):segendfilt(segfilt)) = sgolayfilt(subdata.Interpolation.InterpX(trinum,segstartfilt(segfilt):segendfilt(segfilt)),filt_order,filt_wind);
                FiltY(trinum,segstartfilt(segfilt):segendfilt(segfilt)) = sgolayfilt(subdata.Interpolation.InterpY(trinum,segstartfilt(segfilt):segendfilt(segfilt)),filt_order,filt_wind);
                FiltD(trinum,segstartfilt(segfilt):segendfilt(segfilt)) = sgolayfilt(subdata.Interpolation.InterpD(trinum,segstartfilt(segfilt):segendfilt(segfilt)),filt_order,filt_wind);
                FiltP(trinum,segstartfilt(segfilt):segendfilt(segfilt)) = sgolayfilt(subdata.Interpolation.InterpP(trinum,segstartfilt(segfilt):segendfilt(segfilt)),filt_order,filt_wind);
            end
            for seginput = 1:length(segstartnof)
                FiltX(trinum,segstartnof(seginput):segendnof(seginput)) = subdata.Interpolation.InterpX(trinum,segstartnof(seginput):segendnof(seginput));
                FiltY(trinum,segstartnof(seginput):segendnof(seginput)) = subdata.Interpolation.InterpY(trinum,segstartnof(seginput):segendnof(seginput));
                FiltD(trinum,segstartnof(seginput):segendnof(seginput)) = subdata.Interpolation.InterpD(trinum,segstartnof(seginput):segendnof(seginput));
                FiltP(trinum,segstartnof(seginput):segendnof(seginput)) = subdata.Interpolation.InterpP(trinum,segstartnof(seginput):segendnof(seginput));
            end
            filtbegin{trinum} = segstartfilt; filtend{trinum} = segendfilt;
        end
end

subdata.Filtered.FiltX = FiltX;
subdata.Filtered.FiltY = FiltY;
subdata.Filtered.FiltD = FiltD;
subdata.Filtered.FiltP = FiltP;

subdata.Filtered.Indices = [filtbegin;filtend]';
end