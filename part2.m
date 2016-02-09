
%% Part 2 - Auto picking features using SIFT for the transformation

clear all

%Load images
img1 = imread('parliament-left.jpg');
img2 = imread('parliament-right.jpg');

img1 = imresize(img1, 0.25);
img2 = imresize(img2, 0.25);

%Convert to grayscale
img1 = rgb2gray(img1);
img2 = rgb2gray(img2);

%Convert to single
img1 = im2single(img1) ;
img2 = im2single(img2) ;

%find features [f = frames, d = descriptors]
[f1,d1] = vl_sift(img1) ;
[f2,d2] = vl_sift(img2) ;

[r1,c1] = size(d1);
[r2,c2] = size(d2);
% [matches, scores] = vl_ubcmatch(d1,d2); %used for testing

best_match_f = zeros(c1,2);     %holds coord(x,y) for the best match
best_match_d = zeros(c1,r1);    %holds descriptor for the best match
distance = zeros(c1,1);         %computed distance b/w best descriptor

%find distances b/w discriptors
% for i = 1:c1
%     smallest_dist = Inf;
%     match_f = zeros([1,2]);
%     match_d = zeros([1,128]);
%     for j = 1:c2
%         calc = dist2(d1(i)',d2(j)');
%         if(calc < smallest_dist)
%             smallest_dist = calc;
%             match_f = f2(1:2,j)';
%             match_d = d2(:,j)';
%          end
%     end
%     
%     best_match_f(i,:) = match_f;
%     best_match_d(i,:) = match_d;
%     distance(i) = smallest_dist;
% end

[I J] = meshgrid(1:c1, 1:c2);

calc = dist2(d1(I(1:end))', d2(J(1:end))')

for i = 1:size(calc, 1)
    smallest_dist = Inf;
    match_f = zeros([1,2]);
    match_d = zeros([1,128]);
    for j = 1:size(calc, 2)
        if(calc(i,j) < smallest_dist)
            smallest_dist = calc
            match_f = f2(1:2, j)'
            match_d = d2(:, j)'
        end
    end
end

best_match_f(i,:) = match_f;
best_match_d(i,:) = match_d;
distance(i) = smallest_dist;

threshold = 1;
MatchingPairs = [];
%select discriptors_distance < threshhold
for i = 1:c1
     if(distance(i) < threshold)
        MatchingPairs = [MatchingPairs;[f1(1:2 , i)' best_match_f(i,:) distance(i)]];
     end
end

% RANSAC Below
iterations = 100;   %number of times to run  
min_pairs = 2;       %min number of pair of points
threshold = 10;       %radius of 5 pixels
models = [];

for i = 1:iterations

    sample = datasample(MatchingPairs, min_pairs);

    %extract points
    P1X = sample(:,1);
    P1Y = sample(:,2);
    P2X = sample(:,3);
    P2Y = sample(:,4);
    
    %find T (same as top part of this answer when manually picking the
    %points)
    A = [P2X' P2Y' ; 
         P2Y' -P2X' ; 
         1 1 0 0  ;
         0 0 1 1  ]';

    z = [ P1X' P1Y' ]';
    const_estimate = A \ z; 
    a = const_estimate(1); 
    b = const_estimate(2);
    alpha1 = const_estimate(3);
    alpha2 = const_estimate(4);
    
    T = [a 		b 	alpha1 ;
         -b 	a 	alpha2 ;
         0 		0	 1	];
     
     [r,c] = size(MatchingPairs);
     
     %Loops through our entire data set
     % and votes for the current model if this transformation maps
     % correctly (ie its within a radius of where it should be)
     count = 0;
     for j = 1:r
        %take the first point of the feature in image 1 and apply T to get
        %the transformed point
         p = T*[MatchingPairs(j,1:2) 1]';
         x1 = p(1); %x coord for point in image 2
         y1 = p(2); %y cood for point in image 2
         
         %Get our matching feature 
         x2 = MatchingPairs(j,3);
         y2 = MatchingPairs(j,4);
         if (( x2 + threshold) >= x1) && (( x2 - threshold) <= x1)
            if (( y2 + threshold) >= y1) && (( y2 - threshold) <= y1)
                count = count + 1;  %cast vote
            end
         end
     end
    
     models = [models; a b alpha1 alpha2 count]; %record the total votes for this model
end

%pick model with most votes
[maxCount, rowIdx] = max(models(:,5),[],1)
models(rowIdx,:)
a = models(rowIdx,1); 
b = models(rowIdx,2);
alpha1 = models(rowIdx,3);
alpha2 = models(rowIdx,4);

T = [a 		b 	alpha1 ;
     -b 	a 	alpha2 ;
     0 		0	 1	];
 
warp = maketform('affine', T');

[img2, xdata, ydata] = imtransform(img2, warp);
imshow(img2, 'x', xdata, 'y', ydata);
hold on;
imshow(img1);
axis auto;

