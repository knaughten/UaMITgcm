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
%	load '/data/dataphy/janryd69/Antarctic_datasets/Antarctic_Accumulation_Maps/RobArthernAccumulationMap.mat';
%	load '/Users/janderydt/Documents/Work_Data/Antarctic_datasets/RACMO/SMB_RACMO_1979_2013.mat';
%	load '/data/dataphy/janryd69/Antarctic_datasets/Antarctic_Accumulation_Maps/RACMO2.3/SMB_RACMO_1979_2013.mat';
    load(UserVar.RACMO_SMB);
	DTsacc = scatteredInterpolant(xRACMO,yRACMO,SMB_av,'natural','nearest');
end

as=DTsacc(x,y);

%% Surface lowering from Pritchard
% if isempty(DTPritchard)
%     addpath('/home/janryd69/data/Antarctic_datasets/Antarctic_SurfaceLowering_Pritchard');
%     [XP,YP,dsdt] = readdata_Pritchard;
%     I = find(~isnan(dsdt));
%     DTPritchard = scatteredInterpolant(XP(I),YP(I),dsdt(I),'natural','nearest');
% end
% 
% as = as - DTPritchard(x,y);
% 
%figure; PlotNodalBasedQuantities(MUA.connectivity,MUA.coordinates,as);

%if MUA.Nnodes ~= length(as_init)
%	MB_MeshChanged=1;
%else
%	MB_MeshChanged=0;
%end

% if CtrlVar.MeshChanged == 1
% %if MB_MeshChanged==1
% 	as_init=Grid1toGrid2(DTacc,SMB_av,x,y,CtrlVar);
% end

if any(isnan(as))
	as(isnan(as)) = nanmean(as);
	fprint('Corrected for NaNs in surface mass balance');
end

%% Basal melt rates using input from MITgcm

%ab is defined on a grid (x,y)  I need to check in the future if coordinates are defined on the same grid and if not then do an
%interpolation
if isempty(DTbmelt)
	DTbmelt = scatteredInterpolant(UserVar.UaMITgcm.MITgcmCGridX(:),...
        UserVar.UaMITgcm.MITgcmCGridY(:),UserVar.UaMITgcm.MITgcmMelt(:),'linear');
end

x = MUA.coordinates(:,1); y = MUA.coordinates(:,2);
ab=DTbmelt(x,y);

% make sure that ab is zero unless 1) node is afloat and 2) node belongs to ocean
[GF,~,~,~]=IceSheetIceShelves(CtrlVar,MUA,GF);
I = [find(GF.NodesCrossingGroundingLines(:)); find(GF.NodesUpstreamOfGroundingLines(:))];
ab(I)=0;

[~,LakeNodes,~,~,~,~] = LakeOrOcean(CtrlVar,MUA,GF);
ab(LakeNodes)=0;

h=s-b;
I=(h<CtrlVar.ThickMin & ab<0); ab(I)=0;  dabdh(I)=0;% do not melt ice shelf away where ice thickness is less than 1m.

end
