#!/bin/bash --login
#PBS -l select=1
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -m n
#PBS -r n
####################################################################
# Run MITgcm.
# Must pass the argument -v MIT_DIR=<path to MITgcm case directory>
# and -A <Archer budget>
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
else
    echo 'Error in MITgcm '`date` >> jobs.log
fi
