% Fig. S4 | Comparison of RDM and CCM variance over brain regions and over
% subjects.
% 
% Grey areas depict the distribution, under the null, of the log ratio of
% RDM (left) and CCM (right) variance over regions and monkeys. Pink lines
% show the log ratio of variances in the actual data.


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

NeuralGeometry = load(fullfile(getPath("MonkeyData"), "NeuralGeometry.mat"));


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure S4: Comparison of RDM and CCM variance over brain regions and over subjects", ...
    Units = "centimeters", ...
    Position = [0, 0, 9, 5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 1, 2, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[0.7, 1, 8.2, 3.5]);

% Subplots
plotNeuralGeometryLogRatioDistrib(nexttile(1, [1, 1]), NeuralGeometry, "RDM", ...
    title="RDMs");
plotNeuralGeometryLogRatioDistrib(nexttile(2, [1, 1]), NeuralGeometry, "CCM", ...
    title="CCMs");

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

saveas(f, fullfile(getPath("Figures"), "figS4.pdf"));
exportgraphics(f, fullfile(getPath("Figures"), "figS4.png"), Resolution=600);
