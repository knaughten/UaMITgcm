function [UserVar,CtrlVar,MeshBoundaryCoordinates]=DefineInitialInputs(UserVar,CtrlVar)

UserVar.Geometry = 'Bedmachinev2';
UserVar.GeometryInterpolants = 'GriddedInterpolants_Bedmachine2020-07-15.mat';
UserVar.NameOfFileForReadingSlipperinessEstimate = 'AMUND_gsC100000_gsA100000_gaC1_gaA250_kH100_Weertman_m3_Bedmachine20200715_C-Estimate.mat';
UserVar.NameOfFileForReadingAGlenEstimate = 'AMUND_gsC100000_gsA100000_gaC1_gaA250_kH100_Weertman_m3_Bedmachine20200715_AGlen-Estimate.mat';
UserVar.RACMO_SMB = 'SMB_RACMO_1979_2013.mat';
UserVar.SlidingLaw = 'Weertman';

%
CtrlVar.TimeDependentRun=1;  % {0|1} if true (i.e. set to 1) then the run is a forward transient one, if not
CtrlVar.TotalNumberOfForwardRunSteps=10e10; % an arbitrary large number
CtrlVar.TotalTime=UserVar.UaMITgcm.runTime;
CtrlVar.Restart=1;

%
CtrlVar.dt=5e-3;
CtrlVar.ResetTime=1;
CtrlVar.RestartTime=0;
CtrlVar.ResetTimeStep=1;

%
CtrlVar.Parallel.uvhAssembly.parfor.isOn=0;     % assembly over integration points done in parallel using parfor
CtrlVar.Parallel.uvhAssembly.spmd.isOn=0;       % assembly in parallel using spmd over sub-domain (domain decomposition)  
CtrlVar.Parallel.uvhAssembly.spmd.nWorkers=[];  % If left empty, all workers available are used
CtrlVar.Parallel.uvAssembly.spmd.isOn=0;       % assembly in parallel using spmd over sub-domain (domain decomposition)  
CtrlVar.Parallel.uvAssembly.spmd.nWorkers=[];  % If left empty, all workers available are used
CtrlVar.Parallel.isTest=false;

%
CtrlVar.TriNodes=3;
CtrlVar.nip = 6;
CtrlVar.niph = 6;
CtrlVar.kH = 100;
CtrlVar.AdaptMesh=1;
CtrlVar.ReadInitialMesh=0;

% timestepping
CtrlVar.ATSdtMax = UserVar.UaMITgcm.ATStimeStepTarget; 
CtrlVar.dtmin = 1e-10;
CtrlVar.ATStimeStepFactorUp=1.5;
CtrlVar.ATStimeStepFactorDown=5;
CtrlVar.ATSTargetIterations=4;

%
CtrlVar.NRitmax=20;
CtrlVar.uvhDesiredWorkAndForceTolerances=[inf 1e-12];
CtrlVar.uvhDesiredWorkOrForceTolerances=[inf 1e-12];

%
load AMUND_BoundaryCoordinates_Bedmachinev2 MeshBoundaryCoordinates

%
CtrlVar.DefineOutputsDt = UserVar.UaMITgcm.UaOutputTimes;
            % times (in years) at which Ua needs to call UaOutputs

CtrlVar.WriteRestartFile=1;
CtrlVar.WriteRestartFileInterval=50;
CtrlVar.NameOfRestartFiletoWrite=[UserVar.UaMITgcm.Experiment,'-RestartFile.mat'];
CtrlVar.NameOfRestartFiletoRead=CtrlVar.NameOfRestartFiletoWrite;

%
CtrlVar.SlidingLaw = UserVar.SlidingLaw;
CtrlVar.NameOfFileForReadingSlipperinessEstimate=UserVar.NameOfFileForReadingSlipperinessEstimate;
CtrlVar.NameOfFileForSavingSlipperinessEstimate='';
CtrlVar.CisElementBased=0;   
CtrlVar.AGlenisElementBased=0;
CtrlVar.NameOfFileForReadingAGlenEstimate=UserVar.NameOfFileForReadingAGlenEstimate;
CtrlVar.NameOfFileForSavingAGlenEstimate='';

%
CtrlVar.GeometricalVarsDefinedEachTransienRunStepByDefineGeometry='SB';

%
CtrlVar.doplots=0;
CtrlVar.PlotWaitBar=0;
CtrlVar.PlotOceanLakeNodes=0;
CtrlVar.PlotMesh=0;  CtrlVar.PlotBCs=0;

%
CtrlVar.MeltNodesDefinition='edge-wise';
CtrlVar.MassBalanceGeometryFeedback = 0;
CtrlVar.MeltRateFactor=1;

%
CtrlVar.MeshSizeMax=10e3;
CtrlVar.MeshSize=7.5e3;
CtrlVar.MeshSizeMin=CtrlVar.MeshSize/10;
CtrlVar.MeshSizeBoundary=CtrlVar.MeshSize;
CtrlVar.MeshRefinementMethod='explicit:local:newest vertex bisection';
CtrlVar.MeshAdapt.GLrange=[4000 1000 ; 2000 750];

%
CtrlVar.RefineMeshOnStart=0;
CtrlVar.InfoLevelAdaptiveMeshing=1;                                            
CtrlVar.AdaptMeshInitial=1  ; % remesh in first iteration (Itime=1)  even if mod(Itime,CtrlVar.AdaptMeshInterval)~=0.
CtrlVar.AdaptMeshAndThenStop=0;    % if true, then mesh will be adapted but no further calculations performed
                                   % useful, for example, when trying out different remeshing options (then use CtrlVar.doAdaptMeshPlots=1 to get plots)
CtrlVar.AdaptMeshMaxIterations=2;
CtrlVar.AdaptMeshUntilChangeInNumberOfElementsLessThan = 20;
CtrlVar.SaveAdaptMeshFileName='MeshFileAdapt';    %  file name for saving adapt mesh. If left empty, no file is written
CtrlVar.AdaptMeshRunStepInterval=50 ; % remesh whenever mod(Itime,CtrlVar.AdaptMeshInterval)==0
CtrlVar.doAdaptMeshPlots=0; 

%
CtrlVar.ThicknessConstraints=0;
CtrlVar.ResetThicknessToMinThickness=1;  % change this later on
CtrlVar.ThickMin=1;
CtrlVar.ThicknessConstraintsItMax=1; 


end
