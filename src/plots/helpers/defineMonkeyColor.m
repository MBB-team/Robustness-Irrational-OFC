function color = defineMonkeyColor(monkey)
% Returns the display color associated with each monkey.
%
% INPUTS ------------------------------------------------------------------
% monkey : <string 1x1>
%     Monkey name.
%
% OUTPUTS -----------------------------------------------------------------
% color : <float 1x3>
%     RGB color values.

arguments
    monkey (1, 1) string {mustBeMember(monkey, ["Franck", "Miles"])}
end

default_colors = colororder();

switch monkey
    case "Franck"
        color = default_colors(5, :);
    case "Miles"
        color = default_colors(4, :);
end
