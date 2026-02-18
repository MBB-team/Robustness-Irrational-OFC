function [] = plotValueProfileComparison(ax, Data, MonkeyData, plot_options)
% Code for figure 3d.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - value_function: see fitOneValueProfile
%       - is_rational
%
% MonkeyData : <struct 1x1>
%     Structure containing value functions fitted on each monkey behaviour
%     (see also: fitMonkeyValueProfile).
%
% marker_size, marker_alpha, line_width :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    MonkeyData (1, 1) struct
    plot_options.marker_size (1, 1) double = 25
    plot_options.marker_alpha (1, 1) double = 0.3
    plot_options.line_width (1, 1) double = 0.5
end

hold(ax, "on");

% ~ Loop over monkeys ~ %
for monkey = ["Franck", "Miles"]

    % Prepare legend label
    monkey_initial = char(monkey);
    monkey_initial = monkey_initial(1);
    monkey_initial = string(monkey_initial);

    % Scatter
    scatter(ax, ...
        zscore(mean(Data.value_function(:, Data.is_rational), 2))', ...
        zscore(reshape(MonkeyData.(monkey).value_function, [], 1))', ...
        plot_options.marker_size, ...
        Marker=defineMonkeyMarker(monkey), ...
        MarkerEdgeColor=defineMonkeyColor(monkey), ...
        MarkerFaceColor=defineMonkeyColor(monkey), ...
        MarkerFaceAlpha=plot_options.marker_alpha, ...
        LineWidth=plot_options.line_width, ...
        DisplayName="Monkey " + monkey_initial);
end

% Legend
lgd = legend(ax, ...
    Location="northwest", ...
    IconColumnWidth=6, ...
    Box="off", ...
    AutoUpdate="off");
lgd.Position(1) = lgd.Position(1) - 0.005;
lgd.Position(2) = lgd.Position(2) + 0.05;

% Identity line
x_lim = xlim(ax);
y_lim = ylim(ax);
new_lim = [min([x_lim(1), y_lim(1)]), max([x_lim(2), y_lim(2)])];
plot(ax, new_lim, new_lim, "k:", LineWidth=1);

% Ax aesthetics
axis(ax, "square", "equal");
xlim(ax, new_lim);
ylim(ax, new_lim);
xticks(ax, -1:2);
yticks(ax, -1:2);
xlabel(ax, "Rational values (z-scored)");
ylabel(ax, "Monkey values (z-scored)");
setAxFontSize(ax);

hold(ax, "off");
