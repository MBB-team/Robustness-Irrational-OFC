function [] = plotConstraintsVsRationality(ax, Data, constraint_label, x_label, plot_options)
% Code for figure 1c, 1d and 1e.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - fit_label
%       - constraint_weight: see trainModelsInitialRationalConstrained
%       - constraint_label
%       - bacc_optimal_avg: see predictOptimalChoices
%
% constraint_label : <string 1x1>
%     Name of the scalar field used as the constraint signal during the
%     joint optimization (see trainModelsInitialRationalConstrained).
%
% x_label : <string 1x1>
%     Human-friendly constraint label.
%
% cap_size, marker, marker_size, line_width, marker_edge_color, color_map :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    constraint_label (1, 1) string
    x_label (1, 1) string
    plot_options.cap_size (1, 1) double = 0
    plot_options.marker (1, 1) string = "o"
    plot_options.marker_size (1, 1) double = 6
    plot_options.line_width (1, 1) double = 1
    plot_options.marker_edge_color (1, 3) double = [1, 1, 1]
    plot_options.color_map (1, 1) function_handle = @parula
end

hold(ax, "on");
% --- Bin data by constraint weight --- %

% Initialize constraint adequacy and rationality storage
select_trained = (Data.fit_label ~= "Priors");
all_weights = unique(Data.constraint_weight(select_trained));
n_weights = length(all_weights);
constraint_adequacy_avg = NaN(1, n_weights);
constraint_adequacy_se = NaN(1, n_weights);
bacc_optimal_avg = NaN(1, n_weights);
bacc_optimal_se = NaN(1, n_weights);

% Store data for each constraint weight level
for i_weight = 1:n_weights
    % Select data
    select_weight = (Data.constraint_weight == all_weights(i_weight));
    constraint_adequacy = Data.(constraint_label)(select_trained & select_weight);
    bacc_optimal = Data.bacc_optimal_avg(select_trained & select_weight);
    % Compute summary statistics
    constraint_adequacy_avg(i_weight) = mean(constraint_adequacy);
    constraint_adequacy_se(i_weight) = std(constraint_adequacy) / sqrt(length(constraint_adequacy));
    bacc_optimal_avg(i_weight) = mean(bacc_optimal);
    bacc_optimal_se(i_weight) = std(bacc_optimal) / sqrt(length(bacc_optimal));
end

% --- Scatter with error bars --- %

% Discrete colormap
color_map = plot_options.color_map(n_weights);
for i_weight = 1:n_weights
    % Scatter
    errorbar(ax, ...
        constraint_adequacy_avg(i_weight), bacc_optimal_avg(i_weight), ...
        constraint_adequacy_se(i_weight), constraint_adequacy_se(i_weight), ...
        bacc_optimal_se(i_weight), bacc_optimal_se(i_weight), ...
        CapSize=plot_options.cap_size, ...
        Marker=plot_options.marker, ...
        MarkerFaceColor=color_map(i_weight, :), ...
        MarkerEdgeColor=plot_options.marker_edge_color);
end

% Colorbar
cbar = colorbar(ax, ...
    Location="eastoutside", ...
    Ticks=[0, 1], ...
    TickLabels=["min", "max"]);
cbar.Label.String = "Constraint weight";
cbar.Label.Position(1) = cbar.Label.Position(1) - 1.5;

% Aesthetics
ylim(ax, [0.45,  1]);
xlabel(ax, x_label);
ylabel(ax, "P(rational choice)");
xticks(ax, []);
setAxFontSize(ax);

hold(ax, "off");
