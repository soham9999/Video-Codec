image = imread('C:\Users\SOHAM SAHA\Downloads\Girl1.jpg')
% figure
% imshow(image)
image1 = rgb2gray(image)
%  figure
%  imshow(image1)
% imhist(image1)
image2 = histeq(image1)
 figure
% imhist(image2)
 imshow(image2)
t = dctmtx(8)
image3 = im2double(image2)
image3 = imresize(image3,[512 512])
dct = @(block_struct)t * block_struct.data * t'
b = blockproc(image3,[8 8],dct)
mask = [1   1   1   0   0   0   0   0
        1   1   0   0   0   0   0   0
        1   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0
        0   0   0   0   0   0   0   0]
bnew = blockproc(b,[8 8],@(block_struct)mask.*block_struct.data)
inversedct = @(block_struct)t' * block_struct.data * t
image4 = blockproc(bnew,[8 8],inversedct)
figure
imshow(image4)
imwrite(image4,'compressedgirl.jpg')
