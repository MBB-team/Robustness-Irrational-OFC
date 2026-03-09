function [] = plotMonkeyIrrationalChoices(ax, MonkeyData, is_corrected, plot_options)
% Code for figure 4d and 4e.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% MonkeyData : <struct 1x1>
%     Structure containing monkey behavioural analysis results. Must
%     include two sub-structures Franck and Miles, with fields:
%       - option_mean: see computeMonkeyDecisionResiduals or
%       computeMonkeyPropIrrationalChoices
%       - option_se: see computeMonkeyDecisionResiduals or
%       computeMonkeyPropIrrationalChoices
%       - attribute_mean: see computeMonkeyDecisionResiduals or
%       computeMonkeyPropIrrationalChoices
%       - attribute_se: see computeMonkeyDecisionResiduals or
%       computeMonkeyPropIrrationalChoices
%       - both: see computeMonkeyDecisionResiduals or
%       computeMonkeyPropIrrationalChoices
%
% is_corrected : <bool 1x1>
%     Whether to plot the residuals of irrational choice proportions
%     corrected by the choice difficulty (true), or the raw choice
%     proportions.
%
% line_width, monkey_line_style, marker_size :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    MonkeyData (1, 1) struct
    is_corrected (1, 1) logical
    plot_options.x_shift (1, 1) double = 0.05
    plot_options.cap_size (1, 1) double = 0
    plot_options.line_width (1, 1) double = 0.5
    plot_options.marker_size (1, 1) double = 3
    plot_options.marker_edge_color (1, 3) double = [1, 1, 1]
    plot_options.line_style_option (1, 1) string = "-"
    plot_options.line_style_attribute (1, 1) string = "--"
    plot_options.p_threshold (1, 1) double = 0.02
    plot_options.line_color (1, 3) double = [0, 0, 0]
    plot_options.line_y_coord_uncorrected (1, 1) double = 0.385
    plot_options.line_y_coord_corrected (1, 1) double = 0.045
    plot_options.line_top_y_coord_uncorrected (1, 1) double = 0.419
    plot_options.line_top_y_coord_corrected (1, 1) double = 0.0599
    plot_options.star_y_shift_uncorrected (1, 1) double = -0.028
    plot_options.star_y_shift_corrected (1, 1) double = -0.012
    plot_options.star_size (1, 1) double = 14
    plot_options.star_x_shift (1, 1) double = 0.1

end

hold(ax, "on");

% Aesthetics
xlim(ax, [1.5, 4.5]);
if is_corrected
    ylim(ax, [-0.12, 0.06]);
else
    ylim(ax, [0, 0.42]);
end
xticks(ax, 2:4);
xlabel(ax, "Within-trial time step");
if is_corrected
    ylabel(ax, "P(irrational) corrected");
else
    ylabel(ax, "P(irrational)");
end
setAxFontSize(ax);

% ~ Loop over monkey and trial type ~ %
for monkey = ["Franck", "Miles"]
    for trial_type = ["option", "attribute"]

        % Define x coordinates
        x_coord = 2:4;
        if monkey == "Franck"
            x_coord = x_coord - plot_options.x_shift;
        else
            x_coord = x_coord + plot_options.x_shift;
        end
        if trial_type == "option"
            x_coord = x_coord - (plot_options.x_shift / 2);
        else
            x_coord = x_coord + (plot_options.x_shift / 2);
        end

        % Plot with error bars
        errorbar(ax, ...
            x_coord, ...
            MonkeyData.(monkey).(trial_type + "_mean")(2:4), ...
            MonkeyData.(monkey).(trial_type + "_se")(2:4), ...
            CapSize=plot_options.cap_size, ...
            Marker=defineMonkeyMarker(monkey), ...
            MarkerFaceColor=defineMonkeyColor(monkey), ...
            Color=defineMonkeyColor(monkey), ...
            MarkerEdgeColor=plot_options.marker_edge_color, ...
            LineWidth=plot_options.line_width, ...
            LineStyle=plot_options.("line_style_" + trial_type));

    end

    % --- Plot statistics --- %

    for i_step = 2:3
        for j_step = (i_step + 1):4

            % Two-sample t-test
            [~, p] = ttest2(MonkeyData.(monkey).both{i_step}, MonkeyData.(monkey).both{j_step});

            if p < plot_options.p_threshold

                % Horizontal line
                if i_step == 2 && j_step == 4
                    if is_corrected
                        line_y_coord = plot_options.line_top_y_coord_corrected;
                    else
                        line_y_coord = plot_options.line_top_y_coord_uncorrected;
                    end
                else
                    if is_corrected
                        line_y_coord = plot_options.line_y_coord_corrected;
                    else
                        line_y_coord = plot_options.line_y_coord_uncorrected;
                    end
                end
                x_coord = [i_step, j_step];
                if i_step == 2 && j_step == 3
                    x_coord(2) = x_coord(2) - plot_options.x_shift;
                elseif i_step == 3 && j_step == 4
                    x_coord(1) = x_coord(1) + plot_options.x_shift;
                end
                plot(ax, x_coord, line_y_coord * ones(1, 2), ...
                    Color=plot_options.line_color, ...
                    LineWidth=plot_options.line_width);

                % Star
                if monkey == "Franck"
                    x_star = mean([i_step, j_step]) - plot_options.star_x_shift;
                else
                    x_star = mean([i_step, j_step]) + plot_options.star_x_shift;
                end
                if is_corrected
                    y_star = line_y_coord + plot_options.star_y_shift_corrected;
                else
                    y_star = line_y_coord + plot_options.star_y_shift_uncorrected;
                end
                text(ax, x_star, y_star, "*", ...
                    HorizontalAlignment="center", ...
                    FontSize=plot_options.star_size, ...
                    Color=defineMonkeyColor(monkey));
            end
        end
    end
end

hold(ax, "off");
