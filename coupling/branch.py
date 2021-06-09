# Branch a simulation that is finished, to create another simulation that will
# pick up where this one ended. This is useful for eg a common spinup followed
# by multiple different transient runs.
# Call this from within the directory containing all your configurations (such as UaMITgcm/example).
# Give it two arguments: the old experiment name, and the new experiment name.
# Example: python ../coupling/branch.py WSFRIS_001 WSFRIS_002
# After running this script, extend the simulation in the new experiment,
# make any configuration changes, and restart by submitting run_coupler.sh.

import sys
import os
import shutil
from copy_case import do_copy_case, parse_name
from coupling_utils import copy_to_dir

# Parse the input arguments
old_name, old_dir = parse_name(sys.argv[1])
new_name, new_dir = parse_name(sys.argv[2])

# Build Options for old directory
sys.path.insert(0, './'+old_dir)
from set_parameters import Options
options = Options()

# Get some directories
old_output_dir = options.output_dir
new_output_dir = old_output_dir.replace(old_name, new_name)
old_mit_rundir = options.mit_run_dir
new_mit_rundir = old_mit_rundir.replace(old_name, new_name)
old_uaexe_dir = options.ua_exe_dir
new_uaexe_dir = old_uaexe_dir.replace(old_name, new_name)

# Make sure the old simulation is finished
if not os.path.isfile(old_output_dir + options.finished_file):
    print('Error (branch.py): experiment ' + old_name + ' is not finished. Branching will not work properly.')
    sys.exit()

# Copy the case as usual, but ignore the Ua restart file
do_copy_case(old_name, new_name, check_restart=False)
# Also need an output directory
os.mkdir(new_output_dir)

# Copy the correct files so the case will restart at the right place
# Calendar file
copy_to_dir(options.calendar_file, old_output_dir, new_output_dir)
if os.path.isfile(old_output_dir+options.eta_file):
    # eta log file
    copy_to_dir(options.eta_file, old_output_dir, new_output_dir)
# Finished file
copy_to_dir(options.finished_file, old_output_dir, new_output_dir)
# Melt rate file for Ua
copy_to_dir(options.ua_melt_file, old_output_dir, new_output_dir)
# MITgcm namelist
copy_to_dir('data', old_mit_rundir, new_mit_rundir)
# MITgcm pickup files
for fname in os.listdir(old_mit_rundir):
    if fname.startswith('pickup'):
        copy_to_dir(fname, old_mit_rundir, new_mit_rundir)
# MITgcm topography and pressure load files
copy_to_dir(options.bathyFile, old_mit_rundir, new_mit_rundir)
copy_to_dir(options.draftFile, old_mit_rundir, new_mit_rundir)
copy_to_dir(options.pload_file, old_mit_rundir, new_mit_rundir)
# MITgcm grid files for Ua
for fname in os.listdir(old_output_dir):
    if fname.endswith('.data') or fname.endswith('.meta'):
        copy_to_dir(fname, old_output_dir, new_output_dir)

# Copy contents of Ua directory, except for output files we don't care about (i.e. contents of subdirectories that aren't the ua_draft_file). Also rename any files which include the experiment name.
for fname in os.listdir(old_uaexe_dir):
    if os.path.isdir(old_uaexe_dir+fname):
        # Make a new subdirectory
        old_subdir = old_uaexe_dir+fname+'/'
        new_subdir = new_uaexe_dir+fname+'/'
        os.mkdir(new_subdir)
        # Just copy the draft file, if it's there
        for fname2 in os.listdir(old_subdir):
            if fname2 == options.ua_draft_file:
                copy_to_dir(fname2, old_subdir, new_subdir)
    elif old_name in fname:
        # Rename with new experiment name
        new_fname = fname.replace(old_name, new_name)
        shutil.copy(old_uaexe_dir+fname, new_uaexe_dir+new_fname)
    else:
        # Copy as normal
        copy_to_dir(fname, old_uaexe_dir, new_uaexe_dir)
