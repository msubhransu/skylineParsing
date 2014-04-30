function overlayParse(im, parse)
% OVERLAYPARSE overlays the image with the parse
%   OVERLAYPARSE(IM, PARSE) overlays the image with the boundaries of PARSE   
%
% Author: Subhransu Maji

bw = edge(parse, 'canny');
bw = imdilate(bw, strel('disk',8));
imr = im(:,:,1);img = im(:,:,2); imb = im(:,:,3);
imr(bw > 0) = 255;
img(bw > 0) = 0;
imb(bw > 0) = 0;
im(:,:,1) = imr; im(:,:,2) = img; im(:,:,3) = imb;
imagesc(im);
