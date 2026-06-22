function [x,v,cp,d] = genOneTrial_SAC_dir(mu_exp,sd_exp,cp_hazard_rate,ep_hazard_rate,first_stimulus_sd)
%Generate all stimuli for one trial

%Initialize the spatial location for t=0
x = first_stimulus_sd*randn();
v = NaN;
cp = NaN;

%Keep generating stimuli until we reach the last stimulus
t=1;
last_flag = false;
while ~last_flag 
    
    %Randomly determine whether this will be a change-point and/or end-point
    if t==1
        cp(t+1) = true;
        d = sign(rand()-0.5);                   %Randomly determine the starting direction
    else
        cp(t+1) = (rand() <= cp_hazard_rate);                               
    end
    last_flag = (rand() <= ep_hazard_rate);
    
    %Generate the stimulus location and velocity
    [x(t+1),v(t+1),d(t+1)] = genOneStim_SAC_dir(cp(t+1),x(t),v(t),d(t),mu_exp,sd_exp);
    
    %Reset first starting direction to NaN because there is no movement direction with only one stimulus   
    if t==1
        d(1) = NaN;
    end
    
    %Update counter
    t=t+1;    
    
    
end

end %[EoF]
