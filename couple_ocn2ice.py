#######################################################
# Send data from MITgcm to Ua.
#######################################################

import numpy as np
from scipy.io import savemat

from MITgcmutils import rdmds

from mitgcm_python.utils import real_dir, convert_ismr


# Put melt rates in the right format for Ua. No need to interpolate.

# Arguments:
# mit_dir: path to directory containing MITgcm binary output files (*.data and *.meta). In particular, the grid files XC and YC, and whichever files contain the SHIfwFlx variable at each diagnostic step.
# ismr_name: beginning of filenames of the binary files containing SHIfwFlx data, i.e. ismr_name.xxxxx.data and ismr_name.xxxxx.meta where xxxxx is the diagnostic timestep.
# ua_out_file: desired path to .mat file for Ua to read melt rates from.

def extract_melt_rates (mit_dir, ismr_name, ua_out_file):

    # Make sure directory ends in /
    mit_dir = real_dir(mit_dir)

    # Read MITgcm grid
    lon = rdmds(mit_dir+'XC')
    lat = rdmds(mit_dir+'YC')

    # Read the most recent file containing ice shelf melt rate
    data, its, meta = rdmds(mit_dir+ismr_name, itrs=np.Inf, returnmeta=True)
    # Figure out which index contains SHIfwflx
    i = meta['fldlist'].index('SHIfwFlx')
    # Extract the ice shelf melt rate and convert to m/y
    ismr = convert_ismr(data[i,:,:])

    # Put everything in exactly the format that Ua wants: long 1D arrays with an empty second dimension, and double precision
    lon_points = np.ravel(lon)[:,None].astype('float64')
    lat_points = np.ravel(lat)[:,None].astype('float64')
    ismr_points = np.ravel(ismr)[:,None].astype('float64')

    # Write to Matlab file for Ua, as long 1D arrays
    savemat(ua_out_file, {'meltrate':ismr_points, 'x':lon_points, 'y':lat_points})
    

    
    
    
