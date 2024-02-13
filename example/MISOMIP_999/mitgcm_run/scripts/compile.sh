#!/bin/bash
################################################
# Compile MITgcm.
################################################


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
