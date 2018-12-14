%%%%%%%%%%%
%% TO DO %%
%%%%%%%%%%%
%% Hardcode appropriate filenames for 
%   + melt output from MITgcm (MITout_2D.nc?)
%   + calendar file
%   + user variables
%% Need to provide user with ll2psxy.m?
%% Adjust Ua code so it can deal with writing output at variable intervals
%% Code section on reading user input from file

function callUa(UserVar,varargin)

if nargin==0
    UserVar=[];
end

%%%%%%%%%%%%%%%%%%%%%%%%
%% collect user input %%
%%%%%%%%%%%%%%%%%%%%%%%%
% read from user input file:
UserVar.UaMITgcm.Experiment = '.';

UserVar.UaMITgcm.UaSourceDirectory = '.';
UserVar.UaMITgcm.UaOutputsDirectory = '.';

UserVar.UaMITgcm.MITgcmOutputsDirectory = '.';


%%%%%%%%%%%%%%%%%%%%%%%%%%
%% collect MITgcm input %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% read calendar file
CAL = textread([UserVar.UaMITgcm.MITgcmOutputsDirectory,'/sample_calendar_month']);

% save start year and start month in string format
Start = num2str(CAL(1));
UserVar.UaMITgcm.StartYear = Start(1:4);
UserVar.UaMITgcm.StartMonth = Start(5:6);

%convert physical run time to years and save in double format 
UserVar.UaMITgcm.runTime = CAL(2)/365.25; % in years

% generate array of output times for Ua, converted to years
for ii=3:length(CAL)
    OutputInterval(ii-2) = CAL(ii);
end

if OutputInterval(1)==-1
    UserVar.UaMITgcm.OutputTimes = [1:UserVar.UaMITgcm.runTime*365.25]/365.25;
else
    UserVar.UaMITgcm.OutputTimes = cumsum(OutputInterval)/365.25;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read MITgcm grid and check if it’s lat/lon or Cartesian %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read grid from MITgcm melt output
str2D=strcat(UserVar.UaMITgcm.MITgcmOutputsDirectory,'/MITout_2D.nc');
lon = double(ncread(str2D,'LONGITUDE')); Ilon = size(lon);
lat = double(ncread(str2D,'LATITUDE'));

% make sure grid is 2D field
if Ilon(1)==1 || Ilon(2)==1
   [lon,lat] = ndgrid(lon(:),lat(:));
end

% check if grid is lat/lon and convert to cartesian if required
if all(lon(:)>=-180) && all(lon(:)<=180) && all(lat(:)>=-90) && all(lat(:)<=90)
    [x,y] = ll2psxy(lat,lon,-71,0);
else
    x = lon;    y = lat;
end
    
UserVar.UaMITgcm.MITgcmGridX = x;
UserVar.UaMITgcm.MITgcmGridY = y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read MITgcm meltrates %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
[I,J] = size(x);
time = ncread(str2D,'TIME'); T=length(time);

% MITgcm is kg w.e./s, convert to m/yr 
% negative for melting
UserVar.UaMITgcm.MITgcmMelt = double(ncread(str2D,'SHIfwFlx',[1,1,T],[I,J,1])/1000*365*24*60*60);

%%%%%%%%%%%%
%% run Ua %%
%%%%%%%%%%%%
setup_Ua(UserVar.UaMITgcm.UaSourceDirectory);
%Ua2D(UserVar,varargin{:})

end