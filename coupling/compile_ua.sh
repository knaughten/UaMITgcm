#!/bin/bash

# Path to correct version of Matlab
# For running executable on Archer, need 2017a
matlab_path=$HOME/matlab_2017a

# Path to Ua build directory
ua_build=$HOME/UaBuild

ua_source=../UaSource
# TODO: separate this folder into MISOMIP-specific updates (put into examples/MISOMIP, put this at the top so the user can easily change the path) and coupling-general updates (keep where they are)
ua_updates=ua_development

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
# Also copy everything from updates folder
cp -r $ua_updates/* $ua_build

# Create the executable
$matlab_path/bin/mcc -m $ua_build/startUa2D.m -o Ua -d $ua_build
# Copy just the executable (not the associated run script) to the current directory
# TODO: copy to special Ua executable directory which also has necessary data files etc.
cp $ua_build/Ua .
