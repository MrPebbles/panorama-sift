
%%Part 1 - Manually picking the coordinates to find the transformation
% matrix T

%Load images
img1 = imread('parliament-left.jpg');
img2 = imread('parliament-right.jpg');

imshow(img1);
[P1X P1Y] = ginput(3);	%choose 2 points from the first image

imshow(img2);
[P2X P2Y] = ginput(3);	%choose 2 corresponding points from the second image

%building A using the points selected above
A = [P2X(1) P2Y(1) 0 0 1 0;
     P2X(2) P2Y(2) 0 0 1 0;
     P2X(3) P2Y(3) 0 0 1 0;
     0 0 P2X(1) P2Y(1) 0 1;
     0 0 P2X(2) P2Y(2) 0 1;
     0 0 P2X(3) P2Y(3) 0 1];
	 
z = [ P1X' P1Y' ]';

%similar to what we did in part one => using the psuedo inverse of A
%to find the vector of unknowns x
const_estimate = A \ z

%extracting the constants from the vector x
a = const_estimate(1); 
b = const_estimate(2);
c = const_estimate(3);
d = const_estimate(4);
alpha1 = const_estimate(5);
alpha2 = const_estimate(6);

%building our transformation matrix using the extracted constants
T = [   a       b       alpha1 ;
        c      d       alpha2 ;
        0 		0       1	]

% Create a transformation based on transformation matrix (T)
warp = maketform('affine', T');

% Show the translated image
[img2, xdata, ydata] = imtransform(img2, warp);

% Show the original image in a graph using data from the transformation
imshow(img2, 'x', xdata, 'y', ydata);

% Retain graph used for the figure above
hold on;

% Show translated image in same graph to visualize the translation with a
% frame of reference
imshow(img1);

% Generate graph dimensions to accomodate for both images
axis auto;



