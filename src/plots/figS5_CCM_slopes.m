% Fig. S5 | Comparison of CCM entries across monkeys.
% 
% a, The CCM entries of rational RNNs (y-axis) are plotted against the CCM
% entries of their associated monkey (x-axis). Each dot is a given CCM
% entry (blue: value synthesis, orange: value comparison), and lines relate
% pairs of entries across monkeys. Accurate predictions of inter-individual
% differences would show up as oblique lines, aligned with the main
% diagonal (positive slopes).
% 
% b, Same thing for re-trained (irrational) RNNs.
% 
% c, Distribution of the average slope (across CCM cells) under the null,
% for the irrational value synthesis RNNs (blue) and irrational value
% comparison RNNs (orange). The horizontal lines with a diamond show the
% average slope in the actual data.


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

Data = loadMeasureResults(["config_ID", "is_rational", "is_irrational", "fit_label", ...
    "CCM_option", "CCM_attribute"], "rational_last");

MonkeyNeuralGeometry = load(fullfile(getPath("MonkeyData"), "NeuralGeometry.mat"));


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure S5: comparison of CCM entries across monkeys", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 1, 3, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[1, 0.5, 16, 4]);

% Subplots
plotCCMcellsComparison(nexttile(1, [1, 1]), Data, MonkeyNeuralGeometry, ...
    "rational");
plotCCMcellsComparison(nexttile(2, [1, 1]), Data, MonkeyNeuralGeometry, ...
    "irrational");
plotCCMslopesDistrib(nexttile(3, [1, 1]), Data, MonkeyNeuralGeometry);

% Subplot letters
writePanelLetter(nexttile(1, [1, 1]), "a", -0.4, -0.1);
writePanelLetter(nexttile(2, [1, 1]), "b", -0.4, -0.1);
writePanelLetter(nexttile(3, [1, 1]), "c", -0.4, -0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

saveas(f, fullfile(getPath("Figures"), "figS5.pdf"));
exportgraphics(f, fullfile(getPath("Figures"), "figS5.png"), Resolution=600);
