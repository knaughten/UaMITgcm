function  [UserVar,rho,rhow,g]=DefineDensities(UserVar,CtrlVar,MUA,time,s,b,h,S,B)
    
persistent Frho

fprintf('Start loading densities \n');

if isempty(Frho)

	load(UserVar.GeometryInterpolants,'Frho');

end
	
rho = Frho(MUA.coordinates(:,1),MUA.coordinates(:,2));
rho(rho<100) = 100;
rho(rho>917) = 917;

rhow=1027; 
            
g=9.81/1000;

fprintf('Done loading densities \n');
   
end
