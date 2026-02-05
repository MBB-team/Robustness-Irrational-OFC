function [is_initial_training] = checkIfIsInitialTraining(folder_name, fit_label)
% Determines whether a given fit label corresponds to the initial training
% phase of an RNN stored in a specific folder.
%
% This function encodes the convention linking folder names to the name of
% the 'Network' sub-structure used to store results from the initial
% training of RNNs in that folder. It returns true if the provided
% fit label matches the expected initial-training label for the given
% folder, and false otherwise.
%
% INPUTS ------------------------------------------------------------------
% folder_name : <string 1x1>
%     Name of the folder in which the RNN is stored (e.g., rational,
%     rational_subj, or irrational_*).
%
% fit_label : <string 1xN>
%     Name of the 'Network' sub-structures which are being checked.
%
% OUTPUTS -----------------------------------------------------------------
% is_initial_training : <bool 1xN>
%     True if the specified sub-structure corresponds to the initial
%     training of RNNs in the given folder; false otherwise.

arguments
    folder_name (1, 1) string
    fit_label (1, :) string
end

is_initial_training = ...
    (folder_name == "rational" & fit_label == "FitRational") | ...
    (folder_name == "rational_subj" & contains(fit_label, "RationalSubj")) | ...
    (folder_name == "irrational_Franck" & fit_label == "FitIrrationalFranck") | ...
    (folder_name == "irrational_Miles" & fit_label == "FitIrrationalMiles");