% Fig. 5 | Potential biological benefits of irrational circuits.
%
% For all panels, asterisks indicate a significant difference between
% rational (light) and irrational (dark) RNNs (blue: value synthesis,
% orange: value comparison), with p-value < 0.005.
% 
% - a, Metabolic cost, measured as the average network activity, over all
% trials, trial steps, and units.
% 
% - b, Neural code redundancy, measured as the average co-activation
% probability over all integration units pairs.
% 
% - c, Information transfer rate, measured as the entropy of units response
% outputs.
% 
% - d, Excitatory-inhibitory balance, measured as the relative proportion
% of negative and positive connection weights.
% 
% - e, Tolerance to neural loss, measured as the retained rate of rational
% choice from 10% to 50% of lesioned units.


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

Data = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", ...
        "energetic_budget_avg", "code_redundancy", "info_transfer_rate", ...
        "EI_balance", ...
        "avg_prop_optimal_impaired_units"], ...
        "rational_last");


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure 5: potential biological benefits of irrational circuits", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 9], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 2, 5, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[0.8, 0.2, 17, 7]);

% Subplots
plotSchemeEnergeticBudget(nexttile(1, [1, 1]));
plotSchemeCodeRedundancy(nexttile(2, [1, 1]));
% plotSchemeInfoTransferRate(nexttile(3, [1, 1]));
plotSchemeEIbalance(nexttile(4, [1, 1]));
% plotSchemeRobustness(nexttile(5, 1, 1), Data);
plotBiologicalBenefitDistrib(nexttile(6, [1, 1]), Data, "energetic_budget_avg");
plotBiologicalBenefitDistrib(nexttile(7, [1, 1]), Data, "code_redundancy");
plotBiologicalBenefitDistrib(nexttile(8, [1, 1]), Data, "info_transfer_rate");
plotBiologicalBenefitDistrib(nexttile(9, [1, 1]), Data, "EI_balance");

% Prepare subplot letter adjustment
ax_square = nexttile(4, [1, 1]);
ax_nonsquare = nexttile(1, [1, 1]);
set(ax_square, Units="centimeters");
set(ax_nonsquare, Units="centimeters");
shift_d_letter = ax_nonsquare.Position(2) + ax_nonsquare.Position(4) ...
    - ax_square.Position(2) - ax_square.Position(4);

% Subplot letters
writePanelLetter(nexttile(1, [1, 1]), "a", -0.4, 1.2);
writePanelLetter(nexttile(2, [1, 1]), "b", -0.4, 1.2);
writePanelLetter(nexttile(3, [1, 1]), "c", -0.4, 1.2);
writePanelLetter(nexttile(4, [1, 1]), "d", -0.4, 1.2 + shift_d_letter);
writePanelLetter(nexttile(5, [1, 1]), "e", -0.4, 1.2);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "fig5.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "fig5.png"), Resolution=600);
