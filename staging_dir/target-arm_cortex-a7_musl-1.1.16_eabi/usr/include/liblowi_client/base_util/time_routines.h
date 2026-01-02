/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

 Time related routines

 GENERAL DESCRIPTION
 This component implements portable time related routines

 Copyright (c) 2013 Qualcomm Atheros, Inc.
 All Rights Reserved.
 Qualcomm Atheros Confidential and Proprietary.

 Copyright (c) 2015 - 2016 Qualcomm Technologies, Inc.
 All Rights Reserved.
 Confidential and Proprietary - Qualcomm Technologies, Inc.
 =============================================================================*/

#ifndef __QC_LOC_FW_TIME_H__
#define __QC_LOC_FW_TIME_H__

#include <time.h>


#ifdef __cplusplus
#include <base_util/postcard.h>
namespace qc_loc_fw
{

class TimeDiff
{
public:
  // validity: false to prevent any further operation unless it's reset with true
  // or being copied/assigned with = to a valid object
  explicit TimeDiff(const bool validity = true);
  int add_sec(const int sec);
  int add_msec(const int msec);
  int add_nsec(const int nsec);
  float get_total_sec() const;
  float get_total_msec() const;
  const timespec* getTimeDiffPtr() const;
  bool is_valid() const;
  void reset(const bool validity = false);
private:
  static const char *const TAG;
  bool m_is_valid;
  timespec m_timediff;
};

class Timestamp
{
public:
  // set to false if you want to use reset_to_XXX functions to initialize it to
  // non-default clock, or you simply want to set it later, instead of at time of construction
  explicit Timestamp(const bool set_to_default_clock = true);

  // use this if you want to set it to some specific clock type using clock id (defined in time.h)
  explicit Timestamp(const int clock_id);

  // use this if you want to initialize it with pre-existing timespec acquired using some clock type
  Timestamp(const int clock_id, const timespec& src);

  // copy constructor
  Timestamp(const Timestamp& rhs);

  timespec* getTimestampPtr();
  const timespec* getTimestampPtr() const;

  // use this one for most cases, which uses BOOTTIME if available, otherwise MONOTONIC
  int reset_to_default_clock();

  // CLOCK_MONOTONIC, this might be subjected to NTP clock modulation, and might stop counting
  // when the device is sleeping
  int reset_to_monotonic();

  // CLOCK_BOOTTIME, same as CLOCK_MONOTONIC, but should count sleeping time as well
  // currently not supported
  int reset_to_boottime();

  // CLOCK_REALTIME. wall clock, subject to system time change. normally you don't want this
  // if you're looking for timers
  int reset_to_realtime();

  int reset_to_clock_id(const int clock_id);

  int get_clock_id() const;
  bool is_valid() const;
  bool is_valid_and_default() const;
  void invalidate();
  Timestamp operator +(const TimeDiff& rhs) const;
  Timestamp operator -(const TimeDiff& rhs) const;
  TimeDiff operator -(const Timestamp& rhs) const;
  bool operator>=(const Timestamp& rhs) const;
  bool operator<(const Timestamp& rhs) const;
  Timestamp& operator = (const Timestamp& rhs);

  // timestamp is highly system-specific and doesn't translate into Java world well
  // so, please use these functions with caution
  int insert_into_postcard(OutPostcard *const dest_card, const char *const name_str);
  int retrieve_from_postcard(InPostcard *const src_card, const char *const name_str);
private:
  static const char *const TAG;
  bool m_is_valid;
  int m_clock_id;
  timespec m_timestamp;
};
#endif // #ifdef __cplusplus
#ifdef __cplusplus
extern "C"
{
#else
#include <stdbool.h>
#endif

// Function Name: get_time_rtc_ms
// Description:   return rtc time in milliseconds
//                represents time since the Epoch
long long get_time_rtc_ms();

// Function Name: is_time_rtc_ms_valid
// Description:   Check if rtc time is valid or not
bool is_time_rtc_ms_valid(long long rtc_time_ms);

// Function Name: get_time_boot_ms
// Description:   Returns monotonic time from boot
long long get_time_boot_ms();

// Function Name: get_time_monotonic_ms
// Description:   Returns monotonic time
long long get_time_monotonic_ms();

#ifdef __cplusplus
}
#endif
#ifdef __cplusplus
} // namespace qc_loc_fw
#endif

#endif //#ifndef __QC_LOC_FW_TIME_H__
