##############################################################
# Classes and functions to read/write model parameters to
# prepare for the coupled simulation.
# This includes keeping track of the calendar.
##############################################################

import datetime
import os

from config_options import *
from mitgcm_python.utils import real_dir, is_leap_year

# Global parameter
sec_per_day = 24*60*60


# Options object containing all the user-defined options, read from config_options.py and error checked

class Options:

    # Check and save all the options.
    def __init__ (self):

        # Inner function to report an illegal value
        def throw_error (var_name, var, legal=None):
            print 'Error reading config_options.py'
            print 'Invalid value of ' + var_name + ' = ' + str(var)
            if legal is not None:
                print 'Legal options are: '
                print legal
            sys.exit()

        # Inner function to error check a variable
        def check_value (var_name, var, type='str', legal=None):
            # First convert to the right type if needed
            if type == 'bool':
                # Careful with converting strings to boolean
                if var in [True, 'True', 'true', 'T', 't', 1]:
                    return True
                elif var in [False, 'False', 'false', 'F', 'f', 0]:
                    return False
                else:
                    throw_error(var_name, var, legal=[True, False])
            elif type in ['float', 'int']:
                # Try to convert to a number
                try:
                    if type == 'float':
                        var = float(var)
                    elif type == 'int':
                        if var != int(var):
                            # Not a round number
                            throw_error(var_name, var)
                        var = int(var)
                except(ValueError):
                    throw_error(var_name, var, legal=legal)
            elif type == 'str':
                # Everything can be convererted to a string
                var = str(var)
            # Now check against legal options
            if legal is not None and var not in legal:
                throw_error(var_name, var, legal=legal)
            return var

        # Check all the variables and save them to this object
        self.mit_case_dir = real_dir(check_value('mit_case_dir', mit_case_dir))
        # Save the run directory derived from this
        self.mit_run_dir = self.mit_case_dir + 'run/'

        self.couple_step = check_value('couple_step', couple_step, type='int')
        self.melt_average_step = check_value('melt_average_step', melt_average_step, type='int')
        self.calendar_type = check_value('calendar_type', calendar_type, legal=['standard', 'noleap', '360-day'])
        self.digging = check_value('digging', digging, legal=['none', 'bathy', 'draft'])
        self.x_is_lon = check_value('x_is_lon', x_is_lon, type='bool')
        self.pload_option = check_value('pload_option', pload_option, legal=['constant', 'nearest'])
        if self.pload_option == 'constant':
            self.pload_temp = check_value('pload_temp', pload_temp, type='float')
            self.pload_salt = check_value('pload_salt', pload_salt, type='float')
        else:
            # Set dummy values for pload_temp and pload_salt; since they're never used, there's no need to error check
            self.pload_temp = 0.
            self.pload_salt = 0.
            
        self.use_seaice = check_value('use_seaice', use_seaice, type='bool')
        self.deltaT = check_value('deltaT', deltaT, type='int')
        # Make sure ocean timestep evenly divides 1 day
        if sec_per_day % self.deltaT != 0:
            print 'Error reading config_options.py'
            print 'deltaT must evenly divide 1 day'
            sys.exit()
        self.hFacMin = check_value('hFacMin', hFacMin, type='float')
        self.hFacMinDr = check_value('hFacMinDr', hFacMinDr, type='float')
        self.readBinaryPrec = check_value('readBinaryPrec', readBinaryPrec, type='int', legal=[32, 64])
        self.readStatePrec = check_value('readStatePrec', readStatePrec, type='int', legal=[32, 64])
        self.rhoConst = check_value('rhoConst', rhoConst, type='float')
        self.eosType = check_value('eosType', eosType, legal=['MDJWF', 'JMD95', 'LINEAR'])
        if self.eosType == 'LINEAR':
            self.tAlpha = check_value('tAlpha', tAlpha, type='float')
            self.sBeta = check_value('sBeta', sBeta, type='float')
            self.Tref = check_value('Tref', Tref, type='float')
            self.Sref = check_value('Sref', Sref, type='float')
        else:
            # Dummy values
            self.tAlpha = 0.
            self.sBeta = 0.
            self.Tref = 0.
            self.Sref = 0.

        self.calendar_file = check_value('calendar_file', calendar_file)
        self.bathyFile = check_value('bathyFile', bathyFile)
        self.draftFile = check_value('draftFile', draftFile)
        self.ini_temp_file = check_value('ini_temp_file', ini_temp_file)
        self.ini_salt_file = check_value('ini_salt_file', ini_salt_file)
        self.ini_u_file = check_value('ini_u_file', ini_u_file)
        self.ini_v_file = check_value('ini_v_file', ini_v_file)
        if self.use_seaice:
            self.ini_area_file = check_value('ini_area_file', ini_area_file)
            self.ini_heff_file = check_value('ini_heff_file', ini_heff_file)
            self.ini_hsnow_file = check_value('ini_hsnow_file', ini_hsnow_file)
            self.ini_uice_file = check_value('ini_uice_file', ini_uice_file)
            self.ini_vice_file = check_value('ini_vice_file', ini_vice_file)
        else:
            self.ini_area_file = ''
            self.ini_heff_file = ''
            self.ini_hsnow_file = ''
            self.ini_uice_file = ''
            self.ini_vice_file = ''
        self.pload_file = check_value('pload_file', pload_file)
        self.ismr_name = check_value('ismr_name', ismr_name)
        self.final_state_name = check_value('final_state_name', final_state_name)
        if self.use_seaice:
            self.seaice_final_state_name = check_value('seaice_final_state_name', seaice_final_state_name)
        else:
            self.seaice_final_state_name = ''


    # Class function to save calendar info from the previous simulation segment: the starting date (useful for NetCDF conversion) and the final timestep number in the simulation (useful for reading output).
    def save_last_calendar (self, start_date, ndays):
        self.last_start_date = start_date
        self.last_timestep = ndays*sec_per_day

# End of class Object


# Helper function for update_endTime and update_diagnostic_freq. Extract the first continuous group of digits in a string. Return as an integer.
def extract_first_digits (string):

    digits = ''
    # Loop over the characters in the string
    for s in string:
        if s.isdigit():
            # Accumulate the digits
            digits += s
        elif len(digits) > 0:
            # It's not a digit, and we've already found the number.
            # So the digits are finished.
            break
    return int(digits)


# Update endTime for the next MITgcm segment. This is necessary because the number of days per month is not constant for calendar types 'standard' and 'noleap'. For calendar type '360-day', just check that endTime agrees with what we'd expect.
# TODO: deal with initial case where the check should give a warning, not an error.
def update_endTime (mit_dir, endTime, options):

    # Set file paths
    mit_dir = real_dir(mit_dir)
    namelist = mit_dir + 'data'
    namelist_tmp = mit_dir + 'data.tmp'

    # First check if we need to update the file at all
    f = open(namelist, 'r')
    for line in f:
        # Search for lines that contains endTime (case-insensitive) and is not commented out. This can be overwritten if multiple such lines exist; the last one will be the one that counts (as it does for MITgcm)
        if 'endtime' in line.lower() and not line.startswith('#'):
            # Strip out the number
            old_endTime = extract_first_digits(line)
    f.close()

    # Check if endTime needs to be changed
    if old_endTime != endTime:
        
        if options.calendar_type == '360-day':
            # 360-day calendars should never need endTime to be changed
            print 'Error (update_endTime): endTime has mysteriously changed in your namelist and is no longer correct.'
            sys.exit()

        # Open the file for reading again
        f_r = open(namelist, 'r')
        # Open another file to write to
        f_w = open(namelist_tmp, 'w')
        for line in f_r:
            # Search for that line again, and update it
            if 'endtime' in line.lower() and not line.startswith('#'):
                f_w.write(' endTime='+str(endTime)+',\n')
            else:
                # Just copy the line over
                f_w.write(line)
        f_r.close()
        f_w.close()

        # Replace the old file with the new one
        os.remove(namelist)
        os.rename(namelist_tmp, namelist)


# Update the diagnostic frequencies in data.diagnostics. The frequency of snapshots for the final state should equal the simulation length; as for update_endTime, update or check this depending on the calendar type. Also check that the frequency of averaging for ice shelf melt rate agrees with the user parameters.
# TODO: deal with initial case where the checks should give warnings, not errors.
def update_diag_freq (mit_dir, endTime, options):

    # Set file paths
    mit_dir = real_dir(mit_dir)
    namelist = mit_dir + 'data.diagnostics'
    namelist_tmp = mit_dir + 'data.diagnostics.tmp'
        

# Helper function for advance_calendar
# Advance the given date (year and month) by num_months
def add_months (year, month, num_months):
    month += num_months
    while month > 12:
        month -= 12
        year += 1
    return year, month


# Helper function for advance_calendar
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
        elif calendar_time == 'noleap':
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
                    
                
# Read and update the plain-text file in "directory" that keeps track of the calendar (starting date of last simulation segment, and number of days in that simulation). Update any parameters that depend on the calendar (including namelists in mit_dir).
# TODO: deal with initial case where the final doesn't exist yet.
def advance_calendar (directory, mit_dir, options):

    print 'Advancing calendar by ' + str(options.couple_step) + ' months'

    # Read the calendar file
    directory = real_dir(directory)
    f = open(directory+options.calendar_file, 'r')
    date_code = f.readline().strip()
    ndays = int(f.readline())
    f.close()

    # Save that info to the Options object
    options.save_last_calendar(date_code, ndays)

    # Parse the date code
    old_year = int(date_code[:4])
    old_month = int(date_code[4:])
    # Get the date at the beginning of the next simulation
    new_year, new_month = add_months(old_year, old_month, options.couple_step)
    # and the simulation after that
    newer_year, newer_month = add_months(new_year, new_month, options.couple_step)

    # Make sure ndays makes sense
    if ndays != days_between(old_year, old_month, new_year, new_month, options.calendar_type):
        print 'Error (advance_calendar): number of days in last simulation does not agree with couple_step and/or calendar_type.'
        sys.exit()

    # Calculate number of days in the next simulation
    ndays_new = days_between(new_year, new_month, newer_year, newer_month, options.calendar_type)    
    # Create the new date_code
    date_code_new = str(new_year) + str(new_month).zfill(2)

    # Write a new calendar file
    f = open(directory+options.calendar_file, 'w')
    f.write(date_code_new + '\n')
    f.write(str(ndays_new))
    f.close()

    # Calculate simulation length in seconds
    endTime = ndays_new*sec_per_day
    # Update/check endTime for next MITgcm segment
    update_endTime(mit_dir, endTime, options)
    # Update/check diagnostic frequencies
    update_diag_freq(mit_dir, endTime, options)
        

    

    
