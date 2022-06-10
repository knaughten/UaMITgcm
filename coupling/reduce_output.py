# Reduce the output in the given simulation by deleting pickups, topography files, etc - everything except for output.nc.
# Optionally, pass an arbitrary number of years for which all output should be preserved.

import sys
import os

from set_parameters import Options

years_skip = []
for i in len(sys.argv):
    years_skip.append(int(sys.argv[i]))

message = 'Output will be reduced for all years'
if len(years_skip) > 0:
    message += ' except '+str(years_skip)
message += '. Do you want to proceed (yes/no)? '

out = input(message).strip()
while True:
    if out == 'yes':
        break
    if out == 'no':
        sys.exit()
    out = input('Please answer yes or no. ').strip()

options = Options()
for dname in os.listdir(options.output_dir):
    if os.path.isdir(options.output_dir+dname):
        if int(dname[:4]) in years_skip:
            print('Skipping '+dname[:4])
            continue
        date_dir = options.output_dir+dname+'/MITgcm/'
        for fname in os.listdir(date_dir):
            if fname.endswith('.nc'):
                continue
            else:
                os.remove(date_dir+fname)
        
