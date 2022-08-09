function UserVar=DefineOutputs(UserVar,CtrlVar,MUA,BCs,F,l,GF,InvStartValues,InvFinalValues,Priors,Meas,BCsAdjoint,RunInfo)


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
    save(FileName,'UserVar','CtrlVar','MUA','F','GF');
    
elseif strcmp(UserVar.UaMITgcm.UaOutputFormat,'netcdf')
    
    %% add here for netcdf output - use MISOMIP code
    
else
    
    error('Unknown case for writing Ua output');
    return
    
end

%% initialize coordinates
% MITgcm centers
lonCMIT = UserVar.UaMITgcm.MITgcmCGridlon; % 2d arrays
latCMIT = UserVar.UaMITgcm.MITgcmCGridlat;
[nx,ny] = size(lonCMIT);
% MITgcm edges
lonEMIT = [UserVar.UaMITgcm.MITgcmGGridlon(:,1); 2*lonCMIT(end,1)-UserVar.UaMITgcm.MITgcmGGridlon(end,1)];
latEMIT = [UserVar.UaMITgcm.MITgcmGGridlat(1,:) 2*latCMIT(1,end)-UserVar.UaMITgcm.MITgcmGGridlat(1,end)];
[lonEMIT,latEMIT] = ndgrid(lonEMIT,latEMIT);
[xEMIT,yEMIT] = ll2psxy(latEMIT,lonEMIT,-71,0);
% Ua boundary nodes
[UaBlat,UaBlon]=psxy2ll(MUA.Boundary.x,MUA.Boundary.y,-71,0);

%% Generate b and B fields for MITgcm
% Obtain bed via linear interpolation from Ua B field. We use a linear 
% interpolation to map the Ua draft onto the MITgcm grid. Note that more 
% sophisticated methods can be implemented, such as 'data binning'. If the 
% MITgcm tracer points are a subset of the Ua nodes then interpolation is 
% not required. 

% first, close up lakes upstream of the main GL
[~,OceanNodes] = LakeOrOcean3(CtrlVar,MUA,GF);
F.b(~OceanNodes) = F.B(~OceanNodes);

% now interpolate onto MIT grid
FB = scatteredInterpolant(MUA.coordinates(:,1),MUA.coordinates(:,2),F.B,'linear');
B_forMITgcm = FB(UserVar.UaMITgcm.MITgcmCGridX(:),UserVar.UaMITgcm.MITgcmCGridY(:));

% for MITgcm tracer points outside Ua domain replace with Bedmachine data via DefineGeometry
I_outsideUa = find(~inpoly([UserVar.UaMITgcm.MITgcmCGridX(:),UserVar.UaMITgcm.MITgcmCGridY(:)],[MUA.Boundary.x(:),MUA.Boundary.y(:)]));
MITmesh.coordinates = [UserVar.UaMITgcm.MITgcmCGridX(I_outsideUa) UserVar.UaMITgcm.MITgcmCGridY(I_outsideUa)];
[~,~,~,~,B_forMITgcm(I_outsideUa),~]=DefineGeometry(UserVar,CtrlVar,MITmesh,[],'B');

Fb = scatteredInterpolant(MUA.coordinates(:,1),MUA.coordinates(:,2),F.b,'linear');
b_forMITgcm = Fb(UserVar.UaMITgcm.MITgcmCGridX(:),UserVar.UaMITgcm.MITgcmCGridY(:));
b_forMITgcm(I_outsideUa) = 0;

%% Generate mask for MITgcm: 

% Generate triangulation of MITgcm cells. Edges of triangulation correspond
% to edges of MITgcm cells
MITgcm_connectivity = delaunay(lonEMIT(:),latEMIT(:));

%% First identify open ocean cells
% temporary mask: 0 for nodes outside Ua domain, 1 inside Ua boundary
I_edgenodesoutsideUa = ~inpoly([lonEMIT(:) latEMIT(:)],[UaBlon(:) UaBlat(:)]); 
Mask_tmp = 0*lonEMIT+1;
Mask_tmp(I_edgenodesoutsideUa) = 0;
% for graph, only retain MITgcm elements that completely fall outside Ua domain boundary
Mask_ele = sum(Mask_tmp(MITgcm_connectivity),2);
TRI = MITgcm_connectivity(find(Mask_ele==0),:);
% elements crossing the ice front for later:
Iele_crossingicefront = find(Mask_ele>0 & Mask_ele<3);

% create undirected graph
G = graph(TRI,TRI(:,[2 3 1]));
% calculate the connected components of the graph
bins=conncomp(G) ;

% define indices of OceanBoundaryNodes at northern boundary for flooding
% === This is specific to the AMUND setup ===
OceanBoundaryNodes = find(latEMIT == max(latEMIT(:)));

% initialise arrays
Nnum = zeros((nx+1)*(ny+1),1);
OpenOceanNodes = zeros((nx+1)*(ny+1),1);
Nnum(OceanBoundaryNodes) = 1;

% loop through ocean boundary nodes until each one has been checked for
% connected open ocean nodes. Once this is done the only 'open ocean' nodes are
% nodes outside the Ua domain, and grounded
while sum(Nnum)>0
    
    NodeSeed = find(Nnum,1,'first');
    ID=bins(NodeSeed) ;
    % list of all connected nodes to this ocean boundary node
    nodes=find(bins==ID);
    % add these to the OpenOcean list
    OpenOceanNodes(nodes) = 1;
    % also remove these from the list of boundary nodes to save time where
    % one ice shelf has multiple nodes on the ocean boundary
    Nnum(nodes) = 0;
    
end

% figure; hold on;
% 
% triplot(TRI,lonEMIT,latEMIT,'k');
% plot(UaBlon,UaBlat,'-xk');
% CtrlVar.PlotGLs = 0;
% [xGL,yGL,GLgeo]=PlotGroundingLines(CtrlVar,MUA,GF);
% [latGL,lonGL] = psxy2ll(xGL,yGL,-71,0);
% plot(lonGL,latGL,'-xk');

%% Now identify ice shelf nodes
% temporary mask: 0 for nodes outside Ua domain or with b>B+1, 1 inside remainder of the boundary
B_elecornernodes = FB(xEMIT,yEMIT);
b_elecornernodes = Fb(xEMIT,yEMIT);

Mask_tmp = 0*lonEMIT+1;
Mask_tmp([find(I_edgenodesoutsideUa);find(b_elecornernodes>B_elecornernodes+1)]) = 0;

% for graph, only retain elements that are not fully grounded
Mask_ele = sum(Mask_tmp(MITgcm_connectivity),2);

% conservative approach near ice front:
Iele_fullyfloatingnearIF = intersect(find(Mask_ele==0),Iele_crossingicefront);
% include all not-fully grounded elements elsewhere
Iele_notfullygrounded = setdiff(find(Mask_ele<3),Iele_crossingicefront);
TRI = MITgcm_connectivity([Iele_fullyfloatingnearIF(:);Iele_notfullygrounded(:)],:);

% create undirected graph
G=graph(TRI,TRI(:,[2 3 1]));
% calculate the connected components of the graph
bins=conncomp(G) ;

% initialise arrays
Nnum = zeros(nx*ny,1);
OpenOceanIceShelfNodes = zeros(nx*ny,1);
Nnum(OceanBoundaryNodes) = 1;

% loop through ocean boundary nodes until each one has been checked for
% connected ocean nodes
while sum(Nnum)>0
    
    NodeSeed = find(Nnum,1,'first');
    ID=bins(NodeSeed) ;
    % list of all connected nodes to this ocean boundary node
    nodes=find(bins==ID);
    % add these to the OpenOcean list
    OpenOceanIceShelfNodes(nodes) = 1;
    % also remove these from the list of boundary nodes to save time where
    % one ice shelf has multiple nodes on the ocean boundary
    Nnum(nodes) = 0;
    
end

%% Now we are ready to generate the mask
%% In UaMITgcm mask convention is:
% 2 - open ocean
% 1 - ice shelf
% 0 - grounded
Mask_tmp = 0*lonEMIT + 0;
Mask_tmp(OpenOceanNodes==1) = 2;
IceShelfNodes = OpenOceanIceShelfNodes; IceShelfNodes(OpenOceanNodes==1)=0;
Mask_tmp(IceShelfNodes==1) = 1;

%% Reduce size of mask back to MIT grid size by averaging over elements
Mask_tmp = (Mask_tmp(1:end-1,1:end-1)+Mask_tmp(2:end,1:end-1)+Mask_tmp(1:end-1,2:end)+Mask_tmp(2:end,2:end))/4;

%% Now do some cleaning up:
% check that for ice shelf elements, at least 1 corner is afloat
[I_IS,J_IS] = find(Mask_tmp>0 & Mask_tmp<2);

I_err = []; J_err = [];
B_forMITgcm = reshape(B_forMITgcm,nx,ny);
b_forMITgcm = reshape(b_forMITgcm,nx,ny);
for nn=1:numel(I_IS)
    ii = I_IS(nn); jj = J_IS(nn);
    [xC,yC] = ll2psxy([latEMIT(ii,jj) latEMIT(ii+1,jj) latEMIT(ii+1,jj+1) latEMIT(ii,jj+1)],...
        [lonEMIT(ii,jj) lonEMIT(ii+1,jj) lonEMIT(ii+1,jj+1) lonEMIT(ii,jj+1)],-71,0);
    if ~any(FB(xC(:),yC(:))-Fb(xC(:),yC(:))<0)
        %set to grounded
        Mask_tmp(ii,jj) = 0;
        B_forMITgcm(ii,jj) = b_forMITgcm(ii,jj);
    end
end

%% Elements for which at least one corner node is identified as ice shelf, are masked as ice shelf 
% This is generous, but guarantees that floating nodes in Ua are (almost) always part of floating elements in MITgcm
Mask_tmp(Mask_tmp>0 & Mask_tmp<2) = 1;

mask_forMITgcm = Mask_tmp(:);
B_forMITgcm = B_forMITgcm(:);
b_forMITgcm = b_forMITgcm(:);

%% finally, we perform a few consistency checks:
% -> b_forMITgcm = 0 for open ocean
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

%figure; hold on;
%pcolor(lonEMIT(1:end-1,1:end-1),latEMIT(1:end-1,1:end-1),mask_forMITgcm);
%plot(UaBlon,UaBlat,'-xk');
%CtrlVar.PlotGLs = 0;
%[xGL,yGL,GLgeo]=PlotGroundingLines(CtrlVar,MUA,GF);
%[latGL,lonGL] = psxy2ll(xGL,yGL,-71,0);
%plot(lonGL,latGL,'-xk');

%% now save B, b and mask
save([UserVar.UaMITgcm.UaOutputDirectory,'/',UserVar.UaMITgcm.UaDraftFileName],'B_forMITgcm','b_forMITgcm','mask_forMITgcm','-v6');
end
