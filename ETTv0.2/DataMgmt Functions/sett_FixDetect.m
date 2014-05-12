function [Settings] = sett_FixDetect(ETT,mode,existsettings)
% 
% sett_FixDetect
% Interface to edit settings when performing fixation/saccade detection
% 
% INPUTS:
% ETT
% 
% OUTPUTS:
% ETT
% 
%% Change Log
%   [SH] - 05/08/14:    v1 - Creation 

%%
Settings = cell(1,5);
switch mode
    case 0
        text_done = 'Finished';
        FixFigPos = [460 570 260 330];
    case 1
        text_done = 'Refresh';
        FixFigPos = [460 197.5 260 330];
end
val_velo = 40; val_fixdur = 100; val_bins = 5; val_trm = [.1 .45 .45; 0 .95 .05; 0 .05 .95];
curr_est = 1; text_trm = '[.1 .45 .45;     0 .95 .05;     0 .05 .95]';
if ~isempty(existsettings)
    val_velo = existsettings{1};
    val_fixdur = existsettings{2};
    val_trm = existsettings(3);
    text_trm = strcat('[', num2str(val_trm{1}(1,:)), ';     ', num2str(val_trm{1}(2,:)), ';     ', num2str(val_trm{1}(3,:)), ']');
    text_trm = strrep(text_trm,'        ', ' ');
    val_bins = existsettings{4};
    curr_est = existsettings{5};
end

text_velo = num2str(val_velo); text_fixdur = num2str(val_fixdur); text_bins = num2str(val_bins);

FixSacFig = figure('Position',FixFigPos,'Menubar','None','NumberTitle','Off','Color',[.65 .75 .65],...
    'Name','Fixation/Saccade Settings');

uipanel('Title', 'IVT Settings:', 'Units', 'Pixels', 'Position', [10 222.5 240 97.5],...
    'BackgroundColor', [.7 .8 .7], 'FontSize', 12, 'ForegroundColor', [.1 .1 .1]);
uicontrol('Style','Edit','String','Velocity Threshold:','Position',[15 265 175 30],'BackGroundColor',[.7 .8 .7],...
    'FontSize',10,'Enable','Off')
uicontrol('Style','Edit','String','Minimum Fixation Duration:','Position',[15 232.5 175 30],'BackGroundColor',[.7 .8 .7],...
    'FontSize',10,'Enable','Off')

VeloThresh = uicontrol('Style','Edit','String',text_velo,'Value',val_velo,'Position',[190 265 55 30],'FontSize',10,...
    'BackGroundColor',[1 1 1]);
MinFixDur = uicontrol('Style','Edit','String',text_fixdur,'Value',val_fixdur,'Position',[190 232.5 55 30],'FontSize',10,...
    'BackGroundColor',[1 1 1]);

HmmEst = uibuttongroup('Visible','On','units','Pixels','Position',[10 55 240 155],'BackGroundColor',[.7 .8 .7],...
    'Title','HMM Settings:','TitlePosition','lefttop','FontSize',12,'SelectionChangefcn',@est_select);
uicontrol('Style','Edit','String','Transition Matrix:','Position',[15 155 230 30],'BackGroundColor',[.7 .8 .7],...
    'FontSize',10,'Enable','Off')
HMMTR = uicontrol('Style','Edit','String',text_trm,'Position',[15 122.5 230 30],'FontSize',10,...
    'BackGroundColor',[1 1 1]);
uicontrol('Style','Edit','String','Velocity Distribution Estimate:','Position',[15 88.75 175 30],'BackGroundColor',[.7 .8 .7],...
    'FontSize',9,'Enable','Off')
VeloBinBy = uicontrol('Style','Edit','String',text_bins,'Value',val_bins,'Position',[190 88.75 55 30],'FontSize',10,...
    'BackGroundColor',[1 1 1]);
EstOption1 = uicontrol('Style','RadioButton','String','All Trials','Enable','On','Value',1,...
    'Position',[5 5 115 25],'FontSize',10,'Parent',HmmEst,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_est==1,'UserData',1);
EstOption2 = uicontrol('Style','RadioButton','String','Trial-by-trial','Enable','On','Value',0,...
    'Position',[122.5 5 110 25],'FontSize',10,'Parent',HmmEst,'BackGroundColor',[.7 .8 .7],...
    'Value',curr_est==2,'UserData',2);

uicontrol('Style','Pushbutton','String',text_done,'BackgroundColor',[.8 .8 .8],...
    'Parent',FixSacFig,'Position',[10 10 240 35],'FontSize',12,'Callback',@donerefresh)

    function est_select(~,eventdata)
        curr_est = get(eventdata.NewValue,'UserData');
    end

    function donerefresh(~,~)
        val_velo = str2num(get(VeloThresh,'String'));
        val_fixdur = str2num(get(MinFixDur,'String'));
        val_bins = str2num(get(VeloBinBy,'String'));
        val_trm = str2num(strrep(get(HMMTR,'String'), '[];,', ''));
        Settings = [val_velo,val_fixdur,{val_trm},val_bins,curr_est];
        uiresume(FixSacFig)
    end


uiwait(FixSacFig)
try
close(FixSacFig)
end

end