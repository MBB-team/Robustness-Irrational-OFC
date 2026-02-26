% Convert old gathered RNN data files for RNNs trained rationally with
% constraints into the new format.

clear variables;

%% Load old data

AllNetworksOld = load(fullfile("C:", "Users", "jbenon", "Documents", ...
    "Hunt2018_ANN", "Data", "Models", "Sig_100_constraints_new", ...
    "_AllNetworksLast.mat"));

%% Create new data format

old_constraint_labels = ["CodeEfficiency", "FiringRate", "Robustness"];
new_constraint_labels = ["info_transfer_rate", "energetic_budget_avg", "prop_optimal_impaired_units"];

shared_fields = ["input_label", "output_label", "output_format_label", ...
    "seed", "fit_step", "params", ...
    "constraint_weight", ...
    "fit_train", "fit_test"];

all_Config = getDesiredNetworkConfigs();

for i_constraint = 1:length(old_constraint_labels)

    % Select data for this constraint
    old_constraint = old_constraint_labels(i_constraint);
    select_old = AllNetworksOld.constraint_label == old_constraint;
    i_select_old = find(select_old);
    n_select_old = sum(select_old);

    % Prepare file save
    new_constraint = new_constraint_labels(i_constraint);

    % Fill the new structure with similar info from the old one
    AllNetworks = struct();
    for field = shared_fields
        if size(AllNetworksOld.(field), 1) == 1
            AllNetworks.(field) = AllNetworksOld.(field)(select_old);
        else
            AllNetworks.(field) = AllNetworksOld.(field)(:, select_old);
        end
    end

    % --- Handle different fields --- %

    % Constraint label
    AllNetworks.constraint_label = strings(1, n_select_old);
    AllNetworks.constraint_label(:) = new_constraint;
    % Config ID
    AllNetworks.config_ID = NaN(1, n_select_old);
    for i_select = 1:n_select_old
        Config = AllNetworksOld.Config{i_select_old(i_select)};
        AllNetworks.config_ID(i_select) = find(cellfun(@(x) isequaln(x, Config), all_Config));
    end

    % Folder name
    AllNetworks.folder_name = strings(1, n_select_old);
    AllNetworks.folder_name(:) = "rational_" + new_constraint;

    % Fit label
    AllNetworks.fit_label = strings(1, n_select_old);
    AllNetworks.fit_label(:) = "FitRationalConstrained";
    AllNetworks.fit_label(AllNetworks.fit_step == 1) = "Priors";

    % Is initial/rational/irrational/
    AllNetworks.is_initial_fit = true(1, n_select_old);
    AllNetworks.is_rational = true(1, n_select_old);
    AllNetworks.is_irrational = false(1, n_select_old);


    % --- Save --- %

    save(fullfile(getPath("Models"), "rational_" + new_constraint + "_last.mat"), "-struct", "AllNetworks");

    disp("Saved " + new_constraint);
end