##############################################################
# Classes and functions to read/write model parameters to
# prepare for the coupled simulation.
# This includes keeping track of the calendar.
##############################################################

import os
import sys

# Import default options, then overwrite with any user-defined options
from default_config_options import *
from config_options import *

from coupling_utils import extract_first_int, active_line_contains, line_that_matters, replace_line, add_months, days_between, make_tmp_copy, comment_line, add_line, find_comment_line

from mitgcm_python.utils import real_dir, days_per_month

# Global parameter
sec_per_day = 24*60*60


# Options object containing all the user-defined options, read from config_options.py and error checked

class Options:

    # Check and save all the options. Write some in a plain text file for Ua to read.
    def __init__ (self):

        # Inner function to throw an error and stop processing
        def throw_error(message):
            print('Error reading config_options.py')
            print(message)
            sys.exit()        

        # Inner function to report an illegal value
        def var_error (var_name, var, legal=None):
            message = 'Invalid value of ' + var_name + ' = ' + str(var)
            if legal is not None:
                message += 'Legal options are: '
                message += legal
            throw_error(message)

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
                    var_error(var_name, var, legal=[True, False])
            elif type in ['float', 'int']:
                # Try to convert to a number
                try:
                    if type == 'float':
                        var = float(var)
                    elif type == 'int':
                        if var != int(var):
                            # Not a round number
                            var_error(var_name, var)
                        var = int(var)
                except(ValueError):
                    var_error(var_name, var, legal=legal)
            elif type == 'str':
                # Anything can be converted to a string
                var = str(var)
            elif type == 'list':
                # Make sure it's actually a list
                if not isinstance(var, list):
                    var_error(var_name, var, legal=legal)
            # Now check against any legal options given
            if legal is not None and var not in legal:
                var_error(var_name, var, legal=legal)
            return var

        # Save all the variables to this object, doing error checking where needed
        self.expt_name = check_value('expt_name', expt_name)
        self.ua_option = check_value('ua_option', ua_option, legal=['compiled', 'matlab'])
        self.use_xmitgcm = check_value('use_xmitgcm', use_xmitgcm, type='bool')
        self.save_dumps = check_value('save_dumps', save_dumps, type='bool')
        self.save_tmp_ckpt = check_value('save_tmp_ckpt', save_tmp_ckpt, type='bool')
        self.ua_output_format = check_value('ua_output_format', ua_output_format, legal=['matlab'])
        self.mit_case_dir = real_dir(mit_case_dir)
        # Save the run directory derived from this
        self.mit_run_dir = self.mit_case_dir + 'run/'
        self.ua_exe_dir = real_dir(ua_exe_dir)
        # Save the Ua output directory derived from this
        self.ua_output_dir = self.ua_exe_dir + 'ResultsFiles/'
        self.output_dir = real_dir(output_dir)
        # Create it, if needed
        if not os.path.isdir(self.output_dir):
            os.mkdir(self.output_dir)
        self.budget_code = budget_code
        self.rsync_output = check_value('rsync_output', rsync_output, type='bool')
        self.rsync_host = rsync_host
        self.rsync_path = real_dir(rsync_path)

        self.total_time = check_value('total_time', total_time, type='int')
        self.spinup_time = check_value('spinup_time', spinup_time, type='int')
        if self.spinup_time > self.total_time:
            throw_error('spinup_time should not be larger than total_time')
        self.couple_step = check_value('couple_step', couple_step, type='int')
        # Make sure couple_step evenly divides total_time and spinup_time
        if self.total_time % self.couple_step != 0:
            throw_error('couple_step must evenly divide total_time')
        if self.spinup_time % self.couple_step != 0:
            throw_error('couple_step must evenly divide spinup_time')
        self.repeat = check_value('repeat', repeat, type='bool')
        self.melt_coupling = check_value('melt_coupling', melt_coupling, legal=['last', 'avg', 'all'])
        self.mirror = check_value('mirror', mirror, type='bool')
        if self.mirror and self.spinup_time != self.total_time:
            throw_error('spinup_time must equal total_time for mirrored simulations, so only the ocean component runs')
        self.mirror_path = check_value('mirror_path', mirror_path)
        if self.mirror and not os.path.isdir(self.mirror_path):
            throw_error('mirror_path ' + mirror_path + ' does not exist')
        self.mirror_path_final = check_value('mirror_path_final', mirror_path_final)
        self.restart_type = check_value('restart_type', restart_type, legal=['zero', 'pickup'])
        self.calendar_type = check_value('calendar_type', calendar_type, legal=['standard', 'noleap', '360-day'])
        self.output_freq = check_value('output_freq', output_freq, legal=['monthly', 'daily', 'end'])
        self.digging = check_value('digging', digging, legal=['none', 'bathy', 'draft'])
        self.dig_full_cells = check_value('dig_full_cells', dig_full_cells, type='bool')
        self.filling = check_value('filling', filling, type='bool')
        self.adjust_vel = check_value('adjust_vel', adjust_vel, type='bool')
        self.misomip_wall = check_value('misomip_wall', misomip_wall, type='bool')
        self.preserve_open_ocean_bathy = check_value('preserve_open_ocean_bathy', preserve_open_ocean_bathy, type='bool')
        self.preserve_ocean_mask = check_value('preserve_ocean_mask', preserve_ocean_mask, type='bool')
        self.preserve_static_ice = check_value('preserve_static_ice', preserve_static_ice, type='bool')
        self.pload_option = check_value('pload_option', pload_option, legal=['constant', 'nearest'])
        if self.pload_option == 'constant':
            self.pload_temp = check_value('pload_temp', pload_temp, type='float')
            self.pload_salt = check_value('pload_salt', pload_salt, type='float')
        else:
            # Set dummy values for pload_temp and pload_salt; since they're never used, there's no need to error check
            self.pload_temp = 0.
            self.pload_salt = 0.
        self.ua_ini_restart = check_value('ua_ini_restart', ua_ini_restart, type='bool')
        self.correct_obcs_online = check_value('correct_obcs_online', correct_obcs_online, type='bool')
        self.obcs_transient = check_value('obcs_transient', obcs_transient, type='bool')
        self.correct_obcs_steps = check_value('correct_obcs_steps', correct_obcs_steps, type='int')
        if self.correct_obcs_steps < 1:
            throw_error('correct_obcs_steps cannot be less than 1')
        # Make sure couple_step*correct_obcs_steps is a multiple of 12 if we want to do OBCS corrections online
        if self.correct_obcs_online and self.correct_obcs_steps*self.couple_step % 12 != 0:
            throw_error('couple_step*correct_obcs_steps must be a multiple of 12 when correct_obcs_online is set')
        self.obcs_threshold = check_value('obcs_threshold', obcs_threshold, type='float') 
            
        self.coordinates = check_value('coordinates', coordinates, legal=['xy', 'latlon'])
        self.use_seaice = check_value('use_seaice', use_seaice, type='bool')
        self.use_ptracers = check_value('use_ptracers', use_ptracers, type='bool')
        if self.use_ptracers and self.restart_type != 'pickup':
            throw_error('ptracers package only works with pickup-restarts')
        self.use_cal_pkg = check_value('use_cal_pkg', use_cal_pkg, type='bool')
        self.use_ini_deltaTmom = check_value('use_ini_deltaTmom', use_ini_deltaTmom, type='bool')
        self.deltaT = check_value('deltaT', deltaT, type='int')
        # Make sure ocean timestep evenly divides 1 day
        if sec_per_day % self.deltaT != 0:
            throw_error('deltaT must evenly divide 1 day')
        self.hFacMin = check_value('hFacMin', hFacMin, type='float')
        self.hFacMinDr = check_value('hFacMinDr', hFacMinDr, type='float')
        self.readBinaryPrec = check_value('readBinaryPrec', readBinaryPrec, type='int', legal=[32, 64])
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
        if self.use_seaice:
            self.seaice_nz = check_value('seaice_nz', seaice_nz, type='int')
        else:
            self.seaice_nz = 0
        # Make sure the start date is in the right format
        problem = len(startDate) != 8
        try:
            tmp = int(startDate)
        except(ValueError):
            problem = True
        if problem:
            throw_error('startDate should be an 8-digit code in the form YYYYMMDD')
        self.startDate = startDate
        self.use_addmass = check_value('use_addmass', use_addmass, type='bool')
        self.seaice_sigma = check_value('seaice_sigma', seaice_sigma, type='bool')

        self.calendar_file = calendar_file
        self.finished_file = finished_file
        self.eta_file = eta_file
        self.bathyFile = bathyFile
        self.draftFile = draftFile
        self.ini_temp_file = ini_temp_file
        self.ini_salt_file = ini_salt_file
        self.ini_u_file = ini_u_file
        self.ini_v_file = ini_v_file
        self.ini_eta_file = ini_eta_file
        if self.use_seaice:
            self.ini_area_file = ini_area_file
            self.ini_heff_file = ini_heff_file
            self.ini_hsnow_file = ini_hsnow_file
            self.ini_uice_file = ini_uice_file
            self.ini_vice_file = ini_vice_file
        else:
            self.ini_area_file = ''
            self.ini_heff_file = ''
            self.ini_hsnow_file = ''
            self.ini_uice_file = ''
            self.ini_vice_file = ''
        self.pload_file = pload_file
        self.ismr_name = ismr_name
        if self.correct_obcs_online:
            self.etan_name = etan_name
        else:
            self.etan_name = ''
        self.output_names = check_value('output_names', output_names, type='list')
        if self.use_xmitgcm:
            self.mit_nc_name = mit_nc_name
            if not self.mit_nc_name.endswith('.nc'):
                throw_error('mit_nc_name must be a NetCDF file')
            self.dump_start_nc_name = 'dump_start.nc'
            self.dump_end_nc_name = 'dump_end.nc'
            if mit_nc_name in [self.dump_start_nc_name, self.dump_end_nc_name]:
                throw_error('mit_nc_name cannot be '+mit_nc_name)
        else:
            self.mit_nc_name = ''
            self.dump_start_nc_name = ''
            self.dump_end_nc_name = ''
        self.ua_melt_file = ua_melt_file
        self.ua_draft_file = ua_draft_file
        if self.correct_obcs_online:
            self.obcs_file_w_u = obcs_file_w_u
            self.obcs_file_e_u = obcs_file_e_u
            self.obcs_file_s_v = obcs_file_s_v
            self.obcs_file_n_v = obcs_file_n_v
            if not self.obcs_transient:
                # Make sure master copies exist
                for fname in [self.obcs_file_w_u, self.obcs_file_e_u, self.obcs_file_s_v, self.obcs_file_n_v]:
                    if fname is not None:
                        if not os.path.isfile(self.mit_run_dir+fname+'.master'):
                            print('Error (Options): need to make master copy of ' + fname)
                            sys.exit()
        else:
            self.obcs_file_w_u = None
            self.obcs_file_e_u = None
            self.obcs_file_s_v = None
            self.obcs_file_n_v = None

        # Initialise first and last timesteps to 0 (will be updated later if needed)
        self.first_timestep = 0
        self.last_timestep = 0

        # Now write the variables Ua needs in a plain text file.
        f = open(self.ua_exe_dir+'options_for_ua', 'w')
        f.write(self.expt_name+'\n')
        f.write(self.output_dir+'\n')
        f.write(self.calendar_file+'\n')
        f.write(self.ua_melt_file+'\n')
        f.write(self.ua_draft_file+'\n')
        f.write(self.ua_output_format+'\n')
        f.write(self.coordinates+'\n')
        f.close()


    # Class function to save calendar info from the previous simulation segment: the starting date (useful for NetCDF conversion) and the initial/final timestep numbers in the simulation (useful for reading output).
    def save_last_calendar (self, start_date, ndays_old, ndays_new):
        self.last_start_date = start_date
        self.first_timestep = int(ndays_old*sec_per_day/self.deltaT)
        self.last_timestep = int(ndays_new*sec_per_day/self.deltaT)

        
    # Class function to set the simulation type (initial, restart, spinup, first_coupled, finished, and/or init_repeat).
    def save_simulation_type (self, initial, restart, spinup, first_coupled, finished, init_repeat):
        self.initial = initial
        self.restart = restart
        self.spinup = spinup
        self.first_coupled = first_coupled
        self.finished = finished
        self.init_repeat = init_repeat
        

# end class Options


# Update the "data" and "data.diagnostics" namelists for the next simulation segment. For restart_type 'pickup', we need to check/update niter0 (last timestep of previous segment), endTime and pckptFreq (length of the simulation up until the end of the next segment). For restart_type 'zero', we need to check/update endTime (length of the next segment). This is necessary because the number of days per month is not constant for calendar types 'standard' and 'noleap'. For calendar type '360-day', just check that the values already there agree with what we'd expect.
# Also set the frequency of user-specified diganostic filetypes in data.diagnostics (options.output_names), to agree with options.output_freq.
def update_namelists (mit_dir, segment_length, simulation_length, options):

    # Set file paths
    namelist = mit_dir + 'data'
    namelist_diag = mit_dir + 'data.diagnostics'
    if not options.initial:
        # Make backup copies
        make_tmp_copy(namelist)
        make_tmp_copy(namelist_diag)

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
        return freq, freq_line, index

    # Inner function to throw an error or a warning if the value of a namelist variable is not what we expect (eg in a 360-day calendar where every simulation segment should be the same length).
    def throw_error_warning (var_string, file_name, error=False):
        if error:
            message = 'Error: '
        else:
            message = 'Warning: '
        message += var_string + ' has an incorrect value in ' + file_name
        print(message)
        if error:
            sys.exit()

    # Inner function to check if a variable needs to be updated, and then update the file if needed.
    # In some cases we don't think the variable should need to be changed; if so, throw an error (if error=True) or a warning (if error=False).
    # Control which situations this error/warning is thrown with the keyword argument "check": check='360' throws an error/warning if it's a 360-day calendar and the variable needs to be changed; check='all' throws an error/warning if the variable needs to be changed, regardless of the calendar; check='none' will never throw errors or warnings.
    def check_and_change (old_var, new_var, old_line, new_line, file_name, var_string, error=False, check='360'):
        if old_var != new_var:
            if check=='all' or (check=='360' and options.calendar_type == '360-day'):
                throw_error_warning(var_string, file_name, error=error)
            print('Updating ' + var_string + ' in ' + file_name)
            replace_line(file_name, old_line, new_line)

    # Now the work starts

    # Update endTime
    # First figure out what endTime should be
    if options.restart_type == 'zero':
        # Just the length of this segment
        endTime = segment_length
        # This should only change between segments if it's not a 360-day calendar
        check = '360'
    elif options.restart_type == 'pickup':
        # Length of the simulation up until the end of this segment
        endTime = simulation_length
        # This will always change
        check = 'none'
    # Look for endTime in "data" namelist
    endTime_line = line_that_matters(namelist, 'endTime')
    # Strip out the number
    old_endTime = extract_first_int(endTime_line)
    # Update file if needed
    check_and_change(old_endTime, endTime, endTime_line, ' endTime='+str(endTime)+',\n', namelist, 'endTime', check=check)

    if options.restart_type == 'pickup':
        # Update pchkptFreq
        ckpt = simulation_length
        ckpt_line = line_that_matters(namelist, 'pchkptFreq')
        old_ckpt = extract_first_int(ckpt_line)
        check_and_change(old_ckpt, ckpt, ckpt_line, ' pchkptFreq='+str(ckpt)+',\n', namelist, 'pchkptFreq', check='none')
        # Update niter0
        # No need to check this, as it will change every time
        print('Updating niter0 in ' + namelist)
        if options.init_repeat:
            niter0_new = 0
        else:
            niter0_new = options.last_timestep
        niter0_line = line_that_matters(namelist, 'niter0')
        replace_line(namelist, niter0_line, ' niter0='+str(niter0_new)+',\n')
        if options.init_repeat:
            # Rename pickup files so simulation uses them as initial conditions
            file_heads = ['pickup.']
            if options.use_seaice:
                file_heads += ['pickup_seaice.']
            if options.use_ptracers:
                file_heads += ['pickup_ptracers.']
            file_tails = ['.data', '.meta']
            tstep_string = str(options.last_timestep).zfill(10)
            for head in file_heads:
                for tail in file_tails:
                    start_name = mit_dir + head + tstep_string + tail
                    end_name = mit_dir + head + 'ckptA' + tail
                    print('Moving ' + start_name + ' to ' + end_name)
                    os.rename(start_name, end_name)
            # Now update namelist to use these files
            # First make sure pickupSuff is not already defined
            pickupSuff_line = line_that_matters(namelist, 'pickupSuff', throw_error=False)
            if pickupSuff_line is not None:
                print('Error (update_namelists): pickupSuff is already defined. Remove or comment it out so we can set pickupSuff without confusion.')
                sys.exit()
            # Now add the new line, right after niter0
            niter0_line = line_that_matters(namelist, 'niter0')
            add_line(namelist, " pickupSuff='ckptA',\n", niter0_line)
        else:
            # Make sure pickupSuff is commented out
            find_comment_line(namelist, 'pickupSuff')

    if options.use_ini_deltaTmom:
        print('Checking deltaTmom in ' + namelist)
        if options.initial:
            # Make sure it's there and uncommented
            if line_that_matters(namelist, 'deltaTmom', throw_error=False) is None:
                print('Error (update_namelists): use_ini_deltaTmom=False but ' + namelist + ' does not set a value for deltaTmom! Is it commented out?')
                sys.exit()
        else:
            # Comment it out
            find_comment_line(namelist, 'deltaTmom')
                
    # Now set/check diagnostic frequencies. If it's not an initial run and the existing frequencies don't match what we expect, throw an error.
    if len(options.output_names) > 0:

        # Figure out what the frequency should be
        if options.output_freq == 'monthly':
            # Set to 30 days. For 360-day calendars, every month is 30 days; for standard and noleap calendars, the MITgcm calendar package will update to make this a real month.
            freq = 30*sec_per_day
        elif options.output_freq == 'daily':
            freq = sec_per_day
        elif options.output_freq == 'end':
            freq = segment_length

        # Loop over diagnostic filetypes
        for fname in options.output_names:
            curr_freq, curr_line, curr_index = get_diag_freq(fname)
            if options.initial:
                check = 'none'
            else:
                check = 'all'
            check_and_change(curr_freq, freq, curr_line, ' frequency('+str(curr_index)+') = '+str(freq)+'.,\n', namelist_diag, 'diagnostic frequency of '+fname, check=check)
            
# end function update_namelists


# Helper function to set_calendar (also used in change_coupling_step.py)
def update_calendar_file (new_year, new_month, couple_step, options, calfile):

    # Get the date at the beginning of the simulation after next
    newer_year, newer_month = add_months(new_year, new_month, couple_step)
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
            output_intervals = couple_step*[30]
        else:
            # Loop through the months to find the number of days in each
            curr_year = new_year
            curr_month = new_month
            output_intervals = []
            for t in range(couple_step):
                output_intervals.append(days_per_month(curr_month, curr_year, allow_leap=(options.calendar_type=='standard')))
                curr_year, curr_month = add_months(curr_year, curr_month, 1)
    elif options.output_freq == 'end':
        # One line with the number of days in the simulation
        output_intervals = [ndays_new]

    print('Updating ' + calfile)
    f = open(calfile, 'w')
    f.write(date_code_new + '\n')
    f.write(str(ndays_new) + '\n')
    for interval in output_intervals:
        f.write(str(interval) + '\n')
    f.close()

    return newer_year, newer_month, ndays_new, date_code_new


# Read and update the plain-text file in "directory" that keeps track of the calendar (starting date of last simulation segment, and number of days in that simulation). Update any parameters that depend on the calendar (including namelists in mit_dir). Determine whether the run is an initial, restart, spinup, first_coupled, finished, and/or init_repeat run.
def set_calendar (options):

    directory = options.output_dir
    mit_dir = options.mit_run_dir

    # Figure out if this the very first segment, based on whether the calendar file already exists
    calfile = directory + options.calendar_file    
    initial = not os.path.isfile(calfile)
    if not initial:
        # Make a backup copy
        make_tmp_copy(calfile)

    # Figure out if this is restarting from a previously-finished segment, based on whether the finished-file already exists
    finifile = directory + options.finished_file
    restart = os.path.isfile(finifile)
    init_repeat = restart and options.repeat
    if restart:
        # Remove it
        os.remove(finifile)
        if init_repeat:
            print('This is a restart which repeats the forcing period from the beginning')
        else:
            print('This is a restart from a previously-finished simulation that was extended')

    # Get the start year and month for the whole simulation
    ini_year = int(options.startDate[:4])
    ini_month = int(options.startDate[4:6])
    
    if initial:
        print('This is the first segment')
        print('Initialising calendar')
        new_year = ini_year
        new_month = ini_month
    else:
        print('Advancing calendar by ' + str(options.couple_step) + ' months')
        
        # Read the first 2 lines of the calendar file
        f = open(calfile, 'r')
        date_code = f.readline().strip()
        ndays = int(f.readline())
        f.close()

        # Parse the date code
        old_year = int(date_code[:4])
        old_month = int(date_code[4:])
        # Get the date at the beginning of the next simulation
        new_year, new_month = add_months(old_year, old_month, options.couple_step)
        # Make sure ndays makes sense
        if ndays != days_between(old_year, old_month, new_year, new_month, options.calendar_type):
            print('Error (set_calendar): number of days in last simulation does not agree with couple_step and/or calendar_type.')
            sys.exit()

        # Save the last timestep and date code to the Options object
        if options.restart_type == 'zero':
            # First timestep is 0, and last timestep will be based on number of days in the segment
            options.save_last_calendar(date_code, 0, ndays)
        elif options.restart_type == 'pickup':
            # First and last timestep will be based on number of days in the simulation since the very beginning
            options.save_last_calendar(date_code, days_between(ini_year, ini_month, old_year, old_month, options.calendar_type), days_between(ini_year, ini_month, new_year, new_month, options.calendar_type))

        if init_repeat:
            print('Resetting calendar to beginning')
            new_year = ini_year
            new_month = ini_month

    # Figure out if we're in the ocean-only spinup period
    # Find the year and month when coupling begins
    couple_year, couple_month = add_months(ini_year, ini_month, options.spinup_time)
    spinup = (new_year < couple_year) or (new_year==couple_year and new_month < couple_month)
    if spinup:
        print('Simulation is in ocean-only spinup phase')
        
    # Figure out if it's the first coupled timestep
    first_coupled = new_year==couple_year and new_month==couple_month

    # Figure out if the simulation is finished
    # Find the year and month after the simulation ends
    end_year, end_month = add_months(ini_year, ini_month, options.total_time)
    finished = new_year==end_year and new_month==end_month
    
    # Save all the information about this simulation type to the Options object
    options.save_simulation_type(initial, restart, spinup, first_coupled, finished, init_repeat)
    
    if finished:
        print('Simulation has finished')
        # Create the finished file
        open(finifile, 'a').close()
    else:
        print('Setting output intervals')
        newer_year, newer_month, ndays_new, date_code_new = update_calendar_file(new_year, new_month, options.couple_step, options, calfile)

        if options.use_cal_pkg and options.restart_type=='zero':
            print('Updating start date for calendar package')
            # Look for startDate_1 in "data.cal" namelist
            namelist_cal = mit_dir + 'data.cal'
            start_date_line = line_that_matters(namelist_cal, 'startDate_1')
            replace_line(namelist_cal, start_date_line, ' startDate_1='+date_code_new+'01,\n')            

        print('Updating namelists')
        # Calculate segment length in seconds
        segment_length = ndays_new*sec_per_day
        # Calculate simulation length (up to the end of the next segment) in seconds
        simulation_length = days_between(ini_year, ini_month, newer_year, newer_month, options.calendar_type)*sec_per_day
        # Update/check endTime for next MITgcm segment, and diagnostic frequencies
        update_namelists(mit_dir, segment_length, simulation_length, options)

    

        

    

    
