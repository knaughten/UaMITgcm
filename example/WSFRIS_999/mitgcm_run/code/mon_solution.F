#include "MONITOR_OPTIONS.h"

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP
C     !ROUTINE: MON_SOLUTION

C     !INTERFACE:
      SUBROUTINE MON_SOLUTION(
     I     statsTemp,
     I     myTime, myIter, myThid )

C     !DESCRIPTION:
C     Checks that the solutions is within bounds

C     !USES:
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "GRID.h"
#include "MONITOR.h"
#ifdef ALLOW_SEAICE
# include "SEAICE_SIZE.h"
# include "SEAICE_PARAMS.h"
# include "SEAICE.h"
#endif
#include "FFIELDS.h"

C     !INPUT PARAMETERS:
      _RL statsTemp(*)
      _RL myTime
      INTEGER myIter
      INTEGER myThid
CEOP

C     !LOCAL VARIABLES:
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      CHARACTER*(MAX_LEN_MBUF) suff
      _RL tMin,tMax,tMean,tSD,tDel2,tVol

      IF ( statsTemp(1) .LE. statsTemp(2) ) THEN
C     Take statistics from the input argument "statsTemp":
        tMin = statsTemp(1)
        tMax = statsTemp(2)
      ELSE
C     Statistics for T
        CALL MON_CALC_STATS_RL(
     I                Nr, theta, hFacC, maskInC, rA, drF,
     O                tMin, tMax, tMean, tSD, tDel2, tVol,
     I                myThid )
      ENDIF

      IF ( (tMax-tMin).GT.monSolutionMaxRange ) THEN
        _BEGIN_MASTER(myThid)
        WRITE(msgBuf,'(A,1P2E11.3)')
     &    'SOLUTION IS HEADING OUT OF BOUNDS: tMin,tMax=',tMin,tMax
        CALL PRINT_MESSAGE(msgBuf,errorMessageUnit,SQUEEZE_RIGHT,myThid)
        WRITE(msgBuf,'(2A,1PE11.3,A)') '  exceeds allowed range ',
     &             '(monSolutionMaxRange=', monSolutionMaxRange,')'
        CALL PRINT_MESSAGE(msgBuf,errorMessageUnit,SQUEEZE_RIGHT,myThid)
        WRITE(msgBuf,'(A,I10)')
     &    'MON_SOLUTION: STOPPING CALCULATION at Iter=', myIter
        CALL PRINT_MESSAGE(msgBuf,errorMessageUnit,SQUEEZE_RIGHT,myThid)
        _END_MASTER(myThid)

          WRITE(suff,'(I10.10)') myIter
          CALL 
     &   WRITE_FLD_XYZ_RL('stateThetacrash.',suff,theta,myIter,myThid)
          CALL 
     &   WRITE_FLD_XYZ_RL('stateSaltcrash.',suff,salt,myIter,myThid)
          CALL 
     &   WRITE_FLD_XY_RL('stateEtacrash.',suff,etaN,myIter,myThid)
          CALL 
     &   WRITE_FLD_XYZ_RL('stateUvelcrash.',suff,uVel,myIter,myThid)
          CALL 
     &   WRITE_FLD_XYZ_RL('stateVvelcrash.',suff,vVel,myIter,myThid)
          CALL 
     &   WRITE_FLD_XYZ_RL('stateWvelcrash.',suff,wVel,myIter,myThid)
#ifdef ALLOW_SEAICE
          CALL 
     &   WRITE_FLD_XY_RL('stateAreacrash.',suff,AREA,myIter,myThid)
          CALL 
     &   WRITE_FLD_XY_RL('stateHeffcrash.',suff,Heff,myIter,myThid)
          CALL 
     &   WRITE_FLD_XY_RL('stateUicecrash.',suff,UICE,myIter,myThid)
          CALL 
     &   WRITE_FLD_XY_RL('stateVicecrash.',suff,VICE,myIter,myThid)       
#endif
          CALL
     &   WRITE_FLD_XY_RL('stateQnetcrash.',suff,Qnet,myIter,myThid)
          CALL
     &   WRITE_FLD_XY_RL('stateEmpmrcrash.',suff,EmPmR,myIter,myThid)
          CALL
     &   WRITE_FLD_XY_RL('stateMxlcrash.',suff,hMixLayer,myIter,myThid)

         

        CALL ALL_PROC_DIE( myThid )
        STOP
     &  'ABNORMAL END: S/R MON_SOLUTION, stops due to EXTREME Pot.Temp'
      ENDIF

      RETURN
      END
