function [] = plotInformationDecodingAccuracy(ax, Data, plot_options)
% Code for figure S1a.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% Data : <struct 1x1>
%     Structure containing model analysis results. Must include:
%       - config_ID, is_rational: see gatherAllModels
%       - R2_decode_both_attention, R2_decode_diff_attention,
%       R2_decode_both_order, R2_decode_diff_order, ...
%       R2_decode_both_loc, R2_decode_diff_loc: see 
%       computeFrameworkInformationLoss
%
% line_width, marker_size:
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    Data (1, 1) struct
    plot_options.line_width (1, 1) double = 0.7
    plot_options.marker_size (1, 1) double = 5
    plot_options.font_size_labels (1, 1) double = 7
    plot_options.marker_line_shift (1, 1) double = 0.35
end

hold(ax, "on");


% Average R2s among cohorts
decode_data = [...
    Data.R2_decode_both_attention ; ...
    Data.R2_decode_diff_attention ; ...
    Data.R2_decode_both_order ; ...
    Data.R2_decode_diff_order ; ...
    Data.R2_decode_both_loc ; ...
    Data.R2_decode_diff_loc];
decode_avg = NaN(6, 10);

for i_config = 1:10
    select_config = Data.config_ID == i_config & Data.is_rational;
    for i_decode = 1:6
        decode_avg(i_decode, i_config) = mean(decode_data(i_decode, select_config));
    end
end

% Heatmap
imagesc(ax, decode_avg, [0, 1]);
decode_avg

% Grid
for i_line = 0.5:2:6.5
    plot(ax, [0.5, 10.5], [i_line, i_line], "k-", ...
        LineWidth=plot_options.line_width);
end
for i_col = 0.5:2:10.5
    plot(ax, [i_col, i_col], [0.5, 6.5], "k-", ...
        LineWidth=plot_options.line_width);
end

% Colormap
colormap(ax, defineSequentialColormap());

% Colorbar
cb = colorbar(ax, ...
    Ticks=[], ...
    Location="eastoutside");
cb.Label.String = "Decoding accuracy (R2)";

% --- Aesthetics --- %

% Y labels
y_tick_labels = [...
    "V(att.) & V(unatt.)", "V(att.) - V(unatt.)" ...
    "V(first) & V(second)", "V(first) - V(second)", ...
    "V(left) & V(right)", "V(left) - V(right)"];
for i_label = 1:6
    text(ax, 0.3, i_label, y_tick_labels(i_label), ...
    FontSize=8, ...
    HorizontalAlignment="right");
end

set(ax, YDir="reverse", YColor="none", XColor="none");
xlim(ax, [0.5, 10.5]);
ylim(ax, [-0.5, 6.5]);
xticks(ax, []);
yticks(ax, 1:6);
setAxFontSize(ax);

% Text labels
for i_config = 1:10
    for j_decode = 1:6
        decode_cell = decode_avg(j_decode, i_config);
        if decode_cell < 0.5
            color_text = "w";
        else
            color_text = "k";
        end
        text(ax, i_config, j_decode, sprintf("%0.1f", decode_cell), ...
            Color=color_text, ...
            FontName="Arial", ...
            FontSize=plot_options.font_size_labels, ...
            HorizontalAlignment="center");
    end
end

% Config markers
for i_config = 1:10
    plot(ax, i_config + plot_options.marker_line_shift * [-1, 1], [0, 0], ...
        LineWidth=plot_options.line_width, ...
        Color=defineModelColor(i_config), ...
        LineStyle=defineModelLineStyle(i_config));
    plot(ax, i_config, 0, ...
        LineStyle="none", ...
        LineWidth=plot_options.line_width, ...
        Marker=defineModelMarker(i_config), ...
        MarkerFaceColor="w", ...
        MarkerEdgeColor=defineModelColor(i_config), ...
        MarkerSize=plot_options.marker_size);
end

hold(ax, "off");
