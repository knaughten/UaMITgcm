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
PAS_IN=$WORK/PAS_files/
ln -s $PAS_IN/* .
ln -s /work/n02/n02/shared/baspog/ERA5/* .
../scripts/dummy_link.sh ERA5 1947 1978 1979 2010
../scripts/dummy_link.sh ERA5 2020 2020 2019 2019

# Deep copy of some files that will be modified
rm -f OB*corr.bin
cp -r $PAS_IN/OB*corr.bin .
for f in OB*corr.bin; do
  cp $f $f.master
done

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR
