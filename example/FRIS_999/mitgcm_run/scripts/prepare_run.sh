#!/bin/bash
################################################
# Clean out old results and link input files.
################################################

# Save current directory
ORIG_DIR=$PWD

# Optional argument: path to scripts/ directory.
# Can be useful if this script was called from a different directory.
# If unset, assume we're already in it
SCRIPT_DIR=$1
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR=$ORIG_DIR
fi

cd $SCRIPT_DIR

# Empty the run directory - but first make sure it exists!
if [ -d "../run" ]; then
  cd ../run
  rm -rf *
else
  echo 'Creating run directory'
  mkdir ../run
  cd ../run
fi

# Copy everything from the input directory
cp ../input/* .

# Link input files stored elsewhere
ln -s /work/n02/n02/shared/baspog/MITgcm/WS/WSS/* .
ln -s /work/n02/n02/shared/baspog/MITgcm/reanalysis/ERAI_075/* .
# Remove problem humidity files and link in the new ones
rm ERAinterim_spfh2m_*
ln -s /work/n02/n02/shared/baspog/MITgcm/reanalysis/ERAI_075_humidity_fix_new/* .
# Link in dummy 2018 files so simulation doesn't crash right before the end
ln -s /work/n02/n02/kaight/ERAinterim_2018/* .

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR
