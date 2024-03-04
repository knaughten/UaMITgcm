function  [UserVar,rho,rhow,g]=DefineDensities(UserVar,CtrlVar,MUA,time,s,b,h,S,B)
    
persistent Fh_init;

fprintf('Start loading densities \n');

if isempty(Fh_init)

	load(UserVar.GeometryInterpolants,'Fh_init');

end
	
h = Fh_init(MUA.coordinates(:,1),MUA.coordinates(:,2));
rho = Load_Rho(UserVar,MUA,h);

if ~isempty(strfind(UserVar.FirnInterpolants,'RACMO')) 
    rhow=1024;
elseif ~isempty(strfind(UserVar.FirnInterpolants,'Bedmachine'))      
    rhow=1027;
else
    error('Unknown density case');        
end

g=9.81/1000;

fprintf('Done loading densities \n');
   
end
