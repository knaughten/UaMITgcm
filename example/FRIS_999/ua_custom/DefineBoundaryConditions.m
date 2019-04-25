function  BCs=DefineBoundaryConditions(UserVar,CtrlVar,MUA,BCs,time,s,b,h,S,B,ub,vb,ud,vd,GF)

GroundedBoundaryNodes=MUA.Boundary.Nodes(GF.node(MUA.Boundary.Nodes)>0.5);

BCs.vbFixedNode=GroundedBoundaryNodes; 
BCs.ubFixedNode=GroundedBoundaryNodes;

BCs.ubFixedValue=BCs.ubFixedNode*0;
BCs.vbFixedValue=BCs.vbFixedNode*0;
end
