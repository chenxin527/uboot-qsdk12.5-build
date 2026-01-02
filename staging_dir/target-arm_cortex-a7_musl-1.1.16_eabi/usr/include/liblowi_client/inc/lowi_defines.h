#ifndef __LOWI_DEFINES_H__
#define __LOWI_DEFINES_H__

/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

        LOWI Defines Interface Header file

GENERAL DESCRIPTION
  This file contains the structure definitions and function prototypes for
  LOWIDefines

Copyright (c) 2012, 2017-2019 Qualcomm Technologies, Inc.
  All Rights Reserved.
  Confidential and Proprietary - Qualcomm Technologies, Inc.

  (c) 2012 Qualcomm Atheros, Inc.
  All Rights Reserved.
  Qualcomm Atheros Confidential and Proprietary.

=============================================================================*/
#ifndef __STDC_FORMAT_MACROS
  #define __STDC_FORMAT_MACROS
#endif
#include <ctype.h>
#include <inttypes.h>
#include <stdint.h>

#if defined (LOWI_ON_ACCESS_POINT)
  #include <lowi_types.h>
  #include <base_util/string_routines.h>
#else
  #include "comdef.h"
  #include <loc_pla.h>
  #include <loc_cfg.h>
  #ifdef IZAT_OFFLINE
    #include <base_util/string_routines.h>
  #endif
#endif

// This is here because for some reason strlcat and strlcpy
// are not available on Ubuntu but on Android
#ifdef USE_GLIB
#include <glib.h>
#define strlcpy g_strlcpy
#define strlcat g_strlcat
#endif

// Config file
#ifdef __ANDROID__
#define CONFIG_NAME LOC_PATH_LOWI_CONF
#elif defined (LOWI_ON_ACCESS_POINT)
    #define CONFIG_NAME "/etc/lowi/lowi.conf"
#else
  #ifndef ROOT_DIR
  #define ROOT_DIR ""
  #endif
  #define CONFIG_NAME ROOT_DIR "lowi.conf"
#endif // #ifdef __ANDROID__

#endif //#ifndef __LOWI_DEFINES_H__
