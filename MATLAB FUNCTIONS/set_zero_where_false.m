function out = set_zero_where_false(sac, incl_sounds_cell)
    out = sac;  % Copy original values
    out(incl_sounds_cell == 0) = 0;  % Set to zero where both_true_cell is 0
end