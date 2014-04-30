%% Get data for a given image
conf = skylineConfig();
anno = loadAnno();
dataId = 36; 
data = getData(conf, anno, dataId);
gtLabels = data.gtLabels;
fprintf('Loaded data for id=%i\n', dataId);

%% Prepare data (unary potentials) for reuse with multiple methods
data = prepareData(conf, data); % This will be called internally by skylineParse if unaries are not precomputed
    
%% Get parses using rectangle/refined MRF
rparse = skylineParse(conf, data, 'rectangle');

%% Get parses using tiered MRF
tparse = skylineParse(conf, data, 'tiered');

%% Get parses using standard MRF
mparse = skylineParse(conf, data, 'standard');

%% Display parses
figure;
% Image and ground truth
vl_tightsubplot(2,5,1,'Margin',0.01);
imagesc(data.im); axis image off;
title('image','fontSize',16);

vl_tightsubplot(2,5,6,'Margin',0.01);
imagesc(gtLabels); axis image off;
title('ground-truth','fontSize',16);

% Rectangle MRF
vl_tightsubplot(2,5,2,'Margin',0.01);
showParse(data.im, rparse.rect);
evals = evalLabels(parse2label(rparse.rect, data), gtLabels);
title('rectangle MRF','fontSize',16);

vl_tightsubplot(2,5,7,'Margin',0.01);
imagesc(parse2label(rparse.rect, data)); axis image off;
title(sprintf('MAO=%.2f', evals.mao*100),'fontSize',16);

% refined MRF
vl_tightsubplot(2,5,3,'Margin',0.01);
showParse(data.im, rparse.refined);
evals = evalLabels(parse2label(rparse.refined, data), gtLabels);
title('refined MRF','fontSize',16);

vl_tightsubplot(2,5,8,'Margin',0.01);
imagesc(parse2label(rparse.refined, data)); axis image off;
title(sprintf('MAO=%.2f', evals.mao*100),'fontSize',16);

% tiered MRF
vl_tightsubplot(2,5,4,'Margin',0.01);
showParse(data.im, tparse.tiered);
evals = evalLabels(parse2label(tparse.tiered, data), gtLabels);
title('tiered MRF','fontSize',16);

vl_tightsubplot(2,5,9,'Margin',0.01);
imagesc(parse2label(tparse.tiered, data)); axis image off;
title(sprintf('MAO=%.2f', evals.mao*100),'fontSize',16);

% standard MRF
vl_tightsubplot(2,5,5,'Margin',0.01);
overlayParse(data.im, mparse); axis image off;
evals = evalLabels(mparse, gtLabels);
title('standard MRF','fontSize',16);

vl_tightsubplot(2,5,10,'Margin',0.01);
imagesc(mparse); axis image off;
title(sprintf('MAO=%.2f', evals.mao*100),'fontSize',16);