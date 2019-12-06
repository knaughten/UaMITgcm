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

# Deep copy of some files that will be modified
rm -f draft_WSFRIS bathy_WSFRIS pload_piControl_WSFRIS
cp -f $WSFRIS_IN/draft_WSFRIS $WSFRIS_IN/bathy_WSFRIS $WSFRIS_IN/pload_piControl_WSFRIS .

# Link copies of OBCS for the first and last years of simulation, so there is something to interpolate on either side.
for string in *OBCS*2880;
do
  substring=${string%????}
  cp -P $substring"$((2880))" $substring"$((2879))"
done
for string in *OBCS*3059;
do
  substring=${string%????}
  cp -P $substring"$((3059))" $substring"$((3060))"
done

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR
