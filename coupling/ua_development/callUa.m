%%%%%%%%%%%
%% TO DO %%
%%%%%%%%%%%
%% -> Hardcode appropriate filenames and directories for 
%   + melt output and tracer grid from MITgcm
%   + calendar file
%   + file with user variables
%% -> Write code for reading user variables from file
%% -> Which netcdf output do we want to generate?
%% -> What format do I expect for the MITgcm output file: SHIFwFlx in MITout_2D.nc or other?

function callUa(UserVar,varargin)

if nargin==0
    UserVar=[];
end

%%%%%%%%%%%%%%%%%%%%%%%%
%% collect user input %%
%%%%%%%%%%%%%%%%%%%%%%%%
% read from user input file (TO DO):
UserVar.UaMITgcm.Experiment = 'MISOMIP_1r';

UserVar.UaMITgcm.UaSourceDirectory = '/home/UNN/wchm8/Documents/Ua/UaMITgcm_Development/Ua_source/';
UserVar.UaMITgcm.UaOutputsDirectory = './ResultsFiles';

UserVar.UaMITgcm.MITgcmOutputsDirectory = '.';

UserVar.UaMITgcm.OutputFormat = 'matlab'; % options are 'matlab' or 'netcdf'

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% collect MITgcm input %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% read calendar file
CAL = textread([UserVar.UaMITgcm.MITgcmOutputsDirectory,'/sample_calendar_monthly']);

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
elseif OutputInterval(1)==CAL(2)
    UserVar.UaMITgcm.OutputTimes = [OutputInterval(1) 2*OutputInterval(1)]/365.25;
else
    UserVar.UaMITgcm.OutputTimes = cumsum(OutputInterval)/365.25;
end

% based on the OutputTimes we set the ATStimeStepTarget to be the minimum
% gap between successive output times. This should prevent Ua from
% 'overstepping'. 
UserVar.UaMITgcm.ATStimeStepTarget = min(UserVar.UaMITgcm.OutputTimes(2:end)-UserVar.UaMITgcm.OutputTimes(1:end-1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read MITgcm melt rates %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MITgcm is kg w.e./s, convert to m/yr 
% negative for melting
MeltFile = [UserVar.UaMITgcm.MITgcmOutputsDirectory,'/MITout_2D.nc'];
UserVar.UaMITgcm.MITgcmMelt = double(ncread(MeltFile,'SHIfwFlx')/1000*365*24*60*60);
UserVar.UaMITgcm.MITgcmMelt = squeeze(UserVar.UaMITgcm.MITgcmMelt(:,:,end));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read MITgcm grid and check if it’s lat/lon or Cartesian %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read tracer gridpoints
fid=fopen([UserVar.UaMITgcm.MITgcmOutputsDirectory,'/XC.data'],'r','b');
lon=fread(fid,inf,'real*4');    Ilon = size(lon); fclose(fid);
fid=fopen([UserVar.UaMITgcm.MITgcmOutputsDirectory,'/YC.data'],'r','b');
lat=fread(fid,inf,'real*4'); fclose(fid);

% check if grid is lat/lon and convert to cartesian if required
if all(lon(:)>=-180) && all(lon(:)<=180) && all(lat(:)>=-90) && all(lat(:)<=90)
    [x,y] = ll2psxy(lat,lon,-71,0);
else
    x = lon;    y = lat;
end
    
% reshape to 2D grid
[I,J] = size(UserVar.UaMITgcm.MITgcmMelt);
x = reshape(x,I,J); y = reshape(y,I,J);
UserVar.UaMITgcm.MITgcmGridX = x;
UserVar.UaMITgcm.MITgcmGridY = y;

%%%%%%%%%%%%
%% run Ua %%
%%%%%%%%%%%%
setup_Ua(UserVar.UaMITgcm.UaSourceDirectory);
Ua2D(UserVar,varargin{:})

end