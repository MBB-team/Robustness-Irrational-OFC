function [] = plotSimpleNeuralDistanceTrajectory(ax, Data, plot_options)
% Code for figure S1b.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID, is_rational, fit_step: see gatherAllModels
%       - dist_RDM_avg_OFC, dist_CCM_avg_OFC: see computeNeuralDistance
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
    plot_options.n_steps (1, 1) double = 50
    plot_options.area_face_alpha (1, 1) double = 0.1
    plot_options.line_width (1, 1) double = 0.7
    plot_options.marker_size (1, 1) double = 4
    plot_options.marker_face_color (1, 3) double = [1, 1, 1]
    plot_options.marker_end_face_color (1, 3) double = [1, 1, 1]
    plot_options.marker_end_size (1, 1) double = 5
    plot_options.marker_end_line_width (1, 1) double = 1
    plot_options.marker_priors (1, 1) string = "x"
    plot_options.marker_priors_edge_color (1, 3) double = [0, 0, 0]
    plot_options.marker_priors_size (1, 1) double = 10
    plot_options.marker_priors_line_width (1, 1) double = 1
end

hold(ax, "on");

% --- Plot neural distance before and after initial rational fit --- %

% ~ Loop over model configs ~ %
for i_config = 1:10

    select_config = (Data.config_ID == i_config);

    % Average distances before and after training
    RDM_dist_prior = mean(Data.dist_RDM_avg_OFC(select_config & Data.fit_step == 1));
    CCM_dist_prior = mean(Data.dist_CCM_avg_OFC(select_config & Data.fit_step == 1));
    RDM_dist_rational = mean(Data.dist_RDM_avg_OFC(select_config & Data.is_rational));
    CCM_dist_rational = mean(Data.dist_CCM_avg_OFC(select_config & Data.is_rational));

    % Plot the trajectory
    plot(ax, [RDM_dist_prior, RDM_dist_rational], [CCM_dist_prior, CCM_dist_rational], ...
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

    config_RDM_dist = mean(Data.dist_RDM_avg_OFC((Data.config_ID == i_config) & (Data.fit_step == 1)));
    config_CCM_dist = mean(Data.dist_CCM_avg_OFC((Data.config_ID == i_config) & (Data.fit_step == 1)));

    % Plot the prior
    plot(ax, config_RDM_dist, config_CCM_dist, ...
        LineWidth=plot_options.marker_priors_line_width, ...
        Marker = plot_options.marker_priors, ...
        MarkerEdgeColor = plot_options.marker_priors_edge_color, ...
        MarkerSize = plot_options.marker_priors_size);
end

% --- Plot final neural distances --- %

% ~ Loop over model configs ~ %
for i_config = 1:10

    select_config = (Data.config_ID == i_config);

    % Store final neural distances
    mean_RDM = mean(Data.dist_RDM_avg_OFC(select_config & Data.is_rational));
    mean_CCM = mean(Data.dist_CCM_avg_OFC(select_config & Data.is_rational));

    % Plot the final state
    plot(ax, mean_RDM, mean_CCM, ...
        LineStyle="none", ...
        Marker=defineModelMarker(i_config), ...
        LineWidth=plot_options.marker_end_line_width, ...
        MarkerFaceColor=plot_options.marker_end_face_color, ...
        MarkerEdgeColor=defineModelColor(i_config), ...
        MarkerSize=plot_options.marker_end_size);
end

% --- Aesthetics --- %

xlim(ax, [0.2, 0.8]);
ylim([2.5, 4.5]);
xscale(ax, "log");
yscale(ax, "log");
xlabel(ax, "Neural RDM distance (a.u.)");
ylabel(ax, "Neural CCM distance (a.u.)");
setAxFontSize(ax);

hold(ax, "off");
