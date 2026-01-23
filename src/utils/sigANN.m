function y = sigANN(x,B)

    % sigmoid activation function with optional bias parameter
    
    if nargin == 1
      B = 0;
    end

    y = 1 ./ (1 +  exp (-(x-B)) );
end