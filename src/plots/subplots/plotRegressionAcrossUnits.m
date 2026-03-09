function [] = plotRegressionAcrossUnits(ax, UnitRecordings, plot_options)
% Code for figure M1a.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% UnitRecordings : <struct 1x1>
%     Structure containing monkey neural and behavioral recordings.
%
% monkey, i_neuron, marker_size :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    UnitRecordings (1, 1) struct
    plot_options.monkey (1, 1) string = "Franck"
    plot_options.i_neuron (1, 1) double = 68
    plot_options.marker_size (1, 1) double = 6
end

hold(ax, "on");

% Select the activity of one unit
select_neurons = (UnitRecordings.monkey == plot_options.monkey) & (UnitRecordings.area == "OFC");
all_i_neuron = unique(UnitRecordings.i_session(select_neurons));
select_single_neuron = select_neurons & (UnitRecordings.i_session == all_i_neuron(plot_options.i_neuron));
UnitRecordings = selectStructFieldColumns(UnitRecordings, select_single_neuron);

% Store activity depending on the attended cue rank
mean_activity = NaN(1, 5);
se_activity = NaN(1, 5);
for cue_rank = 1:5
    i_select_data = (UnitRecordings.i_step == 2);
    i_select_data = i_select_data(UnitRecordings.cue_rank(UnitRecordings.i_step == 1) == cue_rank);
    mean_activity(cue_rank) = mean(UnitRecordings.firing_rate(i_select_data));
    se_activity(cue_rank) = std(UnitRecordings.firing_rate(i_select_data)) / ...
        sqrt(length(i_select_data));
end

% Regression
x = 1:5;
mdl = fitlm(x', mean_activity');
a = mdl.Coefficients.Estimate(2);
b = mdl.Coefficients.Estimate(1);

% --- Plot --- %

% Regression line
plot(ax, x, a * x + b, ...
    Color=0.5* ones(1, 3), ...
    LineWidth=0.5);

% Errorbar
errorbar(ax, ...
    1:5, mean_activity, se_activity, ...
    Color="k", ...
    LineStyle="none", ...
    Marker="o", ...
    MarkerFaceColor="k", ...
    MarkerEdgeColor="w", ...
    MarkerSize=plot_options.marker_size, ...
    CapSize=0, ...
    LineWidth=1);

% Ax aesthetics
axis(ax, "square");
xticks(ax, []);
yticks(ax, []);
xlabel(ax, "$\mathbf{U_1(1)}$", Interpreter="latex");
ylabel(ax, "$\mathbf{X_2^U (\cdot, 2)}$", Interpreter="latex");
setAxFontSize(ax);

hold(ax, "off");
