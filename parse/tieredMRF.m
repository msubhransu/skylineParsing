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
parse.order = [];
taken = false(1, numBuildings);

% Greedy labelling of all the pixels
currLower = tierLower;
currUpper = tierUpper;
tic;
while any(~taken), 
    ind = findBottomBuilding(currLower, seeds, taken);
    buildingUpper = initUpperBoundary(conf, data, currLower, tierUpper, ind);
    currLower = buildingUpper;
    currUpper = min(currUpper, currLower);
    parse.tiers(ind, :) = currLower;
    taken(ind) = true;
    parse.order = [parse.order; ind];
    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('Initial parse, building %i/%i\n', sum(taken), numBuildings));
    end
end
parses.initial = parse;
label = parse2label(parses.initial,data);
fprintf('%.2fs intial parse..',toc);


% Refine the rectangles using tiered labelling
tic;
maxIter = 2*numBuildings;
for i = 1:maxIter,
    ind = parse.order(mod(i-1, numBuildings)+1);
    buildingUpper = refineTiers(conf, data, parse, ind, label);
    parse = updateParse(buildingUpper, parse, ind);
    label = parse2label(parse, data);
    
    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('Refining parse, iter %i/%i\n', i, maxIter));
    end
end
parses.tiered = parse;
fprintf('%.2fs refinement.\n',toc);

% Refine the rectangles
label = parse2label(parses.initial, data);
parse = parses.initial;
tic;
maxIter = 2*numBuildings;
for i = 1:maxIter,
    ind = parse.order(mod(i-1, numBuildings)+1);
    buildingUpper = refineRectangle(conf, data, parse, ind, label);
    parse = updateParse(buildingUpper, parse, ind);
    label = parse2label(parse, data);

    % Display progress
    if conf.display
        figure(1); clf;
        showParse(data.im, parse);
        title(sprintf('Refining parse, iter %i/%i\n', i, maxIter));
    end
end
parses.rect = parse;
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