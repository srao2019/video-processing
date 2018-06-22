%Load all images
a=dir([strcat('Input/*.jpg')]);
numFrames=size(a,1);
Frames{1,numFrames} = [];
for i = 1:numFrames
     Frames{1,i} = imread(strcat('Input/',num2str(i),'.jpg'));
     %Tried padding images for set2 wasn't very helpful
%      img = padarray(img,[20 20],0,'pre');
%      img = padarray(img,[40 40],0,'post');
%      Frames{1,i} = img;
end
%get original mask
mask = roipoly(Frames{1,1});
%%
windowSize = 41;
models = initializeWindows(Frames{1,1},mask);
f = figure;imshow(Frames{1,1});
hold on;
bdry = bwboundaries(mask,'noholes');
b = bdry{1,1};
plot(b(:,2), b(:,1), 'r', 'LineWidth', 2);
hold off;
saveas(f,'Output/1.jpg');
%update windows and get mask for next frame
fgmask = mask;
for i = 1:numFrames-1
    j = i+1;
    models = updateWindows(Frames{1,i},Frames{1,j},...
        fgmask,models,windowSize);
    results = combinedFgMask(Frames{1,j},models,windowSize);
    fgmask = results{1,1};
    bound = results{1,2};
    f = figure;imshow(Frames{1,j});
    hold on;
    bdry = bwboundaries(bound,'noholes');
    [max_size, max_index] = max(cellfun('size', bdry, 1));
    b = bdry{max_index,1};
    plot(b(:,2), b(:,1), 'r', 'LineWidth', 2);
    hold off;
    saveas(f,strcat('Output/',num2str(j),'.jpg'));
end
    
%% make mp4 of output frames
outputVideo = VideoWriter('Output/results.mp4','MPEG-4');
open(outputVideo)

for i = 1:numFrames
   img = imread(strcat('Output/',num2str(i),'.jpg'));
   writeVideo(outputVideo,img)
end

close(outputVideo)
    
