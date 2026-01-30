function y = sigANN(x, bias)
% Sigmoid activation function.
%
% INPUTS ------------------------------------------------------------------
% x : <float Nx1>
%     Input to the units (pre-activation).
%
% bias : <float 1x1>
%     Additive bias shifting the activation threshold.
%
% OUTPUTS -----------------------------------------------------------------
% y : <float Nx1>
%     Activation of the units after applying the sigmoid nonlinearity.

arguments
    x (:, 1) double
    bias (:, 1) double = 0
end    

y = 1 ./ (1 + exp (-(x-bias)));
