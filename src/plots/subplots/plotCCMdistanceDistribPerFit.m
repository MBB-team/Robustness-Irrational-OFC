function [] = plotCCMdistanceDistribPerFit(ax, Data, plot_options)
% Code for figure 3f.
%
% This function plots the distributions of CCM neural distances between
% RNNs and monkey neural recordings in the OFC at three stages: prior to
% initial training, after the rational initial training, and after the
% irrational re-training. After re-training, distributions are separated
% depending on whether the neural distance was computed with regard to the
% same monkey used as a reference for re-training ("same") or the other one
% ("other").
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
    plot_options.priors_color (1, 3) double = [0, 0, 0]
    plot_options.priors_face_alpha (1, 1) double = 0
    plot_options.star_size (1, 1) double = 18
    plot_options.line_y_coord_top (1, 1) = 5.3
    plot_options.line_y_coord_bottom (1, 1) = 1.1
    plot_options.line_x_shift (1, 1) double = - 0.2
    plot_options.line_y_shift (1, 1) double = 0.2
    plot_options.star_top_shift (1, 1) double = 0
    plot_options.star_bottom_shift (1, 1) double = - 0.1
end

hold(ax, "on");

% Initialize distance matrix
all_distance_matrix = cell(1, 7);
i_matrix = 1;

% Plot prior distance distribution
dist_priors = Data.dist_CCM_avg_OFC(ismember(Data.config_ID, [7, 8]) & Data.fit_label == "Priors");
all_distance_matrix{i_matrix} = dist_priors;
i_matrix = i_matrix + 1;
customViolinplot(ax, 0, dist_priors', ...
    Color=plot_options.priors_color, ...
    FaceAlpha=plot_options.priors_face_alpha, ...
    LineStyle=defineModelLineStyle(7), ...
    LineWidth=plot_options.line_width);

% ~ Loop over candidate RNN configurations only ~ %
for i_config = 9:10

    % Select data
    select_config = Data.config_ID == i_config;

    dist_rational = Data.dist_CCM_avg_OFC(select_config & Data.is_rational);
    dist_rational = [dist_rational, NaN(size(dist_rational))];

    dist_irrational_same = Data.dist_CCM_same_OFC(select_config & Data.is_irrational);
    dist_irrational_other = Data.dist_CCM_other_OFC(select_config & Data.is_irrational);

    dist_matrix = [dist_rational', dist_irrational_same', dist_irrational_other'];

    % Store in the distance matrix
    all_distance_matrix{i_matrix} = dist_rational;
    all_distance_matrix{i_matrix + 1} = dist_irrational_same;
    all_distance_matrix{i_matrix + 2} = dist_irrational_other;
    i_matrix = i_matrix + 3;
    
    % Plot
    customViolinplot(ax, (1:3) + (i_config - 9) * 3, dist_matrix, ...
        Color=defineModelColor(i_config), ...
        FaceAlpha=[0.2, 0.6, 0.6], ...
        LineStyle=defineModelLineStyle(i_config), ...
        LineWidth=plot_options.line_width);

end

% --- Plot stats --- %

% Comparison between priors and rational distance distributions
for i_matrix = [5, 2]
    [~, p] = ttest(all_distance_matrix{1}, all_distance_matrix{i_matrix});
    if p < plot_options.p_threshold
        % Plot the horizontal line
        if i_matrix == 5
            line_y_coord = plot_options.line_y_coord_top;
        else
            line_y_coord = plot_options.line_y_coord_top - plot_options.line_y_shift;
        end
        x_coord = plot_options.line_x_shift - 1 + [1, i_matrix];
        plot(ax, x_coord, line_y_coord * ones(1, 2), ...
            Color=plot_options.priors_color, ...
            LineWidth=plot_options.line_width);
        % Display the star
        text(ax, mean(x_coord), line_y_coord + plot_options.star_bottom_shift, ...
            "*", FontSize=plot_options.star_size);
    end
end

% Comparison between rational and irrational distance distributions
for i_matrix_rational = [2, 5]
    for i_matrix_shift = [2, 1]
        [~, p] = ttest(all_distance_matrix{i_matrix_rational}, ...
            all_distance_matrix{i_matrix_rational + i_matrix_shift});
        if p < plot_options.p_threshold
            % Plot the horizontal line
            if i_matrix_shift == 2
                line_y_coord = plot_options.line_y_coord_bottom;
            else
                line_y_coord = plot_options.line_y_coord_bottom + plot_options.line_y_shift;
            end
            x_coord = plot_options.line_x_shift - 1 + i_matrix_rational + [0, i_matrix_shift];
            if i_matrix_rational == 2
                i_config = 9;
            else
                i_config = 10;
            end
            plot(ax, x_coord, line_y_coord * ones(1, 2), ...
                Color=defineModelColor(i_config), ...
                LineWidth=plot_options.line_width);
            % Display the star
            text(ax, mean(x_coord), line_y_coord + plot_options.star_top_shift, ...
                "*", FontSize=plot_options.star_size, Color=defineModelColor(i_config));
        end
    end
end

% Aesthetics
xlim(ax, [-0.9, 6.4]);
ylim(ax, [1, 5.4]);
xticks(ax, 0:6);
xticklabels(ax, ["Initial\newlinestate", ...
    repmat(["Rational", "Irrational\newline(same)", "Irrational\newline(other)"], 1, 2)]);
ylabel(ax, "Neural CCM distance (a.u.)");