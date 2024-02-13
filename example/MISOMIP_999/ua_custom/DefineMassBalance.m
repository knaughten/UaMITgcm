function [UserVar,as,ab]=DefineMassBalance(UserVar,CtrlVar,MUA,F)

persistent DTbmelt

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
x = MUA.coordinates(:,1); y = MUA.coordinates(:,2);

%% Surface accumulation
as= 0*x + 0.3; 

%% Basal melt
if isempty(DTbmelt)
	DTbmelt = scatteredInterpolant(UserVar.UaMITgcm.MITgcmCGridX(:),...
        UserVar.UaMITgcm.MITgcmCGridY(:),UserVar.UaMITgcm.MITgcmMelt(:),'linear');
end

ab=DTbmelt(x,y);
%ab = 0*x;

%% Only melt/accumulate strictly floating elements, i.e. make sure that ab is zero unless 
%   1) node is afloat,
%   2) node belongs to element that is fully afloat.
% [GF,~,~,~]=IceSheetIceShelves(CtrlVar,MUA,F.GF);
% I = [find(GF.NodesCrossingGroundingLines(:)); find(GF.NodesUpstreamOfGroundingLines(:))];
% ab(I)=0;
% 
%% Do not melt/accumulate isolated 'lakes' upstream of the main grounding line
% [LakeNodes,OceanNodes,~,~] = LakeOrOcean3(CtrlVar,MUA,GF);
% ab(LakeNodes)=0;

%% Or simply:
[MeltNodes,~]=SpecifyMeltNodes(CtrlVar,MUA,F.GF);
ab(~MeltNodes) = 0;

%% do not melt ice where ice thickness is less CtrlVar.ThickMin
h=F.s-F.b;
I=(h<CtrlVar.ThickMin & ab<0); ab(I)=0; 

end
