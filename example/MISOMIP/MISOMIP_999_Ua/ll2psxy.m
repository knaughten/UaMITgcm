function [X,Y] = ll2psxy(Lat,Lon,Sp,Cm)

% function [X,Y] = ll2psxy(Lat,Lon,Sp,Cm)
%
% Function to convert Latitude and Longitude into x and
% y coordinates in a polar stereographic projection with
% standard parallel at 71 South.  Original coordinates are
% WGS-84.  Equations come from Snyder (1987).
% Author: A. Jenkins;  Date: 21/02/02.
% Modified by Craig Stewart 23/7/02 to take separate lat lon input
% arguments and give separate X Y output variables
% Modified by Pierre Dutrieux at some point in 2009 to take Standard
% parallel Sp (default 71S) and Central meridian Cm (default 110W)
% input arguments.

% Define semi-major axis and flatteing of ellipsoid and
% standard parallel and central meridian for projection.
a = 6378137;                %WGS-84
f = 1/298.257223563;   %WGS-84
if ~exist('Sp','var')
    Sp = -71;          %Plane latitude for
                            %southern polar stereographic (latitude
                            %of true scale) 
end
if ~exist('Cm','var')
    Cm = -110;              %Centre meridian
end 

    
% Convert angles to radians.
Sp = -Sp*pi/180;
Cm = -Cm*pi/180;
Lat = -Lat*pi/180;
Lon = -Lon*pi/180;
 
% Calculate coordinates.
e2 = 2*f - f^2;
e = sqrt(e2);
mc = cos(Sp)/sqrt(1-e2*(sin(Sp))^2);
tc = sqrt(((1-sin(Sp))/(1+sin(Sp)))*((1+e*sin(Sp))/(1-e*sin(Sp)))^e);

t = sqrt(((1-sin(Lat))./(1+sin(Lat))).*((1+e*sin(Lat))./(1-e.*sin(Lat))).^e);
r = a*mc*t/tc;

X = -r.*sin(Lon-Cm);
Y = r.*cos(Lon-Cm);
