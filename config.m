function Config = config()
% Returns global configuration parameters stored in a structure.

Config = struct();

% Global rng seed
Config.rngSeed = 0;

% Parameters for model training
Config.nModelsPerCohort = 1000;
Config.nTrialsTrainRational = 500;
Config.nTrialsTestRational = 500;
Config.nTrialsTrainIrrational = 2000;
Config.nTrialsTestIrrational = 2000;
Config.initModelParamVariance = 0.05;
Config.initModelParamMean = 0;

end