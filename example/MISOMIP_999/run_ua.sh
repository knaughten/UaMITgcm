#!/bin/sh
  
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --time=1:00:00
# SBATCH --mem=64gb

###############################################################
# Run Ua.
# Must pass the arguments
# --export=ALL,UA_DIR=<path to Ua executable directory>,ACC=<Archer budget>
# and
# -A <Archer budget>
###############################################################

module load epcc-job-env

# USER VARIABLE
# Path to Matlab Compiler Runtime installation
MCR=$WORK/MCR_2022b/R2022b/

# Make sure MCR cache (as defined in Ua_MCR.sh) exists
# If you want the cache in a different location, modify it here AND in ua_run/Ua_MCR.sh
if [ ! -d $WORK/mcr_cache ]; then
  mkdir $WORK/mcr_cache
fi

echo 'Ua starts '`date` >> jobs.log

cd $UA_DIR
./Ua_MCR.sh $MCR 1>>matlab_std.out 2>>matlab_err.out
OUT=$?

cd ../
if [ $OUT == 0 ]; then
    echo 'Ua ends '`date` >> jobs.log
    touch ua_finished
    if [ -e mitgcm_finished ] ; then
        # Ua was the last one to finish
        sbatch -A $ACC run_coupler.sh
    fi
    exit 0
else
    echo 'Error in Ua '`date` >> jobs.log
    exit 1
fi
