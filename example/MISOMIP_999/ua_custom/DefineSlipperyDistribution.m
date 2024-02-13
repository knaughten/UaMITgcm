
function [UserVar,C,m,q,muk]=DefineSlipperyDistribution(UserVar,CtrlVar,MUA,F)


m=3;
C0=3.16e6^(-m)*1000^m*365*24*60*60;

C=C0+zeros(MUA.Nnodes,1);

q=1 ;      % only needed for Budd sliding law
muk=0.5 ;  % required for Coulomb friction type sliding law as well as Budd, minCW (Tsai), rCW  (Umbi) and rpCW (Cornford).

end
