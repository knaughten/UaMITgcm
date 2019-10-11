# Copy a configuration to one with a new name but all the same settings.
# Call this from within the directory containing all your configurations (such as UaMITgcm/examples).
# Give it two arguments: the old experiment name, and the new experiment name.
# Example: python ../coupling/copy_case.py WSFRIS_999 WSFRIS_001

import sys
from coupling_utils import copy_to_dir, line_that_matters, replace_line

old_name = sys.argv[1]
new_name = sys.arvg[2]
if old_name.endswith('/'):
    old_name = old_name[:-1]
if new_name.endswith('/'):
    new_name = new_name[:-1]
old_dir = old_name+'/'
new_dir = new_name+'/'

# Add the existing configuration to the path so we can read config_options.py
sys.path.insert(0, './'+old_dir)
from set_parameters import Options
options = Options()

# Paths to subdirectories
old_mit_dir = options.mit_case_dir
new_mit_dir = old_mit_dir.replace(old_name, new_name)
old_build_dir = old_mit_dir + 'build/'
new_build_dir = new_mit_dir + 'build/'
old_uapost_dir = old_dir + 'ua_postprocess/'
new_uapost_dir = new_dir + 'ua_postprocess/'
old_uaexe_dir = options.mit_exe_dir
new_uaexe_dir = old_uaexe_dir.replace(old_name, new_name)

# Root directory
os.mkdir(new_dir)
for fname in os.listdir(old_dir):
    if fname.endswith('.sh') or fname.endswith('.py') or fname=='README':
        copy_to_dir(fname, old_dir, new_dir)

# MITgcm case directory
os.mkdir(new_mit_dir)
os.mkdir(new_mit_dir+'run/')
os.mkdir(new_build_dir)
copy_to_dir('mitgcmuv', old_build_dir, new_build_dir)
copy_to_dir('genmake.log', old_build_dir, new_build_dir)
shutil.copytree(old_mit_dir+'code/', new_mit_dir+'code/')
shutil.copytree(old_mit_dir+'input/', new_mit_dir+'input/')
shutil.copytree(old_mit_dir+'scripts/', new_mit_dir+'scripts/')

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
for fname in os.listdir(old_uaexe_dir):
    if fname in ['Ua', 'Ua_MCR.sh'] or (fname.endswith('.mat') and (not fname.endswith('RestartFile.mat')) and fname not in ['NewMeshFile.mat', 'AdaptMesh.mat']):
        copy_to_dir(fname, old_uaexe_dir, new_uaexe_dir)

# Change experiment name in config_options.py
options_file = new_dir + 'config_options.py'
old_line = line_that_matters(options_file, old_name, ignore_case=False)
replace_line(options_file, old_line, old_line.replace(old_name, new_name))
