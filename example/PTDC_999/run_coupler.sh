#!/bin/sh
#SBATCH --time=00:20:00
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --reservation=shortqos

###############################################################
# Run coupling script to exchange data between MITgcm and Ua.
# Must pass the arguments
# --export=ALL -A <Archer budget>
###############################################################

module load epcc-job-env
module load cray-python

# USER VARIABLES
# Path to UaMITgcm repository
REPO_DIR=$WORK/UaMITgcm/UaMITgcm_archer2
# Path to MITgcm source code: default is to use the version inside UaMITgcm
MIT_SOURCE=$REPO_DIR/MITgcm_67k

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

