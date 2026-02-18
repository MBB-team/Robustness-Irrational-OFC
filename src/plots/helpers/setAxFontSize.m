function [] = setAxFontSize(ax)
% Sets the font size of all the axis' elements already drawned.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
end

fontsize(ax, 8, "points");
