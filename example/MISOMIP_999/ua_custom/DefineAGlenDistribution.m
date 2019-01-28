
function [UserVar,AGlen,n]=DefineAGlenDistribution(UserVar,CtrlVar,MUA,F)


%
% A0=2e-17 Pa^-3 / a
% (2e-17)/31556926 = 6.3378e-25 Pa^-3 / s
%
%
%
n=3;

%A=6.338e-25;
A=7.2e-25;
AGlen=A*1e9*365*24*60*60+zeros(MUA.Nnodes,1);


end

