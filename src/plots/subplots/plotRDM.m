function [] = plotRDM(ax, RDM, plot_options)
% Code for figure 2b.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% RDM : <double 20x20>
%     Representational Dissimilarity Matrix. See also: computeRDM.
%
% line_width_thin, line_width_thick, colorbar_lim :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    RDM (20, 20) double
    plot_options.line_width_thin (1, 1) double = 1
    plot_options.line_width_thick (1, 1) double = 2
    plot_options.colorbar_lim (1, 1) double = 1
end

hold(ax, "on");

% Heatmap
imagesc(ax, RDM, [-0.3, 0.3]);

% RDM grid
hold(ax, "on");
plot(ax, [0.5, 20.5], [0.5, 0.5], "k-", LineWidth=plot_options.line_width_thin);
plot(ax, [0.5, 20.5], [20.5, 20.5], "k-", LineWidth=plot_options.line_width_thin);
plot(ax, [0.5, 0.5], [0.5, 20.5], "k-", LineWidth=plot_options.line_width_thin);
plot(ax, [20.5, 20.5], [0.5, 20.5], "k-", LineWidth=plot_options.line_width_thin);
plot(ax, [0.5, 20.5], [10.5, 10.5], "k-", LineWidth=plot_options.line_width_thick);
plot(ax, [10.5, 10.5], [0.5, 20.5], "k-", LineWidth=plot_options.line_width_thick);
plot(ax, [0.5, 20.5], [5.5, 5.5], "k-", LineWidth=plot_options.line_width_thin);
plot(ax, [0.5, 20.5], [15.5, 15.5], "k-", LineWidth=plot_options.line_width_thin);
plot(ax, [5.5, 5.5], [0.5, 20.5], "k-", LineWidth=plot_options.line_width_thin);
plot(ax, [15.5, 15.5], [0.5, 20.5], "k-", LineWidth=plot_options.line_width_thin);

% --- Aesthetics --- %

xticks(ax, [3, 8, 13, 18]);
yticks(ax, [3, 8, 13, 18]);
xlim(ax, [0.5, 20.5]);
ylim(ax, [0.5, 20.5]);
xticklabels(ax, ["Prob L.", "Mag L.", "Prob R.", "Mag R."]);
yticklabels(ax, ["Prob L.", "Mag L.", "Prob R.", "Mag R."]);
ytickangle(ax, 90);
set(ax, ...
    XAxisLocation="top", ...
    Ydir="reverse", ...
    CLim=[-plot_options.colorbar_lim, plot_options.colorbar_lim], ...
    XColor="none", ...
    YColor="none");
axis(ax, "square");
setAxFontSize(ax);

% Colorbar
colormap(ax, defineDivergentColormap());
cb = colorbar(...
    ax, ...
    Ticks=[-plot_options.colorbar_lim, 0, plot_options.colorbar_lim], ...
    FontName="Arial", ...
    FontSize=8, ...
    Location="eastoutside");
cb.Label.String = "Correlation";
cb.Label.FontSize = 8;
cb.Label.FontName = "Arial";
cb.Label.Position(1) = cb.Label.Position(1) - 0.5;

hold(ax, "off");
