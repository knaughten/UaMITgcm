function [UserVar,F]=GetMassBalance(UserVar,CtrlVar,MUA,F)

narginchk(4,4)
nargoutchk(2,2)


N=nargout('DefineMassBalance');

switch N
    
    case 2
        
        [F.as,F.ab]=DefineMassBalance(CtrlVar.Experiment,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.rho,F.rhow,F.GF);
        F.dasdh=F.as*0 ;  F.dabdh=F.ab*0 ;
        
    case 3
        
        [UserVar,F.as,F.ab]=DefineMassBalance(UserVar,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.rho,F.rhow,F.GF);
        F.dasdh=F.as*0 ;  F.dabdh=F.ab*0 ;
        
    case 4
        
        [F.as,F.ab]=DefineMassBalance(CtrlVar.Experiment,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.rho,F.rhow,F.GF);
        F.dasdh=F.as*0 ;  F.dabdh=F.ab*0 ;
        
    case 5
        
        [UserVar,F.as,F.ab,F.dasdh,F.dabdh]=DefineMassBalance(UserVar,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.rho,F.rhow,F.GF);
        
end


% some input checks

errorStruct.identifier = 'GetMassBalance:NaNinInput';
if any(isnan(F.as))
    errorStruct.message = 'nan in as';
    error(errorStruct)
end

if any(isnan(F.ab))
    errorStruct.message = 'nan in ab';
    error(errorStruct)
end

if any(isnan(F.dasdh))
    errorStruct.message = 'nan in dasdh';
    error(errorStruct)
end

if any(isnan(F.dabdh))
    errorStruct.message = 'nan in dabdh';
    error(errorStruct)
end


if numel(F.as)==1
    F.as=F.as+zeros(MUA.Nnodes,1);
end

if numel(F.ab)==1
    F.ab=F.ab+zeros(MUA.Nnodes,1);
end


if  MUA.Nnodes ~= numel(F.as)
    fprintf('as must have same number of values as there are nodes in the mesh \n')
    error('DefineMassBalance returns incorrect dimensions ')
end


if  MUA.Nnodes ~= numel(F.ab)
    fprintf('ab must have same number of values as there are nodes in the mesh \n')
    error('DefineMassBalance returns incorrect dimensions ')
end



end