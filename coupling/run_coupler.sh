#!/bin/bash --login
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=00:30:00
#PBS -j oe
#PBS -m n
#PBS -r n
###############################################################
# Run coupling script to exchange data between MITgcm and Ua.
# Pass the argument -v MITUTILS=<path to MITgcmutils package>,XMITGCM=<path to xmitgcm package>
###############################################################

export PYTHONPATH=$PYTHONPATH:$MITUTILS:$XMITGCM
python master.py &> coupler_stdout

