function [UserVar,C,m]=DefineSlipperyDistribution(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)

persistent FC

if isempty(FC)
    load(CtrlVar.NameOfFileForReadingSlipperinessEstimate,'xC','yC','C');
    FC = scatteredInterpolant(xC,yC,C,'linear', 'nearest');
    fprintf('\n Read slipperiness from file \n');
end

x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);
C = FC(x,y);

if any(isnan(C))
    warning('NaN values in C - check this');
    C(isnan(C)) = 1e-5;
end

m = 3;

end
