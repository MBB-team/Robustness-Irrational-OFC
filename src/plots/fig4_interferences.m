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
        "constraint_label", "constraint_weight", ...
        all_constraint_label(i_constraint), "bacc_optimal_avg"], ...
        "rational_last");


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure 1: decision task, neural net design, option values and impact of constraints", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 11], ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 3, 4, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[0, 0, 16.5, 10.5]);

% Subplots
plotImageInAx(nexttile(1, [1, 3]), fullfile(getPath("Figures"), "fig1a.png"));
plotImageInAx(nexttile(5, [2, 3]), fullfile(getPath("Figures"), "fig1b.png"));
plotConstraintsVsRationality(nexttile(4, [1, 1]), all_Data{1}, ...
    "info_transfer_rate", "Information transfer rate (a.u.)");
plotConstraintsVsRationality(nexttile(8, [1, 1]), all_Data{2}, ...
    "energetic_budget_avg", "Energetic budget (a.u.)");

% Subplot letters
writePanelLetter(nexttile(1, [1, 3]), "a", -0.4, -0.1);
writePanelLetter(nexttile(5, [2, 3]), "b", 0.4, -0.1);
writePanelLetter(nexttile(4, [1, 1]), "c", -0.4, -0.1);
writePanelLetter(nexttile(8, [1, 1]), "d", -0.4, -0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "fig4.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "fig4.png"), Resolution=600);
