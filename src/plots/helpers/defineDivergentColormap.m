function colormap = defineDivergentColormap(n_colors)

arguments
    n_colors (1, 1) double = 256
end

colors = [...
    hex2rgb("#648FFF") ; ...
    1, 1, 1 ; ...
    hex2rgb("#DC267F")];

colormap = multigradient(colors, length=n_colors);

end
