% vis_fixoutcompare

function [hside, hdiff] = vis_fixoutcompare(DIRECT,SUB1,etgf1,mode1,SUB2,etgf2,mode2)

if strcmp(DIRECT(end), '\')
    DIRECT = DIRECT(1:end-1);
end

sub1data = csvread([DIRECT, '\MATLAB\INPUT\GRAFIX\', num2str(SUB1), '\fix_', mode1, '_', num2str(SUB1), '.csv']);
sub2data = csvread([DIRECT, '\MATLAB\INPUT\GRAFIX\', num2str(SUB2), '\fix_', mode2, '_', num2str(SUB2), '.csv']);

[N1,X1] = hist(sub1data(:,3)*1000,[0:100:4000]);
[N2,X2] = hist(sub2data(:,3)*1000,[0:100:4000]);

hside = figure('Name', 'Subject 1 and Subject 2', 'numbertitle', 'off');

dat1hand = bar(X1,N1,.5,'r'); hold on
dat2hand = bar(X2+50,N2,.5,'g'); 
set(gca,'xlim',[0 4000])

% set(dat1hand, 'barwidth', .5, 'facecolor', [1 0 0]);
% set(dat2hand, 'barwidth', .5, 'facecolor', [0 1 0]);

legend(['SUB ' num2str(SUB1), ' ', mode1],['SUB ' num2str(SUB2), ' ', mode2])







