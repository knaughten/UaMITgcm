Welcome to the &#218;a-MITgcm repository. This code has been developed and is maintained by Kaitlin Naughten (British Antarctic Survey, kaight@bas.ac.uk) and Jan De Rydt (Northumbria University, jan.rydt@northumbria.ac.uk). It provides a coupled framework between the ice flow model &#218;a (https://github.com/ghilmarg) and the general circulation model MITgcm (http://mitgcm.org/). Some basic documentation and example setups can be found in their respective directories on the repository, and a quick installation guide follows below. Please let us know if you intend to use the code, or feel free to get in touch to discuss new ideas. 

![Ua-MITgcm-logo](./documentation/UaMITgcm_logo.png "UaMITgcm")


## Installation

Since this repository contains submodules, use `git clone --recursive` instead of just `git clone`.

Also note that `git pull` will not pull any changes to submodules. If you need to do this, run `git submodule update --remote path_to_submodule`.

## System requirements

You will require the python packages numpy and scipy. These are pre-installed on most systems. On the NERC-UK supercomputer ARCHER2, `module load cray-python` will give you access to them.

If you are using xmitgcm to convert your MITgcm output from binary to NetCDF, you will also need the python package xarray. This is not pre-installed on ARCHER2 but you can do a local install with `pip install --user xarray`.
Make sure to specify the correct installation paths, as explained [here](https://docs.archer2.ac.uk/user-guide/python/). Install xmitgcm and MITgcmutils using `pip install --user xmitgcm` and `pip install --user MITgcmutils`.
