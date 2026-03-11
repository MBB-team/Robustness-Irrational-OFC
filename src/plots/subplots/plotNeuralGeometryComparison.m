function [] = plotNeuralGeometryComparison(ax, data1, data2, plot_options)
% Code for figure S2 and S3.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% data1 : <double Nx1>
%     Vectorized RDM or CCM (by default, for monkey F).
%
% data2 : <double Nx1>
%     Vectorized RDM or CCM (by default, for monkey M).
%
% line_width_thin, line_width_thick, colorbar_lim, show_colorbar, y_label,
% title, labels :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    data1 (:, 1) double
    data2 (:, 1) double
    plot_options.marker_size (1, 1) double = 20
    plot_options.line_width (1, 1) double = 0.7
    plot_options.marker_face_alpha (1, 1) double = 0.2
    plot_options.x_label (1, 1) string = "Monkey F"
    plot_options.y_label (1,1 ) string = "Monkey M"
end

hold(ax, "on");

% Scatter plot
scatter(ax, data1, data2, plot_options.marker_size, "filled",...
    Marker="o", ...
    MarkerEdgeColor="w", ...
    MarkerFaceColor="k", ...
    MarkerFaceAlpha=plot_options.marker_face_alpha, ...
    LineWidth=plot_options.line_width);

% Identity line
x_lim = xlim(ax);
y_lim = ylim(ax);
new_lim = [min(x_lim(1), y_lim(1)), max(x_lim(2), y_lim(2))];
plot(ax, new_lim, new_lim, "k:", LineWidth=plot_options.line_width);

% Correlation
[r, p] = corr(data1, data2);
x_coord = new_lim(1) + 0.1 * diff(new_lim);
y_coord_r = new_lim(2) - 0.05 * diff(new_lim);
y_coord_p = new_lim(2) - 0.15 * diff(new_lim);
text(ax, x_coord, y_coord_r, sprintf("\\rho = %0.2f", r), ...
    Color="k", ...
    FontSize=8, ...
    HorizontalAlignment="left");
if log(p) < -15
    label_p = "p < 10^{-15}";
else
    label_p = sprintf("p = %0.2e", p);
end
text(ax, x_coord, y_coord_p, label_p, ...
    Color="k", ...
    FontSize=8, ...
    HorizontalAlignment="left");

% Aesthetics
axis(ax, "square");
xlim(ax, new_lim);
ylim(ax, new_lim);
xlabel(ax, plot_options.x_label);
ylabel(ax, plot_options.y_label);
xticks(ax, []);
yticks(ax, []);
setAxFontSize(ax);

hold(ax, "off");
