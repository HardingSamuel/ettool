function pix = smh_vac_pix(deg,varargin)
% returns the pixel size of an object of visual angle deg in the direction
% 'orientation' = 'h' or 'v';

%   [SH] - 09/05/17:   created based on Ty's xls sheet

% assumes screen dimensions
xPx = 1920;
yPx = 1080;

xMM = 508;
yMM = 285.75; % note this is different from the sheet to give constant ratio with horiz


% how far away? if we don't know, then assume 650 mm
if nargin ==1
  dist = 650;
else
  dist = varargin{1};
end

tang = tand(deg/2);
pix = tang * 2 * dist * xPx / xMM;