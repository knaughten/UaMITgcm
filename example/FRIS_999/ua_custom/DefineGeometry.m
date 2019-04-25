function [UserVar,s,b,S,B,alpha]=DefineGeometry(UserVar,CtrlVar,MUA,time,FieldsToBeDefined)

persistent FB Fs Fb Fc


if nargin<5
    FieldsToBeDefined='sbSB';
end

alpha=0 ;


if isempty(FB)

        
        fprintf('Loading Interpolants for s, b and B ')
        
        load srFBedrock FB
        load srFicebed Fb
        load srFs2 Fs
        fprintf('done\n')
        

end


x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);


if ~isempty(strfind(FieldsToBeDefined,'S'))
    S=zeros(MUA.Nnodes,1);
else
    S=NaN;
end

if ~isempty(strfind(FieldsToBeDefined,'s'))
    s=Fs(x,y);
else
    s=NaN;
end

if ~isempty(strfind(FieldsToBeDefined,'b'))
    b=Fb(x,y);
else
    b=NaN;
end

if ~isempty(strfind(FieldsToBeDefined,'B'))

    B=FB(x,y);

else
    B=NaN;
end



end



