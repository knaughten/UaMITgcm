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
if exist(fullfile(cd,UserVar.UaMITgcm.UaOutputsDirectory),'dir')~=7
    mkdir(UserVar.UaMITgcm.UaOutputsDirectory) ;
end

% write output in matlab or netcdf format

if strcmp(UserVar.UaMITgcm.OutputFormat,'matlab')
    
    FileName=sprintf('%s/%07i-Nodes%i-Ele%i-Tri%i-kH%i-%s.mat',...
    UserVar.UaMITgcm.UaOutputsDirectory,round(time*365.25),MUA.Nnodes,MUA.Nele,MUA.nod,1000*CtrlVar.kH,CtrlVar.Experiment);
    fprintf(' Saving data in %s \n',FileName)
    save(FileName,'UserVar','CtrlVar','MUA','time','s','b','S','B','h','ub','vb','C','dhdt','AGlen','m','n','rho','rhow','as','ab','GF');
    
elseif strcmp(UserVar.UaMITgcm.OutputFormat,'netcdf')
    
    %% add here for netcdf output - use MISOMIP code
    
else
    
    error('Unknown case for writing Ua output');
    return
    
end

if strcmp(CtrlVar.UaOutputsInfostring,'Last call')==1

    % generate geometry and mask for MITgcm, interpolated on MITgcm tracer grid
    Fb = scatteredInterpolant(MUA.coordinates(:,1),MUA.coordinates(:,2),b);
    b_MIT = Fb(UserVar.UaMITgcm.MITgcmGridX,UserVar.UaMITgcm.MITgcmGridY);

    
    
else

        
end