#!/bin/bash
################################################
# Compile MITgcm.
################################################

# USER VARIABLE
# Path to MITgcm source code: recommend to use the one inside UaMITgcm
MIT_SOURCE=$WORK/UaMITgcm/MITgcm_67g
ROOTDIR=$MIT_SOURCE
# Path to file containing Fortran flags etc
BUILD_OPTIONS=../dev_linux_amd64_gfortran_archer2

# Empty the build and output directories
if [ -d "../build" ]; then
    rm -rf ../build/*
else
    mkdir -p ../build
fi
if [ -d "../output" ]; then
    rm -rf ../output/*
else
    mkdir -p ../output
fi

. ./case_setup
cd ../build

# Generate a Makefile
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
$MITGCM_ROOTDIR/tools/genmake2 ${MITGCM_GENM_FLAGS} -mods=../code -of=${MITGCM_OPT} -mpi >genmake.trace 2>&1

# Run the Makefile
make depend
make
