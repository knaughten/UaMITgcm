# Clean the experiment directory so you can start fresh.

import sys
sys.path.insert(0,'./')
import shutil
import os
import subprocess

from set_parameters import Options

# Make sure the user didn't call this accidentally
out = raw_input('This will delete all existing results if they are not backed up. Are you sure you want to proceed (yes/no)? ').strip()
while True:
    if out == 'yes':
        break
    if out == 'no':
        sys.exit()
    out = raw_input('Please answer yes or no. ').strip()

# Read simulation options so we have directories
options = Options()

# Remove everything in the output directory
# Easiest just to delete the whole directory and then create it again
shutil.rmtree(options.output_dir)
os.mkdir(options.output_dir)

# Look at everything in the Ua executable directory
for fname in os.listdir(options.ua_exe_dir):
    if fname.endswith('RestartFile.mat'):
        # Save the name of the restart file
        restart_name = fname
    # Don't care about mesh files
    elif fname in ['NewMeshFile.mat', 'AdaptMesh.mat']:
        pass    
    # Don't delete the Ua executable, run script, or other .mat files
    elif fname in ['Ua', 'Ua_MCR.sh'] or fname.endswith('.mat'):
        continue
    # Delete everything else
    path = options.ua_exe_dir+fname
    if os.path.isfile(path):
        os.remove(path)
    elif os.path.isdir(path):
        shutil.rmtree(path)

# Copy in the original restart with the correct name
orig_restart = raw_input('Enter path to original Ua restart file, or press enter if this is not a restart run: ')
if len(orig_restart) > 0:
    while True:
        if os.path.isfile(orig_restart):
            break
        orig_restart = raw_input('That file does not exist. Try again: ')
    shutil.copyfile(orig_restart, options.ua_exe_dir+restart_name)

# Now call the prepare_run.sh script to reset the MITgcm run directory
# Pass the path to scripts/ as an argument, because prepare_run.sh is called from outside its own directory
subprocess.check_output([options.mit_case_dir+'scripts/prepare_run.sh', options.mit_case_dir+'scripts/'])

# Delete some log files if they exist
for fname in os.listdir('./'):
    if fname in ['coupler_stdout', 'jobs.log'] or (fname.startswith('run_') and '.sh.o' in fname):
        os.remove(fname)
