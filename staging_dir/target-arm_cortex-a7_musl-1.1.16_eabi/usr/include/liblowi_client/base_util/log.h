/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Log utility

 GENERAL DESCRIPTION
 This header declares a logging utility

 Copyright (c) 2012-2013 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

Copyright (c) 2014 Qualcomm Technologies, Inc.
 All Rights Reserved.
 Confidential and Proprietary - Qualcomm Technologies, Inc.

 =============================================================================*/
#ifndef __XTRAT_WIFI_LOG_H__
#define __XTRAT_WIFI_LOG_H__

namespace qc_loc_fw
{

enum ERROR_LEVEL
{
  EL_LOG_OFF = 0, EL_ERROR = 1, EL_WARNING = 2, EL_INFO = 3, EL_DEBUG = 4, EL_VERBOSE = 5, EL_LOG_ALL = 100
};

void log_error(const char * const local_log_tag, const char * const format, ...);
void log_warning(const char * const local_log_tag, const char * const format, ...);
void log_info(const char * const local_log_tag, const char * const format, ...);
void log_debug(const char * const local_log_tag, const char * const format, ...);
void log_verbose(const char * const local_log_tag, const char * const format, ...);

int log_set_global_level(const ERROR_LEVEL level);
int log_set_global_tag(const char * const tag);
int log_flush_all_local_level();
int log_flush_local_level_for_tag(const char * const tag);
int log_set_local_level_for_tag(const char * const tag, const ERROR_LEVEL level);

bool is_log_verbose_enabled(const char * const local_log_tag);

} // namespace qc_loc_fw

#endif //#ifndef __XTRAT_WIFI_LOG_H__
