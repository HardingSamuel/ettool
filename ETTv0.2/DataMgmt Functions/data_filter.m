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
%   [SH] - 06/19/14:   v1.1 - Added GoodData.Filtered calculation
%   [SH] - 09/05/14:   Added filtbegin in cases where trial is completely
%   null

%%
filt_type = procsettings(1);
switch filt_type
    case 1 %SG Olay
        filt_order = procsettings(5); filt_wind = procsettings(4);
        FiltX = nan(size(subdata.Interpolation.InterpX)); FiltY = nan(size(subdata.Interpolation.InterpY)); FiltD = nan(size(subdata.Interpolation.InterpD)); FiltP = nan(size(subdata.Interpolation.InterpP));
        for trinum = 1:size(subdata.Interpolation.InterpX,1)
            notnans = find(~isnan(subdata.Interpolation.InterpX(trinum,:)));
            if ~isempty(notnans)
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
            else
                filtbegin{trinum} = nan; filtend{trinum} = nan;
                FiltX(trinum,:) = nan(1,size(subdata.Interpolation.InterpX,2));
                FiltY(trinum,:) = nan(1,size(subdata.Interpolation.InterpY,2));
                FiltD(trinum,:) = nan(1,size(subdata.Interpolation.InterpD,2));
                FiltP(trinum,:) = nan(1,size(subdata.Interpolation.InterpP,2));
            end
        end
end

subdata.Filtered.FiltX = FiltX;
subdata.Filtered.FiltY = FiltY;
subdata.Filtered.FiltD = FiltD;
subdata.Filtered.FiltP = FiltP;

subdata.Filtered.Indices = [filtbegin;filtend]';

subdata.GoodData.Filtered = cell2mat(arrayfun(@(X) length(find(~isnan(FiltX(X,:))))/subdata.TrialLengths(X),1:size(FiltX,1),'uni',0))';
end