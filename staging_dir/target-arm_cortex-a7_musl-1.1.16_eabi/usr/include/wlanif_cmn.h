/*
 * Copyright (c) 2017-2019 Qualcomm Technologies, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Technologies, Inc.
 */

#ifndef __WLANIF_CMN_H__
#define __WLANIF_CMN_H__

struct wlanif_config {
    void *ctx;
    uint32_t IsCfg80211;
    struct wlanif_config_ops *ops;
    int pvt_cmd_sock_id;
    int pvt_event_sock_id;
};

#if !SONLIB_SUPPORT_ENABLED
/// The number of bytes in a MAC address
#define IEEE80211_ADDR_LEN 6

/// The max SSID length in bytes
#define IEEE80211_NWID_LEN  32

#ifndef ACS_RANK_DESC_DBG_LEN
/// The max length in bytes for the ACS channel ranking description
#define ACS_RANK_DESC_DBG_LEN 80
#endif  // ACS_RANK_DESC_DBG_LEN

// This struct has to be a duplicate definition of ieee80211_neighbor_info
typedef struct ieee80211_neighbor_info_t {
    u_int32_t   phymode; /* ap channel width*/
    int32_t     rssi; /* ap singal strength */
    u_int8_t    bssid[IEEE80211_ADDR_LEN]; /* BSSID information */
    u_int8_t    ssid_len; /* length of the ssid */
    u_int8_t    ssid[IEEE80211_NWID_LEN + 1]; /* SSID details */
} ieee80211_neighbor_info_t;

// This struct has to be a duplicate definition as struct ieee80211req_athdbg
typedef struct ieee80211_acs_report_t {
    u_int8_t                nchans;
    u_int8_t                entry_id;
    u_int16_t               chan_freq;
    u_int8_t                ieee_chan;
    u_int8_t                chan_nbss;
    int32_t                 chan_maxrssi;
    int32_t                 chan_minrssi;
    int16_t                 noisefloor;
    int16_t                 channel_loading;
    u_int32_t               chan_load;
    u_int8_t                sec_chan;
    int32_t                 neighbor_size;
    ieee80211_neighbor_info_t *neighbor_list;
    u_int32_t               chan_80211_b_duration;
    /* ACS Channel Ranking structure
     *    rank: Channel Rank
     *    desc: Reason in case of no rank
     */
    struct acs_rank {
        u_int32_t rank;
        char desc[ACS_RANK_DESC_DBG_LEN];
    } acs_rank;
    u_int8_t                chan_in_pool;
    u_int8_t                chan_radar_noise;
    u_int8_t                chan_non_80211_noise; /* Not yet supported by HW */
    u_int32_t               chan_utilization;
    u_int32_t               chan_utilization_total;
    u_int32_t               chan_utilization_busy;
    u_int32_t               chan_utilization_busy_tx;
    u_int32_t               chan_utilization_busy_rx;
    u_int32_t               chan_utilization_busy_self;
    u_int32_t               chan_utilization_busy_ext;
    u_int8_t                acs_status;
} ieee80211_acs_report_t;

#define IEEE80211_RRM_CHAN_MAX 255
#define IEEE80211_MAX_REQ_IE 255

#define IEEE80211_BCNREQUEST_VALIDSSID_REQUESTED 0x01
#define IEEE80211_BCNREQUEST_NULLSSID_REQUESTED 0x02

#define IEEE80211_RRM_NUM_CHANREQ_MAX 5
#define IEEE80211_RRM_NUM_CHANREP_MAX 2

typedef struct wlanifBSteerEventsPriv_t *wlanifBSteerEventsHandle_t;

#endif /*SONLIB_SUPPORT_ENABLED*/

/* Netlink socket ports for different applications to bind to
 * These ports are reserved for these specific applications and
 * should take care not to reuse it.
 */
#define LBD_NL80211_CMD_SOCK      899
#define LBD_NL80211_EVENT_SOCK    900
#define WSPLCD_NL80211_CMD_SOCK   901
#define WSPLCD_NL80211_EVENT_SOCK 902
#define HYD_NL80211_CMD_SOCK      903
#define HYD_NL80211_EVENT_SOCK    904
#define IFACEMGR_NL80211_CMD_SOCK      950
#define IFACEMGR_NL80211_EVENT_SOCK    951
#define LIBSTORAGE_NL80211_CMD_SOCK    952
#define LIBSTORAGE_NL80211_EVENT_SOCK  953

struct wlanif_config_ops {
    int (* init) (struct wlanif_config *wext_conf);
    void (* deinit) (struct wlanif_config *wext_conf);
    int (* getName) (void *,const char *, char *);
    int (* isAP) (void *, const char *, uint32_t *);
    int (* getBSSID) (void *, const char *, struct ether_addr *BSSID );
    int (* getESSID) (void *, const char * , void *, uint32_t * );
    int (* getFreq) (void *, const char * , int32_t * freq);
    int (* getChannelWidth) (void *, const char *, int *);
    int (* getChannelExtOffset) (void *, const char *, int *);
    int (* getChannelBandwidth) (void *, const char *, int *);
    int (* getAcsState) (void *, const char *, int *);
    int (* getCacState) (void *, const char *, int *);
    int (* getParentIfindex) (void *, const char *, int *);
    int (* getSmartMonitor) (void *, const char *, int *);
    int (* getGenericInfoAtf) (void *, const char *, int, void *, int);
    int (* getGenericInfoAld) (void *, const char *, void *, int);
    int (* getGenericHmwds) (void *, const char *, void *, int);
    int (* getGenericNac) (void *, const char *, void *, int);
    int (* getCfreq2) (void *, const char * , int32_t *);
    int (* getChannelInfo) (void *, const char *, void *, int);
    int (* getChannelInfo160) (void *, const char *, void *, int);
    int (* getStationInfo) (void *, const char *, void *, int *);
    int (* getDbgreq) (void *, const char *, void *, uint32_t);
    int (* getExtended) (void *, const char *, void *, uint32_t);
    int (* addDelKickMAC) (void *, const char *, int , void *, uint32_t);
    int (* setFilter) (void *, const char *, void *, uint32_t);
    int (* getWirelessMode)(void *, const char *, void *, uint32_t);
    int (* sendMgmt) (void *, const char *, void *, uint32_t);
    int (* setParamMaccmd)(void *, const char *, void *, uint32_t);
    int (* setParam)(void *, const char *,int, void *, uint32_t);
    int (* getStaStats)(void *, const char *, void *, uint32_t);
    int (* getRange) (void *, const char * , int *);
    int (* getStaCount) (void *, const char *, int *);
    int (* getBandInfo) (void *ctx, const char * ifname, uint8_t * band_info);
    int (* getUplinkRate) (void *ctx, const char * ifname, uint16_t * ul_rate);
    int (* setUplinkRate) (void * ctx, const char *ifname, uint16_t ul_rate);
    int (* setSonBhType) (void * ctx, const char *ifname, uint8_t bh_type);
    int (* setParamVapInd)(void * ctx, const char *ifname, void *param, uint32_t len);
    int (* setFreq)(void *ctx, const char *ifname, int freq);

    /**
     * @brief Function to set interface mode
     *
     * @param [in] ctx     opaque pointer to private vendor struct
     * @param [in] ifname  interface name
     * @param [in] mode    the mode to set
     * @param [in] len     length of the mode string
     *
     * @return Success: 0, Failure: -1
     */
    int (* setIntfMode) (void *ctx, const char *ifname, const char *mode, u_int8_t len);

    /**
     * @brief Function to set center frequency segment 1 for VHT 80_80 operation
     *
     * @param [in] ctx        opaque pointer to private vendor struct
     * @param [in] ifname     interface name
     * @param [in] chanNum    channel number for segment 1 center frequency
     *
     * @return Success: 0, Failure: -1
     */
    int (* setCFreq2) (void *ctx, const char *ifname, int chanNum);

    /**
     * @brief Function to get the list of private ioctls
     *
     * The caller is responsible for freeing the allocated memory.
     *
     * @param [in] ctx  opaque pointer to private vendor struct
     * @param [in] ifname  interface name
     * @param [out] numIoctls  the number of ioctls for this interface
     *
     * @return pointer to the list of private ioctls on success, or NULL on failure
     */
    struct iw_priv_args* (* getPrivArgs ) (void *ctx, const char *ifname, size_t *numIoctls);

    /**
     * @brief Function to get ACS report after CBS
     *
     * @param [in] ctx  opaque pointer to private vendor struct
     * @param [in] ifname  interface name
     * @param [inout] numChans  the number of channels to report; on return, the
     *                          number of valid channels
     * @param [out] chanData  caller-provided array of channel data to
     *                        populate; this must be at least numChans in
     *                        length
     * @param [inout] numNeighbors  the number of neighbors to report; on return,
     *                              the number of valid neighbors
     * @param [out] neighborData  caller-provided array of neighbor data to
     *                            populate; this must be at least numNeighbors
     *                            in length
     * @param [out] neighborChans  caller-provided array of neighbor channels
     *                             to populate. The channels are in the same order
     *                             as entry in neighborData. Must be at least
     *                             numNeighbors in length
     *
     * @return 0 on success. Otherwise negative error code.
     */
    int (* getACSReport)(void *ctx, const char *ifName, u_int8_t* numChans,
                         ieee80211_acs_report_t chanData[], u_int8_t* numNeighbors,
                         ieee80211_neighbor_info_t neighborData[],
                         u_int8_t neighborChans[]);

};

/*enum to handle MAC operations*/
enum wlanif_ioops_t
{
    IO_OPERATION_ADDMAC=0,
    IO_OPERATION_DELMAC,
    IO_OPERATION_KICKMAC,
    IO_OPERATION_LOCAL_DISASSOC,
    IO_OPERATION_ADDMAC_VALIDITY_TIMER,
};

/* enum to handle wext/cfg80211 mode*/
enum wlanif_cfg_mode {
    WLANIF_CFG80211=0,
    WLANIF_WEXT
};

/**
 * @brief Get whether the Radio is tuned for low, high, full band or 2g.
 * the equivalent enum declared in ol_if_athvar.h and one-to-one mapping.
*/
typedef enum wlanifBandInfo_e {
    bandInfo_Unknown, /* unable to retrieve band info due to some error */
    bandInfo_High, /* supports channel starts from 100 to 165 */
    bandInfo_Full, /* supports channel starts from 36 to 165 */
    bandInfo_Low, /* supports channel starts from 36 to 64 */
    bandInfo_Non5G, /* supports 2g channel 1 to 14 */
} wlanifBandInfo_e;

/**
 * SON WiFi backhaul type is defined 1 and
 * Eth backhaul type is defined 2, PLC is defined as 3 respectively.
 */
typedef enum backhaulType_e {
    backhaulType_Unknown = 0,
    backhaulType_Wifi = 1,
    backhaulType_Ether = 2,
    bacckhaulType_Plc = 3,
} backhaulType_e;

extern struct wlanif_config * wlanif_config_init(enum wlanif_cfg_mode mode,
                                                 int pvt_cmd_sock_id,
                                                 int pvt_event_sock_id);
extern void wlanif_config_deinit(struct wlanif_config *);

#endif /* #define __WLANIF_CMN_H__ */
