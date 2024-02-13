

function [UserVar,F]=GetDensities(UserVar,CtrlVar,MUA,F)

narginchk(4,4)
nargoutchk(2,2)

%% JDR 13/02/2024: remove these checks because they do not work with the compiled
%% version of Ua-MITgcm. Instead, users should make sure they use the correct
%% form of DefineGeometryAndDensities.m, as specified below.
% InputFile="DefineDensities.m" ;
% TestIfInputFileInWorkingDirectory(InputFile) ;

% N=nargout('DefineDensities');
% 
% switch N
% 
%     case 3
% 
%         [F.rho,F.rhow,F.g]=DefineDensities(CtrlVar.Experiment,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B);
% 
%     case 4
% 
%         [UserVar,F.rho,F.rhow,F.g]=DefineDensities(UserVar,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B);
% 
%     otherwise
% 
%         error('Ua:GetDensities','Need 3 or 4 outputs')
% 
% end

[UserVar,~,~,~,~,F.rho,F.rhow,F.g]=DefineGeometryAndDensities(UserVar,CtrlVar,MUA,F,'-rho-rhow-g-');

[F.rho,F.rhow,F.g]=TestDensityInputValues(CtrlVar,MUA,F.rho,F.rhow,F.g);

end
