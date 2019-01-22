from set_parameters import Options, set_calendar
from mitgcm_python.grid import Grid
from process_data import copy_grid, extract_melt_rates, adjust_mit_geom, set_mit_ics, convert_mit_output, gather_output
from coupling_utils import submit_job

import os


print 'Reading parameters'
options = Options()

print 'Checking calendar'
initial, spinup, first_coupled, finished = set_calendar(options.output_dir, options.mit_run_dir, options)


# Do we need to do any coupling?
if not initial and not spinup and not finished:
    
    print 'Building MITgcm grid'
    grid = Grid(options.mit_run_dir)

    print 'Sending MITgcm grid to Ua'
    copy_grid(options.mit_run_dir, options.output_dir)

    print 'Sending melt rates from MITgcm to Ua'
    extract_melt_rates(options.mit_run_dir, options.output_dir+options.ua_melt_file, grid, options)

    # Do we need to change the ice shelf draft in MITgcm?
    if not first_coupled:

        print 'Adjusting MITgcm topography'
        adjust_mit_geom(options.ua_output_dir+options.ua_draft_file, options.mit_run_dir, grid, options)

    print 'Setting new initial conditions for MITgcm'
    set_mit_ics(options.mit_run_dir, grid, options)

    
# Is there any output we need to deal with?
if not initial:
    
    if options.use_xmitgcm:
        print 'Converting MITgcm binary output to NetCDF'
        convert_mit_output(options)

    print 'Gathering output'
    gather_output(options, spinup)


# Do we need to submit more jobs?
if not finished:

    print 'Submitting next MITgcm segment'
    mit_id = submit_job('run_mitgcm.sh', input_var=['MIT_DIR='+options.mit_case_dir])
    afterok = [mit_id]

    # Do we also need to submit Ua job?
    if not spinup:
        print 'Submitting next Ua segment'
        if options.ua_option == 'compiled':
            ua_id = submit_job('run_ua.sh', input_var=['UA_DIR='+options.ua_exe_dir])
        elif options.ua_option == 'matlab':
            # TODO
            pass
        afterok.append(ua_id)

    print 'Submitting next coupler job to start after segment is finished'
    submit_job('run_coupler.sh', input_var=['MITUTILS='+options.mitgcmutils_dir, 'XMITGCM='+options.xmitgcm_dir], afterok=afterok)
    

print 'Coupling successfully completed'
