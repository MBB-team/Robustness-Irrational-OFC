function marker = defineMonkeyMarker(monkey)
% Returns the marker associated with each monkey.
%
% INPUTS ------------------------------------------------------------------
% monkey : <string 1x1>
%     Monkey name.
%
% OUTPUTS -----------------------------------------------------------------
% marker : <string 1x1>
%     Marker associated with the monkey.

arguments
    monkey (1, 1) string {mustBeMember(monkey, ["Franck", "Miles"])}
end

switch monkey
    case "Franck"
        marker = "o";
    case "Miles"
        marker = "^";
end
