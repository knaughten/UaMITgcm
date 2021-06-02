# Change the ocean timestep.
# Run this after a simulation has finished, and then extend it and restart.
# Give it two arguments: the old value of deltaT, and the new value.
# Example: python ../../coupling/change_ocean_timestep.py 600 300
# No need to change deltaT in config_options.py (this script will do it
# for you), although you will have to change total_time as needed.

import sys
sys.path.insert(0,'./')
import os
from set_parameters import Options
from coupling_utils import line_that_matters, replace_line, extract_first_int

old_deltaT = int(sys.argv[1])
new_deltaT = int(sys.argv[2])
options = Options()
namelist = options.mit_run_dir + 'data'

# Update deltaT in config_options.py and mitgcm_run/run/data
for file_name in ['config_options.py', namelist]:
    print('Updating deltaT in ' + file_name)
    # Try with space
    old_line = line_that_matters(file_name, 'deltaT =', throw_error=False)
    if old_line is None:
        # Try without space
        old_line = line_that_matters(file_name, 'deltaT=', throw_error=False)
        if old_line is None:
            print('Error (change_ocean_timestep): Cannot find deltaT in ' + file_name)
            sys.exit()
    replace_line(file_name, old_line, old_line.replace(str(old_deltaT), str(new_deltaT)))

# Get old value of niter0
niter0_line = line_that_matters(namelist, 'niter0')
# Trim the beginning bit
i = niter0_line.index('=')
niter0_old = extract_first_int(niter0_line[i:])
# Get new value of niter0
niter0_new = niter0_old*old_deltaT/float(new_deltaT)
# Make sure it's a round number
if int(niter0_new) != niter0_new:
    print('Error (change_ocean_timestep): This combination of timesteps does not work as niter0 is not evenly divided.')
    sys.exit()
niter0_new = int(niter0_new)
print('Updating niter0 in ' + namelist + ' from ' + str(niter0_old) + ' to ' + str(niter0_new))
replace_line(namelist, niter0_line, ' niter0='+str(niter0_new)+',\n')

# Get timestep number in pickup file (will be 1 simulation segment ahead of niter0)
for fname in os.listdir(options.mit_run_dir):
    if fname.startswith('pickup.') and fname.endswith('.data') and (not fname.startswith('pickup.ckpt')):
        pickup_tstep_old = extract_first_int(fname)
        break
# Scale it and check as before
pickup_tstep_new = pickup_tstep_old*old_deltaT/float(new_deltaT)
if int(pickup_tstep_new) != pickup_tstep_new:
    print('Error (change_ocean_timestep): This combination of timesteps does not work as the pickup timestep is not evenly divided.')
    sys.exit()
pickup_tstep_new = int(pickup_tstep_new)
print('Renaming pickup files from timestep ' + str(pickup_tstep_old) + ' to ' + str(pickup_tstep_new))
for fname in os.listdir(options.mit_run_dir):
    if str(pickup_tstep_old) in fname:
        fname_new = fname.replace(str(pickup_tstep_old).zfill(10), str(pickup_tstep_new).zfill(10))
        os.rename(options.mit_run_dir+fname, options.mit_run_dir+fname_new)
        
        


