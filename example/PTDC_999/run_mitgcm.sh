#!/bin/bash
#SBATCH --time=00:05:00
#SBATCH --nodes=2
#SBATCH --tasks-per-node=100
#SBATCH --cpus-per-task=1
#SBATCH --partition=standard
#SBATCH --qos=standard
####################################################################
# Run MITgcm.
# Must pass the arguments
# --export=ALL,MIT_DIR=<path to MITgcm case directory>,ACC=<Archer budget>
# and
# -A <Archer budget>
####################################################################

## for debugging purposes, it might be faster to use the short queue, in which case
## SBATCH --qos=short
## SBATCH --reservation=shortqos

# Setup the job environment (this module needs to be loaded before any other modules)
module load epcc-job-env

cd $SLURM_SUBMIT_DIR
echo 'MITgcm starts '`date` >> jobs.log

cd $MIT_DIR

export TMPDIR=/work/n02/n02/`whoami`/SCRATCH
export OMP_NUM_THREADS=1

# Launch the parallel job
# Using 200 MPI processes and 100 MPI processes per node
# This is somewhat wasteful, but the setup was inhereted from 32 core ARCHER1 nodes
# The runtime scales approx linearly with number of nodes. 2 Nodes is prob optimal here
srun --distribution=block:block --hint=nomultithread ./mitgcmuv
OUT=$?

cd $SLURM_SUBMIT_DIR
if [ $OUT == 0 ]; then
    echo 'MITgcm ends '`date` >> jobs.log
    touch mitgcm_finished
    #if [ -e ua_finished ]; then
        # MITgcm was the last one to finish
        #sbatch -A $ACC run_coupler.sh
    #fi
    exit 0
else
    echo 'Error in MITgcm '`date` >> jobs.log
    exit 1
fi
