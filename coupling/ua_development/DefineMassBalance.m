function [UserVar,as,ab]=DefineMassBalance(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)

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

%% Surface accumulation
as=0.3; 

%% Basal melt
if isempty(DTbmelt)
	DTbmelt = scatteredInterpolant(UserVar.UaMITgcm.MITgcmGridX(:),...
        UserVar.UaMITgcm.MITgcmGridY(:),UserVar.UaMITgcm.MITgcmMelt(:),'linear');
end

x = MUA.coordinates(:,1); y = MUA.coordinates(:,2);
ab=DTbmelt(x,y);

%% Only melt/accumulate strictly floating elements, i.e. make sure that ab is zero unless 
%   1) node is afloat,
%   2) node belongs to element that is fully afloat.
[GF,~,~,~]=IceSheetIceShelves(CtrlVar,MUA,GF);
I = [find(GF.NodesCrossingGroundingLines(:)); find(GF.NodesUpstreamOfGroundingLines(:))];
ab(I)=0;

%% Do not melt/accumulate isolated 'lakes' upstream of the main grounding line
[~,LakeNodes]=LakeOrOcean(CtrlVar,GF,MUA.Boundary,MUA.connectivity,MUA.coordinates);
ab(LakeNodes)=0;

%% do not melt ice where ice thickness is less CtrlVar.ThickMin
h=s-b;
I=(h<CtrlVar.ThickMin & ab<0); ab(I)=0; 

end
