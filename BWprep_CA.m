function BW5 = BWprep_CA(file,mask,rotationInfo,plotQ) % Function name

if plotQ
    pause on
    pausetime = 2;
end

%show original image
im = im2double(rgb2gray(imread(file ))); %convert to grayscale

if plotQ
    figure; imshow(im); % Display image
    pause(pausetime); close
end

%% apply mask
[imcropped,~] = imcrop(im,mask); 

if plotQ
    figure; imshow(imcropped); %Display
    pause(pausetime); close
end

%% Rotate image
BW1 = rotateAround_CA(imcropped,rotationInfo(1),rotationInfo(2),rotationInfo(3));
BW2 = BW1( 1:rotationInfo(1),: ); %truncate image so only droplet remains

if plotQ
    figure; imshow( BW2 ); %display
    pause(pausetime); close
end


%% convert to BW
[counts,x] = imhist(BW2,32); %get a histogram of the brightness levels
% figure; stem(x,counts) %can display this histogram if desired
T = otsuthresh(counts); %determine a threshold based on histogram
BW3 =  imbinarize(BW2,T); %convert to binary
% BW3 = imbinarize(BW2,'adaptive','ForegroundPolarity','dark','Sensitivity',0.4);

if plotQ
    figure; imshow(BW3); %display
    pause(pausetime); close
end
    
%% identify and fill in droplet
L = bwlabeln(1-BW3, 4); %label white spots
S = regionprops(L, 'Area'); %measure area of spots
BW4 = ismember(L, find([S.Area] == max( [S.Area]) )); %find largest spot
% BW4(1,:) = 1; % Turn First Row White
% figure; imshow( BW4 ) %display

BW4(end+1,:) = ones(1,size(BW4,2)); % Turn last row black to help fill in holes (temporary)

BW5 = imfill( BW4, 'holes' ); %fill holes in droplet
BW5(end,:) = []; %remove the extra line that we added to help fill in the holes



if plotQ
    figure; imshow( BW5 ); %display
    pause(pausetime); close
end



end