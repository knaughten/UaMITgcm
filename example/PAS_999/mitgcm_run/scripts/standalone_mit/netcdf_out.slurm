#!/bin/bash
#
#SBATCH --partition=serial
#SBATCH --qos=serial
#SBATCH --nodes=1 
#SBATCH --mem=4G 
#SBATCH --tasks-per-node=1
#SBATCH --time=0:30:00
#SBATCH --job-name=PAS_nc
#SBATCH --output=PAS_nc.%j

# note without the 4G (or som eother value) the sbatch of the PAS model fails!

# #PBS -N PAS_nc
# #PBS -l select=serial=true:ncpus=1

# #PBS -l walltime=00:30:00 
# #PBS -e ../run
# #PBS -o ../run
# #PBS -j oe
# #PBS -m n
# #PBS -r n
#########################################################
# Convert from binary output to NetCDF using xmitgcm.
# Only use if MNC option is off.
# The results will go in a directory <case>/output with the name output_001.nc (if that directory is empty), output_002.nc (if output_001.nc exists), etc.
# Then copy the results to BAS server.
#########################################################

echo "received from SLURM" JOBCHUNK=$JOBCHUNK, JOBNO=$JOBNO, PCHKPTFREQ=$PCHKPTFREQ, TIMEQSTART=$TIMEQSTART
echo "runnning in " $PWD

#*******  dirctory of nc_out needs looking at.... have a run/status directory?
#*******  dirctory of output and nc_out needs looking at.... have a case/run/status, case/run/output directory??
#*******  we are tentatively running in run not scripts

. ../scripts/case_setup  # same setup as the build and the model
			# maybe over-kill if all we need is the path to python with xmitgcm
module use /work/n02/shared/mjmn02/sw/modules
module load conda_xmit_1 # to get python with xmitgcm

# Timestep in seconds
DELTA_T=800
# Starting date of simulation
REF_DATE='1979-1-1 0:0:0'
# Directory to save things in
OUT_DIR="output"

#cd $PBS_O_WORKDIR
# Might have been submitted from ../run
##cd ../scripts

# Call xmitgcm
echo about to run:  python ../scripts/convert_netcdf.py $DELTA_T $REF_DATE
echo in $PWD
NCOUT=../run/nc_out

echo running python ../scripts/convert_netcdf.py $DELTA_T $REF_DATE
python ../scripts/convert_netcdf.py $DELTA_T $REF_DATE
OUT=$?

# Make sure that worked
if ([ ! -e ../run/output.nc ] || [ $OUT != 0 ]); then
  echo 'Problem with NetCDF conversion' >> $NCOUT
  exit 1
fi
rm ../run/state*.data ../run/state*.meta

# Check if the output directory exists
if [ -d ../$OUT_DIR ]; then
  # Check if there are any output files in the directory
  if ls ../$OUT_DIR/output_*.nc 1> /dev/null 2>&1; then
    # Some output files exist; figure out the next available filename
    LAST=`exec ls ../$OUT_DIR/output*.nc | sed 's/[^0-9]*//g' | sort -n | tail -1`
    NEWFILE=`printf "../$OUT_DIR/output_%03d.nc" $(( 1 + 10#$LAST ))`
    # Make sure we're not about to overwrite anything - this shouldn't happen but you can't be too careful
    if [ -e $NEWFILE ]; then
      echo 'About to overwrite something!' $NEWFILE >> $NCOUT
      exit 1
    fi
  else
    # No output files; create the first one
    NEWFILE=output_001.nc
  fi
else
  # Create the directory
  mkdir ../$OUT_DIR
  NEWFILE=output_001.nc
fi
mv ../run/output.nc ../$OUT_DIR/$NEWFILE

##cd ..
#CASE=`basename $PWD`
#HOMEDIR=$HOMEROOT/$CASE/
#ssh -t $HOMEHOST "mkdir -p $HOMEDIR/output"
#rsync -razl code input scripts $HOMEHOST:$HOMEDIR
#rsync -razl $OUT_DIR/$NEWFILE $HOMEHOST:$HOMEDIR/$OUT_DIR/
#OUT=$?
#if [ $OUT == 0 ]; then
#  echo 'rsync finished normally'
#  echo 'replacing '$NEWFILE' with placeholder'
#  rm $OUT_DIR/$NEWFILE
#  touch $OUT_DIR/$NEWFILE
#else
#  echo 'Problem with rsync'
#  exit 1
#fi

# Submit the next job, if needed
if ([ ! -e ./finished ] && [ ! -e ./died ]); then

  TIMEQSTART="$(date +%s)"

  if [[ "$HECACC"x != "x" ]]
  then
        ACCFLAG="-A $HECACC"
  else
        ACCFLAG=""
  fi
# submit the job chain
  sbatch -J PAS_$JOBNO  \
     $ACCFLAG \
     --export JOBCHUNK=$JOBCHUNK,JOBNO=$JOBNO,PCHKPTFREQ=$PCHKPTFREQ,TIMEQSTART=$TIMEQSTART \
     ../scripts/run_repeat.slurm

 # qsub -N PAS_$JOBNO \
       #-A $HECACC \
       #-v JOBCHUNK=$JOBCHUNK,JOBNO=$JOBNO,PCHKPTFREQ=$PCHKPTFREQ,TIMEQSTART=$TIMEQSTART \
       #run_repeat.sh

 else # maybe if ./finished exists
	 cd ../output
	 for i in *.nc
	 do
		 python ../scripts/check_theta.py $i
	 done
fi


