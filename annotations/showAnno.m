function showAnno(anno, imageSet)
% SHOWANNO interactively displays the annotations
%   SHOWANNO(ANNO, IMAGESET) interactively shows all the annotations in
%   ANNO that belong to images in IMAGESET. Press 'h' for help and 'esc' 
%   to exit the display.
%
% Author: Subhransu Maji

conf = skylineConfig();

if nargin > 1, 
    setId = find(ismember(anno.meta.imageSet, imageSet));
    anno = selectAnno(anno, anno.object.imageSet == setId);
end

% Global variables to keep state
global g;
g.conf = conf;
g.anno = anno;
g.curId = 1;
g.showSeeds = true;
g.se = strel('diamond', 3);
numImages = length(anno.object.image);

% Loop over images and display
while(1),
    drawAnno();
    while 1,
        [~,~,b] = ginput(1);
        if isscalar(b)
            break;
        end
    end
    % Change state depending on input
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
        case 's'
            g.showSeeds = ~g.showSeeds;
        case 'g' %jump to a specified image index
            answer = str2double(inputdlg('Enter index:'));
            if(~isempty(answer))
                answer = round(answer);
                if(answer > 0 && answer <= numImages)
                    g.curId = answer;
                end
            end
        case 'h'
            displayHelp();
    end
end

%--------------------------------------------------------------------------
%                                            display help message for usage
%--------------------------------------------------------------------------
function displayHelp()
fprintf('Shortcut key bindings for display\n');
fprintf('    h: print this help message\n');
fprintf('  esc: exit display\n');
fprintf(' Navigation:\n');
fprintf('   ->: next image\n');
fprintf('   <-: prev image\n');
fprintf('    g: jump to image\n');
fprintf(' Display:\n');
fprintf('    s: toggle seeds\n');
    
%--------------------------------------------------------------------------
%                                        draw the annotations for the image
%--------------------------------------------------------------------------
function drawAnno()
global g;
i = g.curId;
data = getData(g.conf, g.anno, i);

% Plot the image
figure(1); clf;
vl_tightsubplot(1,2,1);
imagesc(data.im); axis image off; hold on;

% Plot upper and lower tiers
plot(1:size(data.region,1), data.region(:,1),'w-','LineWidth', 2);
plot(1:size(data.region,1), data.region(:,1),'b--','LineWidth',2);

plot(1:size(data.region,1), data.region(:,2),'w-','LineWidth', 2);
plot(1:size(data.region,1), data.region(:,2),'b--','LineWidth',2);

% Display the seeds
if g.showSeeds, 
    for s = 1:length(data.seeds), 
        plot(data.seeds{s}(:,1), data.seeds{s}(:,2), 'y.');
    end
end

% Display info
handle=title(sprintf('City: %s (%i/%i)  Image: %i/%i ImageSet:%i', data.city, ...
                     g.anno.object.cityId(i), max(g.anno.object.cityId), ...
                     i, length(g.anno.object.image), ...
                     g.anno.object.imageSet(i)));
set(handle, 'Interpreter','none');

% Display the segmentation labels
vl_tightsubplot(1,2,2); % from vlfeat
imagesc(data.labels); axis image off;
title(sprintf('Ground truth labels (%i x %i px)', size(data.labels,2), size(data.labels,1)));
colormap(hot);