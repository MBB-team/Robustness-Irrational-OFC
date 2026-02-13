% Convert old RNN data files into the new file format.

clear variables;

% Identify paths to all old data files
folder_old_networks = fullfile("C:", "Users", "jbenon", "OneDrive - Universität Zürich UZH", ...
    "Code projects", "Hunt2018_ANN", "Data", "Models", "Sig_1000");
path_old_networks = getAllNetworkPaths(folder_old_networks);
n_old_networks = length(path_old_networks);

for i_network = 1:n_old_networks

    try
        OldNetwork = load(path_old_networks(i_network)).Network;
    catch
        warning("Unable to load %s", path_old_networks(i_network));
        continue;
    end

    [~, old_file_name] = fileparts(path_old_networks(i_network));

    % Identify fit phases
    all_old_fit_labels = string(fieldnames(OldNetwork))';
    all_old_fit_labels = all_old_fit_labels(startsWith(all_old_fit_labels, "Fit"));
    n_old_fit_labels = length(all_old_fit_labels);

    % Identify where to store each fit info
    all_fit_labels = strings(1, n_old_fit_labels);
    all_folder_names = strings(1, n_old_fit_labels);

    for i_fit_label = 1:n_old_fit_labels

        % Match old fit labels to new ones
        switch all_old_fit_labels(i_fit_label)
            case "FitOptimal"
                all_fit_labels(i_fit_label) = "FitRational";
                all_folder_names(i_fit_label) = "rational";

            case "FitOptimalToRationalFranck"
                all_fit_labels(i_fit_label) = "FitRationalSubjFranck";
                all_folder_names(i_fit_label) = "rational";

            case "FitOptimalToRationalMiles"
                all_fit_labels(i_fit_label) = "FitRationalSubjMiles";
                all_folder_names(i_fit_label) = "rational";

            case "FitOptimalToIrrationalFranck"
                all_fit_labels(i_fit_label) = "FitIrrationalFranck";
                all_folder_names(i_fit_label) = "rational";

            case "FitOptimalToIrrationalMiles"
                all_fit_labels(i_fit_label) = "FitIrrationalMiles";
                all_folder_names(i_fit_label) = "rational";
            
            case "FitIrrationalFranck"
                all_fit_labels(i_fit_label) = "FitIrrationalFranck";
                all_folder_names(i_fit_label) = "irrational_Franck";
            
            case "FitIrrationalMiles"
                all_fit_labels(i_fit_label) = "FitIrrationalMiles";
                all_folder_names(i_fit_label) = "irrational_Miles";
            
            case "FitIrrationalFranckToOptimal"
                all_fit_labels(i_fit_label) = "FitRational";
                all_folder_names(i_fit_label) = "irrational_Franck";
            
            case "FitIrrationalMilesToOptimal"
                all_fit_labels(i_fit_label) = "FitRational";
                all_folder_names(i_fit_label) = "irrational_Miles";

            % Do not save data for the second distortion training

            case "FitRationalToIrrationalFranck"

            case "FitRationalToIrrationalMiles"

            otherwise
                fprintf("\n==== %s ===== \n", old_file_name);
        end
    end

    % Create one network structure per folder where to save it
    unique_folder_names = unique(all_folder_names);
    unique_folder_names(unique_folder_names == "") = [];
    n_new_network = length(unique_folder_names);

    for i_new_network = 1:n_new_network

        % Initialize new network
        Network = struct();
        
        % Network general info
        Network.Config = OldNetwork.Config;
        Network.seed = OldNetwork.FitOptimal.seed;

        % Select fit info for this data file
        i_select_fit_label = find(all_folder_names == unique_folder_names(i_new_network));

        % Create new sub-structures
        for i_fit_label = i_select_fit_label

            old_fit_label = all_old_fit_labels(i_fit_label);
            fit_label = all_fit_labels(i_fit_label);

            Network.(fit_label) = struct();
            Network.(fit_label).params = OldNetwork.(old_fit_label).params;
            Network.(fit_label).fit_train = OldNetwork.(old_fit_label).fit_train;
            if isfield(OldNetwork.(old_fit_label), "fit_test")
                Network.(fit_label).fit_test = OldNetwork.(old_fit_label).fit_test;
            else
                Network.(fit_label).fit_test = NaN(size(OldNetwork.(old_fit_label).fit_train));
                % warning("no fit test: %s %s", old_fit_label, old_file_name);
            end
            Network.(fit_label).i_end_GnLoop = OldNetwork.(old_fit_label).i_end_GnLoop;

        end

        % Save the new network
        path_network = fullfile(getPath("ModelsRaw"), unique_folder_names(i_new_network));
        filename = defineFilenamePattern(Network.Config, Network.seed);

        save(fullfile(path_network, filename), "-struct", "Network");        
    end

    if mod(i_network, 100) == 0
        fprintf("%d / %d\n", i_network, n_old_networks);
    end
end