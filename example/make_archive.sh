#!/bin/bash --login
#
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=10:00:00 
#PBS -j oe
#PBS -m n
#PBS -r n
##################################################################
# Create a zipped archive of the simulation.
# Must pass -v SOURCE_DIR=<case directory>
# and -A <Archer budget>.
##################################################################

cd $PBS_O_WORKDIR
# Remove any trailing slash
SOURCE_DIR=${SOURCE_DIR%/}
tar -czvf $SOURCE_DIR.tar.gz $SOURCE_DIR/