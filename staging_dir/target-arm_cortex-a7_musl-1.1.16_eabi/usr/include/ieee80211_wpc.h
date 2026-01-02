/*
 * Copyright (c) 2011 Qualcomm Atheros, Inc..
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef __IEEE80211_WPC_H
#define __IEEE80211_WPC_H
/*  The NETLINK wIFIPOS should NETLINK_GENERIC + 6, because we need to 
    match the protocol number even at App's*/
#define NETLINK_WIFIPOS (NETLINK_GENERIC + 6)

#ifndef ETH_ALEN
#define ETH_ALEN 6
#endif

// This is need to change the RX chain mask to num of chains
#ifndef __KERNEL__
static u_int8_t ieee80211_mask2numchains[8] = {
    0 /* 000 */,
    1 /* 001 */,
    1 /* 010 */,
    2 /* 011 */,
    1 /* 100 */,
    2 /* 101 */,
    2 /* 110 */,
    3 /* 111 */
};
#endif


struct nsp_header {
#define START_OF_FRAME 0x1273
#define NSP_VERSION 0x01    
	u_int16_t SFD;
	u_int8_t version;
	u_int8_t frame_type;
	u_int16_t frame_length;
}__attribute__((packed));
#define NSP_HDR_LEN sizeof(struct nsp_header)
// This has been introduced in NBP1.1. The value for this will be 0x02 for 
// NBP 1.1 change requests
#define NSP_AP_SW_VERSION 0x02

struct nsp_mrqst {
	u_int16_t request_id;
    /* A unique ID which identifies the request. It is the responsibility 
     * of the application to ensure that this is unique. 
     * The library will use this Id in its response. */

	u_int16_t mode;
#define NSP_MRQSTTYPE_MASK 0x3
#define NSP_MRQSTTYPE_TYPE0 0x0
#define NSP_MRQSTTYPE_TYPE1 0x1

#define FRAME_TYPE_HASH 0x001c
#define TX_CHAINMASK_HASH 0x00e0
#define RX_CHAINMASK_HASH 0x0700
#define TYPE0 0
#define TYPE1 1
#define NULL_FRAME 0
#define QOS_NULL_FRAME 4
#define RTS_CTS 8
#define TX_CHAINMASK_1 0x0020
#define TX_CHAINMASK_2 0x0040
#define TX_CHAINMASK_3 0x0060
#define RX_CHAINMASK_1 0x0100
#define RX_CHAINMASK_2 0x0200
#define RX_CHAINMASK_3 0x0300
#define SYNCHRONIZE    0x0800
    /* Bits 1:0: Type of measurement:
          00: RTT, 01: CIR
     * Bits 4:2: 802.11 Frame Type to use as Probe
          000: NULL, 001: Qos NULL, 010: RTS/CTS
     * Bits 7:5 Transmit chainmask to use for transmission
          01: 1, 10: 2, 11:3 
     * Bits 10:8: Receive chainmask to use for reception
          01: 1, 10: 2, 11:3 
     * Bits 13:11: The method by which the request should be serviced
          00 = Immediate: The request must be serviced as soon as possible
          01 = Delayed: The WPC can defer the request to when it deems appropriate
          10 = Cached: The WPC should service the request from cached results only */

	u_int8_t sta_mac_addr[ETH_ALEN];
    /* The MAC Address of the STA for which a measurement is requested.*/

	u_int8_t spoof_mac_addr[ETH_ALEN];
    /* The MAC Address which the AP SW should use as the source 
     * address when sending out the sounding frames */

	u_int32_t sta_info;
    /* A bit field used to provide information about the STA
     * The bit fields include the station type (WP Capable/Non Capable)
     * and other fields to be defined in the future.
     * STAInfo[0]: Station Type: 0=STA is not WP Capable, 1=STA is WP Capable
     * STAInfo[31:1]: TBD */

	u_int8_t channel;
    /* The channel on which the STA is currently listening. 
     * The channel is specified in the notation (1-11 for 2.4 GHz and 36 – 169 for 5 GHz. 
     * If a STA is in HT40 mode, then the channel will indicate the 
     * control channel. Probe frames will always be sent at HT20 */

	u_int8_t no_of_measurements;
    /* The number of results requested i.e the WLAN AP can stop measuring 
     * after it successfully completes a number of measurements equal 
     * to this number. For RTT based measurement this will always = 1 */

	u_int32_t transmit_rate;
    /* Rate requested for transmission. If value is all zeros 
     * the AP will choose its own rate. If not the AP will honor this 
     * 31:0: IEEE Physical Layer Transmission Rate of the Probe frame */
    u_int32_t transmit_retries;
    /* Retries requested from the server for this particular request.
     * 31:0 IEEE rety set for probe frame. 
     */

	u_int16_t timeout;
    /* Time out for collecting all measurements. This includes the 
     * time taken to send out all sounding frames and retry attempts. 
     * Measured in units of milliseconds. For the Immediate Measurement mode, 
     * the WLAN AP system must return a Measurement Response after the 
     * lapse of an interval equal to “timeout” milliseconds after 
     * reception of the Measurement Request */

    u_int8_t bandwidth; /* The bandwidth at which the
                            measurement frames should be transmitted
                            0: legacy 20
                            1: VHT_20
                            2: VHT_40
                            3: VHT_80
                            */
    u_int8_t lci_req;
    u_int8_t loc_civ_req;
    u_int8_t req_report_type;
    u_int8_t req_preamble;
    u_int8_t asap_mode;
    u_int8_t burst_exp;
    u_int16_t burst_period;
    u_int16_t burst_dur;
    u_int16_t ftm_per_burst;
}__attribute__((packed));

struct nsp_mresp {
    u_int16_t request_id;
    /* A unique ID which identifies the request. It is the responsibility 
     * of the application to ensure that this is unique. 
     * The library will use this Id in its response. */

    u_int8_t sta_mac_addr[ETH_ALEN];
    /* The MAC Address of the STA for which a measurement is requested.*/

    u_int16_t no_of_responses;
    /* no of responses */
    u_int64_t req_tstamp;
    /*Request timestamp */
    u_int64_t resp_tstamp;
    /*Response timestamp */
    u_int16_t result;
    /*result =0 complete, result =1 more packet*/
}__attribute__((packed));

#define TYPE1PAYLDLEN 390
#define WPC_MAX_CHAINS 3
struct nsp_type1_resp {

    u_int64_t tod;
    /* A timestamp indicating when the measurement probe was sent */

    u_int64_t toa;
    /* A timestamp indicating when the probe response was received */

    u_int32_t send_rate;
    /* IEEE Physical Layer Transmission Rate of the Probe frame */

    u_int32_t receive_rate;
    /* IEEE Physical Layer receive Rate of the Probe frame */

    u_int8_t no_of_retries;
    /* Number of retries for the probe */

    u_int8_t no_of_chains;
    /* Number of chains used for reception */
    u_int8_t payload_info;
    /*Information how the payload is encoded */

    u_int8_t rssi[WPC_MAX_CHAINS];
    /* Received signal strength indicator */

    char type1_payld[TYPE1PAYLDLEN];
    /* Type 1 response for max no of chains */

}__attribute__((packed));

struct nsp_type0_resp {
	u_int16_t request_id;
    /* A unique ID which identifies the request. It is the responsibility 
     * of the application to ensure that this is unique. 
     * The library will use this Id in its response. */

	u_int8_t sta_mac_addr[ETH_ALEN];
    /* The MAC Address of the STA for which a measurement is requested.*/

	u_int8_t result;
    /* result */

    u_int32_t rtt_mean;
    /*Mean RTT */

    u_int32_t rtt_stddev;
    /*Standard deviation of RTT*/

    u_int8_t rtt_samples;
    /*Number of samples of RTT*/
    
    u_int8_t rssi_mean;
    /*(Arithmetic) Mean RSSI */

    u_int8_t rssi_stddev;
    /*Standard deviation of RSSI*/

    u_int8_t rssi_samples;
    /*Number of samples of RSSI*/
}__attribute__((packed));

struct nsp_cap_req {
    u_int16_t request_id;
}__attribute__((packed));

struct nsp_cap_resp {
    u_int16_t request_id;
    u_int8_t band;
    u_int8_t positioning;
    /* This will get the current setting of chains  */
    u_int8_t curr_chain_masks;  
    u_int16_t sw_version;
    u_int16_t hw_version;
    u_int32_t clk_freq;
}__attribute__((packed));

struct nsp_station_info {
	u_int8_t vap_index;
    u_int8_t sta_mac_addr[ETH_ALEN];
    u_int64_t tstamp;
    u_int8_t info;
    u_int8_t rssi;
}__attribute__((packed));

struct nsp_sreq {
    u_int16_t request_id;
}__attribute__((packed));

struct nsp_sresp {
    u_int16_t request_id;
	u_int16_t no_of_vaps; 
    u_int16_t no_of_stations;
    u_int64_t req_tstamp;
    u_int64_t resp_tstamp;
}__attribute__((packed));

struct nsp_vap_info {
	u_int8_t vap_mac[ETH_ALEN];
    u_int8_t vap_channel;
    u_int8_t vap_ssid[36];
}__attribute__((packed));


struct nsp_sleep_req {
    u_int16_t request_id;
    u_int8_t sta_mac_addr[ETH_ALEN];
}__attribute__((packed));

struct nsp_sleep_resp {
    u_int16_t request_id;
    u_int8_t sta_mac_addr[ETH_ALEN];
    u_int16_t num_ka_frm;  // addition for NBP 1.1
    u_int8_t result;
}__attribute__((packed));

struct nsp_wakeup_req {
    u_int16_t request_id;
    u_int8_t sta_mac_addr[ETH_ALEN];
    u_int8_t wakeup_interval;
    u_int8_t mode;
}__attribute__((packed));

struct nsp_wakeup_resp {
    u_int16_t request_id;
    u_int8_t sta_mac_addr[ETH_ALEN];
    u_int8_t result;
}__attribute__((packed));

struct nsp_tsf_req {
    u_int16_t request_id;
    u_int8_t ap_mac_addr[ETH_ALEN];
    char ssid[36];
    u_int8_t channel;
    u_int8_t timeout;
}__attribute__((packed));

struct nsp_tsf_resp {
    u_int16_t request_id;
    u_int8_t ap_mac_addr[ETH_ALEN];
    u_int64_t assoc_tsf;
    u_int64_t prob_tsf;
    u_int8_t result;
}__attribute__((packed));

struct request_no {
    u_int8_t request_id;
}__attribute__((packed));

struct nsp_error_msg {
    u_int16_t request_id;
    u_int16_t errorid;
#define NSP_UNSUPPORTED_PROTOCOL_VERSION    0x0001
#define NSP_INCORRECT_MESSAGE_LENGTH        0x0002
}__attribute__((packed));

struct nsp_wpc_dbg_req {
    u_int16_t request_id;
    u_int8_t dbg_mode;
};

struct nsp_wpc_dbg_resp {
    u_int16_t request_id;
    u_int8_t result;
};

struct wpc_dbg_header {
    char filename[20];
    u_int32_t line_no;
    u_int8_t frame_type;
};

#define MAX_NEIGHBOR_NUM 15
#define MAX_NEIGHBOR_LEN 50

struct neighbor_report_arr {
    u_int8_t sta_mac[6];
    u_int8_t dialogtoken;
    u_int16_t num_repetitions;
    u_int8_t id;
    u_int8_t len;
    u_int8_t meas_token;
    u_int8_t meas_req_mode;
    u_int8_t meas_type;
    u_int16_t rand_inter;
    u_int8_t min_ap_count;
    u_int8_t elem[MAX_NEIGHBOR_NUM*MAX_NEIGHBOR_LEN]; 
}__attribute__((packed));

/* Used for Where are you: LCI measurement request */
struct meas_req_lci_request {
    u_int8_t sta_mac[6];
    u_int8_t dialogtoken;
    u_int16_t num_repetitions;
    u_int8_t id;
    u_int8_t len;
    u_int8_t meas_token;
    u_int8_t meas_req_mode;
    u_int8_t meas_type;
    u_int8_t loc_subject;
    u_int8_t maxage_subie;
    u_int8_t maxage_len;
    u_int16_t maxage_val;
}__attribute__((packed));

#define IEEE80211_MAXAGE_SUBIE         4
#define IEEE80211_MAXAGE_LEN           2
#define IEEE80211_MAXAGE_VALUE_DEFAULT 65535
#define IEEE80211_MAXAGE_IE_SIZE       4

#define MREQ_LEN sizeof(struct nsp_mrqst)
#define MRES_LEN sizeof(struct nsp_mresp)
#define TYPE1RES_LEN sizeof(struct nsp_type1_resp)
#define TYPE0RES_LEN sizeof(struct nsp_type0_resp)
#define CAPREQ_LEN sizeof(struct nsp_cap_req)
#define CAPRES_LEN sizeof(struct nsp_cap_resp)
#define SREQ_LEN sizeof(struct nsp_sreq)
#define SRES_LEN sizeof(struct nsp_sresp)
#define SINFO_LEN sizeof(struct nsp_station_info)
#define SLEEPREQ_LEN sizeof(struct nsp_sleep_req)
#define SLEEPRES_LEN sizeof(struct nsp_sleep_resp)
#define WAKEUPREQ_LEN sizeof(struct nsp_wakeup_req)
#define WAKEUPRES_LEN sizeof(struct nsp_wakeup_resp)
#define TSFREQ_LEN sizeof(struct nsp_tsf_req)
#define TSFRES_LEN sizeof(struct nsp_tsf_resp)
#define WPCDBGREQ_LEN sizeof(struct nsp_wpc_dbg_req)
#define WPCDBGRESP_LEN sizeof(struct nsp_wpc_dbg_resp)
#define WPCDBGHDR_LEN sizeof(struct wpc_dbg_header)
#define ERRORMSG_LEN sizeof(struct nsp_error_msg)
#define VAPINFO_LEN sizeof(struct nsp_vap_info)

enum NSP_FRAME_TYPE {
    NSP_MRQST = 1,
    NSP_TYPE1RESP,
    NSP_TYPE0RESP,
    NSP_SRQST,
    NSP_SRESP,
    NSP_CRQST,
    NSP_CRESP,
    NSP_WAKEUPRQST,
    NSP_WAKEUPRESP,
    NSP_TSFRQST,
    NSP_TSFRESP,
    NSP_STARETURNTOSLEEPREQ,
    NSP_STARETURNTOSLEEPRES,
    NSP_WPCDBGRGST,
    NSP_WPCDBGRESP,
    NSP_FTMRR, 
    NSP_WPC_LCI,
    NSP_WPC_LCR,
    NSP_WHEREAREYOU,
    NSP_ERRORMSG
};

#endif /* __IEEE80211_WPC_H */
