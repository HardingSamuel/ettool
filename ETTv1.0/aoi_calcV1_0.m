function [proportions,goodprops,buffproportions,buffgoodprops] = aoi_calcV1_0(x,y,t,wo,stimcode,aoimat,sr,vfr)

%%  AOI_Calc
%   Calculate the percentage of gaze points that land within various
%   (groups of) aois.  Pass this script a .mat file with AOI coordinates
%   over time and the gaze data.  If grouping is intended, include within
%   .mat a .group level listing indices of aois to be considered the same.
%
%   Option to include display / movie generation of gaze overlaying aoi
%   images.  --ToBeAdded--


%   [SH] - 12/12/13:  Generalized for ETTool


VersionNumber = 1.0;

%   Colors for displaying gaze & aois
color = [{'r', 'b', 'g', 'y', 'm', 'c', 'w', 'k'}, [1 .4 .6], [.75 .75 .75]];

%   How much to expand the AOIs to include errant edge points?
edgebuff = .1;

% normalize x
x = x / 1920;
% normalize y
y = y / 1080;
t = t - t(1);

fvec = [1:size(aoimat.data(:,:,:,stimcode),2)]*(1000/vfr);
fvec = fvec- fvec(1);

tfvec = cell2mat(arrayfun(@(x) find(x >= fvec, 1, 'last'), t, 'uni', 0));

aoimat.data(find(aoimat.data==0)) = NaN;
aoimat.adjusteddata(find(aoimat.adjusteddata==0)) = NaN;

% AOIMAT(1) = XY; 
% AOIMAT(2) = FRAME;
% AOIMAT(3) = AOIS;
% AOIMAT(4) = VIDEOTYPE;

% calculate logicals for in_aoi?
xlog = (repmat(x, [1 1 size(aoimat.data, 3)]) >= aoimat.data(1,tfvec,:,stimcode)) & (repmat(x, [1 1 size(aoimat.data, 3)]) <= aoimat.data(3,tfvec,:,stimcode));
ylog = (repmat(y, [1 1 size(aoimat.data, 3)]) >= aoimat.data(2,tfvec,:,stimcode)) & (repmat(y, [1 1 size(aoimat.data, 3)]) <= aoimat.data(4,tfvec,:,stimcode));

xlogbuff = (repmat(x, [1 1 size(aoimat.adjusteddata, 3)]) >= aoimat.adjusteddata(1,tfvec,:,stimcode)) & (repmat(x, [1 1 size(aoimat.adjusteddata, 3)]) <= aoimat.adjusteddata(3,tfvec,:,stimcode));
ylogbuff = (repmat(y, [1 1 size(aoimat.adjusteddata, 3)]) >= aoimat.adjusteddata(2,tfvec,:,stimcode)) & (repmat(y, [1 1 size(aoimat.adjusteddata, 3)]) <= aoimat.adjusteddata(4,tfvec,:,stimcode));

goodxlog = xlog(:,~isnan(x),:); goodylog = ylog(:,~isnan(y),:);
goodxlogbuff = xlogbuff(:,~isnan(x),:); goodylogbuff = ylogbuff(:,~isnan(y),:);

proportions = squeeze(mean((xlog & ylog), 2));
buffproportions = squeeze(mean((xlogbuff & ylogbuff), 2));

goodprops = squeeze(mean((goodxlog & goodylog),2));
buffgoodprops = squeeze(mean((goodxlogbuff & goodylogbuff),2));

% keyboard

%% 
% %%%%%%This loop allows visualization; disabled for faster, vectorized
% %%%%%%operations for now.

% fig = figure;
% gg = 1;
% for t = 1:length(xvec)
%    
%     % What was the last frame to be displayed when this gazepoint was
%     % gathered?  Used to compare x & y from gaze with aoi positions in
%     % videofinal as an (i)ndex of videofinal.
%     
%     i = find(tvec(t) >= fvec, 1, 'last');  
%     
%     
%     % The below, commented code allows visualization of gaze overlaid on
%     % the AOIs.  Also uncomment sections labeled ********** below
%     
% %     **********
% %     if i > 1
% %         pic = imread(aoimat.data(stimcode).aoi(1).picname{i});
% %         image(pic)        
% %     end
% %     hold on
% %     **********
% %     
%     for naoi_cal = 1:length(aoimat.data(stimcode).aoi)
%         
%         rect = [aoimat.data(stimcode).aoi(naoi_cal).UL.X(i), aoimat.data(stimcode).aoi(naoi_cal).UL.Y(i), aoimat.data(stimcode).aoi(naoi_cal).LR.X(i), aoimat.data(stimcode).aoi(naoi_cal).LR.Y(i)];  % [UL.X, UL.Y, LR.X, LR.Y];
%         rect_resize = [rect(1)-edgebuff*(rect(3) - rect(1)), rect(2)-edgebuff*(rect(4)-rect(2)), rect(3)+edgebuff*(rect(3) - rect(1)), rect(4)+edgebuff*(rect(4)-rect(2))]; % [UL.X, ULY., LR.X, LR.Y];
%        
%         
%         % **********
% %         rect_draw = [rect_resize(1), rect_resize(2), rect_resize(3) - rect_resize(1), rect_resize(4)-rect_resize(2)]; % [UL.X, UL.Y, W, H];
% %         if ~any(isnan(rect))
% %              rectangle('Position', rect_draw, 'EdgeColor', color{naoi_cal}, 'LineWidth', 3)
% %         end
%         % **********
%         
%         if (xvec(t) >= rect_resize(1) && yvec(t) >= rect_resize(2)) && (xvec(t) <= rect_resize(3) && yvec(t) <= rect_resize(4))
%             aoi_props(naoi_cal).bin(t) = 1;
%         end
%     end
%     
%     
% %     **********
% %     axis ij
% %     axis([0 1280 0 960])
% %      plot(x(t), y(t), 'ro')   
% %     vidout(gg) = getframe;
% %     gg = gg + 1;
% %     
% %     drawnow    
% %     clf
% %     **********
%     
% end

% close(fig)

% Write the arrays into procdata with name, proportion, and count
% %%
% for add_names = 1:length(inboxes)
%     inboxes(add_names).Name = cellstr(aoimat.data(stimcode).aoi(add_names).name);
% end
% 
% 
% procdata.sub(subn).video(v).repit(r).aoiprops(1, end+1) = cellstr('NaNs');
% procdata.sub(subn).video(v).repit(r).aoiprops(2, end) = num2cell(length(find(isnan(x)))/length(x));
% procdata.sub(subn).video(v).repit(r).aoiprops(3, end) = num2cell(length(find(isnan(x))));
% 
% name = '';
% 
% % If any groups were set up by the user, perform 'or' operations to see
% % what percentage of time they were in either AOI.  You cannot simply add
% % the proportions in the event that the aois in questions ever overlap and
% % the gaze point fell into both - this would be an overestimation.
% 
% procdata.sub(subn).video(v).repit(r).groupprops = [];
% 
% if ~isempty(aoimat.data(stimcode).group )
%     procdata.sub(subn).video(v).repit(r).groupprops = cell(3,size(aoimat.data(stimcode).group,1));
%     for g = 1:size(aoimat.data(stimcode).group, 1)
%         
%         name = '';
%         
%         a = aoimat.data(stimcode).group(g, 1:find(aoimat.data(stimcode).group(g,:) == 0, 1)-1);
%         
%         
%         www = vertcat(inboxes(a).prop);
%         aprop = (length(find(nansum(www)>=1))/length(www));
%         
%         
%         for aa = aoimat.data(stimcode).group(g, 1:find(aoimat.data(stimcode).group(g,:) == 0, 1)-1)
%             name = strcat([' ', char(name), char(procdata.sub(subn).video(v).repit(r).aoiprops(1,aa)), ' & ']);
%         end
%         
%         
%         % Clean up the name a bit
%         name = strrep(name, '&', '& ');
%         name = name(3:end-3);
%         
%         procdata.sub(subn).video(v).repit(r).groupprops(1,g) = cellstr(name);
%         procdata.sub(subn).video(v).repit(r).groupprops(2,g) = num2cell(aprop);
%         procdata.sub(subn).video(v).repit(r).groupprops(3,g) = num2cell(length(find(nansum(www)>=1)));
%         
%     end
% end
%     
% 
%     

    
    
