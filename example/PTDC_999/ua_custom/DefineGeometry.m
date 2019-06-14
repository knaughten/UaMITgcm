function [UserVar,s,b,S,B,alpha]=DefineGeometry(UserVar,CtrlVar,MUA,time,FieldsToBeDefined)

persistent Fs FB Fh_init

s=[]; b=[]; S=[]; B=[];
alpha=0 ;

if nargin<5
    FieldsToBeDefined='sbSB';
end

MUAnew = MUA;

fprintf(['Loading ',FieldsToBeDefined,'\n']);

if isempty(Fs)
    load(UserVar.GeometryInterpolants);
end

%% Step I. Bed
if contains(FieldsToBeDefined,'B')
    
    B = FB(MUA.coordinates(:,1),MUA.coordinates(:,2));
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

%% Step III. ice surface and draft

if contains(FieldsToBeDefined,'s') || contains(FieldsToBeDefined,'b') 
    s = Fs(MUA.coordinates(:,1),MUA.coordinates(:,2));
    h_init = Fh_init(MUA.coordinates(:,1),MUA.coordinates(:,2));
    fprintf('Done h \n');

    %% Step IV. Density from firn model

    rho = Load_Rho(UserVar,MUA,h_init);

    %% Step V. Ice draft
    % step 1: first guess for b, based on s, B and rho
    b1 = max([B(:),rho(:).*s(:)./(rho(:)-1024)],[],2);
    h1 = s - b1;

    % refine
    [b,s,h,~]=Calc_bs_From_hBS(CtrlVar,MUA,h1,S,B,rho,1024);

    fprintf('Done b \n');

    % all s above zero
    s(s<0)=0;

    % check minimum ice thickness
    h = s-b;
    I = find(h<=CtrlVar.ThickMin);
    s(I) = b(I)+CtrlVar.ThickMin;
    
    if any(isnan(s)|isnan(b))
        error('NaN values in s or b');
    end
end



