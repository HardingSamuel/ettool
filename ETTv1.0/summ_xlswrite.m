%   [SH] - 02/25/14:  Creation. To be called from pop_Summary to flexibly
%   write into Excel

function summ_xlswrite(DIRECT, STUDYNAME, SHEETNAME, values, range)
% keyboard
outname = [DIRECT '\EXCEL\' STUDYNAME ' SUMMARY.xlsx'];
alph = {'[A-Z]'};
alphlist = ['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R' 'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z'];
num = {'[0-9]'};

numsat = cell2mat(regexp(range,num)); %numsat = [numsat(1), numsat(diff(numsat)==1)]
letsat = cell2mat(regexp(range,alph));

if length(letsat) > 2 & find(find(diff(letsat)==1)==1)
    firstcol = find(range(letsat(1))==alphlist)*26 + find(range(letsat(2))==alphlist);
else
    firstcol = find(range(1)==alphlist);
end

e = actxserver ('Excel.Application');
ewb = e.Workbooks.Open(outname);
sheetObj = e.Worksheets.get('Item', SHEETNAME);
num_cols = sheetObj.UsedRange.Columns.Count;
num_rows = sheetObj.UsedRange.Rows.Count;
usedrange = sheetObj.UsedRange.Address;
usedrange = strrep(usedrange, '$', '');
e.Quit
delete(e)

% keyboard
usedfirstcol = find(usedrange(1) == alphlist);
if length(usedrange)==2
    usedrange = strcat(usedrange, ':', usedrange);
end
usedlastcol = find(usedrange(strfind(usedrange,':')+1)==alphlist);

if firstcol <= usedlastcol 
    xlsfig = figure('pos', [138 609 360 90], 'menubar', 'none', 'numbertitle', 'off', 'Color', [.1 .5 .1], 'Name', 'Select Test Phase', 'visible', 'on');
    uicontrol('style', 'text', 'string', 'Selected Range already has data.  Overwrite?', 'pos', [10 50 340 30]);
    uicontrol('style', 'pushbutton', 'string', 'Yes', 'Callback', {@writexl, outname, SHEETNAME, values, range}, 'pos', [185 10 165 30])
    uicontrol('style', 'pushbutton', 'string', 'No', 'callback', 'close', 'pos', [10 10 165 30])
    uiwait
else
    try
        xlswrite(outname,values,SHEETNAME,range)    
    catch
        error('Writing Failed, File Likely still open')
    end
end

function writexl(~,~,writefile,writesheet,writevalues,writerange)
    close(gcf)
    xlsfig = figure('pos', [138 609 360 50], 'menubar', 'none', 'numbertitle', 'off', 'Color', [.1 .5 .1], 'Name', 'Writing to Excel', 'visible', 'on');
    uicontrol('style', 'text', 'string', 'Writing Data, please wait', 'pos', [10 10 340 30]);
    uiresume
    try
        xlswrite(writefile,writevalues,writesheet,writerange)    
    catch
        error('Writing Failed, File Likely still open')
    end
    close(gcf)
    

