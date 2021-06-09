# Change the coupling timestep.
# Run this after a simulation has finished, and then extend it and restart.
# Give it two arguments: the old value of couple_step, and the new value.
# Example: python ../../coupling/change_coupling_step.py 12 6
# No need to change couple_step in config_options.py (this script will do it
# for you), although you will have to change total_time as needed.

import sys
sys.path.insert(0,'./')
import os
from set_parameters import Options, update_calendar_file
from coupling_utils import add_months, subtract_months, line_that_matters, replace_line

old_couple_step = int(sys.argv[1])
new_couple_step = int(sys.argv[2])
options = Options()

# Error checking
if old_couple_step != options.couple_step:
    print('Error (change_coupling_step): an original coupling step of ' + str(old_couple_step) + ' does not match the value in config_options.py, of ' + str(options.couple_step) + '.')
    sys.exit()
if not os.path.isfile(options.output_dir + options.finished_file):
    print('Warning (change_coupling_step): Looks like the last simulation did not finish properly. If this is deliberate, make sure everything works when you restart!!')

# Read the date code from the calendar file
calfile = options.output_dir + options.calendar_file
f = open(calfile, 'r')
date_code = f.readline().strip()
f.close()
orig_old_year = int(date_code[:4])
orig_old_month = int(date_code[4:])
# Get the date code at the beginning of the next segment, if the old coupling step was used
orig_new_year, orig_new_month = add_months(orig_old_year, orig_old_month, old_couple_step)
# Now subtract the new coupling step to get the date code that will fool the model
old_year, old_month = subtract_months(orig_new_year, orig_new_month, new_couple_step)
# Overwrite the calendar file
update_calendar_file(old_year, old_month, new_couple_step, options, calfile)

# Now update couple_step in config_options.py
options_file = 'config_options.py'
old_line = line_that_matters(options_file, 'couple_step')
replace_line(options_file, old_line, old_line.replace(str(old_couple_step), str(new_couple_step)))



