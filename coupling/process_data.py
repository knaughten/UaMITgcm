################################################################################
# Functions to exchange data between MITgcm and Ua, and adjust the MITgcm geometry/initial conditions as needed.
################################################################################

import numpy as np
from scipy.io import savemat

# TODO: add MITgcmutils and mitgcm_python to python path. 3 options here:
# 1. In the control script which calls these files, use sys.path.insert(0, path) relative to os.get_cwd()
# 2. Get the user to edit PYTHONPATH in their .bashrc
# 3. Edit PYTHONPATH in all PBS job scripts that use these files
# I think option 3 is preferable. No work for the user, and it makes sure the paths are correct.

from MITgcmutils import rdmds

from mitgcm_python.utils import convert_ismr, xy_to_xyz, z_to_xyz, real_dir
from mitgcm_python.make_domain import model_bdry, level_vars, do_digging, do_zapping
from mitgcm_python.file_io import read_binary, write_binary
from mitgcm_python.interpolation import discard_and_fill
from mitgcm_python.ics_obcs import calc_load_anomaly


# Helper function for extract_melt_rates and set_mit_ics
# Find the most recently modified MITgcm binary output file of a given type/name (file_head, eg 'MIT2D' or 'pickup') and extract all the variables in the given list of names. Note that temporary pickup files (eg pickup.ckptA.data) will be ignored.
# If there is an expected value for the timestep number corresponding to this output, check that it agrees. Can print a custom error message if it doesn't, suggesting what the likely source of the problem is.
def read_last_output (directory, file_head, var_names, timestep=None, error_message=None):

    # Check if var_names is a string rather than a list
    if isinstance(var_names, str):
        var_names = [var_names]

    # Read the most recent file
    data, its, meta = rdmds(directory+file_head, itrs=np.Inf, returnmeta=True)
    print 'Read ' + file_head + ' data from MITgcm timestep ' + str(its[0])
    # Make sure it agrees with any expected timestep number
    if timestep is not None and its != timestep:
        print 'Error: most recent ' + file_head + ' file is not from the expected timestep ' + timestep
        if error_message is not None:
            print error_message
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
        

# Put MITgcm melt rates in the right format for Ua. No need to interpolate.

# Arguments:
# mit_dir: MITgcm directory containing SHIfwFlx output
# ua_out_file: desired path to .mat file for Ua to read melt rates from.
# grid: Grid object (for the MITgcm segment that just finished)
# options: Options object

def extract_melt_rates (mit_dir, ua_out_file, grid, options):

    # Make sure directory ends in /
    mit_dir = real_dir(mit_dir)

    # Read the most recent ice shelf melt rate output and convert to m/y
    # TODO: check timestep against calendar and pass error message
    ismr = convert_ismr(read_last_output(mit_dir, options.ismr_name, 'SHIfwFlx'))

    # Put everything in exactly the format that Ua wants: long 1D arrays with an empty second dimension, and double precision
    lon_points = np.ravel(grid.lon_1d)[:,None].astype('float64')
    lat_points = np.ravel(grid.lat_1d)[:,None].astype('float64')
    ismr_points = np.ravel(ismr)[:,None].astype('float64')

    # Write to Matlab file for Ua, as long 1D arrays
    print 'Writing ' + ua_out_file
    savemat(ua_out_file, {'meltrate':ismr_points, 'x':lon_points, 'y':lat_points})  


# Given the updated ice shelf draft from Ua, adjust the draft and/or bathymetry so that MITgcm is happy. In order to have fully connected adjacent water columns, they must overlap by at least two wet cells.
# There are three ways to do this (set in options.digging):
#    'none': ignore the 2-cell rule and don't dig anything
#    'bathy': dig bathymetry which is too shallow
#    'draft': dig ice shelf drafts which are too deep
# In all cases, also remove ice shelf drafts which are too thin.
# Ua does not see these changes to the geometry.

# Arguments:
# ua_draft_file: path to ice shelf draft file written by Ua at the end of the last segment (TODO: define format)
# mit_dir: path to MITgcm directory containing binary files for bathymetry and ice shelf draft
# grid: Grid object
# options: Options object

def adjust_mit_geom (ua_draft_file, mit_dir, grid, options):

    mit_dir = real_dir(mit_dir)

    # TODO: Read Ua draft output and possibly reassemble
    # Save in variable 'draft'
    
    # Read MITgcm bathymetry file from last segment
    bathy = read_binary(mit_dir+options.bathyFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)

    if options.digging == 'none':
        print 'Not doing digging as per user request'
    elif options.digging == 'bathy':
        print 'Digging bathymetry which is too shallow'
        bathy = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr, dig_option='bathy')
    elif options.digging == 'draft':
        print 'Digging ice shelf drafts which are too deep'
        draft = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr, dig_option='draft')

    print 'Zapping ice shelf drafts which are too thin'
    draft = do_zapping(draft, draft!=0, grid.dz, grid.z_edges, hFacMinDr=options.hFacMinDr)
    
    # Ice shelf draft could change in all three cases
    write_binary(draft, mit_dir+options.draftFile, prec=options.readBinaryPrec)
    if options.digging == 'bathy':
        # Bathymetry can only change in one case
        write_binary(bathy, mit_dir+options.bathyFile, prec=options.readBinaryPrec)

    
# Helper function for set_mit_ics
# Given 2D fields for bathymetry and ice shelf draft, and information about the vertical grid (which doesn't change over time, so Grid object from last segment is fine), figure out which cells in the 3D grid are (at least partially) open. Return a 3D boolean array.
def find_open_cells (bathy, draft, grid, options):

    # Calculate the actual bathymetry and ice shelf draft seen by MITgcm, based on hFac constraints
    bathy_model = model_bdry(bathy, grid.dz, grid.z_edges, option='bathy', hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr)
    draft_model = model_bdry(draft, grid.dz, grid.z_edges, option='draft', hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr)

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


# Read MITgcm's state variables from the end of the last segment, and adjust them to create initial conditions for the next segment.
# Any cells which have opened up since the last segment (due to Ua's simulated ice shelf draft changes + MITgcm's adjustments eg digging) will have temperature and salinity set to the average of their nearest neighbours, and velocity to zero.
# Sea ice (if active) will also set to zero area, thickness, snow depth, and velocity in the event of a retreat of the ice shelf front.
# Also set the new pressure load anomaly.

# Arguments:
# mit_dir: path to MITgcm directory containing binary files for bathymetry, ice shelf draft, initial conditions, and TODO: output/pickup?
# grid: Grid object
# options: Options object

def set_mit_ics (mit_dir, grid, options):

    mit_dir = real_dir(mit_dir)

    # Read the final state of ocean variables
    # TODO: Check timestep against calendar and pass error message
    temp, salt, u, v = read_last_output(mit_dir, options.final_state_name, ['THETA', 'SALT', 'UVEL', 'VVEL'])
    if options.use_seaice:
        # Read the final state of sea ice variables
        # TODO: Check timestep against calendar and pass error message
        aice, hice, hsnow, uice, vice = read_last_output(mit_dir, options.seaice_final_state_name, ['SIarea', 'SIheff', 'SIhsnow', 'SIuice', 'SIvice'])
    
    # Read the new ice shelf draft, and also the bathymetry
    draft = read_binary(mit_dir+options.draftFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)
    bathy = read_binary(mit_dir+options.bathyFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)

    print 'Selecting newly opened cells'
    # Figure out which cells will be (at least partially) open in the next segment
    open_next = find_open_cells(bathy, draft, grid)
    # Also save this as a mask with 1s and 0s
    mask_new = open_next.astype(int)
    # Now select the open cells which weren't already open in the last segment
    newly_open = open_next*(grid.hfac==0)

    print 'Extrapolating temperature into newly opened cells'
    temp_new = discard_and_fill(temp, [], newly_open, missing_val=0)
    print 'Extrapolating salinity into newly opened cells'
    salt_new = discard_and_fill(salt, [], newly_open, missing_val=0)
    
    # Write the new initial conditions, masked with 0s (important in case maskIniTemp and/or maskIniSalt are off)
    write_binary(temp_new*mask_new, mit_dir+options.ini_temp_file, prec=readBinaryPrec)
    write_binary(salt_new*mask_new, mit_dir+options.ini_salt_file, prec=readBinaryPrec)

    # Write the initial conditions which haven't changed
    # No need to mask them, as velocity and sea ice variables are always masked when they're read in
    write_binary(u, mit_dir+options.ini_u_file, prec=readBinaryPrec)
    write_binary(v, mit_dir+options.ini_v_file, prec=readBinaryPrec)
    if options.use_seaice:
        write_binary(aice, mit_dir+options.ini_area_file, prec=readBinaryPrec)
        write_binary(hice, mit_dir+options.ini_heff_file, prec=readBinaryPrec)
        write_binary(hsnow, mit_dir+options.ini_hsnow_file, prec=readBinaryPrec)
        write_binary(uice, mit_dir+options.ini_uice_file, prec=readBinaryPrec)
        write_binary(vice, mit_dir+options.ini_vice_file, prec=readBinaryPrec)

    print 'Calculating pressure load anomaly'
    calc_load_anomaly(grid, mit_dir+options.pload_file, option=options.pload_option, constant_t=pload_temp, constant_s=pload_salt, ini_temp_file=mit_dir+options.ini_temp_file, ini_salt_file=mit_dir+options.ini_salt_file, eosType=options.eosType, rhoConst=options.rhoConst, Talpha=options.tAlpha, Sbeta=options.sBeta, Tref=options.Tref, Sref=options.Sref, prec=options.readBinaryPrec)


    
    

    
