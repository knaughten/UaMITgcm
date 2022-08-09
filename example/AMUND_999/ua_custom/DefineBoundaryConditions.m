function  BCs=DefineBoundaryConditions(UserVar,CtrlVar,MUA,BCs,time,s,b,h,S,B,ub,vb,ud,vd,GF)
%%
persistent AA BB

if isempty(AA)
  
    % load points that define the line-segments along which the BCs are to be defined
    load AMUND_FixedBoundaryPoints_Bedmachinev2.mat
    xfixed = FixedBoundaryCoordinates(:,1);
    yfixed = FixedBoundaryCoordinates(:,2);
    AA=[xfixed(1:end-1) yfixed(1:end-1)] ; BB=[xfixed(2:end) yfixed(2:end)];

end

% find all boundary nodes within 1m distance from the line segment.
x=MUA.coordinates(:,1);  y=MUA.coordinates(:,2); tolerance=1;
I = DistanceToLineSegment([x(MUA.Boundary.Nodes) y(MUA.Boundary.Nodes)],AA,BB,tolerance);

BCs.vbFixedNode=MUA.Boundary.Nodes(I);
BCs.ubFixedNode=MUA.Boundary.Nodes(I);

BCs.ubFixedValue=BCs.ubFixedNode*0;
BCs.vbFixedValue=BCs.vbFixedNode*0;


end
