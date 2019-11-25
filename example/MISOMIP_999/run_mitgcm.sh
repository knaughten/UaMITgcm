#!/bin/bash --login
#PBS -l select=1
#PBS -l walltime=2:00:00
#PBS -j oe
#PBS -m n
#PBS -r n
####################################################################
# Run MITgcm.
# Must pass the arguments
# -v MIT_DIR=<path to MITgcm case directory>,ACC=<Archer budget>
# and
# -A <Archer budget>
####################################################################

cd $PBS_O_WORKDIR
echo 'MITgcm starts '`date` >> jobs.log

cd $MIT_DIR
cd run/

export TMPDIR=/work/n02/n02/`whoami`/SCRATCH
export OMP_NUM_THREADS=1

aprun -n 24 -N 24 ./mitgcmuv
OUT=$?

cd $PBS_O_WORKDIR
if [ $OUT == 0 ]; then
    echo 'MITgcm ends '`date` >> jobs.log
    touch mitgcm_finished
    if [ -e ua_finished ]; then
        # MITgcm was the last one to finish
	qsub -A $ACC run_coupler.sh
    fi
    exit 0
else
    echo 'Error in MITgcm '`date` >> jobs.log
    exit 1
fi
