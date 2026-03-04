% Convert old RNN aggregated data files into the new file format.

clear variables;

% Identify paths to the old and new data file
path_old_data = fullfile("C:", "Users", "jbenon", "Documents", "Hunt2018_ANN", ...
    "Data", "Models", "Sig_1000", "_AllNetworksFullFitOptimal.mat");
OldData = load(path_old_data);
path_new_data = fullfile("C:", "Users", "jbenon", "Documents", "Bio_OFC_data_models", ...
    "processed", "rational_full.mat");
NewData = load(path_new_data);


%% Main

% Initialize storage of distance information
NewData.dist_RDM_avg_OFC = NaN(size(NewData.seed));
NewData.dist_CCM_avg_OFC = NaN(size(NewData.seed));

% Loop through network configs
for input_label = ["loc", "order"]
    for output_label = ["loc", "order", "attention"]
        for output_format_label = ["both", "diff"]

            select_old_config = ...
                OldData.input_label == input_label & ...
                OldData.output_label == output_label & ...
                OldData.output_format_label == output_format_label;
            select_new_config = ...
                NewData.input_label == input_label & ...
                NewData.output_label == output_label & ...
                NewData.output_format_label == output_format_label;

            % Loop through individual networks within this cohort
            old_seeds = unique(OldData.seed(select_old_config));

            for seed = old_seeds

                select_old_network = select_old_config & ...
                    OldData.seed == seed;
                select_new_network = select_new_config & ...
                    NewData.seed == seed;

                % Copy priors information
                select_old_priors = select_old_network & OldData.fit_label == "Priors";
                select_new_priors = select_new_network & NewData.fit_label == "Priors";
                NewData.dist_RDM_avg_OFC(select_new_priors) = OldData.dist_RDM(select_old_priors);
                NewData.dist_CCM_avg_OFC(select_new_priors) = OldData.dist_CCM(select_old_priors);

                % Copy rational fit information
                select_old_rational = select_old_network & OldData.fit_label == "FitOptimal";
                select_new_rational = select_new_network & NewData.fit_label == "FitRational";
                NewData.dist_RDM_avg_OFC(select_new_rational) = OldData.dist_RDM(select_old_rational);
                NewData.dist_CCM_avg_OFC(select_new_rational) = OldData.dist_CCM(select_old_rational);

            end

        end
    end
end

%% Save

save(path_new_data, "-struct", "NewData", "-append");