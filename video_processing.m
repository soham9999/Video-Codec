% reading the video
v = VideoReader('original_video_50f.mp4.avi');
frame = read(v,1);
imshow(frame);
%% converting the video to grayscale
vgray = VideoWriter('grayvideo1.mp4');
vgray.FrameRate = v.FrameRate;
open(vgray);
while hasFrame(v)
   img = readFrame(v);
   img = rgb2gray(img);
   writeVideo(vgray,img);
end
close(vgray);
%% playing movie player
implay
%% applying dct compression to all the frames
vfirst = VideoReader('grayvideo.mp4.avi');
vsec = VideoWriter('compvideo.mp4');
vsec.FrameRate = vfirst.FrameRate;
open(vsec);
while hasFrame(vfirst)
   img = readFrame(vfirst);
   img = rgb2gray(img);
   t = dctmtx(8);
   image3 = im2double(img);
   dct = @(block_struct)t * block_struct.data * t';
   b = blockproc(image3,[8 8],dct);
   mask = [1   1   1   0   0   0   0   0
        1   1   0   0   0   0   0   0
        1   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0];
   bnew = blockproc(b,[8 8],@(block_struct)mask.*block_struct.data);
   inversedct = @(block_struct)t' * block_struct.data * t;
   image4 = blockproc(bnew,[8 8],inversedct);
   image4 = im2uint8(image4);
   writeVideo(vsec,image4);
end
close(vsec);
% the video file compresses to 9.32 mb from 13.8 mb
% the compression is 21%

%% block dividing the first frame
frame = read(v,1);
figure();
imshow(frame);
frame1 = read(v,2);
% figure();
% imshow(frame1);
% choosing block size to be 16
block_size = 16;
[length, width, rgb]=size(frame);
horizontal_blocks = width/block_size;
vertical_blocks = length/block_size;
total_blocks = horizontal_blocks*vertical_blocks;
motion_vectors1 = zeros(total_blocks,2);

first_block = zeros(block_size,block_size,3);
% extracting the first block
for i=1:block_size
    for j=1:block_size
        for k=1:3
            first_block(i,j,k)=frame(i,j,k);
        end    
    end
end
% displaying the first extracted block from the first frame 
first_block = uint8(first_block);
figure();
imshow(first_block);

%% calculating the motion vectors ( for 2nd frame w.r.t first frame)
sum = 0;
sum = double(sum);
min_sum=999999;
max_count = 0;
count=0;
temp_block=zeros(block_size,block_size,3);
% start_h=1;
% end_h=block_size;
% start_v=1;
% end_v=block_size;
mv1=0;
mv2=0;
p=1;
i1=1;
j1=1;
k1=1;
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         the outer two loops iterate through the blocks of 2nd frame
%         now iterating through each block
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                for k=1:3
                    temp_block(i1,j1,k1)=frame1(i,j,k);
                    k1=k1+1;
                end
                j1=j1+1;
                k1=1;
            end
            i1=i1+1;
            j1=1;
            k1=1;
        end
        temp_block = uint8(temp_block);
%         now for each block of 2nd frame we check all blocks of 1st frame
%          start_h1=1;
%          end_h1=block_size;
%          start_v1=1;
%          end_v1=block_size;
          i1=1;
          j1=1;
          k1=1;
        for i_in=1:vertical_blocks
            for j_in=1:horizontal_blocks
%                 the inner two loops iterate through all blocks of the first frame
%                  now iterating through each block of first frame

                 for i=(((i_in-1)*block_size)+1):(i_in*block_size)
                     for j=(((j_in-1)*block_size)+1):(j_in*block_size)
                         for k=1:3
%                                 sum = sum + double(abs(temp_block(i1,j1,k1)-frame(i,j,k)));
% above line of code is Minimum Absolute difference method
% below if block is the Maximum pixel Count method
                                  if temp_block(i1,j1,k1)==frame(i,j,k)
                                      count=count+1;
                                  end
                                k1=k1+1;
                         end  
                         j1=j1+1;
                         k1=1;
                     end
                     i1=i1+1;
                     j1=1;
                     k1=1;
                 end
%                  if (min_sum>sum)
%                      min_sum = sum;
%                      mv1=i_in;
%                      mv2=j_in;
%                  end
                  if (max_count<count)
                     max_count = count;
                     mv1=i_in;
                     mv2=j_in;
                 end

%                  sum=0;
                 count=0;
                 i1=1;
                 j1=1;
                 k1=1;
            end
        end
        motion_vectors1(p,1)=mv1;
        motion_vectors1(p,2)=mv2;
        disp(p); 
        p=p+1;
%         min_sum=999999;
        mv1=0;
        mv2=0;
        max_count = 0;
       
    end
end
%% making the predicted frame
predict_frame1 = zeros(length,width,rgb);
p=1;
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the predicted frame
        mv1 = motion_vectors1(p,1);
        mv2 = motion_vectors1(p,2);
        i1 = (((mv1-1)*block_size)+1);
        j1 = (((mv2-1)*block_size)+1);
        k1=1;
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                for k=1:3
%                     this three loops iterate to fill the empty block being processed
                      predict_frame1(i,j,k) = frame(i1,j1,k1);
                      k1=k1+1;
                end
                j1=j1+1;
                k1=1;
            end
            i1=i1+1;
            j1 = (((mv2-1)*block_size)+1);
            k1=1;
        end
        disp(p);
        p=p+1;
        
    end
end
        
predict_frame1 = uint8(predict_frame1);
figure();
imshow(predict_frame1);
figure();
imshow(frame1);

%% finding the first residual frame
% residual_frame1 = zeros(length,width,rgb);
% for i_out=1:vertical_blocks
%     for j_out=1:horizontal_blocks
% %         this two outer loops iterate over each block of the residual frame
%           for i=(((i_out-1)*block_size)+1):(i_out*block_size)
%             for j=(((j_out-1)*block_size)+1):(j_out*block_size)
%                 for k=1:3
% %                     this three loops iterate to fill the empty block being processed
%                       residual_frame1(i,j,k)= abs(frame1(i,j,k) - predict_frame1(i,j,k));
% %                     the difference between each pixel of original and predicted frame is stored
%                 end
%             end
%           end
%     end
% end

% displaying the original , predicted and residual frame together
% predict_frame1 = uint8(predict_frame1);
% frame1 = rgb2gray(frame1);
% predict_frame1 = rgb2gray(predict_frame1);
x = int32(frame1);
y = int32(predict_frame1);
% residual_frame1 =  imsubtract(frame1,predict_frame1);
z =  imsubtract(x,y);
% figure();
% imshow(predict_frame1);
% figure();
% imshow(frame1);
% residual_frame1 = uint8(residual_frame1);
figure();
z1 = uint8(z);
imshow(z1);
 imwrite(z1,'first_residue1.jpg','jpg');
figure();
recon_f = imadd(y,z);
recon_f = uint8(recon_f);
imshow(recon_f);
%% all the residual frames extracting
v_residual = VideoWriter('residue_video_grayscale_50f_new.mp4');
v_residual.FrameRate = v.FrameRate;
open(v_residual);
total_frames=0;
%finding an estimate number of frames in the actual video
while hasFrame(v)
   readFrame(v);
   total_frames=total_frames+1;
end
first_frame = read(v,1);
writeVideo(v_residual,first_frame);
prev_frame = first_frame;

%initializing variables again
sum = 0;
sum = double(sum);
min_sum=999999;
max_count = 0;
count=0;
motion_vectors = zeros(total_frames-1,total_blocks,2);
temp_block=zeros(block_size,block_size,3);
% start_h=1;
% end_h=block_size;
% start_v=1;
% end_v=block_size;
mv1=0;
mv2=0;
p=1;
i1=1;
j1=1;
k1=1;
%****************************

for i_frame=2:total_frames
    disp(i_frame);
    prev_frame = read(v,i_frame-1);
    current_frame = read(v,i_frame);
    %now finding motion vectors for current_frame w.r.t prev_frame
    for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         the outer two loops iterate through the blocks of 2nd frame
%         now iterating through each block
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                for k=1:3
                    temp_block(i1,j1,k1)=current_frame(i,j,k);
                    k1=k1+1;
                end
                j1=j1+1;
                k1=1;
            end
            i1=i1+1;
            j1=1;
            k1=1;
        end
        temp_block = uint8(temp_block);
%         now for each block of 2nd frame we check all blocks of 1st frame
%          start_h1=1;
%          end_h1=block_size;
%          start_v1=1;
%          end_v1=block_size;
          i1=1;
          j1=1;
          k1=1;
        for i_in=1:vertical_blocks
            for j_in=1:horizontal_blocks
%                 the inner two loops iterate through all blocks of the first frame
%                  now iterating through each block of first frame

                 for i=(((i_in-1)*block_size)+1):(i_in*block_size)
                     for j=(((j_in-1)*block_size)+1):(j_in*block_size)
                         for k=1:3
%                                 sum = sum + double(abs(temp_block(i1,j1,k1)-frame(i,j,k)));
% above line of code is Minimum Absolute difference method
% below if block is the Maximum pixel Count method
                                  if temp_block(i1,j1,k1)==prev_frame(i,j,k)
                                      count=count+1;
                                  end
                                k1=k1+1;
                         end  
                         j1=j1+1;
                         k1=1;
                     end
                     i1=i1+1;
                     j1=1;
                     k1=1;
                 end
%                  if (min_sum>sum)
%                      min_sum = sum;
%                      mv1=i_in;
%                      mv2=j_in;
%                  end
                  if (max_count<count)
                     max_count = count;
                     mv1=i_in;
                     mv2=j_in;
                 end

%                  sum=0;
                 count=0;
                 i1=1;
                 j1=1;
                 k1=1;
            end
        end
        motion_vectors(i_frame-1,p,1)=mv1;
        motion_vectors(i_frame-1,p,2)=mv2;
         disp(p);
        p=p+1;
%         min_sum=999999;
        max_count = 0;
       
    end
    end
% now obtaining the predicted frame from prev_frame
predict_frame1 = zeros(length,width,rgb);
p=1;
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the predicted frame
        mv1 = motion_vectors(i_frame-1,p,1);
        mv2 = motion_vectors(i_frame-1,p,2);
        i1 = (((mv1-1)*block_size)+1);
        j1 = (((mv2-1)*block_size)+1);
        k1=1;
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                for k=1:3
%                     this three loops iterate to fill the empty block being processed
                      predict_frame1(i,j,k) = prev_frame(i1,j1,k1);
                      k1=k1+1;
                end
                j1=j1+1;
                k1=1;
            end
            i1=i1+1;
            j1 = (((mv2-1)*block_size)+1);
            k1=1;
        end
        disp(p);
        p=p+1;
        
    end
end
        
predict_frame1 = uint8(predict_frame1);
% now obtaining the residual frame
residual_frame1 =  imsubtract(current_frame,predict_frame1);

%adding the residual frame to the video
writeVideo(v_residual,residual_frame1);

sum = 0;
sum = double(sum);
min_sum=999999;
max_count = 0;
count=0;
temp_block=zeros(block_size,block_size,3);
% start_h=1;
% end_h=block_size;
% start_v=1;
% end_v=block_size;
mv1=0;
mv2=0;
p=1;
i1=1;
j1=1;
k1=1;

end
close(v_residual)
% the residual frame video is complete
%% analysing the first residual frame 
first_res = imread('first_residue1.jpg');
 first_res_bg = rgb2gray(first_res);
% converting it to black and white for convenience
figure();
imshow(first_res_bg);
% extracting two 16*16 blocks, one detailed and other non detailed
detail_block = zeros(block_size,block_size);
undetail_block = zeros(block_size,block_size);
% choosing block indexes for detail and undetail blocks
di = 9;
dj = 10;
udi = 35;
udj = 30;
i1=1;
j1=1;
% extracting detail block
for i=(((di-1)*block_size)+1):(di*block_size)
    for j=(((dj-1)*block_size)+1):(dj*block_size)
        detail_block(i1,j1)=first_res_bg(i,j);
        j1=j1+1;
    end
    i1=i1+1;
    j1=1;
end
detail_block = uint8(detail_block);
% extracting undetail block
i1=1;
j1=1;
for i=(((udi-1)*block_size)+1):(udi*block_size)
    for j=(((udj-1)*block_size)+1):(udj*block_size)
        undetail_block(i1,j1)=first_res_bg(i,j);
        j1=j1+1;
    end
    i1=i1+1;
    j1=1;
end
undetail_block = uint8(undetail_block);

figure();
imshow(detail_block);
figure();
imshow(undetail_block);
% observing the histograms of the two blocks
figure();
imhist(detail_block);
figure();
imhist(undetail_block);
% observing the entropy of each block
detail_block_entropy = entropy(detail_block);
undetail_block_entropy = entropy(undetail_block);
disp(detail_block_entropy);
disp(undetail_block_entropy);
%% finding the max entropy for the first residual frame
i1=1;
j1=1;

max_entropy = 0.0;
temp_block=zeros(block_size,block_size);
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the residual frame
       
        i1 = 1;
        j1 = 1;
        
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
%                     this three loops iterate to fill the empty block being processed
                      temp_block(i1,j1) = first_res_bg(i,j);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
        temp_block = uint8(temp_block);
        entrop = entropy(temp_block);
        if(entrop>max_entropy)
            max_entropy=entrop;
        end
        
    end
end
disp(max_entropy);
% max entropy for first residual frame = 6.3418
%% considering quantisation step-size QP be 8 for the first residual frame blocks
% figure();
% imshow(first_res_bg);
% imwrite(first_res_bg,'first_residual_frame_black_white.jpg','jpg')
% computing DCT coefficients for the first block of first frame
di=10;
dj=12;
i1=1;
j1=1;
step_size = 8;
temp_block = zeros(block_size,block_size);
for i=(((di-1)*block_size)+1):(di*block_size)
    for j=(((dj-1)*block_size)+1):(dj*block_size)
        temp_block(i1,j1)=first_res_bg(i,j);
        j1=j1+1;
    end
    i1=i1+1;
    j1=1;
end
temp_block = uint8(temp_block);
figure();
imshow(temp_block);
dct_first = dct2(temp_block);
% quantizing the block
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=round(dct_first(i,j)/step_size);
       
    end
end
% reconstructing
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=dct_first(i,j)*step_size;
       
    end
end
idct_first=idct2(dct_first);
% idct_first = rescale(idct_first);
idct_first = uint8(idct_first);
figure();
imshow(idct_first);
%% DCT and quantization on first frame 
i1=1;
j1=1;
step_size = 32;
temp_block = zeros(block_size,block_size);
recon_frame1 = zeros(length,width);
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the residual frame
        i1 = 1;
        j1 = 1;
        
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                
                      temp_block(i1,j1) = first_res_bg(i,j);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
       temp_block = uint8(temp_block);
        % checking the step size acording to entropy value
       entropy_frame = entropy(temp_block);
       if(entropy_frame < 3)
           step_size = 60;
       end
       if(entropy_frame >= 3 && entropy_frame<5)
            step_size = 50;
       end
       if(entropy_frame >= 5 && entropy_frame<7)
            step_size = 40;
       end
       if(entropy_frame >= 7)
            step_size = 32;
       end 
       dct_first = dct2(temp_block);
       % quantizing the block
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=round(dct_first(i,j)/step_size);
       
    end
end
% reconstructing
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=dct_first(i,j)*step_size;
       
    end
end
idct_first=idct2(dct_first);
% idct_first = rescale(idct_first);
idct_first = uint8(idct_first);
% filling in the blocks of reconstructed frame
i1=1;
j1=1;
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                
                      recon_frame1(i,j) = idct_first(i1,j1);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
    end
end
recon_frame1 = uint8(recon_frame1);
imwrite(recon_frame1,'reconstruted_frame_mod_range.jpg','jpg');
figure();
imshow(recon_frame1);
% comparing with original residual 1st frame
figure();
imshow(first_res_bg);
%% compressed and reconstructed video of the residual frames
step_size=32;
total_frames = 48; % obtained earlier in the motion vector finding part
% reading the residual_frame video
v_res = VideoReader('residue_video_grayscale_50f.mp4.avi');
v_residual_comp = VideoWriter('compressed_residue_video_grayscale_50f.mp4');
v_residual_comp.FrameRate = v.FrameRate;
open(v_residual_comp);
first_frame = read(v,1);
writeVideo(v_residual_comp,first_frame);
temp_block = zeros(block_size,block_size);
for i_frame = 2:total_frames
    disp(i_frame);
    res_frame = read(v_res,i_frame);
    res_frame = rgb2gray(res_frame);
    for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the residual frame
        i1 = 1;
        j1 = 1;
        
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                
                      temp_block(i1,j1) = res_frame(i,j);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
       temp_block = uint8(temp_block);
       dct_first = dct2(temp_block);
       % quantizing the block
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=round(dct_first(i,j)/step_size);
       
    end
end
% reconstructing
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=dct_first(i,j)*step_size;
       
    end
end
idct_first=idct2(dct_first);
% idct_first = rescale(idct_first);
idct_first = uint8(idct_first);
% filling in the blocks of reconstructed frame
i1=1;
j1=1;
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                
                      recon_frame1(i,j) = idct_first(i1,j1);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
    end
    end
   recon_frame1 = uint8(recon_frame1);
   writeVideo(v_residual_comp,recon_frame1);
end
close(v_residual_comp);
%% converting the original residual frames to black and white
v_res = VideoReader('residue_video_grayscale.mp4.avi');
v_residual_bw = VideoWriter('blackwhite_residue_video2.mp4');
v_residual_bw.FrameRate = v.FrameRate;
open(v_residual_bw);
first_frame = read(v,1);

writeVideo(v_residual_bw,first_frame);
for i_frame=2:total_frames 
   img = read(v_res,i_frame);
   img = rgb2gray(img);
   writeVideo(v_residual_bw,img);
end
close(v_residual_bw);
%% deciding the entropy ranges and assigning QP values for it and recompressing the residual frame
step_size=32;
entropy_frame = 0.0;
total_frames = 48; % obtained earlier in the motion vector finding part
% reading the residual_frame video
v_res = VideoReader('residue_video_grayscale_50f_new.mp4.avi');
v_residual_comp_mod = VideoWriter('compressed_residue_mod_video_50f_new.mp4');
v_residual_comp_mod.FrameRate = v.FrameRate;
open(v_residual_comp_mod);
first_frame = read(v,1);
temp_block = zeros(block_size,block_size);
writeVideo(v_residual_comp_mod,first_frame);

for i_frame = 2:total_frames
    disp(i_frame);
    res_frame = read(v_res,i_frame);
    res_frame = rgb2gray(res_frame);
    for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the residual frame
        i1 = 1;
        j1 = 1;
        
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                
                      temp_block(i1,j1) = res_frame(i,j);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
       temp_block = uint8(temp_block);
       % checking the step size acording to entropy value
       entropy_frame = entropy(temp_block);
       if(entropy_frame < 3)
           step_size = 60;
       end
       if(entropy_frame >= 3 && entropy_frame<5)
            step_size = 40;
       end
       if(entropy_frame >= 5 && entropy_frame<7)
            step_size = 32;
       end
       if(entropy_frame >= 7)
            step_size = 24;
       end 
       % ************************************************
       dct_first = dct2(temp_block);
       % quantizing the block
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=round(dct_first(i,j)/step_size);
       
    end
end
% reconstructing
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=dct_first(i,j)*step_size;
       
    end
end
idct_first=idct2(dct_first);
% idct_first = rescale(idct_first);
idct_first = uint8(idct_first);
% filling in the blocks of reconstructed frame
i1=1;
j1=1;
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                
                      recon_frame1(i,j) = idct_first(i1,j1);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
    end
    end
   recon_frame1 = uint8(recon_frame1);
   writeVideo(v_residual_comp_mod,recon_frame1);
end
close(v_residual_comp_mod);

% previously for a uniform step_size of 32 , compression was 23 %
% now with the variable QP w.r.t entropy , compression is 32 %
%% analysing the size of the compressed and quantised frames
step_size=32;
entropy_frame = 0.0;
dct_frame = zeros(length,width);
total_frames = 201; % obtained earlier in the motion vector finding part
% reading the residual_frame video
v_res = VideoReader('residue_video.mp4.avi');
v_residual_comp_dct = VideoWriter('compressed_residue_dct_uniform_QP_video.mp4');
v_residual_comp_dct.FrameRate = v.FrameRate;
open(v_residual_comp_dct);
first_frame = read(v,1);
writeVideo(v_residual_comp_dct,first_frame);

for i_frame = 2:total_frames
    disp(i_frame);
    res_frame = read(v_res,i_frame);
    res_frame = rgb2gray(res_frame);
    for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the residual frame
        i1 = 1;
        j1 = 1;
        
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                
                      temp_block(i1,j1) = res_frame(i,j);
                      
                j1=j1+1;
                
            end
            i1=i1+1;
            j1 = 1;
            
        end
       temp_block = uint8(temp_block);
       % checking the step size acording to entropy value
%        entropy_frame = entropy(temp_block);
%        if(entropy_frame < 3)
%            step_size = 56;
%        end
%        if(entropy_frame >= 3 && entropy_frame<5)
%             step_size = 40;
%        end
%        if(entropy_frame >= 5 && entropy_frame<7)
            step_size = 32;
%        end
%        if(entropy_frame >= 7)
%             step_size = 24;
%        end 
       % ************************************************
       dct_first = dct2(temp_block);
       % quantizing the block
for i=1:block_size
    for j=1:block_size
        dct_first(i,j)=round(dct_first(i,j)/step_size);
       
    end
end
% % reconstructing
% for i=1:block_size
%     for j=1:block_size
%         dct_first(i,j)=dct_first(i,j)*step_size;
%        
%     end
% end
% idct_first=idct2(dct_first);
% % idct_first = rescale(idct_first);
% idct_first = uint8(idct_first);
% % filling in the blocks of reconstructed frame
 i1=1;
 j1=1;
         for i=(((i_out-1)*block_size)+1):(i_out*block_size)
             for j=(((j_out-1)*block_size)+1):(j_out*block_size)
                 
                       dct_frame(i,j) = abs(dct_first(i1,j1));
                       
                 j1=j1+1;
                 
             end
             i1=i1+1;
             j1 = 1;
             
         end
     end
     end
   dct_frame = uint8(dct_frame);
   writeVideo(v_residual_comp_dct,dct_frame);
end
close(v_residual_comp_dct);
%% the original video
total_frames = 50;
v_original = VideoWriter('original_video_50f.mp4');
v_original.FrameRate = v.FrameRate;
open(v_original);
first_frame = read(v,1);
writeVideo(v_original,first_frame);
for i_frame=2:total_frames 
   img = read(v,i_frame);
   writeVideo(v_original,img);
end
close(v_original);
%% displaying the first block (grayscale)
frame = read(v,1);
figure();
imshow(frame);
frame1 = read(v,2);
% figure();
% imshow(frame1);
% choosing block size to be 16
block_size = 16;
[length, width]=size(frame);
horizontal_blocks = width/block_size;
vertical_blocks = length/block_size;
total_blocks = horizontal_blocks*vertical_blocks;
motion_vectors = zeros(total_blocks,2);

first_block = zeros(block_size,block_size);
% extracting the first block
for i=1:block_size
    for j=1:block_size
%         for k=1:3
            first_block(i,j)=frame(i,j);
%         end    
    end
end
% displaying the first extracted block from the first frame 
first_block = uint8(first_block);
figure();
imshow(first_block);
%% motion vectors (grayscale) first frame
sum = 0;
sum = double(sum);
min_sum=999999;
max_count = 0;
count=0;
temp_block=zeros(block_size,block_size);
% start_h=1;
% end_h=block_size;
% start_v=1;
% end_v=block_size;
mv1=0;
mv2=0;
p=1;
i1=1;
j1=1;
k1=1;
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         the outer two loops iterate through the blocks of 2nd frame
%         now iterating through each block
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
%                 for k=1:3
                    temp_block(i1,j1)=frame1(i,j);
%                     k1=k1+1;
%                 end
                j1=j1+1;
%                 k1=1;
            end
            i1=i1+1;
            j1=1;
%             k1=1;
        end
        temp_block = uint8(temp_block);
%         now for each block of 2nd frame we check all blocks of 1st frame
%          start_h1=1;
%          end_h1=block_size;
%          start_v1=1;
%          end_v1=block_size;
          i1=1;
          j1=1;
          k1=1;
        for i_in=1:vertical_blocks
            for j_in=1:horizontal_blocks
%                 the inner two loops iterate through all blocks of the first frame
%                  now iterating through each block of first frame

                 for i=(((i_in-1)*block_size)+1):(i_in*block_size)
                     for j=(((j_in-1)*block_size)+1):(j_in*block_size)
%                          for k=1:3
%                                 sum = sum + double(abs(temp_block(i1,j1,k1)-frame(i,j,k)));
% above line of code is Minimum Absolute difference method
% below if block is the Maximum pixel Count method
                                  if temp_block(i1,j1)==frame(i,j)
                                      count=count+1;
                                  end
%                                 k1=k1+1;
%                          end  
                         j1=j1+1;
                         k1=1;
                     end
                     i1=i1+1;
                     j1=1;
                     k1=1;
                 end
%                  if (min_sum>sum)
%                      min_sum = sum;
%                      mv1=i_in;
%                      mv2=j_in;
%                  end
                  if (max_count<count)
                     max_count = count;
                     mv1=i_in;
                     mv2=j_in;
                 end

%                  sum=0;
                 count=0;
                 i1=1;
                 j1=1;
                 k1=1;
            end
        end
        motion_vectors(p,1)=mv1;
        motion_vectors(p,2)=mv2;
         disp(p);
        p=p+1;
%         min_sum=999999;
        max_count = 0;
       
    end
end
%% test
close(v_residual_comp);
%% reconstructing the video
entropy_frame = 0.0;
dct_frame = zeros(length,width);
total_frames = 48; % obtained earlier in the motion vector finding part
% reading the residual_frame video
v_res = VideoReader('compressed_residue_mod_video_50f_new.mp4.avi');
v_recon = VideoWriter('reonstructed_video_50f_imsub.mp4');
v_recon.FrameRate = v.FrameRate;
open(v_recon);
first_frame = read(v,1);
writeVideo(v_recon,first_frame);

%initializing variables again
% sum = 0;
% sum = double(sum);
% min_sum=999999;
% max_count = 0;
% count=0;
% motion_vectors = zeros(total_frames-1,total_blocks,2);
temp_block=zeros(block_size,block_size);
% start_h=1;
% end_h=block_size;
% start_v=1;
% end_v=block_size;
mv1=0;
mv2=0;
p=1;
i1=1;
j1=1;
k1=1;
%****************************
prev_frame = read(v,1);
prev_frame = rgb2gray(prev_frame);
recon_frame = zeros(length,width);
for i_frame=2:total_frames
    disp(i_frame);
    %now finding motion vectors for current_frame w.r.t prev_frame
    
predict_frame1 = zeros(length,width);
p=1;
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the predicted frame
        mv1 = motion_vectors(i_frame-1,p,1);
        mv2 = motion_vectors(i_frame-1,p,2);
        i1 = (((mv1-1)*block_size)+1);
        j1 = (((mv2-1)*block_size)+1);
        k1=1;
        for i=(((i_out-1)*block_size)+1):(i_out*block_size)
            for j=(((j_out-1)*block_size)+1):(j_out*block_size)
%                 for k=1:3
%                     this three loops iterate to fill the empty block being processed
                      
                      predict_frame1(i,j) = prev_frame(i1,j1);
%                       k1=k1+1;
%                 end
                j1=j1+1;
                k1=1;
            end
            i1=i1+1;
            j1 = (((mv2-1)*block_size)+1);
            k1=1;
        end
        disp(p);
        p=p+1;
        
    end
end
        
predict_frame1 = uint8(predict_frame1);
% now adding the residual frame
residual_frame = read(v_res,i_frame);
residual_frame = rgb2gray(residual_frame);
recon_frame =  imadd(predict_frame1,residual_frame);
if mod(i_frame,4)~=0 
    %adding the residual frame to the video
    writeVideo(v_recon,recon_frame);
    prev_frame = recon_frame;
end
if mod(i_frame,4)==0
     temp_frame = read(v,i_frame);
     temp_frame = rgb2gray(temp_frame);
     writeVideo(v_recon,temp_frame);
     prev_frame = temp_frame;
end
% sum = 0;
% sum = double(sum);
% min_sum=999999;
% max_count = 0;
% count=0;
temp_block=zeros(block_size,block_size);
% start_h=1;
% end_h=block_size;
% start_v=1;
% end_v=block_size;
mv1=0;
mv2=0;
p=1;
i1=1;
j1=1;
k1=1;

end
close(v_recon)

%% test
close(v_recon)

%% test
close(v_residual_comp_mod);

%% making the predicted frame ( way 2 )

predict_frame2 = zeros(length,width);
frame2 = rgb2gray(frame1);
p=1;
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the predicted frame
        mv1 = motion_vectors1(p,1);
        mv2 = motion_vectors1(p,2);
        i1 = (((mv1-1)*block_size)+1);
        j1 = (((mv2-1)*block_size)+1);
        k1=1;
        predict_frame2((((i_out-1)*block_size)+1):(i_out*block_size),(((j_out-1)*block_size)+1):(j_out*block_size))=frame2(i1:(i1+block_size-1),j1:(j1+block_size-1));
        disp(p);
        p=p+1;
        
    end
end
        
predict_frame2 = uint8(predict_frame2);
figure();
imshow(predict_frame2);
figure();
imshow(frame2);

