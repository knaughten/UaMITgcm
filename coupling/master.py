##### Just planning for now #####

# Workflow of master function/script:

# Initialise Options object
# Some kind of processing based on server workflow type. Figure out which directories things are in and whether there should be an rsync.
# Call advance_calendar
# Initialise Grid object
# Call extract_melt_rates
# Call adjust_mit_geom
# Call set_mit_ics
# Convert MITgcm output from last simulation segment to NetCDF (new option with xmitgcm, mit2nc, or none)
# For workflow with both models on same server (Ua either compiled or not):
#  Submit MITgcm job
#  Submit Ua job
#  Submit this coupling job again, with afterok: MITgcm and Ua jobs
# Work out how to submit the jobs when they're on different servers, and if there should be an rsync.

# Other things to sort out:

# Need to sort out some Ua compiling stuff:
#  Make the necessary edits more sensibly (talk to Jan or Hilmar about how best to do this)
#  Build script that collapses directories into one
#  Can the build script also call Matlab compile function?
#  Can the build script also rsync the executable if needed?
#  Idea is to use same options file on the compiling system. ua_compile.py in place of master.py.

# Need to decide if Ua will change simulation length with calendar or just approximate (and if so, do we trust user to set the final time correctly?)

# Still need to read Ua draft into adjust_mit_geom, once we know the format

# Special things to do on initial segment - haven't coded any of this yet:
#   calendar file doesn't exist yet, tell advance_calendar to create it using a new option with start date
#   360-day checking in update_namelists should throw warnings not errors
#   where does initial melt rate and geometry come from? supplied by user? different file names?
#   how do we know it's an initial segment? Keyword argument to master function?
