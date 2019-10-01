C CPP options file for FRAZIL
C Use this file for selecting options within package "Frazil"

#ifndef FRAZIL_OPTIONS_H
#define FRAZIL_OPTIONS_H
#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"

#ifdef ALLOW_FRAZIL

C Three options to prevent Ice Shelf Water, which escapes from cavities, from forming sea ice. This process, while realistic, is inherently unstable as it causes isolated patches of sea ice tens of metres thick.

C Calculate supercooling of potential temperature with respect to the surface freezing point, NOT in-situ temperature with respect to the depth-dependent freezing point.
# define FRAZIL_TFREEZE_SFC

C Instead of moving the supercooling to the surface layer, just remove it completely. Send it to space!
# define FRAZIL_ZAP

C Don't do anything to supercooled water in cavities.
# define FRAZIL_IGNORE_CAVITIES

#endif /* ALLOW_FRAZIL */
#endif /* FRAZIL_OPTIONS_H */

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
