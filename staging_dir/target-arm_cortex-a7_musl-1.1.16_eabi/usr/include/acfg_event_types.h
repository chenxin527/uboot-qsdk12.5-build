/*
 * Copyright (c) 2017, 2019 Qualcomm Innovation Center, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 *
 * Copyright (c) 2008-2010, Atheros Communications Inc.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifndef __ACFG_EVENT_TYPES_H
#define __ACFG_EVENT_TYPES_H

enum acfg_device_state {
    ACFG_DEVICE_STATE_UNKNOWN    = 0x00,
    ACFG_DEVICE_STATE_RESET      = 0x01,
    ACFG_DEVICE_STATE_READY      = 0x02,
    ACFG_DEVICE_STATE_ERROR      = 0xFF,
};
typedef uint32_t  acfg_device_state_t;

/**
 * @brief Target State Change Event Data
 */
typedef struct acfg_device_state_data {
    acfg_device_state_t     prev_state;     /**< previous state of target */
    acfg_device_state_t     curr_state;     /**< new current state of target */
} acfg_device_state_data_t;

/**
 * @brief Association status
 */
enum acfg_assoc_status {
    ACFG_ASSOC_SUCCESS  = 0,    /**< Assoc completed */
    ACFG_ASSOC_FAILED   = 1,    /**< Unspecified failure */
    ACFG_ASSOC_LEAVE    = 2,    /**< Peer left */
};
typedef uint32_t  acfg_assoc_status_t;

/**
 * @brief De authentication Reason
 */
typedef uint32_t  acfg_dauth_reason_t;
typedef uint32_t  acfg_reason_t;


/**
 * @brief Mode of receiving events
 */
enum acfg_event_mode {
    ACFG_EVENT_BLOCK    = 0x1,  /**< Recv Event Blocks */
    ACFG_EVENT_NOBLOCK  = 0x2   /**< Recv Event Unblocks */
};
typedef uint32_t acfg_event_mode_t;

/**
 * @brief Creat Vap event structure
 */
typedef struct acfg_create_vap {
    uint8_t   wifi_index;
    uint8_t   vap_index;
    uint8_t   if_name[ACFG_MAX_IFNAME];
    uint8_t   mac_addr[ACFG_MACADDR_LEN];
} acfg_create_vap_t;

/**
 * @brief Restore wifi event structure
 */
typedef struct acfg_restore_wifi {
    uint8_t   wifi_index;
    uint8_t   if_name[ACFG_MAX_IFNAME];
    uint8_t   mac_addr[ACFG_MACADDR_LEN];
} acfg_restore_wifi_t;

/**
 * @brief Association Done event structure
 */
typedef struct acfg_assoc_sta {
    acfg_assoc_status_t     status;                 /**< Assoc Status */
    acfg_ssid_t             ssid;                   /**< SSID */
    uint8_t               bssid[ACFG_MACADDR_LEN];/**< MAC Addr */
} acfg_assoc_sta_t;

/**
 * @brief Association Done event structure
 */
typedef struct acfg_assoc_ap {
    acfg_assoc_status_t     status;                 /**< Assoc Status */
    uint8_t               bssid[ACFG_MACADDR_LEN];/**< MAC Addr */
} acfg_assoc_ap_t;

/**
 * @brief De-Authentication event from AP
 */
typedef struct acfg_dauth {
    acfg_ssid_t             ssid;   /**< SSID of the AP */
    acfg_dauth_reason_t     reason; /**< Reason for De-Authentication */
    acfg_assoc_status_t        status;
    uint8_t               macaddr[ACFG_MACADDR_LEN];/**< MAC Addr */
    uint8_t         frame_send;
} acfg_dauth_t;

typedef struct acfg_assoc {
    acfg_assoc_status_t     status;                 /**< Assoc Status */
    acfg_ssid_t             ssid;                   /**< SSID */
    uint8_t               bssid[ACFG_MACADDR_LEN];/**< MAC Addr */
    uint8_t         frame_send;
} acfg_assoc_t;

typedef struct acfg_disassoc {
    acfg_reason_t     reason; /**< Reason for Disassociation */
    acfg_assoc_status_t        status;
    uint8_t               macaddr[ACFG_MACADDR_LEN];/**< MAC Addr */
    uint8_t         frame_send;
} acfg_disassoc_t;

typedef struct acfg_auth {
    acfg_assoc_status_t        status;
    uint8_t         macaddr[ACFG_MACADDR_LEN];/**< MAC Addr */
    uint8_t         frame_send;
} acfg_auth_t;


/**
 * @brief Radio On Channel event
 */
enum acfg_chan_start_reason {
    ACFG_CHAN_CHANGE_DFS = 0x01,
    ACFG_CHAN_CHANGE_NORMAL = 0x02,
};

typedef struct acfg_chan_start {
    uint32_t              freq;     /**< Frequency */
    uint32_t              reason;   /**< Reason */
    uint32_t              duration; /**< Duration */
    uint32_t              req_id;   /**< Request ID */
} acfg_chan_start_t;

/**
 * @brief Radio Off Channel event
 */
typedef struct acfg_chan_end {
    uint32_t              freq;     /**< Frequency */
    uint32_t              reason;   /**< Reason */
    uint32_t              duration; /**< Duration */
    uint32_t              req_id;   /**< Request ID */
} acfg_chan_end_t;

/**
 * @brief Leave AP event
 */
typedef struct acfg_leave_ap {
    acfg_reason_t     reason;
    uint8_t               mac[ACFG_MACADDR_LEN]; /**< MAC Addr of STA */
} acfg_leave_ap_t;

/**
 * @brief Pass IE event
 */
typedef struct acfg_gen_ie {
    uint32_t              len;                        /**< IE Length */
    uint8_t               *data;                      /**< IE Data */
} acfg_gen_ie_t;

/**
 * @brief scan done status
 */
enum acfg_scan_done_status {
    ACFG_SCAN_SUCCESS  = 0,    /**< SCAN Done completed */
    ACFG_LENGTH_FAIL   = 1,    /**< Unspecified failure */
};
typedef uint32_t  acfg_scan_done_status_t;

/**
 * @brief Scan Completion Event
 */
typedef struct acfg_scan_done {
    acfg_scan_done_status_t     status;     /**< Scan Done Status */
    uint32_t                  size;      /**< Size of the Scan results */
} acfg_scan_done_t;

/**
 * @brief Radar Event
 */
typedef struct acfg_radar {
    uint8_t                  count; /**< no. of freqs */
    uint8_t                  freqs[ACFG_MAX_IEEE_CHAN]; /**< list of radar freqs */
} acfg_radar_t;

/**
 * @brief STA Session timeout Event
 */
enum acfg_session_reason {
    ACFG_SESSION_TIMEOUT = 0x01,
    ACFG_SESSION_UNKNOWN = 0x02,
};
typedef struct acfg_session {
    acfg_reason_t           reason;
    uint8_t               mac[ACFG_MACADDR_LEN]; /**< MAC Addr of STA */
} acfg_session_t;

/**
 * @brief Structure returned on a ACFG_EV_WSUPP_WPS_EVENT_ENROLLEE_SEEN event\n
 */
typedef struct acfg_wsupp_wps_enrollee {
    uint8_t station_address[ACFG_MACADDR_LEN];    /**< MAC Addr */
    char raw_message[128];                           /**< always, undecoded char data */
} acfg_wsupp_wps_enrollee_t;

/**
 * @brief Structure returned on a ACFG_EV_WSUPP_WPA_EVENT event\n
 */
typedef struct acfg_wsupp_wpa_conn {
    uint8_t station_address[ACFG_MACADDR_LEN];    /**< MAC Addr */
    char raw_message[128];                      /**< always, undecoded char data */
} acfg_wsupp_wpa_conn_t;

/**
 * @brief Structure returned on a ACFG_EV_WSUPP_AP_STA_CONNECTED event\n
 */
typedef struct acfg_wsupp_ap_sta_conn {
    uint8_t station_address[ACFG_MACADDR_LEN];    /**< MAC Addr */
    char raw_message[128];                      /**< always, undecoded char data */
} acfg_wsupp_ap_sta_conn_t;

/**
 * @brief Structure returned on a ACFG_EV_WSUPP_RAW_MESSAGE event\n
 */
typedef struct acfg_wsupp_raw_message {
    char raw_message[128];                     /**< always, undecoded char data */
} acfg_wsupp_raw_message_t;

/**
 * @brief Structure returned on a ACFG_EV_WSUPP_RADIUS_RAW_MESSAGE event\n
 */
typedef struct acfg_wsupp_radius_message {
    uint8_t raw_message[1800];                     /**< always, undecoded char data */
} acfg_wsupp_radius_message_t;


/**
 * @brief Structure returned on a PROBE REQUEST Frame through IWEVASSOCREQIE event\n
 */
typedef struct acfg_probe_req {
    uint32_t len;
    uint8_t  *data;
} acfg_probe_req_t;

typedef struct acfg_wsupp_custom_message {
    uint8_t raw_message[500];                     /**< always, undecoded char data */
} acfg_wsupp_custom_message_t;

typedef struct acfg_wsupp_assoc {
    uint8_t addr[ACFG_MACADDR_LEN];
    char raw_message[128];                      /**< always, undecoded char data */
} acfg_wsupp_assoc_t;

typedef struct acfg_wsupp_eap_status {
    uint8_t addr[ACFG_MACADDR_LEN];
    char raw_message[128];                      /**< always, undecoded char data */
} acfg_wsupp_eap_t;

typedef struct acfg_pbc_ev {
    uint8_t ifname[ACFG_MAX_IFNAME];
    uint8_t data;
} acfg_pbc_ev_t;

typedef struct acfg_wsupp_wps_success {
    char raw_message[128];                      /**< always, undecoded char data */
} acfg_wsupp_wps_success_t;

typedef struct acfg_wsupp_wps_new_ap_settings {
    char raw_message[128];                      /**< always, undecoded char data */
} acfg_wsupp_wps_new_ap_settings_t;

typedef uint32_t acfg_tx_overflow_t;
typedef struct acfg_gpio {
    uint32_t num;
} acfg_gpio_t;

enum acfg_wdt_reason {
    ACFG_WDT_TARGET_ASSERT = 0x01,
    ACFG_WDT_REINIT_DONE = 0x02,
    ACFG_WDT_FWDUMP_READY = 0x04,
    ACFG_WDT_PCIE_ASSERT = 0x08,
    ACFG_WDT_INIT_FAILED = 0x10,
    ACFG_WDT_VAP_STOP_FAILED = 0x11,
};
typedef struct acfg_wdt_event {
    acfg_reason_t           reason;
} acfg_wdt_event_t;

typedef uint32_t acfg_cac_start_t;
typedef uint32_t acfg_up_after_cac_t;

typedef uint32_t acfg_exceed_max_client_t; /*Exceed Max Client*/

#if defined(OL_ATH_SMART_LOGGING) && !defined(REMOVE_PKT_LOG)
/**
 * @brief Reason for stopping FW initiated packetlog\n
 */
enum acfg_smart_log_fw_pktlog_stop_reason {
    ACFG_SMART_LOG_FW_PKTLOG_STOP_NORMAL,  /**< Normal stop by firmware */
    ACFG_SMART_LOG_FW_PKTLOG_STOP_HOSTREQ, /**< Stop requested by host */
    ACFG_SMART_LOG_FW_PKTLOG_STOP_DISABLE, /**< Stop since the smart log FW
                                                initiated packetlog feature is
                                                being disabled */
};

/**
 * @brief Structure returned on an ACFG_EV_SMART_LOG_FW_PKTLOG_STOP event\n
 */
typedef struct acfg_smart_log_fw_pktlog_stop {
    acfg_reason_t reason;  /**< Reason for event as defined in
                                acfg_smart_log_fw_pktlog_stop_reason */
} acfg_smart_log_fw_pktlog_stop_t;
#endif /* defined(OL_ATH_SMART_LOGGING) && !defined(REMOVE_PKT_LOG) */

typedef struct acfg_hw_mode_change_status {
    uint32_t result; /* 0 = fail, success otherwise */
} acfg_hw_mode_change_status_t;

typedef struct acfg_kickout {
    uint8_t               macaddr[ACFG_MACADDR_LEN];/**< MAC Addr */
} acfg_kickout_t;

typedef struct acfg_assoc_failure {
    uint32_t     reason;
    uint8_t      macaddr[ACFG_MACADDR_LEN];/**< MAC Addr */
} acfg_assoc_failure_t;

enum acfg_diag_type {
    ACFG_DIAGNOSTICS_WARNING = 0x01,
    ACFG_DIAGNOSTICS_ERROR = 0x02,
    ACFG_DIAGNOSTICS_NORMAL = 0x04,
};

enum acfg_diag_status {
   ACFG_DIAGNOSTICS_DOWN = 0x01,
   ACFG_DIAGNOSTICS_DOWN_15_SEC = 0x02,
   ACFG_DIAGNOSTICS_DOWN_1_HR = 0x04,
   ACFG_DIAGNOSTICS_UP = 0x08,
};

typedef struct acfg_diag_event {
    uint32_t type;
    uint32_t status;
    uint32_t data_rate_threshold;
    uint8_t  macaddr[ACFG_MACADDR_LEN];/* MAC Addr */
    uint16_t power_level;
    uint8_t  rssi;
    char   mode[64];
    char   tstamp[32];
    uint8_t  channel_index;
    uint32_t tx_data_rate;
    uint8_t  mcs_index;
    uint8_t  chan_width;
    uint8_t  sgi;
    uint8_t  nss;
    uint8_t  airtime;
} acfg_diag_event_t;

#endif /* __ACFG_EVENT_TYPES_H */
