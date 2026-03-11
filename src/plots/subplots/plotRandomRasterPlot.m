function [] = plotRandomRasterPlot(ax, plot_options)
% Code for figure 2a.
%
% INPUTS ------------------------------------------------------------------
% ax : <matlab.graphics.axis.Axes 1x1>
%     Axes handle where the plot should be drawn.
% rng, marker_size :
%     Name-value parameters controlling visual properties of the plot.
%
% OUTPUTS -----------------------------------------------------------------
% None. The function draws into the provided axes.

arguments
    ax (1, 1) matlab.graphics.axis.Axes
    plot_options.rng (1, 1) double = 1
    plot_options.prop_spikes (1, 1) double = 15
    plot_options.n_neurons (1, 1) double = 20
    plot_options.sample_time (1, 1) double = 20
    plot_options.cue_display_time (1, 1) double = 30
    plot_options.cue_display_var (1, 1) double = 5
    plot_options.time_before_cue (1, 1) double = 30
    plot_options.spike_gray_level (1, 1) double = 0.6
end

hold(ax, "on");

% Generate random spikes
rng(plot_options.rng);
display_time = plot_options.cue_display_time + plot_options.cue_display_var * randn(1, 4);
cue_onset = round(plot_options.time_before_cue + cumsum([0, display_time]));
n_sample = cue_onset(end);
spike_prob = rand(plot_options.n_neurons, n_sample);
for i_neuron = 1:plot_options.n_neurons
    spike_prob(i_neuron, :) = spike_prob(i_neuron, :) .* min((1.1 - abs(cos((1:n_sample)/(n_sample/9)))), 1);
end
thresh_spike_prob = prctile(spike_prob(:), plot_options.prop_spikes);
spikes = double(spike_prob <= thresh_spike_prob);

% Plot
colormap(ax, plot_options.spike_gray_level * ones(1, 3));
imagesc(ax, spikes, AlphaData=spikes);

% Cue onset
for i_cue = 1:4
    xline(ax, cue_onset(i_cue), "k-", LineWidth=2);
end

% Aesthetics
xticks(ax, cue_onset);
yticks(ax, []);
xticklabels(ax, []);
xlim(ax, [0, n_sample]);
ylim(ax, [0.5, plot_options.n_neurons + 0.5]);
setAxFontSize(ax);


hold(ax, "off");
