# Initialise Options
# Figure out if it's initial run, ocean spinup, or end of simulation
# Call advance_calendar
# Initialise Grid
# Call extract_melt_rates
# Call adjust_mitgcm_geom
# Call set_mit_ics
# Convert MITgcm output with xmitgcm
# Centrally gather all output from the models
# Submit next MITgcm job
# Submit next Ua job
# Submit itself with afterok
