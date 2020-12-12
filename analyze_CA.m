function analyze_CA( filePath, OutputFile, varargin)
%Do the projected area and contact angle analysis on images. Should have
%prepared the data first with the prepFileCA.m function.
%CAregionOverride should be in format
%[startIdx1,step1,endIdx1;startIdx2,step2,endIdx2]

cd(filePath)
if ~strcmp(OutputFile(length(OutputFile)-4:end),'.mat')
    OutputFile = strcat(OutputFile,'.mat');
end
OutputLoaded = load(OutputFile);

Output = OutputLoaded.Output;

%%get the user defined values
CAregion = OutputLoaded.CAregion;
do_CA = true;
for vv = 1:length(varargin)
    if strcmp(varargin{vv},'CAregion') %Could do this in semi-manual mode
        CAregion = varargin{vv+1};
    end
end; clear vv varargin

if size(CAregion,1) == 1
    if CAregion == [0 0 0]
        do_CA = false;
    end
end

   
FilesOrdered = OutputLoaded.FilesOrdered;
substrateID = OutputLoaded.substrateID;



%% Prepare each image for analysis
tic
for im=1:length(FilesOrdered)
    baseFileName = FilesOrdered(im).name;
    Output(im).name=baseFileName;
    data_prep1=baseFileName(1:length(baseFileName)-4); %start extracting data from filenames
    data_prep2=strsplit(data_prep1,'_');
    %save time and pressure info from file name
    Output(im).time=str2double(data_prep2{1,1});
    Output(im).pressure=str2double(data_prep2{1,2});
    
    if OutputLoaded.temperatureDataTF
        Output(im).temperature=str2double(data_prep2{1,3});
    end
    
    %load image info
    fullFileName = fullfile(filePath, baseFileName);
%     fprintf(1, 'Now reading %s\n',baseFileName);
    
    if isempty(Output(im).img) %don't repeat
        Output(im).img=BWprep_CA(fullFileName,OutputLoaded.masterMaskPosition,[OutputLoaded.masterBasePosY,OutputLoaded.masterBasePosX,OutputLoaded.masterBaseAngle],false);
    end
    
    if rem(im,50)==0 % do a countdown
        fprintf('Finished %i of %s @ %0.1f min. Estimated time left: %0.1f min\n',im,substrateID,toc/60,toc/60/im*(length(FilesOrdered)-im));
    end
    
end; clear im 
tocp=toc;
fprintf('Preparation took %0.1f seconds\n',tocp)
clear tocp

clear baseFileName data_prep1 data_prep2 fullFileName


%% Do analysis
tic
for im=1:length(FilesOrdered)
%     BWim=Output(im).img;
    if or(or(isempty(Output(im).area),isempty(Output(im).height)),isempty(Output(im).width))
        [Output(im).area,Output(im).height,Output(im).width]=dimensions_CA(Output(im).img);
    end
    if rem(im,50)==0 % do a countdown
        fprintf('Finished %i of %s @ %0.1f min. Estimated time left: %0.1f min\n',im,substrateID,toc/60,toc/60/im*(length(FilesOrdered)-im));
    end
end; clear im
fprintf('General analysis took %0.1f seconds\n',toc)

%% Do contact angle analysis


if do_CA
    
    %get the indices of the images to analyze. Can specify multiple
    %sections with different step sizes.
    CAsToDo = [];
    for ii = 1:size(CAregion,1)
        CAsToDo = [CAsToDo (CAregion(ii,1):CAregion(ii,2):min(length(FilesOrdered),CAregion(ii,3)))];
    end
    CAsToDo = unique(CAsToDo);

    
    CApausetime = 0; %can have it show you each contact angle, but it isn't realistic when doing lots of images.
    
    tic
    CA_guess=[size(Output(1).img,1), size(Output(1).img,2)/2, 50]; %initial parameter guess [center of circle (Y), center of circle (X), radius]
    fprintf('Beginning contact angle analysis of %s.\n',substrateID)
    for im=CAsToDo
        if isempty(Output(im).ca) %don't repeat a calculation.
    %         BWim=Output(im).img;
            val=[]; %clear the variable memory
            try
                [val,~, ~] = fminsearch(@(cntr_radius)...
                fitfun_CA( cntr_radius(1:2), cntr_radius(3), Output(im).img), ...
                CA_guess, optimset( 'display','off' ) );  %'display' was 'iter'. Changed to save time.
                   
            catch ME
                if (strcmp(ME.identifier,'MATLAB:nomem'))
                    fprintf('Not enough memory on %i of %s @ %0.1f min.\n',im,substrateID,toc/60);
                end
                
                break
            end
            
            ca = acosd((val(1)-size(Output(im).img,1))/val(3));
            if isreal(ca)
                Output(im).ca = ca;
                Output(im).crcl = val;
                Output(im).fit=fitfun_CA(val(1:2), val(3), Output(im).img);
            end
    
            if CApausetime ~=0
                crcl = circle_CA( val(1:2), val(3), size(Output(im).img) ); %generate optimized circle
                figure; imagesc( 10*crcl+Output(im).img ); %display
                axis equal %so you don't skew the image
                title(sprintf('%s (output %i) Contact Angle: %.1f%c',strrep(substrateID,'_','\_'),im,Output(im).ca,char(176)))
                pause(CApausetime)
                close
            end
            

            if rem(im-CAsToDo(1),1)==0 % do a countdown
                prog = find(CAsToDo>im,1);
                if isempty(prog)
                    prog = 1;
                end
                fprintf('Finished %i of %s @ %0.1f min (%0.1f deg). Estimated time left: %0.1f min\n',im,substrateID,toc/60,Output(im).ca,toc/60/prog*(length(CAsToDo)-prog));
            end
        end
        
    end; clear im
    tocca=toc;
    fprintf('Contact angle analysis took %0.1f seconds\n',tocca);
    clear tocca

    clear CA_guess message status val
end
clear doCA

beep

%% save data
averageCA = mean([Output.ca])


interestingImages = OutputLoaded.interestingImages;
maskXPositions = OutputLoaded.maskXPositions;
masterBaseAngle = OutputLoaded.masterBaseAngle;
masterBasePosX = OutputLoaded.masterBasePosX;
masterBasePosY = OutputLoaded.masterBasePosY;
masterBaseSlope = OutputLoaded.masterBaseSlope;
masterMaskPosition = OutputLoaded.masterMaskPosition;
temperatureDataTF = OutputLoaded.temperatureDataTF;


save(OutputFile,'filePath','substrateID','interestingImages','CAregion','FilesOrdered','maskXPositions','masterBaseAngle','masterBasePosX','masterBasePosY','masterBaseSlope','masterMaskPosition','Output','temperatureDataTF')
[warnmsg, msgid] = lastwarn;
if strcmp(msgid,'MATLAB:save:sizeTooBigForMATFile')
    save(OutputFile,'filePath','substrateID','interestingImages','CAregion','FilesOrdered','maskXPositions','masterBaseAngle','masterBasePosX','masterBasePosY','masterBaseSlope','masterMaskPosition','Output','temperatureDataTF','-v7.3')
    lastwarn('');
end




%% plot

plotQ = false;
plotAndSave = true;

if plotAndSave
    time=[Output.time]./1000./60-min([Output.time])/1000/60;

%     figure; plot(time,[Output.area])
%     xlabel('Time (min)')
%     ylabel('Projected area (pixels)')
%     title(strrep(substrateID,'_','\_'))

    figure; plot([Output.pressure],[Output.area],'.')
    xlabel('Pressure (Torr)')
    ylabel('Projected area (pixels)')
    title(strrep(substrateID,'_','\_'))

    savePlots('projArea-v-pp')
    if ~plotQ
        close
    end
        
    
%     if temperatureDataTF
%         figure; plot([Output.temperature],[Output.area],'.')
%         xlabel('Temperature (degC)')
%         ylabel('Projected area (pixels)')
%         title(strrep(substrateID,'_','\_'))
%     end

%     figure; plot(time,[Output.fit])
%     xlabel('Time (min)')
%     ylabel('Parameter of fit with final circle')
%     title(strrep(substrateID,'_','\_'))

%     figure; plot(time,[Output.height])
%     ylabel('Height (pixels)')
%     yyaxis right; plot(time,[Output.width])
%     ylabel('Width (pixels)')
%     xlabel('Time (min)')
%     title(strrep(substrateID,'_','\_'))

%     if temperatureDataTF
%         figure; plot([Output.temperature],[Output.height])
%         ylabel('Height (pixels)')
%         yyaxis right; plot([Output.temperature],[Output.width])
%         ylabel('Width (pixels)')
%         xlabel('Temperature (degC)')
%         title(strrep(substrateID,'_','\_'))
%     end

    figure; plot([Output.pressure],[Output.height])
    ylabel('Height (pixels)')
    yyaxis right; plot([Output.pressure],[Output.width])
    ylabel('Width (pixels)')
    xlabel('Pressure (Torr)')
    title(strrep(substrateID,'_','\_'))
    
    savePlots('hw-v-pp')
    if ~plotQ
        close
    end

%     figure; plot(time(end-length([Output.ca])+1:end),[Output.ca])
%     ylabel('Contact angle (deg)')
%     xlabel('Time (min)')
%     title(strrep(substrateID,'_','\_'))

    caIdxes = find(~cellfun(@isempty,{Output.ca}));
    pressures = [Output.pressure];

    figure; plot(pressures(caIdxes),[Output.ca],'.')
    ylabel('Contact angle (deg)')
    xlabel('Pressure (Torr)')
    title(strrep(substrateID,'_','\_'))

    
    

    savePlots('ca-v-pp')
    if ~plotQ
        close
    end



end




end

