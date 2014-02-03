%%  Clean-up and Interpolate

%   Script identifies and interpolates bad points from gazedata based on
%   validity measures.  Parameters for maximum length of interpolation as
%   optional input.

%   [SH] - 10/31/13:  Adding Comments

function [processed, gooddata, gapdata] = clean_interp(time, eye1, eye2, sr)   

    max_points_to_interpolate = floor(80/(1000/sr)); %Maximum interpolation gap is 80ms.  This converts 'ms' to number of points.
    max_blink = floor(500/(1000/sr)); %Maximum theoretical blink size (500ms), also converted to 'ms'.  Anythings larger is likely missing data.

%% Bounding
% Any points which fall outside of the screen area ([0 0 1 1]) need to be
% addressed.

% We do this first by marking them all as Validity 4, so as to exclude them
% from later analysis
    eye1.Validity(eye1.GazeX < 0 | eye1.GazeX > 1 | eye1.GazeY < 0 | eye1.GazeY > 1) = 4;
    eye2.Validity(eye2.GazeX < 0 | eye2.GazeX > 1 | eye2.GazeY < 0 | eye2.GazeY > 1) = 4;
% We bring all such points back inside the boundaries by setting the
% highest value as 1, and the lowest as -1.  We cannot set the lowest to 0
% because this will remove points marked as bad by Tobii via -1 values;
% this allows for points in the range~ -.999 : -.001 but because they are
% marked bad already this shouldn't actually matter.  In other words, this
% step may be entirely unnecessary.
    eye1.GazeX = max(eye1.GazeX, -1); eye1.GazeY = max(eye1.GazeY, -1);
    eye1.GazeX = min(eye1.GazeX, 1); eye1.GazeY = min(eye1.GazeY, 1);
    
    eye2.GazeX = max(eye2.GazeX, -1); eye2.GazeY = max(eye2.GazeY, -1);
    eye2.GazeX = min(eye2.GazeX, 1); eye2.GazeY = min(eye2.GazeY, 1);
    
    
%%  Create vectors containing eye information

% This section primarily uses logical indexing.  See demo_log_indx.m for a
% detailed description.

%     Index of all points, same length as input eye1 data.
    vec.all = 1:length(eye1.Validity); 
%     Make a new vector to describe the quality of the eyes at each points in time.  Set initial values for all points to '3' indicating both eyes are good.
    vec.eyes = ones(1, length(vec.all)) * 3; 
%     if eye1 is bad validity (2 or 4), change the quality metric at that time point to '2' indicating only eye2 is good here
    vec.eyes(or(eye1.Validity == 4, eye1.Validity == 2)) = 2; 
%     if eye2 is bad validity (2 or 4), change the quality metric at that time point to '1' indicating only eye1 is good here
    vec.eyes(or(eye2.Validity == 4, eye2.Validity == 2)) = 1; 
%     when both eyes are bad, mark the quality as '0'
    vec.eyes(and(or(eye1.Validity == 2, eye1.Validity == 4), or(eye2.Validity == 2, eye2.Validity == 4))) = 0; 
%     Find where gaps begin.  This is done by logical index where eyes ==
%     0 returns 1, finding where the difference of this vector == 1,
%     indicating that a good point (logical 0) was immediately followed
%     by a bad point (logical 1); 1-0 ==1.  Locate this index of the first point and add 1
%     gives you the begnning of bad segments of data
    vec.gaps = [find(diff(vec.eyes==0)==1)+1];
    
%     if the first or last (or both) points in our eye-quality is 0, we need to take special care
%     because our logical indexing won't be able to find them.  To get around
%     this, we add a fake 1 at the beginning (allows us to find the first point
%     as a gap), or tell the last point that its length is 1
    if vec.eyes(1) == 0
        if vec.eyes(end) == 0
            vec.gaps = [1, vec.gaps];
            vec.gaps = [vec.gaps; [find(diff(vec.eyes==0)==-1), length(vec.eyes)] - [1, find(diff(vec.eyes==0)==1)]];
        else            
            vec.gaps = [1, vec.gaps];
            vec.gaps = [vec.gaps; find(diff(vec.eyes==0)==-1) - [1, find(diff(vec.eyes==0)==1)]];
        end
    else
        if vec.eyes(end) == 0            
            vec.gaps = [vec.gaps; [find(diff(vec.eyes==0)==-1), length(vec.eyes)] - find(diff(vec.eyes==0)==1)];
        else
%             this is the basic operation that is happening in this chunk
%             of 'if' code when neither the first nor the last point is 0.
%             The second row of vec.gaps is now defined by finding where the difference of logicals (see
%             lines 50-54) is now -1 instead of 1, indicating a bad
%             followed by good point.  If we subtract the known beginning
%             indiced from these ending points, we determine
%             the length of the gap (end-beginning == length)
            vec.gaps = [vec.gaps; find(diff(vec.eyes==0)==-1) - find(diff(vec.eyes==0)==1)];
        end
    end
%     the last row in vec.gaps is now a logical to classify the gap length
%     as either interpolatable, as a blink, or missing data.  This is simply done by
%     making a row of ones (indicating interpolatable), adding 1 if the
%     length is beyond the maximum interp. length, and adding another 1 if
%     it is beyond the max blink length.  
    vec.gaps = [vec.gaps; [ones(1, size(vec.gaps,2)) + (vec.gaps(2,:) > max_points_to_interpolate) + (vec.gaps(2,:) > max_blink)]];
    
%     The end result here is: 
%     [an array where gaps begin;
%     their lengths;
%     a classification for later treatment];
  
%% Interpolating
%     this part uses a neat trick to fill in string values into a looping
%     'eval' function to perform the same functions on many variables
%     without writing out each one separately.
% 
%     Eval works by literally evaluating a string command e.g. 
%         eval(['mean(x) * ', str2num('5');])
%     will evaluate the literal command: mean(x) * 5;  
% 
%     In our case, we will be using it to fill in the names of vectors from
%     our inputs eye1 and eye2 listed below as 'origname' and making new
%     vectors for our output 'newname'
% 

    newname = {'x', 'y', 'd', 'v', 'p'};
    origname = {'GazeX', 'GazeY', 'Distance', 'Validity', 'Pupil'};
    

    for i = newname
%         convert the cell to a string
        i = char(i);
%         make a new empty vector full of nans, the same length as our
%         incoming data.
        eval([i, '= ones(1, length(vec.all))-2;'])
%         at every point in vec.eyes where both eyes are good (==3) take
%         the mean of the values from both eyes and plug that values into
%         our new vector at the same location. 
%         The 'char(origname(strfind(char(newname)', i)))' basically
%         finds which new name to use based on the oldname.
        eval([i, '(vec.eyes==3) = nanmean([eye1.' char(origname(strfind(char(newname)', i))), '(vec.eyes==3); eye2.' char(origname(strfind(char(newname)', i))), '(vec.eyes==3)]);'])
%         however, if only one eye is good, take the value from only that
%         eye and plug it into the new vector
        eval([i, '(vec.eyes==1) = eye1.' char(origname(strfind(char(newname)', i))), '(vec.eyes==1);'])
        eval([i, '(vec.eyes==2) = eye2.' char(origname(strfind(char(newname)', i))), '(vec.eyes==2);'])
        
%         here is where we handle gaps.  'rep' will go column-by-column
%         through vec.gaps
        for rep = 1:size(vec.gaps,2)
%             if the category of this gap (defined in line 88) is 1, it is
%             interpolatable, so let's do it!
            if vec.gaps(3, rep) == 1
%                 if the first point in our data is a gap, we can't
%                 interpolate because we don't know where we started so we
%                 have to skip this, otherwise move on.
                if vec.gaps(1,rep) ~=1
%                     we need to know if we will be interpolating over both
%                     eyes because they had good data prior to the gap or
%                     only one.  Rather than writing different formulas to
%                     calculate all three cases differently, we simply used
%                     a weighted sum of both eyes where the weights are
%                     either 0 or 1 and we divide the end result by the sum
%                     of the weights (either 1 or 2)
% 
%                     For example, if both are good, our weights = [1,1]
%                     and we take the value form eye1 + the value from eye2
%                     and divide by (1+1) to get the average.
% 
%                     If only eye1 is good, weights = [1,0] and we take
%                     1*eye1 + 0*eye2 and divide by (1+0);
                    weights = [[vec.eyes(vec.gaps(1,rep)-1) ~= 2, vec.eyes(vec.gaps(1,rep)-1) ~= 1]; [vec.eyes(min(vec.gaps(1,rep)+vec.gaps(2,rep), length(vec.eyes))) ~= 2, vec.eyes(min(vec.gaps(1,rep)+vec.gaps(2,rep), length(vec.eyes))) ~= 1]];
%                     create values for the last good point before
%                     the gap (bgn) and the first good point after (endd).
                    bgn = vec.gaps(1,rep)-1;
                    endd = min(vec.gaps(1,rep)+vec.gaps(2,rep), length(vec.eyes));
                    
%                     here is the weighted sum and averaging described in
%                     140-153
%                     
                    eval([i, '(bgn:endd) = (' ...                     
                        'linspace(' ...
                        '(weights(1,1) * eye1.' char(origname(strfind(char(newname)', i))), '(bgn) + weights(1,2) * eye2.' char(origname(strfind(char(newname)', i))), '(bgn)) / (weights(1,1) + weights(1,2)), ' ...
                        '(weights(2,1) * eye1.' char(origname(strfind(char(newname)', i))), '(endd) + weights(2,2) * eye2.' char(origname(strfind(char(newname)', i))), '(endd)) / (weights(2,1) + weights(2,2)), ' ...
                        'endd - bgn + 1));'])
                end
            end

        end
        eval([i '(' i '==-1) = NaN;']);
%         eval again to place the newly created matrix into the structure
%         'processed' which will get returned to the function caller.
        eval(['processed.', char(origname(strfind(char(newname)', i))), ' = ' i ';'])
    end
%       calculate how many good points / total points to get a ratio of how
%       much of our data is usable.
    gooddata = length(find(~isnan(x)))/length(x);
%       pass the information about the gaps back to the caller as well;
%       this will eventually get sent off to the fixation / saccade
%       detection for use in finding blinks and gaps.
    gapdata = vec.gaps(:, vec.gaps(3,:)~=1);
keyboard
return
    
    