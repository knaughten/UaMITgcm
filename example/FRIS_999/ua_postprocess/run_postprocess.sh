#!/bin/bash

# Path to Matlab Compiler Runtime installation
MCR=$WORK/MCR_2017a/v92/
# Name of output file
FNAME=ua_postprocessed.nc

# Save current directory
DIR=$PWD

# Read a few variables from config file
cd ..
EXPT=`python -c 'from config_options import *; print expt_name`
OUTPUT=`python -c 'from config_options import *; print output_dir`

# Call Matlab Compiler script
cd $DIR
./UaPost_MCR.sh $MCR $EXPT $OUTPUT $OUTPUT/$FNAME 1>>matlab_std.out 2>>matlab_err.out
