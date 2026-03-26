
%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

Data = loadMeasureResults([...
        "config_ID", "is_rational", "is_irrational", ...
        "prop_optimal_noise"], "rational_last");


%% === Generate figure ====================================================

close all;

% Initialize the figure
f = figure(...
    Name = "Figure S9: comparing the tolerance to neural noise in rational and irrational RNNs", ...
    Units = "centimeters", ...
    Position = [0, 0, 9, 7.5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 1, 1, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[1, 1, 7.5, 5]);

% Subplots
plotRobustnessToNeuralNoiseTrajectoryPerFit(nexttile(1, [1, 1]), Data);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "figS9.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "figS9.png"), Resolution=600);
