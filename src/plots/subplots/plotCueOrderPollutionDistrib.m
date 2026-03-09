function [] = plotCueOrderPollutionDistrib(ax, Data, i_config, plot_options)
% Code for figure 4b and 4c.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID: see gatherAllModels
%       - std_order_option_per_step: see computeCueOrderPollution
%       - std_order_attribute_per_step: see computeCueOrderPollution
%       - std_order_per_step: see computeCueOrderPollution
%
% i_config : <int 1x1>
%     Index of the network configuration whose data to display.     
%
% x_shift, line_width :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    i_config (1, 1) double
    plot_options.x_shift (1, 1) double = 0.08
    plot_options.line_width (1, 1) double = 0.5
    plot_options.density_width (1, 1) double = 0.35
    plot_options.option_line_style (1, 1) string = "-"
    plot_options.attribute_line_style (1, 1) string = "--"
    plot_options.line_step_y_coord (1, 3) double = [1.05, 1.05, 1.6]
    plot_options.line_top_y_coord (1, 1) double = 1.659
    plot_options.line_x_shift (1, 1) double = 0.27
    plot_options.star_y_shift (1, 1) double = -0.11
    plot_options.star_size (1, 1) double = 14
    plot_options.p_threshold (1, 1) double = 0.005
end

hold(ax, "on");

% Aesthetics
xlabel(ax, "Within-trial time step");
ylabel(ax, "Value readout std.");
xlim(ax, [1, 5]);
ylim(ax, [0, 1.66]);
xticks(ax, 2:4);
setAxFontSize(ax);

% Select data for this config only
Data = selectStructFieldColumns(Data, Data.config_ID == i_config);

% ~ Loop over trial step and type ~ %
for i_step = 2:4
    for trial_type = ["option", "attribute"]

        % Select data
        std_order = Data.("std_order_" + trial_type + "_per_step")(i_step - 1, Data.is_irrational)';

        % Define violinplot parameters
        if trial_type == "option"
            x_distrib = i_step - plot_options.x_shift;
            density_direction = "negative";
        else
            x_distrib = i_step + plot_options.x_shift;
            density_direction = "positive";
        end

        % Plot
        customViolinplot(ax, ...
            x_distrib, std_order, ...
            Color=defineModelColor(i_config), ...
            FaceAlpha=0.5, ...
            DensityWidth=plot_options.density_width, ...
            DensityDirection=density_direction, ...
            LineStyle=plot_options.(trial_type + "_line_style"), ...
            LineWidth=plot_options.line_width);

    end

    % --- Plot statistics: option vs. attribute trials --- %

    std_order_option = Data.std_order_option_per_step(i_step - 1, Data.is_irrational);
    std_order_attribute = Data.std_order_attribute_per_step(i_step - 1, Data.is_irrational);
    [~, p] = ttest(std_order_option, std_order_attribute);
    % Horizontal line
    line_y_coord = plot_options.line_step_y_coord(i_step - 1);
    x_coord = plot_options.line_x_shift * [-1, 1] + i_step;
    plot(ax, x_coord, line_y_coord * ones(1, 2), ...
        Color=defineModelColor(i_config), ...
        LineWidth=plot_options.line_width);
    % Star
    x_star = i_step;
    y_star = line_y_coord + plot_options.star_y_shift;
    if p < plot_options.p_threshold
        text(ax, x_star, y_star, "*", ...
            HorizontalAlignment="center", ...
            FontSize=plot_options.star_size, ...
            Color=defineModelColor(i_config));
    end

end

% --- Plot statistics: step 2 vs. step 4 --- %
    
std_order_step2 = Data.std_order_per_step(1, Data.is_irrational);
std_order_step4 = Data.std_order_per_step(3, Data.is_irrational);
[~, p] = ttest(std_order_step2, std_order_step4);
% Horizontal line
line_y_coord = plot_options.line_top_y_coord;
x_coord = [2, 4];
plot(ax, x_coord, line_y_coord * ones(1, 2), ...
    Color=defineModelColor(i_config), ...
    LineWidth=plot_options.line_width);
% Star
x_star = 3;
y_star = line_y_coord + plot_options.star_y_shift;
if p < plot_options.p_threshold
    text(ax, x_star, y_star, "*", ...
        HorizontalAlignment="center", ...
        FontSize=plot_options.star_size, ...
        Color=defineModelColor(i_config));
end

hold(ax, "off");
