function S = selectStructFieldColumns(S, select_column)
% Selects a subset of columns in each field of a structure.
%
% INPUTS ------------------------------------------------------------------
% S : <struct 1x1>
%     Structure from which sub-columns will be selected.
%
% select_column : <bool 1xN>
%     Logical vector indicating which columns to retain.
%
% OUTPUT ------------------------------------------------------------------
% S : <struct 1x1>
%     Structure with all fields restricted to the selected columns.

all_fields = string(fieldnames(S))';
for field = all_fields
    % Select columns depending on whether the field is a row vector or a matrix
    if size(S.(field), 1) == 1
        S.(field) = S.(field)(select_column);
    else
        S.(field) = S.(field)(:, select_column);
    end
end
