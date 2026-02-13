function [] = plotCCMdistanceDistribPerArea(ax, Data, plot_options)
% Code for figure 3g.
%
% Longer description
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
    plot_options.line_y_coord_top (1, 1) = 5.3
    plot_options.line_x_shift (1, 1) double = - 0.2
    plot_options.line_y_shift (1, 1) double = 0.2
    plot_options.star_bottom_shift (1, 1) double = - 0.1
end

hold(ax, "on");

% Initialize distance matrix
all_distance_matrix = cell(1, 6);
i_matrix = 1;

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    select_config = Data.config_ID == i_config;

    % ~ Loop over brain area of reference ~ %
    for area = ["OFC", "dlPFC", "ACC"]
        
        % Select data
        dist = Data.("dist_CCM_avg_" + area)(select_config & Data.is_irrational);

        % Store in the distance matrix
        all_distance_matrix{i_matrix} = dist;
        i_matrix = i_matrix + 1;
    
        % Plot
        customViolinplot(ax, i_matrix - 1, dist', ...
            Color=defineModelColor(i_config), ...
            FaceAlpha=0.6, ...
            LineStyle=defineModelLineStyle(i_config), ...
            LineWidth=plot_options.line_width);

    end

end

% --- Plot stats --- %

% Comparison between OFC and dlPFC/ACC distances
for i_matrix_OFC = [1, 4]
    for i_matrix_shift = [2, 1]
        [~, p] = ttest(all_distance_matrix{i_matrix_OFC}, ...
            all_distance_matrix{i_matrix_OFC + i_matrix_shift});

        if p < plot_options.p_threshold

            % Plot the horizontal line
            if i_matrix_shift == 2
                line_y_coord = plot_options.line_y_coord_top;
            else
                line_y_coord = plot_options.line_y_coord_top - plot_options.line_y_shift;
            end
            x_coord = plot_options.line_x_shift + i_matrix_OFC + [0, i_matrix_shift];
            if i_matrix_OFC == 1
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
ylim(ax, [1, 5.4]);
xticks(ax, 1:6);
xticklabels(ax, repmat(["OFC", "dlPFC", "ACC"], 1, 2));
ylabel(ax, "Neural CCM distance (a.u.)");