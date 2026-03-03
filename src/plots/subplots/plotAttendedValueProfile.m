function [] = plotAttendedValueProfile(ax, Data, select_data, title_label, plot_options)
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
% color_map :
%     Name-value parameter controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    select_data (1, :) logical
    title_label (1, 1) string = ""
    plot_options.color_map (1, 1) string = "parula"
end

% Heatmap
imagesc(ax, flipud(reshape(mean(Data.value_function_attended(:, select_data), 2), 5, 5)));

% Colormap
colormap(ax, plot_options.color_map);

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
