/*
 * Copyright (c) 2017-2019 Qualcomm Technologies, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Technologies, Inc.
 */

/* SON Libraries - Common header file */

#ifndef __SONLIB_CMN_H__
#define __SONLIB_CMN_H__
#include <net/if.h>
#include <bufrd.h>
#include <ieee80211_band_steering_api.h>
#define _LINUX_IF_H
#include <sys/socket.h>
#include <linux/socket.h>
#include <net/ethernet.h>
#include <dbg.h>

typedef enum wlan_band{
    band_24g,   ///< 2.4 GHz
    band_5g,    ///< 5 GHz
    band_invalid,  ///< band is not known or is invalid
}wlan_band;

struct soncmnDrvHandle {
    void *ctx;
    struct soncmnOps *ops;
};

int soncmnGetIfIndex(const char *ifname);

/* enum for vendors */
enum soncmnVendors {
    SONCMN_VENDOR_QTI = 0,
    SONCMN_VENDOR_ATHXK,
    SONCMN_VENDOR_BRCM,
    SONCMN_VENDOR_INTC,
    SONCMN_VENDOR_MTEK,
    SONCMN_VENDOR_RTEK,
    /* Add new vendor enums here */
    SONCMN_VENDOR_UNKNOWN,  // unknown vendor
    SONCMN_VENDOR_MAX /* This is always the last enum */
};

/* For debugging support */
struct soncmnDbg_t {
    struct dbgModule *dbgModule;
} soncmnDbgS;

typedef enum {
    SONCMN_OK = 0,
    SONCMN_NOK = -1
} SONCMN_STATUS;

// This is always enabled in QCA driver.
// TODO: Get this value from Makefile flags
#define QCN_IE 1

typedef struct wlanifBSteerEventsPriv_t *wlanifBSteerEventsHandle_t;
void wlanifBSteerEventsMsgRx(wlanifBSteerEventsHandle_t state,
                             const ath_netlink_bsteering_event_t *event);

typedef struct wlanifLinkEventsPriv_t * wlanifLinkEventsHandle_t;
typedef struct wlanifBSteerControlPriv_t  * wlanifBSteerControlHandle_t;

void wlanifLinkEventsCmnGenerateDisassocEvent(
        wlanifLinkEventsHandle_t state, void *event,
        int sysIndex);
void wlanifLinkEventsCmnProcessChannelChange(
        wlanifLinkEventsHandle_t state, void *event,
        u_int8_t band, int sysIndex);
void wlanifLinkEventsProcessChannelChange(
        int sysIndex, u_int8_t channel);

/***********************************************************************************/
/******** Soncmn structures used to commuinicate between driver and SON modules ****/
/***********************************************************************************/

/// The number of bytes in a MAC address
#define IEEE80211_ADDR_LEN 6

/// The max SSID length in bytes
#define IEEE80211_NWID_LEN  32

/// The max length in bytes for the ACS channel ranking description
#define ACS_RANK_DESC_DBG_LEN 48

// This struct has to be a duplicate definition of ieee80211_neighbor_info
typedef struct ieee80211_neighbor_info_t {
    u_int32_t   phymode; /* ap channel width*/
    int32_t     rssi; /* ap singal strength */
    u_int8_t    bssid[IEEE80211_ADDR_LEN];    /* BSSID information */
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

/*** Structure to pass Station Info ***/
struct soncmn_ieee80211_bsteering_datarate_info_t {
    /* Maximum bandwidth the client supports, valid values are enumerated
     * in enum ieee80211_cwm_width in _ieee80211.h. But the header file cannot
     * be included here because of potential circular dependency. Caller should
     * make sure that only valid values can be written/read. */
    u_int8_t max_chwidth;
    /* Number of spatial streams the client supports */
    u_int8_t num_streams;
    /* PHY mode the client supports. Same as max_chwidth field, only valid values
     * enumerated in enum ieee80211_phymode can be used here. */
    u_int8_t phymode;
    /* Maximum MCS the client supports */
    u_int8_t max_MCS;
    /* Maximum TX power the client supports */
    u_int8_t max_txpower;
    /* Set to 1 if this client is operating in Static SM Power Save mode */
    u_int8_t is_static_smps : 1;
    /* Set to 1 if this client supports MU-MIMO */
    u_int8_t is_mu_mimo_supported : 1;
};

struct soncmn_sta_info_t {
    /* Station mac address */
    u_int8_t stamac[6];
    /* Set to 1 if client is BTM capable */
    u_int8_t isbtm;
    /* Set to 1 if client is RRM capable */
    u_int8_t isrrm;
    /* Operating bands if sta is 2.4G or 5G or both */
    /* 0th bit - 2.4G band, 1st bit - 5G band */
    u_int8_t operating_band;
    /* When set to 1, datarateInfo below is valid, else ignore datarateInfo */
    u_int8_t phy_cap_valid;
    /* Rssi value */
    u_int8_t rssi;
    /* Data rate info as defined above */
    struct soncmn_ieee80211_bsteering_datarate_info_t datarateInfo;

    struct timespec isi_tr069_assoc_time;
};

#define SONCMN_MAX_STA_CLIENTS 1023
struct soncmn_req_stainfo_t {
    /* Total number of clients/stations */
    u_int8_t numSta;
    /* Info for each client/station */
    struct soncmn_sta_info_t stainfo[SONCMN_MAX_STA_CLIENTS];
};

/****** Structure to pass Station Stats *******/
struct soncmn_staStatsSnapshot_t {
    /// Number of bytes sent to the STA by this AP.
    u_int64_t txBytes;
    /// Number of bytes received from the STA by this AP.
    u_int64_t rxBytes;
    /// Last rate (in Kbps) at which packets sent to the STA by this AP were sent.
    u_int32_t lastTxRate;
    /// Last rate (in Kbps) at which the packets sent by the STA to this AP were sent.
    u_int32_t lastRxRate;
#ifdef WIFISON_SUPPORT_QSDK
    // total tx packets
    u_int32_t ns_tx_data;
    // Raw counter of the number of packets successfully sent
    u_int32_t ns_tx_data_success;

    // Raw counter of the number of packets received from the associated
    u_int32_t ns_rx_data;

    // rx TKIP MIC failure
    u_int32_t ns_rx_tkipmic;

    //  rx CCMP MIC failure
    u_int32_t ns_rx_ccmpmic;

    // rx WAPI MIC failure
    u_int32_t ns_rx_wpimic;

    // rx ICV check failed (TKIP)
    u_int32_t ns_rx_tkipicv;

    // rx decapsulation failed
    u_int32_t ns_rx_decap;

    // rx defragmentation failed
    u_int32_t ns_rx_defrag;

    u_int8_t ns_rssi;

    // Raw counter of the number of packets sent with the retry flag set
    u_int32_t ns_is_tx_not_ok;

    // time delta in ms between rssi measurement and IOCTL call
    u_int32_t ns_rssi_time_delta;
#endif
};

/***** Structure for Beacon Report Request  ****/
#define IEEE80211_RRM_CHAN_MAX 255
#define IEEE80211_MAX_REQ_IE 255

#define IEEE80211_BCNREQUEST_VALIDSSID_REQUESTED 0x01
#define IEEE80211_BCNREQUEST_NULLSSID_REQUESTED 0x02

#define IEEE80211_RRM_NUM_CHANREQ_MAX 5
#define IEEE80211_RRM_NUM_CHANREP_MAX 2

struct soncmn_ieee80211_beaconreq_chaninfo {
    /* Requglatory class to identify set of channels */
    u_int8_t regclass;
    /* Total number of channels */
    u_int8_t numchans;
    /* List of Channel numbers */
    u_int8_t channum[IEEE80211_RRM_NUM_CHANREQ_MAX];
};

/* Structure containing information for creating Measurement  */
/* request of type Beacon request. Different fields contain   */
/* info needed as per Measurement request element in 11k spec */
struct soncmn_ieee80211_rrm_beaconreq_info_t {
#define MAX_SSID_LEN 32
    // Number of repetitions for the measurement
    u_int16_t num_rpt;
    // Regulatory class identifying channel set
    // for which the measurement request applies
    u_int8_t regclass;
    // Channel number for the measurement
    u_int8_t channum;
    // Randomization Interval field specifies the upper bound of the random
    // delay to be used prior to making the measurement, in units of TUs
    u_int16_t random_ivl;
    // Measurement Duration field is set to the preferred or
    // mandatory duration of the requested measurement, in units of TUs
    u_int16_t duration;
    // Measurement Mode: Bits for Parallel, Enable, Request, report etc.
    // Default value used: 0
    u_int8_t reqmode;
    // Measurement request type: e.g. Beacon (5)
    u_int8_t reqtype;
    // BSSID for which a beacon report is requested
    u_int8_t bssid[6];
    // Beacon request Mode: Active, Passive, Beacon table
    u_int8_t mode;
    // Optional element: SSID subelement indicates the ESS for which
    // a beacon report is requested.
    u_int8_t req_ssid;
    // Optional Beacon Reporting subelement: reporting condition
    // indicates the condition for issuing a Beacon report
    u_int8_t rep_cond;
    // Option Beacon reporting subelement: reporting threshold value
    // to be used for conditional reporting
    u_int8_t rep_thresh;
    // Optional Reporting Detail subelement defines the level of
    // detail per AP to be reported to the requesting STA
    u_int8_t rep_detail;
    // Optional Request sublement
    u_int8_t req_ie;
    // Optional subelement: Last Beacon Report Indicator
    u_int8_t    lastind;
    // Optional subelement: AP Channel Report (indicates if
    // additional channels are provided for measurement)
    u_int8_t num_chanrep;
    // List of additional channels for iterative measurement
    // Measurement is done on these only when one or more AP Channel
    // Report elements are included in the request
    struct soncmn_ieee80211_beaconreq_chaninfo apchanrep[IEEE80211_RRM_NUM_CHANREP_MAX];
    // Optional element: ssid_len subelement indicates the length of the SSID for which
    // a beacon report is requested.
    u_int8_t ssidlen;
    // Optional element: SSID subelement indicates the SSID for which
    // a beacon report is requested.
    u_int8_t ssid[MAX_SSID_LEN];
    // Optional element: Request subelement length
    u_int8_t req_ielen;
    // Optional element: Request element list to be included in beacon report
    u_int8_t req_iebuf[IEEE80211_MAX_REQ_IE];
#undef MAX_SSID_LEN
};

/**** Structure for BTM Request ****/
/* candidate BSSID for BSS Transition Management Request */
struct soncmn_ieee80211_bstm_candidate {
    /* candidate BSSID */
    u_int8_t bssid[6];
    /* channel number for the candidate BSSID */
    u_int8_t channel_number;
    /* preference from 1-255 (higher number = higher preference) */
    u_int8_t preference;
    /* operating class */
    u_int8_t op_class;
    /* PHY type */
    u_int8_t phy_type;
};

/* maximum number of candidates in the list.  Value 3 was selected based on a
   2 AP network, so may be increased if needed */
#define SONCMN_IEEE80211_BSTM_REQ_MAX_CANDIDATES 3
/* BSS Transition Management Request information that can be specified via ioctl */
struct soncmn_ieee80211_bstm_reqinfo_target {
    u_int8_t dialogtoken;
    u_int8_t num_candidates;
#if QCN_IE
    /*If we use trans reason code in QCN IE */
    u_int8_t qcn_trans_reason;
#endif
    u_int8_t trans_reason;
    u_int8_t disassoc;
    u_int16_t disassoc_timer;
    struct soncmn_ieee80211_bstm_candidate candidates[SONCMN_IEEE80211_BSTM_REQ_MAX_CANDIDATES];
};

/* Multiple AP Sig related data structures */
#define SONCMN_MAX_HE_MCS 12
#define SONCMN_MAX_OP_CHANNELS 4
#define SONCMN_MAX_CHANNELS_PER_OP_CLASS 16

#define SONCMN_MAX_OPERATING_CLASSES 16

/**
 * @brief The HE capabilities for a specific radio on an AP
 */
struct soncmn_ap_he_capabilities_t {
    /// Number of supported HE MCS entries
    u_int8_t numMCSEntries;

    /// Supported HE MCS indicating set of supported HE Tx and Rx MCS
    u_int8_t supportedHeMCS[SONCMN_MAX_HE_MCS];

    /// Maximum number of supported Tx spatial streams
    u_int8_t maxTxNSS;

    /// Maximum number of supported Rx spatial streams
    u_int8_t maxRxNSS;

    /// HE support for 80+80 MHz
    u_int8_t support80p80Mhz : 1;

    /// HE support for 160 MHz
    u_int8_t support160Mhz : 1;

    /// SU beamformer capable
    u_int8_t suBeamformerCapable : 1;

    /// MU beamformer capable
    u_int8_t muBeamformerCapable : 1;

    /// UL MU-MIMO capable
    u_int8_t ulMuMimoCapable : 1;

    /// UL MU-MIMO + OFDMA capable
    u_int8_t ulMuMimoOfdmaCapable : 1;

    /// DL MU-MIMO + OFDMA capable
    u_int8_t dlMuMimoOfdmaCapable : 1;

    /// UL OFDMA capable
    u_int8_t ulOfdmaCapable : 1;

    /// DL OFDMA capable
    u_int8_t dlOfdmaCapable : 1;

    u_int8_t reserved : 7;
};

/**
 * @brief The basic capabilities for a specific radio on an AP
 *
 * @warning Same structure is used in driver api any change here should be done
 * in driver as well.
 */
struct soncmn_ap_radio_basic_capabilities_t {
    /// Maximum number of BSSes supported by this radio
    u_int8_t maxSupportedBSS;

    /// Number of operating classes supported for this radio
    u_int8_t numSupportedOpClasses;

    /// Info for each supported operating class
    struct {
        /// Operating class that this radio is capable of operating on
        /// as defined in Table E-4.
        u_int8_t opClass;

        /// Maximum transmit power EIRP the radio is capable of transmitting
        /// in the current regulatory domain for the operating class.
        /// The field is coded as 2's complement signed dBm.
        int8_t maxTxPwrDbm;

        /// Number of statically non-operable channels in the operating class
        /// Other channels from this operating class which are not listed here
        /// are supported by this radio.
        u_int8_t numNonOperChan;

        /// Channel number which is statically non-operable in the operating class
        /// (i.e. the radio is never able to operate on this channel)
        u_int8_t nonOperChanNum[SONCMN_MAX_CHANNELS_PER_OP_CLASS];
    } opClasses[SONCMN_MAX_OPERATING_CLASSES];
};

/**
 * @brief The HT capabilities for a specific radio on an AP
 */
struct soncmn_ap_ht_capabilities_t {
    /// Maximum number of supported Tx spatial streams
    u_int8_t maxTxNSS;

    /// Maximum number of supported Rx spatial streams
    u_int8_t maxRxNSS;

    /// Short GI support for 20 MHz
    u_int8_t shortGiSupport20Mhz : 1;

    /// Short GI support for 40 MHz
    u_int8_t shortGiSupport40Mhz : 1;

    // HT support for 40 MHz
    u_int8_t htSupport40Mhz : 1;

    u_int8_t reserved : 5;
};

/**
 * @brief The VHT capabilities for a specific radio on an AP
 */
struct soncmn_ap_vht_capabilities_t {
    /// Supported VHT Tx MCS
    /// Supported set to VHT MCSs that can be received.
    /// Set to Tx VHT MCS Map field per Figure 9-562.
    u_int16_t supportedTxMCS;

    /// Supported VHT Rx MCS
    /// Supported set to VHT MCSs that can be transmitted.
    /// Set to Rx VHT MCS Map field per Figure 9-562.
    u_int16_t supportedRxMCS;

    /// Maximum number of supported Tx spatial streams
    u_int8_t maxTxNSS;

    /// Maximum number of supported Rx spatial streams
    u_int8_t maxRxNSS;

    /// Short GI support for 80 MHz
    u_int8_t shortGiSupport80Mhz : 1;

    /// Short GI support for 160 and 80+80 MHz
    u_int8_t shortGiSupport160Mhz80p80Mhz : 1;

    /// VHT support for 80+80 MHz
    u_int8_t support80p80Mhz : 1;

    /// VHT support for 160 MHz
    u_int8_t support160Mhz : 1;

    /// SU beamformer capable
    u_int8_t suBeamformerCapable : 1;

    /// MU beamformer capable
    u_int8_t muBeamformerCapable : 1;

    u_int8_t reserved : 2;
};

/**
 * @brief Set of capabilities information about a Wi-Fi radio.
 */
struct soncmn_radio_capabilities_info_t {
    /// Flags indicating whether the capabilities are valid
    u_int8_t radioBasicCapabilitiesValid : 1;
    u_int8_t htCapabilitiesValid : 1;
    u_int8_t vhtCapabilitiesValid : 1;
    u_int8_t heCapabilitiesValid : 1;
    u_int8_t reserved : 4;

    /// AP basic capabilities supported by this interface
    struct soncmn_ap_radio_basic_capabilities_t radioBasicCapabilities;

    /// AP HT capabilities supported by this interface
    struct soncmn_ap_ht_capabilities_t htCapabilities;

    /// AP VHT capabilities supported by this interface
    struct soncmn_ap_vht_capabilities_t vhtCapabilities;

    /// AP HE capabilities supported by this interface
    struct soncmn_ap_he_capabilities_t heCapabilities;
};

struct soncmn_map_rssi_policy_t {
    /// STA metrics reporting RSSI threshold
    u_int8_t rssi;

    /// STA Metrics Reporting RSSI Hysteresis Margin Override
    u_int8_t rssi_hysteresis;
};

#define SONCMN_IEEE80211_ADDR_LEN 6

typedef struct soncmn_client_assoc_req_acl_t {
    /// STA MAC
    u_int8_t stamac[SONCMN_IEEE80211_ADDR_LEN];

    /// Validity Period
    u_int16_t validity_period;
} soncmn_client_assoc_req_acl_t;

/**
 * @brief Estimated Service Parameters Information Field. store the data Info
 * the natural (aka. native) representation rather than the OTA encoding and
 * convert them to/from the OTA encoding at the messaging layer (mapServiceMsg).
 */
typedef struct soncmn_map_esp_info_t {
    /// Whether the ESP Info for this AC is included
    u_int32_t includeESPInfo : 1;

    /// Access Category to which the remaning parameters belong to.
    /// Encoding is AC_BK = 0, AC_BE = 1, AC_VI = 2 AC_VO = 3.
    /// Refer Table 9-260
    u_int8_t ac : 2;

    /// Data format encoding is as in Table 9-261.
    u_int8_t dataFormat : 2;

    /// BA window size indicates the size of Block Ack window.
    /// Reflects actual MPDU counts.
    u_int8_t baWindowSize;

    /// The Estimated Air Time Fraction
    u_int8_t estAirTimeFraction;

    /// The Data PPDU Duration Target
    u_int16_t dataPPDUDurTarget;
} soncmn_map_esp_info_t;

/* Ops structure: API function pointers */
/* NOTE: Mapping to vendor APIs should be in same seqeunce and order as defined here */
/* 3rd party vendor should implement No-Op if not implementing an API */
struct soncmnOps {
    int (* init) (struct soncmnDrvHandle *handle, char *);
    void (* deinit) (struct soncmnDrvHandle *handle);
    int (* getName) (const void *,const char *, char *, size_t len);
    int (* getBSSID) (const void *, const char *, struct ether_addr *bssid );
    int (* getSSID) (const void *, const char * , void *, u_int32_t *);
    int (* isAP) (const void *, const char *, u_int32_t *result);
    int (* getFreq) (const void *, const char *, int32_t * freq);
    int (* getIfFlags) (const void *, const char * , struct ifreq *ifr );
    int (* getAcsState) (const void *, const char *, int * acsstate);
    int (* getCacState) (const void *, const char *, int * cacstate);
    int (* setBSteerAuthAllow) (const void *, const char *, const u_int8_t *dest_addr, u_int8_t authAllow);
    int (* setBSteerProbeRespWH) (const void *, const char *, const u_int8_t *dest_addr, u_int8_t probeRespWHEnable);
    int (* setBSteerProbeRespAllow2G) (const void *, const char *, const u_int8_t *dest_addr, u_int8_t allowProbeResp2G);
    int (* setBSteerOverload) (const void *, const char *, u_int8_t setOverload);
    int (* performLocalDisassoc) (const void *, const char *, const u_int8_t *dest_addr);
    int (* performKickMacDisassoc) (const void *, const char *, const u_int8_t *dest_addr);
    int (* setBSteering) (const void *, const char *, u_int8_t bSteerEnable); //per radio
    int (* setBSteerEvents) (const void *, const char *, u_int8_t bSteerEventsEnable); //per VAP
    int (* setBSteerInProgress) (const void *, const char *, const u_int8_t *dest_addr, u_int8_t bSteerInProgress); //InProgress flag
    int (* setBSteerParams) (const void *, const char *, void *data, u_int32_t data_len); //static config params
    int (* getBSteerRSSI) (const void *, const char *, const u_int8_t *dest_addr, u_int8_t numSamples);
    int (* getDataRateInfo) (const void *, const char *, const u_int8_t *dest_addr, struct soncmn_ieee80211_bsteering_datarate_info_t *);
    int (* getStaInfo) (const void *, const char *, struct soncmn_req_stainfo_t *getStaInfo);
    int (* getStaStats) (const void *, const char *, const u_int8_t *dest_addr, struct soncmn_staStatsSnapshot_t *);
    int (* setAclPolicy) (const void *, const char *, int aclCmd);
    int (* sendBcnRptReq) (const void *, const char *, const u_int8_t *dest_addr, struct soncmn_ieee80211_rrm_beaconreq_info_t *bcnreq);
    int (* sendBTMReq) (const void *, const char *, const u_int8_t *dest_addr, struct soncmn_ieee80211_bstm_reqinfo_target *btmreq);
    int (* setMacFiltering) (const void *, const char *, const u_int8_t *stamac , u_int8_t isAdd);
    int (* getChannelWidth) (const void *, const char *, int *chwidth);
    int (* getOperatingMode) (const void *, const char *, int *opMode);
    int (* getChannelExtOffset) (const void *, const char *, int *choffset);
    int (* getCenterFreq160) (const void *, const char *, u_int8_t channum, u_int8_t *cfreq);
    int (* getCenterFreqSeg1) (const void *, const char *, int32_t *cFreqSeg1);
    int (* getCenterFreqSeg0) (const void *, const char *, u_int8_t channum, u_int8_t *cFreqSeg0);
    int (* enableBSteerEvents) (u_int32_t sysIndex);
    int (* dumpAtfTable) (const void *, const char *, void *atfInfo, int32_t len);
    int (* getStaCount) (const void *, const char *, int *result);
    int (* getClientCap)(const void *ctx, const char *ifname, const struct ether_addr *clientAddr, u_int16_t *bufferLen, u_int8_t *buffer);
    int (* getOperableChannels)(const void *ctx, const char *ifname, u_int8_t opclass, u_int8_t *num_oper_chan, u_int8_t oper_chan_num[], u_int8_t *ch_width);

     /**
     * @brief  Function to get operating class information
     *
     * @param [in] ctx  opaque pointer to private vendor struct
     * @param [in] ifname  interface name
     * @param [in] opclass  the op class being queried
     * @param [inout] num_chan  the number of channels in the op class
     * @param [out] channels  array to fill the channel numbers in the op class
     * @param [out] ch_width  the channel width of the opclass
     * @param [out] sc_loc  location of the secondary channel relative to primary
     *                      chan: +1 if sec chan is above pri chan, -1 if below.
     *                      0 otherwise.
     *
     * @return Success: 0, Failure: -1
     */
    int (* getOpClassInfo)(const void *ctx, const char *ifname, u_int8_t opclass, u_int8_t *num_chan, u_int8_t channels[], u_int8_t *ch_width, int8_t *sc_loc);
    int (* getRadioHwCap)(const void *ctx, const char *ifname, struct soncmn_radio_capabilities_info_t *radio);
    int (* setRssiMetrics)(const void *ctx, const char *ifname, const u_int8_t *dest_addr, struct soncmn_map_rssi_policy_t mapRssiPolicy);
    int (* setMacBlockTimer) (const void *, const char *, const u_int8_t *stamac , struct soncmn_client_assoc_req_acl_t client_assoc_req);

    /**
     * @brief Function to set interface mode
     *
     * @param [in] ctx     opaque pointer to private vendor struct
     * @param [in] ifname  interface name
     * @param [in] mode    the mode to set
     * @param [in] len     length of the mode string

     * @return Success: 0, Failure: -1
     */
    int (* setIntfMode) (const void *ctx, const char *ifname, const char *mode, u_int8_t len);

    /**
     * @brief Function to set center frequency segment 1 for VHT 80_80 operation
     *
     * @param [in] ctx        opaque pointer to private vendor struct
     * @param [in] ifname     interface name
     * @param [in] chanNum    channel number for segment 1 center frequency
     *
     * @return Success: 0, Failure: -1
     */
    int (* setCenterFreqSeg1) (const void *ctx, const char *ifname, int chanNum);

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
    struct iw_priv_args* (* getPrivArgs )(const void *ctx, const char *ifname, size_t *numIoctls);

     /**
     * @brief Function to set a parameter using IEEE80211_IOCTL_SETPARAM
     *
     * @param [in] ctx  opaque pointer to private vendor struct
     * @param [in] ifname  interface name
     * @param [in] cmd  command ID corresponding to the parameter
     * @param [in] param  value of the parameter to be set
     * @param [in] len  length of the parameter value
     *
     * @return Success: 0, Failure: -1
     */
    int (* setParam)(void *ctx, const char *ifname, int cmd, void *param, u_int32_t len);

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

    int (* getEspInfo) (const void *, const char *, u_int8_t, soncmn_map_esp_info_t *espInfo);
};

/***********************************************************************/
/***** Structures/functions for Ifname-Vendor-DrvHandle mapping ********/
/***********************************************************************/

/**
 * @brief Function to obtain LBD Event handler opaque pointer
 *        Used by vendor modules for handling events from driver
 *
 */
void * soncmnGetLbdEventHandler(void);

/**
 * @brief Function called by LBD to provide Event Handler
 *        pointer to SON Lib, used later to handle events
 *
 * @param [in] evHandler   opaque pointer to LBD event Handler
 *
 */
extern void soncmnSetLbdEventHandler(void *evHandler);

extern void soncmnSetLbdLinkHandler(void *evHandler);

void *soncmnGetLbdControlHandler(void);

void *soncmnGetLbdLinkHandler(void);

/**
 * @brief Function to create ifname, vendor, drvHandle mappings
 *        Called by HYD/LBD during its Init. Goes through list of
 *        ifnames in config file, creating corresponding drvHandles
 *
 * @param [in] wlanInterfaces wlanIfname-to-radio mapping from config file
 * @param [in] radioVendorMap  radio-to-vendor mapping from config file
 * @param [in] isHYD  flag to indicate if HYD is running
 * @param [in] isLBD  flag to indicate if LBD/WLB is running
 *
 */
extern void soncmnIfnameVendorMapResolve(const char*, const char*, u_int8_t, u_int8_t);

/**
 * @brief Function to get DrvHandle for a given Ifname
 *
 * @param [in] ifname  wlan interface name
 *
 * @return Driver Handle for this ifname
 *
 */
extern struct soncmnDrvHandle * soncmnGetDrvHandleFromIfname(const char *);

/**
 * @brief Function to get Vendor name for a given Ifname
 *
 * @param [in] ifname  wlan interface name
 *
 * @return Vendor integer as per enum soncmnVendors
 *
 */
extern enum soncmnVendors soncmnGetVendorFromIfname(const char *ifname);

/**
 * @brief Function to get Vendor name for a given Radio Name
 *
 * @param [in] ifname  wlan radio name (wifi0, wifi1..)
 *
 * @return Vendor integer as per enum soncmnVendors
 *
 */
extern enum soncmnVendors soncmnGetVendorFromRadioName(const char *radioName);

/**
 * @brief Function to free up memory for DrvHandle
 *        and any private memory allocated by vendor
 *        by calling vendor specific deInit
 *
 * @param [in] drvHandle  vendor specific drvHandle
 *
 */
extern void soncmnDeinit(struct soncmnDrvHandle *);

/***************************************************************/
/************ Enums used by SON modules ************************/
/***************************************************************/

#define MAX_VAP_PER_BAND 16
#define INTFNAMESIZE 16 /* if name, e.g. "en0" */
#define MAX_RADIOS 3 /* Max tri-radio platforms */
#define MIN_NUM_IFACES 2 /* Minimum 1 interface per band (2G and 5G) */


#endif /* #define __SONLIB_CMN_H__ */
