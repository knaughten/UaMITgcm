#!/bin/bash
#SBATCH --partition=serial
#SBATCH --qos=serial
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --time=1:00:00
#SBATCH --mem=32gb
###############################################################
# Run coupling script to exchange data between MITgcm and Ua.
###############################################################

# USER VARIABLES
# Path to UaMITgcm repository
REPO_DIR=$WORK/UaMITgcm
# Path to MITgcm source code: default is to use the version inside UaMITgcm
MIT_SOURCE=$REPO_DIR/MITgcm_67g

echo 'Coupler starts '`date` >> jobs.log

# Get various python files/packages in the path
# coupling scripts
COUPLEPY=$REPO_DIR/coupling
# mitgcm_python
MITPY=$REPO_DIR/tools
# MITgcmutils
MITU=$MIT_SOURCE/utils/python/MITgcmutils
export PYTHONPATH=$PWD:$COUPLEPY:$MITPY:$MITU:$PYTHONPATH

echo $'\n''*****'`date`'*****' >> coupler_stdout

python $COUPLEPY/master.py >> coupler_stdout 2>&1
OUT=$?

if [ $OUT == 0 ]; then
    echo 'Coupler ends '`date` >> jobs.log
    exit 0
else
    echo 'Error in coupler '`date` >> jobs.log
    exit 1
fi
