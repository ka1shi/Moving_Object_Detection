
function PBAS(myFolder, r_path, idxFrom, idxTo)

% myFolder = 'F:\CODE\MATLAB\bin\Object Detection\WavingTrees\WavingTrees';

myFolder = strcat(myFolder,'input\');
r_path = strcat(r_path,'PBAS_r5\');

if ~isdir(myFolder)
    errorMessage = sprintf('Error : The following folder does not exist: \n%s',myFolder);
    uiwait(warndlg(errorMessage));
    return;
end
% r_path = 'F:\CODE\MATLAB\bin\Object Detection\WavingTrees\Resultvideo\';
%Pd_path = 'F:\CODE\MATLAB\bin\Object Detection\WavingTrees\Resultvideo\';

filePattern = fullfile(myFolder,'*.jpg');
bmpFiles = dir(filePattern);

N = 35; % Number of components of background model
min=2; % Number of components that has to be closer than decision threshold for the pixel to be in background
Rid = 0.05; % rate of controlling of decision threshold(DT)
Rlow = 18; % lower bound of DT
Rscale = 5; %Scaling factor for DT control
Tdec = 0.05; % rate of decrease of learning rate
Tinc = 1; % rate of increase of learning rate
Tlow = 2; % lower bound of learning rate
Tup = 200; % upper bound of learning rate
aph = 10; %optimal weighing parameter
medSize = 9; %Median Filter Dimension

    gx = [-1 0 1; -2 0 2; -1 0 1;]; % sobel filters for gradient calculation
    gy = [-1 -2 -1; 0 0 0; 1 2 1;];
    
    % FIRST IMAGE READING FOR CALCULATION OF WIDTH AND HEIGHT OF IMAGE
    firstFileName = bmpFiles(1).name;
    name = fullfile(myFolder, firstFileName);
    
    img = double(imread(name));
    
    [w, h, z] = size(img); % width height calculation
        
    RchannelV = zeros(w, h, N);  % value of red channel pixels
    GchannelV = zeros(w, h, N);  % value of green channel pixels
    BchannelV = zeros(w, h, N);  % value of blue channel pixels
    
    RchannelM = zeros(w, h, N); % gradient of red channel pixels
    GchannelM = zeros(w, h, N); % gradient of green channel pixels
    BchannelM = zeros(w, h, N); % gradient of blue channel pixels
    
    IF = zeros(w, h);

% FORMATION OF BACKGROUND MODEL
for i=1:N
    baseFileName = bmpFiles(i).name;
    fullFileName = fullfile(myFolder, baseFileName);
    fprintf(1, 'Now reading %s\n',fullFileName);
    imageArray = double(imread(fullFileName));
    
    rV = imageArray(:,:,1);
   
    gV = imageArray(:,:,2);
    
    bV = imageArray(:,:,3);
    
    RchannelV(:,:,i) = rV;  
    GchannelV(:,:,i) = gV;  
    BchannelV(:,:,i) = bV;  
    
    
    rM = (conv2(rV,gx,'same')).^2+(conv2(rV,gy,'same')).^2;
    gM = (conv2(gV,gx,'same')).^2+(conv2(gV,gy,'same')).^2;
    bM = (conv2(bV,gx,'same')).^2+(conv2(bV,gy,'same')).^2;
    
    RchannelM(:,:,i) = rM;  
    GchannelM(:,:,i) = gM;  
    BchannelM(:,:,i) = bM;  
    
    imwrite(IF,[r_path,bmpFiles(i).name]);
%     imshow(imageArray); %Display image
%     drawnow; %Force display to update immediately
end

     RR = zeros(size(rV, 1), size(rV, 2)); %decision threshold define for every individual pixel's red value
     RG = zeros(size(gV, 1), size(gV, 2)); %decision threshold define for every individual pixel's green value
     RB = zeros(size(bV, 1), size(bV, 2)); %decision threshold define for every individual pixel's blue value
        
     RR(:)= 20; % Initialization of decision threshold
     RG(:)= 20;
     RB(:)= 20; 
     
     DR = zeros(size(rV, 1), size(rV, 2)); %stores dmin values and changes everytime when background model is updated(for red)
     DG = zeros(size(gV, 1), size(gV, 2));
     DB = zeros(size(bV, 1), size(bV, 2));
     
     DR(:)=intmax('uint64');
     DG(:)=intmax('uint64');
     DB(:)=intmax('uint64');
     
     TR = zeros(size(rV, 1), size(rV, 2)); %stores learning rate values of red and update everytime background model is updated
     TG = zeros(size(gV, 1), size(gV, 2));
     TB = zeros(size(bV, 1), size(bV, 2));
        
     TR(:)=5; %Initialization of learning rate
     TG(:)=5;
     TB(:)=5;
     
     pR = zeros(size(rV, 1), size(rV, 2)); %probability
     pG = zeros(size(gV, 1), size(gV, 2));
     pB = zeros(size(bV, 1), size(bV, 2));
     
     pR(:)=0.2; %Initialization of probability
     pG(:)=0.2;
     pB(:)=0.2;
    
  for i=N+1:idxTo
       
        baseFileName = bmpFiles(i).name;
        fullFileName = fullfile(myFolder, baseFileName);
        imageArray = double(imread(fullFileName));
        
        rv = imageArray(:, :, 1); %2d array for pixel values
        gv = imageArray(:, :, 2);
        bv = imageArray(:, :, 3);
        
        rm = (conv2(rv,gx,'same')).^2+(conv2(rv,gy,'same')).^2; %2d array for pixel gradient
        gm = (conv2(gv,gx,'same')).^2+(conv2(gv,gy,'same')).^2;
        bm = (conv2(bv,gx,'same')).^2+(conv2(bv,gy,'same')).^2;
       
        gR = sum(rm(:))/w*h; % values of gradient for every frame
        gG = sum(gm(:))/w*h;
        gB = sum(bm(:))/w*h;      
        
        countR = zeros(w, h);
        countG = zeros(w, h);
        countB = zeros(w, h);
        
        FR = zeros(w, h); %result for red channel
        FG = zeros(w, h); %result for green channel
        FB = zeros(w, h); %result for blue channel
     
        % DECISION MAKING
        tempG=0; tempR=0; tempB=0;
         for l=1:N
              
              countR((abs(RchannelV(:, :, l)-rv)+(aph/gR)*abs(RchannelM(:, :, l)-rm))< RR(:, :))=tempR+1;
              tempR = tempR+1;
              
              countG((abs(GchannelV(:, :, l)-gv)+(aph/gG)*abs(GchannelM(:, :, l)-gm))< RG(:, :))=tempG+1;
              tempG = tempG+1;
              
              countB((abs(BchannelV(:, :, l)-bv)+(aph/gB)*abs(BchannelM(:, :, l)-bm))< RB(:, :))=tempB+1;
              tempB = tempB+1;
         end
         
         FR(countR<min)=1; 
                
         FG(countG<min)=1;
                
         FB(countB<min)=1;
               
         %UPDATE OF BACKGROUND MODEL of red channel value
         
         A = rand(w, h);
         B = round(1+(N-1)*A);
         
         for j=1:N
              XR = double(B == j);
              vR = RchannelV(:,:,j); 
              mR = RchannelM(:, :, j);
              vR(XR==1 & FR==0 & pR>=(1/200)) = rv(XR==1 & FR==0 & pR>=(1/200));
              mR(XR==1 & FR==0 & pR>=(1/200)) = rm(XR==1 & FR==0 & pR>=(1/200));
              RchannelV(:,:,j) = vR;
              RchannelM(:,:,j) = mR;
         end    
         
         %UPDATE OF BACKGROUND MODEL of green channel value
         A = rand(w, h);
         B = round(1+(N-1)*A);
         
         for j=1:N
              XG = double(B == j);
              vG = GchannelV(:,:,j); 
              mG = GchannelM(:, :, j);
              vG(XG==1 & FG==0 & pG>=(1/200)) = gv(XG==1 & FG==0 & pG>=(1/200));
              mG(XG==1 & FG==0 & pG>=(1/200)) = gm(XG==1 & FG==0 & pG>=(1/200));
              GchannelV(:,:,j) = vG;
              GchannelM(:,:,j) = mG;
         end
                
         %UPDATE OF BACKGROUND MODEL of blue channel value
         A = rand(w, h);
         B = round(1+(N-1)*A);
         
         for j=1:N
              XB = double(B == j);
              vB = BchannelV(:,:,j); 
              mB = BchannelM(:, :, j);
              vB(XB==1 & FB==0 & pB>=(1/200)) = bv(XB==1 & FB==0 & pB>=(1/200));
              mB(XB==1 & FB==0 & pB>=(1/200)) = bm(XB==1 & FB==0 & pB>=(1/200));
              BchannelV(:,:,j) = vB;
              BchannelM(:,:,j) = mB;
         end

                % UPDATE OF Dmin
                for l=1:N
                    
                % UPDATE OF Dmin of red channel
                XR = abs(RchannelV(:, :, l)-rv)+(aph/gR)*abs(RchannelM(:, :, l)-rm);
                DR(DR>(abs(RchannelV(:, :, l)-rv)+(aph/gR)*abs(RchannelM(:, :, l)-rm))) = XR(DR>(abs(RchannelV(:, :, l)-rv)+(aph/gR)*abs(RchannelM(:, :, l)-rm)));
                    
                %UPDATE OF Dmin of green channel
                XG = (abs(GchannelV(:, :, l)-gv)+(aph/gG)*abs(GchannelM(:, :, l)-gm));
                DG(DG>(abs(GchannelV(:, :, l)-gv)+(aph/gG)*abs(GchannelM(:, :, l)-gm))) = XG(DG>(abs(GchannelV(:, :, l)-gv)+(aph/gG)*abs(GchannelM(:, :, l)-gm)));
                    
                %UPDATE OF Dmin of blue channel
                XB = (abs(BchannelV(:, :, l)-bv)+(aph/gB)*abs(BchannelM(:, :, l)-bm));
                DB(DB>(abs(BchannelV(:, :, l)-bv)+(aph/gB)*abs(BchannelM(:, :, l)-bm))) = XB(DB>(abs(BchannelV(:, :, l)-bv)+(aph/gB)*abs(BchannelM(:, :, l)-bm)));
                    
                end
                
                %UPDATE OF DECISION THRESHOLD of red channel
                XR = RR.*(1-Rid);
                RR(RR>DR.*Rscale) = XR(RR>DR.*Rscale);
                XR = RR(:, :).*(1+Rid);
                RR(RR<DR.*Rscale) = XR(RR<DR.*Rscale);
                
                RR(RR<Rlow) = Rlow;
                    
                %UPDATE OF DECISION THRESHOLD of green channel
                XG = RG.*(1-Rid);
                RG(RG>DG.*Rscale) = XG(RG>DG.*Rscale);
                XG = RG.*(1+Rid);
                RG(RG<DG.*Rscale) = XG(RG<DG.*Rscale);
                
                RG(RG<Rlow) = Rlow;
                   
                %UPDATE OF DECISION THRESHOLD of blue channel
                XB = RB.*(1-Rid);
                RB(RB>DB.*Rscale) = XB(RB>DB.*Rscale);
                XB = RB.*(1+Rid);
                RB(RB<DB.*Rscale) = XB(RB<DB.*Rscale);
                
                RB(RB<Rlow) = Rlow;
                   
                % UPDATE OF LEARNING RATE of red channel
                XR = Tinc./DR;
                TR(FR==1) = TR(FR==1) + XR(FR==1);
          
                XR = Tdec./DR;
                TR(FR==0) = TR(FR==0) - XR(FR==0);
                
                TR(TR<Tlow) = Tlow;
                
                TR(TR>Tup) = Tup;
                    
                pR = 1./TR;
         
                % UPDATE OF LEARNING RATE of green channel
                XG = Tinc./DG;
                TG(FG==1) = TG(FG==1) + XG(FG==1);
                    
                XG = Tdec./DG;
                TG(FG==0) = TG(FG==0) - XG(FG==0);
                    
                TG(TG<Tlow) = Tlow;
                    
                TG(TG>Tup) = Tup;
                    
                pG = 1./TG;
               
                % UPDATE OF LEARNING RATE of blue channel
                XB = Tinc./DB;
                TB(FB==1) = TB(FB==1) + XB(FB==1);
                
                XB = Tdec./DB;
                TB(FB==0) = TB(FB==0) - XB(FB==0);
                    
                TB(TB<Tlow) = Tlow;
                    
                TB(TB>Tup) = Tup;
                    
                pB = 1./TB;
               
        % IMAGE FORMATION
        F = or(FR, FB);
        F = or(F, FG);
        F = medfilt2(F, [medSize, medSize]);
%       r_name = num2str(i);
        bmpFiles(i).name
        imwrite(F,[r_path,bmpFiles(i).name]);
%         title('Binary Results');
                
  end

paraArray = {'Background Model Components',num2str(N);...
    'Min value', num2str(min); 'Decision Threshold Controller',num2str(Rid);...
    'Lower bound of Decision Threshold', num2str(Rlow);...
    'Scalling Factor for controlling Decision Threshold', num2str(Rscale);...
    'Rate of decrease of Learning Rate', num2str(Tdec);...
    'Rate of increase of Learning Rate', num2str(Tinc);...
    'Lower bound of Learning Rate', num2str(Tlow);...
    'Upper bound of Decision Threshold',num2str(Tup);...
    'alpha',num2str(aph); 'Median Filter Size', num2str(medSize)};

% fileID = fopen('parameter.txt','w');
% fprintf(fileID,'%s %s\n',paraArray);
% fclose(fileID);

xlsF_name = strcat(r_path, 'PBAS_parameter');
xlswrite(xlsF_name,paraArray);
end