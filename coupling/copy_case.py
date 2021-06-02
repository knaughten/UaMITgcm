# Copy a configuration to one with a new name but all the same settings.
# Call this from within the directory containing all your configurations (such as UaMITgcm/example).
# Give it two arguments: the old experiment name, and the new experiment name.
# Example: python ../coupling/copy_case.py WSFRIS_999 WSFRIS_001

import sys
import os
import shutil
import subprocess
from coupling_utils import copy_to_dir, line_that_matters, replace_line, copy_ua_restart

# Helper function to get the experiment name (no slash) and the directory (slash)
def parse_name (expt_name):

    if expt_name.endswith('/'):
        expt_name = expt_name[:-1]
    expt_dir = expt_name + '/'
    return expt_name, expt_dir


# Function to encapsulate most of this so we can call it from within branch.py
def do_copy_case (old_name, new_name, check_restart=True):

    old_name, old_dir = parse_name(old_name)
    new_name, new_dir = parse_name(new_name)

    if not os.path.isdir(old_dir):
        print('Error (copy_case): ' + old_dir + ' does not exist')
        sys.exit()
    if os.path.isdir(new_dir):
        print('Error (copy_case): ' + new_dir + ' already exists')
        sys.exit()

    # Add the existing configuration to the path so we can read config_options.py
    sys.path.insert(0, './'+old_dir)
    from set_parameters import Options
    options = Options()

    # Paths to subdirectories
    old_mit_dir = options.mit_case_dir
    new_mit_dir = old_mit_dir.replace(old_name, new_name)
    old_build_dir = old_mit_dir + 'build/'
    new_build_dir = new_mit_dir + 'build/'
    old_scripts_dir = old_mit_dir + 'scripts/'
    new_scripts_dir = new_mit_dir + 'scripts/'
    old_uapost_dir = old_dir + 'ua_postprocess/'
    new_uapost_dir = new_dir + 'ua_postprocess/'
    old_uaexe_dir = options.ua_exe_dir
    new_uaexe_dir = old_uaexe_dir.replace(old_name, new_name)

    # Root directory
    os.mkdir(new_dir)
    for fname in os.listdir(old_dir):
        if fname.endswith('.sh') or fname.endswith('.py') or fname=='README':
            copy_to_dir(fname, old_dir, new_dir)

    # MITgcm case directory
    os.mkdir(new_mit_dir)
    copy_to_dir('linux_amd64_archer_ifort', old_mit_dir, new_mit_dir)
    os.mkdir(new_mit_dir+'run/')
    os.mkdir(new_build_dir)
    copy_to_dir('mitgcmuv', old_build_dir, new_build_dir)
    copy_to_dir('genmake.log', old_build_dir, new_build_dir)
    shutil.copytree(old_mit_dir+'code/', new_mit_dir+'code/')
    shutil.copytree(old_mit_dir+'input/', new_mit_dir+'input/')
    shutil.copytree(old_scripts_dir, new_scripts_dir)
    # Now call the prepare_run.sh script to reset the MITgcm run directory
    subprocess.check_output([new_scripts_dir+'prepare_run.sh', new_scripts_dir])

    # Ua custom source code directory
    shutil.copytree(old_dir+'ua_custom/', new_dir+'ua_custom/')

    # Ua postprocessing directory, if it exists
    if os.path.isdir(old_uapost_dir):
        os.mkdir(new_uapost_dir)
        for fname in os.listdir(old_uapost_dir):
            if not (fname.startswith('matlab') and fname.endswith('.out')) and not fname.startswith('run_postprocess.o'):
                copy_to_dir(fname, old_uapost_dir, new_uapost_dir)

    # Ua executable directory
    os.mkdir(new_uaexe_dir)
    new_restart_name = None
    for fname in os.listdir(old_uaexe_dir):
        if fname.endswith('RestartFile.mat'):
            # Save the name of the restart file, with the experiment name updated
            new_restart_name = fname.replace(old_name, new_name)
        if fname in ['Ua', 'Ua_MCR.sh'] or (fname.endswith('.mat') and (not fname.endswith('RestartFile.mat')) and fname not in ['NewMeshFile.mat', 'AdaptMesh.mat']):
            copy_to_dir(fname, old_uaexe_dir, new_uaexe_dir)
    if new_restart_name is not None:
        # The old simulation had a restart, so the new one might need one too
        if check_restart:
            # See what the user thinks
            copy_ua_restart(new_uaexe_dir, new_restart_name)
        else:
            # Don't do anything yet - the restart will be copied by another script
            pass

    # Change experiment name in config_options.py
    options_file = new_dir + 'config_options.py'
    old_line = line_that_matters(options_file, old_name, ignore_case=False)
    replace_line(options_file, old_line, old_line.replace(old_name, new_name))


if __name__ == "__main__":

    # Parse input arguments
    do_copy_case(sys.argv[1], sys.argv[2])
