panorama-sift

Merging images together to create a panorama (similar to the funtionality of camera apps)

IMPORTANT: VLFeat must be installed on MATLAB for this to work: http://www.vlfeat.org/overview/sift.html

The matlab file contains 2 parts: Part 1 allows you to manually pick corresponding features across the two images and does an affine transformation based on these selected points. Part 2 automagically select points based on SIFT and then uses RANSAC to find a good transformation

