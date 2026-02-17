function output_path = getPath(path_name)
% Return the absolute path to a project directory.
%
% This utility function centralizes the definition of project paths
% (data, models, figures, external toolboxes, etc.) to ensure consistency
% across scripts and to simplify future changes in the project
% architecture. Missing directories along the requested path are created
% automatically.
%
% INPUTS ------------------------------------------------------------------
% path_name : <string 1x1>
%     Label identifying the target directory. Supported values include:
%       - "ModelsRaw"
%       - "Models"
%       - "MonkeyRawData"
%       - "MonkeyData"
%       - "VBA_toolbox"
%       - "Figures"
%
% OUTPUTS -----------------------------------------------------------------
% output_path : <string 1x1>
%     Absolute path to the requested directory.

arguments
    path_name (1, 1) string
end

% Get the root path of the project (current working directory)
root_path = pwd;

% Define the subdirectory sequence associated with each path label
switch path_name
    case "ModelsRaw"
        list_folder = ["data", "models", "raw"];
    case "Models"
        list_folder = ["data", "models", "processed"];
    case "MonkeyRawData"
        list_folder = ["data", "monkeys", "raw"];
    case "MonkeyData"
        list_folder = ["data", "monkeys", "processed"];
    case "VBA_toolbox"
        list_folder = ["utils", "VBA_dep"];
    case "Figures"
        list_folder = ["results", "figures"];
    otherwise
        error("Unknown path name.");
end

% Build the full path and create missing directories if needed
output_path = root_path;
for folder = list_folder
    output_path = fullfile(output_path, folder);
    if ~isfolder(output_path)
        mkdir(output_path)
    end
end
