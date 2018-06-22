function out = initializeWindows(image,mask)
    %Create Local Windows
    boundary = bwboundaries(mask);
    bounds = boundary{1,1};
    [m,n,d] = size(image);
    numWindows = floor(m*n/10000);
    [cx,cy,~] = improfile(image,bounds(:,2),bounds(:,1),numWindows);
    floor(cx);
    floor(cy);
    centers{1,numWindows} = []; %[x,y]
    k = 3;
    labImg = rgb2lab(image);
    antimask = ~mask;
    distmask = bwdist(mask);
    distantimask = bwdist(antimask);
    Pc{1,numWindows} = [];
    ShapeM{1,numWindows} = [];
    ShapeC{1,numWindows} = [];
    Fc{1,numWindows} = 0;
    for p = 1:numWindows
        centers{1,p} = [cx(p),cy(p)];
        imgW = labImg(cy(p)-20:cy(p)+20,cx(p)-20:cx(p)+20,:);
        w = zeros([41 41]);
        x = floor(cx(p))-20;
        y = floor(cy(p))-20;
        f = [];
        b = [];
        %get foreground and background pixels
        for i = 0:40
            for j = 0:40
                lab = labImg(y+i,x+j,:);
                if(mask(y+i,x+j) == 1 && distantimask(y+i,x+j)>=5) %foreground
                   f = cat(1,f,lab);
                elseif(mask(y+i,x+j) == 0 && distmask(y+i,x+j)>=5) %background
                   b = cat(1,b,lab);
                end
            end
        end
        %color model
        [m,n,d] = size(f);
        f = reshape(f,[m*n d]);
        [m,n,d] = size(b);
        b = reshape(b,[m*n d]);
        fgmm = fitgmdist(f,k,'RegularizationValue',0.00001);
        bgmm = fitgmdist(b,k,'RegularizationValue',0.00001);
        Gmm{p,1} = fgmm;
        Gmm{p,2} = bgmm;
        imgW = reshape(imgW,[41*41 3]);
        Pcf = pdf(fgmm,imgW);
        Pcb = pdf(bgmm,imgW);
        PcW = zeros([length(imgW) 1]);
        for px = 1:length(imgW)
            PcW(px) = Pcf(px)/(Pcf(px)+Pcb(px));
        end
        Pc{1,p} = PcW;
        %color confidence 
        sigc = 20;
        conf = zeros([length(imgW) 1]);
        wc = zeros([length(imgW) 1]);
        maskW = mask(cy(p)-20:cy(p)+20,cx(p)-20:cx(p)+20);
        maskW = reshape(maskW,[length(imgW) 1]);
        distantimaskW = distantimask(cy(p)-20:cy(p)+20,cx(p)-20:cx(p)+20);
        distantimaskW = reshape(distantimaskW,[length(imgW) 1]);
        for px = 1:length(imgW)
            d = distantimaskW(px);
            wc(px) = exp(-(d^2)/sigc^2);
            conf(px) = abs(maskW(px)-PcW(px))*wc(px);
        end
        fc = 1-(sum(conf)/sum(wc));
        Fc{1,p} = fc;
        %shape model
        fcutoff = 0.85;
        sigmin = 2;
        sigmax = 41;
        a = (sigmax-sigmin)/(1-fcutoff)^2;
        if(fc >= 0 && fc <= fcutoff)
            sigs = sigmin;
        else
            sigs = sigmin + a * (fc-fcutoff)^2;
        end
        fs = zeros([length(imgW) 1]);
        for px = 1:length(imgW)
            d = distantimaskW(px);
            fs(px) = 1-exp(-d^2/sigs^2);
        end
        ShapeM{1,p} = reshape(fs,[41 41])+...
            mask(cy(p)-20:cy(p)+20,cx(p)-20:cx(p)+20);
        ShapeC{1,p} = reshape(fs,[41 41]);
    end
    out = {centers,Pc,Fc,Gmm,ShapeM,ShapeC};
end