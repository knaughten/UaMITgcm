################################################################################
# Functions to exchange data between MITgcm and Ua, and adjust the MITgcm geometry/initial conditions as needed.
################################################################################

import numpy as np
from scipy.io import savemat, loadmat
import os
import shutil
import sys
import subprocess

from coupling_utils import read_mit_output, move_to_dir, copy_to_dir, find_dump_prefixes, move_processed_files, make_tmp_copy, overwrite_pickup, line_that_matters, replace_line, get_file_list, years_between, months_between

from mitgcm_python.utils import convert_ismr, calc_hfac, xy_to_xyz, z_to_xyz, mask_land_ice
from mitgcm_python.make_domain import do_filling, do_digging, do_zapping
from mitgcm_python.file_io import read_binary, write_binary, set_dtype, read_netcdf
from mitgcm_python.interpolation import discard_and_fill
from mitgcm_python.ics_obcs import calc_load_anomaly, balance_obcs
from mitgcm_python.calculus import area_average


# Create dummy initial conditions files for the files which might not exist
# because their variables initialise with all zeros.
# Only called if options.restart_type='zero'.
def zero_ini_files (options):

    # Set data type string to read from binary
    dtype = set_dtype(options.readBinaryPrec, 'big')

    # Inner function to create a file if it doesn't exist, with data of the same size as the given array
    def check_create_zero_file (fname, base_array):
        file_path = options.mit_run_dir+fname
        if not os.path.isfile(file_path):
            data = base_array*0
            write_binary(data, file_path, prec=options.readBinaryPrec)
    
    # Start with 3D ocean variables (u and v)
    # Read the initial temperature file so we have the right size
    temp = np.fromfile(options.mit_run_dir+options.ini_temp_file, dtype=dtype)
    check_create_zero_file(options.ini_u_file, temp)
    check_create_zero_file(options.ini_v_file, temp)
    # 2D ocean variables (eta)
    # Read the initial pload file so we have the right size
    pload = np.fromfile(options.mit_run_dir+options.pload_file, dtype=dtype)
    check_create_zero_file(options.ini_eta_file, pload)

    if options.use_seaice:
        # 2D Sea ice variables (area, heff, hsnow, uice, vice)
        check_create_zero_file(options.ini_area_file, pload)
        check_create_zero_file(options.ini_heff_file, pload)
        check_create_zero_file(options.ini_hsnow_file, pload)
        check_create_zero_file(options.ini_uice_file, pload)
        check_create_zero_file(options.ini_vice_file, pload)    
    

# Copy the grid files from one directory to another.
# In practice, they will be copied from the MITgcm run directory to the central output directory, so that Ua can read them.
def copy_grid (mit_dir, out_dir):
    for prefix in ['XC', 'YC', 'XG', 'YG']:
        for suffix in ['.data', '.meta']:
            copy_to_dir(prefix+suffix, mit_dir, out_dir)
        

# Put MITgcm melt rates in the right format for Ua. No need to interpolate.
def extract_melt_rates (options):

    mit_dir = options.mit_run_dir
    ua_out_file = options.output_dir+options.ua_melt_file

    # Read the ice shelf melt rate output (last, avg, or all)
    # and convert to m/y.
    # Melting is negative as per Ua convention.
    if options.melt_coupling == 'last':
        # Make sure it's from the last timestep of the previous simulation.
        timestep = options.last_timestep
    else:
        timestep = None    
    ismr = -1*convert_ismr(read_mit_output(options.melt_coupling, mit_dir, options.ismr_name, 'SHIfwFlx', timestep=timestep))

    if os.path.isfile(ua_out_file):
        # Make a backup copy of the old file
        make_tmp_copy(ua_out_file)

    # Write to Matlab file for Ua
    print('Writing ' + ua_out_file)
    if options.melt_coupling == 'all' and len(ismr.shape)==3:
        # More than one time index
        num_time = ismr.shape[0]
        ismr_ravel = np.empty([num_time, ismr.size//num_time])
        for t in range(num_time):
            ismr_ravel[t,:] = ismr[t,:].ravel()
    else:
        # Long 1D array
        ismr_ravel = ismr.ravel()
    savemat(ua_out_file, {'meltrate':ismr_ravel})


# Given the updated ice shelf draft from Ua, adjust the draft and/or bathymetry so that MITgcm is happy. In order to have fully connected adjacent water columns, they must overlap by at least two wet cells.
# There are three ways to do this (set in options.digging):
#    'none': ignore the 2-cell rule and don't dig anything
#    'bathy': dig bathymetry which is too shallow (starting with original, undug bathymetry so that digging is reversible)
#    'draft': dig ice shelf drafts which are too deep
# In all cases, also remove ice shelf drafts which are too thin.
# Ua does not see these changes to the geometry.
def adjust_mit_geom (grid, options):

    ua_draft_file = options.ua_output_dir+options.ua_draft_file
    mit_dir = options.mit_run_dir

    # Read the bathymetry, ice shelf draft and mask from Ua
    f = loadmat(ua_draft_file)
    bathy = np.transpose(f['B_forMITgcm'])
    draft = np.transpose(f['b_forMITgcm'])
    mask = np.transpose(f['mask_forMITgcm'])        
    # Mask grounded ice out of both fields
    bathy[mask==0] = 0
    draft[mask==0] = 0
    # Mask out regions with bathymetry greater than zero
    index = bathy > 0
    bathy[index] = 0
    draft[index] = 0

    if options.preserve_open_ocean_bathy:
        print('Reverting open ocean bathymetry to original')
        # Read the existing bathymetry seen by MITgcm
        bathy_old = read_binary(mit_dir+options.bathyFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)
        # Find regions which Ua say are open ocean
        index = mask==2
        bathy[index] = bathy_old[index]
    elif options.preserve_ocean_mask:
        print('Blocking out specified regions')
        # Read the existing bathymetry seen by MITgcm
        bathy_old = read_binary(mit_dir+options.bathyFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)
        # Find regions which Ua say are open ocean, but MITgcm say are masked
        index = (mask==2)*(bathy_old==0)
        bathy[index] = 0
        
    if options.preserve_static_ice:
        print('Reinstating static ice shelves in regions outside Ua domain')
        # Read the existing ice shelf draft seen by MITgcm
        draft_old = read_binary(mit_dir+options.draftFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)
        # Find regions which Ua say are open ocean, but MITgcm say are ice shelves
        index = (mask==2)*(draft_old<0)
        draft[index] = draft_old[index]

    if options.misomip_wall:
        print('Building walls in MISOMIP domain')
        bathy[0,:] = 0
        draft[0,:] = 0
        bathy[-1,:] = 0
        draft[-1,:] = 0

    if options.filling:
        print('Filling in isolated ocean bottom cells')
        do_filling(bathy, grid.dz, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr)

    if options.digging == 'none':
        print('Not doing digging as per user request')
    elif options.digging == 'bathy':
        print('Digging bathymetry which is too shallow')
        bathy = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr, dig_option='bathy', dig_full_cells=options.dig_full_cells)
    elif options.digging == 'draft':
        print('Digging ice shelf drafts which are too deep')
        draft = do_digging(bathy, draft, grid.dz, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr, dig_option='draft', dig_full_cells=options.dig_full_cells)

    print('Fixing ice shelf drafts which are too thin')
    draft = do_zapping(draft, draft!=0, grid.dz, grid.z_edges, hFacMinDr=options.hFacMinDr, only_grow=True)[0]

    # Figure out largest changes in ice shelf draft, not counting grounding/ungrounding
    draft_old = read_binary(mit_dir+options.draftFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)
    ddraft = np.ma.masked_where(draft==0, np.ma.masked_where(draft_old==0, draft-draft_old))
    if np.amin(ddraft) < 0:
        print('Greatest thinning of ice shelf draft is ' + str(np.abs(np.amin(ddraft))) + ' m')
    if np.amax(ddraft) > 0:
        print('Greatest thickening of ice shelf draft is ' + str(np.amax(ddraft)) + ' m')
    print(str(np.count_nonzero((grid.ice_mask)*(bathy==0))) + ' cells grounded')
    print(str(np.count_nonzero((grid.land_mask)*(bathy!=0))) + ' cells ungrounded')

    # Make a copy of the original bathymetry and ice shelf draft
    make_tmp_copy(mit_dir+options.draftFile)
    make_tmp_copy(mit_dir+options.bathyFile)
    
    # Write to file
    write_binary(draft, mit_dir+options.draftFile, prec=options.readBinaryPrec)
    write_binary(bathy, mit_dir+options.bathyFile, prec=options.readBinaryPrec)


# Read MITgcm's state variables from the end of the last segment (from the final dump files if restart_type='zero', and from the last pickup if restart_type='pickup'), and adjust them to create initial conditions for the next segment.
# Any cells which have opened up since the last segment (due to Ua's simulated ice shelf draft changes + MITgcm's adjustments eg digging) will have temperature and salinity set to the average of their nearest neighbours, and velocity to zero.
# If options.adjust_vel=True, u and v will be adjusted to preserve the barotropic transport.
# Sea ice (if active) will also set to zero area, thickness, snow depth, and velocity in the event of a retreat of the ice shelf front.
# Also set the new pressure load anomaly.

def adjust_mit_state (grid, options):

    mit_dir = options.mit_run_dir

    # Read the final state from the last segment (dump or pickup)
    if options.restart_type == 'zero':
        print('Reading last dump files')

        # Inner function to read the final dump of a given variable
        def read_last_dump (var_name):
            return read_mit_output('last', mit_dir, var_name, None, timestep=options.last_timestep)

        # Read the final ocean state variables
        temp = read_last_dump('T')
        salt = read_last_dump('S')
        u = read_last_dump('U')
        v = read_last_dump('V')
        eta = read_last_dump('Eta')
        if options.use_seaice:
            # Read the final sea ice state variables
            aice = read_last_dump('AREA')
            hice = read_last_dump('HEFF')
            hsnow = read_last_dump('HSNOW')
            uice = read_last_dump('UICE')
            vice = read_last_dump('VICE')

    elif options.restart_type == 'pickup':
        print('Reading last pickup file')

        var_names = ['Theta', 'Salt', 'EtaN', 'EtaH', 'Uvel', 'Vvel', 'GuNm1', 'GvNm1', 'dEtaHdt']
        if options.eosType != 'LINEAR':
            # Also need PhiHyd
            var_names += ['PhiHyd']
        if options.use_addmass:
            var_names += ['AddMass']
        fields = read_mit_output('last', mit_dir, 'pickup', var_names, timestep=options.last_timestep, nz=grid.nz)
        [temp, salt, etan, etah, u, v, gunm1, gvnm1, detahdt] = fields[:9]
        if options.eosType != 'LINEAR':
            phihyd = fields[9]
        if options.use_addmass:
            addmass = fields[-1]

        if options.use_seaice:
            # Read the sea ice pickup too
            var_names_seaice = ['siTICES', 'siAREA', 'siHEFF', 'siHSNOW', 'siUICE', 'siVICE']
            if options.seaice_sigma:
                var_names_seaice += ['siSigm1', 'siSigm2', 'siSigm12']
            fields_seaice = read_mit_output('last', mit_dir, 'pickup_seaice', var_names_seaice, timestep=options.last_timestep, nz=options.seaice_nz)
            temp_ice, aice, hice, hsnow, uice, vice = fields_seaice[:6]
            if options.seaice_sigma:
                sigm1_ice, sigm2_ice, sigm12_ice = fields_seaice[6:]

        if options.use_ptracers:
            # This assumes there is only one tracer: read_mit_output will throw an error if there's more.
            var_names_ptracers = ['pTr01']
            fields_ptracers = read_mit_output('last', mit_dir, 'pickup_ptracers', var_names_ptracers, timestep=options.last_timestep, nz=grid.nz)
            tracer = fields_ptracers

    print('Selecting newly opened cells')
    # Read the new ice shelf draft, and also the bathymetry
    draft = read_binary(mit_dir+options.draftFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)
    bathy = read_binary(mit_dir+options.bathyFile, [grid.nx, grid.ny], 'xy', prec=options.readBinaryPrec)
    # Calculate the new hFacC, hFacW, and hFacS
    hFacC_new = calc_hfac(bathy, draft, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr)
    hFacW_new = calc_hfac(bathy, draft, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr, gtype='u')
    hFacS_new = calc_hfac(bathy, draft, grid.z_edges, hFacMin=options.hFacMin, hFacMinDr=options.hFacMinDr, gtype='v')
    # Also get the new 3D masks
    mask_new = (hFacC_new!=0).astype(int)
    mask_new_2d = (np.sum(mask_new, axis=0)!=0).astype(int)
    mask_new_u = (hFacW_new!=0).astype(int)
    mask_new_v = (hFacS_new!=0).astype(int)
    # Find all the (t-grid) cells which are newly open
    newly_open = (hFacC_new!=0)*(grid.hfac==0)

    # Inner function to extrapolate a t-grid field into its newly opened cells, and mask the closed cells with zeros. Can be 3D (default) or 2D (i.e. surface).
    def extrapolate_into_new (var_string, data, is_2d=False):
        print('Extrapolating ' + var_string + ' into newly opened cells')
        use_3d = not is_2d
        if use_3d:
            discard = grid.hfac==0
            fill = newly_open
            mask = mask_new
        else:
            discard = np.sum(grid.hfac, axis=0)==0
            fill = (np.sum(hFacC_new, axis=0)!=0)*discard
            mask = mask_new_2d
        data_filled = discard_and_fill(data, discard, fill, use_3d=use_3d, preference='vertical', missing_val=-9999)*mask
        if np.count_nonzero(data_filled==-9999) != 0:
            print('Error (extrapolate_into_new): something went wrong with the masking.')
            sys.exit()
        return data_filled

    # Extrapolate T and S into newly opened cells
    temp = extrapolate_into_new('temperature', temp)
    salt = extrapolate_into_new('salinity', salt)
    if options.restart_type == 'pickup':
        # Extrapolate a few more variables
        if options.eosType != 'LINEAR':
            phihyd = extrapolate_into_new('total hydrostatic potential', phihyd)
        etan = extrapolate_into_new('free surface (N)', etan, is_2d=True)
        etah = extrapolate_into_new('free surface (H)', etah, is_2d=True)
    else:
        # Free surface is just one variable
        eta = extrapolate_into_new('free surface', eta, is_2d=True)
    if options.use_ptracers:
        tracer = extrapolate_into_new('custom tracer', tracer)
    # Any remaining variables (velocity etc) want newly opened cells to be set to zero. This is done implicitly as the mask was already zero.

    # Inner function to adjust velocity (u or v) to preserve barotropic transport after coupling. Pass correct dh and hfac depending on the direction: for u pass dy_w and hFacW, for v pass dx_s and hFacS.
    def adjust_vel (vel, dh, hfac_old, hfac_new):
        # Make things 3D
        dh = xy_to_xyz(dh, grid)
        dz = z_to_xyz(grid.dz, grid)
        # Calculate transport before and after
        transport_old = np.sum(vel*dh*dz*hfac_old, axis=0)
        transport_new = np.sum(vel*dh*dz*hfac_new, axis=0)
        # Calculate correction; careful in land mask
        u_star = np.zeros(transport_old.shape)
        denom = np.sum(dh*dz*hfac_new, axis=0)
        index = denom!=0
        u_star[index] = (transport_old[index]-transport_new[index])/denom[index]
        # Apply the correction everywhere
        vel += xy_to_xyz(u_star, grid)
        # Now apply the mask
        vel[hfac_new==0] = 0
        return vel

    if options.adjust_vel:
        print('Adjusting velocities to preserve barotropic transport')
        u = adjust_vel(u, grid.dy_w, grid.hfac_w, hFacW_new)
        v = adjust_vel(v, grid.dx_s, grid.hfac_s, hFacS_new)

    # Apply the new masks to any remaining variables, to make sure that any newly closed cells are masked.
    u *= mask_new_u
    v *= mask_new_v
    if options.use_seaice:
        aice *= mask_new[0,:]
        hice *= mask_new[0,:]
        hsnow *= mask_new[0,:]
        uice *= mask_new_u[0,:]
        vice *= mask_new_v[0,:]
    if options.restart_type == 'pickup':
        gunm1 *= mask_new_u
        gvnm1 *= mask_new_v
        detahdt *= mask_new_2d
        if options.use_seaice:
            temp_ice *= xy_to_xyz(mask_new[0,:], [grid.nx, grid.ny, options.seaice_nz])
            if options.seaice_sigma:
                sigm1_ice *= mask_new[0,:]
                sigm2_ice *= mask_new[0,:]
                sigm12_ice *= mask_new[0,:]

    # Write the new state
    if options.restart_type == 'zero':
        
        # Make backup copies of old initial conditions files before we overwrite them
        files_to_copy = [options.ini_temp_file, options.ini_salt_file, options.ini_u_file, options.ini_v_file, options.ini_eta_file]
        if options.use_seaice:
            files_to_copy += [options.ini_area_file, options.ini_heff_file, options.ini_hsnow_file, options.ini_uice_file, options.ini_vice_file]
        for fname in files_to_copy:
            make_tmp_copy(mit_dir+fname)

        # Write the new initial conditions
        fields = [temp, salt, u, v, eta]
        files = [options.ini_temp_file, options.ini_salt_file, options.ini_u_file, options.ini_v_file, options.ini_eta_file]
        if options.use_seaice:
            fields += [aice, hice, hsnow, uice, vice]
            files += [options.ini_area_file, options.ini_heff_file, options.ini_hsnow_file, options.ini_uice_file, options.ini_vice_file]
        for i in range(len(fields)):
            write_binary(fields[i], mit_dir+files[i], prec=options.readBinaryPrec)
            
    elif options.restart_type == 'pickup':

        # Update pointers
        fields = [temp, salt, etan, etah, u, v, gunm1, gvnm1, detahdt]
        if options.eosType != 'LINEAR':
            fields.append(phihyd)
        if options.use_addmass:
            fields.append(addmass)
        if options.use_seaice:
            fields_seaice = [temp_ice, aice, hice, hsnow, uice, vice]
            if options.seaice_sigma:
                fields_seaice += [sigm1_ice, sigm2_ice, sigm12_ice]
        if options.use_ptracers:
            fields_ptracers = [tracer]

        # Overwrite pickup file
        overwrite_pickup(mit_dir, 'pickup', options.last_timestep, fields, var_names, grid.nz)
        if options.use_seaice:
            overwrite_pickup(mit_dir, 'pickup_seaice', options.last_timestep, fields_seaice, var_names_seaice, options.seaice_nz)
        if options.use_ptracers:
            overwrite_pickup(mit_dir, 'pickup_ptracers', options.last_timestep, fields_ptracers, var_names_ptracers, grid.nz)

    print('Calculating pressure load anomaly')
    make_tmp_copy(mit_dir+options.pload_file)
    calc_load_anomaly(grid, mit_dir+options.pload_file, option=options.pload_option, ini_temp=temp, ini_salt=salt, constant_t=options.pload_temp, constant_s=options.pload_salt, eosType=options.eosType, rhoConst=options.rhoConst, tAlpha=options.tAlpha, sBeta=options.sBeta, Tref=options.Tref, Sref=options.Sref, hfac=hFacC_new, prec=options.readBinaryPrec)


# Convert all the MITgcm binary output files in run/ to NetCDF, using the xmitgcm package.
def convert_mit_output (options):

    # Wrap import statement inside this function, so that xmitgcm isn't required to be installed unless needed
    from xmitgcm import open_mdsdataset

    # Get startDate in the right format for NetCDF
    if options.restart_type == 'zero':
        # Beginning of the segment
        ref_date = options.last_start_date[:4]+'-'+options.last_start_date[4:6]+'-01 0:0:0'
    elif options.restart_type == 'pickup':
        # Beginning of the entire simulation
        ref_date = options.startDate[:4]+'-'+options.startDate[4:6]+'-01 0:0:0'

    # Make a temporary directory to save already-processed files
    tmp_dir = options.mit_run_dir + 'tmp_mds/'
    if not os.path.exists(tmp_dir):
        os.mkdir(tmp_dir)

    # Move all the pickups to that directory, otherwise they mess up xmitgcm
    for fname in os.listdir(options.mit_run_dir):
        if fname.startswith('pickup') and (fname.endswith('.data') or fname.endswith('.meta')):
            move_to_dir(fname, options.mit_run_dir, tmp_dir)

    # Choose calendar type to send to xmitgcm
    if options.calendar_type == '360-day':
        calendar = '360_day'
    else:
        calendar = options.calendar_type

    # Inner function to read MDS files and convert to NetCDF.
    # If dump=True, only read dump files, and only from the given timestep.
    # Then move the original files to a temporary directory so they're hidden
    # at the end.
    # If dump=False, read whatever files are left.
    def convert_files (nc_name, dump=True, tstep=None):
        if dump:
            if tstep is None:
                print('Error (convert_files): must define tstep')
                sys.exit()
            iters = [int(tstep)]
            prefixes = find_dump_prefixes(options.mit_run_dir, tstep)
        else:
            iters = 'all'
            prefixes = None
        # Only convert dumps if the user wants them saved
        if (not dump) or options.save_dumps:
            # Read all the files matching the criteria
            ds = open_mdsdataset(options.mit_run_dir, iters=iters, prefix=prefixes, delta_t=options.deltaT, ref_date=ref_date, ignore_unknown_vars=True, calendar=calendar)
            # Save to NetCDF file
            ds.to_netcdf(options.mit_run_dir+nc_name, unlimited_dims=['time'])
        if dump:
            # Move to temporary directory
            move_processed_files(options.mit_run_dir, tmp_dir, prefixes, tstep)

    # Process first dump
    convert_files(options.dump_start_nc_name, tstep=options.first_timestep)
    # Process last dump
    convert_files(options.dump_end_nc_name, tstep=options.last_timestep)
    # Process diagnostics, i.e. everything that's left
    convert_files(options.mit_nc_name, dump=False)

    # Move everything back out of the temporary directory
    for fname in os.listdir(tmp_dir):
        move_to_dir(fname, tmp_dir, options.mit_run_dir)
    # Make sure we can safely delete it
    if len(os.listdir(tmp_dir)) != 0:
        print('Error (convert_mit_output): '+tmp_dir+' is not empty')
        sys.exit()
    os.rmdir(tmp_dir)


# Gather all output from MITgcm and Ua, moving it to a common subdirectory of options.output_dir.
def gather_output (options):

    # Make a subdirectory named after the starting date of the simulation segment
    new_dir = options.output_dir + options.last_start_date + '/'
    print('Creating ' + new_dir)
    os.mkdir(new_dir)

    # Make a subdirectory for MITgcm
    new_mit_dir = new_dir + 'MITgcm/'
    os.mkdir(new_mit_dir)

    # Inner function to check a file exists, and if so, move it to the new MITgcm output folder. This is just called for xmitgcm output files.
    def check_and_move (directory, fname):
        if not os.path.isfile(directory+fname):
            print('Error gathering output')
            print(directory+fname + ' does not exist')
            sys.exit()
        move_to_dir(fname, directory, new_mit_dir)

    if options.use_xmitgcm:
        # Move the NetCDF files created by convert_mit_output into the new folder
        if options.save_dumps:
            check_and_move(options.mit_run_dir, options.dump_start_nc_name)
            check_and_move(options.mit_run_dir, options.dump_end_nc_name)
        check_and_move(options.mit_run_dir, options.mit_nc_name)
            
    # Deal with MITgcm binary output files
    for fname in os.listdir(options.mit_run_dir):
        if fname.endswith('.data') or fname.endswith('.meta'):
            if fname.startswith('pickup'):
                # Save pickup files
                if options.restart_type == 'pickup' and str(options.last_timestep) in fname:
                    # The run directory still needs these files, so copy them
                    copy_to_dir(fname, options.mit_run_dir, new_mit_dir)
                elif options.save_tmp_ckpt:
                    # Move them
                    move_to_dir(fname, options.mit_run_dir, new_mit_dir)
                else:
                    # Delete them, otherwise they stick around in run/ forever and take up space
                    os.remove(options.mit_run_dir+fname)
            else:
                if options.use_xmitgcm:
                    # Delete binary files which were savely converted to NetCDF
                    os.remove(options.mit_run_dir+fname)
                else:
                    # Move binary files to output directory
                    move_to_dir(fname, options.mit_run_dir, new_mit_dir)

    # Inner function to copy topography/ICs/pload files which are modified every coupling timestep, and for which temporary copies are made prior to modification.
    def copy_tmp_file (fname, source_dir, target_dir, check_tmp=False):
        # First check if it was modified this timestep
        if os.path.isfile(source_dir+fname+'.tmp'):
            # Move the temporary copies
            os.rename(source_dir+fname+'.tmp', target_dir+fname)
        elif check_tmp:
            # There should have been a temporary copy
            print('Error (copy_tmp_file): a temporary copy of ' + fname + ' does not exist')
            sys.exit()
        else:
            # They were not modified, so copy them
            copy_to_dir(fname, source_dir, target_dir)

    # List of such files to copy from MITgcm run directory
    mit_file_names = [options.draftFile, options.bathyFile, options.pload_file, 'data', 'data.diagnostics', 'STDOUT.0000', 'STDERR.0000']
    if options.restart_type == 'zero':
        mit_file_names += [options.ini_temp_file, options.ini_salt_file, options.ini_u_file, options.ini_v_file, options.ini_eta_file]
        if options.use_seaice:
            mit_file_names += [options.ini_area_file, options.ini_heff_file, options.ini_hsnow_file, options.ini_uice_file, options.ini_vice_file]
    # Now copy them
    for fname in mit_file_names:
        copy_tmp_file(fname, options.mit_run_dir, new_mit_dir)
    # Also the calendar file
    copy_tmp_file(options.calendar_file, options.output_dir, new_dir)
    if os.path.isfile(options.output_dir+options.eta_file):
        # Also the eta log file
        copy_tmp_file(options.eta_file, options.output_dir, new_dir)
    
    if not options.spinup:
        # Deal with Ua
        # Find name of restart file
        restart_name = None
        for fname in os.listdir(options.ua_exe_dir):
            if fname.endswith('RestartFile.mat'):
                restart_name = fname
        if restart_name is None and (options.ua_ini_restart or not options.first_coupled):
            print('Error (gather_output): there is no Ua restart file.')
            sys.exit()
        if options.first_coupled:
            # There is no actual Ua output yet.
            # The only thing to do is make a temporary copy of the restart file, if it exists.
            if options.ua_ini_restart:
                make_tmp_copy(options.ua_exe_dir+restart_name)
        else:
            # Make a subdirectory for Ua
            new_ua_dir = new_dir + 'Ua/'
            os.mkdir(new_ua_dir)
            # Move Ua output into this folder
            for fname in os.listdir(options.ua_output_dir):
                move_to_dir(fname, options.ua_output_dir, new_ua_dir)
            # Move the stdout and stderr files too
            move_to_dir('matlab_std.out', options.ua_exe_dir, new_ua_dir)
            move_to_dir('matlab_err.out', options.ua_exe_dir, new_ua_dir)
            # Save the temporary copy made last time (restart at the beginning of this segment)
            copy_tmp_file(restart_name, options.ua_exe_dir, new_ua_dir, check_tmp=options.ua_ini_restart)
            # Make a new temporary copy of the restart at the end of this segment (beginning of the next segment)
            make_tmp_copy(options.ua_exe_dir+restart_name)
            # Also copy melt file from MITgcm
            copy_tmp_file(options.ua_melt_file, options.output_dir, new_ua_dir, check_tmp=True)
            # Make sure the draft file exists
            if not os.path.isfile(new_ua_dir+options.ua_draft_file):
                print('Error gathering output')
                print('Ua did not create the draft file '+ua_draft_file)
                sys.exit()                        


# Move output from a previous repeat into a subdirectory so it doesn't get overwritten.
def move_repeated_output(options):

    # Make the next available subdirectory
    n = 1
    while True:
        new_dir = options.output_dir + 'repeat_' + str(n).zfill(2) + '/'
        if not os.path.isdir(new_dir):
            print('Moving output to ' + new_dir)
            os.mkdir(new_dir)
            break
        n += 1

    # Move all the date-stamped subdirectories into it
    for fname in os.listdir(options.output_dir):
        # Check if it's a directory with name length 6
        if os.path.isdir(options.output_dir+fname) and len(fname) == 6:
            # Check if it's all numbers
            try:
                int(fname)
            except(ValueError):
                continue
            shutil.move(options.output_dir+fname, new_dir)    


# Edit the OBCS normal velocity files (for next and all following years,
# if they're transient) to prevent massive drift in the sea surface height.
# This correction will be performed every correct_obcs_steps coupling steps,
# based on the mean sea surface height over the last correct_obcs_steps steps,
# and will relax this toward zero.
# Only called if options.correct_obcs_online = True.
def correct_next_obcs (grid, options):

    # Read sea surface height from last coupling step, time-averaged
    directory = options.output_dir + options.last_start_date + '/MITgcm/'
    if options.use_xmitgcm:
        eta = read_netcdf(directory+options.mit_nc_name, 'ETAN', time_average=True)
    else:
        eta = read_mit_output('avg', directory, options.etan_name, 'ETAN')
    # Mask out the land and ice shelves, and area-average
    eta = mask_land_ice(eta, grid)
    eta_avg = area_average(eta, grid)
    d_t = options.correct_obcs_steps

    if options.correct_obcs_steps != 1:
        # Average back over more than one coupling step
        # Need to use the log file
        logfile = options.output_dir + options.eta_file
        if os.path.isfile(logfile):
            # It already exists - make a backup file
            make_tmp_copy(logfile)
        f = open(logfile, 'a')
        f.write(str(eta_avg)+'\n')
        f.close()

        # Check if it's time to do a correction
        # Read the calendar file to get the start date of the next simulation
        calfile = options.output_dir + options.calendar_file
        f = open(calfile, 'r')
        date_code = f.readline().strip()
        f.close()
        new_year = int(date_code[:4])
        new_month = int(date_code[4:])
        # Calculate number of months since the beginning of the simulation
        ini_year = int(options.startDate[:4])
        ini_month = int(options.startDate[4:6])        
        num_months = months_between(ini_year, ini_month, new_year, new_month)
        # See if it's a multiple of correct_obcs_steps
        if num_months >= options.correct_obcs_steps and num_months % options.correct_obcs_steps == 0:
            print('OBCS correction will be applied: '+str(num_months)+' months since simulation start')
        else:
            print('Not time for OBCS correction yet')
            # Exit the function
            return        
        # Now read all the values in the file
        eta_all = np.loadtxt(logfile)
        # Average over the last given number of steps
        eta_avg = np.mean(eta_all[-options.correct_obcs_steps:])

    if options.obcs_transient:
        # Figure out the next year to process
        f = open(options.output_dir+options.calendar_file, 'r')
        date_code = f.readline().strip()
        f.close()
        year = int(date_code[:4])
        multi_year = True
    else:
        # Make a copy of the master file, so that we don't entrain corrections from previous years.
        for fname in [options.obcs_file_w_u, options.obcs_file_e_u, options.obcs_file_s_v, options.obcs_file_n_v]:
            if fname is not None:
                file_path = options.mit_run_dir + fname
                print('Making copy of ' + file_path + '.master')
                shutil.copy(file_path+'.master', file_path)
        multi_year = False
        year = None
    if np.abs(eta_avg) > options.obcs_threshold:
        # Apply the correction
        balance_obcs(grid, option='correct', in_dir=options.mit_run_dir, obcs_file_w_u=options.obcs_file_w_u, obcs_file_e_u=options.obcs_file_e_u, obcs_file_s_v=options.obcs_file_s_v, obcs_file_n_v=options.obcs_file_n_v, d_eta=eta_avg, d_t=d_t, multi_year=multi_year, start_year=year, end_year=year)
    else:
        print('OBCS correction not triggered as SSH anomaly below threshold of ' + str(options.obcs_threshold) + ' m')


# Copy the geometry files from a mirrored simulation.
def mirror_geometry (options):

    if options.finished:
        # Special case
        if len(options.mirror_path_final) > 0:
            source_dir = options.mirror_path_final + '/MITgcm/'
        else:
            source_dir = None
    else:         
        # Get the start date of the next segment by reading the calendar file
        f = open(options.output_dir + options.calendar_file, 'r')
        date_code = f.readline().strip()
        f.close()
        source_dir = options.mirror_path+date_code+'/MITgcm/'

    if source_dir is not None:
        if not os.path.isdir(source_dir):
            print('Error (mirror_geometry): ' + source_dir + ' does not exist')
            sys.exit()
        print('Copying geometry files from ' + source_dir)

        # Copy the geometry files to the run directory
        for fname in [options.bathyFile, options.draftFile]:
            copy_to_dir(fname, source_dir, options.mit_run_dir)


# For simulations which will be rsynced to another server, set up the initial directory structure before the simulation starts.
def ini_rsync (options):

    # Create the case directory on the remote host
    subprocess.check_call(['ssh -t '+options.rsync_host+' "mkdir -p '+options.rsync_path+options.expt_name+'"'], shell=True)
    subprocess.check_call(['ssh -t '+options.rsync_host+' "mkdir -p '+options.rsync_path+options.expt_name+'/mitgcm_run"'], shell=True)
    # Get working directory
    pwd = os.getcwd()
    # Copy all the initial files we want
    # If this fails, it will terminate the entire process so no need for error checking.
    subprocess.check_call(['rsync -razL '+pwd+'/*.py '+pwd+'/*.sh '+pwd+'/output '+options.ua_exe_dir[:-1]+' '+options.rsync_host+':'+options.rsync_path+options.expt_name+'/'], shell=True)
    subprocess.check_call(['rsync -razL '+options.mit_case_dir+'code '+options.mit_case_dir+'input '+options.mit_case_dir+'scripts '+options.rsync_host+':'+options.rsync_path+options.expt_name+'/mitgcm_run/'], shell=True)


# rsync the output from this simulation segment, then delete it from the computation server.
def rsync_segment (options):

    new_dir = options.output_dir + options.last_start_date  # No trailing slash
    count = 0
    while True:
        try:
            subprocess.check_call(['rsync', '-razL', new_dir, options.rsync_host+':'+options.rsync_path+options.expt_name+'/output/'])
        except(subprocess.CalledProcessError):
            if count > 5:
                print('rsync keeps dropping. Bailing')
                sys.exit()
            print('rsync dropped, trying again')
            count += 1
            continue
        print('rsync success')
        break
    # If it survived this far, it's safe to delete the directory
    shutil.rmtree(new_dir)
