#!/bin/bash
################################################
# Compile MITgcm.
################################################

# Empty the build directory - but first make sure it exists!
if [ -d "../build" ]; then
  cd ../build
  rm -rf *
else
  echo 'There is no build directory'
  exit 1
fi

# Generate a Makefile
$ROOTDIR/tools/genmake2 -ieee -mods=../code -of=../../../build_options/linux_amd64_archer_ifort -mpi

# Run the Makefile
make depend
make
