#ifndef __LOWI_CONST_H__
#define __LOWI_CONST_H__

/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*

        LOWI Const Interface Header file

GENERAL DESCRIPTION
  This file contains the structure definitions and function prototypes for
  LOWIConst

  Copyright (c) 2012,2016,2018 Qualcomm Technologies, Inc.
  All Rights Reserved.
   Confidential and Proprietary - Qualcomm Technologies, Inc

  (c) 2012 Qualcomm Atheros, Inc.
  All Rights Reserved.
  Qualcomm Atheros Confidential and Proprietary.

=============================================================================*/
#include <ctype.h>
#include <inttypes.h>
#include <time.h>
#include <new>
#include <stdint.h>
#include <base_util/vector.h>
#include <inc/lowi_defines.h>

namespace qc_loc_fw
{

#define BSSID_LEN 6
#define SSID_LEN 32
#define MAX_CHAN_INFO_SIZE 16
#define CLIENT_NAME_LEN 128
#define CELL_POWER_NOT_FOUND 0x7F
#define LOWI_COUNTRY_CODE_LEN 2
#define CIVIC_INFO_LEN 256 // civic information size in bytes

const char* const LOWI_CLIENT_SUFFIX = "-LC";
const char* const SERVER_NAME = "LOWI-SERVER";
const char* const NOT_AVAILABLE = "NA";
// 4 Hours period
const int ASYNC_DISCOVERY_REQ_VALIDITY_PERIOD_SEC_MAX = 4*3600;

#define WIFI_CHANNEL_SPACING 5      // Channels are 5 MHz apart
#define BAND_2G_FREQ_BASE     2407  //Base frequency of 2G band (MHz)
#define BAND_2G_CHAN_BEGIN    1     //First channel for 2G band
#define BAND_2G_CHAN_END      14    //Last channel for 2G band
#define BAND_2G_FREQ_LAST     2484  //Last frequency for 2G band (MHz)
#define BAND_5G_FREQ_BASE     5000  //Base frequency of 5G band (MHz)
#define BAND_5G_CHAN_BEGIN    34    //First channel for 5G band
#define BAND_5G_CHAN_END      196   //Last channel for 5G band
#define BAND_60G_FREQ_BASE    56160 //Base frequency for 60G band (MHz)
#define BAND_60G_CHAN_BEGIN   1     //First channel for 60G band
#define BAND_60G_CHAN_END     4     //Last channel for 60G band
#define BAND_60G_CHAN_SPACING 2160  //Channel spacing for 60G band (MHz)

#define IS_2G_CHANNEL(x) ((x >= BAND_2G_CHAN_BEGIN) && (x <= BAND_2G_CHAN_END))
#define IS_2G_FREQ(x) ((x >= BAND_2G_FREQ_BASE) && (x <= BAND_2G_FREQ_LAST))
#define IS_60G_CHANNEL(x) ((x >= BAND_60G_CHAN_BEGIN) && (x <= BAND_60G_CHAN_END))

/* The highest valid channel ID supported by Wi-Fi driver */
#define MAX_CHANNEL_ID BAND_5G_CHAN_END

// minimum measurement period (in msec) for a wifi node in an ranging periodic request
uint32 const LOWI_MIN_MEAS_PERIOD = 500;
// maximum number of measurement retries attempted by the lowi scheduler on a wifi node
uint8  const MAX_RETRIES_PER_MEAS = 3;
// maximum number of channels allowed in a bgscan bucket specification
uint8 const LOWI_MAX_CHANNELS_GSCAN = 16;
// maximum number of buckets allowed in a bgscan request
uint8 const LOWI_MAX_BUCKETS = 16;
// maximum number of wifi nodes allowed in a hotlist request
uint32 const LOWI_MAX_HOTLIST_APS = 128;
// maximum number of wifi nodes allowed in a significant change request
uint32 const LOWI_MAX_SIGNIFICANT_CHANGE_APS = 64;
// ssid length: 32 bytes plus one byte for null char
uint32 const LOWI_SSID_LENGTH_WITH_NULL = SSID_LEN + 1;

// speed of light in centimeters per nanosecond
float const LOWI_LIGHT_SPEED_CM_PER_NSEC = 30.0;
// speed of light in centimeters per picsecond
float const LOWI_LIGHT_SPEED_CM_PER_PSEC = 0.03;
// speed of light in millimeters per picsecond
float const LOWI_LIGHT_SPEED_MM_PER_PSEC = 0.3;
// tenths of nanoseconds constant
float const TENTHS_PER_NSEC = 10.0;
// divide by two constant
float const LOWI_DIVIDE_BY_TWO = 2.0;
// includes all constants needed to yield distance in cm such that:
// distance(cm) = rtt * RTT_DIST_CONST;
// where rtt is in psecs
float const RTT_DIST_CONST_PS = (LOWI_LIGHT_SPEED_CM_PER_PSEC /
                                LOWI_DIVIDE_BY_TWO);
// includes all constants needed to yield distance in mm such that:
// distance(mm) = rtt * RTT_DIST_CONST;
// where rtt is in psecs
float const RTT_DIST_CONST_PS_MM = (LOWI_LIGHT_SPEED_MM_PER_PSEC /
                                LOWI_DIVIDE_BY_TWO);
// includes all constants needed to yield distance in cm such that:
// distance(cm) = rtt * RTT_DIST_CONST;
// where rtt is in 10ths of nsec
float const RTT_DIST_CONST = (LOWI_LIGHT_SPEED_CM_PER_NSEC /
                              TENTHS_PER_NSEC /
                              LOWI_DIVIDE_BY_TWO);

// FTMRR Report Range units: 1/4096m in cms
float const FTMRR_RANGE_UNITS = ((1.0/4096.0)*100.0);

// WPA Supplicant's string command size
uint32 const LOWI_WPA_CMD_SIZE = 256;
// AP Geospatial Location ANQP Info ID
uint32 const LOWI_GEOSPATIAL_LOCATION_ANQP_INFO_ID = 265;
// AP Civic Location ANQP Info ID
uint32 const LOWI_CIVIC_LOCATION_ANQP_INFO_ID = 266;
// AP Location Public Identifier URI/FQDN
uint32 const LOWI_CIVIC_LOCATION_ANQP_URI_FQDN_ID = 267;

// Wifi driver's default interface name
#ifndef LOWI_ON_ACCESS_POINT
#define DEFAULT_WLAN_INTERFACE "wlan0"
#else
#define DEFAULT_WLAN_INTERFACE "ath"
#endif
// Wigig driver's default interface name
#define DEFAULT_WIGIG_INTERFACE "wigig0"
// Driver interface name maximum length
#define LOWI_MAX_INTF_NAME_LEN 25

// Default values for azimuth and elevation in AoA measurements. These values are
// well beyond the range that is expected from the hardware. Range expected from
// the hardware is +90 to -90 degrees approximately. Units degrees.
#define LOWI_AZIMUTH_DEFAULT   1000
#define LOWI_ELEVATION_DEFAULT 1000

////////////////////////////////////////////////////////////////////////////
// Constants used when checking periodic parameters in RTT ranging requests
////////////////////////////////////////////////////////////////////////////
unsigned int const MAX_FRAMES_PER_BURST         = 31;
unsigned int const MIN_FRAMES_PER_BURST         = 1;
unsigned int const BURST_DURATION_NO_PREFERENCE = 15;
unsigned int const MAX_BURST_DURATION           = 11;
unsigned int const MIN_BURST_DURATION           = 2;
unsigned int const MAX_NUM_BURST_EXP            = 15;
unsigned int const MIN_NUM_BURST_EXP            = 0;
unsigned int const MAX_BURST_PERIOD             = 31;
unsigned int const MIN_BURST_PERIOD             = 0; // means no preference by initiator

} // namespace qc_loc_fw
#endif //#ifndef __LOWI_CONST_H__
