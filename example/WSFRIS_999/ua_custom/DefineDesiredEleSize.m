function [UserVar,EleSizeDesired,ElementsToBeRefined,ElementsToBeCoarsened]=...
    DefineDesiredEleSize(UserVar,CtrlVar,MUA,x,y,EleSizeDesired,ElementsToBeRefined,ElementsToBeCoarsened,s,b,S,B,rho,rhow,ub,vb,ud,vd,GF,NodalErrorIndicators)

persistent Fe

maxsize = 50e3;
if isempty(ub)
    load('initial_strain.mat');
    e = Fe(MUA.coordinates(:,1),MUA.coordinates(:,2));
else
[exx,eyy,exy]=CalcNodalStrainRates(CtrlVar,MUA,ub,vb);
e=real(sqrt(exx.^2+eyy.^2+exx.*eyy+exy.^2));
end
[dfdx,dfdy,xint,yint]=calcFEderivatives(e,MUA.coordinates,MUA.connectivity,MUA.nip,CtrlVar);
% [dfdx,dfdy,xint,yint]=calcFEderivatives(e,MUA.coordinates,MUA.connectivity,MUA.nip,CtrlVar);
dtot = hypot(dfdx,dfdy);

M = Ele2Nodes(MUA.connectivity,MUA.Nnodes);

dnodes = M*mean(dtot,2);
dcrit = abs(log10(dnodes));
f1 = dcrit<5;
f2 = dcrit<6;
ecrit = maxsize + zeros(MUA.Nnodes,1);
ecrit(f2) = 1200;
ecrit(f1) = 500;

EleSizeDesired = ecrit;

EleSizeIndicator = maxsize + zeros(MUA.Nnodes,1);

% CtrlVar.MeshAdapt.GLrange=[10000 2500 ; 4000 1500  ; 1000 800];

KdTree=[];
CtrlVar.PlotGLs=0;
CtrlVar.GLsubdivide=1;
[xGL,yGL]=PlotGroundingLines(CtrlVar,MUA,GF);


ds=10000;
dh=2500;

ID=FindAllNodesWithinGivenRangeFromGroundingLine(CtrlVar,MUA,xGL,yGL,ds,KdTree);

EleSizeIndicator(ID)=dh;

ds=4000;
dh=1500;

ID=FindAllNodesWithinGivenRangeFromGroundingLine(CtrlVar,MUA,xGL,yGL,ds,KdTree);

EleSizeIndicator(ID)=dh;

ds=1000;
dh=800;

ID=FindAllNodesWithinGivenRangeFromGroundingLine(CtrlVar,MUA,xGL,yGL,ds,KdTree);

EleSizeIndicator(ID)=dh;



EleSizeDesired=min(EleSizeDesired,EleSizeIndicator);


end
