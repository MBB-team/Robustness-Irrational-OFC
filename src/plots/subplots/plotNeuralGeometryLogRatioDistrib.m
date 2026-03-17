function [] = plotNeuralGeometryLogRatioDistrib(ax, NeuralGeometry, distance, plot_options)
% Code for figure S4.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
%
% MonkeyData : <struct 1x1>
%     Structure containing monkey neural geometry matrices. See also:
%     computeMonkeyNeuralGeometry.
%
% distance : <string 1x1>
%     Type of neural distance considered (either "RDM" or "CCM").
%
% line_width, monkey_line_style, marker_size :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    NeuralGeometry (1, 1) struct
    distance (1, 1) string {mustBeMember(distance, ["RDM", "CCM"])}
    plot_options.rng_seed (1, 1) double = 1
    plot_options.n_simu (1, 1) double = 1e4
    plot_options.line_width (1, 1) double = 0.7
    plot_options.distrib_color (1, 3) double = [0, 0, 0]
    plot_options.distrib_alpha (1, 1) double = 0.2
    plot_options.data_color (1, 3) double = hex2rgb("#DC267F")
    plot_options.title (1, 1) string = ""

end

hold(ax, "on");

% Vectorize the neural geometry matrix
for area = ["OFC", "dlPFC", "ACC"]
    for monkey = ["Franck", "Miles"]
        if distance == "RDM"
            NeuralGeometry.(area).(monkey).RDM = NeuralGeometry.(area).(monkey).RDM(:);
        elseif distance == "CCM"
            NeuralGeometry.(area).(monkey).CCM = [...
                NeuralGeometry.(area).(monkey).CCM_option(:) ; ...
                NeuralGeometry.(area).(monkey).CCM_attribute(:)];
        end
    end
end

% Compute the log-ratio in the data
ElogRatio_data = computeExpectedLogRatio(...
    NeuralGeometry.OFC.Franck.(distance), ...
    NeuralGeometry.OFC.Miles.(distance), ...
    NeuralGeometry.dlPFC.Franck.(distance), ...
    NeuralGeometry.dlPFC.Miles.(distance), ...
    NeuralGeometry.ACC.Franck.(distance), ...
    NeuralGeometry.ACC.Miles.(distance));

% --- Simulate the log-ratio distribution under the null --- %

% Set seed for reproducibility
rng(plot_options.rng_seed);

ElogRatio_H0 = NaN(plot_options.n_simu, 1);
all_matrices_Franck = [...
    NeuralGeometry.OFC.Franck.(distance), ...
    NeuralGeometry.dlPFC.Franck.(distance), ...
    NeuralGeometry.ACC.Franck.(distance)];
all_matrices_Miles = [...
    NeuralGeometry.OFC.Miles.(distance), ...
    NeuralGeometry.dlPFC.Miles.(distance), ...
    NeuralGeometry.ACC.Miles.(distance)];
n_cells = size(all_matrices_Franck, 1);

for i_simu = 1:plot_options.n_simu

    % Randomly shuffle areas across cells, within monkeys
    all_matrices_Franck_shuffled = NaN(n_cells, 3);
    all_matrices_Miles_shuffled = NaN(n_cells, 3);
    for i_cell = 1:n_cells
        all_matrices_Franck_shuffled(i_cell, :) = all_matrices_Franck(i_cell, randperm(3));
        all_matrices_Miles_shuffled(i_cell, :) = all_matrices_Miles(i_cell, randperm(3));
    end

    % Randomly shuffle matrices across monkeys
    all_matrices_shuffled = NaN(n_cells, 6);
    for i_area = 1:3
        if rand > 0.5
            all_matrices_shuffled(:, (i_area - 1) * 2 + 1) = all_matrices_Franck_shuffled(:, i_area);
            all_matrices_shuffled(:, (i_area - 1) * 2 + 2) = all_matrices_Miles_shuffled(:, i_area);
        else
            all_matrices_shuffled(:, (i_area - 1) * 2 + 1) = all_matrices_Miles_shuffled(:, i_area);
            all_matrices_shuffled(:, (i_area - 1) * 2 + 2) = all_matrices_Franck_shuffled(:, i_area);
        end
    end

    % Compute the log-ratio
    ElogRatio_H0(i_simu) = computeExpectedLogRatio(...
        all_matrices_shuffled(:, 1), all_matrices_shuffled(:, 2), ...
        all_matrices_shuffled(:, 3), all_matrices_shuffled(:, 4), ...
        all_matrices_shuffled(:, 5), all_matrices_shuffled(:, 6));
end

% --- Plot --- %
 
% H0 distribution
[pdf_logratio, eval_logratio] = kde(ElogRatio_H0);
fill(ax, [eval_logratio, fliplr(eval_logratio)], [pdf_logratio, zeros(size(pdf_logratio))], "k", ...
    EdgeColor="none", ...
    FaceColor=plot_options.distrib_color, ...
    FaceAlpha=plot_options.distrib_alpha);

% Actual data
xline(ax, ElogRatio_data, ...
    Color=plot_options.data_color, ...
    LineWidth=plot_options.line_width);

% Aesthetics
xlim(ax, [0, 1.2]);
xlabel(ax, "log(Var[areas/monkeys])");
ylabel(ax, "PDF under H0")
if plot_options.title ~= ""
    title(plot_options.title);
end
setAxFontSize(ax);

% --- Stats --- %

p_value = mean(ElogRatio_H0 >= ElogRatio_data);
fprintf("P-value: %0.2e\n", p_value);

hold(ax, "off");

end


% === Auxiliary function === %

function ElogRatio = computeExpectedLogRatio(...
    OFC_Franck, OFC_Miles, dlPFC_Franck, dlPFC_Miles, ACC_Franck, ACC_Miles)
% Local function computing the logarithm of the ratio of (expected)
% variance in neural geometry matrix cells across areas vs. across monkeys.

arguments
    OFC_Franck (:, 1) double
    OFC_Miles (:, 1) double
    dlPFC_Franck (:, 1) double
    dlPFC_Miles (:, 1) double
    ACC_Franck (:, 1) double
    ACC_Miles (:, 1) double
end

% Average neural geometry matrices across monkeys or across areas
OFC = (OFC_Franck + OFC_Miles) / 2;
dlPFC = (dlPFC_Franck + dlPFC_Miles) / 2;
ACC = (ACC_Franck + ACC_Miles) / 2;
Franck = (OFC_Franck + dlPFC_Franck + ACC_Franck) / 3;
Miles = (OFC_Miles + dlPFC_Miles + ACC_Miles) / 3;

% Compute the average variance across cells
var_inter_areas = mean(var([OFC, dlPFC, ACC], [], 2));
var_inter_monkeys = mean(var([Franck, Miles], [], 2));

% Compute the log ratio
ElogRatio = log(var_inter_areas) - log(var_inter_monkeys);

end