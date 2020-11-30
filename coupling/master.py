from set_parameters import Options, set_calendar
from mitgcm_python.grid import Grid
from process_data import zero_ini_files, copy_grid, extract_melt_rates, adjust_mit_geom, adjust_mit_state, convert_mit_output, gather_output, correct_next_obcs, move_repeated_output, mirror_geometry, ini_rsync
from coupling_utils import submit_job, reset_finished_files

# Top-level coupling function.
if __name__ == "__main__":            

    print 'Reading parameters'
    options = Options()

    print 'Checking calendar'
    set_calendar(options)

    # Delete finished files from last run
    reset_finished_files(options)

    if options.initial and options.restart_type=='zero':
        print 'Creating dummy initial conditions files where needed'
        zero_ini_files(options)

    if options.initial and options.rsync_output:
        print 'Initialising directory on host server for rsync'
        ini_rsync(options)

    # Do we need to do any processing for the next run?
    if not options.initial and not options.restart:

        print 'Building MITgcm grid'
        grid = Grid(options.mit_run_dir)

        # Do we need to do any coupling?
        # Do this when simulation is finished, just in case it is restarted exactly when coupling starts (eg options.repeat=True).
        if (not options.spinup) or options.finished:

            print 'Sending MITgcm grid to Ua'
            copy_grid(options.mit_run_dir, options.output_dir)

            print 'Sending melt rates from MITgcm to Ua'
            extract_melt_rates(options)

            # Do we need to change the ice shelf draft in MITgcm?
            if not options.first_coupled:

                print 'Adjusting MITgcm topography'
                adjust_mit_geom(grid, options)

        if options.mirror:
            # Copy geometry files from a mirrored simulation
            mirror_geometry(options)

        if options.restart_type=='zero' or (not options.spinup and not options.first_coupled) or options.mirror:
            if options.restart_type == 'zero':
                print 'Setting new initial conditions for MITgcm'
            elif options.restart_type=='pickup':
                print 'Adjusting MITgcm pickup file'
            adjust_mit_state(grid, options)

    # Is there any output we need to deal with?
    if not options.initial and not options.restart:

        if options.use_xmitgcm:
            print 'Converting MITgcm binary output to NetCDF'
            convert_mit_output(options)

        print 'Gathering output'
        gather_output(options)

        if options.correct_obcs_online:
            print 'Balancing OBCS based on last changes in sea surface height'
            correct_next_obcs(grid, options)

    if options.init_repeat:
        print 'Moving output from previous repeat'
        move_repeated_output(options)


    # Do we need to submit more jobs?
    if not options.finished:

        print 'Submitting next MITgcm segment'
        mit_id = submit_job(options, 'run_mitgcm.sh', input_var=['MIT_DIR='+options.mit_case_dir,'ACC='+options.budget_code])
        afterok = [mit_id]
        print 'Submitted with job ID ' + str(mit_id)

        # Do we also need to submit Ua job?
        if not options.spinup:
            print 'Submitting next Ua segment'
            if options.ua_option == 'compiled':
                ua_id = submit_job(options, 'run_ua.sh', input_var=['UA_DIR='+options.ua_exe_dir,'ACC='+options.budget_code])
            elif options.ua_option == 'matlab':
                # TODO
                pass
            afterok.append(ua_id)
            print 'Submitted with job ID ' + str(ua_id)

    print 'Coupling successfully completed'
