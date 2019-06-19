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

time=365.25*CtrlVar.time; %time in days

fprintf('Output requested at %s\n',num2str(UserVar.UaMITgcm.UaOutputTimes));
fprintf('Current runtime is %s\n',num2str(time));

if min(abs(UserVar.UaMITgcm.UaOutputTimes-time))<CtrlVar.dtmin %% check if we need to write output
  
    v2struct(F);
    % check if folder 'UaOutputsDirectory' exists, if not create
    if exist(fullfile(cd,UserVar.UaMITgcm.UaOutputDirectory),'dir')~=7
        mkdir(UserVar.UaMITgcm.UaOutputDirectory) ;
    end

    % write output in matlab or netcdf format
    DaysSinceStart = num2str(sprintf('%04d',round(time)));
    FileName=sprintf([UserVar.UaMITgcm.UaOutputDirectory,'/',CtrlVar.Experiment,'_',...
            UserVar.UaMITgcm.StartYear,UserVar.UaMITgcm.StartMonth,'_',DaysSinceStart]);
    fprintf(' Saving data in %s \n',FileName);
        
    if strcmp(UserVar.UaMITgcm.UaOutputFormat,'matlab')

        save(FileName,'UserVar','CtrlVar','MUA','time','s','b','S','B','h','ub','vb','C','dhdt','AGlen','m','n','rho','rhow','as','ab','GF');

    elseif strcmp(UserVar.UaMITgcm.UaOutputFormat,'netcdf')


        %% add here for netcdf output

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

        xUa_new = MUAnew.coordinates(:,1); yUa_new = MUAnew.coordinates(:,2);
        xUa_old = MUAold.coordinates(:,1); yUa_old = MUAold.coordinates(:,2);
        
        %% check if MITgcm grid is lat/lon or polar stereographic. If lat/lon, convert Ua coordinates to lat/lon.

        lonMIT = UserVar.UaMITgcm.MITgcmGridX;
        latMIT = UserVar.UaMITgcm.MITgcmGridY;
        if (all(lonMIT(:)>=0) && all(lonMIT(:)<=360))
            % Convert from 0-360 range to -180-180 range
            index = lonMIT > 180;
            lonMIT(index) = lonMIT(index) - 360;
        end
        if (all(lonMIT(:)>=-180) && all(lonMIT(:)<=180) && all(latMIT(:)>=-90) && all(latMIT(:)<=90))
            [xMIT,yMIT] = ll2psxy(latMIT,lonMIT,-71,0);
            [latUa_new,lonUa_new] = psxy2ll(xUa_new,yUa_new,-71,0);
        else
            xMIT = lonMIT;  yMIT = latMIT;
            lonUa_new = xUa_new;    latUa_new = yUa_new;      
        end
        [XMIT,YMIT] = ndgrid(xMIT,yMIT);
        [nx,ny] = size(XMIT);
        
        %% original MITgcm grid (either lat/lon or polar stereographic) is always assumed to be rectangular 
        dX = lonMIT(2,1)-lonMIT(1,1);
        dY = latMIT(1,2)-latMIT(1,1);

        Mask = 0*XMIT(:);

        % Generate edges of regular MIT boxes
        MITXedges = [lonMIT(1,1)-dX/2:dX:lonMIT(end,1)+dX/2];
        MITYedges = [latMIT(1,1)-dY/2:dY:latMIT(1,end)+dY/2];

        % Assign ice shelf mask
        % criterion: every MIT cell that countains melt nodes is given mask value 1
        % (ice shelf)
        [MeltNodesNew,~]=SpecifyMeltNodes(CtrlVar,MUAnew,GFnew);
        [Nmeltnodes,~,~] = histcounts2(lonUa_new(MeltNodesNew),latUa_new(MeltNodesNew),MITXedges,MITYedges);
        Mask(Nmeltnodes>0)=1;

        % Assign open ocean mask
        % criterion: every MIT cell that does not countain any Ua nodes is given mask value 2
        % (open ocean)
        [NUanodes,~,~] = histcounts2(lonUa_new,latUa_new,MITXedges,MITYedges);
        Mask(NUanodes==0) = 2;

        mask_forMITgcm = reshape(Mask,nx,ny);

        %% Generate b and B fields
        % Obtain bed at MITgcm tracer points via DefineGeometry
        MITmesh.coordinates = [XMIT(:) YMIT(:)];
        [~,~,~,~,B_forMITgcm,~]=DefineGeometry(UserVar,CtrlVar,MITmesh,[],'B');

        % We use a linear interpolation to map the Ua draft onto the MITgcm grid. Note that more sophisticated
        % methods can be implemented, such as 'data binning'. If the MITgcm tracer points are a subset of the Ua nodes then
        % interpolation is not required
        Fb = scatteredInterpolant(xUa_old,yUa_old,F_old.b,'linear');
        b_forMITgcm = Fb(XMIT,YMIT);

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
        save([UserVar.UaMITgcm.UaOutputDirectory,'/',UserVar.UaMITgcm.UaDraftFileName],'B_forMITgcm','b_forMITgcm','mask_forMITgcm');
    end
end
        
