#####################################################
# Lower-level utility functions used during coupling.
#####################################################

import os
import datetime
import subprocess

from MITgcmutils import rdmds

from mitgcm_python.make_domain import model_bdry, level_vars
from mitgcm_python.utils import xy_to_xyz, z_to_xyz, is_leap_year

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
def line_that_matters (file_name, substr, ignore_case=True):
    
    line_to_save = None
    f = open(file_name, 'r')
    # Loop over all the lines in the file and keep overwriting line_to_save
    for line in f:
        if active_line_contains(line, substr, ignore_case=ignore_case):
            line_to_save = line
    f.close()
    
    # Make sure we found it
    if line_to_save is None:
        print 'Error (line_that_matters): ' + file_name + ' does not contain ' + substr
        sys.exit()
        
    return line_to_save


# Replace one line with another in the given file.
def replace_line (file_name, old_line, new_line):
    
    # Open the file for reading
    f_r = open(file_name, 'r')
    # Open another file to write to
    f_w = open(file_name+'.tmp', 'w')
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
    os.rename(file_name+'.tmp', file_name)


# Advance the given date (year and month) by num_months
def add_months (year, month, num_months):
    
    month += num_months
    while month > 12:
        month -= 12
        year += 1
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


# Find the most recently modified MITgcm binary output file of a given type/name (file_head, eg 'MIT2D' or 'FinalState') and extract all the variables in the given list of names.
# If there is an expected value for the timestep number corresponding to this output, check that it agrees.
def read_last_output (directory, file_head, var_names, timestep=None):

    # Check if var_names is a string rather than a list
    if isinstance(var_names, str):
        var_names = [var_names]

    # Read the most recent file
    data, its, meta = rdmds(directory+file_head, itrs=np.Inf, returnmeta=True)
    if len(data)==0:
        # Nothing was read, no such files exist
        print 'Error (read_last_output): no such files ' + directory+file_head+'.*.data exist.'
        sys.exit()
    print 'Read ' + file_head + ' data from MITgcm timestep ' + str(its[0])
    # Make sure it agrees with any expected timestep number
    if timestep is not None and its != timestep:
        print 'Error: most recent ' + file_head + ' file is not from the expected timestep ' + timestep
        sys.exit()
    # Extract one variable at a time and wrap them up in a list
    var_data = []
    for var in var_names:
        # Figure out which index contains this variable
        i = meta['fldlist'].index(var)
        var_data.append(data[i,:])
    # Check for single variable
    if len(var_data) == 1:
        return var_data[0]
    else:
        return var_data


# Given 2D fields for bathymetry and ice shelf draft, and information about the vertical grid (which doesn't change over time, so Grid object from last segment is fine), figure out which cells in the 3D grid are (at least partially) open. Return a 3D boolean array.
def find_open_cells (bathy, draft, grid, options, hFacMin, hFacMinDr):

    # Calculate the actual bathymetry and ice shelf draft seen by MITgcm, based on hFac constraints
    bathy_model = model_bdry(bathy, grid.dz, grid.z_edges, option='bathy', hFacMin=hFacMin, hFacMinDr=hFacMinDr)
    draft_model = model_bdry(draft, grid.dz, grid.z_edges, option='draft', hFacMin=hFacMin, hFacMinDr=hFacMinDr)

    # Find the depth of the last dry z-level edge above the draft
    edge_above_draft = level_vars(draft_model, grid.dz, grid.z_edges, include_edge='top')[1]
    # Find the depth of the first dry z-level edge below the bathymetry
    edge_below_bathy = level_vars(bathy_model, grid.dz, grid.z_edges, include_edge='bottom')[2]

    # Tile everything to be 3D
    edge_above_draft = xy_to_xyz(edge_above_draft, grid)
    edge_below_bathy = xy_to_xyz(edge_below_bathy, grid)
    z_3d = z_to_xyz(grid.z, grid)
    
    # Identify all z-centres between the two edges, and remove any cells with bathymetry 0. This is equivalent to ceil(hFacC). 
    return (z_3d <= edge_above_draft)*(z_3d >= edge_below_bathy)*(bathy_model < 0)


# Move a file from one directory to another, without changing its name.
def move_to_dir (fname, old_dir, new_dir):
    os.rename(old_dir+fname, new_dir+fname)


# Convert a list of strings to a single string with elements separated by commas.
def list_with_commas (A):
    s = ''
    for elm in A:
        s += A + ','
    # Remove the last comma
    return s[:-1]    


# Submit the given PBS script and return the PBS job ID.
# Optional keyword arguments:
# input_var: a list of variable definitions to pass with -v option, eg 'MIT_DIR=directory_path'
# afterok: a list of PBS job IDs of previously submitted jobs. If it is defined, this job will stay on hold until the given jobs successfully complete.
def submit_job (pbs_script, input_var=None, afterok=None):

    # Construct qsub call line by line.
    command = 'qsub'
    # Specify budget
    command += ' -A ' + options.budget_code
    if input_var is not None:
        # Add variable definitions
        command += ' -v '
        command += list_with_commas(input_var)
    if afterok is not None:
        command += ' -W depend=afterok:'
        command += list_with_commas(afterok)
    # Specify script
    command += ' ' + pbs_script

    # Call the command and capture the output
    pbs_id = subprocess.check_output(command, shell=True)
    # Now extract the digits from the PBS job ID and return as a string
    return str(extract_first_int(pbs_id))
