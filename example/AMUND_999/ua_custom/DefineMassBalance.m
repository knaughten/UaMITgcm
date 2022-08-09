function [UserVar,as,ab]=DefineMassBalance(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)

persistent DTsacc DTbmelt
         
%
% When calculating dabdh from ab(b) for floating ice shelves:
% b=S-rho h /rhow
% h=rhow (S-b)/rho
% ab(b)=ab(S-rho h/rhow)
% dab/dh= -(rho/rhow) dab/db
% or:
% dab/dh = dab/db  db/dh = dab/db (-rho/rhow)= -(rho/rhow) dab/db 
          
x = MUA.coordinates(:,1); y=MUA.coordinates(:,2);

%% Surface mass balance
if isempty(DTsacc)

    load(UserVar.RACMO_SMB);
	DTsacc = scatteredInterpolant(xRACMO,yRACMO,SMB_av,'natural','nearest');

end

as=DTsacc(x,y);

%% Basal melt rates using input from MITgcm

%ab is defined on a grid (x,y)  I need to check in the future if coordinates are defined on the same grid and if not then do an
%interpolation
if isempty(DTbmelt)
    % only use non-zero melt values in interpolant to allow for some
    % extrapolation if needed
    I = UserVar.UaMITgcm.MITgcmMelt(:)==0;
	DTbmelt = scatteredInterpolant(UserVar.UaMITgcm.MITgcmCGridX(~I),...
        UserVar.UaMITgcm.MITgcmCGridY(~I),UserVar.UaMITgcm.MITgcmMelt(~I),'natural','nearest');
end

x = MUA.coordinates(:,1); y = MUA.coordinates(:,2);
ab=DTbmelt(x,y);

% make sure that ab is zero unless 1) node is afloat and 2) node belongs to ocean
[GF,~,~,~]=IceSheetIceShelves(CtrlVar,MUA,GF);
I = [find(GF.NodesCrossingGroundingLines(:)); find(GF.NodesUpstreamOfGroundingLines(:))];
ab(I)=0;

[~,OceanNodes] = LakeOrOcean3(CtrlVar,MUA,GF);
ab(~OceanNodes) = 0;

I=(h<CtrlVar.ThickMin+0.5 & ab<0); ab(I)=0;  % do not melt ice shelf away 
% %where ice thickness is less than 0.5m away from minimum ice thickness.
dabdh(I)=0;


if any(isnan(as))
	error('NaNs in surface mass balance');
end
if any(isnan(ab))
	error('NaNs in basal mass balance');
end

end

