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

switch monkey
    case "Franck"
        color = [92, 199, 86] / 255; % green
    case "Miles"
        color = [220, 38, 127] / 255; % IBM pink
end
