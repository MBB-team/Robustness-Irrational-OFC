function [] = plotCCMcellsComparison(ax, Data, MonkeyNeuralGeometry, fit_label, plot_options)
% Code for figure S5a and S5b.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID, is_rational, is_irrational, fit_label: see
%       gatherAllModels
%       - CCM_option, CCM_attribute: see generateNeuralGeometryMatrices
%
% MonkeyNeuralGeometry : <struct 1x1>
%       Structure containing CCMs computed on each monkey. The expected
%       hierarchy is:
%       - MonkeyNeuralGeometry.OFC.(monkey).CCM_option
%       - MonkeyNeuralGeometry.OFC.(monkey).CCM_attribute
%
% fit_label : <string 1x1>
%       Whether to plot the data for rational or irrational models.
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
    fit_label (1, 1) string {mustBeMember(fit_label, ["rational", "irrational"])}
    plot_options.line_width (1, 1) double = 0.7
    plot_options.marker_size (1, 1) double = 10
    plot_options.alpha (1, 1) double = 0.8
end

hold(ax, "on");


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
if fit_label == "rational"
    select_fit = Data.is_rational;
    select_comparison_Franck = true(size(select_fit));
    select_comparison_Miles = true(size(select_fit));
else
    select_fit = Data.is_irrational;
    select_comparison_Franck = contains(Data.fit_label, "Franck");
    select_comparison_Miles = contains(Data.fit_label, "Miles");
end
for i_config = 9:10

    % Select CCM data for the comparison with both monkeys
    select_data_Franck = select_fit & select_comparison_Franck & Data.config_ID == i_config;
    select_data_Miles = select_fit & select_comparison_Miles & Data.config_ID == i_config;
    CCM_comp_Franck = [mean(Data.CCM_option(select_CCM_cell, select_data_Franck), 2) ; ...
        mean(Data.CCM_attribute(select_CCM_cell, select_data_Franck), 2)];
    CCM_comp_Miles = [mean(Data.CCM_option(select_CCM_cell, select_data_Miles), 2) ; ...
        mean(Data.CCM_attribute(select_CCM_cell, select_data_Miles), 2)];

    % --- Plot --- %

    plot(ax, ...
        [CCM_Franck, CCM_Miles]', ...
        [CCM_comp_Franck, CCM_comp_Miles]', ...
        Color=[defineModelColor(i_config), plot_options.alpha], ...
        LineWidth=plot_options.line_width);
    scatter(ax, ...
        [CCM_Franck ; CCM_Miles], ...
        [CCM_comp_Franck ; CCM_comp_Miles], ...
        plot_options.marker_size, ...
        Marker=defineModelMarker(i_config), ...
        MarkerEdgeColor=defineModelColor(i_config), ...
        MarkerFaceColor="w", ...
        MarkerFaceAlpha=plot_options.alpha, ...
        MarkerEdgeAlpha=plot_options.alpha, ...
        LineWidth=plot_options.line_width);
end

% Title
if fit_label == "rational"
    title_label = "Rational neural nets";
else
    title_label = "Irrational neural nets";
end
title(ax, title_label);

% Grid
for i_panel = 1:2
    xline(ax, 0, "k:", LineWidth=plot_options.line_width);
    yline(ax, 0, "k:", LineWidth=plot_options.line_width);
end

% Aesthetics
xlim(ax, [-0.5, 1]);
ylim(ax, [-0.5, 1]);
xticks(ax, []);
yticks(ax, []);
xlabel(ax, "Monkey CCM cell");
ylabel(ax, "Mean neural net CCM cell");
setAxFontSize(ax);
ax.XAxis.Visible = "off";
ax.XAxis.Label.Visible = "on";
ax.YAxis.Visible = "off";
ax.YAxis.Label.Visible = "on";

hold(ax, "off");
