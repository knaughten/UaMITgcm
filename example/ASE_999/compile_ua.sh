#!/bin/bash

# USER VARIABLES
# Path to correct version of MATLAB
# Setup below has been tested on ARCHER2 for MATLAB v2021a 
MATLAB_PATH=/usr/share/modules/apps/MATLAB/R2021a
# Path to UaMITgcm repository
REPO_DIR=/home/UNN/wchm8/Documents/UaMITgcm_v2/UaMITgcm_archer2
# Path to Ua build directory (will be created if it doesn't exist)
UA_BUILD=./UaBuild
# Path to configuration-specific Ua files to overwrite
UA_CASE_UPDATES=$PWD/ua_custom
# Path to Ua source directory (default use the one inside UaMITgcm)
UA_SOURCE=$REPO_DIR/UaSource_beta_25Mar2020
# Path to coupling-specific Ua files to overwrite
UA_COUPLING_UPDATES=$REPO_DIR/coupling/ua_development

if [ -e $UA_BUILD ]; then
    # Empty the directory
    rm -rf $UA_BUILD/*
else
    # Create the directory
    mkdir $UA_BUILD
fi

# Copy all Matlab files from UaSource
cp $UA_SOURCE/*.m $UA_BUILD
# Need to collapse a couple of subdirectories for more Matlab files
cp `find $UA_SOURCE/UaUtilities/ -name "*.m"` $UA_BUILD
cp `find $UA_SOURCE/NewestVertexBisection/ -name "*.m"` $UA_BUILD
# Copy mesh2d files
cp `find $UA_SOURCE/Mesh2d/ -name "*.m"` $UA_BUILD
# Also copy everything from updates folders
cp -r $UA_COUPLING_UPDATES/* $UA_BUILD
cp -r $UA_CASE_UPDATES/* $UA_BUILD

# Create the executable
$MATLAB_PATH/bin/mcc -m $UA_BUILD/callUa.m -o Ua -d $UA_BUILD
# Copy just the executable (not the auto-generated run script as we have a custom one) to the current directory
cp $UA_BUILD/Ua ./ua_run
echo 'Now copy "Ua" to the Ua executable directory on the server where you will run the model.'
rm -rf $UA_BUILD
