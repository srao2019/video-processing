function Pc = colorModel(window,img,mask)
    Pc = [];
    k = 3;
    lab = rgb2lab(img(window(1,1):window(1,end),...
        window(end,1):window(end,end),:));
    [m,n,d] = size(lab);
    lab = reshape(lab,[m*n d]);
    [m,n] = size(window);
    window = reshape(window,[m*n 1]);
    [m,n] = size(mask);
    mask = reshape(mask,[m*n 1]);
    f = [];
    b = [];
    for i = 1:length(lab)
        if(mask(window(i)) == 1) %foreground
           cat(1,f,lab(i,1:3));
        else
            cat(1,b,lab(i,1:3));
        end
    end
    disp(f);
    disp(b);
    fgmm = fitgmdist(f,k);
    bgmm = fitgmdist(b,k);
    disp(fgmm);
    disp(bgmm);
    
    
    
            
    
    
    

    