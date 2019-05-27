######################################################
# Create the initial topography, initial conditions,
# and boundary conditions for MITgcm.
######################################################

import numpy as np
from scipy.io import loadmat
import sys
# Get mitgcm_python in the path
sys.path.append('../../coupling')
sys.path.append('../../tools/')
from mitgcm_python.file_io import write_binary
from mitgcm_python.utils import z_to_xyz, calc_hfac
from mitgcm_python.make_domain import do_digging, do_zapping
from mitgcm_python.ics_obcs import calc_load_anomaly
from set_parameters import Options

# Global parameters
# These are all things set in the input/data namelist.
nx = 180    # first part of delX
dx = 1300   # second part of delX
ny = 360    # first part of delY
dy = 1300   # second part of delY
nz = [50, 10, 6]     # first part of delZ
dz = [20, 40, 100]   # second part of delZ
eosType = 'MDJWF'
#Tref = -1.
#Sref = 34.2
#tAlpha = 3.733e-5
#sBeta = 7.843e-4
rhoConst = 1024.
hFacMin = 0.05
hFacMinDr = 0.

# Some additional stuff about the forcing
obcs_forcing_data='Kimura' # either 'Kimura' or 'Holland'
constant_forcing=False # if set to True, the forcing from options.startDate+options.spinup_time will be taken

# read information about startDates, spinup time and simulation time from the options
options = Options()
ini_year = int(options.startDate[:4])
ini_month = int(options.startDate[4:6])
spinup = int(options.spinup_time)
totaltime = int(options.total_time)

if obcs_forcing_data == 'Kimura':
    print 'Using Kimura data for obcs conditions'
    BC = loadmat('../../MIT_InputData/Kimura_OceanBC.mat')
elif obcs_forcing_data == 'Holland':
    print 'Using Holland data for obcs conditions'
    sys.exit('mat file needs generating first!')
else: 
    print 'Error: input data for obcs not found'

# BasicGrid object to hold some information about the grid - just the variables we need to create all the initial conditions, with the same conventions as the mitgcm_python Grid object where needed. This way we can call calc_load_anomaly without needing a full Grid object.
class BasicGrid:

    def __init__ (self):
        # Build vertical grid
        self.z_edges = [0]
        for x in xrange(0,len(dz)):
            self.newedges = -np.arange(dz[x],(nz[x]+1)*dz[x],dz[x])
            self.z_edges = np.concatenate((self.z_edges,self.z_edges[-1]+np.array(self.newedges)),axis=None)
	self.z = 0.5*(self.z_edges[:-1] + self.z_edges[1:])
        self.dz = -self.z_edges[1:] + self.z_edges[:-1]
        # Build horizontal grid
        self.x = np.arange(-1.7e6+dx/2,-1.7e6+(nx-1/2)*dx,dx)
        self.y = np.arange(-7e5+dy/2,-7e5+(ny-1/2)*dy,dy)
        # Save grid dimensions
        self.nx = nx
        self.ny = ny
        self.nz = np.sum(nz)

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
def make_topo (grid, ua_topo_file, bathy_file, draft_file, prec=64, dig_option='none'):

    # Read bathymetry and initial ice shelf draft from Ua
    # (end of MISMIP experiment)
    f = loadmat(ua_topo_file)
    bathy = np.transpose(f['B_forMITgcm'])
    draft = np.transpose(f['b_forMITgcm'])
    mask = np.transpose(f['mask_forMITgcm'])
    # Mask grounded ice out of both fields
    bathy[mask==0] = 0
    draft[mask==0] = 0

    if dig_option == 'none':
        print 'Not doing digging as per user request'
    elif dig_option == 'bathy':
        print 'Digging bathymetry which is too shallow'
        bathy = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=hFacMin, hFacMinDr=hFacMinDr, dig_option='bathy')
    elif dig_option == 'draft':
        print 'Digging ice shelf drafts which are too deep'
        draft = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=hFacMin, hFacMinDr=hFacMinDr, dig_option='draft')

    print 'Zapping ice shelf drafts which are too thin'
    draft = do_zapping(draft, draft!=0, grid.dz, grid.z_edges, hFacMinDr=hFacMinDr)[0]        

    # Calculate hFacC and save to the grid for later
    grid.save_hfac(bathy, draft)

    # Write to file
    write_binary(bathy, bathy_file, prec=prec)
    write_binary(draft, draft_file, prec=prec)


# Returns temperature and salinity profiles, varying with depth, to be used for initial and boundary conditions.
# Pass option='warm' or 'cold'.
def ts_profile(x,y,z):

    sizetz = (nt,np.sum(nz))
    t_profile, s_profile, u_profile, v_profile = np.zeros(sizetz), np.zeros(sizetz), np.zeros(sizetz), np.zeros(sizetz)
    
    findspinupyear = np.in1d(BC['year'],startyear-1)
    findstartyear = np.in1d(BC['year'],startyear)
    Ispinup = np.where(findspinupyear) 
    Ispinup = Ispinup[0]
    Ispinup = np.tile(Ispinup,spinuptime)

    Istart = np.where(findstartyear)
    Istart = Istart[0][0]
 
    L = np.sqrt((x-BC['x'][:,0])**2+(y-BC['y'][:,0])**2)
    IL = np.nanargmin(L)   

    for i in range(0,len(Ispinup)): # initial forcing for spinup time
        t_profile[i,:] = np.interp(-z,-BC['depth'][:,0],BC['Theta'][IL,:,Ispinup[i]])
        s_profile[i,:] = np.interp(-z,-BC['depth'][:,0],BC['Salt'][IL,:,Ispinup[i]])
        u_profile[i,:] = np.interp(-z,-BC['depth'][:,0],BC['Ups'][IL,:,Ispinup[i]])
        v_profile[i,:] = np.interp(-z,-BC['depth'][:,0],BC['Vps'][IL,:,Ispinup[i]])
        
    for i in range(0,nt-len(Ispinup)):
	t_profile[len(Ispinup)+i,:] = np.interp(-z,-BC['depth'][:,0],BC['Theta'][IL,:,Istart+i])
        s_profile[len(Ispinup)+i,:] = np.interp(-z,-BC['depth'][:,0],BC['Salt'][IL,:,Istart+i])
        u_profile[len(Ispinup)+i,:] = np.interp(-z,-BC['depth'][:,0],BC['Ups'][IL,:,Istart+i])
        v_profile[len(Ispinup)+i,:] = np.interp(-z,-BC['depth'][:,0],BC['Vps'][IL,:,Istart+i])

    return t_profile, s_profile, u_profile, v_profile

# Creates OBCS for the southern/western boundary, and initial conditions for temperature and salinity (cold), using the T/S profiles above. Also calculates the pressure load anomaly.
def make_ics_obcs (grid, ini_temp_file, ini_salt_file, obcs_temp_file_S, obcs_salt_file_S, obcs_uvel_file_S, obcs_vvel_file_S, obcs_temp_file_W, obcs_salt_file_W, obcs_uvel_file_W, obcs_vvel_file_W, pload_file, prec):
    
    sizetzx = (nt,np.sum(nz),nx)
    sizetzy = (nt,np.sum(nz),ny)
    OBS_t, OBS_s, OBS_u, OBS_v = np.zeros(sizetzx), np.zeros(sizetzx), np.zeros(sizetzx), np.zeros(sizetzx)
    OBW_t, OBW_s, OBW_u, OBW_v = np.zeros(sizetzy), np.zeros(sizetzy), np.zeros(sizetzy), np.zeros(sizetzy)

    # southern boundary
    for i in xrange(0,nx):
        x = grid.x[i]
        y = grid.y[0]-dy/2
        t_profile, s_profile, u_profile, v_profile = ts_profile(x,y,grid.z)
        OBS_t[:,:,i] = t_profile
        OBS_s[:,:,i] = s_profile
        OBS_u[:,:,i] = u_profile
        OBS_v[:,:,i] = v_profile
	
    # western boundary
    for i in xrange(0,ny):
        x = grid.x[0]-dx/2
        y = grid.y[i]
        t_profile, s_profile, u_profile, v_profile = ts_profile(x,y,grid.z)
        OBW_t[:,:,i] = t_profile
        OBW_s[:,:,i] = s_profile
        OBW_u[:,:,i] = u_profile
        OBW_v[:,:,i] = v_profile
   
    # initial conditions
    t_profile_av, s_profile_av = np.zeros(np.sum(nz)), np.zeros(np.sum(nz))
    for i in xrange(0,np.sum(nz)):
        t_profile_av[i] = np.mean(OBW_t[0,i,:])
        s_profile_av[i] = np.mean(OBW_s[0,i,:])

    INI_t = z_to_xyz(t_profile_av, [nx, ny])
    INI_s = z_to_xyz(s_profile_av, [nx, ny])
                    
    # Write the files
    # No need to mask out the land because MITgcm will do that for us
    write_binary(OBS_t, obcs_temp_file_S, prec=32)
    write_binary(OBS_s, obcs_salt_file_S, prec=32)
    write_binary(OBS_u, obcs_uvel_file_S, prec=32)
    write_binary(OBS_v, obcs_vvel_file_S, prec=32)
    write_binary(OBW_t, obcs_temp_file_W, prec=32)
    write_binary(OBW_s, obcs_salt_file_W, prec=32)
    write_binary(OBW_u, obcs_uvel_file_W, prec=32)
    write_binary(OBW_v, obcs_vvel_file_W, prec=32)
    
    write_binary(INI_t, ini_temp_file, prec=prec)
    write_binary(INI_s, ini_salt_file, prec=prec)

    # Calculate the pressure load anomaly
    calc_load_anomaly(grid, pload_file, option='precomputed', ini_temp_file=ini_temp_file, ini_salt_file=ini_salt_file, eosType=eosType, rhoConst=rhoConst, prec=prec, check_grid=False)

############## USER INPUT HERE #########################
# Path to MITgcm input/ directory for the MISOMIP case
input_dir = 'mitgcm_run/input/'

print 'Building grid'
grid = BasicGrid()

print 'Creating topography'
make_topo(grid, './ua_custom/DataForMIT.mat', input_dir+'bathymetry.shice', input_dir+'shelfice_topo.bin', prec=64, dig_option='bathy')

print 'Creating initial and boundary conditions'
make_ics_obcs(grid, input_dir+'T_ini.bin', input_dir+'S_ini.bin', input_dir+'OBSt.bin', input_dir+'OBSs.bin', input_dir+'OBSu.bin', input_dir+'OBSv.bin', input_dir+'OBWt.bin', input_dir+'OBWs.bin', input_dir+'OBWu.bin', input_dir+'OBWv.bin', input_dir+'pload.mdjwf', prec=64)




    


    
