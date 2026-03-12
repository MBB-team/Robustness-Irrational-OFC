% Fig. S4 | Comparison of RDM and CCM variance over brain regions and over
% subjects. Black curves depict the distribution, under the null, of the
% log ratio of RDM (left) and CCM (right) variance over regions and
% monkeys. Red lines show the log ratio of variances in the actual data.


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

NeuralGeometry = load(fullfile(getPath("MonkeyData"), "NeuralGeometry.mat"));


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure S4: comparison of RDM and CCM variance over brain regions and over subjects", ...
    Units = "centimeters", ...
    Position = [0, 0, 9, 6], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 1, 2, ...
    TileSpacing="tight", ...
    Units="centimeters", ...
    Position=[2, 0.5, 16, 12.5]);

% Subplots


% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "figS4.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "figS4.png"), Resolution=600);
