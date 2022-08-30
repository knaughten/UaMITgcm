#################################################
# Default options for configuration.
# Overwritten by anything in default_config_options.py.
#################################################


###### 1. Server workflow options ######

### Experiment name, this will be stamped on some files
expt_name = 'EXPT_999'

### Specify how to run Ua. 2 options:
### 'compiled': using Matlab Compiler Runtime, with an executable
###             which was created by Matlab Compiler on another machine
### 'matlab': using regular Matlab
### TODO: consider 'matlab' case in code
ua_option = 'compiled'

# Whether to convert MITgcm binary output to NetCDF using xmitgcm
# (Even if this is False, the MNC package in MITgcm is not supported.)
use_xmitgcm = False
# Whether to save initial and final dumps for each timestep
# Only valid if use_xmitgcm is True.
# If use_xmitgcm is False, you can just switch off dumpInitAndLast instead,
# unless you have restart_type='zero'.
save_dumps = True
# Whether to save temporary checkpoints (eg pickup.ckptA.data)
save_tmp_ckpt = True

# Format for Ua output
# For now the only option is 'matlab', later 'netcdf' will be added
ua_output_format = 'matlab'

### Path to the MITgcm case directory (containing run/, input/, etc.)
mit_case_dir = '/home/mitgcm_run/'
### Path to the Ua directory containing executable
ua_exe_dir = '/home/ua_run/'
### Path to the directory to centrally gather output
output_dir = '/home/output/'

### Archer budget to charge jobs to
budget_code = ''

### Whether to rsync output to another server after each segment
### If True, you must have ssh keys set up!
rsync_output = False
### Get the username to set default values for next parameters
import getpass
user = getpass.getuser()
### Host server including username
rsync_host = user+'@bslcenc.nerc-bas.ac.uk'
### Directory on host server to copy this case to
rsync_path = '/data/oceans_output/shelf/'+user+'/'


###### 2. Coupling options ######

### Total length of simulation (months)
total_time = 24
### Length of ocean spinup period (months)
spinup_time = 6
### Length of coupling timestep (months)
### total_time and spinup_time must be evenly divisible by couple_step
couple_step = 6
### Is this the second (or following) repetition of a forcing period?
### (for example, run the period 1979-2014 twice)
### Only matters for the segment when you're restarting the period.
### After this, if you want to extend the run
### (i.e. finish it, extend total_time, and resubmit run_coupler.sh)
### you have to set repeat back to False, or it will start from the beginning.
repeat = False

### Which melt rates to mass from MITgcm to Ua:
### 'last': melt rates from the last available output step
### 'avg': melt rates averaged over the entire coupling interval
### 'all': transient melt rates over the entire coupling interval
melt_coupling = 'last'

### Option to "mirror": re-run the ocean segments of a coupled simulation,
### pulling the geometry files from a previously finished simulation each segment.
### This is useful if you want to re-run with extra ocean diagnostics,
### because Ua is not bit-reproducible and so the results will slightly change
### if you just rerun the coupled ice-ocean setup.
### You must set total_time=spinup_time for this to work.
mirror = False
### Path to the output directory of the mirrored experiment.
mirror_path = ''
### Path to the simulation segment output to mirror the final geometry to - only do this if the mirrored run will be branched into something else.
mirror_path_final = ''

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
calendar_type = '360-day'
### How often to do time-averaged diagnostic output?
### 'monthly', 'daily', or 'end' (at the end of the segment)
### Set output_names in part 4 so MITgcm uses this frequency.
output_freq = 'monthly'

### How should we deal with digging of the MITgcm domain
### (to ensure adjacent water columns are properly connected)?
### Three options:
### 'none': don't do any digging
### 'bathy': dig bathymetry which is too shallow
### 'draft': dig ice shelf drafts which are too deep
digging = 'bathy'
### Should we dig full cells instead of the minimum amount
### (needed to match PAS domain generation)?
dig_full_cells = False
### Should we fill isolated single bottom cells to prevent pooling
### of dense water?
### This is a really good thing to do, but you also need to have it
### in the initial domain setup, so it is False by default.
filling = False

### Should we adjust velocities at each coupling timestep to preserve
### barotropic transport?
adjust_vel = True

### Is this a MISOMIP domain that needs a wall built at the north and south boundaries?
misomip_wall = False
### Flag to preserve the MITgcm bathymetry everywhere outside the Ua domain (i.e. the open ocean)
preserve_open_ocean_bathy = False
### Flag to preserve the MITgcm land mask in regions outside the Ua domain. 
preserve_ocean_mask = False
### Flag to allow static ice shelves in regions outside the Ua domain.
preserve_static_ice = False

### How should we calculate the pressure load anomaly of the ice shelf draft?
### This involves making an assumption about the properties of the water
### displaced by the draft.
### Two options:
### 'constant': assume the water has a constant temperature and salinity
### 'nearest': set the temperature and salinity with nearest-neighbour
### extrapolation from the cavity
pload_option = 'constant'

### The next two variables only matter if pload_option = 'constant'.
### Set the constant temperature (C) and salinity (psu) to use.
pload_temp = -1.
pload_salt = 34.2

### Does the first Ua segment start from a restart file
### you made ahead of time?
ua_ini_restart = False

### Do you want the coupler to adjust the incoming OBCS velocities such that
### the volume of the domain is approximately conserved?
correct_obcs_online = False
### Are the OBCS transient (one file per year) or a monthly climatology
### (the same yearly file over and over)?
### If False, you must make a copy of each OBCS file with the suffix ".master"
### so that a new correction can be applied each year.
obcs_transient = True
### How many coupling steps to average over for the OBCS corrections?
### Must set this up so it averages over a multiple of 12 months.
correct_obcs_steps = 1
### Threshold of acceptable SSH anomaly before OBCS corrections are triggered
### (absolute value, in metres)
obcs_threshold = 0

###### 3. MITgcm parameters ######

### Are the MITgcm coordinates 'xy' or 'latlon'?
coordinates = 'xy'

### Does your configuration of MITgcm include sea ice?
use_seaice = False
### Does your configuration of MITgcm use the ptracers package?
use_ptracers = False
### Does your configuration of MITgcm use the calendar package?
use_cal_pkg = False

### Does your configuration have a different value for deltaTmom
### (not equal to deltaT) just for the first ocean segment?
### If so, set this variable to true, and make sure that input/data has
### deltaTmom set for the first segment. The code will comment it out
### in later segments so deltaTmom=deltaT implicitly.
use_ini_deltaTmom = False

### For the following variables, match their values to input/data.
### If they are unset there, search for their names in MITgcm's STDOUT.0000
### to find what they have been set to by default.
deltaT = 600
hFacMin = 0.1
hFacMinDr = 20.
readBinaryPrec = 64
rhoConst = 1035.
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
### Should match startDate_1 in data.cal, if the calendar package is used
### Otherwise set it to whatever you want!
startDate = '20000101'

### Does the ocean use the addMass package?
use_addmass = False
### Does the sea ice use sigma terms? (Check in pickup_seaice.*.meta)
seaice_sigma = True


###### 4. Filenames ######

### Don't include any directories in these file names.
### The code will look for them in the appropriate directories.

### Name of plain-text file to keep track of calendar info
### (this will be created for you during the first segment):
calendar_file = 'calendar'

### Name of file that is created when simulation successfully finishes
finished_file = 'finished'

### Name of log file for sea surface height. Only used if correct_obcs_online=True and correct_obcs_steps > 1.
eta_file = 'eta_log'

### Bathymetry file read by MITgcm. Should match the value in input/data.
bathyFile = 'bathy'
### Ice shelf draft file read by MITgcm.
### Should match SHELFICEtopoFile in input/data.shelfice.
draftFile = 'draft'

### Initial conditions files read by MITgcm
### Only needed for restart_type='zero'
###
### Temperature (match hydrogThetaFile in input/data)
ini_temp_file = 'THETA.ini'
### Salinity (match hydrogSaltFile in input/data)
ini_salt_file = 'SALT.ini'
### Zonal velocity (match uVelInitFile in input/data)
### This is assumed not to exist at the beginning,
### it will be created with all zeros.
ini_u_file = 'UVEL.ini'
### Meridional velocity (match vVelInitFile in input/data)
ini_v_file = 'VVEL.ini'
### Free surface (match pSurfInitFile in input/data)
ini_eta_file = 'ETAN.ini'

### Sea ice initial conditions files read by MITgcm
### (only matters if use_seaice=True and restart_type='zero')
### They will be created if they don't exist and restart_type='zero'.
###
### Sea ice area (match AreaFile in input/data.seaice)
ini_area_file = 'SIarea.ini'
### Sea ice thickness (match HeffFile in input/data.seaice)
ini_heff_file = 'SIheff.ini'
### Snow thickness (match HsnowFile in input/data.seaice)
ini_hsnow_file = 'SIhsnow.ini'
### Sea ice zonal velocity (match uIceFile in input/data.seaice)
ini_uice_file = 'SIuice.ini'
### Sea ice meridional velocity (match vIceFile in input/data.seaice)
ini_vice_file = 'SIvice.ini'

### Pressure load anomaly file read by MITgcm.
### Should match SHELFICEloadAnomalyFile in input/data.shelfice.
pload_file = 'pload'

### Beginnings of the filenames of various output diagnostic files
### containing the given variables.
### Should match filename(x) in input/data.diagnostics
### for whichever value of x has those variables in fields(1,x)
###
### Contains SHIfwFlx time-averaged over whichever period
### you want Ua to see
### (you can have SHIfwFlx on another output stream too if you want
### output at a different frequency for analysis)
ismr_name = 'state2D'
### Contains ETAN (only needed if correct_obcs_online)
etan_name = 'state2D'
### Any files you want to output at output_freq.
### Will probably include ismr_name and etan_name.
output_names = ['state2D', 'stateUVEL', 'stateVVEL', 'stateWVEL', 'stateTHETA', 'stateSALT', 'statePSI', 'stateEXF', 'stateICE']

### Name for NetCDF files converted by xmitgcm
### Doesn't really matter what this is,
### as long as it won't overwrite anything in run/
### and isn't 'dump_start.nc' or 'dump_end.nc'
mit_nc_name = 'output.nc'

### Melt rate file read by Ua
ua_melt_file = 'NewMeltrate.mat'
### Ice shelf draft file written by Ua
ua_draft_file = 'DataForMIT.mat'

### Beginnings of filenames for OBCS normal velocities (followed by the year)
### Only matters if correct_obcs_online = True.
### For boundaries which are closed, just set to None.
### Make sure that mitgcm_run/scripts/prepare_run.sh copies these files into
### mitgcm_run/run/, not just links them, as they will be overwritten!
obcs_file_w_u = None
obcs_file_e_u = None
obcs_file_s_v = None
obcs_file_n_v = None



