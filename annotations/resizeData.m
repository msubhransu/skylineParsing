function data = resizeData(data, scale)
[~,w, ~] = size(data.im);
data.im  = imresize(data.im, scale);
[~,tw, ~] = size(data.im);

% Resize labels
data.labels = imresize(data.labels, scale, 'nearest');

% Upper and lower boundaries
ty = round(interp1(linspace(1, tw, w), data.region(:,1)'*scale, 1:tw, 'pchip'));
by = round(interp1(linspace(1,tw, w), data.region(:,2)'*scale, 1:tw, 'pchip'));
data.region = [ty' by'];

% Resize seeds
for i = 1:length(data.seeds), 
    data.seeds{i} = round(data.seeds{i}*scale);
end

% Resize gtLabels
data.gtLabels = imresize(data.gtLabels, scale, 'nearest');
