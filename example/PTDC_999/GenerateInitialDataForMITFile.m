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
x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);
Fb = scatteredInterpolant(x,y,b,'linear');

% make long arrays for center points of structured grid boxes
X=XStr_m(:);
Y=YStr_m(:);
% ice boundary
IF = [MUA.Boundary.x(:) MUA.Boundary.y(:)];

% initialise all necessary variables and matrices
Flag=zeros(nx*ny,1);
Draft=zeros(nx*ny,1);
Bathy=zeros(nx*ny,1);
    
% calculate bathymetry for MITgcm tracer cells: take value at corresponding Ua node
Bathy = FB(X,Y);

%% assign flags for open ocean
% criterion: midpoint of tracer cell falls outside Ua domain
IN = inpoly([X,Y],IF);
Iice = find(IN); Iocean = find(IN==0);
Flag(Iocean) = 2;

[GLgeo,GLnodes,GLele]=GLgeometry(MUA.connectivity,MUA.coordinates,GF,CtrlVar);
[~,LakeNodes]=LakeOrOcean_UaMITgcm(CtrlVar,MUA,GF,GLgeo,GLnodes,GLele);
Index_LakeNodes = find(LakeNodes==1);
GF.node(Index_LakeNodes) = 1;

FGF = scatteredInterpolant(MUA.coordinates(:,1),MUA.coordinates(:,2),GF.node);

%% criterion: MIT grid cell is only grounded if all four corner cells are grounded in Ua
GFMITnodes = FGF(XStr_m(Iice)-deltaX/2,YStr_m(Iice)-deltaY/2)+FGF(XStr_m(Iice)-deltaX/2,YStr_m(Iice)+deltaY/2)+...
FGF(XStr_m(Iice)+deltaX/2,YStr_m(Iice)+deltaY/2)+FGF(XStr_m(Iice)+deltaX/2,YStr_m(Iice)-deltaY/2);

Jshelf = find(GFMITnodes<3.5); Jground = find(GFMITnodes>=3.5);
Flag(Iice(Jshelf))=1;
Flag(Iice(Jground))=0;
%%%%%%%%%%%%%%%%%%%%

%% do consistency checks

Ishelf=find(Flag==1);
Iocean=find(Flag==2);

% areas where ice shelf and open ocean bathymetry are above sea level are
%set to zero 
Ishelfocean=[Ishelf(:);Iocean(:)];
I=Bathy(Ishelfocean)>=0;
Bathy(Ishelfocean(I))=0;
Flag(Ishelfocean(I))=0;

Ishelf=find(Flag==1);
Iocean=find(Flag==2);
Igrounded=find(Flag==0);

Bathy(Igrounded)=0;
Flag(Igrounded)=0;

Draft(Ishelf)= Fb(X(Ishelf),Y(Ishelf));

% areas where draft is above sea level or below bathymetry are set to zero
% and treated as grounded
I = (Draft>=0 & Draft<Bathy);
Draft(I)=0; Bathy(I); Flag(I)=0;

Flag = reshape(Flag,nx,ny);
Draft = reshape(Draft,nx,ny);
Bathy = reshape(Bathy,nx,ny);

B_forMITgcm = Bathy;
b_forMITgcm = Draft;
mask_forMITgcm = Flag;

save ua_custom/DataForMIT.mat B_forMITgcm b_forMITgcm mask_forMITgcm

figure; pcolor(XStr_m-1300/2,YStr_m-1300/2,B_forMITgcm);
shading flat;
hold on; PlotGroundingLines(CtrlVar,MUA,GF,[],[],[],'color','k');

figure; pcolor(XStr_m-1300/2,YStr_m-1300/2,b_forMITgcm);
shading flat;
hold on; PlotGroundingLines(CtrlVar,MUA,GF,[],[],[],'color','k');


