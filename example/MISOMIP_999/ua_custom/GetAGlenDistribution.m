function [UserVar,F]=GetAGlenDistribution(UserVar,CtrlVar,MUA,F)


narginchk(4,4)
nargoutchk(2,2)

%% JDR 13/02/2024: remove these checks because they do not work with the compiled
%% version of Ua-MITgcm. Instead, users should make sure they use the correct
%% form of DefineAGlenDistribution.m, as specified below.
% N=nargout('DefineAGlenDistribution');
% 
% 
% switch N
% 
%     case 2
% 
%         [F.AGlen,F.n]=DefineAGlenDistribution(CtrlVar.Experiment,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.rho,F.rhow,F.GF);
% 
%     case 3
% 
%         [UserVar,F.AGlen,F.n]=DefineAGlenDistribution(UserVar,CtrlVar,MUA,F);
% 
%     otherwise
% 
%         error('Ua:GetAGlen','DefineAGlenDistribution must return either 2 or 3 output arguments')
% 
% end

[UserVar,F.AGlen,F.n]=DefineAGlenDistribution(UserVar,CtrlVar,MUA,F);

[F.AGlen,F.n]=TestAGlenInputValues(CtrlVar,MUA,F.AGlen,F.n);

end