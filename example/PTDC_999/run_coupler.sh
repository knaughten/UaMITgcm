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
REPO_DIR=$WORK/UaMITgcm/UaMITgcm_git
# Path to MITgcm source code: default is to use the version inside UaMITgcm
MIT_SOURCE=$REPO_DIR/MITgcm_67g

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
# Note, also need PBS_O_WORKDIR in path so it sees config_options.py
export PYTHONPATH=$PBS_O_WORKDIR:$COUPLEPY:$MITPY:$XMIT:$MITU:$PYTHONPATH

echo $'\n''*****'`date`'*****' >> coupler_stdout

python $COUPLEPY/master.py >> coupler_stdout 2>&1
OUT=$?

if [ $OUT == 0 ]; then
    echo 'Coupler ends '`date` >> jobs.log
else
    echo 'Error in coupler '`date` >> jobs.log
fi

