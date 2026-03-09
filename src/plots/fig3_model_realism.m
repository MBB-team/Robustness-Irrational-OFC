% Fig. 3 | Behavioral and neural realism of candidate RNN models of the
% OFC.
%
%   - a/b, Estimated option values for monkey F(a) and M(b) are shown as a
% function of reward’s magnitude rank (x-axis) and probability rank
% (y-axis).
%
%   - c, Rational options values are defined as the expected reward, i.e.
% the product of reward magnitude and probability. Note that when an
% attribute is unknown (cf. question mark), the rational model replaces it
% with its mean.
%  
%   - d, Monkeys’ estimated values (y-axis) are plotted against rational
% values (x-axis). Each point represents a specific combination of
% probability and magnitude ranks, including cases where one or both
% attributes are unknown.
% 
%   - e, Balanced accuracy for predicting monkey choices. Each color
% corresponds to one of the two candidate models (blue: value synthesis,
% orange: value comparison). Lighter distributions correspond to rational
% models, darker distributions to irrational models, and distributions with
% a dashed outline represent irrational models trained on one monkey and
% tested on the other. Within each violin plot, the horizontal line denotes
% the mean, and the thicker vertical line represents the interquartile
% range (25th – 75th percentile). Asterisks indicate significant
% differences, with p-value < 0.005.
% 
%   - f, Neural CCM distance between models and the OFC. The white
% distribution corresponds to random RNN initializations (identical for
% both RNN cohorts). g, Neural CCM distance between irrational models and
% the OFC, the dlPFC and the ACC. h, Proportion of units classified as
% offer value, chosen value or chosen option cells, in RNNs models and in
% recorded OFC neurons (black dotted lines), at the time of choice.
%
%   - g, Neural CCM distance between irrational models and the OFC, the
% dlPFC and the ACC. h, Proportion of units classified as offer value,
% chosen value or chosen option cells, in RNNs models and in recorded OFC
% neurons (black dotted lines), at the time of choice.


%% === Environment set-up =================================================

setup;
clear variables;
close all;


%% === Load data ==========================================================

Data = loadMeasureResults([...
    "config_ID", "fit_label", "is_rational", "is_irrational", ...
    "value_function", ...
    "dist_CCM_avg_OFC", "dist_CCM_same_OFC", "dist_CCM_other_OFC", ...
    "dist_CCM_avg_ACC", "dist_CCM_avg_dlPFC", ...
    "bacc_Franck", "bacc_Miles", "bacc_same_monkey", "bacc_other_monkey", ...
    "prop_offer1_Franck", "prop_offer1_Miles", "prop_offer2_Franck", "prop_offer2_Miles", ...
    "prop_chosen_value_Franck", "prop_chosen_value_Miles", ...
    "prop_chosen_offer_Franck", "prop_chosen_offer_Miles", ...
    "prop_none_Franck", "prop_none_Miles"], ...
    "rational_last");

MonkeyData = load(fullfile(getPath("MonkeyData"), "ValueProfile.mat"));


%% === Generate figure ====================================================

% Initialize the figure
f = figure(...
    Name = "Figure 3: behavioral and neural realism of candidate RNN models of the OFC", ...
    Units = "centimeters", ...
    Position = [0, 0, 18, 13], ...
    NumberTitle="off", ...
    Color = "w");
movegui(f, "center");

% Define the layout
t = tiledlayout(f, 3, 4, ...
    TileSpacing="loose", ...
    Units="centimeters", ...
    Position=[2, 1, 15.8, 11.5]);

% Subplots
plotValueProfile(nexttile(1, [1, 1]), MonkeyData.Franck.value_function, ...
    sprintf("Monkey F \\color[rgb]{%f, %f, %f}●", defineMonkeyColor("Franck")));
plotValueProfile(nexttile(2, [1, 1]), MonkeyData.Miles.value_function, ...
    sprintf("Monkey M \\color[rgb]{%f, %f, %f}▲", defineMonkeyColor("Miles")));
plotValueProfile(nexttile(5, [1, 1]), mean(Data.value_function(:, Data.is_rational), 2), "Rational model");
plotValueProfileComparison(nexttile(6, [1, 1]), Data, MonkeyData);
plotMonkeyBaccDistribPerFit(nexttile(9, [1, 2]), Data);
plotCCMdistanceDistribPerFit(nexttile(3, [1, 2]), Data);
plotCCMdistanceDistribPerArea(nexttile(7, [1, 2]), Data);
plotIntegrationUnitsCategory(nexttile(11, [1, 2]), Data);

% Colorbar
ax_top_left = nexttile(1, [1, 1]);
ax_middle_left = nexttile(5, [1, 1]);
cbar = colorbar(ax_top_left);
cbar.Position = [...
    ax_top_left.Position(1) - 0.083, ...
    ax_middle_left.Position(2) - 0.045, ...
    cbar.Position(3), ...
    ax_top_left.Position(2) + ax_top_left.Position(4) - ax_middle_left.Position(2) + 0.115];
cbar.Label.String = "Value (a.u.)";
cbar.Label.Position(1) = cbar.Label.Position(1) + 1;
cbar.Ticks = [min(MonkeyData.Franck.value_function, [],  "all"), ...
    max(MonkeyData.Franck.value_function, [], "all")];
cbar.TickLabels = ["min", "max"];
fontsize(cbar, 8, "points");

% Subplot letters
writePanelLetter(nexttile(1, [1, 1]), "a", -0.4, -0.1);
writePanelLetter(nexttile(2, [1, 1]), "b", -0.4, -0.1);
writePanelLetter(nexttile(5, [1, 1]), "c", -0.4, -0.1);
writePanelLetter(nexttile(6, [1, 1]), "d", -0.7, -0.1);
writePanelLetter(nexttile(9, [1, 2]), "e", -0.5, -0.1);
writePanelLetter(nexttile(3, [1, 2]), "f", -0.6, -0.1);
writePanelLetter(nexttile(7, [1, 2]), "g", -0.6, -0.1);
writePanelLetter(nexttile(11, [1, 2]), "h", -0.6, -0.1);

% Set font globally
fontname(f, "arial");


%% === Save figure ========================================================

exportgraphics(f, fullfile(getPath("Figures"), "fig3.pdf"), ContentType="vector");
exportgraphics(f, fullfile(getPath("Figures"), "fig3.png"), Resolution=600);
