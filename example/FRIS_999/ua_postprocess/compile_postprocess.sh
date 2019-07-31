#!/bin/bash

# USER VARIABLES
# Path to correct version of Matlab
# For running executable on Archer, need 2017a
MATLAB_PATH=$HOME/matlab_2017a
# Path to Ua source directory
UA_SOURCE=$HOME/UaMITgcm/UaSource_22Nov2018
# Path to build directory (will be created if it doesn't exist)
BUILD=$HOME/UaPostBuild

if [ -e $BUILD ]; then
    # Empty the directory
    rm -rf $BUILD/*
else
    # Create the directory
    mkdir $BUILD
fi

# Copy all files from UaSource
cp $UA_SOURCE/*.m $BUILD
# Collapse the utilities folder too
cp `find $UA_SOURCE/UaUtilities/ -name "*.m"` $BUILD
# Copy the postprocessing file
cp ua_postprocess.m $BUILD

# Create the executable
$MATLAB_PATH/bin/mcc -m $BUILD/ua_postprocess.m -o UaPost -d $BUILD
# Copy just the executable (not the auto-generated run script as we have a custom one) to the current directory
cp $BUILD/UaPost .
echo 'Now copy "UaPost" to this directory on the server with model output.'
