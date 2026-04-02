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
    Position = [0, 0, 18, 4.5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 1, 5, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[0.8, 0.3, 17, 3.5]);

% Subplots
plotBiologicalBenefitDistrib(nexttile(1, [1, 1]), Data, "energetic_budget_avg");
plotBiologicalBenefitDistrib(nexttile(2, [1, 1]), Data, "code_redundancy");
plotBiologicalBenefitDistrib(nexttile(3, [1, 1]), Data, "info_transfer_rate");
plotBiologicalBenefitDistrib(nexttile(4, [1, 1]), Data, "EI_balance");
plotBiologicalBenefitDistrib(nexttile(5, [1, 1]), Data, "avg_prop_optimal_impaired_units");

% Subplot letters
writePanelLetter(nexttile(1, [1, 1]), "a", -0.4, 0.1);
writePanelLetter(nexttile(2, [1, 1]), "b", -0.4, 0.1);
writePanelLetter(nexttile(3, [1, 1]), "c", -0.4, 0.1);
writePanelLetter(nexttile(4, [1, 1]), "d", -0.4, 0.1);
writePanelLetter(nexttile(5, [1, 1]), "e", -0.4, 0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "fig5.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "fig5.png"), Resolution=600);
