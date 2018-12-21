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
    
    FileName=sprintf('%s/%07i-Nodes%i-Ele%i-Tri%i-kH%i-%s.mat',...
    UserVar.UaMITgcm.UaOutputDirectory,round(time*365.25),MUA.Nnodes,MUA.Nele,MUA.nod,1000*CtrlVar.kH,CtrlVar.Experiment);
    fprintf(' Saving data in %s \n',FileName)
    save(FileName,'UserVar','CtrlVar','MUA','time','s','b','S','B','h','ub','vb','C','dhdt','AGlen','m','n','rho','rhow','as','ab','GF');
    
elseif strcmp(UserVar.UaMITgcm.UaOutputFormat,'netcdf')
    
    %% add here for netcdf output - use MISOMIP code
    
else
    
    error('Unknown case for writing Ua output');
    return
    
end

if strcmp(CtrlVar.UaOutputsInfostring,'Last call')==1
    
    x = MUA.coordinates(:,1); y = MUA.coordinates(:,2);
    
    %% generate draft and mask for MITgcm, interpolated on MITgcm tracer grid
    %% TO CHECK: bathymetry in MITgcm and Ua need to be the same
    
    % We use a simple linear interpolation method. More sophisticated
    % methods can be implemented, such as 'data binning'
    % If the MITgcm tracer points are a subset of the Ua nodes then
    % interpolation is not required
    Fb = scatteredInterpolant(x,y,b,'linear');
    b_forMITgcm = Fb(UserVar.UaMITgcm.MITgcmGridX,UserVar.UaMITgcm.MITgcmGridY);
    
    % First approximation for MITgcm mask: linear interpolation from Ua mask
    % Note that this will often be a 'minimal' mask, as it will not check
    % what area of the MITgcm tracer cell is afloat. 
    [MeltNodes,~]=SpecifyMeltNodes(CtrlVar,MUA,GF);
        
    ISmask = NaN*x; ISmask(MeltNodes)=1;
    FISmask = scatteredInterpolant(x,y,ISmask,'linear');
    ISmask_forMITgcm_firstapproximation = FISmask(UserVar.UaMITgcm.MITgcmGridX,UserVar.UaMITgcm.MITgcmGridY);
    ISmask_forMITgcm_firstapproximation(isnan(ISmask_forMITgcm_firstapproximation)) = 0;
    % set mask to zero outside Ua domain. Take holes in domain into
    % account, and treat these as grounded.
    I = find(isnan(MUA.Boundary.x));
    if isempty(I)
        J = find(~inpoly([UserVar.UaMITgcm.MITgcmGridX(:) UserVar.UaMITgcm.MITgcmGridY(:)],[MUA.Boundary.x(:) MUA.Boundary.y(:)]));
    else
        I(end+1) = length(MUA.Boundary.x)+1;
        J = find(~inpoly([UserVar.UaMITgcm.MITgcmGridX(:) UserVar.UaMITgcm.MITgcmGridY(:)],[MUA.Boundary.x(1:I(1)-1) MUA.Boundary.y(1:I(1)-1)]));
        for ii=1:length(I)-1
            J2 = find(inpoly([UserVar.UaMITgcm.MITgcmGridX(:) UserVar.UaMITgcm.MITgcmGridY(:)],...
                [MUA.Boundary.x(I(ii)+1:I(ii+1)-1) MUA.Boundary.y(I(ii)+1:I(ii+1)-1)]));
            J = [J(:); J2(:)];
        end
    end
        
    ISmask_forMITgcm_firstapproximation(J) = 0;
            
    % The approximate mask will sometimes indentify cells as 'grounded' whereas they
    % may contain floating Ua nodes due to the interpolation. Here we refine the mask to 
    % change those errors, based on counting the number of floating nodes
    % withing each MITgcm grid box. This is sloppy and very slow, and might have to be improved for large MITgcm
    % grids. One can consider using histcounts2, but this only works for
    % regular grids, which might not be true if the grid is converted
    % from lat/lon to psxy
    dx = UserVar.UaMITgcm.MITgcmGridX(2:end,:)-UserVar.UaMITgcm.MITgcmGridX(1:end-1,:);
    dy = UserVar.UaMITgcm.MITgcmGridY(:,2:end)-UserVar.UaMITgcm.MITgcmGridY(:,1:end-1);
    XEdges = [UserVar.UaMITgcm.MITgcmGridX(1,:)-dx(1,:)/2; UserVar.UaMITgcm.MITgcmGridX(1:end-1,:)+dx/2; UserVar.UaMITgcm.MITgcmGridX(end,:)+dx(end,:)/2];
    XEdges = [XEdges(:,1) XEdges];
    YEdges = [UserVar.UaMITgcm.MITgcmGridY(:,1)-dy(:,1)/2 UserVar.UaMITgcm.MITgcmGridY(:,1:end-1)+dy/2 UserVar.UaMITgcm.MITgcmGridY(:,end)+dy(:,end)/2];
    YEdges = [YEdges(1,:);YEdges]; 
    Nin=[]; Non = [];
    for ii=1:size(UserVar.UaMITgcm.MITgcmGridX,1)
        for jj=1:size(UserVar.UaMITgcm.MITgcmGridX,2)
            [in,on] = inpoly([x(MeltNodes),y(MeltNodes)],...
                [[XEdges(ii,jj) XEdges(ii+1,jj) XEdges(ii+1,jj+1) XEdges(ii,jj+1)]',...
                [YEdges(ii,jj) YEdges(ii+1,jj) YEdges(ii+1,jj+1) YEdges(ii,jj+1)]']);
            Nin(ii,jj) = nnz(in);
            Non(ii,jj) = nnz(on);
        end
    end
    N = Nin-Non;
    
    ISmask_forMITgcm = ISmask_forMITgcm_firstapproximation + (N>=1);
    ISmask_forMITgcm(ISmask_forMITgcm>1) = 1;
    
    b_forMITgcm = b_forMITgcm.*ISmask_forMITgcm;
    
    save([UserVar.UaMITgcm.UaOutputDirectory,'/ua_draft_file.mat'],'b_forMITgcm','ISmask_forMITgcm');
        
end