function [] = plotAttendedValueProfile(ax, value_profile, title_label)
% Code for figure 4f, 4g, 4h and 4i.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - value_function_attended: see computeCueAttentionPollution
%
% select_data : <bool 1xN>
%     Vector defining which data points are taken into account to compute
%     the average value profile.
%     
% title_label : <string 1x1>
%     Subplot title.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    value_profile (5, 5) double
    title_label (1, 1) string = ""
end

% Heatmap
imagesc(ax, flipud(value_profile));

% Colormap
colormap(ax, defineSequentialColormap());

% Ax aesthetics
title(ax, title_label);
axis(ax, "square");
xticks(ax, 1:5);
yticks(ax, 1:5);
xticklabels(ax, string(1:5));
yticklabels(ax, string(5:-1:1));
xlabel(ax, "Previous cue rank");
ylabel(ax, "Current cue rank");
setAxFontSize(ax);
