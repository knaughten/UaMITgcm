#!/bin/bash

# Path to correct version of Matlab
# For running executable on Archer, need 2017a
matlab_path=$HOME/matlab_2017a

# Path to Ua build directory
ua_build=$HOME/UaBuild

# Path to Ua source directory
ua_source=../UaSource
# Path to coupling-specific Ua files to overwrite
ua_coupling_updates=ua_development
# Path to configuration-specific Ua files to overwrite
ua_case_updates=../example/MISOMIP/MISOMIP_999_Ua

if [ -e $ua_build ]; then
    # Empty the directory
    rm -rf $ua_build/*
else
    # Create the directory
    mkdir $ua_build
fi

# Copy all Matlab files from UaSource
cp $ua_source/*.m $ua_build
# Need to collapse a couple of subdirectories for more Matlab files
cp `find $ua_source/UaUtilities/ -name "*.m"` $ua_build
cp `find $ua_source/NewestVertexBisection/ -name "*.m"` $ua_build
# Also copy everything from updates folders
cp -r $ua_coupling_updates/* $ua_build
cp -r $ua_case_updates/* $ua_build

# Create the executable
$matlab_path/bin/mcc -m $ua_build/callUa.m -o Ua -d $ua_build
# Copy just the executable (not the auto-generated run script as we have a custom one) to the current directory
cp $ua_build/Ua .
echo 'Now copy "Ua" to the Ua executable directory on the server where you will run the model.'
