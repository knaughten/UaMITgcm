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

# USER VARIABLE
# Path to Matlab Compiler Runtime installation
MCR=$WORK/MCR_2017a/v92/

cd $PBS_O_WORKDIR
echo 'Ua starts '`date` >> jobs.log

module swap PrgEnv-intel PrgEnv-gnu
cp Ua_MCR.sh $UA_DIR
cd $UA_DIR

./Ua_MCR.sh $MCR 1>>matlab_std.out 2>>matlab_err.out

cd $PBS_O_WORKDIR
echo 'Ua ends '`date` >> jobs.log
