#!/bin/bash



################################################
# Clean out old results and link input files.
################################################

# Empty the run directory - but first make sure it exists!
if [[ $(basename $PWD) != 'scripts' ]]
then
	echo run in scripts directory
	exit 1
fi

. ./case_setup

if [ -d "../run" ]; then
  echo empty run directory
  rm -rf ../run/*
else
  echo 'There is no run directory - make it'
  mkdir ../run
fi

cd ../run

if [ ${PE_ENV} == "CRAY" ]
then
MYINPUT=/work/n02/shared/mjmn02/PAS/PAS_archer1_ref/MITgcm_Amundsen_Sea/PAS_053/input/

elif [ ${PE_ENV} == "GNU" ]
then
MYINPUT=/work/n02/shared/mjmn02/PAS/PAS_053/input_gnu
else
   echo PE_ENV not revcognised $PE_ENV
   exit
fi

if [ -f $MYINPUT/data ]
then
rsync -rt $MYINPUT/* .
else
  echo not found file :data
  exit
fi

## Link everything from the input directory
##ln -s $MYINPUT/* . 

## Deep copy of the master namelist (so it doesn't get overwritten in input/)
##rm -f data
##cp -f $MYINPUT/data .

## Deep copy of any pickups (so they don't get overwritten in input/)
##rm -f pickup*
##cp -f $MYINPUT/pickup* . 2>/dev/null

# Link forcing files stored elsewhere
#SHARED=/work/n02/n02/shared/baspog/MITgcm
SHARED=/work/n02/shared/mjmn02/PAS/PAS_archer1_ref/basdata

echo 'linking ERA5'
#ln -s $SHARED/reanalysis/ERA5/* .
ln -s $SHARED/ERA5/* .
echo not calling ../scripts/dummy_link.sh ERA5 1979 1979 1979 1979
#../scripts/dummy_link.sh ERA5 1955 1978 1979 2002

#echo 'linking PACE'
#ln -s $SHARED/CESM/PACE/* .
#../scripts/dummy_link.sh PACE 1919 1919 1920 1920

# Initial and boundary conditions files, etc.
ln -s $SHARED/AS/PAS/* .

# Link executable
ln -s ../build/mitgcmuv .
