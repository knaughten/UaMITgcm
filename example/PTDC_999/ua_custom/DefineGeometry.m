function [UserVar,s,b,S,B,alpha]=DefineGeometry(UserVar,CtrlVar,MUA,time,FieldsToBeDefined)

%persistent Fs Fb

if nargin<5
    FieldsToBeDefined='sbSB';
end

MUAnew = MUA;
alpha=0 ;
fprintf('Loading s, b, S and B \n');

load(UserVar.GeometryInterpolants);

%% Step I. Bed

B = FB(MUA.coordinates(:,1),MUA.coordinates(:,2));
fprintf('Done B \n');

%% Step II. Surface

s = Fs(MUA.coordinates(:,1),MUA.coordinates(:,2));
S = 0*s;

fprintf('Done s and S \n');

%% Step III. Ice thickness: combination of Millan, RTOPO and Dutrieux

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

if any(isnan(s)|isnan(b)|isnan(B)|isnan(S))
	error('NaN values in s, S, b or B');
end

