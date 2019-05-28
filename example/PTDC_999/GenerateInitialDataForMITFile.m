function GenerateInitialDataForMITFile

addpath('../../../Ua_InputData');
addpath('./ua_custom');

deltaX=1300;  % in m
nx=12*15;
deltaY=1300;  % in m
ny=24*15;
deltaZ=[20 40 100];
nz_part=[50 10 6];
nz = sum(nz_part);
dz=[];
for ii=1:length(deltaZ)
    dz = [dz deltaZ(ii)*ones(1,nz_part(ii))];
end
zgp1 = [0,cumsum(dz)];
zc = .5*(zgp1(1:end-1)+zgp1(2:end));
zg = zgp1(1:end-1);

XStr=[-1.7e6+deltaX/2:deltaX:-1.7e6+(nx-1/2)*deltaX];
YStr=[-7e5+deltaY/2:deltaY:-7e5+(ny-1/2)*deltaY];
[XStr_m,YStr_m]=ndgrid(XStr,YStr);

load('GriddedInterpolants_sBh_Bedmachine_Bamber2009.mat');
load('InitialGeometry_UaOutput_Bedmachine_Bamber2009.mat','b','MUA','GF','CtrlVar');

MUAold = MUA; Fold = F; lold = l; BCsOld = BCs; GFold = GF;
    
[MUAnew.coordinates,MUAnew.connectivity]=FE2dRefineMesh(MUAold.coordinates,MUAold.connectivity);
MUAnew=CreateMUA(CtrlVar,MUAnew.connectivity,MUAnew.coordinates);

[UserVar,~,Fnew,~,~]=MapFbetweenMeshes(UserVar,RunInfo,CtrlVar,MUAold,MUAnew,Fold,BCsOld,lold);
GFnew = GL2d(Fnew.B,Fnew.S,Fnew.h,Fnew.rhow,Fnew.rho,MUAnew.connectivity,CtrlVar);

xnew = MUAnew.coordinates(:,1); ynew = MUAnew.coordinates(:,2);
xold = MUAold.coordinates(:,1); yold = MUAold.coordinates(:,2);
X = UserVar.UaMITgcm.MITgcmGridX; Y = UserVar.UaMITgcm.MITgcmGridY;
[nx,ny] = size(X);
dX = UserVar.UaMITgcm.MITgcmGridX(2,1)-UserVar.UaMITgcm.MITgcmGridX(1,1);
dY = UserVar.UaMITgcm.MITgcmGridY(1,2)-UserVar.UaMITgcm.MITgcmGridY(1,1);

Mask = 0*X(:);

% Generate edges of MIT boxes
MITXedges = [X(1,1)-dX/2:dX:X(end,1)+dX/2];
MITYedges = [Y(1,1)-dY/2:dY:Y(1,end)+dY/2];

% Assign ice shelf mask
% criterion: every MIT cell that countains melt nodes is given mask value 1
% (ice shelf)
[MeltNodesNew,~]=SpecifyMeltNodes(CtrlVar,MUAnew,GFnew);
h=histogram2(xnew(MeltNodesNew),ynew(MeltNodesNew),MITXedges,MITYedges);
Mask(h.Values>0)=1;

% Assign open ocean mask
IN = inpoly([X(:),Y(:)],[MUAnew.Boundary.x(:) MUAnew.Boundary.y(:)]); 
Iocean = find(IN==0 & Mask~=1);
Mask(Iocean) = 2;

mask_forMITgcm = reshape(Mask,nx,ny);

%% Generate b and B fields
B_forMITgcm = FB(X,Y);

% We use a linear interpolation to map the Ua draft onto the MITgcm grid. Note that more sophisticated
% methods can be implemented, such as 'data binning'. If the MITgcm tracer points are a subset of the Ua nodes then
% interpolation is not required
Fb = scatteredInterpolant(xold,yold,Fold.b,'linear');
b_forMITgcm = Fb(X,Y);

%% Consistency checks
b_forMITgcm(mask_forMITgcm==2) = 0;

B_forMITgcm(mask_forMITgcm==0) = b_forMITgcm(mask_forMITgcm==0);

Ierr = find((mask_forMITgcm==1).*(B_forMITgcm>=b_forMITgcm));
B_forMITgcm(Ierr) = b_forMITgcm(Ierr)-1;

Ipos = find((mask_forMITgcm==1).*(b_forMITgcm>0));
b_forMITgcm(Ipos) = B_forMITgcm(Ipos);
mask_forMITgcm(Ipos) = 0;

save ua_custom/DataForMIT.mat B_forMITgcm b_forMITgcm mask_forMITgcm

figure; pcolor(XStr_m-1300/2,YStr_m-1300/2,B_forMITgcm);
shading flat;
hold on; PlotGroundingLines(CtrlVar,MUA,GF,[],[],[],'color','k');

figure; pcolor(XStr_m-1300/2,YStr_m-1300/2,b_forMITgcm);
shading flat;
hold on; PlotGroundingLines(CtrlVar,MUA,GF,[],[],[],'color','k');


