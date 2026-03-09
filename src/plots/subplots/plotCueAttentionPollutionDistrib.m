function [] = plotCueAttentionPollutionDistrib(ax, Data, i_config, plot_options)
% Code for figure 4j and 4k.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - is_rational: see gatherAllModels
%       - is_irrational: see gatherAllModels
%       - value_function_attended_gradient_diff: see
%       computeCueAttentionPollution
%
% Monkey : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - is_rational: see gatherAllModels
%       - is_irrational: see gatherAllModels
%       - value_function_attended_gradient_diff: see
%       computeCueAttentionPollution
%
% i_config : <int 1x1>
%     Index of the network configuration whose data to display.     
%
% line_width, monkey_line_style, marker_size :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    i_config (1, 1) double
    plot_options.distrib_x_shift (1, 1) double = 0.15
    plot_options.line_width (1, 1) double = 0.5
    plot_options.monkey_line_style (1, 1) string = ":"
    plot_options.marker_size (1, 1) double = 3
    plot_options.y_lim (1, 2) double = [-1, 0.2]
    plot_options.line_y_coord (1, 1) double = 0.199
    plot_options.star_y_shift (1, 1) double = -0.09
    plot_options.star_size (1, 1) double = 14
    plot_options.p_threshold (1, 1) double = 0.01
end

hold(ax, "on");

% Load monkey data
MonkeyData = load(fullfile(getPath("MonkeyData"), "CueAttentionPollution.mat"));

% Select data for this config only
Data = selectStructFieldColumns(Data, Data.config_ID == i_config);

% Plot rational stage distribution
customViolinplot(ax, ...
    - plot_options.distrib_x_shift, Data.value_function_attended_gradient_diff(Data.is_rational)', ...
    Color=defineModelColor(i_config), ...
    FaceAlpha=0.1, ...
    DensityDirection="negative", ...
    LineStyle=defineModelLineStyle(i_config), ...
    LineWidth=plot_options.line_width);

% Plot irrational stage distribution
customViolinplot(ax, ...
    plot_options.distrib_x_shift, Data.value_function_attended_gradient_diff(Data.is_irrational)', ...
    Color=defineModelColor(i_config), ...
    FaceAlpha=0.5, ...
    DensityDirection="positive", ...
    LineStyle=defineModelLineStyle(i_config), ...
    LineWidth=plot_options.line_width);

% Aesthetics
yline(ax, 0, "k:", LineWidth=0.1);
ylabel(ax, "\DeltaGradient (att. - unatt.)");
xlim(ax, [-0.8, 0.8]);
ylim(ax, plot_options.y_lim);
xticks(ax, plot_options.distrib_x_shift * [-2.5, 2.5]);
xticklabels(ax, ["Rational", "Irrational"]);
setAxFontSize(ax);

% Plot monkey data
x_lim = xlim(ax);
x_monkey = linspace(x_lim(1), x_lim(2), 8);
for monkey = ["Franck", "Miles"]
    plot(ax, x_monkey, ...
        MonkeyData.(monkey).value_function_attended_gradient_diff * ones(1, length(x_monkey)), ...
        Color=defineMonkeyColor(monkey), ...
        Marker=defineMonkeyMarker(monkey), ...
        MarkerSize=plot_options.marker_size, ...
        MarkerFaceColor=defineMonkeyColor(monkey), ...
        MarkerEdgeColor="none", ...
        LineWidth=plot_options.line_width, ...
        LineStyle=plot_options.monkey_line_style);
end

% --- Stats --- %

grad_diff_rational = Data.value_function_attended_gradient_diff(Data.is_rational)';
grad_diff_rational = repmat(grad_diff_rational, 2, 1);
grad_diff_irrational = Data.value_function_attended_gradient_diff(Data.is_irrational)';
[~, p] = ttest(grad_diff_rational, grad_diff_irrational);
% Horizontal line
line_y_coord = plot_options.line_y_coord;
x_coord =[-0.4, 0.4];
plot(ax, x_coord, line_y_coord * ones(1, 2), ...
    Color=defineModelColor(i_config), ...
    LineWidth=plot_options.line_width);
% Star
x_star = 0;
y_star = line_y_coord + plot_options.star_y_shift;
if p < plot_options.p_threshold
    text(ax, x_star, y_star, "*", ...
        HorizontalAlignment="center", ...
        FontSize=plot_options.star_size, ...
        Color=defineModelColor(i_config));
end

hold(ax, "off");
