function out = set_NaN_where_false(sac, incl_sounds_cell)
    out = sac;  % Copy original values
    out(incl_sounds_cell == 0) = NaN;  % Set to zero where incl_sounds_cell is 0
end