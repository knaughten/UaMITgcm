function [UserVar,CtrlVar,MeshBoundaryCoordinates]=Ua2D_InitialUserInput(UserVar,CtrlVar)

%%
CtrlVar.Experiment=UserVar.UaMITgcm.Experiment;   
%% Types of run
%
CtrlVar.TimeDependentRun=1; 
CtrlVar.TotalNumberOfForwardRunSteps=10e10; % an arbitrary large number
CtrlVar.TotalTime=UserVar.UaMITgcm.runTime;
CtrlVar.Restart=1;

CtrlVar.dt = 1e-3;
CtrlVar.RestartTime=0; 
CtrlVar.ResetTime=1;
CtrlVar.ResetTimeStep=0;    % perhaps this has to be reconsidered if model has issues converging

CtrlVar.UaOutputsDt = UserVar.UaMITgcm.UaOutputTimes; 
            % times (in years) at which Ua needs to produce output

CtrlVar.ATStimeStepTarget = UserVar.UaMITgcm.ATStimeStepTarget;
CtrlVar.WriteRestartFile = 1;  

%% parallel settings
myCluster = parcluster('local') ;  
myCluster.NumWorkers = 6;
saveProfile(myCluster);

% CtrlVar.Parallel.uvhAssembly.parfor.isOn=1;     % assembly over integration points done in parallel using parfor
% CtrlVar.Parallel.uvhAssembly.spmd.isOn=1;       % assembly in parallel using spmd over sub-domain (domain decomposition)  
% CtrlVar.Parallel.uvhAssembly.spmd.nWorkers=[];  % If left empty, all workers available are used
% CtrlVar.Parallel.uvAssembly.spmd.isOn=1;       % assembly in parallel using spmd over sub-domain (domain decomposition)  
% CtrlVar.Parallel.uvAssembly.spmd.nWorkers=[]; 

%% Reading in mesh
CtrlVar.ReadInitialMesh=0;    % if true then read FE mesh (i.e the MUA variable) directly from a .mat file
                              % unless the adaptive meshing option is used, no further meshing is done.
CtrlVar.ReadInitialMeshFileName='AdaptMesh.mat';
CtrlVar.SaveInitialMeshFileName='NewMeshFile.mat';

xd=640e3; xu=0e3 ; yr=0 ; yl=80e3 ;  
MeshBoundaryCoordinates=[xu yr ; xu yl ; xd yl ; xd yr];

%% Plotting options
CtrlVar.doplots=0;
CtrlVar.PlotMesh=0; 
CtrlVar.PlotBCs=0;
CtrlVar.WhenPlottingMesh_PlotMeshBoundaryCoordinatesToo=1;
CtrlVar.doRemeshPlots=0;
CtrlVar.PlotXYscale=1000; 
%%

CtrlVar.TriNodes=3;
CtrlVar.kH=1;
CtrlVar.nip=6;
CtrlVar.niph=6;

CtrlVar.NameOfRestartFiletoWrite=[CtrlVar.Experiment,'-RestartFile.mat'];
CtrlVar.NameOfRestartFiletoRead=CtrlVar.NameOfRestartFiletoWrite;

%% adapt mesh
CtrlVar.AdaptMesh=1;         %
CtrlVar.InfoLevelAdaptiveMeshing=1;
CtrlVar.GmshMeshingAlgorithm=8;     % see gmsh manual

% CtrlVar.MeshSizeMax=20e3; % max element size (corse resolution)
% CtrlVar.MeshSize=20e3;       % over-all desired element size
% CtrlVar.MeshSizeMin=2e3;   % min ele size (corse resolution)
CtrlVar.MeshSize=5e3;       % over-all desired element size
CtrlVar.MeshSizeMax=5e3;    % max element size
CtrlVar.MeshSizeMin=0.25e3;

% reasonably fine mesh resolution
%
%CtrlVar.MeshSizeMax=8e3;    % max element size
%CtrlVar.MeshSizeMin=200;    % min element size

CtrlVar.MaxNumberOfElements=250e3;           % max number of elements. If #elements larger then CtrlMeshSize/min/max are changed


CtrlVar.SaveAdaptMeshFileName='AdaptMesh.mat';
CtrlVar.SaveAdaptMeshFileName=[];          % file name for saving adapt mesh. If left empty, no file is written

CtrlVar.MeshRefinementMethod='explicit:local:newest vertex bisection';
%CtrlVar.MeshRefinementMethod='explicit:local';
%CtrlVar.MeshRefinementMethod='explicit:global';


CtrlVar.LocalAdaptMeshSmoothingIterations=0;
CtrlVar.sweep=0;

CtrlVar.AdaptMeshInitial=1 ;       % if true, then a remeshing will always be performed at the inital step
CtrlVar.AdaptMeshAndThenStop=0;    % if true, then mesh will be adapted but no further calculations performed


I=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='effective strain rates';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=0.01;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;


I=I+1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='effective strain rates gradient';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=0.001/1000;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=true;


I=I+1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='flotation';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=0.001;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;

I=I+1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='thickness gradient';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=0.001;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=true;

I=I+1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='upper surface gradient';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=0.01;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;


I=I+1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='lower surface gradient';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=0.01;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;


I=I+1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='|dhdt|';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=10;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;

I=I+1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='dhdt gradient';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=1/1000;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=CtrlVar.MeshSizeMin;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;

  
% CtrlVar.AdaptMeshRunStepInterval=1;  % number of run-steps between mesh adaptation
% CtrlVar.AdaptMeshMaxIterations=100;
% CtrlVar.AdaptMeshUntilChangeInNumberOfElementsLessThan=10;
% CtrlVar.MeshAdapt.GLrange=[10000 5000 ; 3000 CtrlVar.MeshSizeMin];
CtrlVar.AdaptMeshRunStepInterval=100;  % number of run-steps between mesh adaptation
CtrlVar.AdaptMeshMaxIterations=5;
CtrlVar.AdaptMeshUntilChangeInNumberOfElementsLessThan=10;
CtrlVar.MeshAdapt.GLrange=[10000 5000 ; 5000 1000 ; 3000 CtrlVar.MeshSizeMin];

%% Pos. thickness constraints
CtrlVar.ThickMin=1; % minimum allowed thickness without (potentially) doing something about it
CtrlVar.ResetThicknessToMinThickness=0;  % if true, thickness values less than ThickMin will be set to ThickMin
CtrlVar.ThicknessConstraints=1  ;        % if true, min thickness is enforced using active set method
CtrlVar.ThicknessConstraintsItMax=5  ; 


end
