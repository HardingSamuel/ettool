%%  AOI_Calc
%   Calculate the percentage of gaze points that land within various
%   (groups of) aois.  Pass this script a .mat file with AOI coordinates
%   over time and the gaze data.  If grouping is intended, include within
%   .mat a .group level listing indices of aois to be considered the same.
%
%   Option to include display / movie generation of gaze overlaying aoi
%   images.  --ToBeAdded--

%   Colors for displaying gaze & aois
color = [{'r', 'b', 'g', 'y', 'm', 'c', 'w', 'k'}, [1 .4 .6], [.75 .75 .75]];

%   How much to expand the AOIs to include errant edge points?
edgebuff = .1;

%   Inherits values 'x', 'y', 'd', 'V', 'p' from ProcessV1
%   Recale to resolution that AOIs were coded in.

if subn ~= 105
    x = x - 320; y = y - 31;
else
    x = 1280*(x-600)/720; y = 960*(y-300)/480;
end

aoi = [];

for naoi_set = 1:length(videofinal(v).aoi)
    aoi(naoi_set).prop = zeros(1, length(vec.all));
    aoi(naoi_set).prop(find(isnan(x))) = nan;
end

% Convert time relative to start point and into ms to compare gazedata with
% aoi coding displayed

tt =  (procdata.sub(subn).video(v).repit(r).time - procdata.sub(subn).video(v).repit(r).time(1))/1000;
% fig = figure;
% gg = 1;
for t = 1:length(procdata.sub(subn).video(v).repit(r).time)
   
    % What was the last frame to be displayed when this gazepoint was
    % gathered?  Used to compare x & y from gaze with aoi positions in
    % videofinal as an (i)ndex of videofinal.
    
    i = find(tt(t) >= videofinal(v).time, 1, 'last');  
    
    
    % The below, commented code allows visualization of gaze overlaid on
    % the AOIs.  Also uncomment sections labeled ********** below
    
%     **********
%     if i > 1
%         pic = imread(videofinal(v).aoi(1).picname{i});
%         image(pic)        
%     end
%     hold on
%     **********
%     
    for naoi_cal = 1:length(videofinal(v).aoi)
        
        rect = [videofinal(v).aoi(naoi_cal).UL.X(i), videofinal(v).aoi(naoi_cal).UL.Y(i), videofinal(v).aoi(naoi_cal).LR.X(i), videofinal(v).aoi(naoi_cal).LR.Y(i)];  % [UL.X, UL.Y, LR.X, LR.Y];
        rect_resize = [rect(1)-edgebuff*(rect(3) - rect(1)), rect(2)-edgebuff*(rect(4)-rect(2)), rect(3)+edgebuff*(rect(3) - rect(1)), rect(4)+edgebuff*(rect(4)-rect(2))]; % [UL.X, ULY., LR.X, LR.Y];
        rect_draw = [rect_resize(1), rect_resize(2), rect_resize(3) - rect_resize(1), rect_resize(4)-rect_resize(2)]; % [UL.X, UL.Y, W, H];
        
        
        % **********
%         if ~any(isnan(rect))
%              rectangle('Position', rect_draw, 'EdgeColor', color{naoi_cal}, 'LineWidth', 3)
%         end
        % **********
        
        if (x(t) >= rect_resize(1) && y(t) >= rect_resize(2)) && (x(t) <= rect_resize(3) && y(t) <= rect_resize(4))
            aoi(naoi_cal).prop(t) = 1;
        end
    end
    
    
%     **********
%     axis ij
%     axis([0 1280 0 960])
%      plot(x(t), y(t), 'ro')   
%     vidout(gg) = getframe;
%     gg = gg + 1;
%     
%     drawnow    
%     clf
%     **********
    
end

% close(fig)

% Write the arrays into procdata with name, proportion, and count

for procin = 1:length(aoi)
    procdata.sub(subn).video(v).repit(r).aoiprops(1,procin) = cellstr(videofinal(v).aoi(procin).name);
    procdata.sub(subn).video(v).repit(r).aoiprops(2,procin) = num2cell(nanmean(aoi(procin).prop));    
    procdata.sub(subn).video(v).repit(r).aoiprops(3,procin) = num2cell(length(find(aoi(procin).prop==1)));  
end

procdata.sub(subn).video(v).repit(r).aoiprops(1, end+1) = cellstr('NaNs');
procdata.sub(subn).video(v).repit(r).aoiprops(2, end) = num2cell(length(find(isnan(x)))/length(x));
procdata.sub(subn).video(v).repit(r).aoiprops(3, end) = num2cell(length(find(isnan(x))));

name = '';

% If any groups were set up by the user, perform 'or' operations to see
% what percentage of time they were in either AOI.  You cannot simply add
% the proportions in the event that the aois in questions ever overlap and
% the gaze point fell into both - this would be an overestimation.

procdata.sub(subn).video(v).repit(r).groupprops = [];

if ~isempty(videofinal(v).group )
    procdata.sub(subn).video(v).repit(r).groupprops = cell(3,size(videofinal(v).group,1));
    for g = 1:size(videofinal(v).group, 1)
        
        name = '';
        
        a = videofinal(v).group(g, 1:find(videofinal(v).group(g,:) == 0, 1)-1);
        
        
        www = vertcat(aoi(a).prop);
        aprop = (length(find(nansum(www)>=1))/length(www));
        
        
        for aa = videofinal(v).group(g, 1:find(videofinal(v).group(g,:) == 0, 1)-1)
            name = strcat([' ', char(name), char(procdata.sub(subn).video(v).repit(r).aoiprops(1,aa)), ' & ']);
        end
        
        
        % Clean up the name a bit
        name = strrep(name, '&', '& ');
        name = name(3:end-3);
        
        procdata.sub(subn).video(v).repit(r).groupprops(1,g) = cellstr(name);
        procdata.sub(subn).video(v).repit(r).groupprops(2,g) = num2cell(aprop);
        procdata.sub(subn).video(v).repit(r).groupprops(3,g) = num2cell(length(find(nansum(www)>=1)));
        
    end
end
    

    

    
    
