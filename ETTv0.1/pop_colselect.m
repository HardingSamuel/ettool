function [coldata] = pop_colselect(direct, sublist)



colfig = figure('Position', [340 600 500 290], 'Name', 'Manage Columns', 'NumberTitle', 'off', 'MenuBar', 'none', 'Color', [.1 .5 .1]);
data = guihandles(colfig);
data.count = [];
data.phase = [];
data.cond = [];

data.list_selected = 1;
guidata(colfig, data);
coldata = [];
auto = 1;

DIRECT = dir([direct, '/MATLAB/INPUT/DATA/XLSDATA/']);

Status = uicontrol(colfig, 'Style', 'text', 'Position', [25 260 450 25], 'String', 'Loading Please Wait...', ...
    'BackgroundColor', [.2 .7 .2], 'FontSize', 16, 'ForegroundColor', [1 1 1]);
pause(1)
% keyboard
e = actxserver ('Excel.Application');
filename = fullfile([direct, '/MATLAB/INPUT/DATA/XLSDATA/', DIRECT(sublist(1)+2).name]);
ewb = e.Workbooks.Open(filename);
esh = ewb.ActiveSheet;
sheetObj = e.Worksheets.get('Item', e.Worksheets.Item(1).Name);
num_cols = sheetObj.UsedRange.Columns.Count;
num_rows = sheetObj.UsedRange.Rows.Count;
cellname = sheetObj.UsedRange.Address;
cellname = strrep(cellname, '$', '');
if num_cols <= 26
    range_name = strcat('A1:', cellname(4), '1');
    range_name2 = strcat('A', num2str(num_rows), ':', cellname(4), num2str(num_rows));
else
    range_name = strcat('A1:', cellname(4:5), '1');
    range_name2 = strcat('A', num2str(num_rows), ':', cellname(4:5), num2str(num_rows));
end


[~, ~, raw] = xlsread([direct, '/MATLAB/INPUT/DATA/XLSDATA/', DIRECT(sublist(1)+2).name], range_name); set(Status, 'Visible', 'off');
[~, ~, raw2] = xlsread([direct, '/MATLAB/INPUT/DATA/XLSDATA/', DIRECT(sublist(1)+2).name], range_name2); set(Status, 'Visible', 'off');
figure(colfig)
ewb.Close;
waitfor(Status, 'Visible', 'off')

columns = raw(1,:);
for i = length(columns):-1:1
    if ~isnan(columns{i})
        break
    end
end
coln = i;
coln = i - 23;

collist = columns(24:23+coln);
col_index = 1:length(collist);
data.na = 1:length(collist);

for i = 24:coln
end
%     keyboard
orig_collist = collist;
orig_index = 1:length(collist) ;

ColCheck = uicontrol('Style', 'checkbox', 'Position', [10 270 250 20], 'String', 'Automatic Columns', 'BackgroundColor', [.2 .7 .2], 'ForegroundColor', [.2 .2 .2], 'Value', 0, 'Callback', @EnableAllFunction);

List = uicontrol(colfig, 'Style', 'listbox', 'String', collist', 'Position', [10 70 250 195], 'Enable', 'on');

CountButton = uicontrol(colfig, 'Style', 'pushbutton', 'String', 'Trial Counter', 'Position', [270 260 80 20], 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [.2 .2 .2], 'Callback', @CountButtonCallback, 'Enable', 'on');
CountText = uicontrol(colfig, 'Style', 'text', 'String', '', 'Position', [360 260 100 20], 'BackgroundColor', [.9 .9 .9], 'ForegroundColor', [.2 .2 .2], 'Enable', 'on');

PhaseButton = uicontrol(colfig, 'Style', 'pushbutton', 'String', 'Phase Indicator', 'Position', [270 230 80 20], 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [.2 .2 .2], 'Callback', @PhaseButtonCallback, 'Enable', 'on');
PhaseText = uicontrol(colfig, 'Style', 'text', 'String', '', 'Position', [360 230 100 20], 'BackgroundColor', [.9 .9 .9], 'ForegroundColor', [.2 .2 .2], 'Enable', 'on');

ConditionButton = uicontrol(colfig, 'Style', 'pushbutton', 'String', 'Conditions', 'Position', [270 200 80 20], 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [.2 .2 .2], 'Callback', @ConditionButtonCallback, 'Enable', 'on');
ConditionReset = uicontrol(colfig, 'Style', 'pushbutton', 'String', 'Clear', 'Position', [270 170 80 20], 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [.2 .2 .2], 'Callback', @ConditionResetCallback, 'Enable', 'on');
ConditionText = uicontrol(colfig, 'Style', 'text', 'String', '', 'Position', [360 70 100 150], 'BackgroundColor', [.9 .9 .9], 'ForegroundColor', [.2 .2 .2], 'Enable', 'on');

DoneButton = uicontrol(colfig, 'Style', 'pushbutton', 'String', 'Done', 'Position', [125 10 100 50], 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [.2 .2 .2],'FontSize', 12, 'Callback', @DoneReturnFunction, 'Enable', 'on');
ResetButton = uicontrol(colfig, 'Style', 'pushbutton', 'String', 'Reset', 'Position', [275 10 100 50], 'BackgroundColor', [.7 .7 .7], 'ForegroundColor', [.2 .2 .2],'FontSize', 12, 'Callback', @ResetFunction, 'Enable', 'on');
%     keyboard
uiwait(gcf)

    function EnableAllFunction(ColCheck, eventdata)
        if get(ColCheck, 'Value') == 1
            set(List, 'Enable', 'off')
            
            set(CountButton, 'Enable', 'off')
            set(CountText, 'Enable', 'off')
            
            set(PhaseButton, 'Enable', 'off')
            set(PhaseText, 'Enable', 'off')
            
            set(ConditionButton, 'Enable', 'off')
            set(ConditionReset, 'Enable', 'off')
            set(ConditionText, 'Enable', 'off')
        else
            set(List, 'Enable', 'on')
            
            set(CountButton, 'Enable', 'on')
            set(CountText, 'Enable', 'on')
            
            set(PhaseButton, 'Enable', 'on')
            set(PhaseText, 'Enable', 'on')
            
            set(ConditionButton, 'Enable', 'on')
            set(ConditionText, 'Enable', 'on')
        end
    end


    function varargout = CountButtonCallback(Countbutton, eventdata)
        if strcmp(get(CountText, 'String'), '')
            data.list_selected = get(List, 'Value');
            set(CountText, 'String', collist(data.list_selected))
            collist(data.list_selected) = '';
            data.count = col_index(data.list_selected);
            col_index(data.list_selected) = [];
            set(List, 'Value', 1)
            set(List, 'String', collist)
            guidata(colfig, data);
            
            
        else
            collist = [collist, get(CountText, 'String')];
            col_index = [col_index, data.count];
            set(CountText, 'String', '')
            set(List, 'String', collist)
            guidata(colfig, data)
            data.count = [];
        end
        check_empty_list
    end

    function varargout = PhaseButtonCallback(Phasebutton, eventdata)
        if strcmp(get(PhaseText, 'String'), '')
            data.list_selected = get(List, 'Value');
            set(PhaseText, 'String', collist(data.list_selected))
            collist(data.list_selected) = '';
            data.phase = col_index(data.list_selected);
            col_index(data.list_selected) = [];
            set(List, 'Value', 1)
            set(List, 'String', collist)
            guidata(colfig, data);
            
        else
            collist = [collist, get(PhaseText, 'String')];
            col_index = [col_index, data.phase];
            set(PhaseText, 'String', '')
            set(List, 'String', collist)
            guidata(colfig, data);
            data.phase = [];
        end
        check_empty_list
    end

    function varargout = ConditionButtonCallback(ConditionButton, eventdata)
        data.list_selected = get(List, 'Value');
        set(ConditionText, 'String', [get(ConditionText, 'String'); collist(data.list_selected)])
        collist(data.list_selected) = '';
        data.cond = [data.cond, col_index(data.list_selected)];
        col_index(data.list_selected) = [];
        set(List, 'String', collist)
        guidata(colfig, data);
        set(ConditionReset, 'Enable', 'on')
        check_empty_list
    end

    function varargout = ConditionResetCallback(ConditionButton, eventdata)
        collist = [collist, get(ConditionText, 'String')'];
        col_index = [col_index, data.cond];
        set(List, 'Value', 1)
        set(List, 'String', collist);
        set(ConditionText, 'String', '');
        guidata(colfig, data);
        set(ConditionReset, 'Enable', 'off')
        data.cond = [];
        check_empty_list
    end

    function varargout = DoneReturnFunction(DoneButton, eventdata)
        auto = get(ColCheck, 'Value');
        if auto == 0
            coldata = 1:length(orig_collist);
            coldata(2,data.count) = 1;
            coldata(2,data.phase) = 2;
            coldata(2,data.cond) = 3;
            if ~all(ismember([data.count, data.phase, data.cond], data.na))
                data.na([data.count, data.phase, data.cond]) = [];
            else
                data.na = [];
            end
            coldata(2, data.na) = 4;
        else
            coldata = col_identify(direct, sublist);
        end
        gettypes
        close
    end

    function varargout = ResetFunction(ResetButton, eventdata)
        data.count = [];
        data.phase = [];
        data.cond = [];
        data.na = 1:coln;
        collist = orig_collist;
        col_index = orig_index;
        set(List, 'String', collist)
        set(CountText, 'String', '')
        set(PhaseText, 'String', '')
        set(ConditionText, 'String', '')
        check_empty_list
    end

    function check_empty_list
        if length(collist)<1
            set(CountButton, 'enable', 'off')
            set(PhaseButton, 'enable', 'off')
            set(ConditionButton, 'enable', 'off')
        else
            set(CountButton, 'enable', 'on')
            set(PhaseButton, 'enable', 'on')
            set(ConditionButton, 'enable', 'on')
        end
    end
%     keyboard

    function gettypes        
        for gti = 1:size(coldata,2)
            if coldata(2,gti) == 3
                if isnumeric(raw2{1,23+gti})
                    coldata(3,gti) = 1;
                else
                    coldata(3,gti) = 2;
                end
            end
        end
    end



end