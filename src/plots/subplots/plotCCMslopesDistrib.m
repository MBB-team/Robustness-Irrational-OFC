function [] = plotCCMslopesDistrib(ax, Data, MonkeyNeuralGeometry, plot_options)
% Code for figure S5c.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID, is_irrational, fit_label: see
%       gatherAllModels
%       - CCM_option, CCM_attribute: see generateNeuralGeometryMatrices
%
% MonkeyNeuralGeometry : <struct 1x1>
%       Structure containing CCMs computed on each monkey. The expected
%       hierarchy is:
%       - MonkeyNeuralGeometry.OFC.(monkey).CCM_option
%       - MonkeyNeuralGeometry.OFC.(monkey).CCM_attribute
%
% line_width, marker_size:
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    MonkeyNeuralGeometry (1, 1) struct
    plot_options.rng (1, 1) double = 1
    plot_options.n_MonteCarlo_simu (1, 1) double = 1e4
    plot_options.line_width (1, 1) double = 0.7
    plot_options.x_shift (1, 1) double = 0.1
    plot_options.marker_size (1, 1) double = 7
end

hold(ax, "on");

% Fix RNG seed for reproducibility
rng(plot_options.rng);

% CCM cells to select
select_CCM_cell = true(9);
select_CCM_cell(4, :) = false;
select_CCM_cell(7, :) = false;
select_CCM_cell(8, :) = false;
select_CCM_cell(:, 4) = false;
select_CCM_cell(:, 7) = false;
select_CCM_cell(:, 8) = false;
select_CCM_cell = triu(select_CCM_cell, 1);
select_CCM_cell = select_CCM_cell(:);
n_cells = sum(select_CCM_cell);

% Select cells in monkeys' CCMs
CCM_option_Franck = MonkeyNeuralGeometry.OFC.Franck.CCM_option(:);
CCM_option_Franck = CCM_option_Franck(select_CCM_cell);
CCM_attribute_Franck = MonkeyNeuralGeometry.OFC.Franck.CCM_attribute(:);
CCM_attribute_Franck = CCM_attribute_Franck(select_CCM_cell);
CCM_Franck = [CCM_option_Franck ; CCM_attribute_Franck];
CCM_option_Miles = MonkeyNeuralGeometry.OFC.Miles.CCM_option(:);
CCM_option_Miles = CCM_option_Miles(select_CCM_cell);
CCM_attribute_Miles = MonkeyNeuralGeometry.OFC.Miles.CCM_attribute(:);
CCM_attribute_Miles = CCM_attribute_Miles(select_CCM_cell);
CCM_Miles = [CCM_option_Miles ; CCM_attribute_Miles];

% Select cells in models' CCMs
select_fit = Data.is_irrational;
select_comparison_Franck = contains(Data.fit_label, "Franck");
select_comparison_Miles = contains(Data.fit_label, "Miles");

for i_config = 9:10

    % Select CCM data for the comparison with both monkeys
    select_data_Franck = select_fit & select_comparison_Franck & Data.config_ID == i_config;
    select_data_Miles = select_fit & select_comparison_Miles & Data.config_ID == i_config;
    CCM_comp_Franck = [mean(Data.CCM_option(select_CCM_cell, select_data_Franck), 2) ; ...
        mean(Data.CCM_attribute(select_CCM_cell, select_data_Franck), 2)];
    CCM_comp_Miles = [mean(Data.CCM_option(select_CCM_cell, select_data_Miles), 2) ; ...
        mean(Data.CCM_attribute(select_CCM_cell, select_data_Miles), 2)];

    % Compute slopes in the actual data
    slopes = (CCM_comp_Franck - CCM_comp_Miles) ./ (CCM_Franck - CCM_Miles);
    mean_slope = mean(slopes);

    % Simulate the null hypothesis
    slopes_H0 = NaN(2 * n_cells, plot_options.n_MonteCarlo_simu);
    for i_simu = 1:plot_options.n_MonteCarlo_simu
        % Shuffle the model CCM cells
        CCM_comp_Franck_shuffled = CCM_comp_Franck(randperm(2 * n_cells));
        CCM_comp_Miles_shuffled = CCM_comp_Miles(randperm(2 * n_cells));
        slopes_H0(:, i_simu) = (CCM_comp_Franck_shuffled - CCM_comp_Miles_shuffled) ./ (CCM_Franck - CCM_Miles);
    end
    distrib_slopes_H0 = mean(slopes_H0, 1)';

    % --- Violin plot --- %

    if i_config == 9
        density_direction = "negative";
        x = - plot_options.x_shift;
    else
        density_direction = "positive";
        x = plot_options.x_shift;
    end
    customViolinplot(ax, x, distrib_slopes_H0, ...
        DensityDirection=density_direction, ...
        Color=defineModelColor(i_config), ...
        DensityInterval=[0, 100], ...
        FaceAlpha=0.5, ...
        LineWidth=plot_options.line_width);

    % --- Actual data line --- %

    if i_config == 9
        x = - plot_options.x_shift + [- 0.55, 0.05];
    else
        x = plot_options.x_shift + [- 0.05, 0.55];
    end
    plot(ax, x, mean_slope * [1, 1], ...
        LineWidth=plot_options.line_width, ...
        Color=defineModelColor(i_config));
    plot(ax, mean(x), mean_slope, ...
        LineStyle="none", ...
        Marker=defineModelMarker(i_config), ...
        MarkerSize=plot_options.marker_size, ...
        LineWidth=plot_options.line_width, ...
        MarkerFaceColor="w", ...
        MarkerEdgeColor=defineModelColor(i_config));

    % --- Stats --- %

    fprintf("Config %d: p(H0 >= actual data) = %0.1e\n", ...
        i_config, ...
        mean(distrib_slopes_H0 >= mean_slope));

end

% Aesthetics
xlim(ax, [-0.8, 0.8]);
xticks(ax, plot_options.x_shift * 4 * [-1, 1]);
xticklabels(ax, ["Synthesis", "Comparison"]);
ylabel(ax, "Mean slope");
yline(ax, 0, "k:", LineWidth=plot_options.line_width);
setAxFontSize(ax);

hold(ax, "off");
