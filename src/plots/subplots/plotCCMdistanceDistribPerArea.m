function [] = plotCCMdistanceDistribPerArea(ax, Data, plot_options)
% Code for figure 3g and S7d.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - dist_CCM_avg_OFC, dist_CCM_avg_dlPFC, dist_CCM_avg_ACC: see
%       computeNeuralDistance
%
% p_threshold, line_width, star_size, line_y_coord, line_x_shift, 
% line_y_shift, star_bottom_shift :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    plot_options.p_threshold (1, 1) double = 0.05 / 3
    plot_options.line_width (1, 1) double = 0.5
    plot_options.star_size (1, 1) double = 14
    plot_options.line_y_coord_top (1, 1) = 4.599
    plot_options.line_x_shift (1, 1) double = - 0.2
    plot_options.line_y_shift (1, 1) double = 0.1
    plot_options.star_bottom_shift (1, 1) double = - 0.2
end

hold(ax, "on");

% Aesthetics
xlim(ax, [0.1, 6.4]);
ylim(ax, [1.4, 4.6]);
xticks(ax, 1:6);
xticklabels(ax, repmat(["OFC", "dlPFC", "ACC"], 1, 2));
ylabel(ax, "Neural CCM distance (a.u.)");
setAxFontSize(ax);

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    select_config = Data.config_ID == i_config;

    % Select data
    dist_OFC = Data.dist_CCM_avg_OFC(select_config & Data.is_irrational)';
    dist_dlPFC = Data.dist_CCM_avg_dlPFC(select_config & Data.is_irrational)';
    dist_ACC = Data.dist_CCM_avg_ACC(select_config & Data.is_irrational)';
    distance_matrix = [dist_OFC, dist_dlPFC, dist_ACC];

    % Plot distance distributions
    customViolinplot(ax, ...
        (1:3) + (i_config - 9) * 3, ...
        distance_matrix, ...
        Color=defineModelColor(i_config), ...
        FaceAlpha=0.5, ...
        LineStyle=defineModelLineStyle(i_config), ...
        LineWidth=plot_options.line_width);

    % --- Plot stats ---- %

    % OFC vs. dlPFC
    [~, p] = ttest(dist_OFC, dist_dlPFC);
    % Horizontal line
    line_y_coord = plot_options.line_y_coord_top;
    x_coord = plot_options.line_x_shift + [1, 3] + (i_config - 9) * 3;
    plot(ax, x_coord, line_y_coord * ones(1, 2), ...
        Color=defineModelColor(i_config), ...
        LineWidth=plot_options.line_width);
    % Star
    x_star = plot_options.line_x_shift + 2.5 + (i_config - 9) * 3;
    y_star = line_y_coord + plot_options.star_bottom_shift;
    if p < plot_options.p_threshold
        text(ax, x_star, y_star, "*", ...
            HorizontalAlignment="center", ...
            FontSize=plot_options.star_size, ...
            Color=defineModelColor(i_config));
    end

    % OFC vs. ACC
    [~, p] = ttest(dist_OFC, dist_ACC);
    % Horizontal line
    line_y_coord = plot_options.line_y_coord_top - plot_options.line_y_shift;
    x_coord = plot_options.line_x_shift + [1, 2] + (i_config - 9) * 3;
    plot(ax, x_coord, line_y_coord * ones(1, 2), ...
        Color=defineModelColor(i_config), ...
        LineWidth=plot_options.line_width);
    % Star
    x_star = plot_options.line_x_shift + 1.5 + (i_config - 9) * 3;
    y_star = line_y_coord + plot_options.star_bottom_shift;
    if p < plot_options.p_threshold
        text(ax, x_star, y_star, "*", ...
            HorizontalAlignment="center", ...
            FontSize=plot_options.star_size, ...
            Color=defineModelColor(i_config));
    end

end

hold(ax, "off");
