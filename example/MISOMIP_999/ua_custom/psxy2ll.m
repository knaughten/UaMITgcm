function [lat,lon] = psxy2ll(x,y,Sp,Cm);

% function [lat,lon] = psxy2ll(x,y,Sp,Cm);
%
% Converts polarstereographic coordinates into WGS 84 Lat lon, 
% assuming a projection plane latitude Sp of 71 south
% and a centre meridian Cm of 101W degrees.
%
% Reference: Snyder, J. P. 
% "Map projections Used by the U.S. Geological Survey" 1984 pp 162-164
% Coded by Craig Stewart, British Antarctic Survey 7/8/02
% Vectorised by Adrian Jenkins, British Antarctic Survey 22/7/02
% Modified by Pierre Dutrieux at some point in 2009 to take Standard
% parallel Sp (default 71S) and Central meridian Cm (default 110W)
% input arguments.

% Define semi-major axis and flatteing of ellipsoid and
% standard parallel and central meridian for projection.
a = 6378137;                %WGS-84 major axis
f = 1/298.257223563;   %WGS-84 flattening

if ~exist('Sp','var')
    Sp = -71;               %Plane latitude for
                                  %southern polar stereographic (latitude
                                  %of true scale) 
end
if ~exist('Cm','var')
    Cm = -110;              %Centre meridian
end 

phi_c = -Sp*pi/180;	    %Using Snyders nomenclature

e = sqrt(2*f-f^2);

tol = 1e-12; % set the latitude tolerance for iteration
tc = tan(pi/4-phi_c/2)/((1-e*sin(phi_c))/(1+e*sin(phi_c)))^(e/2); % eqn 13-9
mc = cos(phi_c)/(1-e^2*(sin(phi_c))^2)^0.5; % eqn 12-15
rho = sqrt(x.^2 + y.^2); % eqn 16-18
t = rho*tc/(a*mc); % eqn 17-40
lamda = Cm*pi/180 + atan2(x,y);	% eqn 16-16


% Have to iterate to find lat
% First go use....
phi1 = pi/2-2*atan(t);
trial_phi = pi/2 - 2*atan(t.*((1-e*sin(phi1))./(1+e*sin(phi1))).^(e/2));
the_change = 2*tol; % arbitrary number larger than tol
while the_change > tol
    old_phi = trial_phi;
    trial_phi = pi/2 - 2*atan((t.*((1-e*sin(old_phi))./(1+e*sin(old_phi))).^(e/2))); % eqn 7-9 (more or less)
    the_change = trial_phi-old_phi;
end
phi = trial_phi;

% turn lat and lon into degrees
lat = -phi*180/pi;
lon = lamda*180/pi;
