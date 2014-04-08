function [ind, dmin] = findBottomBuilding(lowerb, seeds, taken)
dy = zeros(length(taken), 1);
for i = 1:length(taken)
    if taken(i) 
        dy(i) = inf;
    else
        thisSeeds = seeds{i};
        yy = thisSeeds(:,2);
        dy(i) = -max(yy);
    end
end
[dmin, ind] = min(dy);