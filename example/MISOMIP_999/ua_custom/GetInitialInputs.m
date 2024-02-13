
function [UserVar,CtrlVar]=GetInitialInputs(UserVar,CtrlVar,varargin)
    
    %% JDR 13/02/2024: remove these checks because they do not work with the compiled
    %% version of Ua-MITgcm. Users should make sure they provide DefineInitialInputs.m
    %% with the correct number of input/output arguments, as specified below
    % 
    % OldInputFile="Ua2D_InitialUserInput.m" ; 
    % NewInputFile="DefineInitialInputs.m" ; 
    % 
    % if exist(OldInputFile,'file')==2  && ~(exist(NewInputFile,'file')==2)
    % 
    %     warning("OldInputFormat:Ua2D_InitialUserInput","Ua2D_InitialUserInput.m  no longer used. Rename that file to DefineInitialInputs.m")
    % 
    % end
    % 
    % 
    % InputFile="DefineInitialInputs.m" ;
    % 
    % 
    % TestIfInputFileInWorkingDirectory(InputFile) ;
    % 
    % 
    % % Get user-defined parameter values
    % %  CtrlVar,UsrVar,Info,UaOuts
    % if nargin("DefineInitialInputs.m")>2
    %     [UserVar,CtrlVar,MeshBoundaryCoordinates]=DefineInitialInputs(UserVar,CtrlVar,varargin{:});
    % else
    %     [UserVar,CtrlVar,MeshBoundaryCoordinates]=DefineInitialInputs(UserVar,CtrlVar);
    % end
    
    [UserVar,CtrlVar,MeshBoundaryCoordinates]=DefineInitialInputs(UserVar,CtrlVar);
    
    CtrlVar.MeshBoundaryCoordinates=MeshBoundaryCoordinates;
    
    
end
