function fgpixels = getAutoSeeds(conf,data)

    segments = data.segments;
    im = data.im;
    opt_path1 = data.region;
    
    K = conf.param.autoseeds.K;
    NS = conf.param.autoseeds.NS;
    segPerPart = conf.param.autoseeds.segPerPart;
    wfactor = conf.param.autoseeds.wfactor;

    [r,c] = size(segments);
    for iter=1%:2
        % Get top and bottom tier to be labelled 0.
        for i=1:c
            segments([1:opt_path1(i,1) opt_path1(i,2):r],i) = 0;
        end
        midRegion = length(find(segments ~= 0));
        
        sp = regionprops(segments,rgb2gray(im),'Area','Centroid','PixelIdxList','WeightedCentroid','BoundingBox');
    

%         load([data_dir 'Annotations/' city '/label_' filename(1:end-4) '.mat'],'labels');
        tmp = cat(1, sp.WeightedCentroid);
        [spc,spci] = sort(tmp(:,1));
        clear tmp;
        newArea = [sp.Area];
        newArea = newArea(spci);
        part = 1;
        prevIndx = 1;
        numIp = 0;
        meanFp = [];
        fgpixels = {};
        while 1
            if isempty(find(spc > part*(c/K)))
                break;
            end
            currIndx = min(find(spc > part*(c/K))) - 1;
            [spas,spai] = sort(newArea(prevIndx:currIndx),'descend');
            for i=1:min(segPerPart,length(spas))
                if spas(i) <= 10
                    break;
                else
                    indx = spci(spai(i)+prevIndx-1);
                    [I,J] = ind2sub([r,c],sp(indx).PixelIdxList(randi(length(sp(indx).PixelIdxList),...
                            [1 min(spas(i),NS)])));
                    tind = find(J > (spc(spai(i)+prevIndx-1)-(c/(K*wfactor))) & J < (spc(spai(i)+prevIndx-1)+(c/(K*wfactor))));
                    if isempty(tind)
                        continue;
                    end
                    fgpixels{numIp+1} = [J(tind) I(tind)];
                    sliclab(sp(indx).PixelIdxList) = numIp+1;
                    meanFp = [meanFp;round(sp(indx).Centroid)];
                    numIp = numIp + 1;
                end
            end
            prevIndx = currIndx + 1;
            part = part + 1;
        end
        
    end

end