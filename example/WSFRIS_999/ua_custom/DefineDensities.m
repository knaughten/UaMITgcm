function  [UserVar,rho,rhow,g]=DefineDensities(UserVar,CtrlVar,MUA,time,s,b,h,S,B)
    
persistent Fdens


if isempty(Fdens)

        
        fprintf('Loading Interpolant for rho ')
        
        load srFdens Fdens
        
end
        
x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);


rho=Fdens(x,y);

rhow=1030; g=9.81/1000;


end
