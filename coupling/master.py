from set_parameters import Options, advance_calendar
from mitgcm_python.grid import Grid
from process_data import extract_melt_rates, adjust_mit_geom, set_mit_ics, convert_mit_output, gather_output

print 'Reading parameters'
options = Options()

# TODO: figure out if it's initial run, ocean spinup, normal case (assume for now), or end of simulation
# Everything following might change then.

print 'Advancing calendar'
advance_calendar(options.output_dir, options.mit_run_dir, options)

print 'Building MITgcm grid'
grid = Grid(options.mit_run_dir)

print 'Sending melt rates from MITgcm to Ua'
extract_melt_rates(options.mit_run_dir, options.output_dir+options.ua_melt_file, grid, options)

print 'Adjusting MITgcm topography'
adjust_mit_geom(options.output_dir+options.ua_draft_file, options.mit_run_dir, grid, options)

print 'Setting new initial conditions for MITgcm'
set_mit_ics(options.mit_run_dir, grid, options)

if options.use_xmitgcm:
    print 'Converting MITgcm binary output to NetCDF'
    convert_mit_output(options)

print 'Gathering output'
gather_output(options)


# TODO: Submit next MITgcm job
# TODO: Submit next Ua job
# TODO: Submit itself with afterok
