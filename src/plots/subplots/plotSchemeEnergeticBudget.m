function [] = plotSchemeEnergeticBudget(ax)
% Code for figure 5a.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
end

hold(ax, "on");

% Compte average activity for a given input distribution
unit_inputs = linspace(-10, 10, 1000);
input_distrib = normpdf(unit_inputs, 2.5, 2);
activation_function = sigANN(unit_inputs)';
avg_activity = input_distrib .* activation_function;

% Draw average activity
fill(ax, [unit_inputs, fliplr(unit_inputs)], ...
    [avg_activity, zeros(size(avg_activity))], "k", ...
    EdgeColor="none", ...
    FaceAlpha=0.2, ...
    DisplayName="Average activity");

% Draw input distribution
plot(ax, unit_inputs, 0.8 * input_distrib / max(input_distrib), ...
    Color=0.5 * ones(1, 3), ...
    LineWidth=1, ...
    LineStyle=":", ...
    DisplayName="Input distribution");

% Draw sigmoid
plot(ax, unit_inputs, activation_function, ...
    Color="k", ...
    LineWidth=1, ...
    DisplayName="Activation function");

% Legend
legend(ax, ...
    Location="northoutside", ...
    Box="off", ...
    AutoUpdate="off", ...
    IconColumnWidth=10, ...
    NumColumns=1);

% Aesthetics
xlabel(ax, "Unit input");
xlim(ax, [min(unit_inputs), max(unit_inputs)]);
ylim(ax, [0, 1])
xticks(ax, []);
yticks(ax, []);
set(ax, YColor="none");
setAxFontSize(ax);

hold(ax, "off");
