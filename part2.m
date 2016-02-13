
%% Part 2 - Auto picking features using SIFT for the transformation

clear all

fprintf('Loading images\n');
%Load images
img1 = imread('parliament-left.jpg');
img2 = imread('parliament-right.jpg');

img1 = imresize(img1, 0.15);
img2 = imresize(img2, 0.15);

%Convert to grayscale
img1 = rgb2gray(img1);
img2 = rgb2gray(img2);

%Convert to single
img1 = im2single(img1) ;
img2 = im2single(img2) ;

fprintf('Calculating SIFT features in both images\n');
%find features [f = keypoint, d = descriptors]

[f1,d1] = vl_sift(img1) ;
[f2,d2] = vl_sift(img2) ;

[r1,c1] = size(d1);
[r2,c2] = size(d2);
% [matches, scores] = vl_ubcmatch(d1,d2); %used for testing

best_match_f = zeros(c1,2);     %holds coord(x,y) for the best match
%best_match_d = zeros(c1,r1);    %holds descriptor for the best match
distance = zeros(c1,1);         %computed distance b/w best descriptor

fprintf('Calculating distance between descriptors and matching features with the closest discriptors\n');
%find distances b/w discriptors
for i = 1:c1
    smallest_dist = Inf;
    match_f = [1,2];
    %match_d = [1,128];
    for j = 1:c2
       calc = dist2(double(d1(:,i)'),double(d2(:,j)'));
        if(calc < smallest_dist)
            smallest_dist = calc;
            match_f = f2(1:2,j)';
            %match_d = d2(:,j)';
        end
    end
    
    best_match_f(i,:) = match_f;
    %best_match_d(i,:) = match_d;
    distance(i) = smallest_dist;
end

fprintf('Selecting pairs of features with descriptor distances < threshold\n');
threshold = 400;
MatchingPairs = [];
for i = 1:c1
      if(distance(i) < threshold)
        MatchingPairs = [MatchingPairs;[f1(1:2 , i)' best_match_f(i,:) distance(i)]];
      end
end

fprintf('Displaying matches across both images\n (Press any key to continue)\n');
%concat images
padded_im = [];
im = [];
if(size(img1, 1) > size(img2, 1))
    x = size(img1, 1) - size(img2, 1);
    padded_im = img2;
    padded_im(size(img2, 1)+1:x+size(img2, 1),: ) = zeros;
    im = [img1 padded_im];
elseif (size(img2, 1) > size(img1, 1))
    x = size(img2, 1)-size(img1, 1);
    padded_im = img1;
    padded_im(size(img1, 1)+1:x+size(img1, 1),: ) = zeros;
    im = [padded_im im2];
else
    im = [img1 img2]
end
imshow(im);
pause;
hold on;

%Pick 20 random pairs and display them
c = randperm(length(MatchingPairs), 20);
sample = MatchingPairs(c,:)
for i=1:20
    x1 = sample(i,1);
    y1 = sample(i,2);
    x2 = sample(i,3);
    y2 = sample(i,4);
    [sx,sy] = size(img1);
    %plot circles/lines showing matches
    line([x1,x2+sx],[y1,y2],'Color','y','LineWidth',2);
    plot( x1, y1, '.r', 'MarkerSize',10)
    plot(x2+sx,y2, '.g', 'MarkerSize',10)
    
end
hold off;
pause;

fprintf('Running RANSAC to estimate the tranformation matrix\n');

% RANSAC Below
iterations = 100;   %number of times to run  
min_pairs = 3;      %min number of pair of points
threshold = 5;    %radius
models = [];
for i = 1:iterations
    %randomly pick pairs of points
    c = randperm(length(MatchingPairs), min_pairs);
    sample = MatchingPairs(c,:);
    
    %extract points
    P1X = sample(:,1);
    P1Y = sample(:,2);
    P2X = sample(:,3);
    P2Y = sample(:,4);
    
    %find T (same as top part of this answer when manually picking the
    %points)
    A = [P2X(1,1) P2Y(1,1) 0 0 1 0;
         P2X(2,1) P2Y(2,1) 0 0 1 0;
         P2X(3,1) P2Y(3,1) 0 0 1 0;
         0 0 P2X(1,1) P2Y(1,1) 0 1;
         0 0 P2X(2,1) P2Y(2,1) 0 1;
         0 0 P2X(3,1) P2Y(3,1) 0 1];


    z = [ P1X' P1Y' ]';
    const_estimate = A \ z; 
    a = const_estimate(1); 
    b = const_estimate(2);
    c = const_estimate(3); 
    d = const_estimate(4);
    alpha1 = const_estimate(5);
    alpha2 = const_estimate(6);
    
    T = [a      b   alpha1 ;
         c      d   alpha2 ;
         0      0    1  ];
     
     [r,tmp_VAR] = size(MatchingPairs);
     
     %Loops through our entire data set
     % and votes for the current model if this transformation maps
     % correctly (ie its within a radius of where it should be)
     count = 0;
     for j = 1:r
        %take the first point of the feature in image 1 and apply T to get the transformed point
         p = T*[MatchingPairs(j,3:4) 1]';
         x1 = p(1); %x coord for point in image 2
         y1 = p(2); %y cood for point in image 2
         
         %Get our matching feature 
         x2 = MatchingPairs(j,1);
         y2 = MatchingPairs(j,2);

         if (( x2 + threshold) >= x1) && (( x2 - threshold) <= x1)
            if (( y2 + threshold) >= y1) && (( y2 - threshold) <= y1)
                count = count + 1;  %cast vote
            end
         end
     end
    
     models = [models; a b c d alpha1 alpha2 count]; %record the total votes for this model
end

fprintf('Picking the model with most votes\n');

[maxVotes, rowIdx] = max(models(:,7),[],1)

a = models(rowIdx,1); 
b = models(rowIdx,2); 
c = models(rowIdx,3);  
d = models(rowIdx,4); 
alpha1 = models(rowIdx,5); 
alpha2 = models(rowIdx,6); 
    
T = [a      b   alpha1;
     c      d   alpha2;
     0      0    1  ]

fprintf('Displaying final result\n');
warp = maketform('affine', T');
[img2, xdata, ydata] = imtransform(img2, warp);
imshow(img2, 'x', xdata, 'y', ydata);
hold on;
imshow(img1);
axis auto;
