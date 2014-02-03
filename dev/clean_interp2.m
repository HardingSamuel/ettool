%%  Clean-up and Interpolate

%   Script identifies and interpolates bad points from gazedata based on
%   validity measures.  Parameters for maximum length of interpolation as
%   optional input.

%   [SH] - 10/31/13:  THIS IS A DEVELOPMENT VERSION -- DO NOT USE

function [processed, gooddata, vec.gaps(:, vec.gaps(3,:)~=1)] = clean_interp2(time, eye1, eye2, sr)   

    npts = floor(80/(1000/sr));
    maxblink = floor(500/(1000/sr));

%% Bounding
    eye1.Validity(eye1.GazeX < 0 | eye1.GazeX > 1 | eye1.GazeY < 0 | eye1.GazeY > 1) = 4;
    eye2.Validity(eye2.GazeX < 0 | eye2.GazeX > 1 | eye2.GazeY < 0 | eye2.GazeY > 1) = 4;

    eye1.GazeX = max(eye1.GazeX, -1); eye1.GazeY = max(eye1.GazeY, -1);
    eye1.GazeX = min(eye1.GazeX, 1); eye1.GazeY = min(eye1.GazeY, 1);
    
    eye2.GazeX = max(eye2.GazeX, -1); eye2.GazeY = max(eye2.GazeY, -1);
    eye2.GazeX = min(eye2.GazeX, 1); eye2.GazeY = min(eye2.GazeY, 1);
    
    eye1.GazeX(eye1.GazeX < 0) = NaN; eye1.GazeY(eye1.GazeY < 0) = NaN;
    eye2.GazeX(eye2.GazeX < 0) = NaN; eye2.GazeY(eye2.GazeY < 0) = NaN;
    
    
%%  Locate all bad points

    vec.all = 1:length(eye1.Validity);    
    vec.eyes = ones(1, length(vec.all)) * 3;
    vec.eyes(or(eye1.Validity == 4, eye1.Validity == 2)) = 2;
    vec.eyes(or(eye2.Validity == 4, eye2.Validity == 2)) = 1;
    vec.eyes(and(or(eye1.Validity == 2, eye1.Validity == 4), or(eye2.Validity == 2, eye2.Validity == 4))) = 0;
    vec.gaps = [find(diff(vec.eyes==0)==1)+1];
    vec.gaps = [vec.gaps; [find(diff(find(vec.eyes==0))>1), (find(vec.eyes ==0, 1, 'last') - vec.gaps(end) +1)]];    
    vec.gaps = [vec.gaps; [ones(1, length(vec.gaps)) + (vec.gaps(2,:) > npts) + (vec.gaps(2,:) > maxblink)]];
  
%% Interpolating
    % Make blank arrays for xpos, ypos, distance, validity, and
    % pupil dilation.

    % Fill these with values from vec -- average when vec.eyes ==3, take
    % from good eye in case or ==1 | ==2

    % Interpolate values based on any distances that are <
    % npts (linspace) using categorization in vec.gaps(3,:)

    % Fills in the values based on 'fill' and
    % 'fillname' so it can be looped.

    fill = {'x', 'y', 'd', 'v', 'p'};
    fillname = {'GazeX', 'GazeY', 'Distance', 'Validity', 'Pupil'};
    
    
    for i = fill
        
        i = char(i);
        eval([i, '= nan(1, length(vec.all));'])
        eval([i, '(vec.eyes==3) = nanmean([eye1.' char(fillname(strfind(char(fill)', i))), '(vec.eyes==3); eye2.' char(fillname(strfind(char(fill)', i))), '(vec.eyes==3)]);'])
        eval([i, '(vec.eyes==1) = eye1.' char(fillname(strfind(char(fill)', i))), '(vec.eyes==1);'])
        eval([i, '(vec.eyes==2) = eye2.' char(fillname(strfind(char(fill)', i))), '(vec.eyes==2);'])
        
        
        for rep = 1:size(vec.gaps,2)
            if vec.gaps(3, rep) == 1
                weights = [vec.eyes(vec.gaps(1,rep)-1) ~= 2, vec.eyes(vec.gaps(1,rep)-1) ~= 1];
                bgn = vec.gaps(1,rep)-1;
                endd = vec.gaps(1,rep)+vec.gaps(2,rep);
                eval([i, '(bgn:endd) = (' ...
                    '[weights(1) * (linspace(eye1.' char(fillname(strfind(char(fill)', i))), '(bgn), eye1.' char(fillname(strfind(char(fill)', i))), '(endd), endd - bgn + 1))] + ' ...
                    '[weights(2) * (linspace(eye2.' char(fillname(strfind(char(fill)', i))), '(bgn), eye2.' char(fillname(strfind(char(fill)', i))), '(endd), endd - bgn + 1))]) / sum(weights);'])
            end
        end
        eval(['processed.', char(fillname(strfind(char(fill)', i))), ' = ' i ';'])
    end
      
    gooddata = length(find(~isnan(x)));
  
return
    
    