#!/bin/bash --login
################################################################################
# Run the model for as long as we can, then prepare for a restart and submit the next job.
################################################################################

#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --nodes=2 
#SBATCH --tasks-per-node=120
#SBATCH --time=02:00:00
#SBATCH --no-requeue

# following are commented out and owuld be used in place of some of the above
# for short test runs.

# SBATCH --time=00:20:00
# SBATCH --partition=standard
# SBATCH --qos=short

# ------end of comemnted out lines for short jobs-----------

# ------------for reference, following were in the PBS script---------
# #PBS -l select=8 8*24=192
# # PBS -l walltime=1:00:00
# #PBS -e ../run
# #PBS -o ../run
# #PBS -j oe
# #PBS -m n

# #PBS -r n
# ----------------end comment on PBS --------------------



# function to return numbwer of seconds left in this job
# the squeue command returns either hh:mm:ss or mm:ss
# so handle both cases.
# We should add in 1-00:00:00 for a day

function hmsleft()
{
	local lhms
	lhms=$(squeue  -j $SLURM_JOB_ID -O TimeLeft | tail -1)
	echo $lhms
}
function secsleft() {
    if [[ ${#hms} < 6 ]]
    then
        echo secs=$(echo $hms|awk -F: '{print ($1 * 60) + $2 }')
    else
        echo secs=$(echo $hms|awk -F: '{print ($1 * 3600) + ($2 * 60) + $3 }')
    fi
}



. ../scripts/case_setup
# hardwire budget if you wish to over-ride default - see netcdf job submission
  if [[ "$HECACC"x != "x" ]]
then
        ACCFLAG="-A $HECACC"
else
        ACCFLAG=""
fi

echo "received from SLURM" JOBCHUNK=$JOBCHUNK, JOBNO=$JOBNO, PCHKPTFREQ=$PCHKPTFREQ, TIMEQSTART=$TIMEQSTART

# run this in run directory? cd $PBS_O_WORKDIR/../run

export TMPDIR=/work/n02/n02/`whoami`/PAS_SCRATCH
export OMP_NUM_THREADS=1

# start timer
timeqend="$(date +%s)"
elapsedqueue="$(expr $timeqend - $TIMEQSTART)"
timestart="$(date +%s)"
echo >> times
echo Queue-time seconds $elapsedqueue >> times
echo Run start `date` >> times
hms=$(hmsleft)
echo Walltime left is $hms>>walltime
rem_secs=$(secsleft)  # function above
echo Walltime left in seconds is $rem_secs >> walltime
# Subtract 3 minutes
RUNTIME="$(($rem_secs-180))"
echo Will run for $RUNTIME sec >> walltime

#                            Run the job but leave 3 minutes at the end

timeout $RUNTIME  srun --distribution=block:block --hint=nomultithread ./mitgcmuv

#archer1 had
#aprun -n 192 -N 24 ./mitgcmuv # srun takes nnodes etc from the SBATCH options.

# Get the exit code
OUT=$?
echo 'job chain: leave_time activated, exit code' $OUT

# end timer
timeend="$(date +%s)"
elapsedtotal="$(expr $timeend - $timestart)"
echo >> times
echo Run end `date` >> times
echo Run-time seconds $elapsedtotal >> times


#  Gather data

module list
ftn --version

# Set the number of threads to 1

#   This prevents any threaded system libraries from automatically
#   using threading.

export OMP_NUM_THREADS=1

# confirm the build is whats expected
echo Example of copmilation flags used:
ftnex=$(grep -m 2 -i exf_check.f ../build/make.trace | tail -1)
echo "          build included" $ftnex
echo "          expect"  $MITGCM_FFLAGS

stdo=STDOUT.0000
x=$(stat --format=%z $stdo)

tracesummary1="| ${x:0:16} | $SLURM_JOB_ID | $SLURM_JOB_NAME | $SLURM_JOB_NUM_NODES | $SLURM_JOB_QOS | $SLURM_JOB_CPUS_PER_NODE | $SLURM_TASKS_PER_NODE "
        traces2=" |  $MITGCM_FFLAGS $MITGCM_GENM_FLAGS | $elapsedtotal |"
tracesummary=${tracesummary1}${traces2}

echo $tracesummary 
echo $tracesummary > traceSummary.txt

# check need for  job chaining.

if ([ $OUT == 0 ] && [ $JOBCHUNK != 1 ]); then

  # Simulation completed and it was not chunk 1 of 2
- a version of opt files had an error (text not test of MITGCM_FFLAG)
  # Move final stdout/stderr from the master node
  mv STDERR.0000 stderr_9999999999
  mv STDOUT.0000 stdout_9999999999

  # Convert output to NetCDF
  touch ../run/finished
  sbatch  $ACCFLAG ../scripts/netcdf_out.slurm

elif [ $OUT == 124 ] || ([ $OUT == 0 ] && [ $JOBCHUNK == 1 ]); then

  # Simulation ran out of time or chunk 1 of 2 has completed
  # Prepare for a restart

  # Find the most recent pickup file
  unset -v PICKUP_FILE
  if ! ls pickup.*.data 1> /dev/null 2>&1 ; then
    echo 'job chain: fail, no pickup files'
    exit 1
  fi
  for file in pickup.*.data; do
    [[ $file -nt $PICKUP_FILE ]] && PICKUP_FILE=$file
  done
  # Extract the middle bit of this filename
  PICKUP=${PICKUP_FILE#pickup.}
  PICKUP=${PICKUP%.data}

  re='^[0-9]+$'
  if [[ $PICKUP =~ $re ]]; then

    echo 'job chain: pickup from permanent checkpoint'

    # Save the timestep, with any leading zeros removed
    NITER0=$(echo $PICKUP | sed 's/^0*//')
    # Make sure pickupSuff will be commented out in namelist
    PICKUP_LINE="# pickupSuff = 'ckptA'"

  elif [[ $PICKUP == ckptA || $PICKUP == ckptB ]]; then

    echo 'job chain: pickup from temporary checkpoint'

    # Read the timestep from the corresponding meta file
    PICKUP_META=pickup.$PICKUP.meta
    META_LINE=`sed -n '/timeStepNumber/p' $PICKUP_META`
    NITER0=$(echo $META_LINE | sed 's/[^0-9]*//g')
    # Make sure pickupSuff will be uncommented and correct
    PICKUP_LINE="\ pickupSuff = '$PICKUP',"

  else

    echo 'job chain: fail, problem with pickup' $PICKUP
    exit 1

  fi
  echo 'PICKUP_LINE: ' $PICKUP_LINE
  echo 'NITER0: ' $NITER0

  # Edit the "data" namelist
  # Update the line which sets niter0 and is uncommented
  NITER0_LINE="\ niter0 = $NITER0,"
  sed -i "/^ niter0/c $NITER0_LINE" data
  # Update the line containing pickupSuff, whether or not it's commented
  # assumes there's only one!
  sed -i "/pickupSuff/c $PICKUP_LINE" data

  # If it is the end of the first chunk, edit stuff for second chunk
  if ([ $OUT == 0 ] && [ $JOBCHUNK == 1 ]); then

    echo 'first chunk complete, editing for second chunk'

    # Set new deltaT
    # find the commented chunkTwo line and extract its number
    TEXTLINE=`sed -n '/deltaT_chunkTwo/p' data`
    DELTAT_TWO=$(echo $TEXTLINE | sed -r 's/[^0-9.]*//g')
    # build the new active line and replace it in file
    TEXTLINE="\ deltaT = $DELTAT_TWO,"
    sed -i "/^ deltaT[ =]/c $TEXTLINE" data

    # Set niter0 to be consistent with new deltaT
    # find chunk 1 endTime divided by chunk 2 deltaT
    TEXTLINE=`sed -n '/^ endTime[ =]/p' data`
    ENDTIME_ONE=$(echo $TEXTLINE | sed -r 's/[^0-9.]*//g')
    NITER0_TWO=`python -c "print int($ENDTIME_ONE/$DELTAT_TWO)"`
    # build the new active line and replace it in file
    TEXTLINE="\ niter0 = $NITER0_TWO,"
    sed -i "/^ niter0/c $TEXTLINE" data

    # Set new endTime
    # find the commented chunkTwo line and extract its number
    TEXTLINE=`sed -n '/endTime_chunkTwo/p' data`
    ENDTIME_TWO=$(echo $TEXTLINE | sed -r 's/[^0-9.]*//g')
    # build the new active line and replace it in file
    TEXTLINE="\ endTime = $ENDTIME_TWO,"
    sed -i "/^ endTime/c $TEXTLINE" data

    # set pChkptFreq to what the user chose originally
    # (this was set to zero in chunk 1)
    TEXTLINE="\ pChkptFreq = $PCHKPTFREQ,"
    sed -i "/^ pChkptFreq/c $TEXTLINE" data

    # set the chunking flag to indicate we are no longer in the first chunk
    JOBCHUNK=0

  fi

  # Move stdout/stderr from the master node so they don't get overwritten
  NITER0FORMAT=`printf "%010i" $NITER0` 
  mv STDERR.0000 stderr_$NITER0FORMAT
  mv STDOUT.0000 stdout_$NITER0FORMAT

  # Convert output to NetCDF
  # This job will then submit the next simulation
  echo sbatch $ACCFLAG --export=JOBCHUNK=$JOBCHUNK,JOBNO=$JOBNO,PCHKPTFREQ=$PCHKPTFREQ ../scripts/netcdf_out.slurm
  sbatch $ACCFLAG --export=JOBCHUNK=$JOBCHUNK,JOBNO=$JOBNO,PCHKPTFREQ=$PCHKPTFREQ ../scripts/netcdf_out.slurm

else

  echo 'job chain: fail, simulation died, exit code' $OUT
  touch ../run/died

  echo sbatch  $ACCFLAG ../scripts/netcdf_out.slurm
  sbatch  $ACCFLAG ../scripts/netcdf_out.slurm

fi

