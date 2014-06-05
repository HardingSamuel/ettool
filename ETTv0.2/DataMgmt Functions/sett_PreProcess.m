function [Settings] = sett_PreProcess(ETT,mode,existsettings)
%
% sett_PreProcess
% A function with settings for PreProcessing.  Allows users to define on a
% project, subject, or real-time basis the setting associated with
% Pre-Processing.
%
% INPUTS:
% ETT - to get project- or subject-wise processing settings
%
% OUTPUTS:
% Settings - updated settings returned to caller
%
%% Change Log
%   [SH] - 05/05/14:    v1 - Creation

%%

switch mode
    case 0
        text_done = 'Finished';
    case 1
        text_done = 'Refresh';
end

Settings = []; curr_fil = 1;
val_mil = 80; val_blk = 500; val_sett1 = 15; val_sett2 = 2;filtsett = [15,2];
if ~isempty(existsettings)
    Settings = existsettings;
    curr_fil = existsettings(1);
    val_mil = existsettings(2);
    val_blk = existsettings(3);
    val_sett1 = existsettings(4);
    val_sett2 = existsettings(5);
end
text_mil = num2str(val_mil); text_blk = num2str(val_blk); text_sett1 = num2str(val_sett1); text_sett2 = num2str(val_sett2);

PPFig = figure('Position',[460 570 260 330],'Menubar','None','NumberTitle','Off','Color',[.65 .75 .65],...
    'Name','PreProcessing Settings');

uipanel('Title', 'Interpolation:', 'Units', 'Pixels', 'Position', [10 200 240 120], 'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style','Edit','String','Max. Interp. Duration (ms):','Position',[15 255 175 40],'BackGroundColor',[.7 .8 .7],...
    'FontSize',10,'Enable','Off')
uicontrol('Style','Edit','String','Max. Blink Duration (ms):','Position',[15 210 175 40],'BackGroundColor',[.7 .8 .7],...
    'FontSize',10,'Enable','Off')

MaxIntrpLat = uicontrol('Style','Edit','String',text_mil,'Value',val_mil,'Position',[190 255 55 40],'FontSize',10,...
    'BackGroundColor',[1 1 1]);
MaxBlinkLat = uicontrol('Style','Edit','String',text_blk,'Value',val_blk,'Position',[190 210 55 40],'FontSize',10,...
    'BackGroundColor',[1 1 1]);


FiltButtonGroup = uibuttongroup('Visible','On','units','Pixels','Position',[10 55 240 135],'BackGroundColor',[.7 .8 .7],...
    'Title','Filtering:','TitlePosition','lefttop','FontSize',12,'SelectionChangefcn',@filt_select);
FiltOption1 = uicontrol('Style','RadioButton','String','Savitzky–Golay (Default)','Enable','On','Value',1,...
    'Position',[2.5 90 230 25],'FontSize',10,'Parent',FiltButtonGroup,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_fil==1,'UserData',1);
FiltOption2 = uicontrol('Style','RadioButton','String','Bilateral Filter','Enable','On','Value',0,...
    'Position',[2.5 70 230 25],'FontSize',10,'Parent',FiltButtonGroup,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_fil==2,'UserData',2,'Enable','Off');
FiltOption3 = uicontrol('Style','RadioButton','String','Moving Average','Enable','On','Value',0,...
    'Position',[2.5 50 230 25],'FontSize',10,'Parent',FiltButtonGroup,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_fil==3,'UserData',3,'Enable','Off');
FiltOption4 = uicontrol('Style','RadioButton','String','Low-Pass Filter','Enable','On','Value',0,...
    'Position',[2.5 30 230 25],'FontSize',10,'Parent',FiltButtonGroup,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_fil==4,'UserData',4,'Enable','Off');

FiltSettings = uicontrol('Style','PushButton','String','Filter Settings','BackGroundColor',[.8 .8 .8],...
    'Parent',FiltButtonGroup,'Position',[5 5 227.5 25],'FontSize',10,'Callback',@filt_edit);

uicontrol('Style','Pushbutton','String',text_done,'BackgroundColor',[.8 .8 .8],...
    'Parent',PPFig,'Position',[10 10 240 35],'FontSize',12,'Callback',@donerefresh)


    function filt_select(~,eventdata)
        curr_fil = get(eventdata.NewValue,'UserData');
    end

    function filt_edit(~,~)
        set(FiltOption1,'Visible','off')
        set(FiltOption2,'Visible','off')
        set(FiltOption3,'Visible','off')
        set(FiltOption4,'Visible','off')
        set(FiltSettings,'String','Return','Callback',@sett_return)
        
        switch curr_fil
            case 1
                sett1txt = uicontrol('Style','Text','String','Window Length (must be odd):  ','Parent',FiltButtonGroup,...
                    'Position',[5 90 180 20],'FontSize',10,'BackGroundColor',[.7 .8 .7],'HorizontalAlignment','Left');
                sett1 = uicontrol('Style','Edit','String',text_sett1,'Parent',FiltButtonGroup,'Position',[190 90 45 20],...
                    'FontSize',10,'BackGroundColor',[1 1 1]);
                sett2txt = uicontrol('Style','Text','String',['Filter Order:  ' text_sett2],'Parent',FiltButtonGroup,...
                    'Position',[5 60 175 20],'FontSize',10,'BackGroundColor',[.7 .8 .7],'HorizontalAlignment','Left');
                sett2 = uicontrol('Style','Slider','Min',1,'Max',5,'Value',val_sett2,'SliderStep',[.25 .25],...
                    'Parent',FiltButtonGroup,'Position',[5 40 227.5 20],'Callback',@slide_text);
            case 3
                sett1txt = uicontrol('Style','Text','String','Window Length (must be odd):  ','Parent',FiltButtonGroup,...
                    'Position',[5 90 180 20],'FontSize',10,'BackGroundColor',[.7 .8 .7],'HorizontalAlignment','Left');
                sett1 = uicontrol('Style','Edit','String','15','Parent',FiltButtonGroup,'Position',[190 90 45 20],...
                    'FontSize',10,'BackGroundColor',[1 1 1]);
        end
        
        function slide_text(~,~)
            text_ex = '';
            slidval = fix(get(sett2,'Value'));
            if slidval ==2
                text_ex = ' (Default)';
            end
            set(sett2txt,'String',['Filter Order:  ' num2str(slidval) text_ex])
            set(sett2,'Value',slidval)
        end
        
        function sett_return(~,~)
            set(sett1,'Visible','Off')
            set(sett1txt,'Visible','Off')
            try
                set(sett2txt,'Visible','Off')
                set(sett2,'Visible','Off')
                val_sett2 = get(sett2,'Value');
            end
            set(FiltOption1,'Visible','on')
            set(FiltOption2,'Visible','on')
            set(FiltOption3,'Visible','on')
            set(FiltOption4,'Visible','on')
            set(FiltSettings,'String','Return','Callback',@filt_edit)
            filtsett = [str2num(get(sett1,'String')),val_sett2];
        end
    end

    function donerefresh(~,~)
        if  filtsett(2) >= filtsett(1)
            filtsett(1) = 5 + 2 * filtsett(2);
            errordlg(['Error while filtering:  SGOlay Filter Order must be less than the window length.' char(10) 'Adjusting Window to length:' char(10) num2str(filtsett(1))  '   (5 + 2 * Filter Order)']);
        end
        
        interpval = str2num(get(MaxIntrpLat,'String'));
        blinkval = str2num(get(MaxBlinkLat,'String'));
        Settings = [curr_fil,interpval,blinkval,filtsett];
        uiresume(PPFig)
    end

uiwait(PPFig)
try
close(PPFig)
end
end