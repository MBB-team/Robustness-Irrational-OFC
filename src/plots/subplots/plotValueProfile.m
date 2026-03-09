function [] = plotValueProfile(ax, value_profile, title_label)
% Code for figure 3a, 3b and 3c.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% value_profile : <double 6x6> or <double 36x1>
%     Value profile fitted onto the behaviour of a system (see also:
%     fitOneValueProfile, fitMonkeyValueProfile).
%
% title_label : <string 1x1>
%     Subplot title.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    value_profile (:, :) double
    title_label (1, 1) string
end

% Heatmap
imagesc(ax, flipud(reshape(value_profile, 6, 6)));

% Colormap
colormap(ax, defineSequentialColormap());

% Title
title(ax, title_label);

% Ax aesthetics
axis(ax, "square");
xticks(ax, 1:6);
yticks(ax, 1:6);
xticklabels(ax, ["?", string(1:5)]);
yticklabels(ax, fliplr(["?", string(1:5)]));
xlabel(ax, "Magnitude rank");
ylabel(ax, "Probability rank");
setAxFontSize(ax);
