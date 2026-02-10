function [] = setup()
% SETUP() adds all the necessary folders to MATLAB's path.

% Add folders to the path
root = pwd;
addpath(genpath(root));

% Check toolboxes
requiredToolboxes = {'Statistics and Machine Learning Toolbox','Parallel Computing Toolbox'};
installedToolboxes = ver;
installedToolboxes = {installedToolboxes.Name};
missingToolboxes = setdiff(requiredToolboxes, installedToolboxes);
if ~isempty(missingToolboxes)
    warning("Missing toolboxes: %s", strjoin(missingToolboxes, ", "));
end

% Display validation
disp("Setup complete.")
