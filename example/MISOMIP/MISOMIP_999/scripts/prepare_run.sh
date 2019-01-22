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

# Deep copy of the master namelist (so it doesn't get overwritten in input/)
rm -f data
cp -f ../input/data .
# Similarly for data.diagnostics
rm -f data.diagnostics
cp -f ../input/data.diagnostics .

# Link executable
ln -s ../build/mitgcmuv .
