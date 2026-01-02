/*
* Copyright (c) 2016, 2018 Qualcomm Innovation Center, Inc.
* All Rights Reserved.
* Confidential and Proprietary - Qualcomm Innovation Center, Inc.
*
*/

/*
* 2016 Qualcomm Atheros, Inc.
* All Rights Reserved.
* Qualcomm Atheros Confidential and Proprietary.
*/

#ifndef __EXT_IOCTL_DRIVER_IF_H
#define __EXT_IOCTL_DRIVER_IF_H

#include "qwrap_structure.h"
#define IEEE80211_CHANNEL_MIN_2G            1
#define IEEE80211_CHANNEL_MAX_2G            14

#define IEEE80211_CHANNEL_MIN_5G            36
#define IEEE80211_CHANNEL_MAX_5G            165

#define IEEE80211_CHANNEL_MAX               IEEE80211_CHANNEL_MAX_5G

#define CHAN_SCAN_MAX                       32
#define MAX_SSID_LENGTH                     32
#define BSSID_LEN                           6
#define IEEE80211_DEFAULT_CHANSWITCH_COUNT  IEEE80211_RADAR_11HCOUNT

#define NUM_MAX_CHANNELS    (255)

#define SCAN_CHANNEL_MASK         0x0000ffff
#define SCAN_CHANNEL_WIDTH_MASK   0xffff0000
#define SCAN_CHANNEL_WIDTH_SHIFT  16

typedef enum _wifi_operating_chanwidth
{
    WIFI_OPERATING_CHANWIDTH_20MHZ = 0,               /* 20 MHz chan width */
    WIFI_OPERATING_CHANWIDTH_40MHZ,                   /* 40 MHz chan width */
    WIFI_OPERATING_CHANWIDTH_80MHZ,                   /* 80 MHz chan width */
    WIFI_OPERATING_CHANWIDTH_160MHZ,                  /* 160 MHz chan width */
    WIFI_OPERATING_CHANWIDTH_80_80MHZ,                /* 80 + 80 MHz chan width */
    WIFI_OPERATING_CHANWIDTH_MAX_ELEM,                /* Number of elements in enum */
} wifi_operating_chanwidth_t;

typedef enum _wifi_sec_chan_offset
{
    WIFI_SEC_CHAN_OFFSET_NA       = 0,  /* No secondary channel */
    WIFI_SEC_CHAN_OFFSET_IS_PLUS  = 1,  /* Secondary channel is above primary channel */
    WIFI_SEC_CHAN_OFFSET_IS_MINUS = 3,  /* Secondary channel is below primary channel */
} wifi_sec_chan_offset_t;

typedef struct ieee80211_chanlist_r {
    u_int8_t  n_chan; /* Number of IEEE802.11 Channels*/
    u_int8_t chan[CHAN_SCAN_MAX];   /* List of channel */
    u_int8_t chan_width[CHAN_SCAN_MAX];/* chanel width used for scan */
    u_int8_t sec_chan_offset[CHAN_SCAN_MAX]; /* Secondary channel offset*/
} ieee80211_chanlist_t;

typedef struct _ssid_info
{
    /* SSID of target Root AP */
    u_int8_t ssid[MAX_SSID_LENGTH];

    /* SSID length */
    u_int8_t ssid_len;
} ssid_info_t;

typedef struct _wifi_scan_custom_request_cmd {
    /* Max Dwell time on each scan channel in ms. */
    u_int32_t           max_dwell_time;
    /* Min Dwell time on each scan channel in ms. */
    u_int32_t           min_dwell_time;
    /* Time in ms between two channel scans.
     * Applicable only if num_channel is more than one
     */
    u_int32_t           rest_time;
    u_int32_t           idle_time;
    u_int32_t           max_scan_time;
    /* Scan mode: 0: passive, 1: active. */
    u_int8_t            scan_mode;
    /* user channel list */
    ieee80211_chanlist_t chanlist;
    /* 1: Wide band scan 0: normal scan*/
    u_int8_t            wide_band;
} wifi_scan_custom_request_cmd_t;


typedef struct _wifi_channel_switch_request {
    /* 0: 20 MHz, 1: 40 MHz, 2: 80 MHz, 3: 160 MHz, 4: 80+ 80MHz. */
    wifi_operating_chanwidth_t  target_chanwidth;
    /* Target primary channel number */
    u_int32_t                   target_pchannel;
    /* Centre frequency for secondary 80 MHz channel.
     * Used only for 80 + 80 MHz. must be set 0 otherwise.
     */
    u_int32_t                   target_cfreq2;
    /* 0: secondary 20 chhannel is not applicable,
     * 1: secondary 20 channel is a plus,
     * 3: secondary 20 channel is a minus.
     */
    wifi_sec_chan_offset_t      sec_chan_offset;
    /* Number of channel switch announcements to be sent
     * before channel change is triggered.
     */
    u_int8_t                    num_csa;
} wifi_channel_switch_request_t;

typedef struct _wifi_repeater_move_request {

    /* Channel switch request structure that will hold -
     * Target Root AP Channel Number
     * Centre frequency for secondary 80MHz channel
     * Target Channel Width
     * Number of channel switch announcements
     * Secondary channel offset
     */
    wifi_channel_switch_request_t chan_switch_req;

    /* SSID information for the target Root AP */
    ssid_info_t                   target_ssid;

    /* BSSID information for the target Root AP */
    u_int8_t                      target_bssid[BSSID_LEN];
} wifi_repeater_move_request_t;

/**
 * struct extacs_chan_info - channel info
 * @cycle_count:                Cycle count
 * @channel_load:               Channel load
 * @period:                     Period
 * @noisefloor:                 Noise floor
 * @comp_usablity:              Computed usability
 * @max_regulatory_power:       Maximum allowed regulatory power
 * @comp_usablity_sec80:        Computed usability of secondary 80 Mhz
 * @max_regulatory_power_sec80: Max regulatory power of secondary 80 Mhz
 * @tx_power_tput:              Tx power used for the channel, with emphasis on
 * throughput
 * @tx_power_range:             Tx power used for the channel, with emphasis on
 * range
 */
struct extacs_chan_info {
    int          cycle_count;
    int          channel_load;
    int          period;
    int          noisefloor;
    u_int16_t    comp_usablity;
    int8_t       max_regulatory_power;
    u_int16_t    comp_usablity_sec80;
    int8_t       max_regulatory_power_sec80;
    int32_t      tx_power_tput;
    int32_t      tx_power_range;
};

struct extended_ioctl_wrapper {
    u_int32_t   cmd;
    union {
        wifi_channel_switch_request_t channel_switch_req;
        wifi_scan_custom_request_cmd_t channel_scan_req;
        wifi_repeater_move_request_t rep_move_req;
        struct thermal_param get_param;
        struct th_config_t  th_config;
        struct qwrap_config_t qwrap_config;
        struct iface_config_t iface_config;
    }ext_data;
    void *data;
    u_int32_t   data_len;
};

#endif /* __EXT_IOCTL_DRIVER_IF_H */
