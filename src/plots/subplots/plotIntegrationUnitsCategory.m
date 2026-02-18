function [] = plotIntegrationUnitsCategory(ax, Data, plot_options)
% Code for figure 3f.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - is_rational, is_irrational: see gatherAllModels
%       - prop_offer1_Franck, prop_offer1_Miles,
%       prop_offer2_Franck, prop_offer2_Miles,
%       prop_chosen_value_Franck, prop_chosen_value_Miles,
%       prop_chosen_offer_Franck, prop_chosen_offer_Miles, ...
%       prop_none_Franck, prop_none_Miles
%
% line_width, distrib_x_shift, distrib_config_x_shift,
% distrib_density_width, monkey_line_style, marker_size :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    plot_options.line_width (1, 1) double = 0.5
    plot_options.distrib_x_shift (1, 1) double = 0.05
    plot_options.distrib_config_x_shift (1, 1) double = 0.22
    plot_options.distrib_density_width (1, 1) double = 0.15
    plot_options.monkey_line_style (1, 1) string = ":"
    plot_options.marker_size (1, 1) double = 3
end

% Load monkey data
MonkeyData = load(fullfile(getPath("MonkeyData"), "PadoaSchioppaCells.mat")).OFC;

all_cell_type = ["offer", "chosen_value", "chosen_offer", "none"];

% Gather offer cell proportions
for monkey = ["Franck", "Miles"]
    Data.("prop_offer_" + monkey) = Data.("prop_offer1_" + monkey) + Data.("prop_offer2_" + monkey);
    MonkeyData.(monkey).prop_offer = MonkeyData.(monkey).prop_offer1 + MonkeyData.(monkey).prop_offer2;
end

for cell_type = all_cell_type
    Data.("prop_" + cell_type) = (Data.("prop_" + cell_type + "_Franck") + ...
        Data.("prop_" + cell_type + "_Miles")) / 2;
end

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    select_config = Data.config_ID == i_config;

    for i_cell = 1:length(all_cell_type)

        % Select data
        prop_rational = Data.("prop_" + all_cell_type(i_cell))(select_config & Data.is_rational);
        prop_irrational = Data.("prop_" + all_cell_type(i_cell))(select_config & Data.is_irrational);

        x_mean = i_cell + 2 * (i_config - 9.5) * plot_options.distrib_config_x_shift;

        % Plot distribution for rational models
        customViolinplot(ax, ...
            x_mean - plot_options.distrib_x_shift, ...
            prop_rational', ...
            Discrete=true, ...
            DensityDirection="negative", ...
            Color=defineModelColor(i_config), ...
            DensityWidth=plot_options.distrib_density_width, ...
            LineWidth=plot_options.line_width, ...
            FaceAlpha=0.1);

        % Plot distribution for irrational models
        customViolinplot(ax, ...
            x_mean + plot_options.distrib_x_shift, ...
            prop_irrational', ...
            Discrete=true, ...
            DensityDirection="positive", ...
            Color=defineModelColor(i_config), ...
            DensityWidth=plot_options.distrib_density_width, ...
            LineWidth=plot_options.line_width, ...
            FaceAlpha=0.5);

        % Plot monkey data
        x_monkey = i_cell + linspace(-0.4, 0.4, 8);
        for monkey = ["Franck", "Miles"]
            plot(ax, x_monkey, ...
                MonkeyData.(monkey).("prop_" + all_cell_type(i_cell)) * ones(1, length(x_monkey)), ...
                Color=defineMonkeyColor(monkey), ...
                Marker=defineMonkeyMarker(monkey), ...
                MarkerSize=plot_options.marker_size, ...
                MarkerFaceColor=defineMonkeyColor(monkey), ...
                MarkerEdgeColor="none", ...
                LineWidth=plot_options.line_width, ...
                LineStyle=plot_options.monkey_line_style);
        end
    end

end

% Aesthetics
xlim(ax, [0.3, 4.7]);
ylim(ax, [0, 100]);
xticks(ax, 1:4);
yticks(ax, 0:10:100);
xticklabels(ax, ["Offer\newlinevalue", "Chosen\newlinevalue", "Chosen\newlineoffer", "None"]);
yticklabels(ax, ["0", "", "", "", "", "50", "", "", "", "", "100"]);
ylabel(ax, "% cell detection");
setAxFontSize(ax);

hold(ax, "off");
