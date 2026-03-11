function [] = plotRDM(ax, RDM, plot_options)
% Code for figure 2b and S2.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% RDM : <double 20x20>
%     Representational Dissimilarity Matrix. See also: computeRDM.
%
% line_width_thin, line_width_thick, colorbar_lim, show_colorbar, y_label,
% title, labels :
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
    plot_options.show_colorbar (1, 1) logical = false
    plot_options.y_label (1,1 ) string = ""
    plot_options.title (1,1 ) string = ""
    plot_options.labels (1, 4) logical = [false, false, false, false]
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
if ~ isempty(plot_options.y_label)
    text(ax, -2.5, 10.5, plot_options.y_label, ...
        FontSize=8, ...
        FontWeight="bold", ...
        Rotation=90, ...
        HorizontalAlignment="center", ...
        VerticalAlignment="middle");
end
if ~ isempty(plot_options.title)
    text(ax, 10.5, -2.5, plot_options.title, ...
        FontSize=8, ...
        FontWeight="bold", ...
        HorizontalAlignment="center", ...
        VerticalAlignment="middle");
end
if any (plot_options.labels)
    cue_labels = ["Prob L.", "Mag L.", "Prob R.", "Mag R."];
    for i_side = 1:4
        if plot_options.labels(i_side)
            for i_label = 1:4
                switch i_side
                    case 1
                        x = 3 + 5 * (i_label - 1);
                        y = -0.7;
                        rot = 0;
                    case 2
                        y = 3 + 5 * (i_label - 1);
                        x = -0.7;
                        rot = 90;
                    case 3
                        x = 3 + 5 * (i_label - 1);
                        y = 21.7;
                        rot = 0;
                    case 4
                        y = 3 + 5 * (i_label - 1);
                        x = 21.7;
                        rot = 90;
                end
                text(ax, x, y, cue_labels(i_label), ...
                    FontSize=8, ...
                    Rotation=rot, ...
                    HorizontalAlignment="center", ...
                    VerticalAlignment="middle");
            end
        end
    end
end
setAxFontSize(ax);

% Colorbar
colormap(ax, defineDivergentColormap());
if plot_options.show_colorbar
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
end

hold(ax, "off");
