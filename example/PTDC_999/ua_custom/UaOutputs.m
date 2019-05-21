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
    
    x = MUA.coordinates(:,1); y = MUA.coordinates(:,2);
    X = UserVar.UaMITgcm.MITgcmGridX(:); Y = UserVar.UaMITgcm.MITgcmGridY(:);
    [nx,ny] = size(X);
    dX = UserVar.UaMITgcm.MITgcmGridX(2,1)-UserVar.UaMITgcm.MITgcmGridX(1,1);
    dY = UserVar.UaMITgcm.MITgcmGridY(1,2)-UserVar.UaMITgcm.MITgcmGridY(1,1);
    
    %% generate draft and mask for MITgcm, interpolated onto MITgcm tracer grid
    %% bathymetry in MITgcm and Ua need to be the same, so
    %% ideally we also generate the bathymetry for MITgcm within Ua
    
    load(UserVar.GeometryInterpolants,'FB');
    Bathy = FB(X,Y);

    % We use a linear interpolation to map the Ua draft onto the MITgcm grid. Note that more sophisticated
    % methods can be implemented, such as 'data binning'. If the MITgcm tracer points are a subset of the Ua nodes then
    % interpolation is not required
    Fb = scatteredInterpolant(x,y,b,'linear');
    Draft = 0*Bathy;
    
    % Generate new mask for MITgcm
    Mask = 0*Bathy;
      
    % Assign mask for open ocean
    % criterion: midpoint of tracer cell falls outside Ua domain
    IN = inpoly([X,Y],[MUA.Boundary.x(:) MUA.Boundary.y(:)]);
    Iice = find(IN); Iocean = find(IN==0);
    Mask(Iocean) = 2;

    [GLgeo,GLnodes,GLele]=GLgeometry(MUA.connectivity,MUA.coordinates,GF,CtrlVar);
    [~,LakeNodes]=LakeOrOcean_UaMITgcm(CtrlVar,MUA,GF,GLgeo,GLnodes,GLele);
    Index_LakeNodes = find(LakeNodes==1);
    GF.node(Index_LakeNodes) = 1;

    FGF = scatteredInterpolant(x,y,GF.node);

    % criterion: MIT grid cell is only grounded if all four corner cells are grounded in Ua
    GFMITnodes = FGF(X(Iice)-dX/2,Y(Iice)-dY/2)+FGF(X(Iice)-dX/2,Y(Iice)+dY/2)+...
    FGF(X(Iice)+dX/2,Y(Iice)+dY/2)+FGF(X(Iice)+dX/2,Y(Iice)-dY/2);

    Jshelf = find(GFMITnodes<3.5); Jground = find(GFMITnodes>=3.5);
    Mask(Iice(Jshelf))=1;
    Mask(Iice(Jground))=0;
    %%%%%%%%%%%%%%%%%%%%

    % do consistency checks
    Ishelf=find(Mask==1);
    Iocean=find(Mask==2);

    % areas where ice shelf and open ocean bathymetry are above sea level are
    %set to zero 
    Ishelfocean=[Ishelf(:);Iocean(:)];
    I=Bathy(Ishelfocean)>=0;
    Bathy(Ishelfocean(I))=0;
    Mask(Ishelfocean(I))=0;

    Ishelf=find(Mask==1);
    Iocean=find(Mask==2);
    Igrounded=find(Mask==0);

    Bathy(Igrounded)=0;
    Mask(Igrounded)=0;
    
    Draft(Ishelf)= Fb(X(Ishelf),Y(Ishelf));

    % areas where draft is above sea level or below bathymetry are set to zero
    % and treated as grounded
    I = (Draft>=0 & Draft<Bathy);
    Draft(I)=0; Bathy(I); Mask(I)=0;

    Mask = reshape(Mask,nx,ny);
    Draft = reshape(Draft,nx,ny);
    Bathy = reshape(Bathy,nx,ny);

    B_forMITgcm = Bathy;
    b_forMITgcm = Draft;
    mask_forMITgcm = Mask;
    
    % save B, b and mask
    save([UserVar.UaMITgcm.UaOutputDirectory,'/',UserVar.UaMITgcm.UaDraftFileName],'B_forMITgcm','b_forMITgcm','mask_forMITgcm');
         
end
