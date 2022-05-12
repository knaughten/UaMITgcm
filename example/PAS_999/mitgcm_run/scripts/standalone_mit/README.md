
These files shoul dbe held int eh scritps directory for a case, so the subdirectories are:
- run
- build
- scripts
- code

## case_setup
case_setup was introduced to set the environment for the run

It includes the following that should be correctly set:
> export MITGCM_ROOTDIR=/path to installed/MITgcm (in which the tools directory resides)

> account 

> export HECACC=

> here can choose cray or gfortran opt files.

> export MITGCM_OPT=../scripts/dev_linux_amd64_cray_archer2

> export MITGCM_OPT=../scripts/dev_linux_amd64_gfortran_archer2


