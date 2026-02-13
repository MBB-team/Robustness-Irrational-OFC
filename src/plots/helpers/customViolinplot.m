function [] = customViolinplot(ax, x_vector, y_matrix, options)
% Plots compact, customizable violin plots into a given axes.
%
% The violin plot distribution is computed by first cropping the data to a
% specified percentile interval (default 5–95%) to reduce the influence of
% outliers. A kernel density estimate (KDE) is then computed on the cropped
% data, producing a smooth probability density function. This density is
% scaled to a fixed width and plotted in the specified direction around the
% corresponding x-position. Optional lines indicate the mean and
% interquartile interval of the distribution.
%
% Distribution for the discrete case
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the violin plots will be drawn.
%
% x_vector : <double 1xN>
%     Horizontal positions for each violin.
%
% y_matrix : <double MxN>
%     Data values for each violin (columns correspond to violins).
%
% options : <struct>
%     Name-value optional arguments:
%       - DensityDirection: 'negative' or 'positive'
%       - DensityWidth: scaling of violin width
%       - Color: fill color of violins
%       - LineColor: color of violin edges
%       - FaceAlpha: fill transparency
%       - LineWidth: edge line width
%       - LineStyle: edge line style
%       - DensityInterval: percentile interval for cropping extreme values
%       - BandWidth: KDE bandwidth
%       - ShowMean: show horizontal line at mean
%       - ShowInterval: show interquartile interval
%       - MeanLineWidth: width of mean line
%       - IntervalLineWidth: width of interval line
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws directly into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    x_vector (1, :) double
    y_matrix (:, :) double
    options.Discrete (1, 1) logical = false
    options.DensityDirection (1, 1) string = "negative"
    options.DensityWidth (1, 1) double = 0.5
    options.Color = "k"
    options.LineColor = []
    options.FaceAlpha = 0.5
    options.LineWidth = 1
    options.LineStyle = "-"
    options.DensityInterval (1, 2) double = [5, 95]
    options.BandWidth (1, 1) double = NaN
    options.ShowMean (1, 1) logical = true
    options.ShowInterval (1, 1) logical = true
    options.MeanLineWidth (1, 1) double = 1
    options.IntervalLineWidth (1, 1) double = 2.5
end

% Format inputs
if isempty(options.LineColor)
    options.LineColor = options.Color;
end
n_violin = length(x_vector);
if n_violin > 1
    if all(isstring(options.Color) | ischar(options.Color))
        if isscalar(options.Color)
            options.Color = repmat(options.Color, n_violin, 1);
        end
    else
        if size(options.Color, 1) == 1
            options.Color = repmat(options.Color, n_violin, 1);
        end
    end
    if all(isstring(options.LineColor) | ischar(options.LineColor))
        if isscalar(options.LineColor)
            options.LineColor = repmat(options.LineColor, n_violin, 1);
        end
    else
        if size(options.LineColor, 1) == 1
            options.LineColor = repmat(options.LineColor, n_violin, 1);
        end
    end
    if isscalar(options.FaceAlpha)
        options.FaceAlpha = repmat(options.FaceAlpha, n_violin, 1);
    end
    if isscalar(options.LineWidth)
        options.LineWidth = repmat(options.LineWidth, n_violin, 1);
    end
    if isscalar(options.LineStyle)
        options.LineStyle = repmat(options.LineStyle, n_violin, 1);
    end
end

for i_violin = 1:n_violin

    % Select violin aesthetics
    if all(isstring(options.Color) | ischar(options.Color))
        color = options.Color(i_violin);
    else
        color = options.Color(i_violin, :);
    end
    if all(isstring(options.LineColor) | ischar(options.LineColor))
        line_color = options.LineColor(i_violin);
    else
        line_color = options.LineColor(i_violin, :);
    end
    face_alpha = options.FaceAlpha(i_violin);
    line_width = options.LineWidth(i_violin);
    line_style = options.LineStyle(i_violin);

    % Crop the data
    y = y_matrix(:, i_violin);
    x = x_vector(i_violin);
    range_y = prctile(y, options.DensityInterval);
    cropped_y = y((y >= range_y(1)) & (y <= range_y(2)));

    if options.Discrete

        % --- Plot histogram enveloppe --- %

        % Compute the enveloppe
        y = y_matrix(:, i_violin);
        range_y = prctile(y, options.DensityInterval);
        cropped_y = y((y >= range_y(1)) & (y <= range_y(2)));
        x = x_vector(i_violin);
        hold(ax, "on");
        if options.DensityDirection == "negative"
            factor_prop = - options.DensityWidth;
        else
            factor_prop = options.DensityWidth;
        end
        unique_y_value = unique(cropped_y)';
        n_value = length(unique_y_value);
        prop_value = NaN(n_value, 1);
        for i_value = 1:n_value
            prop_value(i_value) = ...
                sum(cropped_y == unique_y_value(i_value)) / ...
                length(cropped_y);
        end

        % Plot enveloppe
        prop_value = prop_value ./ max(prop_value);
        fill(ax, ...
            [repelem(x, n_value), x + factor_prop * prop_value'], ...
            [fliplr(unique_y_value), unique_y_value], color, ...
            FaceAlpha=face_alpha, ...
            EdgeColor=color, ...
            LineWidth=line_width);
        
        % Plot compact distribution
        if options.ShowInterval
            hold(ax, "on");
            interval_y = prctile(y, [25, 75]);
            plot(ax, [x, x], interval_y, ...
                Color=color, ...
                LineWidth=options.IntervalLineWidth);
        end
        
        % Plot mean
        if options.ShowMean && length(unique_y_value) > 1
            hold(ax, "on");
            y_mean = mean(y, "omitnan");
            i_y_mean_before = find(unique_y_value <= y_mean, 1, "last");
            i_y_mean_after = find(unique_y_value >= y_mean, 1, "first");
            y_mean_before = unique_y_value(i_y_mean_before);
            y_mean_after = unique_y_value(i_y_mean_after);
            if n_value > 1
                pdf_y_mean =  prop_value(i_y_mean_before) + ...
                    (y_mean - y_mean_before) / (y_mean_after - y_mean_before)...
                    * (prop_value(i_y_mean_after) - prop_value(i_y_mean_before));
            else
                pdf_y_mean =  prop_value(i_y_mean_before);
            end
            pdf_y_mean = pdf_y_mean * factor_prop;
            coord_pdf_y_mean = x + pdf_y_mean;
            plot(ax, [coord_pdf_y_mean, x], ...
                mean(y, "omitnan") * ones(1, 2), ...
                Color=color, ...
                LineWidth=options.MeanLineWidth);
        end

    else

        % --- Plot fitted distribution --- %
    
        % Compute the distribution
        if isnan(options.BandWidth)
            [pdf_y, eval_y] = kde(cropped_y);
        else
            [pdf_y, eval_y] = kde(cropped_y, ...
                BandWidth=options.BandWidth);
        end
        pdf_y = options.DensityWidth * pdf_y ./ max(pdf_y);
    
        % Plot violin
        hold(ax, "on");
        if options.DensityDirection == "negative"
            coord_x = x - pdf_y;
        else
            coord_x = x + pdf_y;
        end
        fill(ax, coord_x, eval_y, color, ...
            EdgeColor=line_color, ...
            FaceAlpha=face_alpha, ...
            LineWidth=line_width, ...
            LineStyle=line_style);
        
        % Plot compact distribution
        if options.ShowInterval
            hold(ax, "on");
            interval_y = prctile(y, [25, 75]);
            plot(ax, [x, x], interval_y, ...
                Color=line_color, ...
                LineWidth=options.IntervalLineWidth);
        end
    
        % Plot mean
        if options.ShowMean
            hold(ax, "on");
            y_mean = mean(y(~isinf(y)), "omitnan");
            [~, i_y_mean] = min(abs(eval_y - y_mean));
            pdf_y_mean = pdf_y(i_y_mean);
            if options.DensityDirection == "negative"
                coord_pdf_y_mean = x - pdf_y_mean;
            else
                coord_pdf_y_mean = x + pdf_y_mean;
            end
            plot(ax, [coord_pdf_y_mean, x], ...
                y_mean * ones(1, 2), ...
                Color=line_color, ...
                LineWidth=options.MeanLineWidth);
        end
    end

end
