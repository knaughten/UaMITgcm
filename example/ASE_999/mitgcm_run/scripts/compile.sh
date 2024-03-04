#!/bin/bash
################################################
# Compile MITgcm.
################################################

module restore PrgEnv-gnu

# USER VARIABLE
# Path to MITgcm source code: recommend to use the one inside UaMITgcm
MIT_SOURCE=$WORK/UaMITgcm/UaMITgcm_source/MITgcm_67g
MITGCM_ROOTDIR=$MIT_SOURCE

# Path to file containing Fortran flags etc
BUILD_OPTIONS=../linux_amd64_gfortran_archer2

# Empty the build directory - but first make sure it exists!
if [ -d "../build" ]; then
  cd ../build
  rm -rf *
else
  echo 'Creating build directory'
  mkdir ../build
  cd ../build
fi

# Generate a Makefile
$MIT_SOURCE/tools/genmake2 -mods=../code -of=$BUILD_OPTIONS -mpi -rootdir=$MIT_SOURCE

# Run the Makefile
make depend
make
