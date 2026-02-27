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
    plot_options.line_width (1, 1) double = 0.5
    plot_options.monkey_line_style (1, 1) string = ":"
    plot_options.marker_size (1, 1) double = 3
end

hold(ax, "on");

% Load monkey data
MonkeyData = load(fullfile(getPath("MonkeyData"), "CueAttentionPollution.mat"));

% Select data for this config only
Data = selectStructFieldColumns(Data, Data.config_ID == i_config);

% Plot rational stage distribution
customViolinplot(ax, ...
    1, Data.value_function_attended_gradient_diff(Data.is_rational), ...
    Color=defineModelColor(i_config), ...
    FaceAlpha=0.2, ...
    LineStyle=defineModelLineStyle(i_config), ...
    LineWidth=plot_options.line_width);

% Plot irrational stage distribution
customViolinplot(ax, ...
    2, Data.value_function_attended_gradient_diff(Data.is_irrational), ...
    Color=defineModelColor(i_config), ...
    FaceAlpha=0.2, ...
    LineStyle=defineModelLineStyle(i_config), ...
    LineWidth=plot_options.line_width);

% Plot monkey data
x_monkey = linspace(0.3, 3.1, 8);
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

% Aesthetics
ylabel(ax, "\DeltaGradient (att. - unatt.)");
xlim(ax, [0.2, 2.2]);
xticks(ax, 1:2);
xticklabels(ax, ["Rational", "Irrational"]);
setAxFontSize(ax);

% --- Stats --- %

hold(ax, "off");
