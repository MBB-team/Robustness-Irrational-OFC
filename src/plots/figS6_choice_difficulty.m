% Fig. S6 | Choice difficulty as a function of choice onset time. Average
% choice ease, as measured in terms of the absolute value difference
% between options (where option values are derived from each monkey's
% estimated value profile), is plotted against choice onset time, for both
% option (light) and attribute (dark) trials. Red and blue colors indicate
% monkeys (red: monkey F, blue: monkey M).


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

ChoiceDifficulty = load(fullfile(getPath("MonkeyData"), "ChoiceDifficulty.mat"));


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure S6: choice difficulty as a function of choice onset time", ...
    Units = "centimeters", ...
    Position = [0, 0, 6, 5.5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 1, 1, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[1, 1, 4, 3]);

% Subplots
plotMonkeyChoiceDifficulty(nexttile(1, [1, 1]), ChoiceDifficulty);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "figS6.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "figS6.png"), Resolution=600);
