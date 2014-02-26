%   [SH] - 02/26/14:  Creation

function phasedata = phase_keep(phasedata, PhaseNames)
% keyboard
phasefig = figure('pos', [138 609 360 220], 'menubar', 'none', 'numbertitle', 'off', 'Color', [.1 .5 .1], 'Name', 'Select Test Phase');
uicontrol('parent', phasefig, 'style', 'text', 'String', 'Do you want to analyze trials with this Phase Structure?', 'pos', [10 150 340 60], 'fontsize', 14);
phaselist = uicontrol('parent', phasefig, 'style', 'listbox', 'String', char(PhaseNames), 'pos', [10 10 165 130], 'fontsize', 10, 'max', length(PhaseNames), 'value', []);
uicontrol('parent', phasefig, 'style', 'pushbutton', 'String', 'Yes', 'pos', [185 80 165 60], 'fontsize', 10, 'callback', {@keepreject,1});
uicontrol('parent', phasefig, 'style', 'pushbutton', 'String', 'No', 'pos', [185 10 165 60], 'fontsize', 10, 'callback', {@keepreject,0});
uiwait

    function keepreject(~,~,mode)
        switch mode
            
            case 1
                phasedata.PhaseKeep = [phasedata.PhaseKeep, {PhaseNames}];
                if isempty(get(phaselist, 'value'))
                    phaseval = 1:size(get(phaselist, 'string'),1);
                else
                    phaseval = get(phaselist, 'value');
                end
                
                phasedata.PhaseIndx = [phasedata.PhaseIndx, {phaseval}];
                close(phasefig)
                uiresume
                %         phasefig = figure('pos', [138 609 360 220], 'menubar', 'none', 'numbertitle', 'off', 'Color', [.1 .5 .1], 'Name', 'Select Test Phase', 'visible', 'off');
                %                 uiresume
            case 0
                phasedata.PhaseReject = [phasedata.PhaseReject, {PhaseNames}];
                close(phasefig)
                uiresume
                %         phasefig = figure('pos', [138 609 360 220], 'menubar', 'none', 'numbertitle', 'off', 'Color', [.1 .5 .1], 'Name', 'Select Test Phase', 'visible', 'off');
                %                 uiresume
        end
    end
end


% function phase_keep(~,~,keepreject,PhaseValues)
%         switch keepreject
%             case 1
%                 phasedata.PhaseKeep = [phasedata.PhaseKeep, {PhaseValues}];
%                 if isempty(get(phaselist, 'value'))
%                     phaseval = 1:size(get(phaselist, 'string'),1);
%                 else
%                     phaseval = get(phaselist, 'value');
%                 end
%
%                 phasedata.PhaseIndx = [phasedata.PhaseIndx, {phaseval}];
%                 close(phasefig)
%                 phasefig = figure('pos', [138 609 360 220], 'menubar', 'none', 'numbertitle', 'off', 'Color', [.1 .5 .1], 'Name', 'Select Test Phase', 'visible', 'off');
% %                 uiresume
%             case 0
%                 phasedata.PhaseReject = [phasedata.PhaseReject, {PhaseValues}];
%                 close(phasefig)
%                 phasefig = figure('pos', [138 609 360 220], 'menubar', 'none', 'numbertitle', 'off', 'Color', [.1 .5 .1], 'Name', 'Select Test Phase', 'visible', 'off');
% %                 uiresume
%         end
%     end