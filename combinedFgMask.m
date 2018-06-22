function out = combinedFgMask(image,models,wSize)
    centers = models{1,1};
    numWindows = length(centers);
    pc = models{1,2};
    ShapeM = models{1,5};
    fs = models{1,6};
    mask = models{1,7};
    Pf{1,numWindows} = [];
    for p = 1:numWindows
        centerX = floor(centers{1,p}(1));
        centerY = floor(centers{1,p}(2));
        maskW = mask(centerY-20:centerY+20,centerX-20:centerX+20);
        maskW = reshape(maskW, [wSize*wSize 1]);
        PfW = zeros([wSize*wSize 1]);
        pcw = pc{1,p};
        fsw = fs{1,p};
        for px = 1:(wSize*wSize)
          PfW(px) = fsw(px)*maskW(px) + (1-fsw(px))*pcw(px);
        end    
        Pf{1,p} = PfW;
    end
    [m,n,~] = size(image);
    PFg = zeros([m n]);
    for i = 1:m
        for j = 1:n
            pf = []; %foreground probabilities
            dist = []; %distances from centers
            for p = 1:numWindows
                cnx = floor(centers{1,p}(1));
                cny = floor(centers{1,p}(2));
                PfW = reshape(Pf{1,p},[41 41]);
                if(i >= cny - 20 && i <= cny + 20 &&...
                        j >= cnx - 20 && j <= cnx +20) 
                    %pixel is in window
                    iW = i - (cny - 20)+1;
                    jW = j - (cnx - 20)+1;
                    d = sqrt((cnx - j)^2+(cny - i)^2);
                    dist = cat(1,dist,d);
                    pf = cat(1,pf,PfW(iW,jW));
                end
            end
            pf = reshape(pf,[1 length(dist)]);
            PFg(i,j) = sum(pf*dist)/ sum(dist);
        end
    end
    out{1,1} = im2bw(PFg);
    %threshold values
    for i = 1:m
        for j = 1:n
            if(PFg(i,j) >= 0.0001)
                PFg(i,j) = 1;
            else
                PFg(i,j) = 0;
            end
        end
    end
    %PFg = round(PFg);
    fgmask = im2bw(PFg);
    fgmask = bwmorph(fgmask,'clean');
    fgmask = bwmorph(fgmask,'fill');
    fgmask = bwmorph(fgmask,'bridge');
    fgmask = imfill(fgmask,'holes');
    out{1,2} = fgmask;
end