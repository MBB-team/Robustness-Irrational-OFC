function [] = plotRobustnessToNeuralNoiseTrajectoryPerFit(ax, Data, plot_options)
% Code for figure S8.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results for models trained first 
%     to be rational, then distorted to fit monkeys' behaviour. Must
%     include:
%       - config_ID, is_rational, is_irrational: see gatherAllModels
%       - avg_prop_optimal_impaired_connec: see
%       prop_optimal_noise
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
    plot_options.line_width (1, 1) double = 0.7
    plot_options.marker_size (1, 1) double = 6
    plot_options.line_style_rational (1, 1) string = "--"
    plot_options.line_style_irrational (1, 1) string = "-"
    plot_options.face_alpha (1, 1) double = 0.1
    plot_options.p_threshold (1, 1) double = 0.005
    plot_options.star_y_coord (1, 1) double = 0.71
    plot_options.star_size (1, 1) double = 14
end

hold(ax, "on");

VAR_NOISE = [0.001, 0.005, 0.01, 0.05, 0.1, 0.5];

% --- Plot standard deviation --- %

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    % Select data
    select_config = Data.config_ID == i_config;

    for fit_phase = ["rational", "irrational"]
    
        mean_data = mean(Data.prop_optimal_noise(:, select_config & Data.("is_" + fit_phase)), 2)';
        std_data = std(Data.prop_optimal_noise(:, select_config & Data.("is_" + fit_phase)), 0, 2)';

        % Plot standard deviation
        fill(ax, [VAR_NOISE, fliplr(VAR_NOISE)], [mean_data - std_data, fliplr(mean_data + std_data)], "k", ...
            FaceColor=defineModelColor(i_config), ...
            EdgeColor="none", ...
            FaceAlpha=plot_options.face_alpha);
    end
end

% --- Plot mean --- %

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    % Select data
    select_config = Data.config_ID == i_config;

    for fit_phase = ["rational", "irrational"]
    
        % Plot mean robustness
        plot(ax, VAR_NOISE, mean(Data.prop_optimal_noise(:, select_config & Data.("is_" + fit_phase)), 2)', ...
            Marker="o", ...
            MarkerSize=plot_options.marker_size, ...
            MarkerEdgeColor="none", ...
            MarkerFaceColor=defineModelColor(i_config), ...
            Color=defineModelColor(i_config), ...
            LineWidth=plot_options.line_width, ...
            LineStyle=plot_options.("line_style_" + fit_phase));
    end
end

% --- Legend --- %

ghost_plots = gobjects(1, 4);
ghost_plots(1) = plot(ax, NaN, NaN, ...
    LineWidth=plot_options.line_width, ...
    Color=defineModelColor(9), ...
    DisplayName="Value synthesis");
ghost_plots(2) = plot(ax, NaN, NaN, ...
    LineWidth=plot_options.line_width, ...
    Color=defineModelColor(10), ...
    DisplayName="Value comparison");
ghost_plots(3) = plot(ax, NaN, NaN, ...
    LineStyle=plot_options.line_style_rational, ...
    LineWidth=plot_options.line_width, ...
    Color="k", ...
    DisplayName="Rational");
ghost_plots(4) = plot(ax, NaN, NaN, ...
    LineStyle=plot_options.line_style_irrational, ...
    LineWidth=plot_options.line_width, ...
    Color="k", ...
    DisplayName="Irrational");
legend(ax, ghost_plots, ...
    NumColumns=2, ...
    Box="off", ...
    Location="northoutside", ...
    IconColumnWidth=20, ...
    AutoUpdate="off");

% Aesthetics
xlim(ax, [0.0008, 0.7]);
ylim(ax, [0.5, 0.72]);
xlabel(ax, "Noise variance");
ylabel(ax, "Tolerance to neural noise (a.u.)");
xscale(ax, "log");
setAxFontSize(ax);

% --- Stats --- %

for i_var_noise = 1:length(VAR_NOISE)

    % Select robustness measure for that noise level
    rational_synthesis = Data.prop_optimal_noise(i_var_noise, Data.config_ID == 9 & Data.is_rational);
    rational_synthesis = repmat(rational_synthesis, 1, 2);
    irrational_synthesis = Data.prop_optimal_noise(i_var_noise, Data.config_ID == 9 & Data.is_irrational);
    rational_comparison = Data.prop_optimal_noise(i_var_noise, Data.config_ID == 10 & Data.is_rational);
    rational_comparison = repmat(rational_comparison, 1, 2);
    irrational_comparison = Data.prop_optimal_noise(i_var_noise, Data.config_ID == 10 & Data.is_irrational);

    % Test difference between rational and irrational models
    [~, p_synthesis] = ttest(rational_synthesis, irrational_synthesis);
    [~, p_comparison] = ttest(rational_comparison, irrational_comparison);
    
    % Plot
    if p_synthesis < plot_options.p_threshold && ...
            p_comparison < plot_options.p_threshold && ...
            mean(rational_synthesis) < mean(irrational_synthesis) && ...
            mean(rational_comparison) < mean(irrational_comparison)
        text(ax, VAR_NOISE(i_var_noise), plot_options.star_y_coord, "*", ...
            Color="k", ...
            FontSize=plot_options.star_size, ...
            HorizontalAlignment="center");
    end
end

% Horizontal line
yline(ax, 0.5, "k:", LineWidth=plot_options.line_width);

hold(ax, "off");
