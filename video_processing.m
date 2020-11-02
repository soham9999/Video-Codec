% reading the video
v = VideoReader('video1.mp4');
frame = read(v,1);
imshow(frame);
%% converting the video to grayscale
vgray = VideoWriter('grayvideo.mp4');
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
motion_vectors = zeros(total_blocks,2);

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
        motion_vectors(p,1)=mv1;
        motion_vectors(p,2)=mv2;
         disp(p);
        p=p+1;
%         min_sum=999999;
        max_count = 0;
       
    end
end
%% making the predicted frame
predict_frame1 = zeros(length,width,rgb);
p=1;
for i_out=1:vertical_blocks
    for j_out=1:horizontal_blocks
%         this two outer loops iterate over each block of the predicted frame
        mv1 = motion_vectors(p,1);
        mv2 = motion_vectors(p,2);
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
residual_frame1 =  imabsdiff(frame1,predict_frame1);
figure();
imshow(predict_frame1);
figure();
imshow(frame1);
% residual_frame1 = uint8(residual_frame1);
figure();
imshow(residual_frame1);

