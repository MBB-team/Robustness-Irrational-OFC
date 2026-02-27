function [] = plotSchemeCodeRedundancy(ax)
% Code for figure 5b.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
end

hold(ax, "on");

% Draw reversed cumulative density function
x = linspace(0, 1, 1000);
y = betapdf(x, 1, 6) / 1000;
y = cumsum(y);
y = fliplr(y);
fill_area = fill(ax, [x, fliplr(x)], [y, zeros(size(y))], "k", ...
    EdgeColor="none", ...
    FaceAlpha=0.2, ...
    DisplayName="Code redundancy");
plot(ax, x, y, ...
    Color="k", ...
    LineWidth=1);

% Legend
legend(ax, fill_area, ...
    Location="northoutside", ...
    Box="off", ...
    AutoUpdate="off", ...
    IconColumnWidth=10);

% Aesthetics
xlabel(ax, "Unit activation threshold");
ylabel(ax, "P(co-activation)");
xlim(ax, [0, 1]);
ylim(ax, [0, 1.05]);
xticks(ax, [0, 0.5, 1]);
yticks(ax, [0, 0.5, 1]);
setAxFontSize(ax);

hold(ax, "off");
