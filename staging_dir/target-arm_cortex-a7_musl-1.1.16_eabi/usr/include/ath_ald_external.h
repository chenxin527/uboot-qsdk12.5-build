/*****************************************************************************/
/* \file ath_ald_external.h
** \brief External Header File References
**
**  This header file refers to the internal header files that provide the
**  data structure definitions and parameters required by external programs
**  that interface via ioctl or similiar mechanisms.  This hides the location
**  of the specific header files, and provides a control to limit what is
**  being exported for external use.
**
**  Copyright (c) 2009 Atheros Communications Inc.  All rights reserved.
**
** Permission to use, copy, modify, and/or distribute this software for any
** purpose with or without fee is hereby granted, provided that the above
** copyright notice and this permission notice appear in all copies.
**
** THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
** WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
** MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
** ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
** WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
** ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
** OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
**/


#ifndef ATH_ALD_EXTERNAL_H
#define ATH_ALD_EXTERNAL_H

#define IEEE80211_IOCTL_ALD	        (SIOCIWFIRSTPRIV+25)
enum {
    IEEE80211_ALD_UTILITY = 0,
    IEEE80211_ALD_CAPACITY,
    IEEE80211_ALD_LOAD,
    IEEE80211_ALD_ALL,
    IEEE80211_ALD_MAXCU,
    IEEE80211_ALD_ASSOCIATE,
    IEEE80211_ALD_BUFFULL_WRN,
    IEEE80211_ALD_MCTBL_UPDATE,
    IEEE80211_ALD_CBS,
    IEEE80211_ALD_ERROR,
};

#define NETLINK_ALD 31

#if ATH_SUPPORT_HYFI_ENHANCEMENTS
#define MAX_NODES_NETWORK (64+1) // one is ap self
typedef struct _linkcapacity_t
{
    u_int32_t   capacity;   // Current number of bits per second that can be delivered to the given DA.
    u_int32_t   aggr;
    u_int32_t   phyerr;
    u_int32_t   lastper;
    u_int32_t   msdusize;
    u_int8_t    da[6];      // This link’s destination address.
    u_int16_t   nobufs[WME_NUM_AC]; /*#pkts lost due to buff overflows per ac*/
    u_int16_t   excretries[WME_NUM_AC];/* #pkts lost due to exc retries per ac*/
    u_int16_t   txpktcnt[WME_NUM_AC];/* #successfully transmitted pkts per ac*/
	u_int16_t	retries;
	u_int32_t	aggrmax;
} linkcapacity_t;

#define IEEE80211_ALD_STAT_UTILITY_UNCHANGED 0xFF
struct ald_stat_info {
    u_int32_t cmd;
    u_int8_t name[IFNAMSIZ];
    u_int32_t maxcu;
    u_int32_t utility;
    u_int32_t load;
    u_int32_t txbuf;
    u_int32_t curThroughput;
    u_int32_t vapstatus;

    u_int32_t nientry;
    linkcapacity_t lkcapacity[MAX_NODES_NETWORK];
};

enum {
    ALD_ACTION_ASSOC = 0,
    ALD_ACTION_DISASSOC,
    ALD_ACTION_MAX,
};

enum {
    ALD_FREQ_24G = 0,
    ALD_FREQ_5G,
    ALD_FREQ_MAX,
};

/**
 * @brief The type of the CBS event
 */
typedef enum ald_cbs_event_type {
    /// CBS has completed
    ALD_CBS_COMPLETE,
    /// CBS was cancelled before completion
    ALD_CBS_CANCELLED
} ald_cbs_event_type;

struct ald_assoc_info {
    u_int32_t cmd;
    u_int8_t name[IFNAMSIZ];
    u_int8_t macaddr[IEEE80211_ADDR_LEN];
    u_int8_t aflag;
    u_int8_t afreq;
};

struct ald_buffull_info {
    u_int32_t cmd;
    u_int8_t name[IFNAMSIZ];
    u_int16_t resv;
};

struct ald_cbs_info {
    u_int32_t cmd;
    u_int8_t name[IFNAMSIZ];
    ald_cbs_event_type type;
};

#endif


#endif
