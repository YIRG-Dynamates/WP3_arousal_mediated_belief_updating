function [x,v,d] = genOneStim_SAC_dir(cp_flag,x_old,v_old,d_old,mu_exp,sd_exp)
%Generate one stimulus according to generative model

%Change direction sign at a change point
if cp_flag
    d = -1*d_old;
else
    d = d_old;
end
v = sd_exp*randn()+d*mu_exp;

%Update the stimulus location
x = x_old + v;

end %[EoF]
