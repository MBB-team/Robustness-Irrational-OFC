% Fig. 2 | Selection of candidate idealized RNN models of the OFCs.
%
%   - a, Schematic procedure for extracting within-trial activity patterns
% from OFC neural recordings and RNN models. At each trial, a sequence of
% decision-relevant cues is sampled by the monkey, until a choice is
% triggered. Within-trial activity patterns of OFC neurons are constructed
% as the average firing rate of each neuron, from 100 msec to 500 msec
% after each cue onset. Similarly, within-trial activity patterns of RNN
% models are the activation strengths of integration units in response to
% each cue.
% 
%   - b, Summary of neural distance metrics for comparing activity patterns
% of OFC neurons and RNN models. Representation Dissimilarity Matrices or
% RDMs quantify how dissimilar evoked activity patterns are for any pair of
% cue (2x2x5 = 20 possibilities at first cue onset). Cross-correlational
% matrices or CCMs quantify the similarity of profiles of neural
% sensitivity to present and past cues. Although CCM-based distance metrics
% are insensitive to cue type (probability or magnitude), they quantify
% potential internal memory traces about previously sampled cues. Full RDM
% and CCM summary statistics for all monkeys and brain regions can be
% eyeballed in the Supplementary Materials.
% 
%   - c, Neural distance trajectories between OFC and RNN cohorts during
% rational training. Points show the average distance between activity
% patterns of OFC recordings and RNN models (across the 1000 RNN
% instances), computed using either RDMs (x-axis) or CCMs (y-axis) metrics.
% Black crosses indicate the initial (random) state of RNN cohorts, black
% triangles/dots/diamonds denote their final rational state. Intermediary
% points show the neural distance at various stages of RNN training (from
% 0% to 100%, by steps of 2%), where color, line style and marker type
% indicate the type of computation (value synthesis vs value comparison),
% the identity format of the attended option (spatial vs temporal), and the
% value readout format (spatial vs temporal vs attentional), respectively.
% Only two RNN cohorts significantly improve in both neural distance
% metrics as rational training unfolds (grey area). 


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

Data = loadMeasureResults(["config_ID", "is_rational", "seed", "fit_step", "fit_label", ...
    "dist_RDM_avg_OFC", "dist_CCM_avg_OFC"], "rational_full");

%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure 2: selection of candidate idealized RNN models of the OFC", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 11.5], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 4, 4, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[0, 0.5, 16.5, 10]);

% Subplots
plotNeuralDistanceTrajectory(nexttile(3, [3, 2]), Data, false);

% Subplot letters
writePanelLetter(nexttile(3, [3, 2]), "c", -0.4, -0.1);

% Create additional inlay
ax_inlay = axes(f, Units="centimeters", Position=[9.8, 8, 3, 3]);
plotNeuralDistanceTrajectory(ax_inlay, Data, true);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "fig2.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "fig2.png"), Resolution=600);
