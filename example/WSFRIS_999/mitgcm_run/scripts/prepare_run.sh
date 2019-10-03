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
WSFRIS_IN=$SHARED/WS/WSFRIS
ln -s $WSFRIS_IN/* .
ln -s $SHARED/UKESM/piControl/* .
# REPLACE THESE FILES once piControl tas data is available.
ln -s $WORK/dummy_tas/* .

# Deep copy of some files that will be modified
rm -f draft_WSFRIS bathy_WSFRIS pload_WSFRIS
cp -f $WSFRIS_IN/draft_WSFRIS $WSFRIS_IN/bathy_WSFRIS $WSFRIS_IN/pload_WSFRIS .
rm -f UVEL*.OBCS_E* VVEL*.OBCS_N*
cp -f $WSFRIS_IN/UVEL*.OBCS_E* $WSFRIS_IN/VVEL*.OBCS_N* .

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR