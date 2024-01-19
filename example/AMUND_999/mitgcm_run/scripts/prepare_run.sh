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
AMUND_IN=/work/n02/n02/shared/baspog/AMUND_files/
ln -s $AMUND_IN/* .
ln -s /work/n02/n02/shared/baspog/ERA5/* .
../scripts/dummy_link.sh ERA5 1947 1978 1979 2010
../scripts/dummy_link.sh ERA5 2022 2022 2021 2021

# Deep copy of some files that will be modified
rm -f draft_AMUND bathy_AMUND pload_AMUND
cp $AMUND_IN/draft_AMUND $AMUND_IN/bathy_AMUND $AMUND_IN/pload_AMUND .
OBCS_CORR=( UVEL_BSOSE.OBCS_E UVEL_BSOSE.OBCS_W VVEL_BSOSE.OBCS_N )
for VAR in "${OBCS_CORR[@]}"; do
    rm -f ${VAR}
    cp $AMUND_IN/${VAR} ${VAR}.master
done    

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR
