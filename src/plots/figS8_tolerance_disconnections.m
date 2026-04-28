% Fig. S8 | Comparing the tolerance to structural lesions and neural noise
% in rational and irrational RNNs.
% 
% a, Distributions (across network instances) of tolerance to unit lesions,
% measured as the retained rate of rational choice from 10% to 50% of
% lesions, for value synthesis (blue) and value comparison (orange) RNNs
% that rely on a temporal option identity format and an attentional value
% readout format. Asterisks indicate a significant difference between
% rational (light) and irrational (dark) RNNs, with p-value < 0.005. Note
% that both types of irrational models (either retrained from rational RNNs
% or directly trained from monkeys' irrational choices) are shown here.
% 
% b and c, Same format as panel a, showing the tolerance to connection
% lesions from 10% to 50% of lesions (b), and the tolerance to neural noise
% averaged the over the full range of noise variance (c).
% 
% d, Tolerance to unit lesions as a function of lesion level. Asterisks
% indicate significant differences between rational (dotted line, circles)
% models and irrational (solid lines) models, including both retrained
% (triangles) or trained directly (diamonds) RNNs, for value synthesis
% (blue) and value comparison (orange) models, with p-value < 0.005 for
% each comparison.
% 
% e and f, Same format as panel d, showing the tolerance to connection
% lesions (e) and neural noise (f).


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

DataIndirect = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", ...
        "avg_prop_optimal_impaired_units", "prop_optimal_impaired_units", ...
        "avg_prop_optimal_impaired_connec", "prop_optimal_impaired_connec", ...
        "prop_optimal_noise"], ...
        "rational_last");

DataFranck = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", ...
        "avg_prop_optimal_impaired_units", "prop_optimal_impaired_units", ...
        "avg_prop_optimal_impaired_connec", "prop_optimal_impaired_connec", ...
        "prop_optimal_noise"], ...
        "irrational_Franck_last");

DataMiles = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", "fit_step", ...
        "avg_prop_optimal_impaired_units", "prop_optimal_impaired_units", ...
        "avg_prop_optimal_impaired_connec", "prop_optimal_impaired_connec", ...
        "prop_optimal_noise"], ...
        "irrational_Miles_last");

% Average robustness to neural noise
DataIndirect.avg_prop_optimal_noise = mean(DataIndirect.prop_optimal_noise, 1);
DataFranck.avg_prop_optimal_noise = mean(DataFranck.prop_optimal_noise, 1);
DataMiles.avg_prop_optimal_noise = mean(DataMiles.prop_optimal_noise, 1);

%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure S8: comparing the tolerance to disconnections in rational and irrational RNNs", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 10], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 2, 3, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[1.4, 0.8, 16, 8.7]);

% Subplots
plotRobustnessDistribPerFit(nexttile(1, [1, 1]), "impaired_units", ...
    DataIndirect, DataFranck, DataMiles);
plotRobustnessDistribPerFit(nexttile(2, [1, 1]), "impaired_connec", ...
    DataIndirect, DataFranck, DataMiles);
plotRobustnessDistribPerFit(nexttile(3, [1, 1]), "noise", ...
    DataIndirect, DataFranck, DataMiles);
plotRobustnessTrajectoryPerFit(nexttile(4, [1, 1]), "impaired_units", ...
    DataIndirect, DataFranck, DataMiles);
plotRobustnessTrajectoryPerFit(nexttile(5, [1, 1]), "impaired_connec", ...
    DataIndirect, DataFranck, DataMiles, plot_legend=true);
plotRobustnessTrajectoryPerFit(nexttile(6, [1, 1]), "noise", ...
    DataIndirect, DataFranck, DataMiles);

% Subplot letters
writePanelLetter(nexttile(1, [1, 1]), "a", -1, -0.1);
writePanelLetter(nexttile(2, [1, 1]), "b", -1, -0.1);
writePanelLetter(nexttile(3, [1, 1]), "c", -1, -0.1);
writePanelLetter(nexttile(4, [1, 1]), "d", -1, -0.1);
writePanelLetter(nexttile(5, [1, 1]), "e", -1, -0.1);
writePanelLetter(nexttile(6, [1, 1]), "f", -1, -0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

saveas(f, fullfile(getPath("Figures"), "figS8.pdf"));
exportgraphics(f, fullfile(getPath("Figures"), "figS8.png"), Resolution=600);
