





x = [12 ,16 ,18 ,16, 12, 12,16,12,10,12,16,20,12,16,10, 18, 16,20,12,16]'
y = [20.5000,31.5000,47.7000, 26.2000,44.0000,8.2800,30.8000,17.2000,19.9000,9.9600,55.8000,25.2000,29.0000,85.5000,15.1000,28.5000,21.4000,17.7000,6.4200,84.9000]'


nLogLGradFun = @(theta) deal(-sum(-gammaln(theta(1)) - ...
    theta(1)*log(theta(2) + x) + (theta(1)-1)*log(y) - ...
    y./(theta(2)+x)),...
    -[sum(-psi(theta(1))+log(y./(theta(2)+x)));...
    sum(1./(theta(2)+x).*(y./(theta(2)+x)-theta(1)))]);


theta0 = randn(2,1); % Initial value for optimization
uLB = [0 -min(x)];   % Unrestricted model lower bound
uUB = [Inf Inf];     % Unrestricted model upper bound
options = optimoptions('fmincon','Algorithm','interior-point',...
    'FunctionTolerance',1e-10,'Display','off',...
    'SpecifyObjectiveGradient',true); % Optimization options

[uMLE,uLogL] = fmincon(nLogLGradFun,theta0,[],[],[],[],uLB,uUB,[],options);
uLogL = -uLogL;


dof = 1;           % Number of restrictions
rLB = [1 -min(x)]; % Restricted model lower bound
rUB = [1 Inf];     % Restricted model upper bound
[rMLE,rLogL] = fmincon(nLogLGradFun,theta0,[],[],[],[],rLB,rUB,[],options);
rLogL = -rLogL;


[h,pValue,stat] = lratiotest(uLogL,rLogL,dof)



waldtest

