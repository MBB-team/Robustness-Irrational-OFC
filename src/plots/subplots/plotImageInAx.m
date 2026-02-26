function [] = plotImageInAx(ax, image_path)
% Displays an image within a Matlab ax.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the image should be drawn.
%
% image_path : <string 1x1>
%     Path to the image to include.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

% Draw image in ax
img = imread(image_path);
image(ax, img)

% Remove axis ticks
axis(ax, "off");

% Preserve image aspect ratio
axis(ax, "image");
