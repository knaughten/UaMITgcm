C $Header: /u/gcmpack/MITgcm_contrib/verification_other/shelfice_remeshing/code/shelfice_thermodynamics.F,v 1.19 2016/07/06 18:03:40 dgoldberg Exp $
C $Name:  $

#include "SHELFICE_OPTIONS.h"

CBOP
C     !ROUTINE: SHELFICE_THERMODYNAMICS
C     !INTERFACE:
      SUBROUTINE SHELFICE_THERMODYNAMICS(
     I                        myTime, myIter, myThid )
C     !DESCRIPTION: \bv
C     *=============================================================*
C     | S/R  SHELFICE_THERMODYNAMICS
C     | o shelf-ice main routine.
C     |   compute temperature and (virtual) salt flux at the
C     |   shelf-ice ocean interface
C     |
C     | stresses at the ice/water interface are computed in separate
C     | routines that are called from mom_fluxform/mom_vecinv
C     *=============================================================*
C     \ev

C     !USES:
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#include "FFIELDS.h"
#include "SHELFICE.h"
#include "SHELFICE_COST.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     myIter :: iteration counter for this thread
C     myTime :: time counter for this thread
C     myThid :: thread number for this instance of the routine.
      _RL  myTime
      INTEGER myIter
      INTEGER myThid

C     !LOCAL VARIABLES :
C     === Local variables ===
C     I,J,K,Kp1,bi,bj  :: loop counters
C     tLoc, sLoc, pLoc :: local in-situ temperature, salinity, pressure
C     theta/saltFreeze :: temperature and salinity of water at the
C                         ice-ocean interface (at the freezing point)
C     freshWaterFlux   :: local variable for fresh water melt flux due
C                         to melting in kg/m^2/s
C                         (negative density x melt rate)
C     convertFW2SaltLoc:: local copy of convertFW2Salt
C     cFac             :: 1 for conservative form, 0, otherwise
C     rFac             :: realFreshWaterFlux factor
C     dFac             :: 0 for diffusive heat flux (Holland and Jenkins, 1999,
C                           eq21)
C                         1 for advective and diffusive heat flux (eq22, 26, 31)
C     fwflxFac         :: only effective for dFac=1, 1 if we expect a melting
C                         fresh water flux, 0 otherwise
C     auxiliary variables and abbreviations:
C     a0, a1, a2, b, c0
C     eps1, eps2, eps3, eps3a, eps4, eps5, eps6, eps7, eps8
C     aqe, bqe, cqe, discrim, recip_aqe
C     drKp1, recip_drLoc
      INTEGER I,J,K,Kp1
      INTEGER bi,bj
      _RL tLoc(1:sNx,1:sNy)
      _RL sLoc(1:sNx,1:sNy)
      _RL pLoc(1:sNx,1:sNy)
      _RL uLoc(1:sNx,1:sNy)
      _RL vLoc(1:sNx,1:sNy)
      _RL u_topdr(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL v_topdr(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL velSq(1:sNx,1:sNy)
      _RL thetaFreeze, saltFreeze, recip_Cp
      _RL freshWaterFlux, convertFW2SaltLoc
      _RL a0, a1, a2, b, c0
      _RL eps1, eps2, eps3, eps3a, eps4, eps5, eps6, eps7, eps8
      _RL cFac, rFac, dFac, fwflxFac
      _RL aqe, bqe, cqe, discrim, recip_aqe
      _RL drKp1, recip_drLoc
      _RL recip_latentHeat
      _RL tmpFac

      _RL ustar, ustarSq
      _RL uStarDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL uLocDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL vLocDiag(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

      _RL SW_TEMP
       EXTERNAL SW_TEMP

CEOP
C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C +++++++++++++++
C +++++++++++++++
C HARDWIRE PARAMS
C +++++++++++++++
C +++++++++++++++

C       shiCdrag = 0.0097
C       SHELFICEheatTransCoeff = 0.011
C       SHELFICEsaltTransCoeff = 0.00031
      
C ++++++++++++++++
C ++++++++++++++++
C INITIALISE STUFF
C ++++++++++++++++
C ++++++++++++++++


      recip_latentHeat = 0. _d 0
      IF ( SHELFICElatentHeat .NE. 0. _d 0 )
     &     recip_latentHeat = 1. _d 0/SHELFICElatentHeat

C     are we doing the conservative form of Jenkins et al. (2001)?
      recip_Cp = 1. _d 0 / HeatCapacity_Cp
      cFac = 0. _d 0
      IF ( SHELFICEconserve ) cFac = 1. _d 0

C     with "real fresh water flux" (affecting ETAN),
C     there is more to modify
      rFac = 1. _d 0
      IF ( SHELFICEconserve .AND. useRealFreshWaterFlux ) rFac = 0. _d 0

C     heat flux into the ice shelf, default is diffusive flux
C     (Holland and Jenkins, 1999, eq.21)
      dFac = 0. _d 0
      IF ( SHELFICEadvDiffHeatFlux ) dFac = 1. _d 0
      fwflxFac = 0. _d 0

C     linear dependence of freezing point on salinity
      a0 = -0.0573   _d  0
      a1 =  0.0      _d -0
      a2 =  0.0      _d -0
      c0 =  0.0832   _d  0
      b  =  -7.53    _d -4

      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO J = 1-OLy,sNy+OLy
         DO I = 1-OLx,sNx+OLx
          shelfIceHeatFlux      (I,J,bi,bj) = 0. _d 0
          shelfIceFreshWaterFlux(I,J,bi,bj) = 0. _d 0
          shelficeForcingT      (I,J,bi,bj) = 0. _d 0
          shelficeForcingS      (I,J,bi,bj) = 0. _d 0
          uStarDiag             (I,J,bi,bj) = 0. _d 0
          uLocDiag              (I,J,bi,bj) = 0. _d 0
          vLocDiag              (I,J,bi,bj) = 0. _d 0
         ENDDO
        ENDDO
       ENDDO
      ENDDO

C +++++++++++++++
C +++++++++++++++
C START MAIN LOOP
C +++++++++++++++
C +++++++++++++++

      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)

C ++++++++++++++++++++++++
C ++++++++++++++++++++++++
C GET T,S TO DRIVE MELTING
C ++++++++++++++++++++++++
C ++++++++++++++++++++++++

C--  make local copies of temperature, salinity and depth (pressure in deci-bar)
C--  underneath the ice
        DO J = 1, sNy
         DO I = 1, sNx
          K         = MAX(1,kTopC(I,J,bi,bj))
          pLoc(I,J) = ABS(R_shelfIce(I,J,bi,bj))
          tLoc(I,J) = theta(I,J,K,bi,bj)
          sLoc(I,J) = MAX(salt(I,J,K,bi,bj), zeroRL)
         ENDDO
        ENDDO

C--  average T and S over boundary layer width
         DO J = 1, sNy
          DO I = 1, sNx

           K   = kTopC(I,J,bi,bj)

           IF ( K .NE. 0 .AND. K .LT. Nr ) THEN
            Kp1 = MIN(Nr,K+1)

C--  overlap into lower cell
            drKp1 = drF(K)*( 1. _d 0 - _hFacC(I,J,K,bi,bj) )

C--  lower cell may not be as thick as required
            drKp1 = MIN( drKp1, drF(Kp1) * _hFacC(I,J,Kp1,bi,bj) )
            drKp1 = MAX( drKp1, 0. _d 0 )
            recip_drLoc = 1. _d 0 /
     &           ( drF(K)*_hFacC(I,J,K,bi,bj) + drKp1 )

            tLoc(I,J) = ( tLoc(I,J) * drF(K)*_hFacC(I,J,K,bi,bj)
     &           + theta(I,J,Kp1,bi,bj) *drKp1 )
     &           * recip_drLoc

            sLoc(I,J) = ( sLoc(I,J) * drF(K)*_hFacC(I,J,K,bi,bj)
     &           + MAX(salt(I,J,Kp1,bi,bj), zeroRL) * drKp1 )
     &           * recip_drLoc
           ENDIF

          ENDDO
         ENDDO

C--  turn potential temperature into in-situ temperature relative
C--  to the surface
        DO J = 1, sNy
         DO I = 1, sNx
          tLoc(I,J) = SW_TEMP(sLoc(I,J),tLoc(I,J),pLoc(I,J),zeroRL)
         ENDDO
        ENDDO

C ++++++++++++++++++++++
C ++++++++++++++++++++++
C GET U TO DRIVE MELTING
C ++++++++++++++++++++++
C ++++++++++++++++++++++

C--  get velocities from topdr formulation
         DO J = 1, sNy+1
          DO I = 1, sNx+1
           u_topdr(I,J,bi,bj) = 0.0
           v_topdr(I,J,bi,bj) = 0.0
          ENDDO
         ENDDO

         DO J = 1, sNy+1
          DO I = 1, sNx+1
           K = ksurfW(I,J,bi,bj)
           Kp1 = K+1

           IF (K.lt.Nr) then
            drKp1 = max (drKp1, 0. _d 0)
            recip_drLoc = 1.0 / 
     &       (drF(K)*_hFacW(I,J,K,bi,bj)+drKp1)
            u_topdr(I,J,bi,bj) = 
     &       (drF(K)*_hFacW(I,J,K,bi,bj)*uVel(I,J,K,bi,bj) + 
     &        drKp1*uVel(I,J,Kp1,bi,bj)) 
     &      * recip_drLoc
           ELSE
            u_topdr(I,J,bi,bj) = 0. _d 0
           ENDIF
           
           K = ksurfS(I,J,bi,bj)
           Kp1 = K+1

           IF (K.lt.Nr) then
            drKp1 = drF(K)*(1. _d 0-_hFacS(I,J,K,bi,bj))
            drKp1 = max (drKp1, 0. _d 0)
            recip_drLoc = 1.0 / 
     &       (drF(K)*_hFacS(I,J,K,bi,bj)+drKp1)
            v_topdr(I,J,bi,bj) = 
     &       (drF(K)*_hFacS(I,J,K,bi,bj)*vVel(I,J,K,bi,bj) + 
     &        drKp1*vVel(I,J,Kp1,bi,bj)) 
     &      * recip_drLoc
           ELSE
            v_topdr(I,J,bi,bj) = 0. _d 0
           ENDIF

          ENDDO
         ENDDO

         DO J = 1, sNy
          DO I = 1, sNx
           uLoc(I,J) = halfRL *
     &      (u_topdr(I,J,bi,bj) + u_topdr(I+1,J,bi,bj))
           vLoc(I,J) = halfRL *
     &      (v_topdr(I,J,bi,bj) + v_topdr(I,J+1,bi,bj))
           velSq(I,J) = uLoc(I,J)*uLoc(I,J)+vLoc(I,J)*vLoc(I,J)
           uLocDiag(I,J,bi,bj) = uLoc(I,J)
           vLocDiag(I,J,bi,bj) = vLoc(I,J)
          ENDDO
         ENDDO

C +++++++++++++++++
C +++++++++++++++++
C CALCULATE MELTING
C +++++++++++++++++
C +++++++++++++++++

C     calculate friction velocity and heat and salt transfer coeffs
         DO J = 1, sNy
          DO I = 1, sNx
           K = kTopC(I,J,bi,bj)
           IF ( K .NE. 0 .AND. pLoc(I,J) .GT. 0. _d 0 ) THEN
            ustarSq = shiCdrag * MAX( 1.D-6, velSq(I,J) )
C     modify ustar with tidal component as specified in ISOMIP+ setup
            ustar   = SQRT(ustarSq + shiCdrag * 0.01 * 0.01)
            uStarDiag(I,J,bi,bj) = ustar
            shiTransCoeffT(i,j,bi,bj) = MAX( zeroRL,
     &           ustar*SHELFICEheatTransCoeff)
            shiTransCoeffS(i,j,bi,bj) = MAX( zeroRL,
     &           ustar*SHELFICEsaltTransCoeff)
           ENDIF
          ENDDO
         ENDDO

C     use BRIOS thermodynamics, following Hellmers PhD thesis:
C     Hellmer, H., 1989, A two-dimensional model for the thermohaline
C     circulation under an ice shelf, Reports on Polar Research, No. 60
C     (in German).

         DO J = 1, sNy
          DO I = 1, sNx
           K    = kTopC(I,J,bi,bj)
           IF ( K .NE. 0 .AND. pLoc(I,J) .GT. 0. _d 0 ) THEN

C     heat flux into the ice shelf, default is diffusive flux
C     (Holland and Jenkins, 1999, eq.21)
            thetaFreeze = a0*sLoc(I,J)+c0+b*pLoc(I,J)
            fwflxFac    = 0. _d 0
            IF ( tLoc(I,J) .GT. thetaFreeze ) fwflxFac = dFac

C     a few abbreviations
            eps1 = rUnit2mass*HeatCapacity_Cp
     &           *shiTransCoeffT(i,j,bi,bj)
            eps2 = rUnit2mass*SHELFICElatentHeat
     &           *shiTransCoeffS(i,j,bi,bj)
            eps5 = rUnit2mass*HeatCapacity_Cp
     &           *shiTransCoeffS(i,j,bi,bj)

C     solve quadratic equation for salinity at shelfice-ocean interface
C     note: this part of the code is not very intuitive as it involves
C     many arbitrary abbreviations that were introduced to derive the
C     correct form of the quadratic equation for salinity. The abbreviations
C     only make sense in connection with my notes on this (M.Losch)
C
C     eps3a was introduced as a constant variant of eps3 to avoid AD of
C     code of typ (pLoc-const)/pLoc
            eps3a = rhoShelfIce*SHELFICEheatCapacity_Cp
     &           * SHELFICEkappa *  ( 1. _d 0 - dFac )
            eps3 = eps3a/pLoc(I,J)
            eps4 = b*pLoc(I,J) + c0
            eps6 = eps4 - tLoc(I,J)
            eps7 = eps4 - SHELFICEthetaSurface
            eps8 = rUnit2mass*SHELFICEheatCapacity_Cp
     &           *shiTransCoeffS(i,j,bi,bj) * fwflxFac
            aqe = a0  *(eps1+eps3-eps8)
            recip_aqe = 0. _d 0
            IF ( aqe .NE. 0. _d 0 ) recip_aqe = 0.5 _d 0/aqe
c           bqe = eps1*eps6 + eps3*eps7 - eps2
            bqe = eps1*eps6
     &           + eps3a*( b
     &                   + ( c0 - SHELFICEthetaSurface )/pLoc(I,J) )
     &           - eps2
     &           + eps8*( a0*sLoc(I,J) - eps7 )
            cqe = ( eps2 + eps8*eps7 )*sLoc(I,J)
            discrim = bqe*bqe - 4. _d 0*aqe*cqe
            saltFreeze = (- bqe - SQRT(discrim))*recip_aqe
            IF ( saltFreeze .LT. 0. _d 0 )
     &           saltFreeze = (- bqe + SQRT(discrim))*recip_aqe
            thetaFreeze = a0*saltFreeze + eps4

C--   upward fresh water flux due to melting (in kg/m^2/s)
            freshWaterFlux = rUnit2mass
     &           * shiTransCoeffS(i,j,bi,bj)
     &           * ( 1. _d 0 - sLoc(I,J) / saltFreeze )

C--   Calculate the upward heat and fresh water fluxes;
C--   MITgcm sign conventions: downward (negative) fresh water flux
C--   implies melting and due to upward (positive) heat flux
            shelfIceHeatFlux(I,J,bi,bj) =
     &           ( eps3
     &           - freshWaterFlux*SHELFICEheatCapacity_Cp*fwflxFac )
     &           * ( thetaFreeze - SHELFICEthetaSurface )
     &           -  cFac*freshWaterFlux*( SHELFICElatentHeat
     &             - HeatCapacity_Cp*( thetaFreeze - rFac*tLoc(I,J) ) )
            shelfIceFreshWaterFlux(I,J,bi,bj) = freshWaterFlux

C--   compute surface tendencies
            shelficeForcingT(i,j,bi,bj) =
     &           ( shiTransCoeffT(i,j,bi,bj)
     &           - cFac*shelfIceFreshWaterFlux(I,J,bi,bj)*mass2rUnit )
     &           * ( thetaFreeze - tLoc(I,J) )
            shelficeForcingS(i,j,bi,bj) =
     &           ( shiTransCoeffS(i,j,bi,bj)
     &           - cFac*shelfIceFreshWaterFlux(I,J,bi,bj)*mass2rUnit )
     &           * ( saltFreeze - sLoc(I,J) )

           ELSE

            shelfIceHeatFlux      (I,J,bi,bj) = 0. _d 0
            shelfIceFreshWaterFlux(I,J,bi,bj) = 0. _d 0
            shelficeForcingT      (I,J,bi,bj) = 0. _d 0
            shelficeForcingS      (I,J,bi,bj) = 0. _d 0

           ENDIF

          ENDDO
         ENDDO

C +++++++++++++
C +++++++++++++
C END MAIN LOOP
C +++++++++++++
C +++++++++++++

       ENDDO
      ENDDO

C +++++++++++++++++
C +++++++++++++++++
C WRITE DIAGNOSTICS
C +++++++++++++++++
C +++++++++++++++++

       CALL DIAGNOSTICS_FILL_RS(shelfIceFreshWaterFlux,'SHIfwFlx',
     &      0,1,0,1,1,myThid)
       CALL DIAGNOSTICS_FILL_RS(shelfIceHeatFlux,      'SHIhtFlx',
     &      0,1,0,1,1,myThid)

C     SHIForcT (Ice shelf forcing for theta [W/m2], >0 increases theta)
       tmpFac = HeatCapacity_Cp*rUnit2mass
       CALL DIAGNOSTICS_SCALE_FILL(shelficeForcingT,tmpFac,1,
     &      'SHIForcT',0,1,0,1,1,myThid)

C     SHIForcS (Ice shelf forcing for salt [g/m2/s], >0 increases salt)
       tmpFac = rUnit2mass
       CALL DIAGNOSTICS_SCALE_FILL(shelficeForcingS,tmpFac,1,
     &      'SHIForcS',0,1,0,1,1,myThid)

C     Transfer coefficients
       CALL DIAGNOSTICS_FILL(shiTransCoeffT,'SHIgammT',
     &      0,1,0,1,1,myThid)
       CALL DIAGNOSTICS_FILL(shiTransCoeffS,'SHIgammS',
     &      0,1,0,1,1,myThid)

C     Friction velocity
       CALL DIAGNOSTICS_FILL(uStarDiag,'SHIuStar',0,1,0,1,1,myThid)
       CALL DIAGNOSTICS_FILL(uLocDiag,'SHIuLoc ',0,1,0,1,1,myThid)
       CALL DIAGNOSTICS_FILL(vLocDiag,'SHIvLoc ',0,1,0,1,1,myThid)

      RETURN
      END


