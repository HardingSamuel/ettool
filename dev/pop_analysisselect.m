function [analysisout] = pop_analysisselect

analysisfig = figure('Position', [1992 604 494 132], 'Name', 'Select Additional Analyses', 'NumberTitle', 'off', 'MenuBar', 'none', 'Color', [.1 .5 .1]);

analysisout = zeros(1, 4);
%         fixsac
%         aois
%         rt
%         custom
title_ui = uicontrol('Style', 'Text', 'String', 'Select Additional Analyses', 'position', [10 112 474 20]);


fix_ui = uicontrol('style', 'checkbox', 'string', 'Fixation/Saccade', 'Value', 0, 'Position', [10 82 130 20]);
fix_ui_sp = uicontrol('style', 'checkbox', 'string', 'Fixation/Saccade + SP', 'Value', 0, 'Position', [10 52 130 20]);
rt_ui = uicontrol('style', 'checkbox', 'string', 'ReactionTime', 'Value', 0, 'Position', [150 82 130 20]);
aoi_ui = uicontrol('style', 'checkbox', 'string', 'AOI Dwell', 'Value', 0, 'Position', [290 82 130 20]);

custom_ui = uicontrol('style', 'checkbox', 'string', 'Custom', 'Value', 0, 'Position', [354 10 130 20]);

donebut = uicontrol('style', 'pushbutton', 'string', 'Done', 'Position', [10 10 130 20], 'callback', @done_button_callback);

uiwait(gcf)
function varargour = done_button_callback(donebut, eventdata)
    analysisout = [get(fix_ui, 'Value'), get(rt_ui, 'Value'), get(aoi_ui, 'Value'), get(custom_ui, 'Value'), get(fix_ui_sp, 'Value')];
    close
end

end

