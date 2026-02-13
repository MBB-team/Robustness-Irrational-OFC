function style = defineModelLineStyle(config_ID)
% Returns the line style associated with each model configuration.
%
% INPUTS ------------------------------------------------------------------
% config_ID : <int 1xN>
%     Vector of configuration IDs identifying the models' Config 
%     structures.
%
% OUTPUTS -----------------------------------------------------------------
% style : <string 1xN>
%     Line style associated with each configuration ID.

arguments
    config_ID (1, :) double
end

% Initialize output
style = strings(1, length(config_ID));

% Loop over all possible config IDs
for i_config = 1:10
    switch i_config
        case 1
            % loc -> loc (both)
            config_style = ":";
        case 2
            % loc -> loc (diff)
            config_style = ":";
        case 3
            % loc -> order (both)
            config_style = ":";
        case 4
            % loc -> order (diff)
            config_style = ":";
        case 5
            % loc -> attention (both)
            config_style = ":";
        case 6
            % loc -> attention (diff)
            config_style = ":";
        case 7
            % order -> order (both)
            config_style = "-";
        case 8
            % order -> order (diff)
            config_style = "-";
        case 9
            % order -> attention (both)
            config_style = "-";
        case 10
            % order -> attention (diff)
            config_style = "-";
        otherwise
            error("Unknown config ID: %d", i_config);
    end
    if any(config_ID == i_config)
        style(config_ID == i_config) = config_style;
    end
end
