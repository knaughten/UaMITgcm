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
SHARED=/work/n02/n02/shared/baspog/MITgcm
WSS_IN=$SHARED/WS/WSS
ln -s $WSS_IN/* .
ln -s $WORK/ERA5/mit/* .
#ln -s $SHARED/reanalysis/ERAI_075/* .

# Deep copy of some files that will be modified
rm -f draft_WSS bathy_WSS pload_WSS
cp -f $WSS_IN/draft_WSS $WSS_IN/bathy_WSS $WSS_IN/pload_WSS .

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR
