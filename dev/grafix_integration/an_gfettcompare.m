%an_gfettcompare

% Use to compare the outputs of various stages of the Grafix data output
% with the ettool output

grafix_auto = csvread('Z:\Current_Studies\Manuela\Faces & EyeGaze\MATLAB\INPUT\GRAFIX\1\fix_auto_1.csv');
grafix_autoPH = csvread('Z:\Current_Studies\Manuela\Faces & EyeGaze\MATLAB\INPUT\GRAFIX\1\fix_all_1.csv');
cla = zeros(0,3);

subn = 1;
for trinum = 1:length(procdata.sub(subn).Trial);
    if ~isempty(procdata.sub(subn).Trial(trinum).Classifications.fixations)
        cla = cat(1,cla, [procdata.sub(subn).Trial(trinum).Classifications.fixations.onsets(1,:)',...
            procdata.sub(subn).Trial(trinum).Classifications.fixations.offsets(1,:)',...
            procdata.sub(subn).Trial(trinum).Classifications.fixations.durations(2,:)']);
    end
end

%% compare auto to auto

if ~exist('autoauto','var')
    autoauto = figure('name', 'Automated Processes Only');
else
    clf
end

figure(autoauto);
subplot(121)
hist(grafix_auto(:,3)*1000,[0:50:4000])
hold on; title('Grafix Automatic Processing')
xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000])
text(2500,18000,['Total: ' num2str(size(grafix_auto,1))])
text(2500,17250,['Mean Dur: ' num2str(mean(grafix_auto(:,3)*1000,1))])

subplot(122)
hist(cla(:,3),[0:50:4000])
hold on; title('ETTool Automatic Processing')
xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000],'ylim',[0 1200])
text(2500,1100,['Total: ' num2str(size(cla,1))])
text(2500,1000,['Mean Dur: ' num2str(mean(cla(:,3),1))])

%% compare auto+PH to auto

if ~exist('autoPHauto','var')
    autoPHauto = figure('name', 'Automated Processes Only');
else
    clf
end

figure(autoauto);
subplot(121)
hist(grafix_autoPH(:,3)*1000,[0:50:4000])
hold on; title('Grafix Automatic Processing + PostHoc')
xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000])
text(2500,1100,['Total: ' num2str(size(grafix_autoPH,1))])
text(2500,1000,['Mean Dur: ' num2str(mean(grafix_autoPH(:,3)*1000,1))])

subplot(122)
hist(cla(:,3),[0:50:4000])
hold on; title('ETTool Automatic Processing')
xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000],'ylim',[0 1200])
text(2500,1100,['Total: ' num2str(size(cla,1))])
text(2500,1000,['Mean Dur: ' num2str(mean(cla(:,3),1))])

%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% AT
% %an_gfettcompare
% 
% % Use to compare the outputs of various stages of the Grafix data output
% % with the ettool output
% load('Z:\Current_Studies\ActionTracking\MATLAB\INPUT\PROCDATA\2014-23-Apr_13-38_ActionTracking_PROCDATA.mat');
% grafix_auto = csvread('Z:\Current_Studies\ActionTracking\MATLAB\INPUT\GRAFIX\1\hold_fix_auto_1.csv');
% grafix_autoPH = csvread('Z:\Current_Studies\ActionTracking\MATLAB\INPUT\GRAFIX\1\hold_fix_all_1.csv');
% cla = zeros(0,3);
% 
% subn = 1;
% for trinum = 1:length(procdata.sub(subn).Trial);
%     if ~isempty(procdata.sub(subn).Trial(trinum).Classifications.fixations)
%         cla = cat(1,cla, [procdata.sub(subn).Trial(trinum).Classifications.fixations.onsets(1,:)',...
%             procdata.sub(subn).Trial(trinum).Classifications.fixations.offsets(1,:)',...
%             procdata.sub(subn).Trial(trinum).Classifications.fixations.durations(2,:)']);
%     end
% end
% 
% %% compare auto to auto
% 
% if ~exist('autoauto','var')
%     autoauto = figure('name', 'Automated Processes Only');
% else
%     figure(autoauto);
%     clf
% end
% 
% 
% subplot(121)
% hist(grafix_auto(:,3)*1000,[0:50:4000])
% hold on; title('Grafix Automatic Processing')
% xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000],'ylim',[0 55])
% text(2500,50,['Total: ' num2str(size(grafix_auto,1))])
% text(2500,45,['Mean Dur: ' num2str(mean(grafix_auto(:,3)*1000,1))])
% 
% subplot(122)
% hist(cla(:,3),[0:50:4000])
% hold on; title('ETTool Automatic Processing')
% xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000],'ylim',[0 55])
% text(2500,50,['Total: ' num2str(size(cla,1))])
% text(2500,45,['Mean Dur: ' num2str(mean(cla(:,3),1))])
% 
% %% compare auto+PH to auto
% 
% if ~exist('autoPHauto','var')
%     autoPHauto = figure('name', 'Automated Processes Only');
% else
%     figure(autoPHauto);
%     clf
% end
% 
% 
% subplot(121)
% hist(grafix_autoPH(:,3)*1000,[0:50:4000])
% hold on; title('Grafix Automatic Processing + PostHoc')
% xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000],'ylim',[0 55])
% text(2500,50,['Total: ' num2str(size(grafix_autoPH,1))])
% text(2500,45,['Mean Dur: ' num2str(mean(grafix_autoPH(:,3)*1000,1))])
% 
% subplot(122)
% hist(cla(:,3),[0:50:4000])
% hold on; title('ETTool Automatic Processing')
% xlabel('Fixation Duration'); ylabel('Frequencies'); set(gca,'xlim',[0 4000],'ylim',[0 55])
% text(2500,50,['Total: ' num2str(size(cla,1))])
% text(2500,45,['Mean Dur: ' num2str(mean(cla(:,3),1))])