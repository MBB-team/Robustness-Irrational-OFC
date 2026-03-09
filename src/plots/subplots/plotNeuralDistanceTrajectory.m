function [] = plotNeuralDistanceTrajectory(ax, Data, inlay_plot, plot_options)
% Code for figure 2c.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID, is_rational, fit_step, fit_label, seed: see
%       gatherAllModels
%       - dist_RDM_avg_OFC, dist_CCM_avg_OFC: see computeNeuralDistance
%
% inlay_plot : <bool 1x1>
%     Whether the function plots in an inlay ax (true) or a classical ax
%     (false).
%
% line_width, marker_size, marker_face_color, marker_end_edge_color, 
% marker_priors, marker_priors_edge_color, marker_priors_size:
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    inlay_plot (1, 1) logical
    plot_options.n_steps (1, 1) double = 50
    plot_options.area_face_alpha (1, 1) double = 0.1
    plot_options.line_width (1, 1) double = 0.7
    plot_options.marker_size (1, 1) double = 4
    plot_options.marker_face_color (1, 3) double = [1, 1, 1]
    plot_options.marker_end_edge_color (1, 3) double = [0, 0, 0]
    plot_options.marker_end_size (1, 1) double = 5
    plot_options.marker_end_line_width (1, 1) double = 1
    plot_options.marker_priors (1, 1) string = "x"
    plot_options.marker_priors_edge_color (1, 3) double = [0, 0, 0]
    plot_options.marker_priors_size (1, 1) double = 10
    plot_options.marker_priors_line_width (1, 1) double = 1
end

hold(ax, "on");

% --- Plot H0 (priors) distribution for models taking order inputs --- %

% Select neural distance distirbutions
select_H0 = ismember(Data.config_ID, 7:10) & Data.fit_step == 1;
dist_RDM_H0 = Data.dist_RDM_avg_OFC(select_H0);
dist_CCM_H0 = Data.dist_CCM_avg_OFC(select_H0);

% Compute the 95% confidence interval threshold
ci_RDM = computeConfidenceInterval(dist_RDM_H0);
ci_CCM = computeConfidenceInterval(dist_CCM_H0);

% Plot the neural space area where both distances are below the 95%
% confidence interval
fill(ax, [0.01, ci_RDM(1), ci_RDM(1), 0.01], [ci_CCM(1), ci_CCM(1), 0.01, 0.01], "k", ...
    EdgeColor="none", ...
    FaceColor="k", ...
    FaceAlpha=plot_options.area_face_alpha);

% --- Plot neural distance trajectories during initial rational fit --- %

select_rational = (Data.fit_label == "FitRational") | (Data.fit_label == "Priors");

% ~ Loop over model configs ~ %
for i_config = 1:10
    select_config = (Data.config_ID == i_config);

    % Identify individual networks
    config_seeds = unique(Data.seed(select_config));
    n_config_networks = length(config_seeds);

    % Initialize storage of neural distances interpolated on a fixed number of steps
    config_RDM_dist = NaN(n_config_networks, plot_options.n_steps);
    config_CCM_dist = NaN(n_config_networks, plot_options.n_steps);

    % ~ Loop over individual networks ~ %
    for i_network = 1:n_config_networks

        select_network_dist = select_rational & select_config & ...
            (Data.seed == config_seeds(i_network));
        n_fit_steps = sum(select_network_dist);

        % Linearly interpolate neural distance trajectories during fit with
        % a fixed 50-step scale
        config_RDM_dist(i_network, :) = interp1(1:n_fit_steps, ...
            Data.dist_RDM_avg_OFC(select_network_dist), ...
            linspace(1, n_fit_steps, plot_options.n_steps));
        config_CCM_dist(i_network, :) = interp1(1:n_fit_steps, ...
            Data.dist_CCM_avg_OFC(select_network_dist), ...
            linspace(1, n_fit_steps, plot_options.n_steps));

    end

    % Plot the trajectory
    plot(ax, mean(config_RDM_dist, 1), mean(config_CCM_dist, 1), ...
        Color = defineModelColor(i_config), ...
        LineStyle = defineModelLineStyle(i_config), ...
        LineWidth = plot_options.line_width, ...
        Marker = defineModelMarker(i_config), ...
        MarkerEdgeColor = defineModelColor(i_config), ...
        MarkerFaceColor = plot_options.marker_face_color, ...
        MarkerSize = plot_options.marker_size);

end

% --- Plot priors neural distances --- %

% ~ Loop over two cohorts with differing input encoding format; priors are
% shared across cohorts with similar formats ~ %
for i_config = [1, 7]

    select_config_priors = (Data.config_ID == i_config) & (Data.fit_label == "Priors");

    config_RDM_dist = mean(Data.dist_RDM_avg_OFC(select_config_priors));
    config_CCM_dist = mean(Data.dist_CCM_avg_OFC(select_config_priors));

    % Plot the prior
    plot(ax, config_RDM_dist, config_CCM_dist, ...
        LineWidth=plot_options.marker_priors_line_width, ...
        Marker = plot_options.marker_priors, ...
        MarkerEdgeColor = plot_options.marker_priors_edge_color, ...
        MarkerSize = plot_options.marker_priors_size);
end

% --- Plot final neural distances --- %

is_last_step = [Data.fit_step(2:end) <= Data.fit_step(1:(end - 1)), true];

% ~ Loop over model configs ~ %
for i_config = 1:10

    select_config = (Data.config_ID == i_config);

    % Store final neural distances
    config_RDM_dist = Data.dist_RDM_avg_OFC(select_config & is_last_step & select_rational);
    config_CCM_dist = Data.dist_CCM_avg_OFC(select_config & is_last_step & select_rational);
    mean_RDM = mean(config_RDM_dist);
    mean_CCM = mean(config_CCM_dist);

    % Plot the final state
    plot(ax, mean_RDM, mean_CCM, ...
        LineStyle="none", ...
        Marker=defineModelMarker(i_config), ...
        LineWidth=plot_options.marker_end_line_width, ...
        MarkerEdgeColor=plot_options.marker_end_edge_color, ...
        MarkerFaceColor=defineModelColor(i_config), ...
        MarkerSize=plot_options.marker_end_size);
end

% --- Legend --- %


if ~ inlay_plot

    % Custom legend handles
    ghost_plots = gobjects(1, 15);
    ghost_plots(1) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="\bfnetwork value");
    ghost_plots(2) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="\bfcomputation");
    ghost_plots(3) = plot(ax, NaN, NaN, Marker="s", MarkerFaceColor=defineModelColor(1), MarkerEdgeColor="none", LineStyle="none", ...
        DisplayName="comparison");
    ghost_plots(4) = plot(ax, NaN, NaN, Marker="s", MarkerFaceColor=defineModelColor(2), MarkerEdgeColor="none", LineStyle="none", ...
        DisplayName="synthesis");
    ghost_plots(5) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="");
    ghost_plots(6) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="\bfattended option");
    ghost_plots(7) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="\bfidentity format");
    ghost_plots(8) = plot(ax, NaN, NaN, Color="k", LineStyle=defineModelLineStyle(1), LineWidth=plot_options.line_width, ...
        DisplayName=" spatial");
    ghost_plots(9) = plot(ax, NaN, NaN, Color="k", LineStyle=defineModelLineStyle(7), LineWidth=plot_options.line_width, ...
        DisplayName=" temporal");
    ghost_plots(10) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="");
    ghost_plots(11) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="\bfvalue readout");
    ghost_plots(12) = plot(ax, NaN, NaN, LineStyle="none", ...
        DisplayName="\bfformat");
    ghost_plots(13) = plot(ax, NaN, NaN, Marker=defineModelMarker(5), MarkerFaceColor="none", MarkerEdgeColor="k", LineStyle="none", LineWidth=plot_options.line_width, ...
        DisplayName="spatial");
    ghost_plots(14) = plot(ax, NaN, NaN, Marker=defineModelMarker(3), MarkerFaceColor="none", MarkerEdgeColor="k", LineStyle="none", LineWidth=plot_options.line_width, ...
        DisplayName="temporal");
    ghost_plots(15) = plot(ax, NaN, NaN, Marker=defineModelMarker(1), MarkerFaceColor="none", MarkerEdgeColor="k", LineStyle="none", LineWidth=plot_options.line_width, ...
        DisplayName="attentional");
    
    % Create legend
    legend(ax, ghost_plots, ...
        NumColumns=3, ...
        Box="off", ...
        Location="southoutside", ...
        IconColumnWidth=20);

end

% --- Aesthetics --- %

if inlay_plot
    xlim(ax, [0.25, 0.3]);
    ylim([2.7, 3.25]);
    box(ax, "on");
else
    xlim(ax, [0.2, 1]);
    ylim([2.5, 7]);
    xscale(ax, "log");
    yscale(ax, "log");
    xlabel(ax, "Neural RDM distance (a.u.)");
    ylabel(ax, "Neural CCM distance (a.u.)");
end
setAxFontSize(ax);

hold(ax, "off");
