function [] = plotNeuralDistanceTrajectory(ax, plot_options)
% Code for figure 2c.
%
% This function plots the trajectory of RDM and CCM neural distance between
% RNNs and monkey neural recordings in the OFC, throughout the initial
% rational training of the RNNs (see also: generateNeuralGeometryMatrices,
% computeNeuralDistance).
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    plot_options.line_width (1, 1) double = 2
    plot_options.marker_size (1, 1) double = 6
    plot_options.marker_face_color (1, 3) double = [1, 1, 1]
    plot_options.marker_end_edge_color (1, 3) double = [0, 0, 0]
    plot_options.marker_priors (1, 1) string = "x"
    plot_options.marker_priors_edge_color (1, 3) double = [0, 0, 0]
    plot_options.marker_priors_size (1, 1) double = 15
end

% Load the data
Data = loadMeasureResults(["seed", "config_ID", "fit_label", "fit_step", ...
    "dist_RDM_OFC", "dist_CCM_OFC"], "rational_last");

hold(ax, "on");

% --- Plot neural distance trajectories during initial rational fit --- %

select_fit = (Data.fit_label == "FitRational");

% ~ Loop over model configs ~ %
for i_config = 1:10
    select_config = (Data.config_ID == i_config);

    % Identify individual networks
    config_seeds = unique(Data.seed(select_config));
    n_config_networks = length(config_seeds);

    % Initialize storage of neural distances interpolated on 100 steps
    config_RDM_dist = NaN(n_config_networks, 100);
    config_CCM_dist = NaN(n_config_networks, 100);

    % ~ Loop over individual networks ~ %
    for i_network = 1:n_config_networks

        select_network_dist = select_fit & select_config & ...
            (Data.seed == config_seeds(i_network));
        n_fit_steps = sum(select_network_dist);

        % Linearly interpolate neural distance trajectories during fit with
        % a fixed 100-step scale
        config_RDM_dist(i_network, :) = interp1(1:n_fit_steps, ...
            Data.dist_RDM_OFC(select_network_dist), linspace(1, n_fit_steps, 100));
        config_CCM_dist(i_network, :) = interp1(1:n_fit_steps, ...
            Data.dist_CCM_OFC(select_network_dist), linspace(1, n_fit_steps, 100));

    end

    % Average the distances across networks
    config_RDM_dist = mean(config_RDM_dist, 1);
    config_CCM_dist = mean(config_CCM_dist, 1);

    % Plot the trajectory
    plot(ax, config_RDM_dist, config_CCM_dist, ...
        Color = defineModelColor(i_config), ...
        LineStyle = defineModelLineStyle(i_config), ...
        LineWidth = plot_options.line_width, ...
        Marker = defineModelMarker(i_config), ...
        MarkerEdgeColor = defineModelColor(i_config), ...
        MarkerFaceColor = plot_options.marker_face_color, ...
        MarkerSize = plot_options.marker_size);

    % Plot the final state with a different marker color
    plot(ax, config_RDM_dist(end), config_CCM_dist(end), ...
        LineWidth = plot_options.line_width, ...
        Marker = defineModelMarker(i_config), ...
        MarkerEdgeColor = plot_options.marker_end_edge_color, ...
        MarkerFaceColor = defineModelColor(i_config), ...
        MarkerSize = plot_options.marker_size);

end

% --- Plot priors neural distances --- %

select_priors = (Data.fit_label == "Priors");

% ~ Loop over two cohorts with differing input encoding format; priors are
% shared across cohorts with similar formats ~ %
for i_config = [1, 7]

    select_config = (Data.config_ID == i_config);
    select_networks = find(select_config & select_priors, 1);

    config_RDM_dist = mean(Data.dist_RDM_OFC(select_networks));
    config_CCM_dist = mean(Data.dist_RDM_OFC(select_networks));

    % Plot the prior
    plot(ax, config_RDM_dist, config_CCM_dist, ...
        Marker = plot_options.marker_priors, ...
        MarkerEdgeColor = plot_options.marker_priors_edge_color, ...
        MarkerSize = plot_options.marker_priors_size);
end

% Custom legend handles
ghost_plots = gobjects(1, 9);
ghost_plots(1) = plot(ax, NaN, NaN, Marker="s", MarkerFaceColor=defineModelColor(1), MarkerEdgeColor="none", LineStyle="none", ...
    DisplayName="comparison");
ghost_plots(2) = plot(ax, NaN, NaN, Marker="s", MarkerFaceColor=defineModelColor(2), MarkerEdgeColor="none", LineStyle="none", ...
    DisplayName="synthesis");
ghost_plots(3) = plot(ax, NaN, NaN, LineStyle="none", ...
    DisplayName="");
ghost_plots(4) = plot(ax, NaN, NaN, Color="k", LineStyle=defineModelLineStyle(1), LineWidth=plot_options.line_width, ...
    DisplayName=" spatial");
ghost_plots(5) = plot(ax, NaN, NaN, Color="k", LineStyle=defineModelLineStyle(7), LineWidth=plot_options.line_width, ...
    DisplayName=" temporal");
ghost_plots(6) = plot(ax, NaN, NaN, LineStyle="none", ...
    DisplayName="");
ghost_plots(7) = plot(ax, NaN, NaN, Marker=defineModelMarker(5), MarkerFaceColor="none", MarkerEdgeColor="k", LineStyle="none", LineWidth=plot_options.line_width, ...
    DisplayName="spatial");
ghost_plots(8) = plot(ax, NaN, NaN, Marker=defineModelMarker(3), MarkerFaceColor="none", MarkerEdgeColor="k", LineStyle="none", LineWidth=plot_options.line_width, ...
    DisplayName="temporal");
ghost_plots(9) = plot(ax, NaN, NaN, Marker=defineModelMarker(1), MarkerFaceColor="none", MarkerEdgeColor="k", LineStyle="none", LineWidth=plot_options.line_width, ...
    DisplayName="attentional");

% Create legend
ax_legend = legend(ax, ghost_plots, ...
    NumColumns=3, ...
    Box="off", ...
    Location="southoutside");
ax_legend.Title.String = [...
    "              network                attended option        value readout", ...
    "value computation       identity format               format "];

% --- Aesthetics --- %

xlim(ax, [0.2, 1]);
ylim([2.5, 7]);
xscale(ax, "log");
yscale(ax, "log");
xlabel(ax, "Neural RDM distance (a.u.)");
ylabel(ax, "Neural CCM distance (a.u.)");
