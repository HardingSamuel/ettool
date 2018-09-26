function [smoothinfo] = fix_smooth(x,y,winlen)
%
% fix_smooth
% Attempt to locate epoch of smooth pursuit given basic assumptions --
% linear trajectory, data has good fit with 1st order poly, slope of
% best-fit is above some threshold
%
% INPUTS:
% velo - velocity
% sr - sample rate
%
% OUTPUTS:
% smoothinfo
%
%% Change Log
%   [SH] - 05/13/14:    v1 - Creation

%%

smoothinfo.slope = nan(1,size(x,2));
smoothinfo.fit = nan(1,size(x,2));

for winslid = 1:size(x,2)-(winlen)
    xvec = x(winslid:winslid+winlen-1);
    yvec = y(winslid:winslid+winlen-1);
    [smoothinfo.slope(winslid),smoothinfo.fit(winslid)] = findslope(xvec,yvec);
end

    function [m,rsq] = findslope(x,y)
        p = polyfit(x,y,1);
        yfit = polyval(p,x);
        yresid = y - yfit;
        SSresid = sum(yresid.^2);
        SStotal = (length(y)-1) * var(y);
        rsq = 1 - SSresid/SStotal;
        m = abs(p(1));
    end
end