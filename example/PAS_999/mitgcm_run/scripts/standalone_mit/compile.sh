#!/bin/bash
################################################
# Compile MITgcm.
################################################

# Empty the build and output directory 

if [ -d "../build" ]; then
  rm -rf ../build/*
else
	mkdir -p ../build
fi
if [ -d "../output" ]; then
  rm -rf ../output/*
else
	mkdir -p ../output
fi
if [ -d "../trace" ]; then
  rm -rf ../trace/*
else
	mkdir -p ../trace
fi

.  ./case_setup
cp case_setup ../trace

##if [ ! -d "../code" ]; then
 ##ln -s /work/n02/shared/MITgcm/mjm/dev/CODES/PAS_053 ../code
 ##fi
mkdir -p ../code
rsync -vt /work/n02/shared/mjmn02/MITgcm/dev/CODES/PAS_053/* ../code/
cp ../code/SIZE.h_240cores ../code/SIZE.h

 cd ../build
# Generate a Makefile
export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

echo genmake
$MITGCM_ROOTDIR/tools/genmake2 ${MITGCM_GENM_FLAGS} -mods=../code -of=${MITGCM_OPT} -mpi >genmake.trace 2>&1 

# Run the Makefile
make depend > dep.trace 2>&1
echo make
make > make.trace 2>&1

ls -ltr | tail -5

