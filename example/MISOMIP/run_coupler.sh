#!/bin/bash --login
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=00:30:00
#PBS -j oe
#PBS -m n
#PBS -r n
###############################################################
# Run coupling script to exchange data between MITgcm and Ua.
###############################################################

# USER VARIABLES
# Path to UaMITgcm repository
REPO_DIR=$WORK/Ua_MITgcm_coupling/UaMITgcm
# Path to MITgcm source code: default is to use the version inside UaMITgcm
MIT_SOURCE=$REPO_DIR/MITgcm

cd $PBS_O_WORKDIR
echo 'Coupler starts '`date` >> jobs.log

# Get various python files/packages in the path
# coupling scripts
COUPLEPY=$REPO_DIR/coupling
# mitgcm_python
MITPY=$REPO_DIR/tools
# xmitgcm
XMIT=$REPO_DIR/tools/xmitgcm
# MITgcmutils
MITU=$MIT_SOURCE/utils/python/MITgcmutils
export PYTHONPATH=$COUPLEPY:$MITPY:$XMIT:$MITU:$PYTHONPATH

python $COUPLEPY/master.py &> coupler_stdout

echo 'Coupler ends '`date` >> jobs.log

