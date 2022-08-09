function [UserVar,s,b,S,B,alpha]=DefineGeometry(UserVar,CtrlVar,MUA,time,FieldsToBeDefined)

persistent Fs FB Fb

s=[]; b=[]; S=[]; B=[];
alpha=0 ;

if nargin<5
    FieldsToBeDefined='sbSB';
end

fprintf('Loading s, b, S and B \n');

if isempty(Fs)

        load(UserVar.GeometryInterpolants,'FB','Fs','Fb');

end

B = FB(MUA.coordinates(:,1),MUA.coordinates(:,2)); fprintf('Done B \n');
S = 0*B;

if contains(FieldsToBeDefined,'s') || contains(FieldsToBeDefined,'b')
    s = Fs(MUA.coordinates(:,1),MUA.coordinates(:,2)); fprintf('Done s \n');
    b = Fb(MUA.coordinates(:,1),MUA.coordinates(:,2)); fprintf('Done b \n');
end

