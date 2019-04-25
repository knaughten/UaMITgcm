function [UserVar,as,ab]=DefineMassBalance(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)

persistent DTbmelt Fas

%%
% Defines mass balance along upper and lower ice surfaces.
%
%   [UserVar,as,ab]=DefineMassBalance(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)
%
%   [UserVar,as,ab,dasdh,dabdh]=DefineMassBalance(UserVar,CtrlVar,MUA,CtrlVar.time,s,b,h,S,B,rho,rhow,GF);
%
%   as        mass balance along upper surface 
%   ab        mass balance along lower ice surface
%   dasdh     upper surface mass balance gradient with respect to ice thickness
%   dabdh     lower surface mass balance gradient with respect to ice thickness
%  
% dasdh and dabdh only need to be specified if the mass-balance feedback option is
% being used. 
%
% In �a the mass balance, as returned by this m-file, is multiplied internally by the local ice density. 
%
% The units of as and ab are water equivalent per time, i.e. usually
% as and ab will have the same units as velocity (something like m/yr or m/day).
%

%% Surface accumulation
if isempty(Fas)
    load('FasRACMO.mat');
end

%% Basal melt
if isempty(DTbmelt)
	DTbmelt = scatteredInterpolant(UserVar.UaMITgcm.MITgcmGridX(:),...
        UserVar.UaMITgcm.MITgcmGridY(:),UserVar.UaMITgcm.MITgcmMelt(:),'linear');
end

x = MUA.coordinates(:,1);
y = MUA.coordinates(:,2);
as = Fas(x,y);
ab1 = DTbmelt(x,y);

MeltNodes=SpecifyMeltNodes(CtrlVar,MUA,GF); 
ab = zeros(MUA.Nnodes,1);
ab(MeltNodes) = ab1(MeltNodes); % don't melt lakes or nodes in elements connected to the GL

         
end
