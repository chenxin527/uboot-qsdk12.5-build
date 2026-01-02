/*
 * Copyright (c) 2013 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */


//depot/sw/qca_main/perf_pwr_offload/drivers/host/include/a_types.h#7 - integrate change 1327637 (ktext)
//==============================================================================
// This file contains the definitions of the basic atheros data types.
// It is used to map the data types in atheros files to a platform specific
// type.
//
// Author(s): ="Atheros"
//==============================================================================

#ifndef _A_TYPES_H_
#define _A_TYPES_H_
#include <athdefs.h>

#if defined (ATHR_WIN_NWF)
typedef char               A_INT8,  int8_t, A_CHAR;
typedef short              A_INT16, int16_t;
typedef long               A_INT32, int32_t;
typedef unsigned char      A_UINT8,  u_int8_t, A_UCHAR, u_char;
typedef unsigned short     A_UINT16, u_int16_t;
typedef	unsigned long      A_UINT32, u_int32_t;
typedef unsigned long long A_UINT64, u_int64_t;
typedef int                A_BOOL;
typedef int                bool;
#else
typedef	unsigned int A_UINT32;
typedef unsigned long long A_UINT64;
typedef unsigned short A_UINT16;
typedef unsigned char  A_UINT8;
typedef int A_INT32;
typedef short A_INT16;
typedef char  A_INT8;
typedef unsigned char  A_UCHAR;
typedef char  A_CHAR;
#ifndef __ubicom32__
typedef bool  A_BOOL;
#else
typedef _Bool A_BOOL;
#endif
#endif
#if 0
typedef u_int32_t A_UINT32;
typedef u_int64_t A_UINT64;
typedef u_int16_t A_UINT16;
typedef u_int8_t  A_UINT8;
typedef int32_t A_INT32;
typedef int16_t A_INT16;
typedef int8_t  A_INT8;
typedef u_char  A_UCHAR;
typedef char  A_CHAR;
typedef bool  A_BOOL;
#endif

#endif /* _ATHTYPES_H_ */
