#!/bin/bash --login
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=3:00:00
#PBS -j oe
#PBS -m n
#PBS -r n

module swap PrgEnv-intel PrgEnv-gnu

# Path to Matlab Compiler Runtime installation
MCR=$WORK/MCR_2017a/v92/
# Name of output file
FNAME=ua_postprocessed.nc

cd $PBS_O_WORKDIR

# Read a few variables from config file
cd ..
EXPT=`python -c 'from config_options import *; print expt_name'`
OUTPUT=`python -c 'from config_options import *; print output_dir'`

# Call Matlab Compiler script
cd $PBS_O_WORKDIR
./UaPost_MCR.sh $MCR $EXPT $OUTPUT $OUTPUT/$FNAME 1>>matlab_std.out 2>>matlab_err.out
