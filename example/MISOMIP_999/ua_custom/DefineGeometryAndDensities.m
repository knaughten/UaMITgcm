function  [UserVar,s,b,S,B,rho,rhow,g]=DefineGeometryAndDensities(UserVar,CtrlVar,MUA,F,FieldsToBeDefined)

%%
%  Define ice and ocean densities, as well as the gravitational acceleration.
%
% [UserVar,rho,rhow,g]=DefineDensities(UserVar,CtrlVar,MUA,time,s,b,h,S,B)
%
%  rhow    :  ocean density (scalar variable)
%  rho     :  ice density (nodal variable)
%  g       :  gravitational acceleration
% 
%%  
        
% Defines model geometry

x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);
alpha=0;

s = [];
b = [];
S = [];
B = [];

if contains(FieldsToBeDefined,'B')
    B=MismBed(x,y);
end

if contains(FieldsToBeDefined,'S')
    S = 0*x;
end

if contains(FieldsToBeDefined,'b')
    b=MismBed(x,y);
end

if contains(FieldsToBeDefined,'s')
    h0 = 300;
    s=MismBed(x,y)+h0;
end


% Defines densities
if contains(FieldsToBeDefined,{'rho','rhow','g'})
   
    rho=918+0*x ; 
    rhow=1028; 
    g=9.81/1000;

end

    
end
