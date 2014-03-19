function [aoimat] = AOI_definelocations(CurrentDir)
%%  AOI_Display 2
%for evaluating the locations of AOIs in dynamic images
%
%   Version Log:
%     V1.0 - Sam Harding
%       :creation and design - used for VideoPilot (Ty
%       W. Boyer)
%     V1.1 - SH (10/3/13)
%       :editing to fit into new folder oganization, vectorized
%     V1.2 - SH (TBD)
%       :generalization for generic study design
%   [SH] - 12/13/13:  normalized x and y coords



%Directory of AOI File

SSname = [CurrentDir, '\EXCEL\AOI Coding.xlsx'];

VersionNumber = 1.3;

% To reimplement operation mode in 1.2
% % % %
% % % % %   Allow users to call this function from other scripts, passing 'opmode'
% % % % %   along.
% % % % if nargin < 1
% % % % %   Does the user want to only display the outputs for rough estimation of
% % % % %   values (fastest), only save (slower), or display and save simultaneously
% % % % %   (slowest)?
% % % %     opmode = input(['(D)isplay, (s)ave, or (g)enerate .mat? [d,s,g]' '\n'], 's');
% % % % else
% % % %     opmode = varargin{1};
% % % % end



% %
%%  User Input -CURRENTLY OUT OF DATE
%   Set these values before running!
% % % %
% % % % %name of the AOI file
% % % %  = 'Z:\Current_Studies\Video Pilot\AOI Materials\AOI Coding\AOI Coding.xlsx';
% % % %
% % % % %DIRECTORIES:
% % % % %location of coded images (this folder should contain separate subfolders
% % % % %for each independent video clip
% % % % IMLOC = 'Z:\Current_Studies\Video Pilot\AOI Materials\AOI Sequences\';
% % % % %directory where files will be saved
% % % % OUT = 'Z:\Current_Studies\Video Pilot\AOI Materials\AOI Coding\AOI Visualizations\';
% % % %
% % % % %for titling purposes, names of the videos
% % % % aois(1).name = 'Cow Sequence\';
% % % % aois(2).name = 'Duck Sequence\';
% % % % aois(3).name = 'Puppet Sequence\';
%%

%coding ratio:  ImageCodeAssist.jar forces resize down to max. 800 pixels
%width.  Values assigned during coding are thus relative to this maximum
%value.  If you stimulus is > 800 px. in width, you need to rescale the
%coded values (based around max 800) to be relative to the true width of
%your image.  This has been fixed in a more recent version of
%ImageCodeAssist; if you use this version, set cr = 1.  Otherwise,
%cr = Width(realimage) / 800.  All values will be multiplied by this ratio.
crx = 1/800;
cry = 1/600;

%open a text file to output errors generated during aoi visualization for
%correction.  This will be generated in the same directory as this script
%unless otherwise defined.
fid = fopen([CurrentDir, '\MATLAB\OUTPUT\VISUALIZATIONS\AOIS\aoi_vis_errors.txt'], 'wt');

%colors of aois 1:10
color = [{'r', 'b', 'g', 'y', 'm', 'c', 'w', 'k'}, [1 .4 .6], [.75 .75 .75]];

%determine # of worksheets.  The format of 'AOI Coding.xls' assumes each
%worksheet is a different stimulus
e = actxserver ('Excel.Application');
efile = e.Workbooks.Open(SSname);
wsc = efile.Worksheets.Count;
efile.Close;

IMLOC = [CurrentDir, '\EPRIME\STIMS\'];

if exist([CurrentDir, '\MATLAB\OUTPUT\DATA\AOIS\aoi_locations.mat'], 'file') ~= 2
    disp('Generating New AOI File')
    for groupi = 1:wsc
        groups = input(['Group AOIs ' num2str(groupi) '\n' 'Format:  [a,b,c]; [d,e,f]' '\n'], 's');
        if ~strcmp(groups, '[]')
            lb = strfind(groups, '[');
            rb = strfind(groups, ']');
            g1 = zeros(length(lb),10);
            for torow = 1:length(lb)
                g1(torow, 1:length(str2num(groups(lb(torow):rb(torow))))) = str2num(groups(lb(torow):rb(torow)));
            end
        else
            g1 = [];
        end
        aoisfinal(groupi).group = g1;
    end
else
    %     keyboard
    %     disp('Loading AOI Locations')
    load([CurrentDir, '\MATLAB\OUTPUT\DATA\AOIS\aoi_locations.mat'])
    
    if aoimat.version ~= VersionNumber
        for groupi = 1:wsc
            groups = input(['Group AOIs ' num2str(groupi) '\n' 'Format:  [a,b,c]; [d,e,f]' '\n'], 's');
            if ~strcmp(groups, '[]')
                lb = strfind(groups, '[');
                rb = strfind(groups, ']');
                g1 = zeros(length(lb),10);
                for torow = 1:length(lb)
                    g1(torow, 1:length(str2num(groups(lb(torow):rb(torow))))) = str2num(groups(lb(torow):rb(torow)));
                end
            else
                g1 = [];
            end
            aoisfinal(groupi).group = g1;
        end
    else
        return
    end
end

% disp('this is the correct version')

% % % % if nargin < 1
% % % %     for groupi = 1:wsc
% % % %         groups = input(['Group AOIs for video ' num2str(groupi) '\n' 'Format:  [a,b,c]; [d,e,f]' '\n'], 's');
% % % %         if ~strcmp(groups, '[]')
% % % %             lb = strfind(groups, '[');
% % % %             rb = strfind(groups, ']');
% % % %             g1 = zeros(length(lb),10);
% % % %             for torow = 1:length(lb)
% % % %             g1(torow, 1:length(str2num(groups(lb(torow):rb(torow))))) = str2num(groups(lb(torow):rb(torow)));
% % % %             end
% % % %             aoisfinal(groupi).group = g1;
% % % %         else
% % % %             aoisfinal(groupi).group = [];
% % % %         end
% % % %     end
% % % % else
% % % %     groupme = varargin{2};
% % % %     disp('Adding groups to videofinal')
% % % %     for groupi = 1:length(groupme)
% % % %         aoisfinal(groupi).group = groupme(groupi).group;
% % % %     end
% % % % end
% % %
% % %
% % % % load vid_stats
%

%%  Find Values
%   Get Values from Excel spreadsheet and place them into structure.
% keyboard
for nvid = 1:wsc
    
    % load the worksheet from the aoi data file
    [num, str, raw] = xlsread(SSname, nvid);
    blnk = size(raw, 1) - size(num, 1) - 1;
    
    %for every aoi
    for naoi = 1:(size(raw, 2)-1)/4
        aois(nvid).aoi(naoi).name = raw{1, 2+4*(naoi-1)}(1:strfind(raw{1, 2+4*(naoi-1)}, '_')-1);
        aoisfinal(nvid).aoi(naoi).name = strrep(aois(nvid).aoi(naoi).name, '\', '');
        
        %for every picture
        for npic = 2:size(num, 1)
            
            aois(nvid).aoi(naoi).UL.X(npic + blnk) = num(npic, 1+4*(naoi-1)) * crx;
            aois(nvid).aoi(naoi).UL.Y(npic + blnk) = num(npic, 2+4*(naoi-1)) * cry;
            aois(nvid).aoi(naoi).LR.X(npic + blnk) = num(npic, 3+4*(naoi-1)) * crx;
            aois(nvid).aoi(naoi).LR.Y(npic + blnk) = num(npic, 4+4*(naoi-1)) * cry;
            
            aois(nvid).aoi(naoi).picname(npic) = cellstr(strcat([IMLOC, raw{npic, 1}]));
            aoisfinal(nvid).aoi(naoi).picname(npic) = cellstr(strcat([IMLOC, raw{npic, 1}]));
        end
        
        %if there are blanks, fill in the rest of the picture names
        for npicblnk = size(num, 1) + 1:size(raw, 1)
            aois(nvid).aoi(naoi).picname(npicblnk) = cellstr(strcat([IMLOC, raw{npicblnk, 1}]));
            aoisfinal(nvid).aoi(naoi).picname(npicblnk) = cellstr(strcat([IMLOC, raw{npicblnk, 1}]));
        end
        
    end
end



%%  Filter
%   Low-pass filter for AOIs to remove high-frequency jitter

for fil_nvid = 1:wsc
    
    %     aoisfinal(fil_nvid).time = linspace(0, aois(fil_nvid).Duration, length(aois(fil_nvid).aoi(1).UL.X));
    
    for fil_naoi = 1:size(aois(fil_nvid).aoi, 2)
        %         Filter UL.X
        aoisfilt(fil_nvid).aoi(fil_naoi).UL.X = aois(fil_nvid).aoi(fil_naoi).UL.X(find(~isnan(aois(fil_nvid).aoi(fil_naoi).UL.X)));
        aoisfilt(fil_nvid).aoi(fil_naoi).UL.X(1:find(aoisfilt(fil_nvid).aoi(fil_naoi).UL.X~=0, 1)) = aoisfilt(fil_nvid).aoi(fil_naoi).UL.X(find(aoisfilt(fil_nvid).aoi(fil_naoi).UL.X~=0, 1));
        aoisfilt(fil_nvid).aoi(fil_naoi).UL.X = filtfilt(fir1(10,[0.1]), 1, aoisfilt(fil_nvid).aoi(fil_naoi).UL.X);
        %         Filter UL.Y
        aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y = aois(fil_nvid).aoi(fil_naoi).UL.Y(find(~isnan(aois(fil_nvid).aoi(fil_naoi).UL.Y)));
        aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y(1:find(aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y~=0, 1)) = aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y(find(aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y~=0, 1));
        aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y = filtfilt(fir1(10,[0.1]), 1, aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y);
        %         Filter LR.X
        aoisfilt(fil_nvid).aoi(fil_naoi).LR.X = aois(fil_nvid).aoi(fil_naoi).LR.X(find(~isnan(aois(fil_nvid).aoi(fil_naoi).LR.X)));
        aoisfilt(fil_nvid).aoi(fil_naoi).LR.X(1:find(aoisfilt(fil_nvid).aoi(fil_naoi).LR.X~=0, 1)) = aoisfilt(fil_nvid).aoi(fil_naoi).LR.X(find(aoisfilt(fil_nvid).aoi(fil_naoi).LR.X~=0, 1));
        aoisfilt(fil_nvid).aoi(fil_naoi).LR.X = filtfilt(fir1(10,[0.1]), 1, aoisfilt(fil_nvid).aoi(fil_naoi).LR.X);
        %         Filter LR.Y
        aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y = aois(fil_nvid).aoi(fil_naoi).LR.Y(find(~isnan(aois(fil_nvid).aoi(fil_naoi).LR.Y)));
        aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y(1:find(aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y~=0, 1)) = aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y(find(aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y~=0, 1));
        aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y = filtfilt(fir1(10,[0.1]), 1, aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y);
        
        
        
        
        %         Combine Filtered and NaNs
        % UL.X
        aoisfinal(fil_nvid).aoi(fil_naoi).UL.X = zeros(1,length(find(isnan(aois(fil_nvid).aoi(fil_naoi).UL.X)))+length(aoisfilt(fil_nvid).aoi(fil_naoi).UL.X));
        Bi = find(isnan(aois(fil_nvid).aoi(fil_naoi).UL.X));
        aoisfinal(fil_nvid).aoi(fil_naoi).UL.X(Bi) = NaN;
        aoisfinal(fil_nvid).aoi(fil_naoi).UL.X(~isnan(aoisfinal(fil_nvid).aoi(fil_naoi).UL.X)) = aoisfilt(fil_nvid).aoi(fil_naoi).UL.X;
        %         UL.Y
        aoisfinal(fil_nvid).aoi(fil_naoi).UL.Y = zeros(1,length(find(isnan(aois(fil_nvid).aoi(fil_naoi).UL.Y)))+length(aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y));
        Bi = find(isnan(aois(fil_nvid).aoi(fil_naoi).UL.Y));
        aoisfinal(fil_nvid).aoi(fil_naoi).UL.Y(Bi) = NaN;
        aoisfinal(fil_nvid).aoi(fil_naoi).UL.Y(~isnan(aoisfinal(fil_nvid).aoi(fil_naoi).UL.Y)) = aoisfilt(fil_nvid).aoi(fil_naoi).UL.Y;
        %         LR.X
        aoisfinal(fil_nvid).aoi(fil_naoi).LR.X = zeros(1,length(find(isnan(aois(fil_nvid).aoi(fil_naoi).LR.X)))+length(aoisfilt(fil_nvid).aoi(fil_naoi).LR.X));
        Bi = find(isnan(aois(fil_nvid).aoi(fil_naoi).LR.X));
        aoisfinal(fil_nvid).aoi(fil_naoi).LR.X(Bi) = NaN;
        aoisfinal(fil_nvid).aoi(fil_naoi).LR.X(~isnan(aoisfinal(fil_nvid).aoi(fil_naoi).LR.X)) = aoisfilt(fil_nvid).aoi(fil_naoi).LR.X;
        %         LR.Y
        aoisfinal(fil_nvid).aoi(fil_naoi).LR.Y = zeros(1,length(find(isnan(aois(fil_nvid).aoi(fil_naoi).LR.Y)))+length(aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y));
        Bi = find(isnan(aois(fil_nvid).aoi(fil_naoi).LR.Y));
        aoisfinal(fil_nvid).aoi(fil_naoi).LR.Y(Bi) = NaN;
        aoisfinal(fil_nvid).aoi(fil_naoi).LR.Y(~isnan(aoisfinal(fil_nvid).aoi(fil_naoi).LR.Y)) = aoisfilt(fil_nvid).aoi(fil_naoi).LR.Y;
    end
end


%%  Display and/or Save
%   We defined each AOI separately above for each frame.  Now we want to show, on every frame, all the AOIs at the same time.
%   This means we have to loop in a different order.

%% TO CREATE VISUAL OUTPUT
% % % % % switch opmode
% % % % %     case {'s', 'd'}
% % % %
% % % % %for every video
% % % %  for disp_nvid = 1:wsc
% % % %      %make a new figure
% % % %      eval(['fig', num2str(disp_nvid)]) = figure;
% % % %      %set UL to (0,0)
% % % %      axis ij
% % % %
% % % %      %for every frame
% % % %      for disp_npic = 2:size(aoisfinal(disp_nvid).aoi(1).UL.X, 2)
% % % %
% % % %          %remove any boxes / image information from the previous frame,
% % % %          %load and draw the appropriate picture, add a title, begin holding
% % % %          %all AOI information
% % % %          hold off
% % % %
% % % %          pic = imread(aois(disp_nvid).aoi(1).picname{disp_npic});
% % % %          image(pic)
% % % %          title([aois(disp_nvid).name(1:end-1), ':  ', num2str(disp_npic)])
% % % %          hold on
% % % %
% % % %          %for every aoi (as defined above)
% % % %          for disp_naoi = 1:size(aoisfinal(disp_nvid).aoi, 2)
% % % %
% % % %              %set up the location of the rectangle to be drawn, check to make sure the rectangle has positive, non-zero dimensions; if not, temporarily use a filler value in order to continue displaying properly, write information about that frame to text file
% % % %              rect = [aoisfinal(disp_nvid).aoi(disp_naoi).UL.X(disp_npic), aoisfinal(disp_nvid).aoi(disp_naoi).UL.Y(disp_npic), aoisfinal(disp_nvid).aoi(disp_naoi).LR.X(disp_npic) - aoisfinal(disp_nvid).aoi(disp_naoi).UL.X(disp_npic), aoisfinal(disp_nvid).aoi(disp_naoi).LR.Y(disp_npic) - aoisfinal(disp_nvid).aoi(disp_naoi).UL.Y(disp_npic)];
% % % %
% % % %              if any(rect == 0)
% % % %                  rect(find(rect == 0)) = 1;
% % % %                  fprintf(fid, ['Video:  ', num2str(disp_nvid), '  Picture:  ', num2str(disp_npic), '  AOI:  ', num2str(disp_naoi), '  0-Value']);
% % % %                  fprintf(fid, '\n');
% % % %              end
% % % %              if any(rect < 0)
% % % %                  while any(rect <0)
% % % %                      rect(find(rect < 0)) = abs(rect(find(rect < 0)));
% % % %                      fprintf(fid, ['Video:  ', num2str(disp_nvid), '  Picture:  ', num2str(disp_npic), '  AOI:  ', num2str(disp_naoi), '  Negative-Value']);
% % % %                      fprintf(fid, '\n');
% % % %                  end
% % % %              end
% % % %
% % % %              if ~any(isnan(rect))
% % % %                  rectangle('Position', rect, 'EdgeColor', color{disp_naoi}, 'LineWidth', 3)
% % % %              end
% % % %
% % % %          end
% % % %          %after all aois have been made, execute functions defined by user
% % % %          %input 'mode'
% % % %          if opmode == 'd'
% % % %              drawnow
% % % %          elseif opmode == 's'
% % % %              figh = figure(disp_nvid);
% % % %              saveas(figh, [OUT, aois(disp_nvid).name, num2str(disp_npic) '.jpg']);
% % % %          elseif opmode == 'b'
% % % %              drawnow
% % % %              figh = figure(disp_nvid);
% % % %              saveas(figh, [OUT, aois(disp_nvid).name, num2str(disp_npic) '.jpg']);
% % % %          end
% % % %      end
% % % %  end

% % % %     case 'g'

%% Rearrange
% keyboard
xy_corn_names = [{'UL.X'}, {'UL.Y'}, {'LR.X'}, {'LR.Y'}];
edgebuff = .1;
for stim_types = 1:length(aoisfinal)
    for aoi_num = 1:length(aoisfinal(stim_types).aoi)
        for xy = 1:4
            xyname = char(xy_corn_names(xy));
            for frame = 1:length(aoisfinal(stim_types).aoi(aoi_num).UL.X)
                aoi_box(xy,frame,aoi_num,stim_types) = aoisfinal(stim_types).aoi(aoi_num).(xyname(1:2)).(xyname(4))(frame);
            end
        end
        aoi_box_sizes = [aoi_box(3,:,aoi_num,stim_types) - aoi_box(1,:,aoi_num,stim_types); ...
            aoi_box(4,:,aoi_num,stim_types) - aoi_box(2,:,aoi_num,stim_types)];                
        aoi_adjustedbox(1,:,aoi_num,stim_types) = aoi_box(1,:,aoi_num,stim_types) - (.5 * edgebuff * aoi_box_sizes(1,:));
        aoi_adjustedbox(3,:,aoi_num,stim_types) = aoi_box(3,:,aoi_num,stim_types) + (.5 * edgebuff * aoi_box_sizes(1,:));
        aoi_adjustedbox(2,:,aoi_num,stim_types) = aoi_box(2,:,aoi_num,stim_types) - (.5 * edgebuff * aoi_box_sizes(2,:));
        aoi_adjustedbox(4,:,aoi_num,stim_types) = aoi_box(4,:,aoi_num,stim_types) + (.5 * edgebuff * aoi_box_sizes(2,:));
    end
end

%% Save
aoimat.version = VersionNumber;
aoimat.data = aoi_box;
aoimat.adjusteddata  = aoi_adjustedbox;
disp('MAT file saved to MATLAB\OUT\AOIS\DATA\')
DataFileLocation = [CurrentDir, '\MATLAB\OUTPUT\DATA\AOIS\aoi_locations.mat'];
save(DataFileLocation, 'aoimat')

% % % % end

return

