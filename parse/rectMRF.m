function [parse, initParse] = rectMRF(conf, data)
seeds = data.seeds;
numBuildings = length(seeds);
[~, w, numUnary] = size(data.unary.combined);
assert(numBuildings + 1 == numUnary);

bottom = data.region(:,2)';
upper = data.region(:,1)';

% Parse is the y coordinate of each building in each column
parse.bottom = bottom;
parse.upper = upper;
parse.tiers = zeros(numBuildings, w, 'uint16');
parse.order = [];
taken = false(1, numBuildings);

% Greedy labelling of all the pixels
tic;
while any(~taken), 
    ind = findBottomBuilding(bottom, seeds, taken);
    buildingUpper = upperBoundary(conf, data, bottom, upper, ind);
    bottom = buildingUpper;
    upper = min(bottom, upper);
    parse.tiers(ind, :) = bottom;
    taken(ind) = true;
    parse.order = [parse.order; ind];
    
    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('Initial parse, building %i/%i\n', sum(taken), numBuildings));
    end
end
initParse = parse;
label = parse2label(initParse,data);
fprintf('%.2fs intial parse..',toc);

% Refine the rectangles
tic;
maxIter = 2*numBuildings;
for i = 1:maxIter,
    ind = parse.order(mod(i-1, numBuildings)+1);
    buildingUpper = upperBoundaryRefine(conf, data, parse, ind, label);
    parse = updateParse(buildingUpper, parse, ind);
    label = parse2label(parse, data);
    
    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('Refining parse, iter %i/%i\n', i, maxIter));
    end
end
fprintf('%.2fs refinement.\n',toc);


%--------------------------------------------------------------------------
%                                                           Upate the parse
%--------------------------------------------------------------------------
function parse = updateParse(buildingUpper, parse, ind)
parse.tiers(ind,:) = buildingUpper;
for i = 2:length(parse.order), 
    this = parse.order(i);
    below = parse.order(i-1);
    parse.tiers(this,:) = min(parse.tiers(this,:), parse.tiers(below,:));
end

%--------------------------------------------------------------------------
%                                Refine the upper boundary of the rectangle
%--------------------------------------------------------------------------
function buildingUpper = upperBoundaryRefine(conf, data, parse, ind, label)
% Compute the bounds of this seed and region of interest
[h,w,~]=size(data.unary.combined);
thisSeed = data.seeds{ind};
xx = thisSeed(:,1); 
yy = thisSeed(:,2);
xmin = max(1, min(xx) - conf.param.building.maxWidth/2);
xmax = min(w, max(xx) + conf.param.building.maxWidth/2);
ymin = max(1, min(parse.upper(xmin:xmax))-conf.param.building.search.deltay);
ymax = min(h, max(parse.bottom(xmin:xmax)));

% Crop the unary and pairwise terms around the building of interest
unaryInd = ind + 1;
fg = data.unary.combined(ymin:ymax,xmin:xmax,unaryInd);
regionLabel = label(ymin:ymax, xmin:xmax);
fgmask = regionLabel == unaryInd;

% Estimate the labels for the background regions
bglabel = regionLabel;
bglabel(fgmask) = 0; 
for i = 1:size(bglabel,2)
    minInd = find(bglabel(:,i)==0,1);
    if ~isempty(minInd)
        if minInd == 1
            bglabel(bglabel(:,i)==0,i) = 1; % background
        else
            upperLabel = bglabel(minInd-1,i);
            bglabel(bglabel(:,i)==0,i) = upperLabel;
        end
    end
end

% Compute unary potentials for background regions
regionUnary = data.unary.combined(ymin:ymax, xmin:xmax, :);

[jj,ii] = meshgrid(1:xmax-xmin+1, 1:ymax-ymin+1);
bgind = sub2ind(size(regionUnary),ii(:), jj(:), double(bglabel(:)));
bg = reshape(regionUnary(bgind), size(ii));

% Compute upper and lower bounds for this tier
orderInd = find(parse.order == ind);
if orderInd == 1, 
    prevUpper = parse.bottom;
else
    prevInd = parse.order(orderInd-1);
    prevUpper = parse.tiers(prevInd,:);
end
thisUpper = parse.upper(xmin:xmax)-ymin+1;
thisLower = prevUpper(xmin:xmax)-ymin+1;
prevSoln = parse.tiers(ind,xmin:xmax)-ymin+1;

% Calculate culumative sums for speed
u = fg-bg;

px = data.pairwise.xx(ymin:ymax,xmin:xmax);
py = data.pairwise.yy(ymin:ymax,xmin:xmax);
for i = 1:size(px,2)
    u(thisLower(i):end,i) = 0;
    px(thisLower(i):end,i) = 0;
end

u1 = cumsum(u, 2);
u2 = cumsum(u1(end:-1:1,:), 1);
cu = u2(end:-1:1,:);

cpy = cumsum(py, 2);
cpx = cumsum(px(end:-1:1,:),1);
cpx = cpx(end:-1:1,:);

stepSize = conf.param.building.search.step;

rects = [];
costs = [];
count = 1;
lambda = conf.param.pairwise.lambda;
for left = (xmin:stepSize:min(xx))-xmin+1,
    for right = (max(xx):stepSize:xmax)-xmin+1, 
        thisy1 = min(thisUpper(left:right));
        thisy2 = min(max(thisLower(left:right)),min(yy-ymin)-1);
        for top = thisy1:stepSize:thisy2,
            rects(:,count) = [left;top;right];
            if right-left < conf.param.building.minWidth 
                costs(count) = inf;
            else
                unaryCost = cu(top, right) - cu(top, left);
                pairwiseCost = cpy(top,right) - cpy(top,left) + ...
                               cpx(top,left)  + cpx(top,right);
                costs(count) = (1-lambda)*unaryCost + lambda*pairwiseCost;
            end
            count = count + 1;
        end
    end
end


[~,best] = min(costs);
if ~isempty(best),
    bestRect = rects(:,best);
    buildingUpper = prevUpper;
    buildingUpper(bestRect(1)+xmin:bestRect(3)+xmin-1) = bestRect(2)+ymin-1;
else
    buildingUpper = prevUpper;
end
buildingUpper = min(buildingUpper, prevUpper);

%figure(1); clf;
%imagesc(data.im(ymin:ymax, xmin:xmax,:)); 
%axis image off;
%hold on; 
%plot(1:length(prevSoln), prevSoln,'k-', 'LineWidth',2);
%plot(1:length(prevSoln), buildingUpper(xmin:xmax)-ymin+1,'r-','LineWidth',2);
%plot(1:length(prevSoln), thisLower,'b-','LineWidth',2);

%keyboard;

%imagesc(data.im); axis image; hold on;
%plot(1:w, buildingUpper,'g-');
%plot(1:w, prevUpper,'r-');



% Initial labelling
function buildingUpper = upperBoundary(conf, data, bottom, upper, ind)
% Compute the bounds of this seed and region of interest
[h,w,~]=size(data.unary.combined);
thisSeed = data.seeds{ind};
xx = thisSeed(:,1); 
yy = thisSeed(:,2);
xmin = max(1, min(xx) - conf.param.building.maxWidth/2);
xmax = min(w, max(xx) + conf.param.building.maxWidth/2);
ymin = max(1, min(upper(xmin:xmax))-conf.param.building.search.deltay);
ymax = min(h, max(bottom(xmin:xmax)));

% Crop the unary and pairwise terms around the building of interest
unaryInd = ind + 1;
other = 1:size(data.unary.combined,3); 
other(other==unaryInd) = []; other(other == 1) = [];
fg = data.unary.combined(ymin:ymax,xmin:xmax,unaryInd);
bg = min(data.unary.combined(ymin:ymax,xmin:xmax,other),[],3);
thisUpper = upper(xmin:xmax)-ymin+1;
thisBottom = bottom(xmin:xmax)-ymin+1;

% Calculate culumative sums for speed
u = fg-bg;
px = data.pairwise.xx(ymin:ymax,xmin:xmax);
py = data.pairwise.yy(ymin:ymax,xmin:xmax);
for i = 1:size(px,2)
    u(thisBottom(i):end,i) = 0;
    px(thisBottom(i):end,i) = 0;
end

u1 = cumsum(u, 2);
u2 = cumsum(u1(end:-1:1,:), 1);
cu = u2(end:-1:1,:);

cpy = cumsum(py, 2);
cpx = cumsum(px(end:-1:1,:),1);
cpx = cpx(end:-1:1,:);

stepSize = conf.param.building.search.step;

rects = [];
costs = [];
count = 1;
lambda = 0.1;
for left = (xmin:stepSize:min(xx))-xmin+1,
    for right = (max(xx):stepSize:xmax)-xmin+1, 
        thisy1 = min(thisUpper(left:right));
        thisy2 = min(max(thisBottom(left:right)),min(yy-ymin)-1);
        for top = thisy1:stepSize:thisy2,
            rects(:,count) = [left;top;right];
            if right-left < conf.param.building.minWidth 
                costs(count) = inf;
            else
                unaryCost = cu(top, right) - cu(top, left);
                pairwiseCost = cpy(top,right) - cpy(top,left) + ...
                               cpx(top,left)  - cpx(thisBottom(left),left) + ...
                               cpx(top,right) - cpx(thisBottom(right), right);
                costs(count) = (1-lambda)*unaryCost + lambda*pairwiseCost;
            end
            count = count + 1;
        end
    end
end

[~,best] = min(costs);
if ~isempty(best),
    bestRect = rects(:,best);
    buildingUpper = bottom;
    buildingUpper(bestRect(1)+xmin:bestRect(3)+xmin-1) = bestRect(2)+ymin-1;
else
    buildingUpper = bottom;
end
buildingUpper = min(buildingUpper, bottom);

function [ind, dmin] = findBottomBuilding(bottom, seeds, taken)
dy = zeros(length(taken), 1);
for i = 1:length(taken)
    if taken(i) 
        dy(i) = inf;
    else
        thisSeeds = seeds{i};
        xx = thisSeeds(:,1); yy = thisSeeds(:,2);
        %dy(i) = min(bottom(xx)-yy');
        dy(i) = -max(yy);
    end
end
[dmin, ind] = min(dy);