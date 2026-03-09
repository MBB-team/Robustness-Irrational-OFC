% Fig. 1 | Decision task, neural net design, option values and impact of
% constraints.
%
%   - a, Task design. Adapted from Hunt et al., 2018. At each trial,
% monkeys choose between two options presented on the left and right sides
% of a screen, each defined by the probability and prospective amount of a
% rewarding juice. Each decision cue (representing either the probability
% or the magnitude of the -currently attended- option) appears sequentially
% and then disappears. Monkeys can commit to a decision at any point after
% the second cue without necessarily sampling the remaining cues and are
% free to decide which cue to sample if they decide to continue the trial. 
%
%   - b, Neural net architecture (see Methods). At each cue onset, the
% neural net’s inputs (back dots) encode the currently attended cue in
% terms of its three raw features (i.e., option identity, cue type and cue
% rank), while its outputs are the neural net’s current estimate of option
% values (value synthesis, blue dots) or value difference (value
% comparison, orange dot). Feedforward connections convey input features to
% a layer of input-specific units, which send their outputs to an
% input-integration layer. Importantly, the latter is equipped with
% feedback/recurrent connections that carry reentrant value computations
% from previously attended cues. Note that both the identity of the
% attended option and value outputs can be encoded in distinct formats
% (see Methods).
%
%   - c/d/e, Neural net training under multiple constraints. Neural nets
% can be trained to optimize a compromise between rational value
% computations, on the one hand, and information transfer rate (c),
% energetic budget (d) or tolerance to damage (e), on the other hand
% (see Methods). Each dot depicts the rate of rational choices (y-axis) and
% constraint adequacy (x-axis) for a given constraint compliance weight
% (gray scale). One can see that imposing stronger compliance with such
% constraints tends to compromise decision rationality, because the
% underlying network wiring eventually alters value computations.


%% === Environment set-up =================================================

setup;
clear variables;
close all; 


%% === Load data ==========================================================

all_constraint_label = ["info_transfer_rate", "energetic_budget_avg", ...
    "prop_optimal_impaired_units"];
n_constraint = length(all_constraint_label);
all_Data = cell(1, n_constraint);

for i_constraint = 1:n_constraint
    all_Data{i_constraint} = loadMeasureResults([...
        "config_ID", "fit_label", ...
        "constraint_label", "constraint_weight", ...
        all_constraint_label(i_constraint), "bacc_optimal_avg"], ...
        "rational_" + all_constraint_label(i_constraint) + "_last");
    % Only consider the tolerance to damage of one unit
    if all_constraint_label(i_constraint) == "prop_optimal_impaired_units"
        all_Data{i_constraint}.prop_optimal_impaired_units = ...
            all_Data{i_constraint}.prop_optimal_impaired_units(1, :);
    end
end


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure 1: decision task, neural net design, option values and impact of constraints", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 12.5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 3, 5, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[0, 0.5, 16.5, 11.5]);

% Subplots
plotImageInAx(nexttile(1, [3, 4]), fullfile(getPath("Figures"), "fig1ab.png"));
plotConstraintsVsRationality(nexttile(5, [1, 1]), all_Data{1}, ...
    "info_transfer_rate", "Information transfer rate (a.u.)");
plotConstraintsVsRationality(nexttile(10, [1, 1]), all_Data{2}, ...
    "energetic_budget_avg", "Energetic budget (a.u.)");
% plotConstraintsVsRationality(nexttile(15, [1, 1]), all_Data{3}, ...
%     "prop_optimal_impaired_units", "Tolerance to damage (a.u.)");

% Subplot letters
writePanelLetter(nexttile(1, [3, 4]), "a", 0.7, -0.5);
writePanelLetter(nexttile(1, [3, 4]), "b", 0.7, -5);
writePanelLetter(nexttile(5, [1, 1]), "c", -0.4, -0.1);
writePanelLetter(nexttile(10, [1, 1]), "d", -0.4, -0.1);
writePanelLetter(nexttile(15, [1, 1]), "e", -0.4, -0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "fig1.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "fig1.png"), Resolution=600);
