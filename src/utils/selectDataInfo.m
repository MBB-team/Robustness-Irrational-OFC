% Selects some fields of a 'DataSamples' structure.

function info = selectDataInfo(DataSamples, info_labels)
% --- INPUT ---
% DataSamples: structure
%   This structure contains relevant information regarding the sampling
%   scenarii of a session.
% info_labels: [1 x n_info] string
%   String array containing the name of the fields to select in
%   'DataSamples'. All fields must designate double arrays in the
%   structure.
%
% --- OUTPUT ---
% info: [n_samples x n_info] double
%   Matrix selected from the 'DataSamples' structure.
%
% --- CALLED BY ---
% trainNetworkCohorts
% checkInformationLoss
% simulateNetworkCohortsH0
% fitNetworkToBehaviour
% computeNeuralRepresentation
% computeLogLikelihoodDynamics


% Initialize the output
n_samples = length(DataSamples.i_trial);
n_info = length(info_labels);
info = NaN(n_samples, n_info);

% Select the fields
for i_info = 1:n_info
    try
        info(:, i_info) = DataSamples.(info_labels(i_info));
    catch
        warning("Impossible to select the field %s in DataSamples.", ...
            info_labels(i_info));
    end

end

end
