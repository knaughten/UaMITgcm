#!/bin/bash
################################################
# Clean out old results and link input files.
################################################

# Empty the run directory - but first make sure it exists!
if [ -d "../run" ]; then
  cd ../run
  rm -rf *
else
  echo 'Creating run directory'
  mkdir ../run
  cd ../run
fi

# Link everything from the input directory
ln -s ../input/* .

# Deep copy of files which will get updated during the simulation
# and which you don't want to get overwritten in input/
rm -f data
cp -f ../input/data .
rm -f data.diagnostics
cp -f ../input/data.diagnostics .
rm -f bathymetry.shice
cp -f ../input/bathymetry.shice .
rm -f shelfice_topo.bin
cp -f ../input/shelfice_topo.bin

# Link executable
ln -s ../build/mitgcmuv .
