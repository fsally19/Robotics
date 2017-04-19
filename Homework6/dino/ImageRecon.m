% Load images.
%SceneDir = fullfile(toolboxdir('vision'), 'visiondata', 'wall');
%WallScene = imageDatastore(SceneDir);

% Display images to be stitched
%montage(WallScene.Files)


% Read the first image from the image set.
%I = readimage(WallScene, 1);

% Initialize features for I(1)
%grayImage = rgb2gray(I);
%points = detectSURFFeatures(grayImage);
%[features, points] = extractFeatures(grayImage, points);

% Initialize all the transforms to the identity matrix. Note that the
% projective transform is used here because the building images are fairly
% close to the camera. Had the scene been captured from a further distance,
% an affine transform would suffice.
%numImages = numel(WallScene.Files);
%tforms(numImages) = projective2d(eye(3));
jpgfiles = dir('/home/francesca/MATLAB/R2016b/bin/toolbox/vision/visiondata/dino/*.JPG');
cd('/home/francesca/MATLAB/R2016b/bin/toolbox/vision/visiondata/dino/');
imagetotal = length(jpgfiles);
undistortedImages = {};
for i=1:imagetotal
    file = jpgfiles(i).name;
    image{i} = imread(file);
    image{i} = imrotate(image{i}, -90);
    [nodistortionImages{i}, newOrigin{i}] = undistortImage(image{i}, cameraParams, 'OutputView','full');
    nodistortionImagesGrey{i} = rgb2gray(nodistortionImages{i});
end

for i = 1:imagetotal
    [y,x,v] = harris(nodistortionImagesGrey{i}, 8000, 'tile', [8 6]); %'disp');
    [feat{i}, spot{i} ]= extractFeatures(nodistortionImagesGrey{i}, [x y]);
end

% Iterate over remaining image pairs
for i = 2:imagetotal


    % Find correspondences between I(n) and I(n-1).
    indexPairs = matchFeatures(feat{i-1}, feat{i}, 'Unique', true);

    matchedPointsPrev = spot{i-1}(indexPairs(:,1), :);
    matchedPoints = spot{i}(indexPairs(:,2), :);
    %figure %for the report
    %showMatchedFeatures(nodistortImagesGrey{i-1}, nodistortImagesGrey{i}, matchedPointsPrev, matchedPoints);

    % Estimate the transformation between I(n) and I(n-1).
    tforms(i) = estimateGeometricTransform(matchedPoints, matchedPointsPrev,...
        'projective', 'Confidence', 99.9, 'MaxNumTrials', 4000);

    % Compute T(1) * ... * T(n-1) * T(n)
    tforms(i).T = tforms(i-1).T * tforms(i).T;
end
I= nodistortionImagesGrey{1};
imageSize = size(I);  % all the images are the same size

% Compute the output limits  for each transform
for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(2)], [1 imageSize(1)]);
end

avgXLim = mean(xlim, 2);

[~, idx] = sort(avgXLim);

centerIdx = floor((numel(tforms)+1)/2);

centerImageIdx = idx(centerIdx);

Tinv = invert(tforms(centerImageIdx));

for i = 1:numel(tforms)
    tforms(i).T = Tinv.T * tforms(i).T;
end

for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(2)], [1 imageSize(1)]);
end

% Find the minimum and maximum output limits
xMin = min([1; xlim(:)]);
xMax = max([imageSize(2); xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([imageSize(1); ylim(:)]);

% Width and height of panorama.
width  = round(xMax - xMin);
height = round(yMax - yMin);

% Initialize the "empty" panorama.
panorama = zeros([height width 3], 'like', I);

blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');

% Create a 2-D spatial reference object defining the size of the panorama.
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoramaView = imref2d([height width], xLimits, yLimits);

% Create the panorama.
for i = 1:imagetotal

    I = image{i};

    % Transform I into the panorama.
    warpedImage = imwarp(I, tforms(i), 'OutputView', panoramaView);

    % Generate a binary mask.
    mask = imwarp(true(size(I,1),size(I,2)), tforms(i), 'OutputView', panoramaView);

    % Overlay the warpedImage onto the panorama.
    panorama = step(blender, panorama, warpedImage, mask);
end

figure
imshow(panorama)