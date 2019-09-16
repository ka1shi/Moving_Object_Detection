
GTFolder = 'F:\CODE\MATLAB\bin\Object Detection\Shopping Mall\gtShoppingMall';
myFolder = 'F:\CODE\MATLAB\bin\Object Detection\Shopping Mall\Result SM';
Pd_path = 'F:\CODE\MATLAB\bin\Object Detection\'; %EXCEL FILE path

if ~isdir(GTFolder)
    errorMessage = sprintf('Error : The following folder does not exist: \n%s',GTFolder);
    uiwait(warndlg(errorMessage));
    return;
end

if ~isdir(myFolder)
    errorMessage = sprintf('Error : The following folder does not exist: \n%s',myFolder);
    uiwait(warndlg(errorMessage));
    return;
end

filePattern1 = fullfile(GTFolder,'*.bmp');
filePattern2 = fullfile(myFolder,'*.bmp');
GTbmpFiles = dir(filePattern1);
mybmpFiles = dir(filePattern2);

fileID = fopen('F:\CODE\MATLAB\bin\Object Detection\Shopping Mall\gtShoppingMall\gtShoppingMall.txt');
formatSpec = '%d';
A = fscanf(fileID, formatSpec);

fclose(fileID);
j=1;
TP=0; TN=0; FN=0; FP=0;
for j=1:size(A)
    i = A(j);
    GTbaseFileName = GTbmpFiles(j).name;
    mybaseFileName = mybmpFiles(i).name;
    GTfullFileName = fullfile(GTFolder, GTbaseFileName);
    myfullFileName = fullfile(myFolder, mybaseFileName);
    
    fprintf(1, 'Now reading %s\n',GTfullFileName);
    fprintf(1, 'Now reading %s\n',myfullFileName);
    %fprintf(1, '%d %d\n',i, j);
    imgGT = double(imread(GTfullFileName));
    imgRes = double(imread(myfullFileName));
    if(size(imgGT,3)>1)
        imgGT = rgb2gray(imgGT);
    end
    th1 = graythresh(imgGT);
    imgGT = im2bw(imgGT,th1);
    if(imgGT==imgRes)
            display('equal');
           TP = sum(sum(imgRes));FP=0;FN=0;TN=0;
    else
       TP = TP + sum(sum(imgGT==1&imgRes==1));  % True Positive 
       TN = TN + sum(sum(imgGT==0&imgRes==0));  % True Negative
       FP = FP + sum(sum(imgGT==0&imgRes==1));  % False Positive
       FN = FN + sum(sum(imgGT==1&imgRes==0));  % False Negative
    end
    
end

    Precision = TP/(TP+FP);
    Recall = TP/(TP+FN);
    Fscore = 2*Precision*Recall/(Precision+Recall);
    PCC = (TP+TN)/(TP+TN+FP+FN);
    FPR = FP / (FP + TN);
    FNR  = FN / (TP + FN);
    %fprintf(1, '%f %f %f %f\n',Precision, Recall, Fscore, PCC);
   
    paraArray = {'PRECISION',num2str(Precision); 'RECALL', num2str(Recall);
        'FSCORE', num2str(Fscore);'PCC', num2str(PCC);
        'FPR', num2str(FPR); 'FNR', num2str(FNR)
        };
    
    xlsF_name = strcat(Pd_path, 'parameter');
    xlswrite(xlsF_name,paraArray, 5);
