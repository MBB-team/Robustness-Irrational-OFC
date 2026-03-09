function colormap = defineSequentialColormap(n_colors)

arguments
    n_colors (1, 1) double = 256
end

grey_level = 0.15;
colors = [...
    grey_level, grey_level, grey_level ; ...
    hex2rgb("#7D75A1") ; ...
    1, 1, 1];

colormap = multigradient(colors, length=n_colors);

end
