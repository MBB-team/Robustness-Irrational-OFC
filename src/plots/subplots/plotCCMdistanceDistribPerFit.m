function [] = plotCCMdistanceDistribPerFit(ax, Data, plot_options)
% Code for figure 3f.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - dist_CCM_avg_OFC, dist_CCM_same_OFC, dist_CCM_other_OFC: see
%       computeNeuralDistance
%
% p_threshold, line_width, priors_color, priors_face_alpha, star_size, 
% line_y_coord_top, line_y_coord_bottom, line_x_shift, line_y_shift, 
% star_top_shift, star_bottom_shift :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    plot_options.p_threshold (1, 1) double = 0.05 / 3
    plot_options.line_width (1, 1) double = 0.5
    plot_options.priors_color (1, 3) double = [0, 0, 0]
    plot_options.priors_face_alpha (1, 1) double = 0
    plot_options.star_size (1, 1) double = 14
    plot_options.line_y_coord_top (1, 1) = 5.299
    plot_options.line_y_coord_bottom (1, 1) = 4.55
    plot_options.line_x_shift (1, 1) double = - 0.2
    plot_options.line_y_shift (1, 1) double = 0.13
    plot_options.star_top_shift (1, 1) double = 0.04
    plot_options.star_bottom_shift (1, 1) double = - 0.35
end

hold(ax, "on");

% Aesthetics
xlim(ax, [-0.9, 6.4]);
ylim(ax, [1.2, 5.3]);
xticks(ax, 0:6);
xticklabels(ax, ["Initial\newlinestate", ...
    repmat(["Ratio.", "Irratio.\newline(same)", "Irratio.\newline(other)"], 1, 2)]);
ylabel(ax, "Neural CCM distance (a.u.)");
setAxFontSize(ax);

% Plot prior distance distribution
dist_priors = Data.dist_CCM_avg_OFC(ismember(Data.config_ID, [7, 8]) & ...
    Data.fit_label == "Priors")';
customViolinplot(ax, 0, dist_priors, ...
    Color=plot_options.priors_color, ...
    FaceAlpha=plot_options.priors_face_alpha, ...
    LineStyle=defineModelLineStyle(7), ...
    LineWidth=plot_options.line_width);

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    select_config = Data.config_ID == i_config;

    % Select data
    dist_rational = Data.dist_CCM_avg_OFC(select_config & Data.is_rational);
    dist_rational = [dist_rational, NaN(size(dist_rational))]';
    dist_irrational_same = Data.dist_CCM_same_OFC(select_config & Data.is_irrational)';
    dist_irrational_other = Data.dist_CCM_other_OFC(select_config & Data.is_irrational)';
    distance_matrix = [dist_rational, dist_irrational_same, dist_irrational_other];
    
    % Plot distance distributions
    customViolinplot(ax, ...
        (1:3) + (i_config - 9) * 3, ...
        distance_matrix, ...
        Color=defineModelColor(i_config), ...
        FaceAlpha=[0.1, 0.5, 0.5], ...
        LineStyle=defineModelLineStyle(i_config), ...
        LineWidth=plot_options.line_width);

    % --- Plot stats ---- %

    % Priors vs. rational
    [~, p] = ttest(dist_priors, dist_rational);
    % Horizontal line
    line_y_coord = plot_options.line_y_coord_top + (i_config - 10) * plot_options.line_y_shift;
    x_coord = plot_options.line_x_shift + [0, 1 + (i_config - 9) * 3];
    plot(ax, x_coord, line_y_coord * ones(1, 2), ...
        Color=plot_options.priors_color, ...
        LineWidth=plot_options.line_width);
    % Star
    x_star = plot_options.line_x_shift + 0.5 + (i_config - 9) * 2;
    y_star = line_y_coord + plot_options.star_bottom_shift;
    if p < plot_options.p_threshold
        text(ax, x_star, y_star, "*", ...
            HorizontalAlignment="center", ...
            FontSize=plot_options.star_size, ...
            Color=plot_options.priors_color);
    end

    % Priors vs. irrational (other)
    [~, p] = ttest(dist_rational, dist_irrational_other);
    % Horizontal line
    line_y_coord = plot_options.line_y_coord_bottom;
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

    % Priors vs. irrational (same)
    [~, p] = ttest(dist_rational, dist_irrational_same);
    % Horizontal line
    line_y_coord = plot_options.line_y_coord_bottom - plot_options.line_y_shift;
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
