# UaMITgcm
Coupling scripts for Ua and MITgcm. Note the submodule mitgcm_python (https://github.com/knaughten/mitgcm_python).

*Jan: we will probably add UaSource later as another submodule, but let's wait and see what happens with Matlab Compiler first.*

Some functions use the python tools distributed with MITgcm. Make sure they are in your `PYTHONPATH`. At the bottom of your `~/.bashrc`, add:

```
export PYTHONPATH=$PYTHONPATH:$ROOTDIR/utils/python/MITgcmutils
```

where `$ROOTDIR` is the path to your copy of the MITgcm source code distribution (latest version here https://github.com/MITgcm/MITgcm). If you don't have/want the entire source code on your machine, you can also just copy the utils/python/MITgcmutils directory and point `PYTHONPATH` to that.

*Jan: should we instead make MITgcm a submodule of this repository? Should we just grab the MITgcmutils subdirectory instead of making the user get it themselves, or does this raise ownership issues?*

You will also need the python packages numpy and scipy.

