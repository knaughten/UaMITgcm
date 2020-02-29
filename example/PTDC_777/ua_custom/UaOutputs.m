function UserVar=UaOutputs(UserVar,CtrlVar,MUA,BCs,F,l,GF,InvStartValues,InvFinalValues,Priors,Meas,BCsAdjoint,RunInfo)
%%
% This routine is called during the run and can be used for saving and/or plotting data.
% 
%   UserVar=UaOutputs(UserVar,CtrlVar,MUA,BCs,F,l,GF,InvStartValues,InvFinalValues,Priors,Meas,BCsAdjoint,RunInfo)
%
% Write your own version of this routine and put it in you local run directory.
% 
% Inputs:
% 
%   BCs             Structure with all boundary conditions
%   UaVars          A structure with fields such as
%                   s, b, S, B, rho, rhow, ub, vb, ud, vd, AGlen, n , C, m , as, ab, g
%   l               Lagrange parameters related to the enforcement of boundary
%                   conditions.
%   GF              Grounding floating mask for nodes and elements.
%
% If preferred to work directly with the variables rather than the respective fields of the structure 
% `UaVars', then`UaVars' can easily be converted into variables using v2struc.
%
%
v2struct(F);
time=CtrlVar.time; 
    
% check if folder 'UaOutputsDirectory' exists, if not create
if exist(fullfile(cd,UserVar.UaMITgcm.UaOutputDirectory),'dir')~=7
    mkdir(UserVar.UaMITgcm.UaOutputDirectory) ;
end

% write output in matlab or netcdf format

if strcmp(UserVar.UaMITgcm.UaOutputFormat,'matlab')

    DaysSinceStart = num2str(sprintf('%04d',round(time*365.25)));
    FileName=sprintf([UserVar.UaMITgcm.UaOutputDirectory,'/',CtrlVar.Experiment,'_',...
        UserVar.UaMITgcm.StartYear,UserVar.UaMITgcm.StartMonth,'_',DaysSinceStart]);
    fprintf(' Saving data in %s \n',FileName);
    save(FileName,'UserVar','CtrlVar','MUA','time','s','b','S','B','h','ub','vb','C','dhdt','AGlen','m','n','rho','rhow','as','ab','GF');
    
elseif strcmp(UserVar.UaMITgcm.UaOutputFormat,'netcdf')
    
    %% add here for netcdf output - use MISOMIP code
    
else
    
    error('Unknown case for writing Ua output');
    return
    
end

if strcmp(CtrlVar.UaOutputsInfostring,'Last call')==1

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

[~,~,F_new,~,~]=MapFbetweenMeshes(UserVar,[],CtrlVar,MUA_old,MUA_new,F_old,BCs_old,l_old,[]);
GF_new = GL2d(F_new.B,F_new.S,F_new.h,F_new.rhow,F_new.rho,MUA_new.connectivity,CtrlVar);

%    [MUA_new.coordinates,MUA_new.connectivity]=FE2dRefineMesh(MUA_old.coordinates,MUA_old.connectivity);
%    MUA_new=CreateMUA(CtrlVar,MUA_new.connectivity,MUA_new.coordinates);

%    [UserVar,~,F_new,~,~]=MapFbetweenMeshes(UserVar,RunInfo,CtrlVar,MUA_old,MUA_new,F_old,BCs_old,l_old);
%    GF_new = GL2d(F_new.B,F_new.S,F_new.h,F_new.rhow,F_new.rho,MUA_new.connectivity,CtrlVar);

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
    [MeltNodesNew,~] = SpecifyMeltNodes(CtrlVar,MUA_new,GF_new);
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
    J = inpoly([lonCMIT(:) latCMIT(:)],[MUA_new.Boundary.x(I(ii)+1:I(ii+1)-1) MUA_new.Boundary.y(I(ii)+1:I(ii+1)-1)]);
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

    %% now save B, b and mask
    save([UserVar.UaMITgcm.UaOutputDirectory,'/',UserVar.UaMITgcm.UaDraftFileName],'B_forMITgcm','b_forMITgcm','mask_forMITgcm','-v6');
end
