function [UserVar,C,m,q,muk]=DefineSlipperyDistribution(UserVar,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF)

persistent FC

if exist(CtrlVar.NameOfFileForReadingSlipperinessEstimate)~=2
     
    error('Cannot fine C file %s\n',CtrlVar.NameOfFileForReadingSlipperinessEstimate);
     
else
    
    if isempty(FC)
        load(CtrlVar.NameOfFileForReadingSlipperinessEstimate,'xC','yC','C');
        FC = scatteredInterpolant(xC,yC,C,'linear');
        fprintf('\n Read slipperiness from file %s\n',CtrlVar.NameOfFileForReadingSlipperinessEstimate);
    end

    load(CtrlVar.NameOfFileForReadingSlipperinessEstimate,'m');
    x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);
    C = FC(x,y);
    m = m(1);

end

q=1 ;      % only needed for Budd sliding law
muk=0.5 ;   % required for Coulomb friction type sliding law as well as Budd, Tsai, Umbi and Cornford

end
