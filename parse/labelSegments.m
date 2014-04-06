%--------------------------------------------------------------------------
%                                                 Perform initial labelling
%--------------------------------------------------------------------------
function label = labelSegments(data)
% Assign each seed its majority label
% 1 backgroud, 0 unknown, 2:N+1 buildings
numSeeds = length(data.seeds);
numSegments = max(data.segments(:));
seed2segment = zeros(numSeeds, numSegments);
label = zeros(size(data.labels), 'uint32');

% Create a seed map
for i = 1:length(data.seeds), 
    fg = data.seeds{i}; %x, y format
    pixelInd = sub2ind(size(label), fg(:,2), fg(:,1));
    segmentId = data.segments(pixelInd);
    for j = 1:length(segmentId), 
        seed2segment(i,segmentId(j)) =  seed2segment(i,segmentId(j)) + 1;
    end
end

% Assign labels to segments
for i = 1:numSegments,
    [maxVal, maxInd] = max(seed2segment(:,i));
    if maxVal == 0 % the superpixel has no seeds
        label(data.segments == i) = 0;
    else
        label(data.segments == i) = maxInd + 1;
    end
end

% All pixels above or below the middle region are background
for i = 1:size(label,2)
    label(1:data.region(i,1),i) = 1;
    label(data.region(i,2):end,i) = 1;
end