function [] = plotRobustnessToConnectionLesionsPerFit(ax, DataIndirect, DataFranck, DataMiles, plot_options)
% Code for figure S8.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% DataIndirect : <struct 1x1>
%     Structure containing model analysis results for models trained first 
%     to be rational, then distorted to fit monkeys' behaviour. Must
%     include:
%       - config_ID, is_rational, is_irrational: see gatherAllModels
%       - avg_prop_optimal_impaired_connec: see
%       computeRobustnessToConnectionLesions
%
% DataFranck, DataMiles : <struct 1x1>
%     Structure containing model analysis results for models trained
%     directly on the behaviour of the monkey. Must include:
%       - config_ID, is_irrational: see gatherAllModels
%       - avg_prop_optimal_impaired_connec: see
%       computeRobustnessToConnectionLesions
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
    DataIndirect (1, 1) struct
    DataFranck (1, 1) struct
    DataMiles (1, 1) struct
    plot_options.line_width (1, 1) double = 0.7
    plot_options.p_threshold (1, 1) double = 0.005
    plot_options.line_y_coord_top (1, 1) double = 0.6099
    plot_options.line_x_shift (1, 1) double = - 0.2
    plot_options.line_y_coord_bottom (1, 1) double = 0.59
    plot_options.star_y_shift (1, 1) double = 0.009
    plot_options.star_size (1, 1) double = 14
end

hold(ax, "on");

% Aesthetics
xlim(ax, [-0.9, 5.9]);
ylim(ax, [0.46, 0.61]);
yticks(ax, 0.5:0.05:0.6);
xticks(ax, [0:2, 3.5 + (0:2)]);
xticklabels(ax, repmat(["Rat.", "Irrat.\newline(distort)", "Irrat.\newline(direct)"], 1, 2));
ylabel(ax, "Tolerance to disconnections (a.u.)");
setAxFontSize(ax);

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    % Select data for models trained in two steps
    select_indirect = DataIndirect.config_ID == i_config;
    prop_rational = DataIndirect.avg_prop_optimal_impaired_connec(select_indirect & DataIndirect.is_rational)';
    prop_rational = repmat(prop_rational, 2, 1);
    prop_irrational = DataIndirect.avg_prop_optimal_impaired_connec(select_indirect & DataIndirect.is_irrational)';

    % Select data for models trained directly on irrational behaviour
    select_direct_Franck = DataFranck.config_ID == i_config;
    select_direct_Miles = DataMiles.config_ID == i_config;
    prop_irrational_direct = [...
        DataFranck.avg_prop_optimal_impaired_connec(select_direct_Franck & DataFranck.is_irrational)' ; ...
        DataMiles.avg_prop_optimal_impaired_connec(select_direct_Miles & DataMiles.is_irrational)'];

    % Plot distance distributions
    customViolinplot(ax, ...
        (0:2) + (i_config - 9) * 3.5, ...
        [prop_rational, prop_irrational, prop_irrational_direct], ...
        Color=defineModelColor(i_config), ...
        FaceAlpha=[0.1, 0.5, 0.5], ...
        LineStyle=defineModelLineStyle(i_config), ...
        LineWidth=plot_options.line_width);

    % --- Plot stats ---- %

    % Rational vs. irrational (distort)
    [~, p] = ttest(prop_rational, prop_irrational);
    % Horizontal line
    line_y_coord = plot_options.line_y_coord_bottom;
    x_coord = plot_options.line_x_shift + (i_config - 9) * 3.5 + [0, 1];
    plot(ax, x_coord, line_y_coord * ones(1, 2), ...
        Color=defineModelColor(i_config), ...
        LineWidth=plot_options.line_width);
    % Star
    x_star = plot_options.line_x_shift + 0.5 + (i_config - 9) * 3.5;
    y_star = line_y_coord - plot_options.star_y_shift;
    if p < plot_options.p_threshold
        text(ax, x_star, y_star, "*", ...
            HorizontalAlignment="center", ...
            FontSize=plot_options.star_size, ...
            Color=defineModelColor(i_config));
    end

    % Rational vs. irrational (direct)
    [~, p] = ttest(prop_rational, prop_irrational_direct);
    % Horizontal line
    line_y_coord = plot_options.line_y_coord_top;
    x_coord = plot_options.line_x_shift + (i_config - 9) * 3.5 + [0, 2];
    plot(ax, x_coord, line_y_coord * ones(1, 2), ...
        Color=defineModelColor(i_config), ...
        LineWidth=plot_options.line_width);
    % Star
    x_star = plot_options.line_x_shift + 1.5 + (i_config - 9) * 3.5;
    y_star = line_y_coord - plot_options.star_y_shift;
    if p < plot_options.p_threshold
        text(ax, x_star, y_star, "*", ...
            HorizontalAlignment="center", ...
            FontSize=plot_options.star_size, ...
            Color=defineModelColor(i_config));
    end

end

% Horizontal line
yline(ax, 0.5, "k:", LineWidth=plot_options.line_width);

hold(ax, "off");
