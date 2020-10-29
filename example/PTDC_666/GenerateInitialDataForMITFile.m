function GenerateInitialDataForMITFile

runID = 'PTDC_702';

%% read restartfile with geometry
restartfile = dir('./*RestartFile.mat');
load([restartfile.folder,'/',restartfile.name]);
CtrlVar = CtrlVarInRestartFile;

load UserVar_MIT.mat;

froot = '/Volumes/mainJDeRydt/UaMITgcm_v2/Ua_InputData/';

RunTable=readtable([froot,'/RunTable.csv']); 
I=find(strcmp({RunTable{:,'ID'}{:}},runID));
 
UserVar.NameOfFileForReadingSlipperinessEstimate = [froot,RunTable{I,'Row'}{:},'_C-Estimate.mat'];
UserVar.NameOfFileForReadingAGlenEstimate = [froot,RunTable{I,'Row'}{:},'_AGlen-Estimate.mat'];
CtrlVar.NameOfFileForReadingSlipperinessEstimate = UserVar.NameOfFileForReadingSlipperinessEstimate;
CtrlVar.NameOfFileForReadingAGlenEstimate = UserVar.NameOfFileForReadingAGlenEstimate;
switch RunTable{I,'GeometryInterpolants'}{:}
    case 'Bedmachine20200715_Bamber2009'
        UserVar.GeometryInterpolants = [froot,'GriddedInterpolants_sBh_Bedmachine2020-07-15_Bamber2009.mat'];
    case 'Bedmachine20190905_Bamber2009'
        UserVar.GeometryInterpolants = [froot,'GriddedInterpolants_sBh_Bedmachine2019-09-05_Bamber2009.mat'];
    case 'Bedmachine_Bamber2009'
        UserVar.GeometryInterpolants = [froot,'GriddedInterpolants_sBh_Bedmachine_Bamber2009.mat'];
    otherwise
        error('Geometry does not exist');
end
UserVar.FirnInterpolants = [froot,'GriddedInterpolants_Firn_RACMO.mat'];
UserVar.RACMO_SMB = [froot,'SMB_RACMO_1979_2013.mat'];

UserVar.UaMITgcm.Experiment = runID;
UserVar.UaMITgcm.CentralOutputDirectory = './';
 
%% Generate mask
MUA_old = MUA; F_old = F; l_old = l; BCs_old = BCs; GF_old = GF;

if ~exist('RefinedMesh_for_MITmask.mat')
    %% Refine mesh for definition of the mask: maximum spacing between Ua nodes should be less than the MITgcm grid resolution
    % MIT grid resolution:
    dX_MIT = UserVar.UaMITgcm.MITgcmCGridX(2,1)-UserVar.UaMITgcm.MITgcmCGridX(1,1);
    dY_MIT = UserVar.UaMITgcm.MITgcmCGridY(1,2)-UserVar.UaMITgcm.MITgcmCGridY(1,1);
    dXmax = min(dX_MIT,dY_MIT);

    CtrlVar.MeshRefinementMethod='explicit:local:newest vertex bisection';
    CtrlVar.AdaptMeshInitial=1;
    CtrlVar.AdaptMeshMaxIterations=20;
    CtrlVar.TimeDependentRun=0;
    CtrlVar.doplots=0; CtrlVar.doAdaptMeshPlots=0; CtrlVar.InfoLevelAdaptiveMeshing=1;
    CtrlVar.MeshSizeMax=dXmax/4;
    CtrlVar.MeshSize=dXmax/4;
    CtrlVar.MeshSizeMin=dXmax/4;
    CtrlVar.MeshAdapt.GLrange=[];

    RunInfo=UaRunInfo;
    CtrlVar.WriteRunInfoFile=0;

    [~,~,F_old,l_old,~,Ruv_old,Lubvb]= uv(UserVar,RunInfo,CtrlVar,MUA_old,BCs_old,F_old,l_old);
    [~,~,MUA_new,BCs_New,F_new,l_new]=AdaptMesh(UserVar,RunInfo,CtrlVar,MUA_old,BCs_old,F_old,l_old,Ruv_old,Lubvb);
    save('RefinedMesh_for_MITmask.mat','MUA_new');
else
    load('RefinedMesh_for_MITmask.mat');
end

CtrlVar.Report_if_b_less_than_B=1;
[~,~,F_new,~,~]=MapFbetweenMeshes(UserVar,[],CtrlVar,MUA_old,MUA_new,F_old,BCs_old,l_old);
GF_new = GL2d(F_new.B,F_new.S,F_new.h,F_new.rhow,F_new.rho,MUA_new.connectivity,CtrlVar);

xUa_new = MUA_new.coordinates(:,1); yUa_new = MUA_new.coordinates(:,2);
xUa_old = MUA_old.coordinates(:,1); yUa_old = MUA_old.coordinates(:,2);

%% check if MITgcm grid is lat/lon or polar stereographic.
if strcmp(UserVar.UaMITgcm.MITcoordinates,'latlon')
    lonCMIT = UserVar.UaMITgcm.MITgcmCGridlon; % 2d arrays
    latCMIT = UserVar.UaMITgcm.MITgcmCGridlat;
    lonGMIT = UserVar.UaMITgcm.MITgcmGGridlon; % 2d arrays
    latGMIT = UserVar.UaMITgcm.MITgcmGGridlat;
    [latUa_new,lonUa_new] = psxy2ll(xUa_new,yUa_new,-71,0);

elseif strcmp(UserVar.UaMITgcm.MITcoordinates,'xy')
    lonCMIT = UserVar.UaMITgcm.MITgcmCGridX; % 2d arrays
    latCMIT = UserVar.UaMITgcm.MITgcmCGridY;
    lonGMIT = UserVar.UaMITgcm.MITgcmGGridX; % 2d arrays
    latGMIT = UserVar.UaMITgcm.MITgcmGGridY;        
    lonUa_new = xUa_new;
    latUa_new = yUa_new;
end
    
[nx,ny] = size(lonCMIT);

Mask = 0*lonCMIT(:);

%% Generate edges of MITgcm grid cells. The MITgcm grid (either lat/lon or polar stereographic) is always assumed to be rectangular 
MITXedges = [lonGMIT(:,1); 2*lonCMIT(end,1)-lonGMIT(end,1)];
MITYedges = [latGMIT(1,:) 2*latCMIT(1,end)-latGMIT(1,end)]';

% Assign ice shelf mask
% criterion: every MIT cell that countains melt nodes is given mask value 1
% (ice shelf)

[MeltNodesNew,~]=SpecifyMeltNodes(CtrlVar,MUA_new,GF_new);

[Nmeltnodes,~,~] = histcounts2(lonUa_new(MeltNodesNew),latUa_new(MeltNodesNew),MITXedges,MITYedges);
Mask(Nmeltnodes>0)=1;

% Assign open ocean mask
% criterion: every MIT cell that does not countain any Ua nodes is given mask value 2
% (open ocean)
[NUanodes,~,~] = histcounts2(lonUa_new,latUa_new,MITXedges,MITYedges);
Mask(NUanodes==0) = 2;

% Check internal boundaries and set to grounded ice
I = find(isnan(MUA_new.Boundary.x));
I = [I;length(MUA_new.Boundary.x)+1];

for ii=1:length(I)-1
    J = inpoly2([lonCMIT(:) latCMIT(:)],[MUA_new.Boundary.x(I(ii)+1:I(ii+1)-1) MUA_new.Boundary.y(I(ii)+1:I(ii+1)-1)]);
    Mask(J) = 0;
end

% correction at western boundary
I = find(lonCMIT(:)>-1.55e6 & lonCMIT(:)<-1.5e6 & latCMIT(:)<-6.95e5);
Mask(I) = 0;

mask_forMITgcm = Mask(:);

%% Generate b and B fields
% Obtain bed at MITgcm tracer points via DefineGeometry
MITmesh.coordinates = [UserVar.UaMITgcm.MITgcmCGridX(:) UserVar.UaMITgcm.MITgcmCGridY(:)];
[~,~,~,~,B_forMITgcm,~]=DefineGeometry(UserVar,CtrlVar,MITmesh,[],'B');

% We use a linear interpolation to map the Ua draft onto the MITgcm grid. Note that more sophisticated
% methods can be implemented, such as 'data binning'. If the MITgcm tracer points are a subset of the Ua nodes then
% interpolation is not required
Fb = scatteredInterpolant(xUa_old,yUa_old,F_old.b,'linear');
b_forMITgcm = Fb(UserVar.UaMITgcm.MITgcmCGridX(:),UserVar.UaMITgcm.MITgcmCGridY(:));

% finally, we perform a few consistency checks:
% -> b_forMITgcm=0 for open ocean
% -> B_forMITgcm = b_forMITgcm whereever the mask indicates that the
% ice is grounded
% -> B_forMITgcm < b_forMITgcm whereever the mask indicates that the
% ice is afloat. If this is not the case, then the bed is carved
% away
% -> b_forMITgcm<0 wherever the mask indicates that the ice is afloat.
%    If this is not the case, the mask is edited to say the ice is
%    grounded, and the draft is set to the bathymetry.

disp('Running consistency checks');

disp(['There are ',num2str(nnz((mask_forMITgcm==2).*(b_forMITgcm~=0))),' open-ocean points with nonzero ice shelf draft']);
b_forMITgcm(mask_forMITgcm==2) = 0;

disp(['There are ',num2str(nnz((mask_forMITgcm==0).*(B_forMITgcm~=b_forMITgcm))),' grounded points where ice draft does not equal bedrock depth']);
B_forMITgcm(mask_forMITgcm==0) = b_forMITgcm(mask_forMITgcm==0);

disp(['There are ',num2str(nnz((mask_forMITgcm==1).*(B_forMITgcm>=b_forMITgcm))),' ice shelf points with negative water column thickness']);
Ierr = find((mask_forMITgcm==1).*(B_forMITgcm>=b_forMITgcm));
B_forMITgcm(Ierr) = b_forMITgcm(Ierr)-1;

disp(['There are ',num2str(nnz((mask_forMITgcm==1).*(b_forMITgcm>0))),' ice shelf points with positive draft']);
Ipos = find((mask_forMITgcm==1).*(b_forMITgcm>0));
b_forMITgcm(Ipos) = B_forMITgcm(Ipos);
mask_forMITgcm(Ipos) = 0;

%% make sure that output fields are 2D
mask_forMITgcm = reshape(mask_forMITgcm,nx,ny);
B_forMITgcm = reshape(B_forMITgcm,nx,ny);
b_forMITgcm = reshape(b_forMITgcm,nx,ny);

figure; pcolor(lonCMIT-650,latCMIT-650,mask_forMITgcm); shading flat
hold on;
plot(MUA_new.Boundary.x,MUA_new.Boundary.y,'-k');
PlotGroundingLines(CtrlVar,MUA_new,GF_new,[],[],[],'w');

%% now save B, b and mask
%save([UserVar.UaMITgcm.UaOutputDirectory,'/',UserVar.UaMITgcm.UaDraftFileName],'B_forMITgcm','b_forMITgcm','mask_forMITgcm','-v6');
save(['./',UserVar.UaMITgcm.UaDraftFileName],'B_forMITgcm','b_forMITgcm','mask_forMITgcm','-v6');

