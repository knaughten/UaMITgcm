Welcome to the &#218;a-MITgcm 

![Ua-MITgcm-logo](./logo/UaMITgcm.png "UaMITgcm")

# UaMITgcm
Coupling scripts for Ua and MITgcm.

## Installation

Since this repository contains submodules, use `git clone --recursive` instead of just `git clone`.

Also note that `git pull` will not pull any changes to submodules. If you need to do this, run `git submodule update --remote path_to_submodule`.

## System requirements

You will require the python packages numpy and scipy. These are pre-installed on most systems; on Archer, `module load anaconda` will give you access to them.

If you are using xmitgcm to convert your MITgcm output from binary to NetCDF, you will also need the python package xarray. This is not pre-installed on Archer but you can do a local install with `easy_install --user xarray`.
