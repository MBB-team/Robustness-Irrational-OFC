function outputPath = getPath(pathName)
% Stores and returns any path needed to execute the scripts.
%
%% INPUTS
%  ======
%
% Mandatory:
% ----------
% - pathName [string]
%       Target of the desired path.
%
%% OUTPUTS
%  =======
%
% - outputPath [string]
%       Path to the desired target.


% Get the path to the project folder
rootPath = pwd;

% Select the list of sub-directories to reach the target directory
if nargin == 1
    switch pathName
        case "ModelsRaw"
            listFolder = ["data", "raw", "models"];
        case "Models"
            listFolder = ["data", "processed", "models"];
        case "MonkeyRawData"
            listFolder = ["data", "raw", "monkeys"];
        case "MonkeyData"
            listFolder = ["data", "processed", "monkeys"];
        case "VBA_toolbox"
            listFolder = ["utils", "VBA_dep"];
        case "Figures"
            listFolder = ["results", "figures"];
        otherwise
            error("Unknown path name.");
    end
end

% Create necessary sub-directories if they don't exist
outputPath = rootPath;
for folder = listFolder
    outputPath = fullfile(outputPath, folder);
    if ~isfolder(outputPath)
        mkdir(outputPath)
    end
end

end
