Welcome to the &#218;a-MITgcm repository. This code has been developed and is maintained by Kaitlin Naughten (British Antarctic Survey, kaight@bas.ac.uk) and Jan De Rydt (Northumbria University, jan.rydt@northumbria.ac.uk). It aims to provide a coupled framework between the ice flow model &#218;a (https://github.com/ghilmarg) and the general circulation model MITgcm (http://mitgcm.org/). Some basic documentation and example setups can be found in their respective repository directories, and a quick installation guide follows below. Please let us know if you intend to use the code for your project, or feel free to get in touch to discuss new ideas. If you already have a working setup of &#218;a and/or MITgcm, we are happy to assit with setting up and running the coupled configuration.

![Ua-MITgcm-logo](./logo/UaMITgcm.png "UaMITgcm")


## Installation

Since this repository contains submodules, use `git clone --recursive` instead of just `git clone`.

Also note that `git pull` will not pull any changes to submodules. If you need to do this, run `git submodule update --remote path_to_submodule`.

## System requirements

You will require the python packages numpy and scipy. These are pre-installed on most systems; on Archer, `module load anaconda` will give you access to them.

If you are using xmitgcm to convert your MITgcm output from binary to NetCDF, you will also need the python package xarray. This is not pre-installed on Archer but you can do a local install with `easy_install --user xarray`.
