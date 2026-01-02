/*
 * @File: ieee1905_vendor.h
 *
 * @Abstract: IEEE 1905.1 vendor specific header file.
 *
 * @Notes:
 *
 *  Copyright (c) 2011,2017 Qualcomm Technologies, Inc.
 *  All Rights Reserved.
 *  Confidential and Proprietary - Qualcomm Technologies, Inc.
 *
 *  2011 Qualcomm Atheros, Inc.
 *  All Rights Reserved.
 *  Qualcomm Atheros Confidential and Proprietary.
 *
 */

#ifndef ieee1905_vendor__h /*once only*/
#define ieee1905_vendor__h

#include "ieee1905_vendor_consts.h"

#define IEEE1905_QCA_OUI        "\x00\x03\x7f"

/*
 * QCA IEEE1905.1 Vendor Specific TLV
 */
typedef enum ieee1905QCAVendorSpecificType_e
{
    /* Any new TLV should be added as part of Version Specific.
     * Version Specific TLVs start from 64.
     * The new TLV should be added at the end of the list.
     */
    IEEE1905_QCA_TYPE_NULL,                 /* Null message. Used for PLC packet spoofing */
    IEEE1905_QCA_TYPE_INTERFACE_BITMAP,     /* Device's interface bitmap */
    IEEE1905_QCA_TYPE_TX_INTERFACE,         /* The interface used to transmit this message */
    IEEE1905_QCA_TYPE_DEVICE_FLAGS,         /* Device flags: HR, HC, can be further extended */
    IEEE1905_QCA_TYPE_BRIDGED_INTERFACES,   /* Bridged interfaces */
    IEEE1905_QCA_TYPE_EXT_LINK_METRICS,     /* Extended link metrics data */
    IEEE1905_QCA_TYPE_LOCAL_FLOWS,          /* List of local flows with rate above threshold */
    IEEE1905_QCA_TYPE_LOCAL_FLOW_RESPONSE,  /* Local flow response */
    IEEE1905_QCA_TYPE_RESPOND_NOW,          /* Ask remote devices to respond, used when hyd restarts/system reboots */
    IEEE1905_QCA_TYPE_WLAN_STA_ASSOC,       /* WLAN Station association */
    IEEE1905_QCA_TYPE_REMOTE_INTERFACE_DOWN,/* Remote interface down acceleration */
    IEEE1905_QCA_TYPE_IPV4_ADDRESS,         /* IPv4 address of the device */
    IEEE1905_QCA_TYPE_WLAN_INFO,            /* Wlan info */
    IEEE1905_QCA_TYPE_ASSOCIATED_STATIONS,  /* List of associated STAs on an AP */
    IEEE1905_QCA_TYPE_BSSID_SSID_MAPPING,   /* Map BSSID with SSID for each AP interface */
    IEEE1905_QCA_TYPE_ETH_UPSTREAM_DEV,     /* Share Ethernet Upstream device addresss */
    IEEE1905_QCA_TYPE_ASSOCIATED_STATIONS_WITH_AGE,  /* List of associated STAs on an AP
                                                        with a field that indicates how long
                                                        the STA has been associated */
    IEEE1905_QCA_TYPE_BACKHAUL,             /* Used for 2G, 5GLow, 5GHigh band Uplink rate for mixed backhaul */
    IEEE1905_QCA_TYPE_WLAN_STA_CLASS_GROUP, /* WLAN Client Classification Group */
    IEEE1905_QCA_TYPE_ASSOCIATED_STATIONS_WITH_CLASS,/* List of associated STAs on an AP
                                                        with a field that indicates the client
                                                        classification group */

    IEEE1905_QCA_TYPE_SYSTEM_INFO_REQ = 64,      /* Request the system parameters for steering */
    IEEE1905_QCA_TYPE_SYSTEM_INFO_RSP,           /* Overall system parameters */
    IEEE1905_QCA_TYPE_CSBC_CONFIG_PARAMS,        /* Client steering behavior classification
                                                    configuration */
    IEEE1905_QCA_TYPE_AVG_UTIL_REQ,              /* Request a local utilization report */
    IEEE1905_QCA_TYPE_AVG_UTIL_REPORT,           /* Local or aggregate utilization report */
    IEEE1905_QCA_TYPE_LOAD_BALANCING_ALLOWED,    /* Node is allowed to steer */
    IEEE1905_QCA_TYPE_LOAD_BALANCING_COMPLETE,   /* All steering has been attemped */
    IEEE1905_QCA_TYPE_STA_BAND_CAPABILITY,       /* Update to which bands a STA can use */
    IEEE1905_QCA_TYPE_STADB_DUMP_REQ,            /* Request dump of all STAs */
    IEEE1905_QCA_TYPE_STADB_DUMP_RSP,            /* List of all known STAs */
    IEEE1905_QCA_TYPE_STADB_AGING,               /* One or more STAs aged out */
    IEEE1905_QCA_TYPE_STA_INFO_REQ,              /* Request complete info for a STA */
    IEEE1905_QCA_TYPE_STA_INFO_RSP,              /* Share the complete info for a STA */
    IEEE1905_QCA_TYPE_STA_CSBC_STATE,            /* Client steering behavior classification
                                                    state for a single STA */
    IEEE1905_QCA_TYPE_PREPARE_FOR_STEERING_REQ,  /* Request blacklist installation */
    IEEE1905_QCA_TYPE_PREPARE_FOR_STEERING_RSP,  /* Indicate blacklist installation complete */
    IEEE1905_QCA_TYPE_AUTH_REJ_SENT,             /* Auth reject sent by this node */
    IEEE1905_QCA_TYPE_STEERING_ABORT_REQ,        /* Request steering be aborted */
    IEEE1905_QCA_TYPE_STEERING_ABORT_RSP,        /* Acknowledge steering was aborted */
    IEEE1905_QCA_TYPE_STA_POLLUTION_STATE,       /* Which channels are polluted */

    IEEE1905_QCA_TYPE_ATF_SSID_CFG,              /* ATF SSID configuration */
    IEEE1905_QCA_TYPE_ATF_PEER_CFG,              /* ATF PEER configuration */
    IEEE1905_QCA_TYPE_ATF_GROUP_CFG,             /* ATF GROUP configuration */
    IEEE1905_QCA_TYPE_ATF_RADIOPARAM_CFG,        /* ATF Radio params */

    IEEE1905_QCA_TYPE_CFG_ACK ,                  /* Ack to config receive */
    IEEE1905_QCA_TYPE_CFG_APPLY,                 /* Apply config and restart */

    IEEE1905_QCA_TYPE_ETH_CLIENT_DOWN,           /* Remote interface client down acceleration */

    IEEE1905_QCA_TYPE_PREPARE_FOR_MONITORING_REQ,/* Request monitoring installation */
    IEEE1905_QCA_TYPE_PREPARE_FOR_MONITORING_RSP,/* Indicate monitoring installation complete */
    IEEE1905_QCA_TYPE_MONITORING_ABORT_REQ,      /* Request monitoring be aborted */
    IEEE1905_QCA_TYPE_MONITORING_ABORT_RSP,      /* Acknowledge monitoring was aborted */
    IEEE1905_QCA_TYPE_AVG_RSSI_REQ,              /* Request a local rssi report */
    IEEE1905_QCA_TYPE_AVG_RSSI_REPORT,           /* Local rssi report */
    IEEE1905_QCA_TYPE_RAW_DATA,                  /* Send raw data to other devices */

    IEEE1905_QCA_TYPE_RESERVED /* Must be the last */

} ieee1905QCAVendorSpecificType_e;

typedef struct ieee1905QCAMessage_t
{
    u_int8_t oui[ IEEE1905_OUI_LENGTH ];
    u_int8_t type;

    u_int8_t content[ 0 ];

} __attribute__((packed)) ieee1905QCAMessage_t;

typedef struct ieee1905QCAInterfaceBitmaps_t
{
    u_int32_t interfaceConnected;                           /* Interface connection bitmap */
    u_int8_t  interfaceTypes[ IEEE1905_QCA_VENDOR_MAX_INTERFACE ]; /* Interface types */

} __attribute__((packed)) ieee1905QCAInterfaceBitmaps_t;


typedef struct ieee1905QCABridgedInterfaces_t
{
    u_int8_t numBridgedDAs;     /* Number of addresses in this message */
    u_int8_t updated;           /* Marks if fdb has been updated or not */

    u_int8_t bridgedDA[ 0 ];  /* Place holder for addresses, size should be 6*numBridgedDAs */

} __attribute__((packed)) ieee1905QCABridgedInterfaces_t;

typedef struct ieee1905QCAExtLinkMetrics_t
{
    struct ether_addr addr;

    u_int32_t TCPFullLinkCapacity;
    u_int32_t UDPFullLinkCapacity;
    u_int32_t TCPAvailableLinkCapacity;
    u_int32_t UDPAvailableLinkCapacity;

    u_int32_t reserved[ 4 ];                /* For future use, I have a feeling we will need it */

} __attribute__((packed)) ieee1905QCAExtLinkMetrics_t;

typedef struct ieee1905QCALocalFlowsInfo_t
{
    u_int8_t hash;
    u_int8_t ifaceType;
    struct ether_addr sa;
    struct ether_addr da;
    u_int32_t rate;

} __attribute__((packed)) ieee1905QCALocalFlowsInfo_t;

enum
{
    IEEE1905_QCA_LOCAL_FLOW_ACTION_CLEAR,
    IEEE1905_QCA_LOCAL_FLOW_ACTION_SET,

    IEEE1905_QCA_LOCAL_FLOW_ACTION_RESERVED
};

typedef struct ieee1905QCALocalFlowReponse_t
{
    u_int8_t hash;
    u_int8_t action;
    struct ether_addr sa;
    struct ether_addr da;

} __attribute__((packed)) ieee1905QCALocalFlowReponse_t;

/**
 * @brief Notification that a WLAN STA has associated on an 
 *        interface
 */
typedef struct ieee1905QCAWLANSTAAssoc_t
{
    /// STA that associated
    struct ether_addr staAddr;     

    /// MAC address of interface it associated on
    struct ether_addr ifaceAddr;
} __attribute__((packed)) ieee1905QCAWLANSTAAssoc_t;

/**
 * @brief Notification that a WLAN STA has associated on an
 *        interface and its Classification group needs
 *        to be updated
 */
typedef struct ieee1905QCAWLANSTAClassGroup_t
{
    /// STA that associated
    struct ether_addr staAddr;

    /// The Classificaiton group the STA belongs to
    u_int8_t clientClassGroup;
} __attribute__((packed)) ieee1905QCAWLANSTAClassGroup_t;

/*
 * @brief PHY capabilities on the WLAN interface, to be sent
 *        in IEEE1905_QCA_TYPE_WLAN_INFO TLV
 */
typedef struct ieee1905QCAWLANInfoPHYCap_t {
    /* Maximum bandwidth the client supports, valid values are enumerated
     * in enum ieee80211_cwm_width in _ieee80211.h. */
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
} __attribute__((packed)) ieee1905QCAWLANInfoPHYCap_t;

/**
 * @brief Extra WiFi info sent per interface (currently just the
 *        primary channel for each interface).
 */
typedef struct ieee1905QCAWLANInfoPerIntf_t
{
    /// The interface layer MAC address
    struct ether_addr interfaceMAC;

    /// Primary channel for that interface.
    u_int8_t primaryChannel;

    /// Flag indicating if this entry contains valid PHY capabilities
    u_int8_t validPHY;

    /// PHY capabilities on this WLAN interface
    ieee1905QCAWLANInfoPHYCap_t phyCapabilities[ 0 ];
} __attribute__((packed)) ieee1905QCAWLANInfoPerIntf_t;

/**
 * @brief Vendor Specific TLV carries 2G, 5GLow, 5GHigh band uplink rate
 *        for mixed back haul scenario.
 */
typedef struct ieee1905QCAMixedBackHaulVendorSpecific_t
{
    // Channel for 2G band
    u_int8_t channelId_2G;

    // 2G band uplink rate
    u_int16_t ulRate_2G;

    // Channel for 5G low band
    u_int8_t channelId_5GLow;

    // 5G low band uplink rate
    u_int16_t ulRate_5GLow;

    /*
     * 5 GHz high band channel number or the channel number
     * which radio that operates on the full 5GHz band.
     */
    u_int8_t channelId_5GHighOrFull;

    // 5G high band or 5G full band uplink rate
    u_int16_t ulRate_5GHighOrFull;
} __attribute__((packed)) ieee1905QCAMixedBackHaulVendorSpecific_t;

/**
 * @brief Vendor specific TLV conveying extra WiFi info
 *        (currently just the primary channel for each
 *        interface).
 */
typedef struct ieee1905QCAWLANInfo_t
{
    /// Number of WiFi interfaces
    u_int8_t numWlanIntf;

    /// Information per interface.
    ieee1905QCAWLANInfoPerIntf_t intfInfo[ 0 ];
} __attribute__((packed)) ieee1905QCAWLANInfo_t;

/**
 * @brief Vendor specific TLV conveying the list of associated STA MAC
 *        addresses for a single AP interface on the sending device.
 */
typedef struct ieee1905QCAAssociatedStations_t
{
    /// The interface layer MAC address of the AP interface to which all
    /// of the below stations are associated.
    struct ether_addr interfaceMAC;

    /// List of associated stations on this AP interface.
    struct ether_addr stationMACs[ 0 ];
} __attribute__((packed)) ieee1905QCAAssociatedStations_t;

// ====================================================================
// Definitions for the versioned messages
// ====================================================================

/**
 * @brief The major portion of the version number.
 *
 * Different major versions can have completely different definitions for
 * messages.
 */
typedef enum ieee1905QCAMajorVersion_e {
    ieee1905QCAMajorVersion1 = 1,
    ieee1905QCAMajorVersion2 = 2,
} ieee1905QCAMajorVersion_e;

/**
 * @brief The minor portion of the version number.
 *
 * A higher minor version can only add fields to a message. It cannot
 * remove or modify any fields defined by an earlier version.
 */
typedef enum ieee1905QCAMinorVersion_e {
    ieee1905QCAMinorVersion0 = 0,
} ieee1905QCAMinorVersion_e;

#define IEEE1905_QCA_VERSION_MAJOR_SHIFT 4
#define IEEE1905_QCA_VERSION_MINOR_SHIFT 0
#define IEEE1905_QCA_VERSION_COMPONENT_MASK 0xFF

// Pack the major/minor version numbers into a single value.
#define ieee1905QCAPackVersionNum(major, minor) \
    (((major & IEEE1905_QCA_VERSION_COMPONENT_MASK) \
        << IEEE1905_QCA_VERSION_MAJOR_SHIFT) | \
     ((minor & IEEE1905_QCA_VERSION_COMPONENT_MASK) \
        << IEEE1905_QCA_VERSION_MINOR_SHIFT))

// Extract the major and minor version numbers from the packed value.
#define ieee1905QCAExtractMajorVersionNum(version) \
    ((version >> IEEE1905_QCA_VERSION_MAJOR_SHIFT) \
        & IEEE1905_QCA_VERSION_COMPONENT_MASK)
#define ieee1905QCAExtractMinorVersionNum(version) \
    (version & IEEE1905_QCA_VERSION_COMPONENT_MASK)

#define IEEE1905_QCA_TLV_MIN_LEN    IEEE1905_TLV_LEN( sizeof(ieee1905QCAMessage_t) )

/* For versioned QCA TLV, add 1 byte for the version number */
#define IEEE1905_VERSION_QCA_TLV_MIN_LEN IEEE1905_TLV_LEN( sizeof(ieee1905QCAMessage_t) + sizeof(u_int8_t) )

/*
 * API
 */
#define ieee1905QCAIsQCAOUI( _oui ) \
    ( memcmp( _oui, IEEE1905_QCA_OUI, IEEE1905_OUI_LENGTH ) == 0 )

#define ieee1905QCAOUIAndTypeSet( _qcaMessage, _type, _total ) \
    do{ memcpy( (_qcaMessage)->oui, IEEE1905_QCA_OUI, IEEE1905_OUI_LENGTH ); (_qcaMessage)->type = _type; _total += IEEE1905_OUI_LENGTH + sizeof( u_int8_t ); } while(0)

#define ieee1905QCATypeGet( _qcaMessage ) \
    ( (_qcaMessage)->type )

#define ieee1905QCATypeSet( _qcaMessage, _type ) \
    ( (_qcaMessage)->type = _type )

#define ieee1905QCALenGet( _TLV ) \
    ( htons( (_TLV)->length ) - IEEE1905_OUI_LENGTH - sizeof( u_int8_t ) )

#define ieee1905QCAValGet( _qcaMessage ) \
    ( (_qcaMessage)->content )

#define ieee1905QCAValSet( _qcaMessage, _val, _len, _total ) \
    do{ memcpy((_qcaMessage)->content, (_val), (_len) ); _total += (_len ); } while(0)

#endif /* ieee1905_vendor__h */
