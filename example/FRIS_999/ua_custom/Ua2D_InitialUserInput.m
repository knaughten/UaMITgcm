function [UserVar,CtrlVar,MeshBoundaryCoordinates]=Ua2D_InitialUserInput(UserVar,CtrlVar)

%%
CtrlVar.Experiment=UserVar.UaMITgcm.Experiment;   

%% Types of run
%
CtrlVar.TimeDependentRun=1; 
CtrlVar.TotalNumberOfForwardRunSteps=10e10; % an arbitrary large number
CtrlVar.TotalTime=UserVar.UaMITgcm.runTime;
CtrlVar.dt = 1e-3;
CtrlVar.ATStimeStepTarget = UserVar.UaMITgcm.ATStimeStepTarget;

CtrlVar.WriteRestartFile = 1;  
CtrlVar.NameOfRestartFiletoWrite=[CtrlVar.Experiment,'-RestartFile.mat'];
CtrlVar.NameOfRestartFiletoRead=CtrlVar.NameOfRestartFiletoWrite;

if exist(CtrlVar.NameOfRestartFiletoRead, 'file') == 2
    CtrlVar.Restart=1;
    CtrlVar.RestartTime=0; 
    CtrlVar.ResetTime=1;
    CtrlVar.ResetTimeStep=0;
else
    CtrlVar.Restart=0;
    CtrlVar.time=0; 
end

CtrlVar.UaOutputsDt = UserVar.UaMITgcm.UaOutputTimes; 

%% parallel settings
myCluster = parcluster('local') ;  
myCluster.NumWorkers = 6;
saveProfile(myCluster);
CtrlVar.Parallel.uvhAssembly.parfor.isOn=1;     % assembly over integration points done in parallel using parfor
CtrlVar.Parallel.uvhAssembly.spmd.isOn=1;       % assembly in parallel using spmd over sub-domain (domain decomposition)  
CtrlVar.Parallel.uvAssembly.spmd.isOn=1;

%% Reading in mesh
CtrlVar.ReadInitialMesh=1;
CtrlVar.ReadInitialMeshFileName = 'MeshFileForInversion.mat';
load BoundaryCoordinates MeshBoundaryCoordinates

%% Plotting options
CtrlVar.doplots=0;
CtrlVar.PlotMesh=0;  
CtrlVar.PlotBCs=0;
CtrlVar.PlotXYscale=1;
CtrlVar.InfoLevelNonLinIt=1;
CtrlVar.InfoLevel=1;

CtrlVar.TriNodes=3;
CtrlVar.kH=1;
CtrlVar.nip=6;
CtrlVar.niph=6;

CtrlVar.AdaptMesh=1;
CtrlVar.InfoLevelAdaptiveMeshing=1;     
CtrlVar.MeshSizeMax=50e3;
CtrlVar.MeshSize=CtrlVar.MeshSizeMax;
CtrlVar.MeshSizeMin=300;
CtrlVar.MeshSizeBoundary=CtrlVar.MeshSize;
CtrlVar.MaxNumberOfElements=150e4;
CtrlVar.SaveAdaptMeshFileName='AdaptMesh.mat';
CtrlVar.MeshRefinementMethod = 'explicit:local:newest vertex bisection';
CtrlVar.RefineMeshOnStart=0;
CtrlVar.AdaptMeshInitial=1  ;
CtrlVar.AdaptMeshAndThenStop=0; 
CtrlVar.AdaptMeshRunStepInterval=0 ;
CtrlVar.AdaptMeshMaxIterations=1;
CtrlVar.AdaptMeshUntilChangeInNumberOfElementsLessThan = 30;
CtrlVar.OnlyMeshDomainAndThenStop=0;
CtrlVar.doAdaptMeshPlots=0; 

I=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Name='flotation';
CtrlVar.ExplicitMeshRefinementCriteria(I).Scale=0.001;
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMin=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).EleMax=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).p=[];
CtrlVar.ExplicitMeshRefinementCriteria(I).InfoLevel=1;
CtrlVar.ExplicitMeshRefinementCriteria(I).Use=false;

%% Pos. thickness constraints
CtrlVar.ThickMin=10;
CtrlVar.ResetThicknessToMinThickness=1; 
CtrlVar.ThicknessConstraints=0;            
            
%% Adjoint
CtrlVar.doInverseStep=0;
CtrlVar.Inverse.Measurements='-uv-dhdt-' ; 
CtrlVar.Inverse.MinimisationMethod='MatlabOptimization'; 
CtrlVar.CisElementBased=0;   
CtrlVar.AGlenisElementBased=0;
CtrlVar.Inverse.CalcGradI=true;  
CtrlVar.AGlenmin=1e-10; CtrlVar.AGlenmax=1e-7;
CtrlVar.Cmin=1e-7;  CtrlVar.Cmax=10;        
CtrlVar.Inverse.Iterations=50;
CtrlVar.Inverse.WriteRestartFile=1;  % always a good idea to write a restart file. 
CtrlVar.Inverse.NameOfRestartOutputFile=['InverseRestart_',Experiment];
CtrlVar.Inverse.NameOfRestartInputFile='';
CtrlVar.NameOfFileForReadingSlipperinessEstimate='C-Estimate.mat';
CtrlVar.NameOfFileForReadingAGlenEstimate='AGlen-Estimate.mat';
CtrlVar.NameOfFileForSavingSlipperinessEstimate='C-Estimate.mat';
CtrlVar.NameOfFileForSavingAGlenEstimate='AGlen-Estimate.mat';
CtrlVar.Inverse.InvertFor='-logC-logAGlen-' ;
CtrlVar.Inverse.DataMisfit.GradientCalculation='Adjoint'; % {'Adjoint','FixPoint'}
CtrlVar.Inverse.AdjointGradientPreMultiplier='I'; % {'I','M'}
CtrlVar.Inverse.TestAdjoint.isTrue=0; % If true then perform a brute force calculation 
                                      % of the directinal derivative of the objective function.  
CtrlVar.Inverse.TestAdjoint.FiniteDifferenceType='central' ; % {'central','forward'}
CtrlVar.Inverse.TestAdjoint.FiniteDifferenceStepSize=1e-8 ;
CtrlVar.Inverse.TestAdjoint.iRange=[] ;
CtrlVar.Inverse.Regularize.Field='logC-logAGlen-' ;
CtrlVar.Inverse.Regularize.C.gs=1; 
CtrlVar.Inverse.Regularize.C.ga=1;
CtrlVar.Inverse.Regularize.logC.gs=1e4; 
CtrlVar.Inverse.Regularize.logC.ga=1;
CtrlVar.Inverse.Regularize.AGlen.gs=1;
CtrlVar.Inverse.Regularize.AGlen.ga=1;
CtrlVar.Inverse.Regularize.logAGlen.gs=1e3;
CtrlVar.Inverse.Regularize.logAGlen.ga=1;
CtrlVar.Inverse.DataMisfit.Multiplier=1;
CtrlVar.Inverse.Regularize.Multiplier=1;
CtrlVar.Inverse.DataMisfit.FunctionEvaluation='integral';
CtrlVar.MUA.MassMatrix=1;
CtrlVar.MUA.StiffnessMatrix=1;
CtrlVar.Inverse.InfoLevel=1; 


end
