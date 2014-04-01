function showAnno(anno, imageSet)
% SHOWANNO shows all the annotations for a particular city
%   SHOWANNO(CITY) interactively loads and displays all the images and
%   annotations for the CITY. Press arrow keys to move from one image to
%   another. Pressing SPACE toggles the overlay of the boundaries on the
%   image.
%
% Author: Subhransu Maji

conf = skylineConfig();

if nargin > 1, 
    setId = find(ismember(anno.meta.imageSet, imageSet));
    anno = selectAnno(anno, anno.object.imageSet == setId);
end

global g;
g.conf = conf;
g.anno = anno;
g.curId = 1;
g.edgeOverlay = false;
g.showSeeds = true;
g.se = strel('diamond', 3);
numImages = length(anno.object.image);

while(1),
    drawAnno();
    while 1,
        [~,~,b] = ginput(1);
        if isscalar(b)
            break;
        end
    end
    
    % Loop and display
    switch b
        case 29
            if g.curId < numImages
                g.curId = g.curId + 1;
            end
        case 28
            if g.curId > 1
                g.curId = g.curId - 1;
            end
        case 27
            break;
        case 'e'
            g.edgeOverlay = ~g.edgeOverlay;
        case 's'
            g.showSeeds = ~g.showSeeds;
    end
end


%--------------------------------------------------------------------------
%                                        draw the annotations for the image
%--------------------------------------------------------------------------
function drawAnno()
global g;

i = g.curId;

% Load annotations corresponding to this data
city = g.anno.meta.cities{g.anno.object.cityId(i)};
im = imread(fullfile(g.conf.path.image, city, g.anno.object.image{i}));
load(fullfile(g.conf.path.labels, city, g.anno.object.label{i}));
load(fullfile(g.conf.path.regions, city, g.anno.object.region{i}));
bRegion = opt_path1;


% Add a red boundary on the buildings
if g.edgeOverlay,
    ee = (labels == 0);
    ee = imdilate(ee,g.se); 
    im(ee > 0) = 255;
end

% Plot the image and the boundaries
figure(1); clf;
vl_tightsubplot(1,2,1);
imagesc(im); axis image off; hold on;

% Plot upper and lower tiers
plot(1:size(bRegion,1), bRegion(:,1),'w-','LineWidth', 4);
plot(1:size(bRegion,1), bRegion(:,1),'b--','LineWidth',4);

plot(1:size(bRegion,1), bRegion(:,2),'w-','LineWidth', 4);
plot(1:size(bRegion,1), bRegion(:,2),'b--','LineWidth',4);

% Display the seeds if enabled
if g.showSeeds, 
    load(fullfile(g.conf.path.seeds, city, g.anno.object.seeds{i}));
    for s = 1:length(fgpixels), 
        plot(fgpixels{s}(:,1), fgpixels{s}(:,2), 'y.');
    end
end
handle=title(sprintf('City: %s (%i/%i)  Image: %i/%i ImageSet:%i', city, ...
                         g.anno.object.cityId(i), max(g.anno.object.cityId), ...
                         i, length(g.anno.object.image), ...
                         g.anno.object.imageSet(i)));
set(handle, 'Interpreter','none');

% Plot the segmentation labels
vl_tightsubplot(1,2,2);
imagesc(labels); axis image off;
title('Ground truth labels');
colormap(hot);