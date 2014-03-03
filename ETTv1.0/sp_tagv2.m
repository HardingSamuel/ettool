function [sp_index_final] = sp_tagv2(x,y,d,velo,sr,varargin)

%   [SH] - 01/24/14:  several bug fixes, incorparting fix and sac data from
%   caller

%% Smooth Pursuit Tagging
% The main method of pulling out moment of smooth pursuit is to examine the
% slope and fit of a linear regression over a moving time window, for both
% x and y coordinates separately.
% Times during which the linear approximation provides a relatively good
% fit (rthresh), where the mean rate of change exceeds some minimum value
% (mthresh_low to rule out fixations) yet remains under a ceiling value
% (mthresh_high to ignore saccades).
% This process will 'tag' potential SP epochs which the user will be
% prompted to review through UI and edit as necessary.
%


%% Persistents

% persistent data
% persistent backsp
% persistent editsize
% persistent plusb
% persistent minusb
% persistent plusplusb
% persistent minusminusb
% persistent xcirc
% persistent ycirc
% persistent vcirc

% global plusb ;
% global plusplusb;
%
% global minusb;
% global minusminusb;

%% Define Parameters
mthresh_low = 1.5;
mthresh_high = varargin{1};
rthresh = .75;
sp_windowsize = 100;
st = 1000/sr;
pix_to_angle_const = varargin{2};
if length(varargin) >2
    fixinfo = varargin{3};
    sacinfo = varargin{4};
    whatson = varargin{5};
end
% disp('Locating Smooth Pursuit Epochs')
%% Moving Window, calculating slope(*m) and fit(*r) for *=x,y separately
for sp_win = 1:length(x)-sp_windowsize
    if all(~isnan(x(sp_win:sp_win+sp_windowsize-1)))
        [xm(sp_win), xr(sp_win)] = findslope((0:sp_windowsize-1), x(sp_win:sp_win+sp_windowsize-1), 1);
    else
        xm(sp_win) = NaN; xr(sp_win) = NaN;
    end
    if all(~isnan(y(sp_win:sp_win+sp_windowsize-1)))
        [ym(sp_win), yr(sp_win)] = findslope((0:sp_windowsize-1), y(sp_win:sp_win+sp_windowsize-1), 1);
    else
        ym(sp_win) = NaN; yr(sp_win) = NaN;
    end
end

% Moving Window cannot calculate on the end of the epoch because the number
% of points will be less than sp_windowsize.  Make these values NaN
xm(end+1:length(d)) = NaN;
xr(end+1:length(d)) = NaN;
ym(end+1:length(d)) = NaN;
yr(end+1:length(d)) = NaN;

%% Perfom X operations
xm = (atand((xm/2)./(d*pix_to_angle_const))*2)*1000/st; %x slope convert to deg/sec

% initialize arrays
xqual = zeros(1, length(xm));
xnqi = xqual;

% find instances where criteria are met
xqi = find(abs(xm)>=mthresh_low & xr>=rthresh & abs(xm) <= mthresh_high); %met
xnqi(abs(xm)<mthresh_low) = 2; %not met -- slope too low
xnqi(abs(xm)>mthresh_high) = 3; %not met -- slope too high
xnqi(xr<rthresh) = 4; %not met -- poor fit
xq_keep_begin = [];
xq_begin = [];
xq_end = [];
xq_thresh = [];
xq_keep_end = [];
xq_keep_all = [];
%
if ~isempty(xqi)
    xq_begin = [xqi(1), xqi(find(diff(xqi)>1)+1)]; %location of beginning of sp
    xq_end = [xqi(find(diff(xqi)>1)), xqi(end)]; %location of end of sp
    xq_thresh = xq_end - xq_begin + 1 >= floor(sp_windowsize/st); %index of sp beginnings where duration >= threshold
    xq_keep_begin = xq_begin(xq_thresh); %sp_begin when above threshold
    xq_keep_end = xq_end(xq_thresh); %sp_end when above threshold
    xq_keep_all = unique(cell2mat(arrayfun(@(x) xq_keep_begin(x):xq_keep_end(x), [1:length(xq_keep_begin)], 'uni', 0))); %every point from keep_begin:keep_end    
    xqual(xq_keep_all) = 1; %logical criteria met
end


%% Y Operations
% same as X
ym = (atand((ym/2)./(d*pix_to_angle_const))*2)*1000/st; %x distance in (degrees / second)

yqual = zeros(1, length(ym));
ynqi = yqual;

yqi = find(abs(ym)>=mthresh_low & yr>=rthresh & abs(ym) <= mthresh_high);
ynqi(abs(ym)<mthresh_low) = 2;
ynqi(abs(ym)>mthresh_high) = 3;
ynqi(yr<rthresh) = 4;
yq_keep_begin = [];
yq_begin = [];
yq_end = [];
yq_thresh = [];
yq_keep_end = [];
yq_keep_all = [];

if ~isempty(yqi)
    yq_begin = [yqi(1), yqi(find(diff(yqi)>1)+1)];
    yq_end = [yqi(find(diff(yqi)>1)), yqi(end)];
    yq_thresh = yq_end - yq_begin + 1 >= floor(sp_windowsize/st);
    yq_keep_begin = yq_begin(yq_thresh);
    yq_keep_end = yq_end(yq_thresh);
    yq_keep_all = unique(cell2mat(arrayfun(@(y) yq_keep_begin(y):yq_keep_end(y), [1:length(yq_keep_begin)], 'uni', 0)));
    yqual(yq_keep_all) = 1;
end



%% Plotting, Interface
% close all
auditmain = figure('position', [100 500 700 525], 'numbertitle', 'off', 'name', 'Smooth Pursuit Auditing', 'menubar', 'none', 'color', [.7 .7 .7]);
auditmainsize = [700 525 700 525];
datafig = guihandles(auditmain);
data.epochs.x = [xq_keep_begin; xq_keep_end; ones(1, length(xq_keep_begin))]';
data.epochs.y = [yq_keep_begin; yq_keep_end; ones(1, length(yq_keep_begin))*2]';
% Menus

auditmain_menu1 = uimenu('label', '&File', 'parent', auditmain);
auditmain_menu1_1 = uimenu('label', '&Save Changes', 'parent', auditmain_menu1, 'Callback', @SaveAndReturn);
auditmain_menu1_2 = uimenu('label', '&View Phases', 'parent', auditmain_menu1, 'Callback', {@PhaseFig, whatson});

auditmain_menu2 = uimenu('label', '&Make Changes', 'parent', auditmain);
auditmain_menu2_2 = uimenu('label', '&Start Editing', 'parent', auditmain_menu2, 'callback', @BeginEdits);
% auditmain_menu2_3 = uimenu('label', '&Add Saccades and Fixations', 'parent', auditmain_menu2, 'callback', {@AddFixSac, fixinfo, sacinfo});

% Plots
% plot x
xchartpos = [75 300 550 175];
subplot('position', xchartpos ./ auditmainsize)
title('X Position')
hold on
plot(st*(1:length(x)), x, 'b')
plot(st*find(xqual), x(find(xqual)), 'go', 'markersize', 3);
ax = axis;
ax(2) = st*length(x);
axis(ax)
for arfill = 1:length(whatson.Begindices)
    rectangle('pos',[st*whatson.Begindices(arfill), ax(3), 5, ax(4)-ax(3)])
end
xlabel('Time (ms)')
ylabel('Pixel Position')
% plot y
ychartpos = [75 50 550 175];
subplot('position', ychartpos ./ auditmainsize)
title('Y Position')
hold on
plot(st*(1:length(y)), y, 'r')
plot(st*find(yqual), y(find(yqual)), 'yo', 'markersize', 3)
ax = axis;
ax(2) = st*length(y);
axis(ax)
axis ij
xlabel('Time (ms)')
ylabel('Pixel Position')

data.sortdat = [data.epochs.x; data.epochs.y];
[a b]= sort(data.sortdat(:,1));
data.sortdat = data.sortdat(b,:);

if size(data.sortdat,1)==0
    set(auditmain_menu2_2, 'enable', 'off')
end
% keyboard
uiwait


%% Functions



    function BeginEdits(auditmain_menu2_2, eventdata)
        editwin = figure('position', [900 350 700 625], 'numbertitle', 'off', 'name', 'Edit SP Epochs',  'color', [.7 .7 .7], ...
            'menubar', 'none', 'toolbar', 'figure');
        data.editmainsize = [700 525 700 525];
        %      Plots
        data.xychartpos = [75 190 550 315];
        axpix = subplot('position', data.xychartpos ./ data.editmainsize);
        title('X & Y Positions')
        hold on
        plot(st*(1:length(x)), x, 'b')                
        plot(st*(1:length(y)), y, 'r')
        xcirc = plot(st*find(xqual), x(find(xqual)), 'ko', 'markersize', 3);
        ycirc = plot(st*find(yqual), y(find(yqual)), 'ko', 'markersize', 3);
        plot(st*(1:length(x)), x, 'b')
        plot(st*(1:length(y)), y, 'r')
        legend('Pix_X', 'Pix_Y')
        data.ax2 = axis;
        
        
        data.veloplotpos = [75, 90, 550, 75];
        axvelo = subplot('position', data.veloplotpos./data.editmainsize);
        plot(st*(1:length(x)), velo, 'k');
        hold on
        vcirc = plot(st*find(xqual), velo(find(xqual)), 'ko', 'markersize', 3);
        plot(st*(1:length(x)), velo, 'k');
        data.ax3 = axis;
        data.ax3(3) = 0; data.ax3(4) = mthresh_high;
        linkaxes([axpix, axvelo], 'x')
        
        % create some buttons and menus
        backsp = uicontrol('style', 'pushbutton', 'string', 'Previous', 'callback', @time_back, 'enable', 'off', 'position', [500 20 80 30]);
        nextsp = uicontrol('style', 'pushbutton', 'string', 'Next', 'callback', {@time_forward, backsp}, 'position', [600 20 80 30], 'enable', 'off');
        if size(data.sortdat,1) >1
            set(nextsp, 'enable', 'on');
        end
        set(backsp, 'callback', {@time_back, nextsp});
        dirbg = uibuttongroup('visible', 'off', 'units', 'pixels','position', [400 20 80 60 ]);
        
        dirseL = uicontrol('style', 'radiobutton', 'string', 'Left', 'position', ...
            [5 5 70 25], 'parent', dirbg, 'handlevisibility', 'off');
        dirseR = uicontrol('style', 'radiobutton', 'string', 'Right', 'position', ...
            [5 30 70 25], 'parent', dirbg, 'handlevisibility', 'off');
        
        set(dirbg,'SelectionChangeFcn',@selcbk);
        set(dirbg,'SelectedObject',[]);  % No selection
        set(dirbg,'Visible','on');
        
        editsize = uicontrol('style', 'edit', 'string', 5, 'position', [300 20 80 30]);
        sizest = uicontrol('style', 'text', 'string', 'Editing Size', 'position', [305 50 70 30]);
        plusb = uicontrol('style', 'pushbutton', 'string', '+', 'position', [200 50 80 30], 'callback', @addsub_low);
        plusplusb = uicontrol('style', 'pushbutton', 'string', '+++', 'position', [200 20 80 30], 'callback', @addsub_low);
        minusb = uicontrol('style', 'pushbutton', 'string', '-', 'position', [100 50 80 30], 'callback', @addsub_low);
        minusminusb = uicontrol('style', 'pushbutton', 'string', '---', 'position', [100 20 80 30], 'callback', @addsub_low);
        removeb = uicontrol('style', 'pushbutton', 'string', 'Remove', 'position', [20 20 80 60], 'callback', {@delete_sp, nextsp, backsp});
        
        set(plusb, 'callback', {@addsub_low, plusb, plusplusb, minusb, minusminusb, editsize});
        set(minusb, 'callback', {@addsub_low, plusb, plusplusb, minusb, minusminusb, editsize});
        set(plusplusb, 'callback', {@addsub_low, plusb, plusplusb, minusb, minusminusb, editsize});
        set(minusminusb, 'callback', {@addsub_low, plusb, plusplusb, minusb, minusminusb, editsize});
        
        edit_menu_1_1 = uimenu('label', '&File', 'parent', editwin);
        edit_menu_1_2 = uimenu('label', '&Save Changes', 'parent', edit_menu_1_1, 'callback', @SaveAndReturn);
        
        data.current_sp = 1;
        
        data.axis.xy = [st*(data.sortdat(data.current_sp, 1)-100), st*(data.sortdat(data.current_sp, 2)+100), data.ax2(3), data.ax2(4)];
        subplot('position', data.xychartpos ./ data.editmainsize)
        axis(data.axis.xy)
        
        data.axis.velo = [st*(data.sortdat(data.current_sp, 1)-100), st*(data.sortdat(data.current_sp, 2)+100), data.ax3(3), data.ax3(4)];
        subplot('position', data.veloplotpos./data.editmainsize)
        axis(data.axis.velo)
        hilite
        
        %have main and editing window; have a primitive loop for each sp
        %epoch, need to add buttons and figure out how to edit
    end
%%
    function selcbk(dirbg,eventdata)
        %         disp(dirbg);
        %         disp([eventdata.EventName,'  ',...
        %              get(eventdata.OldValue,'String'),'  ', ...
        %              get(eventdata.NewValue,'String')]);
        %         disp(get(get(dirbg,'SelectedObject'),'String'));
        LR = get(eventdata.NewValue, 'String')
        switch LR
            case 'Left'
                data.LR = 0;
            case 'Right'
                data.LR = 1;
        end
    end

    function time_forward(nextsp, eventdata, backsp)
        data.current_sp = data.current_sp +1;
        data.axis.xy = [st*(data.sortdat(data.current_sp, 1)-100), st*(data.sortdat(data.current_sp, 2)+100), data.ax2(3), data.ax2(4)];
        subplot('position', data.xychartpos ./ data.editmainsize)
        axis(data.axis.xy)
        
        data.axis.velo = [st*(data.sortdat(data.current_sp, 1)-100), st*(data.sortdat(data.current_sp, 2)+100), data.ax3(3), data.ax3(4)];
        subplot('position', data.veloplotpos./data.editmainsize)
        axis(data.axis.velo)
        
        if data.current_sp >1
            set(backsp, 'enable', 'on')
        end
        if data.current_sp == size(data.sortdat,1)
            set(nextsp, 'enable', 'off')
        end
        hilite
    end

    function time_back(backsp, eventdata, nextsp)
        data.current_sp = data.current_sp -1;
        data.axis.xy = [st*(data.sortdat(data.current_sp, 1)-100), st*(data.sortdat(data.current_sp, 2)+100), data.ax2(3), data.ax2(4)];
        subplot('position', data.xychartpos ./ data.editmainsize)
        axis(data.axis.xy)
        
        data.axis.velo = [st*(data.sortdat(data.current_sp, 1)-100), st*(data.sortdat(data.current_sp, 2)+100), data.ax3(3), data.ax3(4)];
        subplot('position', data.veloplotpos./data.editmainsize)
        axis(data.axis.velo)
        
        if data.current_sp >1
            set(backsp, 'enable', 'on')
        else
            set(backsp, 'enable', 'off')
        end
        if data.current_sp == size(data.sortdat, 1)
            set(nextsp, 'enable', 'off')
        else
            set(nextsp, 'enable', 'on')
        end
        hilite
    end

    function hilite
        %         keyboard
        subplot('position', data.veloplotpos./data.editmainsize);
        cla
        subplot('position', data.xychartpos ./ data.editmainsize)
        cla
%         disp(data.current_sp)
        subplot('position', data.veloplotpos./data.editmainsize);
        plot(st*(1:length(x)), velo, 'k');
        subplot('position', data.xychartpos ./ data.editmainsize)
        plot(st*(1:length(x)), x, 'b')
        plot(st*(1:length(y)), y, 'r')
        title(['Epoch # ' num2str(data.current_sp), '/' num2str(size(data.sortdat, 1))])
        %         keyboard
        
        %         make this one green
        
        %         make the others on both sides back to black
        if data.current_sp >1
            if data.sortdat(data.current_sp-1, 3)==1%ismember(data.sortdat(data.current_sp-1, 1), data.epochs.x(:,1)) && ismember(data.sortdat(data.current_sp-1, 2), data.epochs.x(:,2))
                % ismember(data.sortdat(data.current_sp-1, 1), data.epochs.x(:,1)) && ismember(data.sortdat(data.current_sp-1, 2), data.epochs.x(:,2))
                % data.sortdat(data.current_sp-1, 3)==1
                xcirc = plot(st*(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), x(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), 'ko', 'markersize', 3);
                plot(st*(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), x(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), 'b')
            else
                ycirc = plot(st*(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), y(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), 'ko', 'markersize', 3);
                plot(st*(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), y(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), 'r')
            end
            %             subplot('position', data.veloplotpos./data.editmainsize);
            %             vcirc = plot(st*(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), velo(data.sortdat(data.current_sp-1, 1):data.sortdat(data.current_sp-1, 2)), 'ko', 'markersize', 3);
            %             plot(st*(1:length(x)), velo, 'k');
        end
        if data.current_sp < size(data.sortdat,1)
            if data.sortdat(data.current_sp+1, 3)==1%ismember(data.sortdat(data.current_sp+1, 1), data.epochs.x(:,1)) && ismember(data.sortdat(data.current_sp+1, 2), data.epochs.x(:,2))
                xcirc = plot(st*(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), x(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), 'ko', 'markersize', 3);
                plot(st*(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), x(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), 'b')
            else
                ycirc = plot(st*(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), y(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), 'ko', 'markersize', 3);
                plot(st*(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), y(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), 'r')
            end
            %             subplot('position', data.veloplotpos./data.editmainsize);
            %             vcirc = plot(st*(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), velo(data.sortdat(data.current_sp+1, 1):data.sortdat(data.current_sp+1, 2)), 'ko', 'markersize', 3);
            %             plot(st*(1:length(x)), velo, 'k');
        end
        if data.sortdat(data.current_sp, 3)==1%ismember(data.sortdat(data.current_sp, 1), data.epochs.x(:,1)) && ismember(data.sortdat(data.current_sp, 2), data.epochs.x(:,2))
%             disp('is x')
%             disp([num2str(st*(data.sortdat(data.current_sp, 1))) ':' num2str(st*(data.sortdat(data.current_sp, 2)))])
%             disp([num2str((data.sortdat(data.current_sp, 1))) ':' num2str((data.sortdat(data.current_sp, 2)))])
            xcirc = plot(st*(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), x(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), 'go', 'markersize', 3);
            plot(st*(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), x(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), 'b')
        else
%             disp('is y')
%             disp([num2str(st*(data.sortdat(data.current_sp, 1))) ':' num2str(st*(data.sortdat(data.current_sp, 2)))])
%             disp([num2str((data.sortdat(data.current_sp, 1))) ':' num2str((data.sortdat(data.current_sp, 2)))])
            ycirc = plot(st*(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), y(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), 'go', 'markersize', 3);
            plot(st*(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), y(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), 'r')
        end
        axis(data.axis.xy)
        subplot('position', data.veloplotpos./data.editmainsize);
        vcirc = plot(st*(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), velo(data.sortdat(data.current_sp, 1):data.sortdat(data.current_sp, 2)), 'go', 'markersize', 3);
        plot(st*(1:length(x)), velo, 'k');
        axis(data.axis.velo)
        %%% This isn't working.  It seems to be confused.  I keyboard break
        %%% to look at each chunk, one at a time.
        
        
        
        
    end

    function addsub_low(caller, eventdata, plusb, plusplusb, minusb, minusminusb, editsize)
        %         keyboard
        
        if caller == plusb
            data.plusminus = 1;
        elseif caller == minusb
            data.plusminus = -1;
        elseif caller == plusplusb
            data.plusminus = str2num([get(editsize, 'string')]);
        elseif caller == minusminusb
            data.plusminus = -1 * str2num([get(editsize, 'string')]);
        end
        
        xrow = find(data.sortdat(data.current_sp,1) == data.epochs.x(:,1));
        yrow = find(data.sortdat(data.current_sp,1) == data.epochs.y(:,1));
        
        switch data.LR
            case 0
                data.plusminus = data.plusminus;
                data.sortdat(data.current_sp,1) = max(data.sortdat(data.current_sp,1)-data.plusminus, 1);
                data.sortdat(data.current_sp,1)
                if ~isempty(xrow)
                    data.epochs.x(xrow,1) = max(data.epochs.x(xrow,1)-data.plusminus, 1);
                    data.epochs.x(xrow,1)
                end
                if ~isempty(yrow)
                    data.epochs.y(yrow,1) = max(data.epochs.y(yrow,1)-data.plusminus, 1);
                end
            case 1
                data.sortdat(data.current_sp,2) = min(data.sortdat(data.current_sp,2)+data.plusminus, length(x));
                data.sortdat(data.current_sp,2)
                if ~isempty(xrow)
                    data.epochs.x(xrow,2) = min(data.epochs.x(xrow,2)+data.plusminus, length(x));
                    data.epochs.x(xrow,2)
                end
                if ~isempty(yrow)
                    data.epochs.y(yrow,2) = min(data.epochs.y(yrow,2)+data.plusminus, length(y));
                end
                
        end
        
        hilite
    end

    function delete_sp(removeb, eventdata, nextsp, backsp)
%         keyboard
        xrow = find(data.sortdat(data.current_sp,1) == data.epochs.x(:,1));
        yrow = find(data.sortdat(data.current_sp,1) == data.epochs.y(:,1));
        if size(data.sortdat,1)>1
            data.sortdat(data.current_sp,:) = [];
            if ~isempty(xrow)
                data.epochs.x(xrow,:) = [];
            end
            if ~isempty(yrow)
                data.epochs.y(yrow,:) = [];
            end
            %         data.current_sp = data.current_sp -1;
%             keyboard
            if data.current_sp == size(data.sortdat,1)+1
                time_back(backsp, eventdata, nextsp)
            else
                data.current_sp = data.current_sp - 1;
                time_forward(nextsp, eventdata, backsp)                
            end
        else
%             confirm = [];
            figconfirm = figure('menubar', 'none', 'numbertitle', 'off', 'pos', [950 300, 300, 200]);
            confirmtext = uicontrol('parent', figconfirm, 'style', 'text', 'string', ['This is the last Epoch:  Delete and save?'], 'pos', [25 140 250 50]);
            yesbut = uicontrol('parent', figconfirm, 'style', 'pushbutton', 'string', 'yes', 'pos', [25 10 110 120], 'callback', {@confirm, 1, figconfirm});
            nobut = uicontrol('parent', figconfirm, 'style', 'pushbutton', 'string', 'no', 'pos', [160 10 110 120], 'callback', {@confirm, 0, figconfirm});
            
            
        end
    end

    function SaveAndReturn(edit_menu_1_2, eventdata)
        %         keyboard
        sp_final = zeros(1, length(x));
        sp_index_final = unique(cell2mat(arrayfun(@(x) data.sortdat(x,1):data.sortdat(x,2), [1:size(data.sortdat,1)], 'uni', 0)));
        %         sp_final(sp_index_final) = 1;
        
        
        %         smooth.sp_begin_final = [sp_index_final(1), sp_index_final(find(diff(sp_index_final)>1)+1)];
        %         smooth.nsmooth = length(smooth.sp_begin_final);
        %         smooth.sp_end_final = [sp_index_final(find(diff(sp_index_final)>1)), length(sp_index_final)];
        %         smooth.sp_duration_final = smooth.sp_end_final - smooth.sp_begin_final + 1;
        %         smooth.sp_duration_final = [smooth.sp_duration_final; st*smooth.sp_duration_final];
        uiresume
        close all
        %         set(auditmain_menu2_3, 'callback', {@AddFixSac, fixinfo, sacinfo, smooth});
        
    end


    function AddFixSac(auditmain_menu2_3, eventdata, fixinfo, sacinfo, varargin)
        keyboard
        fixinfo
        sacinfo
        if ~isempty(varargin)
            smooth = varargin{1};
        end
        %         plotcolors = {'
        
    end

    function confirm(caller, eventdata, clogic, figconfirm)
        xrow = find(data.sortdat(data.current_sp,1) == data.epochs.x(:,1));
        yrow = find(data.sortdat(data.current_sp,1) == data.epochs.y(:,1));
        if clogic ==1
            data.sortdat(data.current_sp,:) = [];
            if ~isempty(xrow)
                data.epochs.x(xrow,:) = [];
            end
            if ~isempty(yrow)
                data.epochs.y(yrow,:) = [];
            end
            SaveAndReturn
        else
            close(figconfirm)
            return
        end
    end

    function PhaseFig(auditmain_menu1_2, eventdata, whatson)
        phasefig = figure('position', [100 500 200 225], 'numbertitle', 'off', 'name', 'Phase Information', 'menubar', 'none', 'color', [.7 .7 .7]);
        phasedatnames = uicontrol('style', 'text', 'pos', [10 10 85 205], 'string', whatson.Names);
        phasedatindex = uicontrol('style', 'text', 'pos', [105 10 85 205], 'string', st*whatson.Begindices);
    end




% keyboard
% plot x & y
end

