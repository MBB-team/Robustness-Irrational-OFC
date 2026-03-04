% Fig. 4 | Interference mechanisms in irrational models and monkeys.
%
%   - a, Schematic procedure for evaluating the RNNs' sensitivity to cue
% presentation order.
% 
%   - b, Standard deviation of the irrational value synthesis RNNs' outputs
% in response to random permutations of cue sequence orders (y-axis), as a
% function of cue onset times (x-axis) during option trials only (light) or
% attribute trials only (dark). Asterisks indicate p-value < 0.005.
%
%   - c, Same format as panel b, but for irrational value comparison RNNs.
%
%   - d, Rate of monkeys' irrational choices (y-axis), as a function of cue
% onset time, for both option (light) and attribute (dark) trials.
% Asterisks indicate that the difference between time steps (averaged over
% both monkeys and trial types) are significant, with p-value < 0.02.
%
%   - e, Average residual irrational choice rate, once decision difficulty
% has been regressed away (same format as panel d).
%
%   - f, Average value output of irrational value synthesis RNNs (greyscale
% nuances), as a function of the rank of both previously (x-axis) and
% currently (y-axis) attended cues (see Methods).
%
%   - g, Same format as panel f, but for irrational value comparison RNNs.
%
%   - h/i, Same format as panel f, but for both monkeys (h: monkey F,
% i: monkey M). 
%
%   - j, Average difference in the gradient of the RNNs' value output
% w.r.t. cue rank (attended cue minus unattended cue, see Methods), for
% both rational (light) and irrational (dark) variants of RNNs (blue: value
% synthesis, orange: value comparison). The asterisk denotes a significant
% difference between rational and irrational RNNs, with p-value < 0.01.
% Black dotted lines indicate the gradient difference for both monkeys.



%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

Data = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", ...
        "std_order_option_per_step", "std_order_attribute_per_step", ...
        "std_order_per_step", ...
        "value_function_attended", "value_function_attended_gradient_diff"], ...
        "rational_last");

MonkeyPropData = load(fullfile(getPath("MonkeyData"), "PropIrrational.mat"));
MonkeyResidualsData = load(fullfile(getPath("MonkeyData"), "DecisionResiduals.mat"));


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure 4: interference mechanisms in irrational models and monkeys", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 12.5], ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 3, 4, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[1, 1, 15.5, 11]);

% Subplots
plotImageInAx(nexttile(1, [1, 2]), fullfile(getPath("Figures"), "fig4a.png"));
plotCueOrderPollutionDistrib(nexttile(5, [1, 1]), Data, 9);
plotCueOrderPollutionDistrib(nexttile(6, [1, 1]), Data, 10);
plotMonkeyIrrationalChoices(nexttile(9, [1, 1]), MonkeyPropData, false);
plotMonkeyIrrationalChoices(nexttile(10, [1, 1]), MonkeyResidualsData, true);
plotAttendedValueProfile(nexttile(3, [1, 1]), Data, ...
    Data.config_ID == 9 & Data.is_rational, "Rational synthesis");
plotAttendedValueProfile(nexttile(4, [1, 1]), Data, ...
    Data.config_ID == 10 & Data.is_rational, "Rational comparison");
plotAttendedValueProfile(nexttile(7, [1, 1]), Data, ...
    Data.config_ID == 9 & Data.is_irrational, "Irrational synthesis");
plotAttendedValueProfile(nexttile(8, [1, 1]), Data, ...
    Data.config_ID == 10 & Data.is_irrational, "Irrational comparison");
plotCueAttentionPollutionDistrib(nexttile(11, [1, 1]), Data, 9);
plotCueAttentionPollutionDistrib(nexttile(12, [1, 1]), Data, 10);

% Colorbar
ax_top_right = nexttile(4, [1, 1]);
ax_middle_right = nexttile(8, [1, 1]);
cbar = colorbar(ax_top_right);
cbar.Position = [...
    ax_top_right.Position(1) + ax_top_right.Position(3) + 0.04, ...
    ax_middle_right.Position(2) - 0.01, ...
    cbar.Position(3), ...
    ax_top_right.Position(2) + ax_top_right.Position(4) - ax_middle_right.Position(2) + 0.045];
cbar.Label.String = "Value (a.u.)";
cbar.Label.Position(1) = cbar.Label.Position(1) - 0.5;
data_heatmap_top_right = mean(Data.value_function_attended(:, Data.config_ID == 10 & Data.is_rational), 2);
cbar.Ticks = [min(data_heatmap_top_right, [], "all"), max(data_heatmap_top_right, [], "all")];
cbar.TickLabels = ["min", "max"];
cbar.YAxisLocation = "right";
cbar.Label.Position(1) = cbar.Label.Position(1) - 1;
fontsize(cbar, 8, "points");

% Subplot letters
writePanelLetter(nexttile(1, [1, 2]), "a", -0.2, -0.1);
writePanelLetter(nexttile(5, [1, 1]), "b", -0.5, -0.1);
writePanelLetter(nexttile(6, [1, 1]), "c", -0.5, -0.1);
writePanelLetter(nexttile(9, [1, 1]), "d", -0.4, 0);
writePanelLetter(nexttile(10, [1, 1]), "e", -0.4, 0);
writePanelLetter(nexttile(3, [1, 1]), "f", -0.4, -0.1);
writePanelLetter(nexttile(4, [1, 1]), "g", -0.4, -0.1);
writePanelLetter(nexttile(7, [1, 1]), "h", -0.4, -0.1);
writePanelLetter(nexttile(8, [1, 1]), "i", -0.4, -0.1);
writePanelLetter(nexttile(11, [1, 1]), "j", -0.2, -0.1);
writePanelLetter(nexttile(12, [1, 1]), "k", -0.2, -0.1);

% Set font globally
fontname(f, "arial");
cbar.YAxisLocation = "right";


% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "fig4.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "fig4.png"), Resolution=600);
