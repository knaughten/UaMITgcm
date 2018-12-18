##############################################################
# Classes and functions to read/write model parameters to
# prepare for the coupled simulation.
# This includes keeping track of the calendar.
##############################################################

from config_options import *
from coupling_utils import extract_first_int, active_line_contains, line_that_matters, replace_line, add_months, days_between

from mitgcm_python.utils import real_dir, days_per_month

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
                # Anything can be converted to a string
                var = str(var)
            elif type == 'list':
                # Make sure it's actually a list
                if not isinstance(var, list):
                    throw_error(var_name, var, legal=legal)
            # Now check against any legal options given
            if legal is not None and var not in legal:
                throw_error(var_name, var, legal=legal)
            return var

        # Check all the variables and save them to this object
        self.ua_option = check_value('ua_option', ua_option, legal=['compiled', 'matlab'])
        self.mit_case_dir = real_dir(check_value('mit_case_dir', mit_case_dir))
        self.ua_exe_dir = real_dir(check_value('ua_exe_dir', ua_exe_dir))
        # Save the run directory derived from this
        self.mit_run_dir = self.mit_case_dir + 'run/'
        self.output_dir = real_dir(check_value('output_dir', output_dir))
        self.budget_code = check_value('budget_code', budget_code)
        self.use_xmitgcm = check_value('use_xmitgcm', use_xmitgcm, type='bool')

        self.couple_step = check_value('couple_step', couple_step, type='int')
        self.calendar_type = check_value('calendar_type', calendar_type, legal=['standard', 'noleap', '360-day'])
        self.output_freq = check_value('output_freq', output_freq, legal=['monthly', 'daily', 'end'])
        if self.calendar_type=='noleap' and self.output_freq=='monthly':
            print 'Error reading config_options.py'
            print "output_freq='monthly' does not work with calendar_type='noleap'"
            sys.exit()
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
        self.startDate = check_value('startDate', startDate)
        problem = len(self.startDate) != 8
        try:
            tmp = int(self.startDate)
        except(ValueError):
            problem = True
        if problem:
            print 'Error reading config_options.py'
            print 'startDate should be an 8-digit code in the form YYYYMMDD'

        self.calendar_file = check_value('calendar_file', calendar_file)
        self.bathyFile = check_value('bathyFile', bathyFile)
        if self.digging == 'bathy':
            self.bathyFileOrig = check_value('bathyFileOrig', bathyFileOrig)
        else:
            self.bathyFileOrig = ''
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
        self.output_names = check_value('output_names', output_names, type='list')
        self.mit_nc_name = check_value('mit_nc_name', mit_nc_name)
        if not self.mit_nc_name.endswith('.nc'):
            print 'Error reading config_options.py'
            print 'mit_nc_name must be a NetCDF file'
            sys.exit()
        self.ua_melt_file = check_value('ua_melt_file', ua_melt_file)
        self.ua_draft_file = check_value('ua_draft_file', ua_draft_file)


    # Class function to save calendar info from the previous simulation segment: the starting date (useful for NetCDF conversion) and the final timestep number in the simulation (useful for reading output).
    def save_last_calendar (self, start_date, ndays):
        self.last_start_date = start_date
        self.last_timestep = ndays*sec_per_day

# end class Object



# Update the "data" and "data.diagnostics" namelists to reflect the length of the next simulation segment. This is necessary because the number of days per month is not constant for calendar types 'standard' and 'noleap'. For calendar type '360-day', just check that the values already there agree with what we'd expect.
# Also set the frequency of user-specified diganostic filetypes in data.diagnostics (options.output_names), to agree with options.output_freq.
# TODO: deal with initial case where the check should give a warning, not an error.
def update_namelists (mit_dir, endTime, options):

    # Set file paths
    namelist = mit_dir + 'data'
    namelist_diag = mit_dir + 'data.diagnostics'

    # Inner function to find the line defining the frequency of the given diagnostic file name in data.diagnostics, and also extract that frequency and its file index.
    def get_diag_freq (diag_file_head):
        # First find the line with that filename head
        filename_line = line_that_matters(namelist_diag, diag_file_head, ignore_case=False)
        # This will be of the form "filename(x)=name". Strip out the value of x.
        index = extract_first_int(filename_line)
        # Now find the line defining "frequency(x)".
        freq_line = line_that_matters(namelist_diag, 'frequency('+str(index)+')')
        # Strip out the number after the equals sign
        freq = extract_first_int(freq_line[freq_line.index('=')+1:])
        return freq_line, freq, index

    # Inner function to throw an error or a warning if the existing simulation length is incorrect in a 360-day calendar (where every simulation segment should be the same length).
    def throw_error_warning (var_string, file_name, error=True):
        if error:
            message = 'Error: '
        else:
            message = 'Warning: '
        message += var_string + ' has an incorrect value in ' + file_name
        print message
        if error:
            sys.exit()

    # Inner function to check if a variable needs to be updated, and then update the file if needed.
    # In some cases we don't think the variable should need to be changed; if so, throw an error (if error=True) or a warning (if error=False).
    # Control which situations this error/warning is thrown with the keyword argument "check": check='360' throws an error/warning if it's a 360-day calendar and the variable needs to be changed; check='all' throws an error/warning if the variable needs to be changed, regardless of the calendar; check='none' will never throw errors or warnings.
    def check_and_change (old_var, new_var, old_line, new_line, file_name, var_string, error=False, check='360'):
        if old_var != new_var:
            if check=='all' or (check=='360' and options.calendar_type == '360-day'):
                throw_error_warning(var_string, file_name, error=error)
            print 'Updating ' + var_string + ' in ' + file_name
            replace_line(file_name, old_line, new_line)

    # Now the work starts

    # Look for endTime in "data" namelist
    endTime_line = line_that_matters(namelist, 'endTime')
    # Strip out the number
    old_endTime = extract_first_int(line)
    # Update file if needed
    # TODO: set error=False if initial run
    check_and_change(old_endTime, endTime, endTime_line, ' endTime='+str(endTime)+',\n', namelist, 'endTime')
        
    # Look for the frequency of the final state snapshot file in "data.diagnostics" namelist
    final_state_freq, final_state_freq_line, final_state_index = get_diag_freq(options.final_state_name)
    # Update if needed
    # TODO: set error=False if initial run
    check_and_change(final_state_freq, -endTime, final_state_freq_line, ' frequency('+str(final_state_index)+') = '+str(-endTime)+'.,\n', namelist_diag, 'diagnostic frequency of '+options.final_state_name)
    if options.use_seaice:
        # Sea ice final state snapshot might be a different file
        seaice_final_state_freq, seaice_final_state_freq_line, seaice_final_state_index = get_diag_freq(options.seaice_final_state_name)
        if seaice_final_state_index != final_state_index:
            # Update if needed
            # TODO: set error=False if initial run
            check_and_change(seaice_final_state_freq, -endTime, seaice_final_state_freq_line, ' frequency('+str(seaice_final_state_index)+') = '+str(-endTime)+'.,\n', namelist_diag, 'diagnostic frequency of '+options.seaice_final_state_name)

    # Now set/check diagnostic frequencies. If it's not an initial run and the existing frequencies don't match what we expect, throw an error.
    if len(options.output_names) > 0:

        # Figure out what the frequency should be
        if options.output_freq == 'monthly':
            # Set to 30 days. For 360-day calendars, every month is 30 days; for standard calendars, the MITgcm calendar package will update to make this a real month; we've already checked that noleap calendars don't use this option.
            freq = 30*sec_per_day
        elif options.output_freq == 'daily':
            freq = sec_per_day
        elif options.output_freq == 'end':
            freq = endTime

        # Loop over diagnostic filetypes
        for fname in options.output_names:
            curr_freq, curr_line, curr_index = get_diag_freq(fname)
            # TODO: set error=False and check='none' if initial run
            check_and_change(curr_freq, freq, curr_line, ' frequency('+str(curr_index)+') = '+str(freq)+'.,\n', namelist_diag, 'diagnostic frequency of '+fname, error=True, check='all')
            

# end function update_namelists



# Read and update the plain-text file in "directory" that keeps track of the calendar (starting date of last simulation segment, and number of days in that simulation). Update any parameters that depend on the calendar (including namelists in mit_dir).
# TODO: deal with initial case where the file doesn't exist yet.
def advance_calendar (directory, mit_dir, options):

    print 'Advancing calendar by ' + str(options.couple_step) + ' months'

    # Read the first 2 lines of the calendar file
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

    # Now decide what to write about the output intervals
    if options.output_freq == 'daily':
        # One line with a flag to tell Ua to output daily
        output_intervals = [-1]
    elif options.output_freq == 'monthly':
        # One line for each month in the simulation, containing the number of days in that month
        if options.calendar_type == '360-day':
            # 30 days in every month
            output_intervals = options.couple_step*[30]
        elif options.calendar_type == 'standard':
            # Loop through the months to find the number of days in each
            curr_year = new_year
            curr_month = new_month
            output_intervals = []
            for t in range(options.couple_step):
                output_intervals.append(days_per_month(curr_month, curr_year))
                curr_year, curr_month = add_months(curr_year, curr_month, 1)
    elif options.output_freq == 'end':
        # One line with the number of days in the simulation
        output_intervals = [ndays_new]

    # Write a new calendar file
    f = open(directory+options.calendar_file, 'w')
    f.write(date_code_new + '\n')
    f.write(str(ndays_new) + '\n')
    for interval in output_intervals:
        f.write(str(interval) + '\n')
    f.close()

    # Calculate simulation length in seconds
    endTime = ndays_new*sec_per_day
    # Update/check endTime for next MITgcm segment, and diagnostic frequencies
    update_namelists(mit_dir, endTime, options)

        

    

    
