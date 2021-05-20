#!/bin/bash
#PBS -l select=6
#PBS -l walltime=3:00:00
#PBS -q nexcs
####################################################################
# Run MITgcm.
# Must pass the argument
# -v MIT_DIR=<path to MITgcm case directory>
####################################################################

cd $PBS_O_WORKDIR
echo 'MITgcm starts '`date` >> jobs.log

cd $MIT_DIR
cd run/

export OMP_NUM_THREADS=1

aprun -n 192 -N 32 ./mitgcmuv 1>>mitgcm_std.out 2>>mitgcm_err.out
OUT=$?

cd $PBS_O_WORKDIR
if [ $OUT == 0 ]; then
    echo 'MITgcm ends '`date` >> jobs.log
    touch mitgcm_finished
    if [ -e ua_finished ]; then
        # MITgcm was the last one to finish
	qsub run_coupler.sh
    fi
    exit 0
else
    echo 'Error in MITgcm '`date` >> jobs.log
    exit 1
fi
