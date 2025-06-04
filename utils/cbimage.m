function imFinal = cbimage(im1, im2, nSub, subInt)
% CBIMAGE checkerboard image, superimpose two images (grayscale/RGB) with a chess pattern
%
% Syntax:
%   imFinal = cbimage(im1, im2);
%   imFinal = cbimage(im1, im2, 20);     % 20 subdivisions
%   imFinal = cbimage(im1, im2, [], 10); % lower-intensity pattern got -10 % of max-min
%
% Inputs:
%       im1: grayscale or RGB image of any size (NxNx1 or NxNx3)
%       im2: second grayscale or RGB image with the size of im1
%      nSub: number of subdivisions (1x1 for x==y-direction or 1x2 for [x-, y-direction]) 
%            {default: [12, 12]}       (optional)
%    subInt: relative subtracted intensity in percent of max-min
%            {default: 10% of max-min} (optional)
%
% Outputs:
%   imFinal: Superimposed image with the same class and same size as the input images
%   
% Examples:
%   % Grayscale Example
%   I1 = dicomread('CT-MONO2-16-ankle.dcm');
%   I2 = I1;
%   I2(44:471, 112:372) = I1(44:471, 120:380); % shift the ankle by 8 pixels
%   IC = cbimage(I1, I2);
%   imshow(IC, [])
%   
%   % RGB Example
%   I1 = imread('peppers.png');
%   h = fspecial('average', [4 4]);
%   I2 = imfilter(I1, h);
%   % create the chess image with 9 x- and 12 y-subdivisions and 20 % subtracted intensity
%   IC = cbimage(I1, I2, [12, 9], 20); 
%   imshow(IC)
%
% Requirements:
%   TheMathWorks Image Processing Toolbox (just for the RGB example)
%
% Author:
%   Daniel Kellner, 2011, braggpeaks{}googlemail.com
%   History: v1.00: 2011/08/29

if nargin < 2 || nargin > 4
    error('Incorrect number of input arguments, please refer to the function file!')
end

if ~exist('nSub', 'var') || isempty(nSub)
    nSub = [12, 12];
else
    if isequal(numel(nSub), 1)
        nSub = [nSub, nSub];
    elseif numel(nSub) > 2
        error('Incorrect parameter for number of subdivisions (must be 1x1 or 1x2)')
    end
end

nLayer = size(im1, 3); % == 1 for grayscale, 3 for RGB
subIntensity = zeros(nLayer, 1);
maxValues = squeeze(max(max(im1)));
minValues = squeeze(min(min(im1)));
if ~exist('subInt', 'var') || isempty(subInt)
    for lay = 1:nLayer
        subIntensity(lay) = (maxValues(lay) - minValues(lay)) .* 0.10;
    end
else
    for lay = 1:nLayer
        subIntensity(lay) = (maxValues(lay) - minValues(lay)) .* (subInt ./ 100);
    end
end

if ~isnumeric(im1) || ~isnumeric(im2) ||...
   ~isequal(size(im1), size(im2)) || (~isequal(nLayer, 1) && ~isequal(nLayer, 3))
    error('Input images must be numeric, of the same size and in 2D (grayscale or RGB)!')
end

if ~isnumeric(nSub) || any(nSub < 1) || any(nSub > 200)
    error('Number of subdivisions must be in the range of [1..200]')
end

% image dimensions
nCol = size(im1, 1);
nRow = size(im1, 2);

% preallocate the resulting image to image1
imFinal = im1; 

% nodes of the pattern (have to be rounded)
xNodes = round(linspace(0, nCol, nSub(2)+1));
yNodes = round(linspace(0, nRow, nSub(1)+1));

% overwrite the checkerboard pattern with the values of image2
for cRow = 1:length(xNodes)-1
    for cCol = 1:length(yNodes)-1   
        xRange = xNodes(cRow) + 1 : xNodes(cRow + 1);
        yRange = yNodes(cCol) + 1 : yNodes(cCol + 1);
        
        if rem(cCol + cRow, 2)     % odds will lead to the chess pattern
            for cLay = 1:nLayer    % loop through all layers
                imFinal(xRange, yRange, cLay) = im2(xRange, yRange, cLay) - subIntensity(cLay);
            end
        end
    end
end