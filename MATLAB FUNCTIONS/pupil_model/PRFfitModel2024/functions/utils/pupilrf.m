function output = pupilrf(t,n,tmax,t0)
% Pupil Response Function
% output = pupilrf(t,n,tmax,t0)
% 
% Calculates the pupil response function at time points "t" with given
% parameters n, tmax, and t0.
% 
% INPUTS
% t = time vector (in ms)
% n+1 = number of layers (canonical value of n = 10.1)
% tmax = response maximum (canonical value of tmax = 930)
% t0 = the time of the event
% 
% OUTPUT
% output = time series of pupil response function resulting from the input
% parameters, at the time points specified in t
% 
% For more information about the pupil response function, see "Pupillary
% dilation as a measure of attention: A quantitative system analysis", 
% Hoeks & Levelt 1993
% 
% Code was first adapted from Denison, Parker & Carrasco
% Behavior Research Methods (2020) 52:1991–2007
% https://doi.org/10.3758/s13428-020-01368-6
% PRET toolbox: https://github.com/jacobaparker/PRET
%
% Then updated to normalized pdf using a gamma distribution
% As in: Silvestrin, Penny & FitzGerald
% Journal of Mathematical Psychology (2021) 101:102503
% https://doi.org/10.1016/j.jmp.2021.102503

if nargin < 4
    t0 = 0;
end

% % Original parameterization:
% output = ((t-t0).^n).*exp(-n.*(t-t0)./tmax);
% output((t-t0)<0) = 0;
%
% % Normalize the PRF to a max of 1 at tmax 
% output = output / (tmax^n*exp(-n));

a = n+1;         %shape parameter
b = tmax./n;     %scale parameter

x = t-t0;

% Use the stats toolbox function
output = gampdf(x,a,b);

% output = 1./(gamma(a).*b.^a) .* x.^(a-1) .* exp(-x./b);
% output(x<0) = 0;

end %[EoF]
