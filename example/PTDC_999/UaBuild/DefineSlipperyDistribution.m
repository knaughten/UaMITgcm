function [UserVar,C,m]=DefineSlipperyDistribution(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)

persistent FC

if exist(CtrlVar.NameOfFileForReadingSlipperinessEstimate)~=2
    error(['AGlen file', UserVar.NameOfFileForReadingSlipperinessEstimate,' does not exist'])
else
    if isempty(FC)
        load(CtrlVar.NameOfFileForReadingSlipperinessEstimate,'xC','yC','C');
        FC = scatteredInterpolant(xC,yC,C,'linear');
        fprintf('\n Read slipperiness from file \n');
    end

    load(CtrlVar.NameOfFileForReadingSlipperinessEstimate,'m');
    x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);
    C = FC(x,y);
    m = m(1);

end

end
