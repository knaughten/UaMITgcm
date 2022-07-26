#####################################################
# Lower-level utility functions used during coupling.
#####################################################

import os
import datetime
import subprocess
import numpy as np
import sys
import shutil

from MITgcmutils import rdmds

from mitgcm_python.make_domain import level_vars
from mitgcm_python.utils import xy_to_xyz, z_to_xyz, is_leap_year, calc_hfac
from mitgcm_python.file_io import write_binary

# Global variables
# Dimensions (2D or 3D) of variables in pickup file
# These files are structured differently so a 2D/3D key is necessary.
pickup_vars_3d = ['Uvel', 'Vvel', 'Theta', 'Salt', 'GuNm1', 'GvNm1', 'PhiHyd', 'siTICES', 'pTr01', 'AddMass']
pickup_vars_2d = ['EtaN', 'dEtaHdt', 'EtaH', 'siAREA', 'siHEFF', 'siHSNOW', 'siUICE', 'siVICE', 'siSigm1', 'siSigm2', 'siSigm12']

# Extract the first continuous group of digits in a string, including minus signs. Return as an integer.
def extract_first_int (string):

    int_string = ''
    # Loop over the characters in the string
    for s in string:
        if s.isdigit() or s=='-':
            # Accumulate the digits
            int_string += s
        elif len(int_string) > 0:
            # It's not a digit, and we've already found the number.
            # So the digits are finished.
            break
    return int(int_string)


# Check if a string contains the given substring, and is uncommented (where # in the first column indicate comments, as in a Fortran namelist). Default not case sensitive.
def active_line_contains (line, substr, ignore_case=True):
    
    if ignore_case:
        return substr.lower() in line.lower() and not line.startswith('#')
    else:
        return substr in line and not line.startswith('#')

    
# Return the last line in a file satisfying active_line_contains. In a namelist, this is the line of the file that actually defines the given variable.
def line_that_matters (file_name, substr, ignore_case=True, throw_error=True):
    
    line_to_save = None
    f = open(file_name, 'r')
    # Loop over all the lines in the file and keep overwriting line_to_save
    for line in f:
        if active_line_contains(line, substr, ignore_case=ignore_case):
            line_to_save = line
    f.close()
    
    # Make sure we found it
    if line_to_save is None and throw_error:
        print('Error (line_that_matters): ' + file_name + ' does not contain ' + substr)
        sys.exit()
        
    return line_to_save


# Replace one line with another in the given file.
def replace_line (file_name, old_line, new_line):
    
    # Open the file for reading
    f_r = open(file_name, 'r')
    # Open another file to write to
    f_w = open(file_name+'.replace', 'w')
    for line in f_r:
        if line == old_line:
            # Update this line in the new file
            f_w.write(new_line)
        else:
            # Just copy the line over
            f_w.write(line)
    f_r.close()
    f_w.close()
    
    # Replace the old file with the new one
    os.remove(file_name)
    os.rename(file_name+'.replace', file_name)


# Comment out a line (where # at the beginning of a line makes a comment)
def comment_line (file_name, line):
    replace_line(file_name, line, '#'+line)


# Find the active line in the file containing the given substring, and comment it out. If there is more than one, throw an error.
def find_comment_line (file_name, substring):

    line = line_that_matters(file_name, substring, throw_error=False)
    if line is not None:
        comment_line(file_name, line)
        line_2 = line_that_matters(file_name, substring, throw_error=False)
        if line_2 is not None:
            print('Error (find_comment_line): ' + substring + ' is set multiple times in ' + file_name + '. Choose one so we can comment it out without confusion.')
            sys.exit()
    

# Add a new line to a file, right after the given previous line.
def add_line (file_name, line, previous_line):
    replace_line(file_name, previous_line, previous_line+line)


# Advance the given date (year and month) by num_months
def add_months (year, month, num_months):
    
    month += num_months
    while month > 12:
        month -= 12
        year += 1
    return year, month


# Rewind the given date (year and month) by num_months
def subtract_months (year, month, num_months):

    month -= num_months
    while month < 1:
        month += 12
        year -= 1
    return year, month


# Calculate the number of days between the given dates (assuming 1st of the month), depending on the calendar type
def days_between (year_1, month_1, year_2, month_2, calendar_type):
    
    if calendar_type == '360-day':
        # Every month has 30 days in this calendar
        # First calculate the number of months
        num_months = 12*(year_2 - year_1) + (month_2 - month_1)
        return num_months*30
    else:
        # Calculate using date objects
        date_1 = datetime.date(year_1, month_1, 1)
        date_2 = datetime.date(year_2, month_2, 1)
        num_days = (date_2-date_1).days
        if calendar_type == 'standard':
            # We're done
            return num_days
        elif calendar_type == 'noleap':
            # Subtract the leap days
            if year_1 == year_2:
                # Dates are in the same year; maximum 1 leap day between them
                if month_1 <= 2 and month_2 >= 3 and is_leap_year(year_1):
                    num_days -= 1
            else:
                # Check the year of the first date
                if month_1 <= 2 and is_leap_year(year_1):
                    num_days -= 1
                # Check any complete years between the dates
                for year in range(year_1+1, year_2):
                    if is_leap_year(year):
                        num_days -= 1
                # Check the year of the last date
                if month_2 >= 3 and is_leap_year(year_2):
                    num_days -= 1
            return num_days


# Calculate the number of months between the given dates.
def months_between (year_1, month_1, year_2, month_2):

    return 12*(year_2 - year_1) + (month_2 - month_1)


# As above, but in years (conversion depends on calendar type).
def years_between (year_1, month_1, year_2, month_2, calendar_type):

    num_days = days_between(year_1, month_1, year_2, month_2, calendar_type)
    if calendar_type == '360-day':
        return num_days/360.
    elif calendar_type == 'noleap':
        return num_days/365.
    elif calendar_type == 'standard':
        return num_days/365.25


# Read MITgcm binary output file(s) of a given type/name (file_head, eg 'MIT2D') and extract all the variables in the given list of names. Can also pass var_names=None if there are no named variables (eg if it's a dump file with just one variable in it).
# Will either read the most recently modified file (time_option='last'), time-average all available files (time_option='avg'), or read all available files with no averaging (time_option='all').
# If there is an expected value for the timestep number corresponding to the 'last' output, check that it agrees.
# For pickups, you must pass nz, which is the number of vertical layers in the model (for normal pickups) OR the number of sea ice vertical layers (for sea ice pickups).
def read_mit_output (time_option, directory, file_head, var_names, timestep=None, nz=None):

    # Check if var_names is a string rather than a list
    if isinstance(var_names, str):
        var_names = [var_names]

    if time_option == 'last':
        # Read the most recent file
        data, its, meta = rdmds(directory+file_head, itrs=np.Inf, returnmeta=True)
    elif time_option in ['avg', 'all']:
        # Read all files
        data, its, meta = rdmds(directory+file_head, itrs=np.nan, returnmeta=True)
        if len(its) > 1 and time_option == 'avg':
            # Time-average
            data = np.mean(data, axis=0)
    if len(data)==0:
        # Nothing was read, no such files exist
        print('Error (read_mit_output): no such files ' + directory+file_head+'.*.data exist.')
        if var_names is None:
            # This looks like a case of missing dump files
            print('Make sure that dumpInitAndLast=.true. in input/data.')
        sys.exit()
    if time_option == 'last':
        print('Read ' + file_head + ' data from MITgcm timestep ' + str(its[0]))
        # Make sure it agrees with any expected timestep number
        if timestep is not None and its[0] != timestep:
            print('Error: most recent ' + file_head + ' file is not from the expected timestep ' + str(timestep))
            sys.exit()
        
    if var_names is None:
        # There is just one variable here, return the whole array
        return data

    if file_head.startswith('pickup'):
        # Pickup files do not have an extra dimension for the different variables.
        # Instead this is collapsed into the depth dimension.
        # Unpick the resulting large 3D array into the different variables.
        if nz is None:
            print('Error (read_mit_output): must define nz for pickup files')
            sys.exit()
        data_unpick = []
        for var in meta['fldlist']:
            if var in pickup_vars_3d:
                # Select the first nz records
                data_unpick.append(data[:nz,:])
                data = data[nz:,:]
            elif var in pickup_vars_2d:
                # Select the first 1 record
                data_unpick.append(data[0,:])
                data = data[1:,:]
            else:
                print('Error (read_mit_output): ' + var + ' is not in list of standard pickup variables. Add it to pickup_vars_3d or pickup_vars_2d array.')
                sys.exit()
        data = data_unpick            

    # Extract one variable at a time and wrap them up in a list
    var_data = []
    for var in var_names:
        # Figure out which index contains this variable
        i = meta['fldlist'].index(var)
        if file_head.startswith('pickup'):
            var_data.append(data[i])
        else:
            if time_option == 'all' and len(its) > 1:
                # Deal with time dimension
                var_data.append(data[:,i,:])
            else:
                var_data.append(data[i,:])
    # Check for single variable
    if len(var_data) == 1:
        return var_data[0]
    else:
        return var_data


def overwrite_pickup (directory, file_head, timestep, fields, var_names, nz):

    # Read the existing file
    data, its, meta = rdmds(directory+file_head, itrs=[timestep], returnmeta=True)
    if len(data)==0:
        # Nothing was read; no such files exist
        print('Error (overwrite_pickup): file not found.')
        sys.exit()

    # Loop over the variables in order and overwrite them along the depth dimension.
    posn = 0
    for var in meta['fldlist']:
        # Find the index of this variable in the input variable list
        try:
            i = var_names.index(var)
        except(ValueError):
            print('Error (overwrite_pickup): variable ' + var + ' is not in input var_names')
            sys.exit()
        if var in pickup_vars_3d:
            # Overwrite nz depth records
            data[posn:posn+nz,:] = fields[i]
            posn += nz
        elif var in pickup_vars_2d:
            data[posn,:] = fields[i]
            posn += 1
        else:
            print('Error (overwrite_pickup): ' + var + ' is not in list of standard pickup variables. Add it to pickup_vars_3d or pickup_vars_2d array.')
            sys.exit()
    if posn != data.shape[0]:
        print("Error (overwrite_pickup): didn't overwrite the entire pickup; something is wrong.")
        sys.exit()

    # Now overwrite the file
    file_path = directory + file_head + '.' + str(int(timestep)).zfill(10) + '.data'
    if not os.path.isfile(file_path):
        print('Error (overwrite_pickup): incorrect pickup file path.')
        sys.exit()
    prec = int(meta['dataprec'][0][-2:])
    write_binary(data, file_path, prec=prec)


# Move a file from one directory to another, without changing its name.
def move_to_dir (fname, old_dir, new_dir):
    os.rename(old_dir+fname, new_dir+fname)

# Copy a file from one directory to another, without changing its name.
def copy_to_dir (fname, old_dir, new_dir):
    try:
        shutil.copy(old_dir+fname, new_dir+fname)
    except(shutil.SameFileError):
        # They are already the same file (probably symlinks)
        pass


# Convert a list of strings to a single string with elements separated by the given separator character.
def list_with_separator (A, sep):
    s = ''
    for elm in A:
        s += elm + sep
    # Remove the last character
    return s[:-1]    


# Submit the given SBATCH script and return the PBS job ID.
# Optional keyword arguments:
# options: Options object
# input_var: a list of variable definitions to pass with -v option, eg 'MIT_DIR=directory_path'
# afterok: a list of SBATCH job IDs of previously submitted jobs. If it is defined, this job will stay on hold until the given jobs successfully complete.
def submit_job (options, sbatch_script, input_var=None, afterok=None):

    # Construct sbatch call line by line.
    command = 'sbatch'
    # Specify budget
    command += ' -A ' + options.budget_code
    # Specify job name
    jobname = options.expt_name
    if 'mitgcm' in sbatch_script:
        jobname += 'o'
    elif 'ua' in sbatch_script:
        jobname += 'i'
    elif 'coupler' in sbatch_script:
        jobname += 'c'
    command += ' -J ' + jobname
    if input_var is not None:
        # Add variable definitions
        command += ' --export=ALL,'
        command += list_with_separator(input_var,',')
    if afterok is not None:
        command += ' -W depend=afterok:'
        command += list_with_separator(afterok,':')
    # Specify script
    command += ' ' + sbatch_script
    
    # Call the command and capture the output
    sbatch_id = subprocess.check_output(command, shell=True, text=True)
    # Now extract the digits from the SBATCH job ID and return as a string
    try:
        return str(extract_first_int(sbatch_id))
    except(ValueError):
        print('Error (submit_job): job did not submit properly')
        print('Error message from sbatch was:')
        print(sbatch_id)
        sys.exit()

        
# Check if the given plain-text file contains the given string.
def string_in_file (fname, string):

    f = open(fname, 'r')
    for line in f:
        if string in line:
            f.close()
            return True
    # If we're still here, the string's not in the file
    f.close()
    return False


# Find all the prefixes for MDS dump files at the given timestep.
# They are identified by their .meta file being a different format to
# diagnostic files, specifically the fldList isn't there.
def find_dump_prefixes (directory, tstep):

    # Figure out the end of the filenames we care about
    file_tail = '.' + str(tstep).zfill(10) + '.meta'
    prefixes = []
    for fname in os.listdir(directory):
        if fname.endswith(file_tail):
            if not string_in_file(directory+fname, 'fldList'):
                # Extract the prefix (everything before the first .)
                prefixes.append(fname.split('.')[0])
    return prefixes


# Move the MDS files defined by "prefixes" and "tstep" into the given directory "tmpdir".
def move_processed_files (directory, tmpdir, prefixes, tstep):

    for fname in os.listdir(directory):
        if (fname.endswith('.data') or fname.endswith('.meta')) and fname.split('.')[0] in prefixes and int(fname.split('.')[1])==tstep:
            move_to_dir(fname, directory, tmpdir)


# Make a temporary copy of the given file with the suffix .tmp
def make_tmp_copy (file_path):
    shutil.copy(file_path, file_path+'.tmp')


# Make a list of filenames in the given directory that start with the given string, and return in alphabetical order.
def get_file_list (directory, prefix):
    output_files = []
    for fname in os.listdir(directory):
        if fname.startswith(prefix):
            output_files.append(fname)
    output_files.sort()
    return output_files


# Delete the mitgcm_finished and ua_finished files from the last run, if they exist. If it's the spinup, create the ua_finished file so it doesn't stop the run from progressing.
def reset_finished_files (options):

    for fname in ['mitgcm_finished', 'ua_finished']:
        if os.path.isfile(fname):
            os.remove(fname)
    if options.spinup:
        f = open('ua_finished', 'w')
        f.close()        


# Function to copy the Ua restart file when a simulation is being duplicated or cleaned.
def copy_ua_restart (directory, restart_name):
    orig_restart = input('Enter path to desired Ua restart file, or press enter if you want Ua to start from scratch: ')
    if len(orig_restart) > 0:
        while True:
            if os.path.isfile(orig_restart):
                break
            orig_restart = input('That file does not exist. Try again: ')
        shutil.copy(orig_restart, directory+restart_name)
                
                
