function [] = plotCorrelationAcrossRegressionCoefficients(ax, tstats, plot_options)
% Code for figure M1b.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% tstats : <double Nx3x3>
%     T-statstics for the encoding of the rank of each cue (2nd dimension),
%     evaluated at each sampling step (3rd dimension), for each unit (1st
%     dimension). See also: computeCCM.
%
% rng, marker_size :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    tstats (:, 3, 3) double
    plot_options.rng (1, 1) double = 6
    plot_options.marker_size (1, 1) double = 30
end

hold(ax, "on");

% Ax aesthetics
axis(ax, "square");
xticks(ax, []);
yticks(ax, []);
xlabel(ax, "$\mathbf{\tilde{\beta}_2(2)}$", Interpreter="latex");
ylabel(ax, "$\mathbf{\tilde{\beta}_1(2)}$", Interpreter="latex");
setAxFontSize(ax);

% Select neurons' t-statistics
rng(plot_options.rng);
select_neurons = randi(7, size(tstats, 1), 1) == 1;
tstats_step2 = tstats(select_neurons, 2, 2);
tstats_step1 = tstats(select_neurons, 1, 2);

% Regression
mdl = fitlm(tstats_step2, tstats_step1);
a = mdl.Coefficients.Estimate(2);
b = mdl.Coefficients.Estimate(1);

% --- Plot --- %

% Regression line
plot(ax, tstats_step2, a * tstats_step2 + b, ...
    Color=0.5* ones(1, 3), ...
    LineWidth=0.5);
% Data points
scatter(ax, tstats_step2, tstats_step1, plot_options.marker_size, "k", "filled", ...
    MarkerEdgeColor="w", ...
    LineWidth=0.7);
% Point label
[~, i_neuron] = sort(tstats_step1, "descend");
i_neuron = i_neuron(1);
label_step1 = tstats_step1(i_neuron);
label_step2 = tstats_step2(i_neuron);
text(ax, ...
    label_step2 + 0.1 * diff(xlim(ax)), label_step1 + 0.1 * diff(ylim(ax)), ...
    "One neuron", ...
    FontName="Arial", ...
    FontSize=8, ...
    HorizontalAlignment="center");

hold(ax, "off");
