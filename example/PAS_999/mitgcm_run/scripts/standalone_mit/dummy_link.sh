#! /bin/bash
# create dummy years of forcing by making links to real years of data
# (for spinning models up)
# assumes that source year data already exists in run directory
#
# to do: check targets exist, better checking that source and target year counts agree
#
# example: dummy_link.sh <reanalysis> <target_start> <target_end> <source_start> <source_end> 
# example: dummy_link.sh ERAI 1955 1978 1979 2002
#
# warning: you will need to consider leap years when choosing what to link

cd ../run

REANALYSIS=$1

TARGETSTART=$2
TARGETEND=$3
SOURCESTART=$4
SOURCEEND=$5

#
# ERA5 forcing
#

if [ $REANALYSIS = ERA5 ] 
  then

  TARGETYEAR=$TARGETSTART
  SOURCEYEAR=$SOURCESTART

  while [ $TARGETYEAR -le $TARGETEND ]
    do 

    ln -fs ERA5_lwdown_$SOURCEYEAR ERA5_lwdown_$TARGETYEAR
    ln -fs ERA5_swdown_$SOURCEYEAR ERA5_swdown_$TARGETYEAR
    ln -fs ERA5_apressure_$SOURCEYEAR ERA5_apressure_$TARGETYEAR
    ln -fs ERA5_precip_$SOURCEYEAR ERA5_precip_$TARGETYEAR
    ln -fs ERA5_aqh_$SOURCEYEAR ERA5_aqh_$TARGETYEAR
    ln -fs ERA5_atemp_$SOURCEYEAR ERA5_atemp_$TARGETYEAR
    ln -fs ERA5_uwind_$SOURCEYEAR ERA5_uwind_$TARGETYEAR
    ln -fs ERA5_vwind_$SOURCEYEAR ERA5_vwind_$TARGETYEAR

    TARGETYEAR=$((TARGETYEAR+1))
    SOURCEYEAR=$((SOURCEYEAR+1))

  done

  SOURCETEST=$((SOURCEYEAR-1))
  if [ $SOURCETEST -ne $SOURCEEND ]
    then
      echo "ERROR: links do not include source end"
  fi

fi

#
# ERAI forcing
#

if [ $REANALYSIS = ERAI ] 
  then

  TARGETYEAR=$TARGETSTART
  SOURCEYEAR=$SOURCESTART

  while [ $TARGETYEAR -le $TARGETEND ]
    do 

    ln -fs ERAinterim_dlw_$SOURCEYEAR ERAinterim_dlw_$TARGETYEAR
    ln -fs ERAinterim_dsw_$SOURCEYEAR ERAinterim_dsw_$TARGETYEAR
    ln -fs ERAinterim_msl_$SOURCEYEAR ERAinterim_msl_$TARGETYEAR
    ln -fs ERAinterim_rain_$SOURCEYEAR ERAinterim_rain_$TARGETYEAR
    ln -fs ERAinterim_spfh2m_$SOURCEYEAR ERAinterim_spfh2m_$TARGETYEAR
    ln -fs ERAinterim_tmp2m_degC_$SOURCEYEAR ERAinterim_tmp2m_degC_$TARGETYEAR
    ln -fs ERAinterim_u10m_$SOURCEYEAR ERAinterim_u10m_$TARGETYEAR
    ln -fs ERAinterim_v10m_$SOURCEYEAR ERAinterim_v10m_$TARGETYEAR

    TARGETYEAR=$((TARGETYEAR+1))
    SOURCEYEAR=$((SOURCEYEAR+1))

  done

  SOURCETEST=$((SOURCEYEAR-1))
  if [ $SOURCETEST -ne $SOURCEEND ]
    then
      echo "ERROR: links do not include source end"
  fi

fi

#
# PACE forcing
#

if [ $REANALYSIS = PACE ] 
  then

  TARGETYEAR=$TARGETSTART
  SOURCEYEAR=$SOURCESTART

  while [ $TARGETYEAR -le $TARGETEND ]
    do 

    for ENS in $(seq -f "%02g" 1 5)   # Update with all ensembles later
      do

      ln -fs PACE_ens${ENS}_FLDS_$SOURCEYEAR PACE_ens${ENS}_FLDS_$TARGETYEAR
      ln -fs PACE_ens${ENS}_FSDS_$SOURCEYEAR PACE_ens${ENS}_FSDS_$TARGETYEAR
      ln -fs PACE_ens${ENS}_PRECT_$SOURCEYEAR PACE_ens${ENS}_PRECT_$TARGETYEAR
      ln -fs PACE_ens${ENS}_PSL_$SOURCEYEAR PACE_ens${ENS}_PSL_$TARGETYEAR
      ln -fs PACE_ens${ENS}_QBOT_$SOURCEYEAR PACE_ens${ENS}_QBOT_$TARGETYEAR
      ln -fs PACE_ens${ENS}_TREFHT_$SOURCEYEAR PACE_ens${ENS}_TREFHT_$TARGETYEAR
      ln -fs PACE_ens${ENS}_UBOT_$SOURCEYEAR PACE_ens${ENS}_UBOT_$TARGETYEAR
      ln -fs PACE_ens${ENS}_VBOT_$SOURCEYEAR PACE_ens${ENS}_VBOT_$TARGETYEAR

    done

    TARGETYEAR=$((TARGETYEAR+1))
    SOURCEYEAR=$((SOURCEYEAR+1))

  done

  SOURCETEST=$((SOURCEYEAR-1))
  if [ $SOURCETEST -ne $SOURCEEND ]
    then
      echo "ERROR: links do not include source end"
  fi

fi


