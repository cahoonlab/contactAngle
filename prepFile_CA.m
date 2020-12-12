function [outputFileName] = prepFile_CA( filePath, substrateID, interestingImages, CAregion )
%Prepares a file for doing projected area and contact angle measurements
%   filePath: exact file path
%   substrateID: name for informational purposes
%   interestingImages:
%       example: '764897173_249.8.png' will do one specific image
%       example: '*_*.png' will do all png images with an underscore
%   CAregion (contact angle parameters) as [start step end]:
%       example: [1 1 Inf] will do all images
%       example: [1 10 100] will do images 1-100 but only do every 10
%       example: [0 0 0] will not do CA analysis
%       example: [1 50 Inf; 2000 5 Inf] will do all images (step size 50)
%       plus 2000 to the end with step size of 5. It's okay that they will
%       double up.


%%NOTE: Be sure that the camera does not pan at all during sequence of images.


sampImFreq = 1000; %if doing more than one image, how many images to skip before doing another baseline sample?


%% Get stuff ready
%check to make sure that folder actually exists.  Warn user if it doesn't.
if ~isdir(filePath)
  errorMessage = sprintf('Error: The following folder does not exist:\n%s', filePath);
  uiwait(warndlg(errorMessage));
end


%get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(filePath, interestingImages); 
File = dir(filePattern);
[~,reindex] = sort(str2double(regexp({File.name},'\d+','match','once'))); %sort them smartly
FilesOrdered=File(reindex);

temperatureDataTF = length(strfind(FilesOrdered(1).name,'_'))==2;

clear reindex filePattern File

%% Load representative images and get mask and baseline information
%*******************************************************************************

% Load and crop the images
sampImIdx = 1:sampImFreq:length(FilesOrdered);
if sampImIdx(end) ~= length(FilesOrdered)
    sampImIdx = [sampImIdx length(FilesOrdered)];
end

%repIm is short for representative image
for sii = 1:length(sampImIdx)
    repIm(sii).Idx = sampImIdx(sii);
    repIm(sii).Name = strcat(filePath,'\',FilesOrdered(repIm(sii).Idx).name); %get name
    repIm(sii).BW = im2double(rgb2gray(imread(repIm(sii).Name))); %load and convert to grayscale
    
    % Crop the images to make sure we get all important parts
    figure; imshow(repIm(sii).BW); title('Select the area to analyze. Double click when done.')
    hBox = imrect; %handle for rectangle
    maskXPositions = wait(hBox); close %wait for double click
    repIm(sii).maskX = maskXPositions(1);
    repIm(sii).maskY = maskXPositions(2);
    repIm(sii).maskWidth = maskXPositions(3);
    repIm(sii).maskHeight = maskXPositions(4);
    

end; clear sii hBox

%% Merge the masks
maskX1 = min([repIm.maskX]);
maskY1 = min([repIm.maskY]);
maskX2 = max([repIm.maskX] + [repIm.maskWidth]);
maskY2 = max([repIm.maskY] + [repIm.maskHeight]);
masterMaskPosition = [maskX1 maskY1 maskX2-maskX1 maskY2-maskY1];
clear maskX1 maskX2 maskY1 maskY2 maskPositions

%% Do the cropping and select baselines

for sii=1:length(sampImIdx)
    [imcropped, ~] = imcrop(repIm(sii).BW,masterMaskPosition);
    repIm(sii).BWcrop = imcropped;
    
    figure; imshow(imcropped); title('Select the baseline with two points. Push enter when done.')
    [baseX, baseY, ~] = impixel; close %user selects substrate baseline


    
    if ~isempty(baseX)
        fit = polyfit(baseX,baseY,1);
        repIm(sii).baseSlope = fit(1);
        repIm(sii).baseInt = fit(2);
        repIm(sii).centerX = mean(baseX);
        repIm(sii).centerY = mean(baseY);
        repIm(sii).baseX = baseX;
        repIm(sii).baseY = baseY;
    end
end; clear sii imcropped baseX baseY fit

%% Average the baselines and find the rotation position and angle

masterBaseSlope = mean([repIm.baseSlope]);
% masterBaseInt = mean([repIm.baseInt]);
masterBaseAngle = atand( masterBaseSlope); %rotation angle (determined from slope)
%Negative slope and negative angle mean a positive slope. Thus, rotate clockwise.

masterBasePosX = round(mean([repIm.centerX]));
masterBasePosY = round(mean([repIm.centerY]));
        
%% Convert to black and white
%*******************************************************************************
% [counts,x]=imhist(imcropped2,32); %get a histogram of the brightness levels
% figure; stem(x,counts) %can display this histogram if desired
% T = otsuthresh(counts); %determine a threshold based on histogram
% BW =  imbinarize(imcropped2,T); %convert to binary
pausetime = 1;

for sii=1:length(sampImIdx)
    %%Rotate image using selection made earlier
    %*******************************************************************************
    %Note: doing rotation and truncation before converting to BW to get a
    %better conversion.
    BW1 = rotateAround_CA(repIm(sii).BWcrop,masterBasePosY,masterBasePosX,masterBaseAngle);
%     figure; imshow(BW1)
    BW2 = BW1( 1:masterBasePosY,: ); %truncate image so only droplet remains
%     repIm(sii).BW2 = BW2;

    
    if pausetime ~=0
        figure; imshow( BW2 ); %display
        pause(pausetime)
        close
    end
    
    
    
    %%Convert to black and white
%     BW3 = imbinarize(BW2,'adaptive','ForegroundPolarity','dark','Sensitivity',0.4);
    [counts,x] = imhist(BW2,32); %get a histogram of the brightness levels
%     figure; stem(x,counts) %can display this histogram if desired
    T = otsuthresh(counts); %determine a threshold based on histogram
    BW3 =  imbinarize(BW2,T); %convert to binary
    
    
    if pausetime ~= 0
        figure; imshow(BW3); %display
        pause(pausetime)
        close
    end
%     repIm(sii).BW3 = BW3;
    
    %%Identify and fill in droplet
    %*******************************************************************************
    
    L = bwlabeln(1-BW3, 4); %label white spots
    S = regionprops(L, 'Area'); %measure area of spots
    BW4 = ismember(L, find([S.Area] ==max( [S.Area]) )); %find largest spot
%     BW4(1,:) = 1; % Turn First Row White
    % figure; imshow( BW4 ) %display

    BW4(end+1,:) = ones(1,size(BW4,2)); % Turn last row black to help fill in holes (temporary)
    
    BW5 = imfill( BW4, 'holes' ); %fill holes in droplet
    BW5(end,:) = []; %remove the extra line that we added to help fill in the holes
    
    if pausetime ~=0
        figure; imshow( BW5 ); %display
        pause(pausetime)
        close
    end
    
    DoCA=0;
    if length(FilesOrdered)>1 && DoCA==1
        try
            %%Get best fit circle for final
            %*******************************************************************************
            % val is [centerY, centerX, radius]
            [val,status, message] = fminsearch(@(cntr_radius)...
            CA_FitFun( cntr_radius(1:2), cntr_radius(3), BW5), ...
            [size(BW5,1), size(BW5,2)/2, 50], optimset( 'display','iter' ) )  
        catch ME
            disp(ME.identifier)
            continue
        end
        
        
        repIm(sii).CA = acosd((val(1)-size(BW5,1))/val(3)); % Contact Angle in degrees

        crcl = CA_Circle( val(1:2), val(3), size(BW5) ); %generate optimized circle

        if pausetime ~=0
            figure; imagesc( 10*crcl+BW5 ); %display
            axis equal %so you don't skew the image
            imfilename = strsplit(repIm(sii).Name,'\');
            title(sprintf('%s (%s) Contact Angle: %.1f%c',strrep(substrateID,'_','\_'),strrep(imfilename{end},'_','\_'),repIm(sii).CA,char(176)))
            pause(pausetime)
            close
        end
    else
        
    end
        
end; %clear BW1 L S BW2 BW3 BW4 imfilename crcl sii
% clear repIm

%% Initialize final output structure

Output(length(FilesOrdered)).name = [];
Output(length(FilesOrdered)).time = [];
Output(length(FilesOrdered)).pressure = [];
if temperatureDataTF
    Output(length(FilesOrdered)).temperature = [];
end
Output(length(FilesOrdered)).area = [];
Output(length(FilesOrdered)).fit = [];
Output(length(FilesOrdered)).height = [];
Output(length(FilesOrdered)).width = [];
Output(length(FilesOrdered)).img = [];
Output(length(FilesOrdered)).ca = [];
Output(length(FilesOrdered)).crcl = [];

clear BW5



%% save the data
cd(filePath)
outputFileName = strcat(substrateID,'_output');

doesfileexist = eq(exist(strcat(outputFileName,'.mat'),'file'),2);
filenum = 1; tempOutputFileName = outputFileName;
while doesfileexist
    tempOutputFileName = sprintf('%s%i',outputFileName,filenum);
    doesfileexist = eq(exist(strcat(tempOutputFileName,'.mat'),'file'),2);
    filenum = filenum+1;
end
outputFileName = tempOutputFileName;

save(outputFileName,'filePath','substrateID','interestingImages','CAregion','FilesOrdered','maskXPositions','masterBaseAngle','masterBasePosX','masterBasePosY','masterBaseSlope','masterMaskPosition','Output','temperatureDataTF')


end

