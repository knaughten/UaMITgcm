#!/bin/bash --login
#PBS -l select=1
#PBS -l walltime=00:30:00
#PBS -j oe
#PBS -m n
#PBS -r n
####################################################################
# Run Ua.
# Must pass the argument -v UA_DIR=<path to Ua executable directory>
# and -A <Archer budget>
####################################################################

module swap PrgEnv-intel PrgEnv-gnu
cd $UA_DIR

./run_Ua.sh $WORK/MCR_2017a/v92/ 1>>matlab_std.out 2>>matlab_err.out
