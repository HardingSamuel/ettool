%   [SH] - 02/14/14:  Added to ETTool on Git

function [m, rsq] = findslope(x,y,order)

% Use polyfit to compute a linear regression that predicts y from x:
p = polyfit(x,y,order);

% p =
%     1.5229   -2.1911
% p(1) is the slope and p(2) is the intercept of the linear predictor. You can also obtain regression coefficients using the Basic Fitting GUI.
% Call polyval to use p to predict y, calling the result yfit:
yfit = polyval(p,x);
% Using polyval saves you from typing the fit equation yourself, which in this case looks like:
yfit =  p(1) * x + p(2);
% Compute the residual values as a vector signed numbers:
yresid = y - yfit;
% Square the residuals and total them obtain the residual sum of squares:
SSresid = sum(yresid.^2);
% Compute the total sum of squares of y by multiplying the variance of y by the number of observations minus 1:
SStotal = (length(y)-1) * var(y);
% Compute R2 using the formula given in the introduction of this topic:
rsq = 1 - SSresid/SStotal;
m = p(1);


% rsq =
%     0.8707

