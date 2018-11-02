################################################################################
# Functions to exchange data between MITgcm and Ua, and prepare MITgcm for the next segment.
################################################################################

import numpy as np
from scipy.io import savemat

from MITgcmutils import rdmds

from mitgcm_python.utils import convert_ismr, z_to_xyz
from mitgcm_python.make_domain import model_bdry, level_vars, do_digging, do_zapping
from mitgcm_python.file_io import read_binary, write_binary
from mitgcm_python.interpolation import discard_and_fill


# Put MITgcm melt rates in the right format for Ua. No need to interpolate.

# Arguments:
# ismr_head: beginning of file paths of the binary files containing SHIfwFlx data, including the directory. i.e. ismr_head.xxxxx.data and ismr_head.xxxxx.meta where xxxxx is the diagnostic timestep.
# ua_out_file: desired path to .mat file for Ua to read melt rates from.
# grid: Grid object (for the MITgcm segment that just finished)

def extract_melt_rates (ismr_head, ua_out_file, grid):

    # Read the most recent file containing ice shelf melt rate
    data, its, meta = rdmds(ismr_head, itrs=np.Inf, returnmeta=True)
    print 'Reading melt rates from ocean timestep ' + str(its)
    # Figure out which index contains SHIfwflx
    i = meta['fldlist'].index('SHIfwFlx')
    # Extract the ice shelf melt rate and convert to m/y
    ismr = convert_ismr(data[i,:,:])

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
#    'bathy': dig bathymetry which is too deep
#    'draft': dig ice shelf drafts which are too shallow
# In all cases, also remove ice shelf drafts which are too thin.
# Ua does not see these changes to the geometry.

# Arguments:
# ua_draft_file: path to ice shelf draft file written by Ua at the end of the last segment (TODO: define format)
# bathy_file: path to MITgcm bathymetry file (binary) from the last segment. If options.digging='bathy', it will get overwritten.
# draft_file: path to desired MITgcm ice shelf draft file (binary).
# grid: Grid object
# options: TODO define this

def adjust_mit_geom (ua_draft_file, bathy_file, draft_file, grid, options):

    # TODO: Read Ua draft output and possibly reassemble
    # Save in variable 'draft'
    
    # Read MITgcm bathymetry file from last segment
    bathy = read_binary(bathy_file, [grid.nx, grid.ny], 'xy', prec=options.topo_prec)

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
    print 'Writing ' + draft_file
    write_binary(draft, draft_file, prec=options.topo_prec)
    if options.digging == 'bathy':
        # Bathymetry can only change in one case
        print 'Writing ' + bathy_file
        write_binary(bathy, bathy_file, prec=options.topo_prec)
    

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

    # Tile the z-level centres to be 3D
    z_3d = z_to_xyz(z, grid)
    
    # Identify all z-centres between the two edges. This should be equivalent to ceil(hFacC). TODO: test this equivalence.
    return (z_3d <= edge_above_draft)*(z_3d >= edge_below_bathy)



def set_mit_ics (bathy_file, draft_file, grid, options):

    # TODO: Read temp, salt, u, v. From last pickup (need pickup frequency set correctly, or dump last)? Or diagnostic at the right time?
    if options.use_seaice:
        # TODO: Read aice, hice, hsnow, uice, vice
        pass
    
    # Read the new ice shelf draft, and also the bathymetry
    print 'Reading ' + draft_file
    draft = read_binary(draft_file, [grid.nx, grid.ny], 'xy', prec=options.topo_prec)
    print 'Reading ' + bathy_file
    bathy = read_binary(bathy_file, [grid.nx, grid.ny], 'xy', prec=options.topo_prec)

    print 'Selecting newly opened cells'
    # Figure out which cells will be (at least partially) open in the next segment
    open_next = find_open_cells(bathy, draft, grid)
    # Now select the ones which weren't already open in the last segment
    newly_open = open_next*(grid.hfac==0)

    print 'Extrapolating temperature into newly opened cells'
    temp_new = discard_and_fill(temp, [], newly_open, missing_val=0)
    print 'Extrapolating salinity into newly opened cells'
    salt_new = discard_and_fill(salt, [], newly_open, missing_val=0)

    # TODO: Write out all variables including sea ice ones, with new mask applied (inverse of newly_open, select surface for sea ice)

    # TODO: Calculate pload anomaly: write a new function in ics_obcs.py, encapsulate mitgcm_python imports within that module, get calc_load_anomaly to call it with special case of constant T and S. Then write a function here which calls it for all possible options.


    
    

    
