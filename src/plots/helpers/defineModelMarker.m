function marker = defineModelMarker(config_ID)
% Returns the marker associated with each model configuration.
%
% INPUTS ------------------------------------------------------------------
% config_ID : <int 1xN>
%     Vector of configuration IDs identifying the models' Config 
%     structures.
%
% OUTPUTS -----------------------------------------------------------------
% marker : <string 1xN>
%     Marker associated with each configuration ID.

arguments
    config_ID (1, :) double
end

% Initialize output
marker = strings(1, length(config_ID));

% Loop over all possible config IDs
for i_config = 1:10
    switch i_config
        case 1
            % loc -> loc (both)
            config_marker = "^";
        case 2
            % loc -> loc (diff)
            config_marker = "^";
        case 3
            % loc -> order (both)
            config_marker = "o";
        case 4
            % loc -> order (diff)
            config_marker = "o";
        case 5
            % loc -> attention (both)
            config_marker = "diamond";
        case 6
            % loc -> attention (diff)
            config_marker = "diamond";
        case 7
            % order -> order (both)
            config_marker = "o";
        case 8
            % order -> order (diff)
            config_marker = "o";
        case 9
            % order -> attention (both)
            config_marker = "diamond";
        case 10
            % order -> attention (diff)
            config_marker = "diamond";
        otherwise
            error("Unknown config ID: %d", i_config);
    end
    if any(config_ID == i_config)
        marker(config_ID == i_config) = config_marker;
    end
end
