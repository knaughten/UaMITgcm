import sys
sys.path.insert(0,'./')
import os
import shutil

from set_parameters import Options
from coupling_utils import copy_to_dir, line_that_matters, extract_first_int

# Make sure the user didn't call this accidentally
out = raw_input('This will delete all existing results following the restart point, unless they are backed up. Are you sure you want to proceed (yes/no)? ').strip()
while True:
    if out == 'yes':
        break
    if out == 'no':
        sys.exit()
    out = raw_input('Please answer yes or no. ').strip()

# Get date code to restart from
date_code = raw_input('Enter the date code to restart at (eg 199201). ').strip()
# Make sure it's a date
valid_date = len(date_code)==4
try:
    int(valid_date)
except(ValueError):
    valid_date = False
if not valid_date:
    print 'Error: invalid date code ' + date_code
    sys.exit()

# Read simulation options so we have directories
options = Options()

# Make sure this date code exists in the output directory
output_date_dir = options.output_dir + date_code + '/'
if not os.path.isdir(output_date_dir):
    print 'Error: ' + output_date_dir + ' does not exist'
    sys.exit()

# Copy the calendar file
copy_to_dir(options.calendar_file, options.output_date_dir, options.output_dir)

# Copy MITgcm run files. First figure out what files we need to copy.
# Geometry files and namelists which might change each timestep
mit_file_names = [options.draftFile, options.bathyFile, options.pload_file, 'data', 'data.diagnostics']
if options.restart_type == 'zero':
    # Initial conditions files
    mit_file_names += [options.ini_temp_file, options.ini_salt_file, options.ini_u_file, options.ini_v_file, options.ini_eta_file]
    if options.use_seaice:
        mit_file_names += [options.ini_area_file, options.ini_heff_file, options.ini_hsnow_file, options.ini_uice_file, options.ini_vice_file]
elif options.restart_type == 'pickup':
    # Pickup files
    # Figure out the initial timestep based on niter0
    niter0 = extract_first_int(line_that_matters(options.output_date_dir+'MITgcm/data', 'niter0'))
    # Reconstruct timestep stamp for pickup files we want
    niter0_stamp = str(niter0).zfill(10)
    mit_file_names += ['pickup.'+niter0_stamp+'.data', 'pickup.'+niter0_stamp+'.meta']
    if options.use_seaice:
        mit_file_names += ['pickup_seaice.'+niter0_stamp+'.data', 'pickup_seaice.'+niter0_stamp+'.meta']
# Now copy all the files
for fname in mit_file_names:
    copy_to_dir(fname, options.output_date_dir+'MITgcm/', options.mit_run_dir)

# Copy Ua restart file (saved at beginning of segment)
for fname in os.listdir(options.output_date_dir+'Ua/'):
    if fname.endswith('RestartFile.mat'):
        copy_to_dir(fname, options.output_date_dir+'Ua/', options.ua_exe_dir)
# Copy Ua melt rate file
copy_to_dir(options.ua_melt_file, options.output_date_dir+'Ua/', options.ua_exe_dir)

# Delete this output folder and all following
for dname in os.listdir(options.output_dir):
    # Make sure this is an output date folder
    if not os.path.isdir(options.output_dir+dname):
        # Not a directory
        continue
    try:
        int(dname)
    except(ValueError):
        # Not numerical
        continue
    if len(dname) != 4:
        # Not a date code
        continue
    if int(dname) >= int(date_code):
        # Now we can delete
        shutil.rmtree(options.output_dir+dname)
