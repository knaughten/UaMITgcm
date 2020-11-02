#############################################################
# Important note: PAS is an ocean-only configuration which is
# only within UaMITgcm so it can use the OBCS balancing code.
# Some coupling variables are not specified here because the
# coupling code is never used.
#############################################################

###### 1. Server workflow options ######

expt_name = 'PAS_999'
use_xmitgcm = True
save_dumps = False

work_dir = '/work/n02/n02/kaight/UaMITgcm/example/PAS_999/'
mit_case_dir = work_dir+'mitgcm_run/'
output_dir = work_dir+'output/'

budget_code = 'n02-NES011994'


###### 2. Coupling options ######

total_time = 64*12  #124*12
spinup_time = 64*12  #124*12
couple_step = 12

calendar_type = 'standard'  #'noleap'
output_freq = 'monthly'

digging = False
adjust_vel = False

correct_obcs_online = True
obcs_transient = False


###### 3. MITgcm parameters ######

coordinates = 'latlon'

use_seaice = True
use_cal_pkg = True

deltaT = 600
hFacMin = 0.1
hFacMinDr = 10.
rhoConst = 1028.5
seaice_nz = 7

startDate = '19550101'  #'18900101'


###### 4. Filenames ######

bathyFile = 'bathymetry_bedmach.bin'
draftFile = 'shelfice.bin'
pload_file = 'panom.bin'

ismr_name = 'state2D'
etan_name = 'state2D'
output_names = ['state2D', 'stateExf', 'stateTheta', 'stateSalt', 'stateUvel', 'stateVvel', 'stateWvel']

obcs_file_w_u = 'OBWuvel_sose_corr.bin'
obcs_file_e_u = 'OBEuvel_sose_corr.bin'
obcs_file_n_v = 'OBNvvel_sose_corr.bin'
