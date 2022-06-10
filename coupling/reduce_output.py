# Reduce the output in the given simulation by deleting pickups, topography files, etc - everything except for output.nc.
# Optionally, pass an arbitrary number of years for which all output should be preserved.

import sys
import os

years_skip = []
if len(sys.argv) > 1:
    for i in range(1,len(sys.argv)):
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

output_dir = 'output/'
for dname in os.listdir(output_dir):
    if os.path.isdir(output_dir+dname):
        if int(dname[:4]) in years_skip:
            print('Skipping '+dname[:4])
            continue
        date_dir = output_dir+dname+'/MITgcm/'
        for fname in os.listdir(date_dir):
            if fname.endswith('.nc'):
                continue
            else:
                os.remove(date_dir+fname)
        
