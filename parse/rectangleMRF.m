function parses = rectangleMRF(conf, data)
seeds = data.seeds;
numBuildings = length(seeds);
[~, w, numUnary] = size(data.unary.combined);
assert(numBuildings + 1 == numUnary);

tierLower = data.region(:,2)';
tierUpper = data.region(:,1)';

% Parse is the y coordinate of each building in each column
parse.lower = tierLower;
parse.upper = tierUpper;
parse.tiers = zeros(numBuildings, w, 'uint16');
parse.rect = zeros(numBuildings, 3, 'double');
parse.order = [];
taken = false(1, numBuildings);

% Greedy labelling of all the pixels
currLower = tierLower;
currUpper = tierUpper;
tic;
while any(~taken), 
    ind = findBottomBuilding(currLower, seeds, taken);
    [buildingUpper, rect] = initUpperBoundary(conf, data, currLower, tierUpper, ind);
    currLower = buildingUpper;
    currUpper = min(currUpper, currLower);
    tierUpper = min(currUpper, tierUpper);
    parse.tiers(ind, :) = currLower;
    parse.rect(ind, :) = rect;
    taken(ind) = true;
    parse.order = [parse.order; ind];
    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('rectange MRF: initialization: building %i/%i', sum(taken), numBuildings),'fontSize',16);
    end
end
parses.initial = parse;
fprintf('rectangle MRF: %.2fs intial parse..',toc);

% Refine the rectangles
label = parse2label(parses.initial, data);
parse = parses.initial;
tic;
maxIter = 2*numBuildings;
for i = 1:maxIter,
    ind = parse.order(mod(i-1, numBuildings)+1);
    [buildingUpper, rect] = refineRectangle(conf, data, parse, ind, label);
    parse = updateParse(buildingUpper, parse, rect, ind);
    label = parse2label(parse, data);

    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('rectangle MRF: updating: iter %i/%i', i, maxIter),'fontSize',16);
    end
end
parses.rect = parse;
fprintf('%.2fs updating...',toc);

% Refine the upper boundaries of the rectangles
label = parse2label(parse, data);
tic;
maxIter = numBuildings;
for i = 1:maxIter,
    ind = parse.order(mod(i-1, numBuildings)+1);
    buildingUpper = refineTiers(conf, data, parse, ind, label, true);
    parse = updateParse(buildingUpper, parse, parse.rect(ind, :), ind);
    label = parse2label(parse, data);

    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('refined MRF: refining: iter %i/%i', i, maxIter),'fontSize',16);
    end
end
parses.refined = parse;
fprintf('%.2fs refinement.\n',toc);


%--------------------------------------------------------------------------
%                                                           Upate the parse
%--------------------------------------------------------------------------
function parse = updateParse(buildingUpper, parse, rect, ind)
parse.tiers(ind,:) = buildingUpper;
parse.rect(ind, :) = rect;
for i = 2:length(parse.order), 
    this = parse.order(i);
    below = parse.order(i-1);
    parse.tiers(this,:) = min(parse.tiers(this,:), parse.tiers(below,:));
end
parse.upper = min(double(parse.tiers(parse.order(end),:)), parse.upper);