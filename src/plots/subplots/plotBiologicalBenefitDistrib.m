function [] = plotBiologicalBenefitDistrib(ax, Data, measure_label, plot_options)
% Code for figure 3f.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - is_rational, is_irrational: see gatherAllModels
%       - energetic_budget_avg | code_redundancy | info_transfer_rate |
% EI_balance | avg_prop_optimal_impaired_units| : see
% computeEnergeticBudget, computeCodeRedundancy, computeInfoTransferRate,
% computeEIbalance, computeRobustnessToUnitLesions
%
% measure_label : <string 1x1>
%     Label of the measure to display.
%
% options :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    measure_label (1, 1) string
    plot_options.x_shift (1, 1) double = 0.07
    plot_options.density_width (1, 1) double = 0.36
    plot_options.line_width (1, 1) double = 0.5
    plot_options.line_y_coord_prop (1, 1) double = 0.01
    plot_options.line_x_shift (1, 1) double = 0.3
    plot_options.p_threshold (1, 1) double = 0.005
    plot_options.star_y_shift_prop (1, 1) double = - 0.067
    plot_options.label_y_shift_prop (1, 1) double = - 0.03
    plot_options.star_size (1, 1) double = 14
end

hold(ax, "on");

% Define plot aesthetics
switch measure_label
    case "energetic_budget_avg"
        y_lim = [0.3, 0.72];
        y_label = "Energetic budget (a.u.)";
    case "code_redundancy"
        y_lim = [0.315, 0.365];
        y_label = "Code redundancy (a.u.)";
    case "info_transfer_rate"
        y_lim = [-3.1, -1.5];
        y_label = "Info transfer rate (a.u.)";
    case "EI_balance"
        y_lim = [0.5, 1.65];
        y_label = "E/I balance";
    case "avg_prop_optimal_impaired_units"
        y_lim = [0.49, 0.54];
        y_label = "Tolerance to lesions (a.u.)";
end
xlim(ax, [8.4, 10.6]);
ylim(ax, y_lim);
xticks(ax, []);
ylabel(ax, y_label);
setAxFontSize(ax);

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    select_config = Data.config_ID == i_config;

    % Plot distribution for rational models
    data_rational = Data.(measure_label)(select_config & Data.is_rational)';
    customViolinplot(ax, ...
        i_config - plot_options.x_shift, ...
        data_rational, ...
        Color=defineModelColor(i_config), ...
        FaceAlpha=0.1, ...
        LineStyle=defineModelLineStyle(i_config), ...
        LineWidth=plot_options.line_width, ...
        DensityWidth=plot_options.density_width, ...
        DensityDirection="negative");

    % Plot distribution for irrational models
    data_irrational = Data.(measure_label)(select_config & Data.is_irrational)';
    customViolinplot(ax, ...
        i_config + plot_options.x_shift, ...
        data_irrational, ...
        Color=defineModelColor(i_config), ...
        FaceAlpha=0.5, ...
        LineStyle=defineModelLineStyle(i_config), ...
        LineWidth=plot_options.line_width, ...
        DensityWidth=plot_options.density_width, ...
        DensityDirection="positive");

    % --- Plot statistics: rational vs. irrational --- %

    [~, p] = ttest(repmat(data_rational, 2, 1), data_irrational);
    % Horizontal line
    line_y_coord = y_lim(2) - diff(y_lim) * plot_options.line_y_coord_prop;
    x_coord = i_config + plot_options.line_x_shift * [-1, 1];
    plot(ax, x_coord, line_y_coord * ones(1, 2), ...
        Color=defineModelColor(i_config), ...
        LineWidth=plot_options.line_width);
    if p < plot_options.p_threshold
        % Star
        x_star = i_config;
        y_star = line_y_coord + diff(y_lim) * plot_options.star_y_shift_prop;
        text(ax, x_star, y_star, "*", ...
            HorizontalAlignment="center", ...
            FontSize=plot_options.star_size, ...
            Color=defineModelColor(i_config));
    else
        % "n.s." label
        x_label = i_config;
        y_label = line_y_coord + diff(y_lim) * plot_options.label_y_shift_prop;
        text(ax, x_label, y_label, "n.s.", ...
            HorizontalAlignment="center", ...
            FontSize=8, ...
            Color=defineModelColor(i_config));
    end
end

% Re-enforce y limit
ylim(ax, y_lim);

hold(ax, "off");
