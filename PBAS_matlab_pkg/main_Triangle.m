function main_Triangle( videoPath, binaryFolder, idxFrom, idxTo )
srcPath = strcat(videoPath,'\input\*.jpg');
imgPath = strcat(videoPath,'\input\');
srcFiles = dir(srcPath);
filename1 = strcat(imgPath,srcFiles(idxFrom).name);
CF = imread(filename1);
[s,v,~] = size(CF);
mod_s = 10;alpha=10;
lgth = s*v;
%C_TRI_MP_r1=144#*#C_TRI_MP_L1=288#*#
b_Model = zeros(lgth,144,mod_s);
f_Model = zeros(lgth,144,mod_s); 
% crs_b_mat = false(lgth,1); crs_f_mat = false(lgth,1);
% fine_detect = false(lgth,1);
fine_detect = zeros(s,v);
for frameCount = idxFrom:idxTo
    tic;
    filename = strcat(imgPath,srcFiles(idxFrom).name);
    img = imread(filename);
    if(frameCount==1)
      past = img;
    else
      past_filename = strcat(imgPath,srcFiles(frameCount-1).name);
      past = imread(past_filename);
    end
    curr = img;
    
    fprintf('Image No : %d \n',frameCount);
    if(size(img,3)>1)
    else
        fprintf('The input image is grayscale');
    end
    star_p = C_TRI_MP_r1(img);
%     star_p = ST_C_TRI_MP_r1(past,curr);
    inv_star_p = ~star_p;
    if (frameCount<=mod_s)
        b_Model(:,:,frameCount) = star_p;
        f_Model(:,:,frameCount) = inv_star_p;
    else
        %-----Code for taking minumum distance from all the BG/FG Model-----
        G = repmat(star_p,[1,1,mod_s]);
        b_hd = sum((G~=b_Model),2);
        f_hd = sum((G~=f_Model),2);
        b_hd = reshape(b_hd,[lgth,mod_s]);
        f_hd = reshape(f_hd,[lgth,mod_s]);
        [b_v,~] = min(b_hd,[],2);
        [f_v,~] = min(f_hd,[],2); 
        %---- Code for Union of BG/FG Model----
%         bm_uni = sum(b_Model,3)>0;
%         fm_uni = sum(f_Model,3)>0; 
%         b_v = sum(star_p~=bm_uni,2);
%         f_v = sum(star_p~=fm_uni,2);
        %------End---------
        b_P = exp(-b_v);f_P = exp(-f_v);        
        crs_b_mat = (b_P>f_P).*(b_v<alpha);
%         crs_b_mat = (b_P>f_P);
        crs_f_mat = ~crs_b_mat;
        b_Model(:,:,1:mod_s-1) = b_Model(:,:,2:mod_s);
        b_Model(:,:,mod_s) = star_p;
        f_Model(:,:,1:mod_s-1) = f_Model(:,:,2:mod_s);
        f_Model(:,:,mod_s) = inv_star_p;
        
        p1 = reshape(crs_b_mat,[s,v]);
        p2 = reshape(crs_f_mat,[s,v]);    
        p1 = padarray(p1,[5,5]);
        p2 = padarray(p2,[5,5]);
        [row1,col1] = size(p1);
        for rr = 6:row1-5
              for cc = 6:col1-5
                  r1 = rr-5; r2 = rr+5;
                  c1= cc-5; c2= cc+5;
                  b_lik = sum(sum(p1(r1:r2,c1:c2)));
                  f_lik = sum(sum(p2(r1:r2,c1:c2)));
                  fine_detect(r1,c1) = f_lik > b_lik;
              end
        end
        imwrite(logical(fine_detect),[binaryFolder,'/',srcFiles(frameCount).name]); 
    end
    imwrite(logical(fine_detect),[binaryFolder,'/',srcFiles(frameCount).name]); 
end   

end

