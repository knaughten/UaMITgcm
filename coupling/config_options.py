#################################################
# User-defined options for the configuration.
#################################################


###### 1. Server workflow options ######

### Specify how to run Ua. 2 options:
### 'compiled': using Matlab Compiler Runtime, with an executable
###             which was created by Matlab Compiler on another machine
### 'matlab': using regular Matlab
### TODO: consider 'matlab' case in code
ua_option = 'compiled'

### Path to the MITgcm case directory (containing run/, input/, etc.)
mit_case_dir = '/work/n02/n02/kaight/mitgcm/cases/MISOMIP_999/'
### Path to the Ua directory containing executable
ua_exe_dir = '/work/n02/n02/kaight/Ua_exe_MISOMIP_999/'
### Path to the directory to centrally gather output
output_dir = '/work/n02/n02/kaight/MISOMIP_999_output/'

### Archer budget to charge jobs to
budget_code = 'n02-NEL013770'

# Whether to convert MITgcm binary output to NetCDF using xmitgcm
# (Even if this is False, the MNC package in MITgcm is not supported.)
use_xmitgcm = True


###### 2. Coupling options ######

### Total length of simulation (months)
total_time = 120
### Length of ocean spinup period (months)
spinup_time = 12
### Length of coupling timestep (months)
### total_time and spinup_time must be evenly divisible by couple_step
couple_step = 6

### Calendar type. 3 options:
### 'standard': full calendar with leap years 
### 'noleap': every year is 365 days
### '360-day': every month is 30 days
### For 'standard', you must use the calendar package in MITgcm.
calendar_type = '360-day'
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
digging = 'draft'

### Does the x-coordinate of your domain refer to longitude?
x_is_lon = False

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


###### 3. MITgcm parameters ######

### Does your configuration of MITgcm include sea ice?
use_seaice = False

### For the following variables, match their values to input/data.
### If they are unset there, search for their names in MITgcm's STDOUT.0000
### to find what they have been set to by default.
deltaT = 300
hFacMin = 0.05
hFacMinDr = 0.
readBinaryPrec = 64
readStatePrec = 64
rhoConst = 1028.
eosType = 'LINEAR'
### The following four variables only matter if eosType='LINEAR'.
### Note that Tref and Sref in input/data will be multiplied by
### the number of vertical levels; don't include this here
### (eg set Tref: -1. instead of 36*-1.)
tAlpha = 3.733e-5
sBeta = 7.843e-4
Tref = -1.
Sref = 34.2

### Starting date of simulation
### Should match startDate_1 in data.cal
startDate = '19790101'



###### 4. Filenames ######

### Don't include any directories in these file names.
### The code will look for them in the appropriate directories.

### Name of plain-text file to keep track of calendar info
### (this will be created for you during the first segment):
calendar_file = 'calendar'

### Bathymetry file read by MITgcm. Should match the value in input/data.
bathyFile = 'bathymetry.shice'
### Original bathymetry file before digging,
### written out during domain generation
### (see save_pre_digging option in remove_grid_problems function,
### file make_domain.py, repository mitgcm_python)
### Only matters if digging='bathy'
bathyFileOrig = ''

### Ice shelf draft file read by MITgcm.
### Should match SHELFICEtopoFile in input/data.shelfice.
draftFile = 'shelfice_topo.bin'

### Initial conditions files read by MITgcm:
###
### Temperature (match hydrogThetaFile in input/data)
ini_temp_file = 'lev_t.shice'
### Salinity (match hydrogSaltFile in input/data)
ini_salt_file = 'lev_s.shice'
### Zonal velocity (match uVelInitFile in input/data)
ini_u_file = 'u_init.bin'
### Meridional velocity (match vVelInitFile in input/data)
ini_v_file = 'v_init.bin'

### Sea ice initial conditions files read by MITgcm
### (only matters if use_seaice=True):
###
### Sea ice area (match AreaFile in input/data.seaice)
ini_area_file = ''
### Sea ice thickness (match HeffFile in input/data.seaice)
ini_heff_file = ''
### Snow thickness (match HsnowFile in input/data.seaice)
ini_hsnow_file = ''
### Sea ice zonal velocity (match uIceFile in input/data.seaice)
ini_uice_file = ''
### Sea ice meridional velocity (match vIceFile in input/data.seaice)
ini_vice_file = ''

### Pressure load anomaly file read by MITgcm.
### Should match SHELFICEloadAnomalyFile in input/data.shelfice.
pload_file = 'phi0surf.bin'

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
### Contains THETA, SALT, UVEL, VVEL snapshot at end of simulation
final_state_name = 'FinalState'
### Contains SIarea, SIheff, SIhsnow, SIuice, SIvice snapshot
### at end of simulation
### (only matters if use_seaice = True)
seaice_final_state_name = ''
### Any files you want to output at output_freq.
### Will probably include ismr_name.
### Should not include any snapshots including the final state.
output_names = ['MITout_2D', 'MITout_3D']
### Name for NetCDF files converted by xmitgcm
### Doesn't really matter what this is,
### as long as it won't overwrite anything in run/
mit_nc_name = 'output.nc'

### Melt rate file read by Ua
ua_melt_file = 'NewMeltrate.mat'
### Ice shelf draft file written by Ua
ua_draft_file = 'DataForMIT.mat'




