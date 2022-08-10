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
AMUND_IN=$WORK/AMUND_files/
ln -s $AMUND_IN/* .
LENS_ATM=/work/n02/n02/shared/baspog/CESM/LENS
ln -s $LENS_ATM/* .
LENS_OBCS=/work/n02/n02/shared/baspog/CESM/LENS_obcs
ln -s $LENS_OBCS/* .
../scripts/dummy_link.sh LENS 1890 1919 1920 1949
../scripts/dummy_link.sh LENS 1889 1889 1890 1890
../scripts/dummy_link.sh LENS 2101 2101 2100 2100


# Deep copy of some files that will be modified
rm -f draft_AMUND bathy_AMUND pload_AMUND
cp $AMUND_IN/draft_AMUND $AMUND_IN/bathy_AMUND $AMUND_IN/pload_AMUND .

OBCS_CORR=( UVEL_E UVEL_W VVEL_N )
for VAR in "${OBCS_CORR[@]}"; do
    rm -f LENS_ens001_${VAR}_*
    cp $LENS_OBCS/LENS_ens001_${VAR}_* .
    # Now redo the work of dummy_link.sh as deep copies
    for YEAR in {1920..1949}; do
	cp LENS_ens001_${VAR}_$YEAR LENS_ens001_${VAR}_$((YEAR-30))
    done
    cp LENS_ens001_${VAR}_1890 LENS_ens001_${VAR}_1889
    cp LENS_ens001_${VAR}_2100 LENS_ens001_${VAR}_2101
    for f in LENS_ens001_${VAR}_*; do
	cp $f $f.master
    done
done    

# Link executable
ln -s ../build/mitgcmuv .

cd $ORIG_DIR
