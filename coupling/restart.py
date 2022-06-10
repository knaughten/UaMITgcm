# Restart from the middle of a coupled simulation. Doesn't work if you're restarting from the end - if so, just submit run_coupler.sh!

import sys
sys.path.insert(0,'./')
import os
import shutil

from set_parameters import Options
from coupling_utils import copy_to_dir, line_that_matters, extract_first_int, make_tmp_copy, submit_job, add_months
from clean import clean_ua

if __name__ == "__main__":

    # Make sure the user didn't call this accidentally
    out = input('This will delete all existing results following the restart point, unless they are backed up. Are you sure you want to proceed (yes/no)? ').strip()
    while True:
        if out == 'yes':
            break
        if out == 'no':
            sys.exit()
        out = input('Please answer yes or no. ').strip()

    # Get date code to restart from
    date_code = input('Enter the date code to restart at (eg 199201): ').strip()
    # Make sure it's a date
    valid_date = len(date_code)==6
    try:
        int(valid_date)
    except(ValueError):
        valid_date = False
    if not valid_date:
        print('Error: invalid date code ' + date_code)
        sys.exit()

    # Read simulation options so we have directories
    options = Options()

    # Figure out if this date is within the ocean-only spinup phase
    ini_year = int(options.startDate[:4])
    ini_month = int(options.startDate[4:6])
    new_year = int(date_code[:4])
    new_month = int(date_code[4:])
    couple_year, couple_month = add_months(ini_year, ini_month, options.spinup_time)
    spinup = (new_year < couple_year) or (new_year==couple_year and new_month < couple_month)
    first_coupled = new_year==couple_year and new_month==couple_month

    # Make sure this date code exists in the output directory
    output_date_dir = options.output_dir + date_code + '/'
    if not os.path.isdir(output_date_dir):
        print('Error: ' + output_date_dir + ' does not exist')
        sys.exit()

    # Copy the calendar file
    copy_to_dir(options.calendar_file, output_date_dir, options.output_dir)
    if os.path.isfile(output_date_dir+options.eta_file):
        # Also the eta log file
        copy_to_dir(options.eta_file, output_date_dir, options.output_dir)

    # Remove any MITgcm binary output files which are in the run directory (for example if a simulation died prior to this restart and gather_output was never called)
    for fname in os.listdir(options.mit_run_dir):
        if fname.endswith('.data') or fname.endswith('.meta'):
            os.remove(options.mit_run_dir+fname)

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
        niter0_line = line_that_matters(output_date_dir+'MITgcm/data', 'niter0')
        start = niter0_line.index('=')
        niter0 = extract_first_int(niter0_line[start:])
        # Reconstruct timestep stamp for pickup files we want
        niter0_stamp = str(niter0).zfill(10)
        # They will actually be in the directory from the year before
        prefix = '../'+output_date_dir.replace(str(new_year),str(new_year-1))+'/MITgcm/'
        mit_file_names += [prefix+'pickup.'+niter0_stamp+'.data', prefix+'pickup.'+niter0_stamp+'.meta']
        if options.use_seaice:
            mit_file_names += [prefix+'pickup_seaice.'+niter0_stamp+'.data', prefix+'pickup_seaice.'+niter0_stamp+'.meta']
        if options.use_ptracers:
            mit_file_names += [prefix+'pickup_ptracers.'+niter0_stamp+'.data', prefix+'pickup_ptracers.'+niter0_stamp+'.meta']
    # Now copy all the files
    for fname in mit_file_names:
        copy_to_dir(fname, output_date_dir+'MITgcm/', options.mit_run_dir)

    if spinup or first_coupled:
        # We are restarting within the spinup period. There is no Ua output yet.
        # Clean the Ua run directory.
        clean_ua(options.ua_exe_dir)
    else:
        # Copy Ua restart file (saved at beginning of segment)
        for fname in os.listdir(output_date_dir+'Ua/'):
            if fname.endswith('RestartFile.mat'):
                restart_name = fname
        copy_to_dir(restart_name, output_date_dir+'Ua/', options.ua_exe_dir)
        # Make a temporary copy of this one too
        make_tmp_copy(options.ua_exe_dir+restart_name)
    if not spinup:
        # Copy Ua melt rate file
        copy_to_dir(options.ua_melt_file, output_date_dir+'Ua/', options.output_dir)        

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
        if len(dname) != 6:
            # Not a date code
            continue
        if int(dname) >= int(date_code):
            # Now we can delete
            shutil.rmtree(options.output_dir+dname)

    # Delete the "finished" file if it exists
    finifile = options.output_dir+options.finished_file
    if os.path.isfile(finifile):
        os.remove(finifile)

    # Submit the next jobs
    print('Submitting next MITgcm segment')
    mit_id = submit_job(options, 'run_mitgcm.sh', input_var=['MIT_DIR='+options.mit_case_dir, 'ACC='+options.budget_code])
    print('Submitted with job ID ' + str(mit_id))
    if not spinup:
        print('Submitting next Ua segment')
        ua_id = submit_job(options, 'run_ua.sh', input_var=['UA_DIR='+options.ua_exe_dir, 'ACC='+options.budget_code])
        print('Submitted with job ID ' + str(ua_id))
