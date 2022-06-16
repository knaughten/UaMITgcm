function [UserVar,CtrlVar,MeshBoundaryCoordinates]=Ua2D_InitialUserInput(UserVar,CtrlVar)

UserVar.Geometry = 'Bedmachine_Bamber2009';
UserVar.GeometryInterpolants = 'GriddedInterpolants_sBh_Bedmachine2020-07-15_Bamber2009.mat';
UserVar.FirnInterpolants = 'GriddedInterpolants_Firn_RACMO.mat';
UserVar.NameOfFileForReadingSlipperinessEstimate='PTDC_C.mat';
UserVar.NameOfFileForReadingAGlenEstimate='PTDC_AGlen.mat';
UserVar.RACMO_SMB='SMB_RACMO_1979_2013.mat';
UserVar.SlidingLaw = 'Weertman';

%% Type of run
%
CtrlVar.TimeDependentRun=1; 
CtrlVar.TotalNumberOfForwardRunSteps=10e10; % an arbitrary large number
CtrlVar.TotalTime=UserVar.UaMITgcm.runTime;
CtrlVar.Restart=1;

CtrlVar.dt = 1e-3;
CtrlVar.RestartTime=0; 
CtrlVar.ResetTime=1;
CtrlVar.ResetTimeStep=1;    % perhaps this has to be reconsidered if model has issues converging

% Parallel options
%myCluster = parcluster('local') ;  
%myCluster.NumWorkers = 6;
%saveProfile(myCluster)

CtrlVar.Parallel.uvhAssembly.parfor.isOn=0;     % assembly over integration points done in parallel using parfor
CtrlVar.Parallel.uvhAssembly.spmd.isOn=0;       % assembly in parallel using spmd over sub-domain (domain decomposition)  
CtrlVar.Parallel.uvhAssembly.spmd.nWorkers=[];

% Grid options
CtrlVar.TriNodes=3;
CtrlVar.kH=100;
CtrlVar.nip=6;
CtrlVar.niph=6;
CtrlVar.AdaptMesh=1;

% timestepping
CtrlVar.ATStimeStepTarget = UserVar.UaMITgcm.ATStimeStepTarget; 
CtrlVar.dtmin = 1e-10;
CtrlVar.ATStimeStepFactorUp=2 ;
CtrlVar.ATStimeStepFactorDown=5 ;
CtrlVar.ATSTargetIterations=2;

CtrlVar.InitialDiagnosticStep=1;
CtrlVar.TestUserInputs=0;
CtrlVar.InitialDiagnosticStepAfterRemeshing=1;
CtrlVar.Implicituvh=1;
CtrlVar.TG3=0 ; %CtrlVar.Gamma=1;
CtrlVar.uvhTimeSteppingMethod='supg';

load BoundaryCoordinates MeshBoundaryCoordinates

CtrlVar.UaOutputsDt = UserVar.UaMITgcm.UaOutputTimes;
            % times (in years) at which Ua needs to call UaOutputs

CtrlVar.WriteRestartFile=1;
CtrlVar.WriteRestartFileInterval=50;
CtrlVar.NameOfRestartFiletoWrite=[UserVar.UaMITgcm.Experiment,'-RestartFile.mat'];
CtrlVar.NameOfRestartFiletoRead=CtrlVar.NameOfRestartFiletoWrite;

CtrlVar.SlidingLaw = UserVar.SlidingLaw;
CtrlVar.NameOfFileForReadingSlipperinessEstimate=UserVar.NameOfFileForReadingSlipperinessEstimate;
CtrlVar.NameOfFileForSavingSlipperinessEstimate='';
CtrlVar.Cmin=1e-100;  
CtrlVar.Cmax=1e100;

CtrlVar.NameOfFileForReadingAGlenEstimate=UserVar.NameOfFileForReadingAGlenEstimate;
CtrlVar.NameOfFileForSavingAGlenEstimate='';

CtrlVar.GeometricalVarsDefinedEachTransienRunStepByDefineGeometry='SB';

CtrlVar.doplots=0;
CtrlVar.PlotWaitBar=0;
CtrlVar.PlotOceanLakeNodes=0;
CtrlVar.PlotMesh=0;  CtrlVar.PlotBCs=0;

CtrlVar.MeltNodesDefinition='edge-wise';
CtrlVar.MassBalanceGeometryFeedback = 0;
CtrlVar.MeltRateFactor=1;
%CtrlVar.MeltReductionTime=Inf;

CtrlVar.MeshSizeMax=20e3;
CtrlVar.MeshSize=20e3;
CtrlVar.MeshSizeMin=CtrlVar.MeshSize/40;
%CtrlVar.MeshSizeFastFlow=CtrlVar.MeshSizeMax/10;
%CtrlVar.MeshSizeIceShelves=CtrlVar.MeshSizeMax/10;
CtrlVar.MeshSizeBoundary=CtrlVar.MeshSize;

%     CtrlVar.GmshGeoFileAdditionalInputLines{1}='Field[7] = Box;'; % these lines are added to the gmsh .geo input file each time such a file is created
%     CtrlVar.GmshGeoFileAdditionalInputLines{2}='Field[7].VIn = 10e3;';
%     CtrlVar.GmshGeoFileAdditionalInputLines{3}='Field[7].VOut = 20e3;';
%     CtrlVar.GmshGeoFileAdditionalInputLines{4}='Field[7].XMin = -1700e3;';
%     CtrlVar.GmshGeoFileAdditionalInputLines{5}='Field[7].XMax = -1200e3;';
%     CtrlVar.GmshGeoFileAdditionalInputLines{6}='Field[7].YMin = -600e3;';
%     CtrlVar.GmshGeoFileAdditionalInputLines{7}='Field[7].YMax = -50e3;';
%     CtrlVar.GmshGeoFileAdditionalInputLines{8}='Field[10] = Min;';
%     CtrlVar.GmshGeoFileAdditionalInputLines{9}='Field[10].FieldsList = {7};';
%     CtrlVar.GmshGeoFileAdditionalInputLines{10}='Background Field = 10;';

%CtrlVar.ReadInitialMeshFileName='MeshFileAdapt_68410Ele_34746Nod.mat';
%CtrlVar.ReadInitialMeshFileName='MeshFileAdapt_138451Ele_69814Nod.mat';
%CtrlVar.ReadInitialMeshFileName='MeshFileAdapt_149786Ele_75526Nod.mat';
CtrlVar.ReadInitialMesh=0;
%CtrlVar.ReadInitialMeshFileName='MeshFileAdapt_Ele135446_Nod3.mat';
%CtrlVar.SaveInitialMeshFileName='MeshFile.mat';

CtrlVar.OnlyMeshDomainAndThenStop=0; % if true then only meshing is done and no further calculations. Usefull for checking if mesh is reasonable
CtrlVar.MaxNumberOfElements=150e4;


%% plotting
CtrlVar.PlotXYscale=1;

%%
CtrlVar.InfoLevelNonLinIt=1;


%% adapt mesh

CtrlVar.MeshRefinementMethod='explicit:local:newest vertex bisection';
%CtrlVar.MeshRefinementMethod='explicit:global';    % can have any of these values:
                                                   % 'explicit:global'
                                                   % 'explicit:local'
                                                   % 'implicit:global'  (broken at the moment, do not use)
                                                   % 'implicit:local'   (broken at the moment, do not use)
% I=1;
% CtrlVar.ExplicitMeshRefinementCriteria(I).Name='effective strain rates';
% CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=1e-3;
% CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1000;
% CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;
% 
% I=I+1;
% CtrlVar.ExplicitMeshRefinementCriteria(I).Name='thickness gradient';
% CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=1e-2;
% CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1000;
% CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;
% 
% I=I+1;
% CtrlVar.ExplicitMeshRefinementCriteria(I).Name='effective strain rates gradient';
% CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=5e-7;
% CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
% CtrlVar.ExplicitMeshRefinementCriteria(I).p=[0.7];
% CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1000;
% CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;
         
CtrlVar.MeshSizeMin = 400;
CtrlVar.MeshAdapt.GLrange=[2000 750 ; 1000 400];
%CtrlVar.MeshAdapt.GLrange=[2500 CtrlVar.MeshSizeMin];

CtrlVar.RefineMeshOnStart=0;
CtrlVar.InfoLevelAdaptiveMeshing=1;                                            
CtrlVar.AdaptMeshInitial=1  ; % remesh in first iteration (Itime=1)  even if mod(Itime,CtrlVar.AdaptMeshInterval)~=0.
CtrlVar.AdaptMeshAndThenStop=0;    % if true, then mesh will be adapted but no further calculations performed
                                   % useful, for example, when trying out different remeshing options (then use CtrlVar.doAdaptMeshPlots=1 to get plots)
CtrlVar.AdaptMeshMaxIterations=5;
CtrlVar.AdaptMeshUntilChangeInNumberOfElementsLessThan = 20;
CtrlVar.SaveAdaptMeshFileName='MeshFileAdapt';    %  file name for saving adapt mesh. If left empty, no file is written
CtrlVar.AdaptMeshRunStepInterval=50 ; % remesh whenever mod(Itime,CtrlVar.AdaptMeshInterval)==0
CtrlVar.doAdaptMeshPlots=0; 

%%
CtrlVar.ThicknessConstraints=1;
CtrlVar.ResetThicknessToMinThickness=0;  % change this later on
CtrlVar.ThickMin=1;


end
