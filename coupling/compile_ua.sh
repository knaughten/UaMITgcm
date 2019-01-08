#!/bin/bash

# Path to correct version of Matlab
# For running executable on Archer, need 2017a
matlab_path=$HOME/matlab_2017a

# Path to Ua build directory
ua_build=$HOME/UaBuild

# TODO: put a specific branch of UaSource within the UaMITgcm repository
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

# Collapse all subdirectories from UaSource and updates folders into a single directory
cp `find $ua_source/ -name "*"` ua_build
cp `find $ua_updates/ -name "*"` ua_build

# Create the executable
$matlab_path/bin/mcc -m $ua_build/startUa2D.m -o Ua -d $ua_build
# Copy just the executable (not the associated run script) to the current directory
# TODO: copy to special Ua executable directory which also has necessary data files etc.
cp $ua_build/Ua .
    
    
 

