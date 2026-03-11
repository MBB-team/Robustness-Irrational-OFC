% Fig. M1 | Derivation of CCM statistics in OFC neurons.
%
%   - a, First, we regress the mean firing rate of each neuron at each cue
% onset against the rank of all previously attended cues (across trials).
% Here, we show the apparent statistical relationship between the activity
% X_2^U (∙,t) of one example OFC neuron sampled at time t=2 (y-axis),
% plotted against the rank U_1 (k) of the first presented cue (k=1).
% 
%   - b, Second, we measure the correlation (across neurons), between the
% ensuing regression coefficients for different activity sampling and cue
% presentation times. Here, we plot the sensitivity β ̃_k (t) of OFC neurons
% (one dot is one neuron) sampled at time t=2 to the first cue (k=1,
% y-axis) against their sensitivity to the second cue (k=2 , x-axis).
% 
%   - c, Each cell in the CCM matrix shows the correlation across neurons
% for a given pair of regression coefficients (neurons pooled across
% monkeys). The upper half of the matrix shows the results computed on
% option trials (where the two first cues characterize the same option),
% while the lower half corresponds to attribute trials (where the two first
% cues characterize the same attribute, but different options). Asterisks
% indicate significant correlations, with p-value < 0.0007 (correction for
% multiple comparisons across CCM cells).


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

UnitRecordings = load(fullfile(getPath("MonkeyData"), "UnitRecordings.mat"));
NeuralGeometry = load(fullfile(getPath("MonkeyData"), "NeuralGeometry.mat"));


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure M1: derivation of CCM statistics in OFC neurons", ...
    Units = "centimeters", ...
    Position = [0, 0, 9, 11], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 3, 2, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[1, 0.9, 5.8, 9.8]);

% Subplots
plotRegressionAcrossUnits(nexttile(1, [1, 1]), UnitRecordings);
plotCorrelationAcrossRegressionCoefficients(nexttile(2, [1, 1]), NeuralGeometry.OFC.both.tstats_option);
plotCCM(nexttile(3, [2, 2]), NeuralGeometry.OFC.both.CCM_option, NeuralGeometry.OFC.both.CCM_attribute, ...
    NeuralGeometry.OFC.both.CCM_option_p, NeuralGeometry.OFC.both.CCM_attribute_p);

% Colorbar
ax_bottom = nexttile(3, [2, 2]);
ax_bottom.Units = "centimeters";
cb_position = [...
    ax_bottom.Position(1) + ax_bottom.Position(3) + 1.2, ...
    ax_bottom.Position(2) - 0.55, ...
    0.4, ...
    ax_bottom.Position(4)];
cb = colorbar(...
    nexttile(3, [2, 2]), ...
    Units="centimeters", ...
    Position=cb_position, ...
    Ticks=[-1, 0, 1], ...
    FontName="Arial", ...
    FontSize=8);
cb.Label.String = "Correlation";
cb.Label.FontSize = 8;
cb.Label.FontName = "Arial";
cb.Label.Position(1) = cb.Label.Position(1) - 0.5;

% Subplot letters
writePanelLetter(nexttile(1, [1, 1]), "a", -0.4, -0.1);
writePanelLetter(nexttile(2, [1, 1]), "b", -0.4, -0.1);
writePanelLetter(nexttile(3, [2, 2]), "c", -0.4, -0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "figM1.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "figM1.png"), Resolution=600);
