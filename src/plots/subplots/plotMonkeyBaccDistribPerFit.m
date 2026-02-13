function [] = plotMonkeyBaccDistribPerFit(ax, Data, plot_options)
% Code for figure 3e.
%
% Longer description.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% + named aesthetic options
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    plot_options.p_threshold (1, 1) double = 0.05 / 3
    plot_options.line_width (1, 1) double = 1
    plot_options.star_size (1, 1) double = 18
    plot_options.line_y_coord_top (1, 1) = 0.905
    plot_options.line_x_shift (1, 1) double = - 0.1
    plot_options.line_y_shift (1, 1) double = 0.01
    plot_options.star_bottom_shift (1, 1) double = - 0.01
end

hold(ax, "on");

% Initialize balanced accuracy matrix
all_bacc_matrix = cell(1, 7);
i_matrix = 1;

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    % Select data
    select_config = Data.config_ID == i_config;

    dist_rational = [Data.bacc_Franck(select_config & Data.is_rational), ...
        Data.bacc_Miles(select_config & Data.is_rational)];

    dist_irrational_same = Data.bacc_same_monkey(select_config & Data.is_irrational);
    dist_irrational_other = Data.bacc_other_monkey(select_config & Data.is_irrational);

    dist_matrix = [dist_rational', dist_irrational_same', dist_irrational_other'];

    % Store in the distance matrix
    all_bacc_matrix{i_matrix} = dist_rational;
    all_bacc_matrix{i_matrix + 1} = dist_irrational_same;
    all_bacc_matrix{i_matrix + 2} = dist_irrational_other;
    i_matrix = i_matrix + 3;
    
    % Plot
    customViolinplot(ax, (1:3) + (i_config - 9) * 3, dist_matrix, ...
        Color=defineModelColor(i_config), ...
        FaceAlpha=[0.2, 0.6, 0.6], ...
        LineStyle=defineModelLineStyle(i_config), ...
        LineWidth=plot_options.line_width);

end

% --- Plot stats --- %

% Comparison between rational and irrational distance distributions
for i_matrix_rational = [1, 4]
    for i_matrix_shift = [2, 1]
        [~, p] = ttest(all_bacc_matrix{i_matrix_rational}, ...
            all_bacc_matrix{i_matrix_rational + i_matrix_shift});

        if p < plot_options.p_threshold

            % Plot the horizontal line
            if i_matrix_shift == 2
                line_y_coord = plot_options.line_y_coord_top;
            else
                line_y_coord = plot_options.line_y_coord_top - plot_options.line_y_shift;
            end
            x_coord = plot_options.line_x_shift + i_matrix_rational + [0, i_matrix_shift];
            if i_matrix_rational == 1
                i_config = 9;
            else
                i_config = 10;
            end
            plot(ax, x_coord, line_y_coord * ones(1, 2), ...
                Color=defineModelColor(i_config), ...
                LineWidth=plot_options.line_width);

            % Display the star
            text(ax, mean(x_coord), line_y_coord + plot_options.star_bottom_shift, ...
                "*", FontSize=plot_options.star_size, Color=defineModelColor(i_config));

        end
    end
end

% Aesthetics
xlim(ax, [0.1, 6.4]);
ylim(ax, [0.7, 0.92]);
xticks(ax, 1:6);
xticklabels(ax, repmat(["Rational", "Irrational\newline(same)", "Irrational\newline(other)"], 1, 2));
ylabel(ax, "Balanced accuracy");