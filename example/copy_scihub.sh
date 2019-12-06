#!/bin/bash --login
#
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=10:00:00 
#PBS -j oe
#PBS -m n
#PBS -r n
##################################################################
# Copy output to Scihub. Must pass -v SOURCE_DIR=<case directory>
##################################################################

cd $PBS_O_WORKDIR
# Remove any trailing slash
SOURCE_DIR=${SOURCE_DIR%/}
echo 'Copying' $SOURCE_DIR 'to scihub'

# Submit the next job to start if this one finishes with non-0 exit status, indicating the copying didn't finish in time
qsub -A $HECACC -v SOURCE_DIR=$SOURCE_DIR -W depend=afternotok:$PBS_JOBID copy_scihub.sh

while [ 1 ]
do
    rsync -razl $SOURCE_DIR $HOMEHOST:$HOMEROOT/
    OUT=$?
    if [ $OUT == 0 ]; then
        echo "rsync finished normally"
	du -sh $SOURCE_DIR
	ssh $HOMEHOST 'du -sh '$HOMEROOT'/'$SOURCE_DIR
	echo 'Copied' $SOURCE_DIR
	exit
    else
        echo "rsync connection dropped, trying again..."
	sleep 60
    fi
done