function [nitems,outmat] = summ_fixsac(classifications)
if ~isempty(classifications.saccades)
    fn = fieldnames(classifications);
    outmat = nan(0,13);
    for fni = 1:length(fn)
        nitems = classifications.(char(fn(fni))).count;
        if ~isempty(nitems)
            loopmat = nan(nitems,13);
            loopmat(:,1) = nitems;
            loopmat(:,2) = fni;
            loopmat(:,3) = 1:nitems';
            loopmat(:,4) = classifications.(char(fn(fni))).onsets(1,:)';
            loopmat(:,5) = classifications.(char(fn(fni))).onsets(2,:)';
            loopmat(:,6) = classifications.(char(fn(fni))).durations(1,:)';
            loopmat(:,7) = classifications.(char(fn(fni))).durations(2,:)';
            loopmat(:,8) = classifications.(char(fn(fni))).offsets(1,:)';
            loopmat(:,9) = classifications.(char(fn(fni))).offsets(2,:)';
            if strcmp('fixations', char(fn(fni)))
                loopmat(:,10) = classifications.(char(fn(fni))).centroids(1,:)';
                loopmat(:,11) = classifications.(char(fn(fni))).centroids(2,:)';
            end
            if strcmp('saccades', char(fn(fni)))
                loopmat(:,12) = classifications.(char(fn(fni))).velocities(3,:)';
            end
            if strcmp('smoothpursuit', char(fn(fni)))
                loopmat(:,13) = classifications.(char(fn(fni))).displacement(1,:)';
            end
            outmat = [outmat; loopmat];
        end
    end
    nitems = size(outmat,1);
else
    nitems = 0;
    outmat = [];
end



