% Convert robustness data for RNNs trained rationally and
% then re-trained into the new format.


%% Load old data

clear variables;

labels_robustness = [compose("opt_choice_impair_%d", 1:10), ...
    compose("modif_choice_impair_%d", 1:9)];

AllNetworksOld = load(fullfile("C:", "Users", "jbenon", "Documents", ...
    "Hunt2018_ANN", "Data", "Models", "Sig_1000", "_AllNetworksLast.mat"), ...
    "input_label", "output_label", "output_format_label", ...
    "fit_label", "fit_step", "seed", ...
    labels_robustness{:});

AllNetworksNew = loadMeasureResults(["input_label", "output_label", "output_format_label", ...
    "fit_label", "fit_step", "seed"], "rational_last");


%% Create new data format

all_new_fit_labels = ["Priors", "FitRational", ...
    "FitRationalSubjFranck", "FitRationalSubjMiles", ...
    "FitIrrationalFranck", "FitIrrationalMiles"];

all_old_fit_labels = ["Priors", "FitOptimal",...
    "FitOptimalToRationalFranck", "FitOptimalToRationalMiles", ...
    "FitOptimalToIrrationalFranck", "FitOptimalToIrrationalMiles"];

% Initialize new robustness field
n_data_new = length(AllNetworksNew.seed);
AllNetworksNew.prop_optimal_impaired_units = NaN(10, n_data_new);
AllNetworksNew.avg_prop_optimal_impaired_units = NaN(1, n_data_new);
AllNetworksNew.prop_consistent_impaired_units = NaN(10, n_data_new);
AllNetworksNew.avg_prop_consistent_impaired_units = NaN(1, n_data_new);

for input_label = ["loc", "order"]
    for output_label = ["loc", "order", "attention"]
        for output_format_label = ["diff", "both"]

            % Select cohorts in the old and new dataset
            select_cohort_old = ...
                AllNetworksOld.input_label == input_label & ...
                AllNetworksOld.output_label == output_label & ...
                AllNetworksOld.output_format_label == output_format_label;
            select_cohort_new = ...
                AllNetworksNew.input_label == input_label & ...
                AllNetworksNew.output_label == output_label & ...
                AllNetworksNew.output_format_label == output_format_label;

            % Identify unique networks within each cohort
            all_seeds_old = unique(AllNetworksOld.seed(select_cohort_old));
            all_seeds_new = unique(AllNetworksNew.seed(select_cohort_new));

            for seed = all_seeds_old

                % Select unique network in the old and new dataset
                select_network_old = select_cohort_old & ...
                    AllNetworksOld.seed == seed;
                select_network_new = select_cohort_new & ...
                    AllNetworksNew.seed == seed;

                for i_fit = 1:length(all_new_fit_labels)

                    % Select network at this fit stage in the old and new
                    % dataset
                    select_fit_old = select_network_old & ...
                        AllNetworksOld.fit_label == all_old_fit_labels(i_fit);
                    select_fit_new = select_network_new & ...
                        AllNetworksNew.fit_label == all_new_fit_labels(i_fit);

                    % Save the data
                    for i_lesioned = 1:10
                        AllNetworksNew.prop_optimal_impaired_units(i_lesioned, select_fit_new) = ...
                            mean(AllNetworksOld.("opt_choice_impair_" + i_lesioned)(:, select_fit_old));
                        if i_lesioned < 10
                            AllNetworksNew.prop_consistent_impaired_units(i_lesioned, select_fit_new) = ...
                                mean(AllNetworksOld.("modif_choice_impair_" + i_lesioned)(:, select_fit_old));
                        end
                    end
                    AllNetworksNew.avg_prop_optimal_impaired_units(select_fit_new) = ...
                        mean(AllNetworksNew.prop_optimal_impaired_units(1:5, select_fit_new));
                    AllNetworksNew.avg_prop_consistent_impaired_units(select_fit_new) = ...
                        mean(AllNetworksNew.prop_consistent_impaired_units(1:5, select_fit_new));
                end
            end
        end
    end
end

save(fullfile(getPath("Models"), "rational_last.mat"), "-struct", "AllNetworksNew", "-append");
