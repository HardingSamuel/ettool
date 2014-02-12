close all
clear all
screensize = get(0, 'screensize');

fig = figure('Position', [38 509 560 420], 'Name', 'Eyetracking Tool v0.1', 'NumberTitle', 'off', 'MenuBar', 'none', 'Color', [.1 .5 .1]);
subslist = [];
customfileexe = [];


Title = uicontrol('Style', 'text', 'Position', [25 380 510 25], 'String', 'Eyetracking Toolkit', ...
    'BackgroundColor', [.2 .7 .2], 'FontSize', 16, 'ForegroundColor', [1 1 1]);
%%%%
DirectoryTextUpdate = ['DIRECT = uigetdir; set(DirectoryText, ''String'', DIRECT); '];
DirectoryFrame = uicontrol('Style', 'frame', 'Position', [25 315 510 50], 'BackgroundColor', [.2 .7 .2], 'ForegroundColor', [.2 .5 .2]);

DirectoryButton = uicontrol('Style', 'pushbutton', 'Position', [30 320 150 40], 'String', 'Select Directory', ...
    'BackgroundColor', [.7 .7 .7], 'FontSize', 12, 'ForegroundColor', [.2 .2 .2], 'Callback', DirectoryTextUpdate);

DirectoryText = uicontrol('Style', 'text', 'Position', [185 320 345 40], 'String', 'N/A', 'ForegroundColor', [.2 .2 .2], ...
    'BackgroundColor', [.9 .9 .9], 'FontSize', 10);
%%%%
DirSubDiv = uicontrol('Style', 'frame', 'Position', [5 300 550 2], 'ForegroundColor', [.9 .9 .9]);
%%%%

SubFrame = uicontrol('Style', 'frame', 'Position', [25 235 510 50], 'BackgroundColor', [.2 .7 .2], 'ForegroundColor', [.2 .5 .2]);

SubList = uicontrol('Style', 'pushbutton', 'Position', [30 240 150 40], 'String', 'Subjects', ...
    'BackgroundColor', [.7 .7 .7], 'FontSize', 12, 'ForegroundColor', [.2 .2 .2], 'Callback', 'subslist = pop_subselect(DIRECT);');


ColPick = uicontrol('Style', 'pushbutton', 'Position', [202.5 240 150 40], 'String', 'Columns', 'Callback', '[coldata] = pop_colselect(DIRECT, subslist);', 'BackgroundColor', [.7 .7 .7], 'FontSize', 12, 'ForegroundColor', [.2 .2 .2]);


ReadIn = uicontrol('Style', 'pushbutton', 'Position', [375 240 150 40], 'String', 'Read-In', 'Callback', 'pri_init(DIRECT,1,subslist,coldata)', 'BackgroundColor', [.7 .7 .7], 'FontSize', 12, 'ForegroundColor', [.2 .2 .2]);
% 

%%%%
SubProcDiv = uicontrol('Style', 'frame', 'Position', [5 220 550 2], 'ForegroundColor', [.9 .9 .9]);
%%%%

AdditionalAnalysis = uicontrol('Style', 'pushbutton', 'Position', [30 160 150 40], 'String', 'Analyses', 'Callback', '[analyoutput,customfileexe] = pop_analysisselectv2;', 'BackgroundColor', [.7 .7 .7], 'FontSize', 12, 'ForegroundColor', [.2 .2 .2]);
Process = uicontrol('Style', 'pushbutton', 'Position', [202.5 160 150 40], 'String', 'Process', 'Callback', 'pri_init(DIRECT,2,subslist,analyoutput,customfileexe)', 'BackgroundColor', [.7 .7 .7], 'FontSize', 12, 'ForegroundColor', [.2 .2 .2]);


Summarize = uicontrol('Style', 'pushbutton', 'Position', [30 80 150 40], 'String', 'Summarize', 'Callback', 'pri_init(DIRECT,3,subslist)', 'BackgroundColor', [.7 .7 .7], 'FontSize', 12, 'ForegroundColor', [.2 .2 .2]);
        
    