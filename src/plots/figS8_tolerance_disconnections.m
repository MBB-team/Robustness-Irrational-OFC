% Fig. S8 | Comparing the tolerance to disconnections in rational and
% irrational RNNs. Distributions (across cohort instances) of the tolerance
% to neural disconnections, measured as the retained rate of rational
% choice from 10% to 50% of recurrent connections within the integration
% layer, for value synthesis (blue) and value comparison (orange) RNNs that
% rely on a temporal option identity format and an attentional value
% readout format. Asterisks indicate a significant difference between
% rational (light) and irrational (dark) RNNs, with p-value < 0.005. Note
% that both types of irrational models (either retrained from rational RNNs 
% or directly trained from monkeys' irrational choices) are shown here.


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

DataIndirect = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", ...
        "avg_prop_optimal_impaired_connec", "prop_optimal_noise"], ...
        "rational_last");

DataFranck = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", ...
        "avg_prop_optimal_impaired_connec", "prop_optimal_noise"], ...
        "irrational_Franck_last");

DataMiles = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", "fit_step", ...
        "avg_prop_optimal_impaired_connec", "prop_optimal_noise"], ...
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
    Position = [0, 0, 18, 5.5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 1, 2, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[1.4, 1, 16.5, 4]);

% Subplots
plotAlternativeRobustnessMeasurePerFit(nexttile(1, [1, 1]), "impaired_connec", ...
    DataIndirect, DataFranck, DataMiles);
plotAlternativeRobustnessMeasurePerFit(nexttile(2, [1, 1]), "noise", ...
    DataIndirect, DataFranck, DataMiles);

% Subplot letters
writePanelLetter(nexttile(1, [1, 1]), "a", -1, -0.1);
writePanelLetter(nexttile(2, [1, 1]), "b", -1, -0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "figS8.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "figS8.png"), Resolution=600);
