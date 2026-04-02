function [] = plotRobustnessTrajectoryPerFit(ax, measure_type, DataIndirect, DataFranck, DataMiles, plot_options)
% Code for figure S8.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% measure_type : <string 1x1>
%     Field indicating whether to plot the robustness to connection lesions
%     ("impaired_connec") or to neural noise ("noise").
%
% DataIndirect : <struct 1x1>
%     Structure containing model analysis results for models trained first 
%     to be rational, then distorted to fit monkeys' behaviour. Must
%     include:
%       - config_ID, is_rational, is_irrational: see gatherAllModels
%       - prop_optimal_impaired_units, prop_optimal_impaired_connec, or
%       prop_optimal_noise: see computeRobustnessToUnitLesions, 
%       computeRobustnessToConnectionLesions or
%       computeRobustnessToInternalNoise
%
% DataFranck, DataMiles : <struct 1x1>
%     Structure containing model analysis results for models trained
%     directly on the behaviour of the monkey. Must include:
%       - config_ID, is_irrational: see gatherAllModels
%       - avg_prop_optimal_impaired_units, 
%       - prop_optimal_impaired_units, prop_optimal_impaired_connec, or
%       prop_optimal_noise: see computeRobustnessToUnitLesions, 
%       computeRobustnessToConnectionLesions or
%       computeRobustnessToInternalNoise
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
    measure_type (1, 1) string
    DataIndirect (1, 1) struct
    DataFranck (1, 1) struct
    DataMiles (1, 1) struct
    plot_options.line_width (1, 1) double = 0.7
    plot_options.cap_size (1, 1) double = 0
    plot_options.marker_size (1, 1) double = 5
    plot_options.marker_alpha (1, 1) double = 0.4
    plot_options.marker_rational (1, 1) string = "o"
    plot_options.marker_irrational (1, 1) string = "^"
    plot_options.marker_irrational_direct (1, 1) string = "diamond"
    plot_options.line_style_rational (1, 1) string = ":"
    plot_options.line_style_irrational (1, 1) string = "-"
    plot_options.line_style_irrational_direct (1, 1) string = "-"
    plot_options.face_alpha (1, 1) double = 0.1
    plot_options.p_threshold (1, 1) double = 0.005
    plot_options.star_y_coord (1, 1) double = 0.025
    plot_options.star_size (1, 1) double = 14
    plot_options.plot_legend (1, 1) logical = false
end

hold(ax, "on");

if measure_type == "noise"
    x_values = [0.001, 0.005, 0.01, 0.05, 0.1, 0.5];
    i_select_impairement_level = 1:length(x_values);
else
    i_select_impairement_level = 1:9;
    x_values = 1:9;
end

% Initialize storage of data
prop_rational = cell(1, 2);
prop_irrational = cell(1, 2);
prop_irrational_direct = cell(1, 2);
i_cell = 1;

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    % Select data for models trained in two steps
    select_indirect = DataIndirect.config_ID == i_config;
    prop_rational{i_cell} = DataIndirect.("prop_optimal_" + measure_type)(...
        i_select_impairement_level, select_indirect & DataIndirect.is_rational)';
    prop_rational{i_cell} = repmat(prop_rational{i_cell}, 2, 1);
    prop_irrational{i_cell} = DataIndirect.("prop_optimal_" + measure_type)(...
        i_select_impairement_level, select_indirect & DataIndirect.is_irrational)';
    
    % Select data for models trained directly on irrational behaviour
    select_direct_Franck = DataFranck.config_ID == i_config;
    select_direct_Miles = DataMiles.config_ID == i_config;
    prop_irrational_direct{i_cell} = [...
        DataFranck.("prop_optimal_" + measure_type)(...
        i_select_impairement_level, select_direct_Franck & DataFranck.is_irrational)' ; ...
        DataMiles.("prop_optimal_" + measure_type)(...
        i_select_impairement_level, select_direct_Miles & DataMiles.is_irrational)'];

    % Compute summary statistics
    mean_prop_rational = mean(prop_rational{i_cell}, 1);
    mean_prop_irrational = mean(prop_irrational{i_cell}, 1);
    mean_prop_irrational_direct = mean(prop_irrational_direct{i_cell}, 1);
    se_prop_rational = std(prop_rational{i_cell}, 0, 1) / size(prop_rational{i_cell}, 1);
    se_prop_irrational = std(prop_irrational{i_cell}, 0, 1) / size(prop_irrational{i_cell}, 1);
    se_prop_irrational_direct = std(prop_irrational_direct{i_cell}, 0, 1) / size(prop_irrational_direct{i_cell}, 1);

    % --- Plot --- %

    % Rational
    errorbar(ax, x_values, mean_prop_rational, se_prop_rational, ...
        CapSize=plot_options.cap_size, ...
        LineWidth=plot_options.line_width, ...
        Color=defineModelColor(i_config), ...
        Marker=plot_options.marker_rational, ...
        MarkerSize=plot_options.marker_size, ...
        MarkerEdgeColor="w", ...
        MarkerFaceColor=defineModelColor(i_config), ...
        LineStyle=plot_options.line_style_rational);

    % Irrational (distort)
    errorbar(ax, x_values, mean_prop_irrational, se_prop_irrational, ...
        CapSize=plot_options.cap_size, ...
        LineWidth=plot_options.line_width, ...
        Color=defineModelColor(i_config), ...
        Marker=plot_options.marker_irrational, ...
        MarkerSize=plot_options.marker_size, ...
        MarkerEdgeColor="w", ...
        MarkerFaceColor=defineModelColor(i_config), ...
        LineStyle=plot_options.line_style_irrational);

    % Irrational (direct)
    errorbar(ax, x_values, mean_prop_irrational_direct, se_prop_irrational_direct, ...
        CapSize=plot_options.cap_size, ...
        LineWidth=plot_options.line_width, ...
        Color=defineModelColor(i_config), ...
        Marker=plot_options.marker_irrational_direct, ...
        MarkerSize=plot_options.marker_size, ...
        MarkerEdgeColor="w", ...
        MarkerFaceColor=defineModelColor(i_config), ...
        LineStyle=plot_options.line_style_irrational_direct);

    i_cell = i_cell + 1;

end

% --- Legend --- %

if plot_options.plot_legend
    ghost_plots = gobjects(1, 3);
    ghost_plots(1) = plot(ax, NaN, NaN, ...
        LineStyle=plot_options.line_style_irrational_direct, ...
        LineWidth=plot_options.line_width, ...
        Color="k", ...
        Marker=plot_options.marker_irrational_direct, ...
        MarkerSize=plot_options.marker_size, ...
        MarkerFaceColor="k", ...
        MarkerEdgeColor="w", ...
        DisplayName="Irrational (direct)");
    ghost_plots(2) = plot(ax, NaN, NaN, ...
        LineStyle=plot_options.line_style_irrational, ...
        LineWidth=plot_options.line_width, ...
        Color="k", ...
        Marker=plot_options.marker_irrational, ...
        MarkerSize=plot_options.marker_size, ...
        MarkerFaceColor="k", ...
        MarkerEdgeColor="w", ...
        DisplayName="Irrational (distorted)");
    ghost_plots(3) = plot(ax, NaN, NaN, ...
        LineStyle=plot_options.line_style_rational, ...
        LineWidth=plot_options.line_width, ...
        Color="k", ...
        Marker=plot_options.marker_rational, ...
        MarkerSize=plot_options.marker_size, ...
        MarkerFaceColor="k", ...
        MarkerEdgeColor="w", ...
        DisplayName="Rational");
    legend(ax, ghost_plots, ...
        Box="off", ...
        Location="northeast", ...
        IconColumnWidth=20, ...
        AutoUpdate="off");
end

% Aesthetics
ylim(ax, [0.48, 0.7]);
switch measure_type
    case "impaired_units"
        xlabel(ax, "Perc. lesions");
        ylabel(ax, "Tolerance to lesions (a.u.)");
    case "impaired_connec"
        xlabel(ax, "Perc. disconnections");
        ylabel(ax, "Tolerance to disconnections (a.u.)");
    case "noise"
        xlabel(ax, "Noise variance");
        ylabel(ax, "Tolerance to neural noise (a.u.)");
    otherwise
        error("Unknown robustness measure label.")
end
if measure_type == "noise"
    xlim(ax, [0.0008, 0.7]);
    xticks(ax, [1e-3, 1e-2, 1e-1]);
    xscale(ax, "log");
else
    xlim(ax, [0.5, 9.5]);
    xticks(ax, 1:2:10);
    xticklabels(ax, compose("%d", 10:20:100));
end
y_lim = ylim(ax);
setAxFontSize(ax);

% --- Stats --- %

for i_impairement_level = i_select_impairement_level

    % Check whether all p-values are below a threshold
    is_signif = true;
    for i_cell = 1:2
        % Rational vs. irrational (distorted)
        [~, p] = ttest2(prop_rational{i_cell}(:, i_impairement_level), ...
            prop_irrational{i_cell}(:, i_impairement_level));
        is_signif = is_signif & p < plot_options.p_threshold;
        % Rational vs. irrational (direct)
        [~, p] = ttest2(prop_rational{i_cell}(:, i_impairement_level), ...
            prop_irrational_direct{i_cell}(:, i_impairement_level));
        is_signif = is_signif & p < plot_options.p_threshold;
    end

    % Plot
    if is_signif
        text(ax, x_values(i_impairement_level), ...
            y_lim(1) + plot_options.star_y_coord * diff(y_lim), "*", ...
            FontSize=plot_options.star_size, ...
            HorizontalAlignment="center");
    end
end

% Horizontal line
yline(ax, 0.5, "k:", LineWidth=plot_options.line_width);

hold(ax, "off");
