function [] = plotSchemeEIbalance(ax, plot_options)
% Code for figure 5d.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% line_style_excitatory, line_style_inhibitory, line_width,
% connection_color :
%     Name-value parameter controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    plot_options.line_style_excitatory (1, 1) string = "-"
    plot_options.line_style_inhibitory (1, 1) string = ":"
    plot_options.line_width (1, 1) double = 1
    plot_options.connection_color (1, 3) double = [0.5, 0.5, 0.5]
end

hold(ax, "on");

% Define circle properties
rng(3);
n_units = 8;
theta_units = 2 * pi * linspace(0, 1, n_units + 1);
theta_units = theta_units(2:end);
x_units = cos(theta_units);
y_units = sin(theta_units);
n_connec = [1, 0, 1, 2, 1, 1, 0, 3];

% --- Draw connections between units --- %

for i_unit = 1:n_units

    % Connection between successive units
    x_current_unit = x_units(i_unit);
    y_current_unit = y_units(i_unit);
    if i_unit == n_units
        i_next_unit = 1;
    else
        i_next_unit = i_unit + 1;
    end
    if i_unit == 1
        i_last_unit = n_units;
    else
        i_last_unit = i_unit - 1;
    end
    x_next_unit = x_units(i_next_unit);
    y_next_unit = y_units(i_next_unit);
    is_excitatory = logical(randi(2) - 1);
    if is_excitatory
        line_style = plot_options.line_style_excitatory;
    else
        line_style = plot_options.line_style_inhibitory;
    end
    plot(ax, ...
        [x_current_unit, x_next_unit], ...
        [y_current_unit, y_next_unit], ...
        Color=plot_options.connection_color, ...
        LineStyle=line_style, ...
        LineWidth=plot_options.line_width);

    % Random connections with other units
    for i_connec = 1:n_connec(i_unit)
        i_random_unit = i_unit;
        while (i_random_unit == i_unit) || ...
                (i_random_unit == i_next_unit) || ...
                (i_random_unit == i_last_unit)
            i_random_unit = randi(n_units);
        end
        x_random_unit = x_units(i_random_unit);
        y_random_unit = y_units(i_random_unit);
        is_excitatory = logical(randi(2) - 1);
        if is_excitatory
            line_style = plot_options.line_style_excitatory;
        else
            line_style = plot_options.line_style_inhibitory;
        end
        plot(ax, ...
            [x_current_unit, x_random_unit], ...
            [y_current_unit, y_random_unit], ...
        Color=plot_options.connection_color, ...
        LineStyle=line_style, ...
        LineWidth=plot_options.line_width);
    end
end

% Draw units
scatter(ax, x_units, y_units, 60, ...
    MarkerEdgeColor="k", ...
    MarkerFaceColor="w", ...
    LineWidth=plot_options.line_width);

% Legend
ghost_plot = {};
ghost_plot{end + 1} = plot(ax, NaN, NaN, ...
    Color=plot_options.connection_color, ...
    LineStyle=plot_options.line_style_excitatory, ...
    LineWidth=plot_options.line_width, ...
    DisplayName="Excitatory");
ghost_plot{end + 1} = plot(ax, NaN, NaN, ...
    Color=plot_options.connection_color, ...
    LineStyle=plot_options.line_style_inhibitory, ...
    LineWidth=plot_options.line_width, ...
    DisplayName="Inhibitory");
legend(ax, [ghost_plot{:}], ...
    Location="northoutside", ...
    Box="off", ...
    AutoUpdate="off", ...
    IconColumnWidth=10);

% Aesthetics
xlim(ax, [-1.01, 1.01]);
ylim(ax, [-1.01, 1.01]);
set(ax, XColor="none", YColor="none");
axis(ax, "square");
setAxFontSize(ax);

hold(ax, "off");
