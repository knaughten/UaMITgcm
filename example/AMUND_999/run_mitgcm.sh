#!/bin/bash
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --nodes=2
#SBATCH --tasks-per-node=120
#SBATCH --time=3:00:00
#SBATCH --no-requeue
####################################################################
# Run MITgcm.
# Must pass the argument
# --export=MIT_DIR=<path to MITgcm case directory>
####################################################################

echo 'MITgcm starts '`date` >> jobs.log

cd $MIT_DIR
cd run/
. ../scripts/case_setup

export OMP_NUM_THREADS=1

srun --distribution=block:block --hint=nomultithread ./mitgcmuv 1>>mitgcm_std.out 2>>mitgcm_err.out
OUT=$?

cd ../../
if [ $OUT == 0 ]; then
    echo 'MITgcm ends '`date` >> jobs.log
    touch mitgcm_finished
    if [ -e ua_finished ]; then
        # MITgcm was the last one to finish
	sbatch -A $ACC run_coupler.sh
    fi
    exit 0
else
    echo 'Error in MITgcm '`date` >> jobs.log
    exit 1
fi
