function [] = plotMonkeyBaccDistribPerFit(ax, Data, plot_options)
% Code for figure 3e.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - fit_label
%       - config_ID: see gatherAllModels
%       - is_rational, is_irrational: see gatherAllModels
%       - bacc_Franck, bacc_Miles, bacc_same_monkey, bacc_other_monkey: see
%       predictMonkeyChoices
%
% p_threshold, marker_size, line_width, line_y_coord_top, line_x_shift,
% line_y_shift, star_size, star_bottom_shift, star_x_shift :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS --------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    plot_options.p_threshold (1, 1) double = 0.05 / 3
    plot_options.marker_size (1, 1) double = 15
    plot_options.line_width (1, 1) double = 0.5
    plot_options.line_y_coord_top (1, 1) = 0.889
    plot_options.line_x_shift (1, 1) double = - 0.15
    plot_options.line_y_shift (1, 1) double = 0.005
    plot_options.star_size (1, 1) double = 14
    plot_options.star_bottom_shift (1, 1) double = - 0.0125
    plot_options.star_x_shift (1, 1) double = 0.1
end

hold(ax, "on");

% Aesthetics
xlim(ax, [0.1, 6.4]);
ylim(ax, [0.735, 0.89]);
xticks(ax, 1:6);
xticklabels(ax, repmat(["Rational", "Irration.\newline(same)", "Irration.\newline(other)"], 1, 2));
ylabel(ax, "Balanced accuracy");
setAxFontSize(ax);

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    % ~ Loop over monkey whose choices are predicted ~ %
    for monkey = ["Franck", "Miles"]

        if monkey == "Franck"
            other_monkey = "Miles";
            star_x_shift = plot_options.star_x_shift;
        else
            other_monkey = "Franck";
            star_x_shift = - plot_options.star_x_shift;
        end

        % Select data
        select_config = Data.config_ID == i_config;
        dist_rational = Data.("bacc_" + monkey)(select_config & Data.is_rational)';
        dist_irrational_same = Data.bacc_same_monkey(select_config & ...
            Data.is_irrational & contains(Data.fit_label, monkey))';
        dist_irrational_other = Data.bacc_other_monkey(select_config & ...
            Data.is_irrational & contains(Data.fit_label, other_monkey))';
        distance_matrix = [dist_rational, dist_irrational_same, dist_irrational_other];
        
        % Plot bacc distribution
        customViolinplot(ax, (1:3) + (i_config - 9) * 3, ...
            distance_matrix, ...
            Color=defineModelColor(i_config), ...
            FaceAlpha=[0.1, 0.5, 0.5], ...
            LineStyle=defineModelLineStyle(i_config), ...
            LineWidth=plot_options.line_width);

        % Indicate monkey ID
        for i_distrib = 1:3
            scatter(ax, ...
                0.2 + i_distrib + (i_config - 9) * 3, ...
                mean(distance_matrix(:, i_distrib)), ...
                plot_options.marker_size, ...
                Marker=defineMonkeyMarker(monkey), ...
                MarkerFaceColor=defineMonkeyColor(monkey), ...
                MarkerEdgeColor=defineMonkeyColor(monkey));
        end

        % --- Plot stats --- %

        % Rational vs. irrational other
        [~, p] = ttest(dist_rational, dist_irrational_other);
        % Horizontal line
        line_y_coord = plot_options.line_y_coord_top;
        if monkey == "Franck"
            x_coord = plot_options.line_x_shift + [1, 3] + (i_config - 9) * 3;
            plot(ax, x_coord, line_y_coord * ones(1, 2), ...
                Color=defineModelColor(i_config), ...
                LineWidth=plot_options.line_width);
        end
        % Star
        x_star = plot_options.line_x_shift + star_x_shift + 2.5 + (i_config - 9) * 3;
        y_star = line_y_coord + plot_options.star_bottom_shift;
        if p < plot_options.p_threshold
            text(ax, x_star, y_star, "*", ...
                HorizontalAlignment="center", ...
                FontSize=plot_options.star_size, ...
                Color=defineMonkeyColor(monkey));
        end

        % Rational vs. irrational same
        [~, p] = ttest(dist_rational, dist_irrational_same);
        line_y_coord = plot_options.line_y_coord_top - plot_options.line_y_shift;
        % Horizontal line
        if monkey == "Franck"
            x_coord = plot_options.line_x_shift + [1, 2] + (i_config - 9) * 3;
            plot(ax, x_coord, line_y_coord * ones(1, 2), ...
                Color=defineModelColor(i_config), ...
                LineWidth=plot_options.line_width);
        end
        % Star
        x_star = plot_options.line_x_shift + star_x_shift + 1.5 + (i_config - 9) * 3;
        y_star = line_y_coord + plot_options.star_bottom_shift;
        if p < plot_options.p_threshold
            text(ax, x_star, y_star, "*", ...
                HorizontalAlignment="center", ...
                FontSize=plot_options.star_size, ...
                Color=defineMonkeyColor(monkey));
        end

    end

end

hold(ax, "off");
