######################################################
# Create the initial topography, initial conditions,
# and boundary conditions for MITgcm.
######################################################

import numpy as np
from scipy.io import loadmat
import sys
# Get mitgcm_python in the path
# TODO: is this the best way to do it? Absolute path? .bashrc?
sys.path.insert(0, '../../tools/')
from mitgcm_python.file_io import write_binary
from mitgcm_python.utils import z_to_xyz
from mitgcm_python.make_domain import calc_hfac, do_digging, do_zapping
from mitgcm_python.ics_obcs import calc_load_anomaly


# Global parameters
# These are all things set in the input/data namelist.
nx = 240    # first part of delX
ny = 42     # first part of delY
nz = 36     # first part of delZ
dz = 20.    # second part of delZ
eosType = 'LINEAR'
Tref = -1.
Sref = 34.2
tAlpha = 3.733e-5
sBeta = 7.843e-4
rhoConst = 1028.
hFacMin = 0.05
hFacMinDr = 0.


# BasicGrid object to hold some information about the grid - just the variables we need to create all the initial conditions, with the same conventions as the mitgcm_python Grid object where needed. This way we can call calc_load_anomaly without needing a full Grid object.
class BasicGrid:

    def __init__ (self):
        # Build vertical grid
        self.z_edges = np.arange(0, -(nz+1)*dz, -dz)
        self.z = 0.5*(self.z_edges[:-1] + self.z_edges[1:])
        # Save grid dimensions
        self.nx = nx
        self.ny = ny
        self.nz = nz

    # Calculate hFacC given the bathymetry and ice shelf draft.
    # Save to the object.
    def save_hfac (self, bathy, draft):
        self.hfac = calc_hfac(bathy, draft, self.z_edges, hFacMin=hFacMin, hFacMinDr=hFacMinDr)

    # Compatibility function with Grid.
    def get_hfac (self, gtype='t'):
        if gtype != 't':
            print 'Error (BasicGrid.get_hfac): hfac only exists on tracer grid'
            sys.exit()
        return self.hfac

# end BasicGrid object


# Calculate the topography and write to binary files.
def make_topo (grid, ua_topo_file, bathy_file, draft_file, prec=64, dig_option='none', bathy_orig_file=None):

    # Read bathymetry and initial ice shelf draft from Ua
    # (end of MISMIP experiment)
    f = loadmat(ua_topo_file)
    bathy = np.transpose(f['B_forMITgcm'])
    draft = np.transpose(f['b_forMITgcm'])
    mask = np.transpose(f['mask_forMITgcm'])
    # Mask grounded ice out of both fields
    bathy[mask==0] = 0
    draft[mask==0] = 0
    
    # Build a wall at the north and south
    bathy[0,:] = 0
    draft[0,:] = 0
    bathy[-1,:] = 0
    draft[-1,:] = 0

    if dig_option == 'none':
        print 'Not doing digging as per user request'
    elif dig_option == 'bathy':
        print 'Saving original bathymetry'
        if bathy_orig_file is None:
            print "Error (make_topo): must set bathy_orig_file if dig_option='bathy'"
            sys.exit()
        write_binary(bathy, bathy_orig_file, prec=prec)
        print 'Digging bathymetry which is too shallow'
        bathy = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=hFacMin, hFacMinDr=hFacMinDr, dig_option='bathy')
    elif dig_option == 'draft':
        print 'Digging ice shelf drafts which are too deep'
        draft = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=hFacMin, hFacMinDr=hFacMinDr, dig_option='draft')

    print 'Zapping ice shelf drafts which are too thin'
    draft = do_zapping(draft, draft!=0, grid.dz, grid.z_edges, hFacMinDr=hFacMinDr)        

    # Calculate hFacC and save to the grid for later
    grid.save_hfac(bathy, draft)

    # Write to file
    write_binary(bathy, bathy_file, prec=prec)
    write_binary(draft, draft_file, prec=prec)


# Returns temperature and salinity profiles, varying with depth, to be used for initial and boundary conditions.
# This is the MISOMIP "warm" case.
def ts_profile (z):

    T0 = -1.9
    Tbot = 1.
    S0 = 33.8
    Sbot = 34.7
    zdeep = -720.

    t_profile = T0 + (Tbot-T0)*z/zdeep
    s_profile = S0 + (Sbot-S0)*z/zdeep

    return t_profile, s_profile


# Creates OBCS for the eastern boundary, and initial conditions for temperature and salinity, using the T/S profiles above. Also calculates the pressure load anomaly.
def make_ics_obcs (grid, ini_temp_file, ini_salt_file, obcs_temp_file, obcs_salt_file, obcs_u_file, obcs_v_file, pload_file, prec=64):

    t_profile, s_profile = ts_profile(grid.z)

    # Tile to cover the whole domain
    temp = z_to_xyz(t_profile, [nx, ny])
    salt = z_to_xyz(s_profile, [nx, ny])

    # Extract boundary conditions
    temp_e = temp[:,:,-1]
    salt_e = salt[:,:,-1]
    # Zero velocity
    u_e = np.zeros([nz,ny])
    v_e = np.zeros([nz,ny])

    # Write the files
    # No need to mask out the land because MITgcm will do that for us
    write_binary(temp, ini_temp_file, prec=prec)
    write_binary(salt, ini_salt_file, prec=prec)
    write_binary(temp_e, obcs_temp_file, prec=prec)
    write_binary(salt_e, obcs_salt_file, prec=prec)
    write_binary(u_e, obcs_u_file, prec=prec)
    write_binary(v_e, obcs_v_file, prec=prec)

    # Calculate the pressure load anomaly
    calc_load_anomaly(grid, pload_file, option='precomputed', ini_temp_file=ini_temp_file, ini_salt_file=ini_salt_file, eosType=eosType, rhoConst=rhoConst, tAlpha=tAlpha, sBeta=sBeta, Tref=Tref, Sref=Sref, prec=prec, check_grid=False)



############## USER INPUT HERE #########################
# Path to MITgcm input/ directory for the MISOMIP case
input_dir = './'#'/work/n02/n02/kaight/mitgcm/cases/MISOMIP_999/input/'

print 'Building grid'
grid = BasicGrid()

print 'Creating topography'
make_topo(grid, 'ua_draft_file.mat', input_dir+'bathymetry.shice', input_dir+'shelfice_topo.bin', prec=64)

print 'Creating initial and boundary conditions'
make_ics_obcs(grid, input_dir+'lev_t.shice', input_dir+'lev_s.shice', input_dir+'OBEt', input_dir+'OBEs', input_dir+'OBEu', input_dir+'OBEv', input_dir+'phi0surf.bin', prec=64)




    


    
