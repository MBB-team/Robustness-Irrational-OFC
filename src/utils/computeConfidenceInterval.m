function conf_interval = computeConfidenceInterval(x)

standard_error = std(x, "omitnan") / sqrt(length(x));        
t_score = tinv([0.025, 0.975], sum(~ isnan(x)) - 1);
conf_interval = mean(x, "omitnan") + t_score * standard_error;

end
