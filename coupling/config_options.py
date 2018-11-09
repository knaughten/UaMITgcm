#################################################
# User-defined options for the configuration.
#################################################


###### 1. Server workflow options ######

### Path to the MITgcm case directory (containing run/, input/, etc.)
### on whichever machine MITgcm is run
mit_case_dir = '/work/n02/n02/kaight/mitgcm/cases/MISOMIP_999/'


###### 2. Coupling options ######

### Length of coupling timestep (months)
couple_step = 6
### Calendar type. 3 options:
### 'standard': full calendar with leap years
### 'noleap': every year is 365 days
### '360-day': every month is 30 days
calendar_type = '360-day'

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


###### 4. Filenames ######

### Don't include any directories in these file names.
### The code will look for them in the appropriate directories.

### Name of plain-text file to keep track of calendar info
### (this will be created for you during the first segment):
calendar_file = 'calendar'

### Bathymetry file read by MITgcm. Should match the value in input/data.
bathyFile = 'bathymetry.shice'

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
### Contains SHIfwFlx time-averaged over some period,
### less than or equal to couple_step months
### (you can have SHIfwFlx on another output stream too if you want
### output at a different frequency for analysis)
ismr_name = 'MITout_2D'
### Contains THETA, SALT, UVEL, VVEL snapshot at end of simulation
final_state_name = 'FinalState'
### Contains SIarea, SIheff, SIhsnow, SIuice, SIvice snapshot
### at end of simulation
### (only matters if use_seaice = True)
seaice_final_state_name = ''



