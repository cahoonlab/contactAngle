%This project was inspired by Ken Osborne (2008). Some sections are exact duplications. 
%Most sections required minor/major modifications. Source code is available here: 
%https://web.wpi.edu/Pubs/E-project/Available/E-project-042508-083811/unrestricted/MQP.pdf

%% Add a job to the queue

substrateID = 'SiNatOx_APTES_example'; % (e.g. SiNatOx_1) - for labeling purposes
interestingImages = '*_*.png'; %image name (or '*_*.png' to find all png in folder)

filePath = pwd; % get current working directory (make sure you're in the folder with all the images)


% In some cases, you may not care about contact angles for some images. Most 
% of the time this is with the long recordings. In those cases you should 
% have thumbnails that are numbered 1,2,3,... that will help you figure out 
% what values to put here.
CAregion = [1 1 Inf]; %Default [1 1 Inf]. [Beg Step End; Beg Step End]

outputFile = prepFile_CA(filePath,substrateID,interestingImages,CAregion); %generate a blank file where all the output information will be added.

try
    queue(end+1,:) = {filePath outputFile}; %add the above to a queue
catch
    queue = {filePath outputFile}; %queue has not started yet. Start it.
end


%%%%%%%%%%%%%%%  add many samples into the queue. It will save you time in the long-run.

%% Perform CA analysis on the queue

for ii = 1:size(queue,1)
    fprintf('starting %s (%i)\n',queue{ii,2},ii)
    analyze_CA(queue{ii,1},queue{ii,2});
end; clear ii


% Results will be automatically saved in each folder.



%% optional code for plotting the image and circle post-simulation
pltIdx = 1;
pltCrcl = circle_CA( Output(pltIdx).crcl(1:2), Output(pltIdx).crcl(3), size(Output(pltIdx).img) ); %generate optimized circle
figure; imagesc( 10*pltCrcl+Output(pltIdx).img ); %display
axis equal %so you don't skew the image