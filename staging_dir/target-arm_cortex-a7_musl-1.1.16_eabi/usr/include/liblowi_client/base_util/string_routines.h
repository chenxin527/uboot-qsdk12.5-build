/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 String related routines

 GENERAL DESCRIPTION
 This component implements portable string related routines

 Copyright (c) 2013 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 Copyright (c) 2016 Qualcomm Technologies, Inc.
 All Rights Reserved.
 Confidential and Proprietary - Qualcomm Technologies, Inc.
 =============================================================================*/

#ifndef __QC_LOC_FW_STRING_H__
#define __QC_LOC_FW_STRING_H__

#include <base_util/log.h>

namespace qc_loc_fw
{

#ifndef __ANDROID__
#ifndef LOWI_ON_ACCESS_POINT
// Android has its own strlcpy
size_t strlcpy(char *dest, const char *src, size_t dest_capacity);
// Android has its own strlcat
size_t strlcat(char *dest, const char *src, size_t dest_capacity);
#endif // #ifndef LOWI_ON_ACCESS_POINT
#endif // #ifndef __ANDROID__

} // namespace qc_loc_fw

#endif //#ifndef __QC_LOC_FW_STRING_H__
