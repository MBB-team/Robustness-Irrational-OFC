function [] = plotSchemeRobustness(ax, Data)
% Code for figure 5e.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - is_irrational: see gatherAllModels
%       - prop_optimal_impaired_units: see
%       computeRobustnessToUnitLesions
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
end

hold(ax, "on");

% Plot robustness curve
robustness = mean(Data.prop_optimal_impaired_units(:, ...
    ismember(Data.config_ID, [9, 10]) & Data.is_irrational), 2)';
plot(ax, 1:9, robustness(1:9), ...
    Color="k", ...
    LineWidth=1);

% Plot average zone
avg_zone = fill(ax, [1, 5, 5, 1], [0.49, 0.49, 0.56, 0.56], "k", ...
    FaceAlpha=0.15, ...
    EdgeColor="none", ...
    DisplayName="Averaging range");

% Legend
legend(ax, avg_zone, ...
    Location="northoutside", ...
    Box="off", ...
    AutoUpdate="off", ...
    IconColumnWidth=10);

% Aesthetics
xlabel(ax, "Prop. lesioned units");
ylabel(ax, "P(rational)");
xlim(ax, [0, 10]);
ylim(ax, [0.5, .55]);
xticks(ax, 1:4:9);
xticklabels(ax, compose("%d%%", 10 * xticks(ax)))
setAxFontSize(ax);

hold(ax, "off");
