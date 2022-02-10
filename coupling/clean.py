# Clean the experiment directory so you can start fresh.

import sys
sys.path.insert(0,'./')
import shutil
import os
import subprocess

from set_parameters import Options
from coupling_utils import copy_ua_restart

# Function to clean the given Ua executable directory
def clean_ua (directory):
    restart_name = None
    # Look at everything in the Ua executable directory
    for fname in os.listdir(directory):
        if fname.endswith('RestartFile.mat'):
            # Save the name of the restart file
            restart_name = fname
        # Don't care about mesh files
        elif fname in ['NewMeshFile.mat', 'AdaptMesh.mat']:
            pass    
        # Don't delete the Ua executable, run script, options file, or other .mat files
        elif fname in ['Ua', 'Ua_MCR.sh', 'options_for_ua'] or fname.endswith('.mat'):
            continue
        # Delete everything else
        path = directory+fname
        if os.path.isfile(path):
            os.remove(path)
        elif os.path.isdir(path):
            shutil.rmtree(path)
    if restart_name is not None:
        # Copy in the original restart with the correct name
        copy_ua_restart(directory, restart_name)


# Main processing
if __name__ == "__main__":

    # Make sure the user didn't call this accidentally
    out = input('This will delete all existing results if they are not backed up. Are you sure you want to proceed (yes/no)? ').strip()
    while True:
        if out == 'yes':
            break
        if out == 'no':
            sys.exit()
        out = input('Please answer yes or no. ').strip()

    # Read simulation options so we have directories
    options = Options()

    # Remove everything in the output directory
    # Easiest just to delete the whole directory and then create it again
    shutil.rmtree(options.output_dir)
    os.mkdir(options.output_dir)

    # Clean Ua executable directory
    clean_ua(options.ua_exe_dir)

    # Now call the prepare_run.sh script to reset the MITgcm run directory
    # Pass the path to scripts/ as an argument, because prepare_run.sh is called from outside its own directory
    subprocess.check_output([options.mit_case_dir+'scripts/prepare_run.sh', options.mit_case_dir+'scripts/'])

    # Delete some log files if they exist
    for fname in os.listdir('./'):
        if fname in ['coupler_stdout', 'jobs.log'] or (fname.startswith('run_') and '.sh.o' in fname) or fname.startswith(options.expt_name+'o.o') or fname.startswith(options.expt_name+'i.o') or (fname.startswith('slurm-') and fname.endswith('.out')):
            os.remove(fname)
