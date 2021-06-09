function  BCs=DefineBoundaryConditions(UserVar,CtrlVar,MUA,BCs,time,s,b,h,S,B,ub,vb,ud,vd,GF)
%%
persistent AA BB

if isempty(AA)
  
    % load points that define the line-segments along which the BCs are to be defined
    load FixedBoundaryPoints xOuter yOuter
    AA=[xOuter(1:end-1) yOuter(1:end-1)] ; BB=[xOuter(2:end) yOuter(2:end)];

end

% find all boundary nodes within 1m distance from the line segment.
x=MUA.coordinates(:,1);  y=MUA.coordinates(:,2); tolerance=1;
I = DistanceToLineSegment([x(MUA.Boundary.Nodes) y(MUA.Boundary.Nodes)],AA,BB,tolerance);

BCs.vbFixedNode=MUA.Boundary.Nodes(I);
BCs.ubFixedNode=MUA.Boundary.Nodes(I);
%BCs.vbFixedNode=MUA.Boundary.Nodes(I);
%BCs.ubFixedNode=MUA.Boundary.Nodes(I);

BCs.ubFixedValue=BCs.ubFixedNode*0;
BCs.vbFixedValue=BCs.vbFixedNode*0;

end
