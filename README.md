# UaMITgcm
Coupling scripts for Ua and MITgcm.

## Installation

Since this repository contains the submodule mitgcm_python, use `git clone --recursive` instead of just `git clone`.

Also note that `git pull` will not pull any changes to submodules. To do this, run `git submodule update --remote`.

*Jan: we will probably add UaSource later as another submodule, but let's wait and see what happens with Matlab Compiler first. If Ua gets compiled on one machine and run on another, it might make more sense to have two repositories. What do you think?*

## System requirements

Some functions use the python tools distributed with MITgcm. Make sure they are in your `PYTHONPATH`. At the bottom of your `~/.bashrc`, add:

```
export PYTHONPATH=$PYTHONPATH:$ROOTDIR/utils/python/MITgcmutils
```

where `$ROOTDIR` is the path to your copy of the MITgcm source code distribution (latest version here https://github.com/MITgcm/MITgcm). If you don't have/want the entire source code on your machine, you can also just copy the utils/python/MITgcmutils directory and point `PYTHONPATH` to that.

*Jan: should we instead make MITgcm a submodule of this repository? Should we just grab the MITgcmutils subdirectory instead of making the user get it themselves, or does this raise ownership issues?*

You will also need the python packages numpy and scipy.

