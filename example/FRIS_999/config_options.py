#################################################
# User-defined options for the configuration.
#################################################


###### 1. Server workflow options ######

expt_name = 'FRIS_999'

use_xmitgcm = True

# Base directory to simplify definition of directories below
work_dir = '/work/n02/n02/kaight/UaMITgcm/example/'+expt_name+'/'
mit_case_dir = work_dir+'mitgcm_run/'
ua_exe_dir = work_dir+'ua_run/'
output_dir = work_dir+'output/'

budget_code = 'n02-FISSA'


###### 2. Coupling options ######

total_time = 12*20  # Update to 12*40 after spinup
spinup_time = 12*20  # Update to 0 after spinup
couple_step = 6
repeat = False   # Update to True after spinup

calendar_type = 'standard'
output_freq = 'monthly'

digging = 'bathy'
filling = True
adjust_vel = True
preserve_ocean_mask = True

pload_option = 'nearest'


###### 3. MITgcm parameters ######

coordinates = 'latlon'

use_seaice = True
use_cal_pkg = True

use_ini_deltaTmom = True

deltaT = 450
hFacMin = 0.1
hFacMinDr = 20.
readBinaryPrec = 64
rhoConst = 1035.
eosType = 'MDJWF'
seaice_nz = 7

startDate = '19790101'



###### 4. Filenames ######

bathyFile = 'bathy_WSS'
draftFile = 'draft_WSS'

pload_file = 'pload_WSS'

ismr_name = 'state2D'
etan_name = 'state2D'
output_names = ['state2D', 'stateUVEL', 'stateVVEL', 'stateWVEL', 'stateTHETA', 'stateSALT', 'statePSI', 'stateEXF', 'stateICE']
