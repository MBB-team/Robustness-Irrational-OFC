function [] = saveDistortTrainingNetwork(Network, fit_label, ...
    params, fit_train, fit_test, out, path_network)
% Saves the results of RNN re-training under distorted conditions.
%
% This function appends a new substructure to an existing RNN structure,
% storing parameter trajectories, training and test performance, and
% convergence diagnostics obtained during re-training. The updated network
% is then saved.
%
% INPUTS ------------------------------------------------------------------
% Network : <struct 1x1>
%     Structure containing the RNN architecture, parameters, and previous
%     training results.
%
% fit_label : <string 1x1>
%     Label identifying the re-training condition under which the RNN was
%     optimized. This label is used as the name of the new field added to
%     the Network structure. See also: trainModelsDistortIrrational.
%
% params : <float PxT>
%     Trajectory of network parameters across training iterations.
%
% fit_train : <float TxR>
%     Prediction quality on the training dataset for each output dimension
%     (R), evaluated at each training iteration (T).
%
% fit_test : <float TxR>
%     Prediction quality on the test dataset for each output dimension (R),
%     evaluated at each training iteration (T).
%
% out : <struct 1x1>
%     Structure containing fitted model parameters, convergence statistics,
%     and training diagnostics. See also: VBA_NLStateSpaceModel.
%
% path_network : <string 1x1>
%     Path to the RNN file.

arguments
    Network (1, 1) struct
    fit_label (1, 1) string
    params (:, :) double
    fit_train (:, :) double
    fit_test (:, :) double
    out (1, 1) struct
    path_network (1, 1) string
end

% Store parameters, fit history, and convergence info
Network.(fit_label) = struct();
Network.(fit_label).params = params;
Network.(fit_label).fit_train = fit_train;
Network.(fit_label).fit_test = fit_test;
Network.(fit_label).i_end_GnLoop = out.suffStat.i_end_GnLoop;

% Save the RNN
if save_network
    save(path_network, "-struct", "Network");
end
