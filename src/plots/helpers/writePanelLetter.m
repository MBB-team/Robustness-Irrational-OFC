function [] = writePanelLetter(ax, letter, x_shift, y_shift)

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    letter (1, 1) string
    x_shift (1, 1) double = 0
    y_shift (1, 1) double = 0
end

% Get coordinates of the ax top left corner
ax.Units = "centimeters";
ax_height = ax.Position(4);

% Write the letter on the top left corner
panelLetter = text(ax, 0, ax_height, letter, ...
    Units="centimeters", ...
    FontWeight="bold", ...
    VerticalAlignment="bottom", ...
    HorizontalAlignment="right", ...
    FontSize=14);

% Shift it
panelLetter.Position(1) = panelLetter.Position(1) + x_shift;
panelLetter.Position(2) = panelLetter.Position(2) + y_shift;
