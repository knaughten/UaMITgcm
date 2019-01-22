#!/bin/bash

# Edit these paths as needed
MITUTILS=$WORK/mitgcm/MITgcm/utils/python/MITgcmutils
XMITGCM=$WORK/python/xmitgcm

qsub -A $HECACC -v MITUTILS=$MITUTILS,XMITGCM=$XMITGCM run_coupler.sh