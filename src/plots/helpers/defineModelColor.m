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

% Loop over all possible config IDs
for i_config = 1:10
    if mod(i_config, 2) == 1
        % Synthesis models
        config_color = [100, 143, 255];
    else
        % comparison models
        config_color = [254, 97, 0];
    end
    if any(config_ID == i_config)
        color(config_ID == i_config, :) = config_color;
    end
end

color = color / 255;
