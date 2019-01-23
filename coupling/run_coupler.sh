#!/bin/bash --login
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=00:30:00
#PBS -j oe
#PBS -m n
#PBS -r n
###############################################################
# Run coupling script to exchange data between MITgcm and Ua.
###############################################################

cd $PBS_O_WORKDIR

# Get mitgcm_python in the path
# Assumes this script was submitted from its own directory
MITPY=$PBS_O_WORKDIR/../tools/
export PYTHONPATH=$PYTHONPATH:$MITPY
python master.py &> coupler_stdout

