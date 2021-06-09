%%%%%%%%%%%
%%%

function callUa(UserVar,varargin)

if nargin==0
    UserVar=[];
end

%%%%%%%%%%%%%%%%%%%%%%%%
%% collect user input %%
%%%%%%%%%%%%%%%%%%%%%%%%
% read from user input file:
fid = fopen('./options_for_ua');
UserOptions = textscan(fid,'%s\n');
fclose(fid);
UserOptions = UserOptions{1};

UserVar.UaMITgcm.Experiment = UserOptions{1};
UserVar.UaMITgcm.CentralOutputDirectory = UserOptions{2};
UserVar.UaMITgcm.CalendarFileName = UserOptions{3};
UserVar.UaMITgcm.MeltFileName = UserOptions{4};
UserVar.UaMITgcm.UaDraftFileName = UserOptions{5}; 
UserVar.UaMITgcm.UaOutputFormat = UserOptions{6};
UserVar.UaMITgcm.MITcoordinates = UserOptions{7};

UserVar.UaMITgcm.UaOutputDirectory = './ResultsFiles';

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% collect MITgcm input %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% read calendar file

fid = fopen([UserVar.UaMITgcm.CentralOutputDirectory,...
    '/',UserVar.UaMITgcm.CalendarFileName]);
CAL = textscan(fid,'%d\n');
CAL = double(CAL{1});

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
    UserVar.UaMITgcm.UaOutputTimes = [1:UserVar.UaMITgcm.runTime*365.25]/365.25;
%elseif OutputInterval(1)==CAL(2)
%    UserVar.UaMITgcm.UaOutputTimes = [OutputInterval(1) 2*OutputInterval(1)]/365.25;
else
    UserVar.UaMITgcm.UaOutputTimes = cumsum(OutputInterval)/365.25;
end

% based on the OutputTimes we set the ATStimeStepTarget to be the minimum
% gap between successive output times. This should prevent Ua from
% 'overstepping'. 
if numel(UserVar.UaMITgcm.UaOutputTimes)==1
	% allows for a single Ua output interval equal to the coupling timestep,
	% e.g. monthly output and a 1 month coupling timestep
	UserVar.UaMITgcm.ATStimeStepTarget=UserVar.UaMITgcm.UaOutputTimes(1);
elseif numel(UserVar.UaMITgcm.UaOutputTimes)>1
	% this covers multiple Ua outputs within a single coupling timestep
	UserVar.UaMITgcm.ATStimeStepTarget=min(UserVar.UaMITgcm.UaOutputTimes(2:end)-UserVar.UaMITgcm.UaOutputTimes(1:end-1));
else
	error('Not enough input values in UaOutputTimes');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read MITgcm melt rates %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% needs to be adjusted to read the correct input file
MeltFile = [UserVar.UaMITgcm.CentralOutputDirectory,'/',...
    UserVar.UaMITgcm.MeltFileName];
load(MeltFile);

UserVar.UaMITgcm.MITgcmMelt = meltrate(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Read MITgcm grid and check if it’s lat/lon or Cartesian %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read tracer gridpoints
lonCMIT = rdmds([UserVar.UaMITgcm.CentralOutputDirectory,'/XC']);
latCMIT = rdmds([UserVar.UaMITgcm.CentralOutputDirectory,'/YC']);

lonGMIT = rdmds([UserVar.UaMITgcm.CentralOutputDirectory,'/XG']); % 2d array
latGMIT = rdmds([UserVar.UaMITgcm.CentralOutputDirectory,'/YG']); % 2d array

% check if MIT coordinates are latlon or ps.
if strcmp(UserVar.UaMITgcm.MITcoordinates,'latlon')
    % Convert longitude from 0-360 range to -180-180 range
    index = lonCMIT > 180;
    lonCMIT(index) = lonCMIT(index) - 360;
    index = lonGMIT > 180;
    lonGMIT(index) = lonGMIT(index) - 360;
    
    [UserVar.UaMITgcm.MITgcmCGridX,UserVar.UaMITgcm.MITgcmCGridY] = ll2psxy(latCMIT,lonCMIT,-71,0);
    [UserVar.UaMITgcm.MITgcmGGridX,UserVar.UaMITgcm.MITgcmGGridY] = ll2psxy(latCMIT,lonCMIT,-71,0);
    
    UserVar.UaMITgcm.MITgcmCGridlon = lonCMIT;
    UserVar.UaMITgcm.MITgcmCGridlat = latCMIT;
    UserVar.UaMITgcm.MITgcmGGridlon = lonGMIT;
    UserVar.UaMITgcm.MITgcmGGridlat = latGMIT;
    
elseif strcmp(UserVar.UaMITgcm.MITcoordinates,'xy')
    UserVar.UaMITgcm.MITgcmCGridX = lonCMIT;
    UserVar.UaMITgcm.MITgcmCGridY = latCMIT;
    UserVar.UaMITgcm.MITgcmGGridX = lonGMIT;
    UserVar.UaMITgcm.MITgcmGGridY = latGMIT;
    
end

%%%%%%%%%%%%
%% run Ua %%
%%%%%%%%%%%%
%setenv('UaHomeDirectory','./');
%UaHomeDirectory=getenv('UaHomeDirectory'); addpath(genpath(UaHomeDirectory));
Ua2D(UserVar);
