function [] = setup()
% SETUP() adds all the necessary folders to MATLAB's path.

% Add folders to the path
root = fileparts(pwd);
addpath(genpath(root));

% Check toolboxes
requiredToolboxes = {'Statistics and Machine Learning Toolbox','Deep Learning Toolbox'};
installedToolboxes = ver;
installedToolboxes = {installedToolboxes.Name};
missingToolboxes = setdiff(requiredToolboxes, installedToolboxes);
if ~isempty(installedToolboxes)
    warning("Missing toolboxes: %s", strjoin(installedToolboxes, ", "));
end

% Display validation
disp("Setup complete.")
