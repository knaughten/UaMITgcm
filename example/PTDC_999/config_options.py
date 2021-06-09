#################################################
# User-defined options for the configuration.
#################################################

###### 1. Server workflow options ######

### Experiment name, this will be stamped on some files
expt_name = 'PTDC_ARCHER2_999'

### Specify how to run Ua. 2 options:
### 'compiled': using Matlab Compiler Runtime, with an executable
###             which was created by Matlab Compiler on another machine
### 'matlab': using regular Matlab
### TODO: consider 'matlab' case in code
ua_option = 'compiled'

# Whether to convert MITgcm binary output to NetCDF using xmitgcm
# (Even if this is False, the MNC package in MITgcm is not supported.)
use_xmitgcm = True

# Format for Ua output
# For now the only option is 'matlab', later 'netcdf' will be added
ua_output_format = 'matlab'

# Optional base directory to simplify definition of directories below
# This variable won't be read by the coupler, so you don't have to use it.
work_dir = '/work/n02/n02/janryd69/UaMITgcm/cases/'+expt_name+'/'

### Path to the MITgcm case directory (containing run/, input/, etc.)
mit_case_dir = work_dir+'mitgcm_run/'
### Path to the Ua directory containing executable
ua_exe_dir = work_dir+'ua_run/'
### Path to the directory to centrally gather output
output_dir = work_dir+'output/'

### Archer budget to charge jobs to
budget_code = 'n02-PROPHET'


###### 2. Coupling options ######

### Total length of simulation (months)
total_time = 276
### Length of ocean spinup period (months)
spinup_time = 24
### Length of coupling timestep (months)
### total_time and spinup_time must be evenly divisible by couple_step
couple_step = 3

### Restart type for MITgcm. 2 options:
### 'zero': MITgcm will start from time 0 every coupling segment.
###         Initial conditions for temperature, salinity, u, v,
###         and sea ice variables will be calculated based on the dump
###         at the end of the last segment.
###         Other variables, such as sea surface height and
###         dynamics tendencies, will be set to zero.
###         With this option, you need to set dumpInitAndLast=.true.
###         in the input/data namelist.
### 'pickup': MITgcm will restart from the pickup file it writes
###           at the frequency given by pchkptFreq in input/data.
###           (This frequency will be set to the coupling timestep
###           by the code, if it's not already correct.)
###           If there are no changes in the ice shelf draft,
###           this represents a perfect restart with no loss of information.
restart_type = 'pickup'

### Calendar type. 3 options:
### 'standard': full calendar with leap years 
### 'noleap': every year is 365 days
### '360-day': every month is 30 days
### For 'standard', you must use the calendar package in MITgcm.
calendar_type = 'standard'
### How often to do time-averaged diagnostic output?
### 'monthly', 'daily', or 'end' (at the end of the segment)
### Note 'monthly' does not work with calendar_type='noleap'.
### Set output_names in part 4 so MITgcm uses this frequency.
output_freq = 'monthly'

### How should we deal with digging of the MITgcm domain
### (to ensure adjacent water columns are properly connected)?
### Three options:
### 'none': don't do any digging
### 'bathy': dig bathymetry which is too shallow
### 'draft': dig ice shelf drafts which are too deep
digging = 'bathy'

### Should we adjust velocities at each coupling timestep to preserve
### barotropic transport?
adjust_vel = True

### Is this a MISOMIP domain that needs a wall built at the north and south boundaries?
misomip_wall = False

### How should we calculate the pressure load anomaly of the ice shelf draft?
### This involves making an assumption about the properties of the water
### displaced by the draft.
### Two options:
### 'constant': assume the water has a constant temperature and salinity
### 'nearest': set the temperature and salinity with nearest-neighbour
### extrapolation from the cavity
pload_option = 'nearest'

### The next two variables only matter if pload_option = 'constant'.
### Set the constant temperature (C) and salinity (psu) to use.
pload_temp = -1.
pload_salt = 34.2

### Does the first Ua segment start from a restart file
### you made ahead of time?
ua_ini_restart = True


###### 3. MITgcm parameters ######

### Does your configuration of MITgcm include sea ice?
use_seaice = False
### Does your configuration of MITgcm use the calendar package?
use_cal_pkg = True

### Does your configuration have a different value for deltaTmom
### (not equal to deltaT) just for the first ocean segment?
### If so, set this variable to true, and make sure that input/data has
### deltaTmom set for the first segment. The code will comment it out
### in later segments so deltaTmom=deltaT implicitly.
use_ini_deltaTmom = False

### For the following variables, match their values to input/data.
### If they are unset there, search for their names in MITgcm's STDOUT.0000
### to find what they have been set to by default.
deltaT = 120
hFacMin = 0.05
hFacMinDr = 0.
readBinaryPrec = 64
rhoConst = 1024.
eosType = 'MDJWF'
### The following four variables only matter if eosType='LINEAR'.
### Note that Tref and Sref in input/data will be multiplied by
### the number of vertical levels; don't include this here
### (eg set Tref: -1. instead of 36*-1.)
tAlpha = 3.733e-5
sBeta = 7.843e-4
Tref = -1.
Sref = 34.2
### Number of vertical sea ice layers; match SEAICE_multDim in data.seaice.
### Only matters if use_seaice=True.
seaice_nz = 7

### Starting date of simulation
### Should match startDate_1 in data.cal
startDate = '19920101'


###### 4. Filenames ######

### Don't include any directories in these file names.
### The code will look for them in the appropriate directories.

### Name of plain-text file to keep track of calendar info
### (this will be created for you during the first segment):
calendar_file = 'calendar'

### Name of file that is created when simulation successfully finishes
finished_file = 'finished'

### Bathymetry file read by MITgcm. Should match the value in input/data.
bathyFile = 'bathymetry.shice'
### Ice shelf draft file read by MITgcm.
### Should match SHELFICEtopoFile in input/data.shelfice.
draftFile = 'shelfice_topo.bin'

### Initial conditions files read by MITgcm:
###
### Temperature (match hydrogThetaFile in input/data)
ini_temp_file = 'T_ini.bin'
### Salinity (match hydrogSaltFile in input/data)
ini_salt_file = 'S_ini.bin'
### Zonal velocity (match uVelInitFile in input/data)
### Only needed for restart_type='zero'.
### This is assumed not to exist at the beginning,
### it will be created with all zeros.
ini_u_file = 'U_ini.bin'
### Meridional velocity (match vVelInitFile in input/data)
ini_v_file = 'V_ini.bin'
### Free surface (match pSurfInitFile in input/data)
ini_eta_file = ''

### OBCS files read by MITgcm
### Temperature Southern/Western boundary
obcs_temp_file_S = 'OBSt'
obcs_temp_file_W = 'OBWt'
### Salinity Southern/Western boundary
obcs_salt_file_S = 'OBSs'
obcs_salt_file_W = 'OBWs'
### Temperature Southern/Western boundary
obcs_uvel_file_S = 'OBSu'
obcs_uvel_file_W = 'OBWu'
### Temperature Southern/Western boundary
obcs_vvel_file_S = 'OBSv'
obcs_vvel_file_W = 'OBWv'

### Pressure load anomaly file read by MITgcm.
### Should match SHELFICEloadAnomalyFile in input/data.shelfice.
pload_file = 'pload.mdjwf'

### Beginnings of the filenames of various output diagnostic files
### containing the given variables.
### Should match filename(x) in input/data.diagnostics
### for whichever value of x has those variables in fields(1,x)
###
### Contains SHIfwFlx time-averaged over whichever period
### you want Ua to see
### (you can have SHIfwFlx on another output stream too if you want
### output at a different frequency for analysis)
ismr_name = 'MITout_2D'
### Any files you want to output at output_freq.
### Will probably include ismr_name.
output_names = ['MITout_2D', 'MITout_3D']

### Name for NetCDF files converted by xmitgcm
### Doesn't really matter what this is,
### as long as it won't overwrite anything in run/
### and isn't 'dump_start.nc' or 'dump_end.nc'
mit_nc_name = 'output.nc'

### Melt rate file read by Ua
ua_melt_file = 'NewMeltrate.mat'
### Ice shelf draft file written by Ua
ua_draft_file = 'DataForMIT.mat'

### If you want different MITgcm options for the spinup
### and the coupled part of the simulation,
### you can make two versions of input/data.
### The first (saved as input/data) will be used for the spinup.
### The second (saved as input/something_else) will be copied to input/data
### after the spinup.
### If you want to do this, set swap_namelist_postinit to True
### and set namelist_postinit to the second filename (eg something_else)
swap_namelist_postinit = False
namelist_postinit = ''




