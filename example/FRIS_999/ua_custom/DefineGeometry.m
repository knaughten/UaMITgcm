function [UserVar,s,b,S,B,alpha]=DefineGeometry(UserVar,CtrlVar,MUA,time,FieldsToBeDefined)

persistent FB Fs Fb Fc

s=[]; b=[]; S=[]; B=[];
alpha=0 ;

if nargin<5
    FieldsToBeDefined='sbSB';
end

x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);

fprintf(['Loading ',FieldsToBeDefined,'\n']);

%% Step I. Bed
if contains(FieldsToBeDefined,'B')
    if isempty(FB)
        load srFBedrock FB
    end
    B=FB(x,y);
    fprintf('Done B \n');
    if any(isnan(B))
        error('NaN values in B');
    end
end

%% Step II. sea surface
if contains(FieldsToBeDefined,'S')
    S = zeros(MUA.Nnodes,1);
    fprintf('Done S \n');
end

%% Step III. ice base
if contains(FieldsToBeDefined,'b')
    if isempty(Fb)
        load srFicebed Fb
    end
    b=Fb(x,y);
    fprintf('Done b \n');
    if any(isnan(b))
        error('NaN values in b');
    end
end

%% Step IV. ice surface
if contains(FieldsToBeDefined,'s')
    if isempty(Fs)
        load srFs2 Fs
    end
    s=Fs(x,y);
    fprintf('Done s \n');
    if any(isnan(s))
        error('NaN values in s');
    end
end



end



