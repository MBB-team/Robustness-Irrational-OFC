% Updates the suffStat structure in order to store information throughout
% the fitting of the ANN, adding the information computed with the new
% posterior.

function suffStat = updateSuffStatHistory(suffStat, posterior, options)
% Parameters
% ----------
% suffStat: structure
%   .params_history: [n_params x n_fit] double
%   Matrix storing the parameters of the ANN at each fitting iteration
%   after the initialization.
% posterior: structure
%   .muPhi: [n_params x 1] double
%       First-order estimates of the ANN's parameters.
% options: structure
%   .store_history: bool
%       Whether to update and store the history information throughout the
%       fitting iterations.
%
% Outputs
% ------
% suffStat: structure
%   .params_history: [n_params x n_fit] double
%   Matrix storing the parameters of the ANN at each fitting iteration
%   after the initialization.


% Only update if the model states to store updates
if isfield(options, 'store_history') && options.store_history

    % Estimated parameters of the model
    new_parameters = posterior.muPhi;
    try
        suffStat.params_history = [...
            suffStat.params_history, new_parameters];
    catch
        suffStat.params_history = new_parameters;
    end
end

end
