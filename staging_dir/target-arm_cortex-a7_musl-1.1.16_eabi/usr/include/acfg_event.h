/*
 * Copyright (c) 2019 Qualcomm Innovation Center, Inc.
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

#ifndef __ACFG_EVENT_H
#define __ACFG_EVENT_H

/**
 * @file acfg_event.h
 * @brief
 * @author Atheros Communications Inc.
 * @version 0.1
 */
#include <acfg_api_types.h>

/**
 * @brief OS Event specific handle
 */
//typedef __acfg_os_event_t   acfg_os_event_t;

/**
 * @brief ACFG Event Structure, to be populated by the user APP
 */
typedef struct acfg_event {
    /**
     * @brief  Indicate Device state Change event
     */
    uint32_t  (*device_state_change)(acfg_device_state_data_t *device_state);

    /**
     * @brief  Indicate Scan complete event
     */
    uint32_t  (*scan_done)(uint8_t  *ifname, acfg_scan_done_t   *done);

    /**
     * @brief  Indicate AP Association events
     */
    uint32_t  (*assoc_ap)(uint8_t *ifname, acfg_assoc_t  *done);
    uint32_t  (*disassoc_ap)(uint8_t *ifname, acfg_disassoc_t  *done);
    uint32_t  (*auth_ap)(uint8_t *ifname, acfg_auth_t  *done);
    uint32_t  (*deauth_ap)(uint8_t *ifname, acfg_dauth_t  *fail);

    /**
     * @brief   Indicate STA Association events
     */
    uint32_t  (*assoc_sta)(uint8_t *ifname, acfg_assoc_t  *fail);
    uint32_t  (*disassoc_sta)(uint8_t *ifname, acfg_disassoc_t  *fail);
    uint32_t  (*auth_sta)(uint8_t *ifname, acfg_auth_t  *done);
    uint32_t  (*deauth_sta)(uint8_t *ifname, acfg_dauth_t  *fail);


    /**
     * @brief   Indicate Radio On Channel events
     */
    uint32_t  (*chan_start)(uint8_t *ifname, acfg_chan_start_t *chan_start);

    /**
     * @brief   Indicate Radio Off Channel events
     */
    uint32_t  (*chan_end)(uint8_t *ifname, acfg_chan_end_t *chan_end);

    /**
     * @brief   Indicate Management Frame Received events
     */
    uint32_t  (*rx_mgmt)(uint8_t *ifname, void *dummy);

    /**
     * @brief   Indicate Action Frame Sent events
     */
    uint32_t  (*sent_action)(uint8_t *ifname, void *dummy);

    /**
     * @brief   Indicate AP Dis-association events
     */
    uint32_t  (*leave_ap)(uint8_t *ifname, acfg_leave_ap_t *leave_ap);

    /**
     * @brief   Indicate to Pass IE events
     */
    uint32_t  (*gen_ie)(uint8_t *ifname, acfg_gen_ie_t *gen_ie);

    /**
     * @brief   Indicate to Pass Assoc Req IE events
     */
    uint32_t  (*assoc_req_ie)(uint8_t *ifname, acfg_gen_ie_t *gen_ie);

    /**
     * @brief   Indicate to Pass Radar events
     */
    uint32_t  (*radar)(uint8_t *ifname, acfg_radar_t *radar);

    /**
     * @brief   Indicate raw message from wpa supplicant
     */
    uint32_t  (*wsupp_raw_message)(uint8_t *, acfg_wsupp_raw_message_t *);

    /**
     * @brief   Indicate AP-STA connected
     */
    uint32_t  (*wsupp_ap_sta_conn)(uint8_t *, acfg_wsupp_ap_sta_conn_t *);
    uint32_t  (*wsupp_ap_sta_disconn)(uint8_t *, acfg_wsupp_ap_sta_conn_t *);

    /**
     * @brief   Indicate WPA connected
     */
    uint32_t  (*wsupp_wpa_conn)(uint8_t *, acfg_wsupp_wpa_conn_t *);

    /**
     * @brief   Indicate WPA disconnected
     */
    uint32_t  (*wsupp_wpa_disconn)(uint8_t *, acfg_wsupp_wpa_conn_t *);

    uint32_t  (*wsupp_assoc_reject)(uint8_t *, acfg_wsupp_assoc_t *);

    /**
     * @brief   Indicate WPA terminating
     */
    uint32_t  (*wsupp_wpa_term)(uint8_t *, acfg_wsupp_wpa_conn_t *);

    /**
     * @brief   Indicate WPA scan result available
     */
    uint32_t  (*wsupp_wpa_scan)(uint8_t *, acfg_wsupp_wpa_conn_t *);

    /**
     * @brief   Indicate WPS enrolle seen
     */
    uint32_t  (*wsupp_wps_enrollee)(uint8_t *, acfg_wsupp_wps_enrollee_t *);
    uint32_t  (*wsupp_eap_success)(uint8_t *, acfg_wsupp_eap_t *);
    uint32_t  (*wsupp_eap_failure)(uint8_t *, acfg_wsupp_eap_t *);
    uint32_t  (*push_button)(uint8_t *, acfg_pbc_ev_t *);
    uint32_t  (*wsupp_wps_new_ap_setting)(uint8_t *,
            acfg_wsupp_wps_new_ap_settings_t *);
    uint32_t  (*wsupp_wps_success)(uint8_t *, acfg_wsupp_wps_success_t *);
    uint32_t  (*session_timeout)(uint8_t *, acfg_session_t *);
    uint32_t  (*tx_overflow)(uint8_t *);
    uint32_t  (*gpio_input)(uint8_t *, acfg_gpio_t *);

    /* mgmt rx info  */
    uint32_t  (*mgmt_rx_info)(uint8_t *, acfg_mgmt_rx_info_t *);
    /* watchdog event */
    uint32_t  (*wdt_event)(uint8_t *, acfg_wdt_event_t *);
    uint32_t  (*nf_dbr_dbm_info)(uint8_t *, acfg_nf_dbr_dbm_t *);
    uint32_t  (*packet_power_info)(uint8_t *, acfg_packet_power_t *);
    uint32_t  (*cac_start)(uint8_t *);
    uint32_t  (*up_after_cac)(uint8_t *);
    uint32_t  (*kickout)(uint8_t *, acfg_kickout_t *);
    uint32_t  (*assoc_failure)(uint8_t *, acfg_assoc_failure_t *);
    uint32_t  (*diagnostics)(uint8_t *ifname, acfg_diag_event_t *diag);
    uint32_t  (*chan_stats)(uint8_t *, acfg_chan_stats_t *);
    uint32_t  (*exceed_max_client)(uint8_t *);
#if defined(OL_ATH_SMART_LOGGING) && !defined(REMOVE_PKT_LOG)
    uint32_t  (*smart_log_fw_pktlog_stop)(uint8_t *,
            acfg_smart_log_fw_pktlog_stop_t *);
#endif /* defined(OL_ATH_SMART_LOGGING) && !defined(REMOVE_PKT_LOG) */
    uint32_t  (*hw_mode_change_status)(uint8_t *, acfg_hw_mode_change_status_t *);
} acfg_event_t;


/**
 * @brief
 *
 * @param ifname (Event
 * @param event
 *
 * @return
 */
uint32_t
acfg_setup_events(uint8_t *ifname, acfg_event_t  *event);

/**
 * @brief
 *
 * @param ifname    (Interface name to listen)
 * @param event     (Event Structure)
 * @param mode      (Listening mode)
 *
 * @return
 */
uint32_t
acfg_recv_events(acfg_event_t *event, \
        acfg_event_mode_t  mode);

int acfg_recv_netlink_events(acfg_event_t *event);
void acfg_wait_for_wps_app_event(void);

/*Private reason codes*/
enum {
    ACFG_REASON_ASSOC_CAP_MISMATCH = 1,
    ACFG_REASON_ASSOC_RATE_MISMATCH= 2,
    ACFG_REASON_ASSOC_PUREN_NOHT   = 3,
    ACFG_REASON_ASSOC_PUREAC_NOVHT = 4,
    ACFG_REASON_ASSOC_11AC_TKIP_USED = 5,
    ACFG_REASON_ASSOC_CHANWIDTH_MISMATCH = 6,
};

#endif /* __ACFG_EVENT_H */
