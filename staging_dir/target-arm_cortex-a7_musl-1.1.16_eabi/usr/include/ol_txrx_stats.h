/*
 * Copyright (c) 2012, 2017 Qualcomm Innovation Center, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary . Qualcomm Innovation Center, Inc.
 *
 * 2012 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */
/**
 * @file ol_txrx_status.h
 * @brief Functions provided for visibility and debugging.
 * NOTE: This file is used by both kernel driver SW and userspace SW.
 * Thus, do not reference use any kernel header files or defs in this file!
 */
#ifndef _OL_TXRX_STATS__H_
#define _OL_TXRX_STATS__H_

#include <athdefs.h>       /* u_int64_t */
#include "wlan_defs.h" /* for wlan statst definitions */
#include "cdp_txrx_extd_struct.h"

#define OL_TXRX_MAX_TX_RATE_VALUES 10 /*Max Tx Rates */
#define OL_TXRX_MAX_RSSI_VALUES 10 /*Max Rssi values */

#define RSSI_INV     0x80 /*invalid RSSI */

#define RSSI_DROP_INV(_curr_val, _new_val) (_new_val == RSSI_INV ? _curr_val: _new_val)

#define RSSI_CHAIN_STATS(ppdu, rx_chain)        do {        \
        (rx_chain).rx_rssi_pri20 = RSSI_DROP_INV((rx_chain).rx_rssi_pri20, ((ppdu) & RX_RSSI_CHAIN_PRI20_MASK)); \
        (rx_chain).rx_rssi_sec20 = RSSI_DROP_INV((rx_chain).rx_rssi_sec20, ((ppdu) & RX_RSSI_CHAIN_SEC20_MASK) >> RX_RSSI_CHAIN_SEC20_SHIFT) ; \
        (rx_chain).rx_rssi_sec40 = RSSI_DROP_INV((rx_chain).rx_rssi_sec40, ((ppdu) & RX_RSSI_CHAIN_SEC40_MASK) >> RX_RSSI_CHAIN_SEC40_SHIFT); \
        (rx_chain).rx_rssi_sec80 = RSSI_DROP_INV((rx_chain).rx_rssi_sec80, ((ppdu) & RX_RSSI_CHAIN_SEC80_MASK) >> RX_RSSI_CHAIN_SEC80_SHIFT); \
    } while ( 0 )


#define RSSI_CHAIN_PRI20(ppdu, rx_chain)       do { \
        rx_chain = RSSI_DROP_INV((rx_chain), ((ppdu) & HTT_T2H_EN_STATS_RSSI_PRI_20_M) >> HTT_T2H_EN_STATS_RSSI_PRI_20_S); \
        } while ( 0 )


enum pflow_ctrl_global_stats {
    HTTFETCH,
    HTTFETCH_NOID,
    HTTFETCH_CONF,
    HTTDESC_ALLOC,
    HTTDESC_ALLOC_FAIL,
    HTTFETCH_RESP,
    DEQUEUE_CNT,
    ENQUEUE_CNT,
    QUEUE_BYPASS_CNT,
    ENQUEUE_FAIL_CNT,
    DEQUEUE_BYTECNT,
    ENQUEUE_BYTECNT,
    PEER_Q_FULL,
    DEQUEUE_REQ_BYTECNT,
    DEQUEUE_REQ_PKTCNT,
    QUEUE_DEPTH,
    TX_COMPL_IND,
    TX_DESC_FAIL,
    INTR_TASKLETBIN500,
    INTR_TASKLETBIN1000,
    INTR_TASKLETBIN2000,
    INTR_TASKLETBIN4000,
    INTR_TASKLETBIN6000,
    INTR_TASKLETBINHIGH,
    HTTFETCHBIN500,
    HTTFETCHBIN1000,
    HTTFETCHBIN2000,
    HTTFETCHBINHIGH,
    QUEUE_OCCUPANCY,
    QUEUE_OCCUPANCY_BIN2,
    QUEUE_OCCUPANCY_BIN8,
    QUEUE_OCCUPANCY_BIN16,
    QUEUE_OCCUPANCY_BIN32,
    QUEUE_OCCUPANCY_BINHIGH,
    PFLOW_CTRL_GLOBAL_STATS_MAX,
};

#ifndef BIG_ENDIAN_HOST
typedef struct {
	uint64_t pkts;
	uint64_t bytes;
} ol_txrx_stats_elem;
#else
struct ol_txrx_elem_t {
	uint64_t pkts;
	uint64_t bytes;
};
typedef struct ol_txrx_elem_t ol_txrx_stats_elem;
#endif

/**
 * @brief data stats published by the host txrx layer
 */
struct ol_txrx_stats {
	struct {
		/* MSDUs received from the stack */
		ol_txrx_stats_elem from_stack;
		/* MSDUs successfully sent across the WLAN */
		ol_txrx_stats_elem delivered;
		struct {
			/* MSDUs that the host did not accept */
			ol_txrx_stats_elem host_reject;
			/* MSDUs which could not be downloaded to the target */
			ol_txrx_stats_elem download_fail;
			/*
			 * MSDUs which the target discarded
			 * (lack of mem or old age)
			 */
			ol_txrx_stats_elem target_discard;
			/*
			 * MSDUs which the target sent but couldn't get
			 * an ack for
			 */
			ol_txrx_stats_elem no_ack;
			/* MSDUs dropped in NSS-FW */
			ol_txrx_stats_elem nss_ol_dropped;
		} dropped;
		u_int32_t desc_in_use;
		u_int32_t desc_alloc_fails;
		u_int32_t ce_ring_full;
		u_int32_t dma_map_error;
		/* MSDUs given to the txrx layer by the management stack */
		ol_txrx_stats_elem mgmt;
		struct {
			/* TSO applied jumbo packets received from NW Stack */
			ol_txrx_stats_elem tso_pkts;
			/* Non - TSO packets */
			ol_txrx_stats_elem non_tso_pkts;
			/* TSO packets : Dropped during TCP segmentation*/
			ol_txrx_stats_elem tso_dropped;
			/* TSO Descriptors */
			u_int32_t tso_desc_cnt;
		} tso;

		struct {
			/* TSO applied jumbo packets received from NW Stack */
			ol_txrx_stats_elem sg_pkts;
			/* Non - TSO packets */
			ol_txrx_stats_elem non_sg_pkts;
			/* TSO packets : Dropped during TCP segmentation*/
			ol_txrx_stats_elem sg_dropped;
			/* TSO Descriptors */
			u_int32_t sg_desc_cnt;
		} sg;
		struct {
			/* packets enqueued for flow control */
			u_int32_t fl_ctrl_enqueue;
			/* packets discarded for flow control is full */
			u_int32_t fl_ctrl_discard;
			/* packets sent to CE without flow control */
			u_int32_t fl_ctrl_avoid;
		} fl_ctrl;
	} tx;
	struct {
		/* MSDUs given to the OS shim */
		ol_txrx_stats_elem delivered;
		/* MSDUs forwarded from the rx path to the tx path */
		ol_txrx_stats_elem forwarded;
		/* MSDUs in which ipv4 chksum error detected by HW */
		ol_txrx_stats_elem ipv4_cksum_err;
		/* MSDUs in which tcp chksum error detected by HW */
		ol_txrx_stats_elem tcp_ipv4_cksum_err;
		/* MSDUs in which udp chksum error detected by HW */
		ol_txrx_stats_elem udp_ipv4_cksum_err;
		/* MSDUs in which tcp V6 chksum error detected by HW */
		ol_txrx_stats_elem tcp_ipv6_cksum_err;
		/* MSDUs in which UDP V6 chksum error detected by HW */
		ol_txrx_stats_elem udp_ipv6_cksum_err;
	} rx;
	struct {
		/* Number of mcast received for conversion */
		u_int32_t num_me_rcvd;
		/* Number of unicast sent as part of mcast conversion */
		u_int32_t num_me_ucast;
		/* Number of multicast frames dropped due to dma_map failure */
		u_int32_t num_me_dropped_m;
		/*
		 * Number of multicast frames dropped due to allocation
		 * failure
		 */
		u_int32_t num_me_dropped_a;
		/* Number of multicast frames dropped due to internal failure */
		u_int32_t num_me_dropped_i;
		/* Number of me buf currently in use */
		u_int32_t num_me_buf;
		/* Number of me buf frames to self mac address  */
		u_int32_t num_me_dropped_s;
		/* Number of me buf in use in non pool based allocation*/
		u_int32_t num_me_nonpool;
		/* Number of me buf allocated using non pool based allocation*/
		u_int32_t num_me_nonpool_count;
	} mcast_enhance;
};

struct ol_pflow_stats {
    uint32_t value;
};

/* Macros previously defined in ol_if_stats which are specific to
 * legacy datapath hence moved here
 */
#define OL_PKTLOG_STATS_HDR_LOG_TYPE_OFFSET 1
#define OL_PKTLOG_STATS_HDR_LOG_TYPE_MASK 0xffff
#define OL_PKTLOG_STATS_HDR_LOG_TYPE_SHIFT 0
#define OL_PKTLOG_STATS_TYPE_TX_CTRL      1
#define OL_PKTLOG_STATS_TYPE_TX_STAT      2
#define OL_PKTLOG_STATS_TYPE_RC_UPDATE    7
#define OL_TX_PEER_ID_OFFSET 1
#define OL_RX_NULL_DATA_MASK 0x00000080
#define OL_RX_OVERFLOW_MASK 0x00010000
#define TX_FRAME_OFFSET 13
#define TX_TYPE_OFFSET 14
#define TX_PEER_ID_MASK
#define TX_PEER_ID_OFFSET 1
#define TX_FRAME_TYPE_MASK 0x3c00000
#define TX_FRAME_TYPE_SHIFT 22
#define TX_FRAME_TYPE_NOACK_MASK 0x00010000
#define TX_FRAME_TYPE_NOACK_SHIFT 16
#define TX_TYPE_MASK 0xc0000
#define TX_TYPE_SHIFT 18
#define TX_AMPDU_SHIFT 15
#define TX_AMPDU_MASK 0x8000
#define PPDU_END_OFFSET 16
#define TX_OK_OFFSET (PPDU_END_OFFSET + 0)
#define OL_TX_OK_MASK (0x80000000)

/**
 * struct ol_txrx_data_stats
 * @download_fail: MSDUx which could not be downloaded to the target
 * @ce_ring_full: CE ring full
 * @desc_in_use: descriptor which are in use
 * @mgmt: mgmt packet info
 * @fl_ctrl_enqueue: packets enqueued for flow control
 * @fl_ctrl_discard: packets discarded for flow control is full
 * @fl_ctrl_avoid: packets sent to CE without flow control
 * @pstats: Peer flow control stats
 * @tx_mcs: tx_mcs, gets updated from wmi_host_pdev_ext_stats
 * @tx_bawadv: TX Block ack window advertisement
 * @forwarded: MSDUs forwarded from the rx path to the tx path
 * @ipv4_cksum_err: MSDUs in which ipv4 chksum error detected by HW
 * @tcp_ipv4_cksum_err: MSDUs in which tcp chksum error detected by HW
 * @udp_ipv4_cksum_err: MSDUs in which udp chksum error detected by HW
 * @tcp_ipv6_cksum_err: MSDUs in which tcp V6 chksum error detected by HW
 * @udp_ipv6_cksum_err: MSDUs in which udp V6 chksum error detected by HW
 * @mpdu_bad: mpdus which are bad
 * @rx_mcs: rx_mcs, gets updated from wmi_host_pdev_ext_stats
 * @num_me_buf: Number of me buf currently in use
 * @num_me_nonpool: Number of me buf in use in non pool based allocation
 * @num_me_nonpool_count: Number of me buf allocated using non pool based allocation
 */
struct ol_txrx_data_stats {
	struct {
		struct {
			ol_txrx_stats_elem download_fail;
			uint32_t ce_ring_full;
		} dropped;
		uint32_t desc_in_use;
		ol_txrx_stats_elem mgmt;
		struct {
			uint32_t fl_ctrl_enqueue;
			uint32_t fl_ctrl_discard;
			uint32_t fl_ctrl_avoid;
		} fl_ctrl;
#if PEER_FLOW_CONTROL
	struct ol_pflow_stats pstats[PFLOW_CTRL_GLOBAL_STATS_MAX];
#endif
	uint32_t tx_mcs[10];
	uint32_t tx_bawadv;
	} tx;

	struct {
		ol_txrx_stats_elem forwarded;
		ol_txrx_stats_elem ipv4_cksum_err;
		ol_txrx_stats_elem tcp_ipv4_cksum_err;
		ol_txrx_stats_elem udp_ipv4_cksum_err;
		ol_txrx_stats_elem tcp_ipv6_cksum_err;
		ol_txrx_stats_elem udp_ipv6_cksum_err;
		struct {
			uint64_t mpdu_bad;
		} err;
		uint32_t rx_mcs[10];
		/* members added after converging ol_ath_radiostats at scn level
		 * follwing are added to update stats for invalid peer
		 */
		uint64_t rx_bytes;
		uint32_t rx_packets;
		uint32_t rx_crcerr;
		uint32_t rx_last_msdu_unset_cnt;
	} rx;

	struct {
		uint32_t num_me_buf;
		uint32_t num_me_nonpool;
		uint32_t num_me_nonpool_count;
	} mcast_enhance;

};

/**
 * struct ol_txrx_host_peer_stats -  interface structure for peer stats
 *                                   (derived from wmi_host_peer_stats)
 * @peer_rssi: rssi
 * @peer_rssi_seq_num: rssi sequence number
 * @peer_tx_rate: last tx data rate used for peer
 * @peer_rx_rate: last rx data rate used for peer
 * @currentper: Current PER
 * @retries: Retries happened during transmission
 * @txratecount:  Maximum Aggregation Size
 * @max4msframelen: Max4msframelen of tx rates used
 * @totalsubframes: Total no of subframes
 * @txbytes: No of bytes transmitted to the client
 * @nobuffs: Packet Loss due to buffer overflows
 * @excretries: Packet Loss due to excessive retries
 * @peer_rssi_changed: times peer's RSSI changed by a non-negligible amount
 */
struct ol_txrx_host_peer_stats {
    uint32_t  peer_rssi;
    uint32_t  peer_rssi_seq_num;
    uint32_t  peer_tx_rate;
    uint32_t  peer_rx_rate;
    uint32_t  currentper;
    uint32_t  retries;
    uint32_t  txratecount;
    uint32_t  max4msframelen;
    uint32_t  totalsubframes;
    uint32_t  txbytes;
    uint32_t  nobuffs[WME_AC_MAX];
    uint32_t  excretries[WME_AC_MAX];
    uint32_t  peer_rssi_changed;
};

/*
 * MACROS derived from wmi_unified.h specific to legacy path
 */
#define OL_TXRX_SGI_CONFIG_BIT 31
#define OL_TXRX_PEER_EXTD_STATS_SGI_CONFIG_SET (1 << OL_TXRX_SGI_CONFIG_BIT)
#define OL_TXRX_PEER_EXTD_STATS_SGI_CONFIG_GET(sgi_count) \
    (((sgi_count) & OL_TXRX_PEER_EXTD_STATS_SGI_CONFIG_SET) >> OL_TXRX_SGI_CONFIG_BIT)
#define OL_TXRX_PEER_EXTD_STATS_SGI_COUNT_SET(sgi_count) \
    (OL_TXRX_PEER_EXTD_STATS_SGI_CONFIG_SET | (sgi_count))
#define OL_TXRX_PEER_EXTD_STATS_SGI_COUNT_GET(sgi_count) \
    ((sgi_count) & (~OL_TXRX_PEER_EXTD_STATS_SGI_CONFIG_SET))
/**
 * struct ol_txrx_host_peer_extd_stats - structure for extended WMI peer stats
 *                                       (derived from wmi_host_peer_extd_stats)
 * @inactive_time: Peer Inactive time in seconds
 * @peer_chain_rssi: peer chain rssi
 * @rx_duration: rx duration
 * @peer_tx_bytes: Total TX bytes (including dot11 header) sent to peer
 * @peer_rx_bytes: Total RX bytes (including dot11 header) received from peer
 * @last_tx_rate_code: last TX ratecode
 * @last_tx_power: TX power used by peer - units are 0.5 dBm
 * @atf_tokens_allocated: tokens allocated for the peer at one ATF interval
 * @atf_tokens_utilized: tokens utilized by the peer at one ATF interval
 * @num_mu_tx_blacklisted: Blacklisted MU Tx count
 * @sgi_count: Tx sgi count of the peer
 * @reserved: for future extensions */ /* set to 0x0
 */
struct ol_txrx_host_peer_extd_stats {
    uint32_t inactive_time;
    uint32_t peer_chain_rssi;
    uint32_t rx_duration;
    uint32_t peer_tx_bytes;
    uint32_t peer_rx_bytes;
    uint32_t last_tx_rate_code;
    uint32_t last_tx_power;
    uint32_t atf_tokens_allocated;
    uint32_t atf_tokens_utilized;
    uint32_t num_mu_tx_blacklisted;
    uint32_t sgi_count;
    uint32_t reserved[2];
};

/**
 * structure ol_txrx_host_peer_retry_stats - structure for peer retry stats
 *                                      (derived from wmi_host_peer_retry_stats)
 * @ retry_counter_wraparnd_ind: wraparound counter indication
 * @ msdu_success: successfully transmitted msdus
 * @ msdu_retried: Retried msdus
 * @ msdu_mul_retried: msdus retried for more than once
 * @ msdu_failed: msdus failed
 * @ reserved: for furure extensions */ /* set to 0x0
 */
struct ol_txrx_host_peer_retry_stats {
    uint32_t retry_counter_wraparnd_ind;
    uint32_t msdus_success;
    uint32_t msdus_retried;
    uint32_t msdus_mul_retried;
    uint32_t msdus_failed;
    uint32_t reserved[4];
};

/**
 * struct ol_txrx_host_snr_info - WMI host Signal to noise ration info
 *                                (derived from wmi_host_snr_info)
 * @bcn_snr: beacon SNR
 * @dat_snr: Data frames SNR
 */
struct ol_txrx_host_snr_info {
    int32_t bcn_snr;
    int32_t dat_snr;
};

/**
 * struct ol_txrx_host_vdev_extd_stats - VDEV extended stats
 *                                       (derived from wmi_host_vdev_extd_stats)
 * @vdev_id: unique id identifying the VDEV, generated by the caller
 * @ppdu_aggr_cnt: No of Aggrs Queued to HW
 * @ppdu_noack: No of PPDU's not Acked includes both aggr and nonaggr's
 * @mpdu_queued: No of MPDU/Subframes's queued to HW in Aggregates
 * @ppdu_nonaggr_cnt: No of NonAggr/MPDU/Subframes's queued to HW
 *         in Legacy NonAggregates
 * @mpdu_sw_requed: No of MPDU/Subframes's SW requeued includes
 *         both Aggr and NonAggr
 * @mpdu_suc_retry: No of MPDU/Subframes's transmitted Successfully
 *         after Single/mul HW retry
 * @mpdu_suc_multitry: No of MPDU/Subframes's transmitted Success
 *         after Multiple HW retry
 * @mpdu_fail_retry: No of MPDU/Subframes's failed transmission
 *         after Multiple HW retry
 * @reserved[13]: for future extensions set to 0x0
 */
struct ol_txrx_host_vdev_extd_stats {
    uint32_t vdev_id;
    uint32_t ppdu_aggr_cnt;
    uint32_t ppdu_noack;
    uint32_t mpdu_queued;
    uint32_t ppdu_nonaggr_cnt;
    uint32_t mpdu_sw_requed;
    uint32_t mpdu_suc_retry;
    uint32_t mpdu_suc_multitry;
    uint32_t mpdu_fail_retry;
    uint32_t reserved[13];
};

/**
 * struct ol_txrx_host_vdev_stats - vdev stats structure
 *                                  derived from wmi_host_vdev_stats
 * @vdev_id: unique id identifying the VDEV, generated by the caller
 *        Rest all Only TLV
 * @vdev_snr: wmi_host_snr_info
 * @tx_frm_cnt: Total number of packets(per AC) that were successfully
 *              transmitted (with and without retries,
 *              including multi-cast, broadcast)
 * @rx_frm_cnt: Total number of packets that were successfully received
 *             (after appropriate filter rules including multi-cast, broadcast)
 * @multiple_retry_cnt: The number of MSDU packets and MMPDU frames per AC
 *      that the 802.11 station successfully transmitted after
 *      more than one retransmission attempt
 * @fail_cnt: Total number packets(per AC) failed to transmit
 * @rts_fail_cnt: Total number of RTS/CTS sequence failures for transmission
 *      of a packet
 * @rts_succ_cnt: Total number of RTS/CTS sequence success for transmission
 *      of a packet
 * @rx_err_cnt: The receive error count. HAL will provide the
 *      RxP FCS error global
 * @rx_discard_cnt: The sum of the receive error count and
 *      dropped-receive-buffer error count (FCS error)
 * @ack_fail_cnt: Total number packets failed transmit because of no
 *      ACK from the remote entity
 * @tx_rate_history:History of last ten transmit rate, in units of 500 kbit/sec
 * @bcn_rssi_history: History of last ten Beacon rssi of the connected Bss
 */
struct ol_txrx_host_vdev_stats {
    uint32_t vdev_id;
    struct ol_txrx_host_snr_info vdev_snr;
    uint32_t tx_frm_cnt[WME_AC_MAX];
    uint32_t rx_frm_cnt;
    uint32_t multiple_retry_cnt[WME_AC_MAX];
    uint32_t fail_cnt[WME_AC_MAX];
    uint32_t rts_fail_cnt;
    uint32_t rts_succ_cnt;
    uint32_t rx_err_cnt;
    uint32_t rx_discard_cnt;
    uint32_t ack_fail_cnt;
    uint32_t tx_rate_history[OL_TXRX_MAX_TX_RATE_VALUES];
    uint32_t bcn_rssi_history[OL_TXRX_MAX_RSSI_VALUES];
};

/**
 * struct ol_txrx_pdev_extd_stats - peer ext stats structure
 *                        (derived from wmi_host_pdev_ext_stats)
 * @rx_rssi_comb: RX rssi
 * @rx_rssi_chain0: RX rssi chain 0
 * @rx_rssi_chain1: RX rssi chain 1
 * @rx_rssi_chain2: RX rssi chain 2
 * @rx_rssi_chain3: RX rssi chain 3
 * @rx_mcs: RX MCS array
 * @tx_mcs: TX MCS array
 * @ack_rssi: Ack rssi
 */
struct ol_txrx_pdev_extd_stats {
    uint32_t rx_rssi_comb;
    uint32_t rx_rssi_chain0;
    uint32_t rx_rssi_chain1;
    uint32_t rx_rssi_chain2;
    uint32_t rx_rssi_chain3;
    uint32_t rx_mcs[10];
    uint32_t tx_mcs[10];
    uint32_t ack_rssi;
};
/**
 * struct ol_dbg_tx_stats - Debug stats (derived from wlan_dbg_tx_stats)
 * @comp_queued: Num HTT cookies queued to dispatch list
 * @comp_delivered: Num HTT cookies dispatched
 * @msdu_enqued: Num MSDU queued to WAL
 * @mpdu_enqued: Num MPDU queue to WAL
 * @wmm_drop: Num MSDUs dropped by WMM limit
 * @local_enqued: Num Local frames queued
 * @local_freed: Num Local frames done
 * @hw_queued: Num queued to HW
 * @hw_reaped: Num PPDU reaped from HW
 * @underrun: Num underruns
 * @hw_paused: HW Paused.
 * @tx_abort: Num PPDUs cleaned up in TX abort
 * @mpdus_requed: Num MPDUs requed by SW
 * @tx_ko: excessive retries
 * @tx_xretry:
 * @data_rc: data hw rate code
 * @self_triggers: Scheduler self triggers
 * @sw_retry_failure: frames dropped due to excessive sw retries
 * @illgl_rate_phy_err: illegal rate phy errors
 * @pdev_cont_xretry: wal pdev continous xretry
 * @pdev_tx_timeout: wal pdev continous xretry
 * @pdev_resets: wal pdev resets
 * @stateless_tid_alloc_failure: frames dropped due to non-availability of
 *                               stateless TIDs
 * @phy_underrun: PhY/BB underrun
 * @txop_ovf: MPDU is more than txop limit
 * @seq_posted: Number of Sequences posted
 * @seq_failed_queueing: Number of Sequences failed queueing
 * @seq_completed: Number of Sequences completed
 * @seq_restarted: Number of Sequences restarted
 * @mu_seq_posted: Number of MU Sequences posted
 * @mpdus_sw_flush: Num MPDUs flushed by SW, HWPAUSED, SW TXABORT
 *                  (Reset,channel change)
 * @mpdus_hw_filter: Num MPDUs filtered by HW, all filter condition
 *                   (TTL expired)
 * @mpdus_truncated: Num MPDUs truncated by PDG (TXOP, TBTT,
 *                   PPDU_duration based on rate, dyn_bw)
 * @mpdus_ack_failed: Num MPDUs that was tried but didn't receive ACK or BA
 * @mpdus_expired: Num MPDUs that was dropped du to expiry.
 * @mc_dropr: Num mc drops
 */
typedef struct {
        int32_t comp_queued;
        int32_t comp_delivered;
        int32_t msdu_enqued;

        int32_t mpdu_enqued;
        int32_t wmm_drop;
        int32_t local_enqued;
        int32_t local_freed;
        int32_t hw_queued;
        int32_t hw_reaped;
        int32_t underrun;
        uint32_t hw_paused;
        int32_t tx_abort;
        int32_t mpdus_requed;
        uint32_t tx_ko;
        uint32_t tx_xretry;
        uint32_t data_rc;
        uint32_t self_triggers;
        uint32_t sw_retry_failure;
        uint32_t illgl_rate_phy_err;
        uint32_t pdev_cont_xretry;
        uint32_t pdev_tx_timeout;
        uint32_t pdev_resets;
        uint32_t stateless_tid_alloc_failure;
        uint32_t phy_underrun;
        uint32_t txop_ovf;
        uint32_t seq_posted;
        uint32_t seq_failed_queueing;
        uint32_t seq_completed;
        uint32_t seq_restarted;
        uint32_t mu_seq_posted;
        int32_t mpdus_sw_flush;
        int32_t mpdus_hw_filter;
        int32_t mpdus_truncated;
        int32_t mpdus_ack_failed;
        int32_t mpdus_expired;
        uint32_t mc_drop;
} ol_dbg_tx_stats;

/**
 * struct ol_dbg_rx_stats - RX Debug stats (derived from wlan_dbg_rx_stats)
 * @mid_ppdu_route_change: Cnts any change in ring routing mid-ppdu
 * @status_rcvd: Total number of statuses processed
 * @r0_frags: Extra frags on rings 0
 * @r1_frags: Extra frags on rings 1
 * @r2_frags: Extra frags on rings 2
 * @r3_frags: Extra frags on rings 3
 * @htt_msdus: MSDUs delivered to HTT
 * @htt_mpdus: MPDUs delivered to HTT
 * @loc_msdus: MSDUs delivered to local stack
 * @loc_mpdus: MPDUS delivered to local stack
 * @oversize_amsdu: AMSDUs that have more MSDUs than the status ring size
 * @phy_errs: Number of PHY errors
 * @phy_err_drop: Number of PHY errors drops
 * @mpdu_errs: Number of mpdu errors - FCS, MIC, ENC etc.
 * @pdev_rx_timeout: Number of rx inactivity timeouts
 * @rx_ovfl_errs: Number of rx overflow errors.
 */
typedef struct {
        int32_t mid_ppdu_route_change;
        int32_t status_rcvd;
        int32_t r0_frags;
        int32_t r1_frags;
        int32_t r2_frags;
        int32_t r3_frags;
        int32_t htt_msdus;
        int32_t htt_mpdus;
        int32_t loc_msdus;
        int32_t loc_mpdus;
        int32_t oversize_amsdu;
        int32_t phy_errs;
        int32_t phy_err_drop;
        int32_t mpdu_errs;
        uint32_t pdev_rx_timeout;
        int32_t rx_ovfl_errs;
} ol_dbg_rx_stats;

/** struct ol_dbg_mem_stats - memory stats (derived from wlan_dbg_mem_stats)
 * @iram_free_size: IRAM free size on target
 * @dram_free_size: DRAM free size on target
 * @sram_free_size: SRAM free size on target
 */
typedef struct {
        uint32_t iram_free_size;
        uint32_t dram_free_size;
        /* Only Non-TLV */
        uint32_t sram_free_size;
} ol_dbg_mem_stats;

typedef struct {
        /* Only TLV */
        int32_t dummy;/* REMOVE THIS ONCE REAL PEER STAT COUNTERS ARE ADDED */
} ol_dbg_peer_stats;

/**
 * struct ol_dbg_stats - host debug stats (derived from wlan_dbg_stats)
 * @tx: TX stats of type ol_dbg_tx_stats
 * @rx: RX stats of type ol_dbg_rx_stats
 * @mem: Memory stats of type ol_dbg_mem_stats
 * @peer: peer stats of type ol_dbg_peer_stats
 */
typedef struct {
        ol_dbg_tx_stats tx;
        ol_dbg_rx_stats rx;
        ol_dbg_mem_stats mem;
        ol_dbg_peer_stats peer;
} ol_dbg_stats;

/*
** structure to hold all stats information
** for offload device interface
*/
struct ol_stats {
    int txrx_stats_level;
    struct ol_txrx_stats txrx_stats;
    ol_dbg_stats stats;
    struct ol_ath_radiostats interface_stats;
    struct wlan_dbg_tidq_stats tidq_stats;
    struct cdp_pdev_stats pdev_stats;
    struct ol_txrx_data_stats legacy_stats;
};
/*
 * Structure to consolidate host stats
 */
struct ieee80211req_ol_ath_host_stats {
    struct ol_txrx_stats txrx_stats;
    struct {
        int pkt_q_fail_count;
        int pkt_q_empty_count;
        int send_q_empty_count;
    } htc;
    struct {
        int pipe_no_resrc_count;
        int ce_ring_delta_fail_count;
    } hif;
};


#endif /* _OL_TXRX_STATS__H_ */
