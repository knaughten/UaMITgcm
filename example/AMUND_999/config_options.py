
###### 1. Server workflow options ######

expt_name = 'AMUND_999'
use_xmitgcm = True
save_dumps = False
save_tmp_ckpt = False

work_dir = '/work/n02/n02/kaight/UaMITgcm/example/'+expt_name+'/'
mit_case_dir = work_dir+'mitgcm_run/'
ua_exe_dir = work_dir+'ua_run/'
output_dir = work_dir+'output/'

budget_code = 'n02-NES011994'

rsync_output = True
rsync_host = 'kaight@bslcenb.nerc-bas.ac.uk'
rsync_path = '/data/oceans_output/shelf/kaight/archer2_mitgcm/'

###### 2. Coupling options ######

total_time = 12*116 #211
spinup_time = 12*116
couple_step = 12

melt_coupling = 'avg'

calendar_type = 'noleap'
output_freq = 'monthly'

digging = 'bathy'
filling = True
adjust_vel = True

preserve_ocean_mask = True  # Necessary for Bear Ridge grounded icebergs

pload_option = 'constant'
pload_temp = 1.
pload_salt = 34.5

ua_ini_restart = True

correct_obcs_online = True
obcs_transient = True
correct_obcs_steps = 1

###### 3. MITgcm parameters ######

coordinates = 'latlon'

use_seaice = True
use_cal_pkg = True

deltaT = 600
hFacMin = 0.1
hFacMinDr = 10.
rhoConst = 1028.5
seaice_nz = 7

startDate = '18900101'

use_addmass = True
seaice_sigma = False


###### 4. Filenames ######

bathyFile = 'bathy_AMUND'
draftFile = 'draft_AMUND'
pload_file = 'pload_AMUND'

ismr_name = 'state2D'
etan_name = 'state2D'
output_names = ['state2D', 'stateExf', 'stateTheta', 'stateSalt', 'stateVel']

obcs_file_w_u = 'LENS_ens001_UVEL_W_'
obcs_file_e_u = 'LENS_ens001_UVEL_E_'
obcs_file_n_v = 'LENS_ens001_VVEL_N_'
