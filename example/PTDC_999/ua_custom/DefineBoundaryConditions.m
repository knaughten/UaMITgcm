function  BCs=DefineBoundaryConditions(UserVar,CtrlVar,MUA,BCs,time,s,b,h,S,B,ub,vb,ud,vd,GF)
%%
persistent AA BB %CC DD

if isempty(AA)
  
    % load points that define the line-segments along which the BCs are to be defined
    load FixedBoundaryPoints xOuter yOuter %xInner yInner
    AA=[xOuter(1:end-1) yOuter(1:end-1)] ; BB=[xOuter(2:end) yOuter(2:end)];
    
%     xInner = [NaN; xInner; NaN]; yInner = [NaN; yInner; NaN];
%     I = find(isnan(xInner)); CC=[]; DD=[];
%     for ii=1:length(I)-1
%         CC = [CC; xInner(I(ii)+1:I(ii+1)-2) yInner(I(ii)+1:I(ii+1)-2)];
%         DD = [DD; xInner(I(ii)+2:I(ii+1)-1) yInner(I(ii)+2:I(ii+1)-1)];
%     end
end

% find all boundary nodes within 1m distance from the line segment.
x=MUA.coordinates(:,1);  y=MUA.coordinates(:,2); tolerance=1;
I = DistanceToLineSegment([x(MUA.Boundary.Nodes) y(MUA.Boundary.Nodes)],AA,BB,tolerance);
%J = DistanceToLineSegment([x(MUA.Boundary.Nodes) y(MUA.Boundary.Nodes)],CC,DD,tolerance);

% BCs.vbFixedNode=MUA.Boundary.Nodes([I;J]);
% BCs.ubFixedNode=MUA.Boundary.Nodes([I;J]);
BCs.vbFixedNode=MUA.Boundary.Nodes(I);
BCs.ubFixedNode=MUA.Boundary.Nodes(I);

BCs.ubFixedValue=BCs.ubFixedNode*0;
BCs.vbFixedValue=BCs.vbFixedNode*0;

%BCs.ubvbFixedNormalNode=MUA.Boundary.Nodes(J);
%BCs.ubvbFixedNormalValue=BCs.ubvbFixedNormalNode*0;

end
