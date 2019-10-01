function [UserVar,AGlen,n]=DefineAGlenDistribution(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)


persistent FA

if isempty(FA)
    
    fprintf('DefineAGlenDistribution: loading file: %-s ',CtrlVar.NameOfFileForReadingAGlenEstimate);
    load(CtrlVar.NameOfFileForReadingAGlenEstimate,'AGlen','n','xA','yA')
    fprintf(' done \n')
    
    FA=scatteredInterpolant(xA,yA,AGlen,'linear', 'nearest'); 
end
x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);

AGlen=FA(x,y);
if any(isnan(AGlen))
    warning('NaN values in AGlen - check this');
    meanA = nanmean(AGlen(GF.node>0.5));
    AGlen(isnan(AGlen)) = meanA;
end
n=3;

end
