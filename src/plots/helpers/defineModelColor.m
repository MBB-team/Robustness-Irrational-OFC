function color = defineModelColor(config_ID)
% Returns the display color associated with each model configuration.
%
% INPUTS ------------------------------------------------------------------
% config_ID : <int 1xN>
%     Vector of configuration IDs identifying the models' Config 
%     structures.
%
% OUTPUTS -----------------------------------------------------------------
% color : <float Nx3>
%     RGB color values associated with each configuration ID.

arguments
    config_ID (1, :) double
end

% Initialize output
color = NaN(length(config_ID), 3);

default_colors = colororder();

% Loop over all possible config IDs
for i_config = 1:10
    switch i_config
        case 1
            % loc -> loc (both)
            config_color = default_colors(1, :);
        case 2
            % loc -> loc (diff)
            config_color = default_colors(2, :);
        case 3
            % loc -> order (both)
            config_color = default_colors(1, :);
        case 4
            % loc -> order (diff)
            config_color = default_colors(2, :);
        case 5
            % loc -> attention (both)
            config_color = default_colors(1, :);
        case 6
            % loc -> attention (diff)
            config_color = default_colors(2, :);
        case 7
            % order -> order (both)
            config_color = default_colors(1, :);
        case 8
            % order -> order (diff)
            config_color = default_colors(2, :);
        case 9
            % order -> attention (both)
            config_color = default_colors(1, :);
        case 10
            % order -> attention (diff)
            config_color = default_colors(2, :);
        otherwise
            error("Unknown config ID: %d", i_config);
    end
    if any(config_ID == i_config)
        color(config_ID == i_config, :) = config_color;
    end
end
