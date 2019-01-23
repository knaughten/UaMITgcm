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

# Get various python packages in the path
# Assumes this script was submitted from its own directory
# mitgcm_python
MITPY=$PBS_O_WORKDIR/../tools/
# xmitgcm
XMIT=$PBS_O_WORKDIR/../tools/xmitgcm/
# MITgcmutils
MITU=$PBS_O_WORKDIR/../MITgcm/utils/python/MITgcmutils/
export PYTHONPATH=$PYTHONPATH:$MITPY:$XMIT:$MITU
python master.py &> coupler_stdout

