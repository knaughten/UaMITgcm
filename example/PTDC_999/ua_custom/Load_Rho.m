function [DensAv] = Load_Rho(UserVar,MUA,h)

persistent Frhofirn Ffirndepth;

if ~isempty(strfind(UserVar.FirnInterpolants,'RACMO'))
    
    if isempty(Frhofirn)
        load(UserVar.FirnInterpolants);

        fprintf('Done loading firn interpolants \n');
    end

    firndepth = Ffirndepth(MUA.coordinates(:,1),MUA.coordinates(:,2));
    I = find((h-firndepth)<0);
    J = find((h-firndepth)>=0);

    DensAv = 0 * MUA.coordinates(:,1);
    DensAv(I) = Frhofirn(MUA.coordinates(I,1),MUA.coordinates(I,2))./firndepth(I);
    DensAv(J) = (Frhofirn(MUA.coordinates(J,1),MUA.coordinates(J,2))+917*(h(J)-firndepth(J)))./h(J);

    DensAv(DensAv==0)=850;

elseif ~isempty(strfind(UserVar.FirnInterpolants,'Bedmachine'))
        
        DensAv = 0*h+917; % in bedmachine, the firn correction has already been absorbed in the ice thickness.

else
        error('Unknown density case');        
end

    
		