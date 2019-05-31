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
    load(UserVar.GeometryInterpolants,'FB');
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
    
    % save B, b and mask
    save([UserVar.UaMITgcm.UaOutputDirectory,'/',UserVar.UaMITgcm.UaDraftFileName],'B_forMITgcm','b_forMITgcm','mask_forMITgcm');
         
end
