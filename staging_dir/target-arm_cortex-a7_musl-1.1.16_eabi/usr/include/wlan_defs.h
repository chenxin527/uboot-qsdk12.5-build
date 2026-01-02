/*
 * Copyright (c) 2012, 2015-2016, 2018 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */
//------------------------------------------------------------------------------
// <copyright file="wlan_defs.h" company="Atheros">
//    Copyright (c) 2004-2010 Atheros Corporation.  All rights reserved.
// $ATH_LICENSE_HOSTSDK0_C$
//------------------------------------------------------------------------------
//==============================================================================
// Author(s): ="Atheros"
//==============================================================================
#ifndef __WLAN_DEFS_H__
#define __WLAN_DEFS_H__

/*
 * This file contains WLAN definitions that may be used across both
 * Host and Target software.  
 */

#ifndef offsetof
#define offsetof(type, field)   ((unsigned int)(&((type *)0)->field))
#endif

#define MAX_SPATIAL_STREAM   4

/* Use below constant for pergrine derivatives */
#define MAX_SPATIAL_STREAM_AR988X   3

typedef enum {
    MODE_11A        = 0,   /* 11a Mode */
    MODE_11G        = 1,   /* 11b/g Mode */
    MODE_11B        = 2,   /* 11b Mode */
    MODE_11GONLY    = 3,   /* 11g only Mode */
    MODE_11NA_HT20   = 4,  /* 11a HT20 mode */
    MODE_11NG_HT20   = 5,  /* 11g HT20 mode */
    MODE_11NA_HT40   = 6,  /* 11a HT40 mode */
    MODE_11NG_HT40   = 7,  /* 11g HT40 mode */
    MODE_11AC_VHT20 = 8,
    MODE_11AC_VHT40 = 9,
    MODE_11AC_VHT80 = 10,
    MODE_11AC_VHT20_2G = 11,
    MODE_11AC_VHT40_2G = 12,
    MODE_11AC_VHT80_2G = 13,

#if defined(CONFIG_AR900B_SUPPORT) || defined(CONFIG_QCA9984_SUPPORT) || defined(CONFIG_IPQ4019_SUPPORT) || defined(CONFIG_QCA9888_SUPPORT) || defined(AR900B)  || defined(QCA9984) || defined(IPQ4019) || defined(QCA9888)
    /* current WLAN chips */
    MODE_11AC_VHT80_80 = 14,
    MODE_11AC_VHT160 = 15,
    MODE_UNKNOWN    = 16,
  #ifdef ATHR_WIN_NWF
    PHY_MODE_MAX    = 16
  #else
    MODE_MAX        = 16
  #endif

#else
    /* legacy WLAN chips (Peregrine/Swift) */
    MODE_UNKNOWN    = 14,
    MODE_MAX        = 14
#endif
} WLAN_PHY_MODE;

typedef enum {
    VHT_MODE_NONE = 0,  /* NON VHT Mode, e.g., HT, DSSS, CCK */
    VHT_MODE_20M = 1,
    VHT_MODE_40M = 2,
    VHT_MODE_80M = 3,
    VHT_MODE_160M = 4
} VHT_OPER_MODE;

typedef enum {
    WLAN_11A_CAPABILITY   = 1,
    WLAN_11G_CAPABILITY   = 2,
    WLAN_11AG_CAPABILITY  = 3,
}WLAN_CAPABILITY;

#if defined(CONFIG_AR900B_SUPPORT) || defined(CONFIG_QCA9984_SUPPORT) || defined(CONFIG_IPQ4019_SUPPORT) || defined(CONFIG_QCA9888_SUPPORT) || defined(AR900B)  || defined(QCA9984) || defined(IPQ4019) || defined(QCA9888)
#define A_RATEMASK A_UINT64
#else
#define A_RATEMASK A_UINT32
#endif

#define A_RATEMASK_NUM_OCTET (sizeof (A_RATEMASK))
#define A_RATEMASK_NUM_BITS ((sizeof (A_RATEMASK)) << 3)


#define IS_MODE_VHT(mode) (((mode) == MODE_11AC_VHT20) || \
        ((mode) == MODE_11AC_VHT40) || \
        ((mode) == MODE_11AC_VHT80) || \
        ((mode) == MODE_11AC_VHT160) || \
        ((mode) == MODE_11AC_VHT80_80))

#define IS_MODE_VHT_2G(mode) (((mode) == MODE_11AC_VHT20_2G) || \
        ((mode) == MODE_11AC_VHT40_2G) || \
        ((mode) == MODE_11AC_VHT80_2G))


#define IS_MODE_11A(mode)       (((mode) == MODE_11A) || \
                                 ((mode) == MODE_11NA_HT20) || \
                                 ((mode) == MODE_11NA_HT40) || \
                                 (IS_MODE_VHT(mode)))
                                 
#define IS_MODE_11B(mode)       ((mode) == MODE_11B)
#define IS_MODE_11G(mode)       (((mode) == MODE_11G) || \
                                 ((mode) == MODE_11GONLY) || \
                                 ((mode) == MODE_11NG_HT20) || \
                                 ((mode) == MODE_11NG_HT40) || \
                                 (IS_MODE_VHT_2G(mode)))
#define IS_MODE_11GN(mode)      (((mode) == MODE_11NG_HT20) || \
                                 ((mode) == MODE_11NG_HT40))
#define IS_MODE_11GONLY(mode)   ((mode) == MODE_11GONLY)


enum {
    REGDMN_MODE_11A              = 0x00001,      /* 11a channels */
    REGDMN_MODE_TURBO            = 0x00002,      /* 11a turbo-only channels */
    REGDMN_MODE_11B              = 0x00004,      /* 11b channels */
    REGDMN_MODE_PUREG            = 0x00008,      /* 11g channels (OFDM only) */
    REGDMN_MODE_11G              = 0x00008,      /* XXX historical */
    REGDMN_MODE_108G             = 0x00020,      /* 11g+Turbo channels */
    REGDMN_MODE_108A             = 0x00040,      /* 11a+Turbo channels */
    REGDMN_MODE_XR               = 0x00100,      /* XR channels */
    REGDMN_MODE_11A_HALF_RATE    = 0x00200,      /* 11A half rate channels */
    REGDMN_MODE_11A_QUARTER_RATE = 0x00400,      /* 11A quarter rate channels */
    REGDMN_MODE_11NG_HT20        = 0x00800,      /* 11N-G HT20 channels */
    REGDMN_MODE_11NA_HT20        = 0x01000,      /* 11N-A HT20 channels */
    REGDMN_MODE_11NG_HT40PLUS    = 0x02000,      /* 11N-G HT40 + channels */
    REGDMN_MODE_11NG_HT40MINUS   = 0x04000,      /* 11N-G HT40 - channels */
    REGDMN_MODE_11NA_HT40PLUS    = 0x08000,      /* 11N-A HT40 + channels */
    REGDMN_MODE_11NA_HT40MINUS   = 0x10000,      /* 11N-A HT40 - channels */
    REGDMN_MODE_11AC_VHT20       = 0x20000,      /* 5Ghz, VHT20 */
    REGDMN_MODE_11AC_VHT40PLUS   = 0x40000,      /* 5Ghz, VHT40 + channels */
    REGDMN_MODE_11AC_VHT40MINUS  = 0x80000,      /* 5Ghz  VHT40 - channels */
    REGDMN_MODE_11AC_VHT80       = 0x100000,     /* 5Ghz, VHT80 channels */
    REGDMN_MODE_11AC_VHT160      = 0x200000,     /* 5Ghz, VHT160 channels */
    REGDMN_MODE_11AC_VHT80_80    = 0x400000,     /* 5Ghz, VHT80+80 channels */
    REGDMN_MODE_ALL              = 0xffffffff
};

#define REGDMN_CAP1_CHAN_HALF_RATE        0x00000001
#define REGDMN_CAP1_CHAN_QUARTER_RATE     0x00000002
#define REGDMN_CAP1_CHAN_HAL49GHZ         0x00000004


/* regulatory capabilities */
#define REGDMN_EEPROM_EEREGCAP_EN_FCC_MIDBAND   0x0040
#define REGDMN_EEPROM_EEREGCAP_EN_KK_U1_EVEN    0x0080
#define REGDMN_EEPROM_EEREGCAP_EN_KK_U2         0x0100
#define REGDMN_EEPROM_EEREGCAP_EN_KK_MIDBAND    0x0200
#define REGDMN_EEPROM_EEREGCAP_EN_KK_U1_ODD     0x0400
#define REGDMN_EEPROM_EEREGCAP_EN_KK_NEW_11A    0x0800

typedef struct {
    A_UINT32 eeprom_rd;      //regdomain value specified in EEPROM
    A_UINT32 eeprom_rd_ext;  //regdomain 
    A_UINT32 regcap1;        // CAP1 capabilities bit map.
    A_UINT32 regcap2;        // REGDMN EEPROM CAP.
    A_UINT32 wireless_modes; // REGDMN MODE 
    A_UINT32 low_2ghz_chan;
    A_UINT32 high_2ghz_chan;
    A_UINT32 low_5ghz_chan;
    A_UINT32 high_5ghz_chan;
} HAL_REG_CAPABILITIES;

/*
 * Used to update rate-control logic with the status of the tx-completion.
 * In host-based implementation of the rate-control feature, this struture is used to 
 * create the payload for HTT message/s from target to host.
 */

typedef struct {
    A_UINT8 rateCode;
    A_UINT8 flags;
}RATE_CODE;

typedef struct {
    RATE_CODE ptx_rc; /* rate code, bw, chain mask sgi */
    A_UINT8 reserved[2];
    A_UINT32 flags;       /* Encodes information such as excessive
                             retransmission, aggregate, some info
                             from .11 frame control,
                             STBC, LDPC, (SGI and Tx Chain Mask
                             are encoded in ptx_rc->flags field),
                             AMPDU truncation (BT/time based etc.),
                             RTS/CTS attempt  */
    A_UINT32 num_enqued;  /* # of MPDUs (for non-AMPDU 1) for this rate */
    A_UINT32 num_retries; /* Total # of transmission attempt for this rate */
    A_UINT32 num_failed;  /* # of failed MPDUs in A-MPDU, 0 otherwise */
    A_UINT32 ack_rssi;    /* ACK RSSI: b'7..b'0 avg RSSI across all chain */
    A_UINT32 time_stamp ; /* ACK timestamp (helps determine age) */
    A_UINT32 is_probe;    /* Valid if probing. Else, 0 */
    A_UINT32 ba_win_size; /* b'7..b0, block Ack Window size, b'31..b8 Resvd */
    A_UINT32 failed_ba_bmap_0_31; /* failed BA bitmap 0..31 */
    A_UINT32 failed_ba_bmap_32_63; /* failed BA bitmap 32..63 */
    A_UINT32 bmap_tried_0_31; /* enqued bitmap 0..31 */
    A_UINT32 bmap_tried_32_63; /* enqued bitmap 32..63 */
} RC_TX_DONE_PARAMS;


#define RC_SET_TX_DONE_INFO(_dst, _rc, _f, _nq, _nr, _nf, _rssi, _ts) \
    do {                                                              \
        (_dst).ptx_rc.rateCode = (_rc).rateCode;                      \
        (_dst).ptx_rc.flags    = (_rc).flags;                         \
        (_dst).flags           = (_f);                                \
        (_dst).num_enqued      = (_nq);                               \
        (_dst).num_retries     = (_nr);                               \
        (_dst).num_failed      = (_nf);                               \
        (_dst).ack_rssi        = (_rssi);                             \
        (_dst).time_stamp      = (_ts);                               \
    } while (0)

#define RC_SET_TXBF_DONE_INFO(_dst, _f)                                 \
    do {                                                                \
        (_dst).flags           |= (_f);                                 \
    } while (0)

#define NUM_SCHED_ENTRIES           4

/* pergrine derivatives use this constant */
#define NUM_SCHED_ENTRIES_AR988X    2

#define NUM_DYN_BW_MAX              4

/* Current Product only uses 20/40/80/160 */
#if defined(CONFIG_160MHZ_SUPPORT)
	#define NUM_DYN_BW                  4
#else
	#define NUM_DYN_BW                  3
#endif

#define NUM_DYN_BW_MASK             0x3

#define PROD_SCHED_BW_ENTRIES       (NUM_SCHED_ENTRIES * NUM_DYN_BW)
typedef A_UINT8 A_RATE;
typedef A_UINT8 A_RATECODE;

// Extend rate table module for 80+80/160 MHz first

#if defined(CONFIG_AR900B_SUPPORT) || defined(CONFIG_QCA9984_SUPPORT) || defined(CONFIG_IPQ4019_SUPPORT) || defined(CONFIG_QCA9888_SUPPORT) || defined(AR900B)  || defined(QCA9984) || defined(IPQ4019) || defined(QCA9888)
typedef struct{
    A_UINT32    psdu_len    [NUM_DYN_BW * NUM_SCHED_ENTRIES];
    A_UINT16    flags[NUM_SCHED_ENTRIES][NUM_DYN_BW];
    A_RATE      rix[NUM_SCHED_ENTRIES][NUM_DYN_BW];
    A_UINT8     tpc[NUM_SCHED_ENTRIES][NUM_DYN_BW];
    A_UINT32    antmask[NUM_SCHED_ENTRIES];
    A_UINT8     num_mpdus   [NUM_DYN_BW * NUM_SCHED_ENTRIES];
    A_UINT16    txbf_cv_len;
    A_UINT32    txbf_cv_ptr;
    A_UINT16    txbf_flags;
    A_UINT16    txbf_cv_size;
    A_UINT8     txbf_nc_idx;
    A_UINT8     tries[NUM_SCHED_ENTRIES];
    A_UINT8     bw_mask[NUM_SCHED_ENTRIES];
    A_UINT8     max_bw[NUM_SCHED_ENTRIES];
    A_UINT8     num_sched_entries;
    A_UINT8     paprd_mask;
    A_UINT8     rts_rix;
    A_UINT8     sh_pream;
    A_UINT8     min_spacing_1_4_us;
    A_UINT8     fixed_delims;
    A_UINT8     bw_in_service;
    A_RATE      probe_rix;
    A_UINT8     rtscts_tpc;    
    A_UINT8     dd_profile;
} RC_TX_RATE_SCHEDULE;

#else
typedef struct{
    A_UINT32    psdu_len    [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
    A_UINT16    flags       [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
    A_RATE      rix         [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
    A_UINT8     tpc         [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
    A_UINT8     num_mpdus   [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
    A_UINT32    antmask     [NUM_SCHED_ENTRIES_AR988X];
    A_UINT32    txbf_cv_ptr;
    A_UINT16    txbf_cv_len;
    A_UINT8     tries       [NUM_SCHED_ENTRIES_AR988X];
    A_UINT8     num_valid_rates;
    A_UINT8     paprd_mask;
    A_UINT8     rts_rix;
    A_UINT8     sh_pream;
    A_UINT8     min_spacing_1_4_us;
    A_UINT8     fixed_delims;
    A_UINT8     bw_in_service;
    A_RATE      probe_rix;
    A_UINT8     rtscts_tpc;
} RC_TX_RATE_SCHEDULE;
#endif

#if !defined(AR9888)
typedef struct{
    A_UINT16    flags[NUM_DYN_BW];
    A_RATE      rix[NUM_DYN_BW];
#ifdef DYN_TPC_ENABLE
    A_UINT8     tpc[NUM_DYN_BW];
#endif
#ifdef SECTORED_ANTENNA
    A_UINT32    antmask;
#endif
    A_UINT8     num_valid_rates;
    A_UINT8     rts_rix;
    A_UINT8     sh_pream;
    A_UINT8     bw_in_service;
    A_RATE      probe_rix;
    A_UINT8     dd_profile;
} RC_TX_RATE_INFO;
#else
typedef struct{
    A_UINT16    flags       [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
    A_RATE      rix         [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
#ifdef DYN_TPC_ENABLE
    A_UINT8     tpc         [NUM_DYN_BW * NUM_SCHED_ENTRIES_AR988X];
#endif
#ifdef SECTORED_ANTENNA
    A_UINT32    antmask     [NUM_SCHED_ENTRIES_AR988X];
#endif
    A_UINT8     tries       [NUM_SCHED_ENTRIES_AR988X];
    A_UINT8     num_valid_rates;
    A_UINT8     rts_rix;
    A_UINT8     sh_pream;
    A_UINT8     bw_in_service;
    A_RATE      probe_rix;
    A_UINT8     dd_profile;
} RC_TX_RATE_INFO;

/* WHAL_RC_INIT_RC_MASKS only applies to Peregrine / Swift */
#define WHAL_RC_INIT_RC_MASKS(_rm) do {                                     \
        _rm[WHAL_RC_MASK_IDX_NON_HT] = A_RATEMASK_OFDM_CCK;                 \
        _rm[WHAL_RC_MASK_IDX_HT_20]  = A_RATEMASK_HT_20;                    \
        _rm[WHAL_RC_MASK_IDX_HT_40]  = A_RATEMASK_HT_40;                    \
        _rm[WHAL_RC_MASK_IDX_VHT_20] = A_RATEMASK_VHT_20;                   \
        _rm[WHAL_RC_MASK_IDX_VHT_40] = A_RATEMASK_VHT_40;                   \
        _rm[WHAL_RC_MASK_IDX_VHT_80] = A_RATEMASK_VHT_80;                   \
        } while (0)

#endif

/**
 * strucutre describing host memory chunk.
 */
typedef struct {
   /** id of the request that is passed up in service ready */
   A_UINT32 req_id; 
   /** the physical address the memory chunk */
   A_UINT32 ptr; 
   /** size of the chunk */
   A_UINT32 size;
} wlan_host_memory_chunk;

#define NUM_UNITS_IS_NUM_VDEVS   0x1
#define NUM_UNITS_IS_NUM_PEERS   0x2
#define NUM_UNITS_IS_NUM_ACTIVE_PEERS   0x4
#define REQ_TO_HOST_FOR_CONT_MEMORY     0X8  /* Request host to allocate memory contiguously */

/**
 * structure used by FW for requesting host memory 
 */
typedef struct {
    /** ID of the request - of type WMI_HOST_MEM_REQ_ID */
    A_UINT32    req_id;
    /** size of the  of each unit */
    A_UINT32    unit_size;
    /**
     * flags to  indicate that
     * the number units is dependent
     * on number of resources(num vdevs num peers .. etc)
     */
    A_UINT32    num_unit_info;
    /*
     * actual number of units to allocate . if flags in the num_unit_info
     * indicate that number of units is tied to number of a particular
     * resource to allocate then  num_units filed is set to 0 and host
     * will derive the number units from number of the resources it is
     * requesting.
     */
    A_UINT32    num_units;
} wlan_host_mem_req;

typedef enum {
    IGNORE_DTIM = 0x01,
    NORMAL_DTIM = 0x02,
    STICK_DTIM  = 0x03,
    AUTO_DTIM   = 0x04,
} BEACON_DTIM_POLICY;

#define WMI_DTIM_POLICY BEACON_DTIM_POLICY /* alias */

/* During test it is observed that 6 * 400 = 2400 can
 * be alloced in addition to CFG_TGT_NUM_MSDU_DESC.
 * If there is any change memory requirement, this number
 * needs to be revisited. */
#define TOTAL_VOW_ALLOCABLE 2400 
#define VOW_DESC_GRAB_MAX 800

#define VOW_GET_NUM_VI_STA(vow_config) (((vow_config) & 0xffff0000) >> 16)
#define VOW_GET_DESC_PER_VI_STA(vow_config) ((vow_config) & 0x0000ffff)

/***TODO!!! Get these values dynamically in WMI_READY event and use it to calculate the mem req*/
/* size in bytes required for msdu descriptor. If it changes, this should be updated. LARGE_AP
 * case is not considered. LARGE_AP is disabled when VoW is enabled.*/
#define MSDU_DESC_SIZE 20
 
/* size in bytes required to support a peer in target.
 * This obtained by considering Two tids per peer.
 * peer structure = 168 bytes
 * tid = 96 bytes (per sta 2 means we need 192 bytes)
 * peer_cb = 16 * 2
 * key = 52 * 2
 * AST = 12 * 2
 * rate, reorder.. = 384
 * smart antenna = 50
 */
#define MEMORY_REQ_FOR_PEER 800

struct wlan_dbg_tx_stats {
    /* Num HTT cookies queued to dispatch list */
    A_INT32 comp_queued;
    /* Num HTT cookies dispatched */
    A_INT32 comp_delivered;
    /* Num MSDU queued to WAL */
    A_INT32 msdu_enqued;
    /* Num MPDU queue to WAL */
    A_INT32 mpdu_enqued;
    /* Num MSDUs dropped by WMM limit */
    A_INT32 wmm_drop;
    /* Num Local frames queued */
    A_INT32 local_enqued;
    /* Num Local frames done */
    A_INT32 local_freed;
    /* Num queued to HW */
    A_INT32 hw_queued;
    /* Num PPDU reaped from HW */
    A_INT32 hw_reaped;
    /* Num underruns */
    A_INT32 underrun;
    /* HW Paused. */
    A_UINT32 hw_paused;
    /* Num PPDUs cleaned up in TX abort */
    A_INT32 tx_abort;
    /* Num MPDUs requed by SW */
    A_INT32 mpdus_requed;
    /* excessive retries */
    A_UINT32 tx_xretry; 
    /* data hw rate code */
    A_UINT32 data_rc;
    /* Scheduler self triggers */
    A_UINT32 self_triggers;
    /* frames dropped due to excessive sw retries */
    A_UINT32 sw_retry_failure;
    /* illegal rate phy errors  */
    A_UINT32 illgl_rate_phy_err;
    /* wal pdev continous xretry */
    A_UINT32 pdev_cont_xretry;
    /* wal pdev continous xretry */
    A_UINT32 pdev_tx_timeout;
    /* wal pdev resets  */
    A_UINT32 pdev_resets;
    /* frames dropped due to non-availability of stateless TIDs */
    A_UINT32 stateless_tid_alloc_failure;
    /* PhY/BB underrun */
    A_UINT32 phy_underrun;
    /* MPDU is more than txop limit */
    A_UINT32 txop_ovf;
    /* Number of Sequences posted */
    A_UINT32 seq_posted;
    /* Number of Sequences failed queueing */
    A_UINT32 seq_failed_queueing;
    /* Number of Sequences completed */
    A_UINT32 seq_completed;
    /* Number of Sequences restarted */
    A_UINT32 seq_restarted;
    /* Number of MU Sequences posted */
    A_UINT32 mu_seq_posted;
    /* Num MPDUs flushed by SW, HWPAUSED, SW TXABORT (Reset,channel change) */
    A_INT32 mpdus_sw_flush;
    /* Num MPDUs filtered by HW, all filter condition (TTL expired) */
    A_INT32 mpdus_hw_filter;
    /* Num MPDUs truncated by PDG (TXOP, TBTT, PPDU_duration based on rate, dyn_bw) */
    A_INT32 mpdus_truncated;
    /* Num MPDUs that was tried but didn't receive ACK or BA */
    A_INT32 mpdus_ack_failed;
    /* Num MPDUs that was dropped du to expiry. */
    A_INT32 mpdus_expired;
    /* Num mc drops */
    A_UINT32 mc_drop;
};

struct wlan_dbg_rx_stats {
    /* Cnts any change in ring routing mid-ppdu */
    A_INT32 mid_ppdu_route_change;
    /* Total number of statuses processed */
    A_INT32 status_rcvd;
    /* Extra frags on rings 0-3 */
    A_INT32 r0_frags;
    A_INT32 r1_frags;
    A_INT32 r2_frags;
    //A_INT32 r3_frags;
    /* MSDUs / MPDUs delivered to HTT */
    A_INT32 htt_msdus;
    A_INT32 htt_mpdus;
    /* MSDUs / MPDUs delivered to local stack */
    A_INT32 loc_msdus;
    A_INT32 loc_mpdus;
    /* AMSDUs that have more MSDUs than the status ring size */
    A_INT32 oversize_amsdu;
    /* Number of PHY errors */
    A_INT32 phy_errs;
    /* Number of PHY errors drops */
    A_INT32 phy_err_drop;
    /* Number of mpdu errors - FCS, MIC, ENC etc. */
    A_INT32 mpdu_errs;
    /* Number of rx inactivity timeouts */
    A_UINT32 pdev_rx_timeout;
    /* Number of rx overflow errors. */
    A_INT32 rx_ovfl_errs;
};

struct wlan_dbg_mem_stats {
    A_UINT32 iram_free_size;
    A_UINT32 dram_free_size;
    A_UINT32 sram_free_size;
};

struct wlan_dbg_peer_stats {

    //A_INT32 dummy; /* REMOVE THIS ONCE REAL PEER STAT COUNTERS ARE ADDED */
};

typedef struct wlan_dbg_tx_path_stats {
    A_UINT32 tx_de_cache_miss;
    A_UINT32 tx_enqueue_peer_invalid;
    A_UINT32 tx_burst_disable_cong_ctrl;
    A_UINT32 tx_de_lookup_failed;
    A_UINT32 tx_delay_proc;
    A_UINT32 tt_prefetch_suspend;
    A_UINT32 short_pkt;
    A_UINT32 total_enqueue; /* units = frames */
    A_UINT32 peer_id_invalid;
    A_UINT32 host_inspect;
    A_UINT32 pdev_zero_discard;
    A_UINT32 tickle_proc_sched;
    A_UINT32 residue_cleanup;
} wlan_dbg_tx_path_stats_t;

typedef struct {
    A_UINT32 mcs[10];
    A_UINT32 sgi[10];
    A_UINT32 nss[4];
    A_UINT32 nsts;
    A_UINT32 stbc[10];
    A_UINT32 bw[4];
    A_UINT32 pream[6];
    A_UINT32 ldpc;
    A_UINT32 txbf;
    A_UINT32 rssi_chain0;
    A_UINT32 rssi_chain1;
    A_UINT32 rssi_chain2;
    A_UINT32 rssi_chain3;
    A_UINT8 mgmt_rssi;
    A_UINT8 data_rssi;
    A_UINT8 rssi_comb_ht;
    A_INT8 reserved;
    A_INT32 nf_dbm;
    A_INT32 rssi_dbm;
} wlan_dbg_rx_rate_info_t;

typedef struct {
    A_UINT32 mcs[10];
    A_UINT32 sgi[10];
    A_UINT32 nss[4];
    A_UINT32 stbc[10];
    A_UINT32 bw[4];
    A_UINT32 pream[4];
    A_UINT32 ldpc;
    A_UINT32 rts_cnt;
    A_UINT32 ack_rssi;
    A_UINT32 mu_mcs[10]; /* counts MU transmissions for each MCS index 0-9 */
    A_UINT32 mu_nss[2];  /* counts MU transmissions for each NSS */
} wlan_dbg_tx_rate_info_t ;

#define WHAL_DBG_PHY_ERR_MAXCNT 21
#define WHAL_DBG_SIFS_ERR_MAXCNT 8
#define WHAL_DBG_SIFS_STATUS_MAXCNT 8
#define WHAL_DBG_CMD_RESULT_MAXCNT 8
#define WHAL_DBG_CMD_STALL_ERR_MAXCNT 4
#define WHAL_DBG_FLUSH_REASON_MAXCNT 18

typedef enum {
    WIFI_URRN_STATS_FIRST_PKT,
    WIFI_URRN_STATS_BETWEEN_MPDU,
    WIFI_URRN_STATS_WITHIN_MPDU,
    WHAL_MAX_URRN_STATS
} wifi_urrn_type_t;

#define NUM_OF_SOUNDING_STATS_WORDS   (3 * 4) /* (max_users * max_bw) */
typedef struct wlan_dbg_txbf_snd_stats {
    A_UINT32 cbf_20[4];
    A_UINT32 cbf_40[4];
    A_UINT32 cbf_80[4];
    A_UINT32 cbf_160[4];
    
    /*
     * The sounding array is a 2-D array stored as an 1-D array of
     * A_UINT32. The stats for a particular mu_user/bw combination is
     * referenced with the following:
     *
     * 		sounding[(mu_user* max_bw) + bw]"
     *
     * ... where max_bw == 4 for 160mhz HW and max_bw == 3 for
     * everything else. The maximum bandwidth must be determined
     * through some other means. 
     */
    A_UINT32 sounding[NUM_OF_SOUNDING_STATS_WORDS];
}wlan_dbg_txbf_snd_stats_t;

typedef struct wlan_dbg_wifi2_error_stats {
    A_UINT32 urrn_stats[WHAL_MAX_URRN_STATS];
    A_UINT32 flush_errs[WHAL_DBG_FLUSH_REASON_MAXCNT];
    A_UINT32 schd_stall_errs[WHAL_DBG_CMD_STALL_ERR_MAXCNT];
    A_UINT32 schd_cmd_result[WHAL_DBG_CMD_RESULT_MAXCNT];
    A_UINT32 sifs_status[WHAL_DBG_SIFS_STATUS_MAXCNT];
    A_UINT8  phy_errs[WHAL_DBG_PHY_ERR_MAXCNT];
    A_UINT32 rx_rate_inval;
}wlan_dbg_wifi2_error_stats_t;

typedef struct wlan_dbg_wifi2_error2_stats {
    A_UINT32 schd_errs[WHAL_DBG_CMD_STALL_ERR_MAXCNT];
    A_UINT32 sifs_errs[WHAL_DBG_SIFS_ERR_MAXCNT];
}wlan_dbg_wifi2_error2_stats_t;

#define WLAN_DBG_STATS_SIZE_TXBF_VHT 10
#define WLAN_DBG_STATS_SIZE_TXBF_HT 8
#define WLAN_DBG_STATS_SIZE_TXBF_OFDM 8

typedef struct wlan_dbg_txbf_data_stats {
    A_UINT32 tx_txbf_vht[WLAN_DBG_STATS_SIZE_TXBF_VHT];
    A_UINT32 rx_txbf_vht[WLAN_DBG_STATS_SIZE_TXBF_VHT];
    A_UINT32 tx_txbf_ht[WLAN_DBG_STATS_SIZE_TXBF_HT];
    A_UINT32 tx_txbf_ofdm[WLAN_DBG_STATS_SIZE_TXBF_OFDM];
    A_UINT32 tx_txbf_ibf_vht[WLAN_DBG_STATS_SIZE_TXBF_VHT];
    A_UINT32 tx_txbf_ibf_ht[WLAN_DBG_STATS_SIZE_TXBF_HT];
    A_UINT32 tx_txbf_ibf_ofdm[WLAN_DBG_STATS_SIZE_TXBF_OFDM];
} wlan_dbg_txbf_data_stats_t;

/*
 * This struct's stats are reported in the HTT_T2H STATS_CONF message
 * using HTT_DBG_STATS_TX_MU_INFO if the VAP_ID field is non-zero.
 * (A HTT_DBG_STATS_TX_MU_INFO tag and a 0x0 VAP_ID indicate that
 * the STATS_CONF TLV contains wlan_dbg_tx_mu_stats instead.)
 */
struct wlan_dbg_tx_mu_stats_vap {
    A_UINT32 mu_sch_nusers_2;
    A_UINT32 mu_sch_nusers_3;
    /*
     * In the mu_mpdus_queued_usr and mu_mpdus_failed_usr arrays,
     * the indices are for the different users within a MU transmission.
     * Index 0 is for the primary MU user, index 1 is for the secondary
     * MU user, etc.
     */
    A_UINT32 mu_mpdus_queued_usr[4];
    A_UINT32 mu_mpdus_failed_usr[4];
};
 
/*
 * This struct's stats are reported in the HTT_T2H STATS_CONF message
 * using HTT_DBG_STATS_TX_SELFGEN_INFO if the VAP_ID field is non-zero.
 * (A HTT_DBG_STATS_TX_SELFGEN_INFO tag and a 0x0 VAP_ID indicate that
 * the STATS_CONF TLV contains wlan_dbg_tx_selfgen_stats instead.)
 */
struct wlan_dbg_tx_selfgen_stats_vap {
    A_UINT32 su_ndpa;     /* num SU-NDPA frames transmitted */
    A_UINT32 su_ndp;      /* num SU-NDP frames transmitted */
    A_UINT32 mu_ndpa;     /* num MU-NDPA frames transmitted */
    A_UINT32 mu_ndp;      /* num MU-NDP frames transmitted */
    A_UINT32 mu_brpoll_1; /* num BRPOLL frames transmitted to second user */
    A_UINT32 mu_brpoll_2; /* num BRPOLL frames transmitted to third user */
    A_UINT32 su_bar;      /* num BAR frames transmitted in SU seq to flush BA state */
    A_UINT32 su_cts;      /* num CTS2SELf frames to extend SU-data burst */
    A_UINT32 su_ndpa_err; /* num SU-NDPA frames not transmitted due to HW pause */
    A_UINT32 su_ndp_err;  /* num SU-NDP frames that didn't receive correct CBF */
};

struct wlan_dbg_tx_mu_stats {
    A_UINT32 mu_sch_nusers_2;
    A_UINT32 mu_sch_nusers_3;
    A_UINT32 mu_mpdus_queued_usr[4];
    A_UINT32 mu_mpdus_tried_usr[4];
    A_UINT32 mu_mpdus_failed_usr[4];
    A_UINT32 mu_mpdus_requeued_usr[4];
    A_UINT32 mu_err_no_ba_usr[4];
    A_UINT32 mu_mpdu_underrun_usr[4];
    A_UINT32 mu_ampdu_underrun_usr[4];
};

struct wlan_dbg_tx_selfgen_stats {
    A_UINT32 su_ndpa;              /* num SU-NDPA frames transmitted */
    A_UINT32 su_ndp;               /* num SU-NDP frames transmitted */
    A_UINT32 mu_ndpa;              /* num MU-NDPA frames transmitted */
    A_UINT32 mu_ndp;               /* num MU-NDP frames transmitted */
    A_UINT32 mu_brpoll_1;          /* num BRPOLL frames transmitted to second user */
    A_UINT32 mu_brpoll_2;          /* num BRPOLL frames transmitted to third user */
    A_UINT32 su_bar;               /* num BAR frames transmitted in SU seq to flush BA state */
    A_UINT32 mu_bar_1;             /* num BAR frames to second user in MU-PPDU */
    A_UINT32 mu_bar_2;             /* num BAR frames to third user in MU-PPDU */
    A_UINT32 su_cts;               /* num CTS2SELf frames to extend SU-data burst */
    A_UINT32 mu_cts;               /* num CTS2SELF frames to extend MU-data burst */
    A_UINT32 su_ndpa_err;          /* num SU-NDPA frames not transmitted due to HW pause */
    A_UINT32 mu_ndpa_err;          /* num MU-NDPA frames not transmitted due to HW pause */
    A_UINT32 su_ndp_err;           /* num SU-NDP frames that didn't receive correct CBF */
    A_UINT32 mu_ndp_err;           /* num MU-NDP frames that didn't receive correct CBF */
    A_UINT32 mu_brp1_err;          /* num BRPOLL frames to second user that didn't receive correct CBF */
    A_UINT32 mu_brp2_err;          /* num BRPOLL frames to third user that didn't receive correct CBF */
};

typedef struct wlan_dbg_sifs_resp_stats {
    A_UINT32 ps_poll_trigger;       /* num ps-poll trigger frames */
    A_UINT32 uapsd_trigger;         /* num uapsd trigger frames */
    A_UINT32 qb_data_trigger[2];    /* num data trigger frames; idx 0: explicit and idx 1: implicit */
    A_UINT32 qb_bar_trigger[2];     /* num bar trigger frames;  idx 0: explicit and idx 1: implicit */ 
    A_UINT32 sifs_resp_data;        /* num ppdus transmitted at SIFS interval */
    A_UINT32 sifs_resp_err;         /* num ppdus failed to meet SIFS resp timing */
} wlan_dgb_sifs_resp_stats_t;

typedef struct wlan_dbg_reset_stats {
    A_UINT16 warm_reset;
    A_UINT16 cold_reset;
    A_UINT16 tx_flush;
    A_UINT16 tx_glb_reset;
    A_UINT16 tx_txq_reset;
    A_UINT16 rx_timeout_reset;
    A_UINT16 hw_status_mismatch;
    A_UINT16 hw_status_multi_mismatch;
} wlan_dbg_reset_stats_t;

typedef struct wlan_dbg_mac_wdog_stats {
    A_UINT16 rxpcu;
    A_UINT16 txpcu;
    A_UINT16 ole;
    A_UINT16 rxdma;
    A_UINT16 hwsch;
    A_UINT16 crypto;
    A_UINT16 pdg;
    A_UINT16 txdma;
} wlan_dbg_mac_wdog_stats_t;

/* MAX HCM Bins in firmware=20, we only allocate 9 now */
#define WLAN_TX_DESC_MAX_BINS 9

/* Set/Get helper macros to encode/decode values in to 32bit fields
 * that facilitates easy access on both little/big-endian hosts
 */
/* 1st A_UINT32 word of wlan_dbg_tx_desc_bin struct */
#define WLAN_DBG_TX_DESC_BIN_IDX_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_min__bin_idx)))) |= \
    (((val) & 0xFF) << 0)

#define WLAN_DBG_TX_DESC_BIN_IDX_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_min__bin_idx)))) \
    >> 0) & 0xFF)

#define WLAN_DBG_TX_DESC_CFG_MIN_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_min__bin_idx)))) |= \
    (((val) & 0xFFFF) << 16)

#define WLAN_DBG_TX_DESC_CFG_MIN_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_min__bin_idx)))) \
    >> 16) & 0xFFFF)

/* 2nd A_UINT32 word of wlan_dbg_tx_desc_bin struct */
#define WLAN_DBG_TX_DESC_CFG_MAX_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_prio__cfg_max)))) |= \
    (((val) & 0xFFFF) << 0)

#define WLAN_DBG_TX_DESC_CFG_MAX_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_prio__cfg_max)))) \
    >> 0) & 0xFFFF)

#define WLAN_DBG_TX_DESC_CFG_PRIO_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_prio__cfg_max)))) |= \
    (((val) & 0xFF) << 16)

#define WLAN_DBG_TX_DESC_CFG_PRIO_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, cfg_prio__cfg_max)))) \
    >> 16) & 0xFF)

/* 3rd A_UINT32 word of wlan_dbg_tx_desc_bin struct */
#define WLAN_DBG_TX_DESC_CFG_BIN_HYST_THR_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, curr_total__cfg_bin_hist_th)))) |= \
    (((val) & 0xFFFF) << 0)

#define WLAN_DBG_TX_DESC_CFG_BIN_HYST_THR_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, curr_total__cfg_bin_hist_th)))) \
    >> 0) & 0xFFFF)

#define WLAN_DBG_TX_DESC_CURR_TOT_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, curr_total__cfg_bin_hist_th)))) |= \
    (((val) & 0xFFFF) << 16)

#define WLAN_DBG_TX_DESC_CURR_TOT_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, curr_total__cfg_bin_hist_th)))) \
    >> 16) & 0xFFFF)

/* 4th A_UINT32 word of wlan_dbg_tx_desc_bin struct */
#define WLAN_DBG_TX_DESC_PREALLOC_CNT_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, bin_max__pre_alloc_cnt)))) |= \
    (((val) & 0xFFFF) << 0)

#define WLAN_DBG_TX_DESC_PREALLOC_CNT_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, bin_max__pre_alloc_cnt)))) \
    >> 0) & 0xFFFF)

#define WLAN_DBG_TX_DESC_BIN_MAX_SET(p_tx_desc_bin, val) \
    (*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, bin_max__pre_alloc_cnt)))) |= \
    (((val) & 0xFFFF) << 16)

#define WLAN_DBG_TX_DESC_BIN_MAX_GET(p_tx_desc_bin) \
    (((*((A_UINT32 *)(((A_UINT8 *) p_tx_desc_bin) + \
    offsetof(struct wlan_dbg_tx_desc_bin, bin_max__pre_alloc_cnt)))) \
    >> 16) & 0xFFFF)

typedef struct wlan_dbg_tx_desc_bin {
    /* configured min number of descriptors: 31-16, bin index: 7-0 */
    A_UINT32 cfg_min__bin_idx; /* bits 15-8 unused */
    /* configured bin priority: 23-16, configured max desc: 15-0 */
    A_UINT32 cfg_prio__cfg_max; /* 31-24 unused */
    /* total desc. consumed: 31-16, configured bin hysteresis threshold: 15-0 */
    A_UINT32 curr_total__cfg_bin_hist_th; 
    /* max desc. consumed: 31-16, preallocated desc. count: 15-0 */
    A_UINT32 bin_max__pre_alloc_cnt;
    /* low threshold count */
    A_UINT32 bin_hist_low;
    /* high threshold count */
    A_UINT32 bin_hist_high;
} wlan_dbg_tx_desc_bin_t;


/* Set/Get helper macros to encode/decode values in to 32bit fields
 * that facilitates easy access on both little/big-endian hosts
 */
#define WLAN_DBG_TX_DESC_CFG_TOTAL_SET(desc_stats, val) \
    (desc_stats) |= (((val) & 0xFFFF) << 0)

#define WLAN_DBG_TX_DESC_CFG_TOTAL_GET(desc_stats) \
    (((desc_stats) & 0xFFFF) >> 0)

#define WLAN_DBG_TX_DESC_TOTAL_AVAIL_SET(desc_stats, val) \
    (desc_stats) |= (((val) & 0xFFFF) << 16)

#define WLAN_DBG_TX_DESC_TOTAL_AVAIL_GET(desc_stats) \
    (((desc_stats) & 0xFFFF0000) >> 16)

typedef struct wlan_dbg_tx_desc_stats {
    /*current avail desc. count: 31-16, total configured desc count: 15-0 */
    A_UINT32 word1;
    wlan_dbg_tx_desc_bin_t bin_stats[WLAN_TX_DESC_MAX_BINS];
} wlan_dbg_tx_desc_stats_t;

/* max number of queues for which prefetch is enabled. */
#define WAL_STATS_PREFETCH_MAX_QUEUES 4

/* max number of histogram slots supported by fetch mgr */
#define WAL_STATS_FETCH_MGR_MAX_HIST_SLOTS 8

/* Set/Get helper macros to encode/decode values in to 32bit fields
 * that facilitates easy access on both little/big-endian hosts
 */
#define WLAN_DBG_FETCH_MGR_OUTSTANDING_FETCH_DUR_SET(fetch_stats, val) \
    (fetch_stats) |= (((val) & 0xFFFF) << 0)

#define WLAN_DBG_FETCH_MGR_OUTSTANDING_FETCH_DUR_GET(fetch_stats) \
    (((fetch_stats) & 0xFFFF) >> 0)

#define WLAN_DBG_FETCH_MGR_OUTSTANDING_FETCH_DESC_SET(fetch_stats, val) \
    (fetch_stats) |= (((val) & 0xFFFF) << 16)

#define WLAN_DBG_FETCH_MGR_OUTSTANDING_FETCH_DESC_GET(fetch_stats) \
    (((fetch_stats) & 0xFFFF0000) >> 16)

typedef struct wlan_dbg_tx_fetch_mgr_stats {
    /* outstanding fetch desc: 31-16, outstanding fetch duration: 15-0 */
    A_UINT32 fetch_desc__fetch_dur[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 fetch_mgr_total_outstanding_fetch_desc;
    A_UINT32 fetch_mgr_rtt_histogram_4ms[WAL_STATS_FETCH_MGR_MAX_HIST_SLOTS];
    A_UINT32 fetch_mgr_rtt_histogram_500us[WAL_STATS_FETCH_MGR_MAX_HIST_SLOTS];
} wlan_dbg_tx_fetch_mgr_stats_t;

typedef struct wlan_dbg_tx_pf_sched_stats {
    A_UINT32 tx_queued[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 tx_reaped[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 tx_sched[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 abort_sched[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 sched_timeout[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 tx_sched_waitq[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 fetch_resp[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 fetch_resp_invld[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 fetch_resp_delayed[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 fetch_request[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 tx_requeued[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 sched_fail[WAL_STATS_PREFETCH_MAX_QUEUES];
    A_UINT32 pfsched_peer_skipped[WAL_STATS_PREFETCH_MAX_QUEUES];
} wlan_dbg_tx_pf_sched_stats_t;

/** wlan_dbg_wifi2_error_stats_t is not grouped with the
 *  following structure as it is allocated differently and only
 *  belongs to whal 
 */
typedef struct wlan_dbg_stats_wifi2 {
    wlan_dbg_txbf_snd_stats_t txbf_snd_info;
    wlan_dbg_txbf_data_stats_t txbf_data_info;
    struct wlan_dbg_tx_selfgen_stats tx_selfgen;
    struct wlan_dbg_tx_mu_stats tx_mu;
    wlan_dgb_sifs_resp_stats_t sifs_resp_info;
    wlan_dbg_reset_stats_t reset_stats;
    wlan_dbg_mac_wdog_stats_t wdog_stats;
    wlan_dbg_txbf_snd_stats_t *txbf_snd_info_vap;
    struct wlan_dbg_tx_selfgen_stats_vap *tx_selfgen_vap;
    struct wlan_dbg_tx_mu_stats_vap *tx_mu_vap;
} wlan_dbg_wifi2_stats_t;

typedef struct {
    wlan_dbg_rx_rate_info_t rx_phy_info;
    wlan_dbg_tx_rate_info_t tx_rate_info;
} wlan_dbg_rate_info_t;

struct wlan_dbg_stats {
    struct wlan_dbg_tx_stats tx;
    struct wlan_dbg_rx_stats rx;
    struct wlan_dbg_mem_stats mem;
    struct wlan_dbg_peer_stats peer;
};

#define DBG_STATS_MAX_HWQ_NUM 10
#define DBG_STATS_MAX_TID_NUM 20
#define DBG_STATS_MAX_CONG_NUM 16
struct wlan_dbg_txq_stats {
    A_UINT16 num_pkts_queued[DBG_STATS_MAX_HWQ_NUM];
    A_UINT16 tid_hw_qdepth[DBG_STATS_MAX_TID_NUM];//WAL_MAX_TID is 20
    A_UINT16 tid_sw_qdepth[DBG_STATS_MAX_TID_NUM];//WAL_MAX_TID is 20
};

struct wlan_dbg_tidq_stats{
    A_UINT32 wlan_dbg_tid_txq_status;
    struct wlan_dbg_txq_stats txq_st;
};

/* HALPHY RELATED STATS */
#define WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_S          0
#define WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_M          0x00000001

#define WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_S             1
#define WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_M             0x00000002

#define WLAN_HALPHY_DBG_STATS_CALSTATUSREG_S               2
#define WLAN_HALPHY_DBG_STATS_CALSTATUSREG_M               0x00000004

#define WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_S          3
#define WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_M          0x00000008

#define WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_S 4
#define WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_M 0x00000010


#define WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_GET(dword) \
    (((dword) & WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_M) >> \
    WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_S)
#define WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_SET(dword,value) \
    do{ \
        (dword) &= ~WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_M; \
        (dword) |= (((value) << WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_S) & \
            WLAN_HALPHY_DBG_STATS_HOME_OR_SCAN_CHAN_M); \
    } while (0)

#define WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_GET(dword) \
    (((dword) & WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_M) >> \
    WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_S)
#define WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_SET(dword,value) \
    do{ \
        (dword) &= ~WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_M; \
        (dword) |= (((value) << WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_S) & \
            WLAN_HALPHY_DBG_STATS_CALREG_ENABLED_M); \
    } while (0)

#define WLAN_HALPHY_DBG_STATS_CALSTATUSREG_GET(dword) \
    (((dword) & WLAN_HALPHY_DBG_STATS_CALSTATUSREG_M) >> \
    WLAN_HALPHY_DBG_STATS_CALSTATUSREG_S)
#define WLAN_HALPHY_DBG_STATS_CALSTATUSREG_SET(dword,value) \
    do{ \
        (dword) &= ~WLAN_HALPHY_DBG_STATS_CALSTATUSREG_M; \
        (dword) |= (((value) << WLAN_HALPHY_DBG_STATS_CALSTATUSREG_S) & \
            WLAN_HALPHY_DBG_STATS_CALSTATUSREG_M); \
    } while (0)

#define WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_GET(dword) \
    (((dword) & WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_M) >> \
    WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_S)
#define WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_SET(dword,value) \
    do{ \
        (dword) &= ~WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_M; \
        (dword) |= (((value) << WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_S) & \
            WLAN_HALPHY_DBG_STATS_POSTPROCESS_STATS_M); \
    } while (0)

#define WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_GET(dword) \
    (((dword) & WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_M) >> \
    WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_S)
#define WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_SET(dword,value) \
    do{ \
        (dword) &= ~WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_M; \
        (dword) |= (((value) << WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_S) & \
            WLAN_HALPHY_DBG_STATS_IS_HW_ENABLED_WITH_CALDATA_M); \
    } while (0)

typedef struct {
    /*
     * bit 0: Represent the stats is for home channel or scan channel.
     *        0: Scan channel, 1: Home channel
     * bit 1: Represents the register which controls the hardware calibration
     *        is enabled or not.
     *        0: Not enabled, 1: Enabled
     * bit 2: Represents the calibration status from hardware perspective.
     *        0: Fail, 1: Pass
     * bit 3: Represents the status of post processing of caldata in halphy.
     *        0: Fail, 1: Pass
     * bit 4: Represents if the post processed data applied to hardware or not.
     *        0: Not applied, 1:Applied
     * bit 5 - 31 : Reserved for future use
     */
    A_UINT32 Statusflags;
    /* lastCalTime -
     * Units are target clock ticks.
     * Used just to determine whether cal results are new or a repeat of
     * prior cal results.
     */
    A_UINT32 lastCaltime;
    A_UINT32 reserved; /* for future use */
} wlan_halphy_cal_stats_t;

/* Below ANI stats are directly fetched from the BB registers.
 * The values will be displayed in hexa decimal format and mainly
 * used for debugging purpose.
 * These values will not be used by host for any other purpose.
 */
typedef struct {
    /* current OFDM ANI level used */
    A_UINT32 ofdm_ANI_level;
    /* current CCK ANI level used */
    A_UINT32 cck_ANI_level;
    /* Detection threshold for 11b packet during agc CORR state (first correlation) */
    A_UINT32 th_d0_b;
    /* Detection threshold for 11b packet after agc CORR state (second correlation) */
    A_UINT32 th_d0_b_tf_est;
    /* threshold for flag_firstep */
    A_UINT32 firstep;
    /* threshold for flag_firstep_low */
    A_UINT32 firstep_low;
    /* the minimum rssi (SNR) required to validate strong signal detection */
    A_UINT32 rssi_thr1a;
    /* cyclic power threshold1 */
    A_UINT32 cycpwr_thr1;
    /* in-band or total power ratio requred for strong signal detection */
    A_UINT32 relpwr;
    /* Barker corr input backoff for VOTING */
    A_UINT32 bk_in_backoff;
    /* Strong signal detection in case of RF saturation 0: Disabled, 1: Enabled */
    A_UINT32 enable_rfsat_strong;
    /* gain update when AGC is starting a new search 0: Disabled 1: Enabled */
    A_UINT32 enable_srch_start_gain;
    /* Very weak ofdm signal detection: 0: Disabled, 1: Enabled */
    A_UINT32 use_self_corr_low;
    /* reserved for future use */
    A_UINT32 reserved_1;
    /* reserved for future use */
    A_UINT32 reserved_2;
} wlan_halphy_ani_stats_t;

typedef struct {
    /* Num of dpd training frames queued */
    A_UINT32 dpd_hw_queued;
    /* Num of dpd training frames reaped */
    A_UINT32 dpd_hw_reaped;
    /* Num of dpd training frames transmission done */
    A_UINT32 dpd_tx_done;
    /* Num of dpd training frames transmission abort */
    A_UINT32 dpd_tx_abort;
    /* Num of dpd training frames transmission fail */
    A_UINT32 dpd_tx_fail;
    /* Num of ibf training frames queued */
    A_UINT32 ibf_hw_queued;
    /* Num of ibf training frames reaped */
    A_UINT32 ibf_hw_reaped;
    /* Num of ibf training frames transmission done */
    A_UINT32 ibf_tx_done;
    /* Num of ibf training frames transmission abort */
    A_UINT32 ibf_tx_abort;
    /* Num of ibf training frames transmission fail */
    A_UINT32 ibf_tx_fail;
    /* Num of enqueue */
    A_UINT32 tx_async_enqueue;
    /* Num of dequeue */
    A_UINT32 tx_async_dequeue;
    /* Reserved for future use */
    A_UINT32 reserved;
} wlan_halphy_tx_stats_t;

typedef struct {
    wlan_halphy_cal_stats_t nf_stats;         /* NF Calibration stats*/
    wlan_halphy_cal_stats_t ibf_stats;        /* IBF Calibration stats*/
    wlan_halphy_cal_stats_t dpd_stats;        /* DPD calibration stats*/
    wlan_halphy_cal_stats_t RxDCO_stats;      /* RXDCO Calibration stats*/
    wlan_halphy_cal_stats_t PeakDetect_stats; /* Peak detector calibration stats*/
    wlan_halphy_cal_stats_t TxIQCal_stats;    /* TX IQ Calibration stats*/
    wlan_halphy_cal_stats_t RxIQCal_stats;    /* RX IQ Calibration stats*/
    wlan_halphy_cal_stats_t carrierLkg_stats; /* Carrier Leakage calibration stats*/
    wlan_halphy_cal_stats_t RxFltrCal_stats;  /* RX Filter calibration stats*/
    wlan_halphy_ani_stats_t ani_stats;        /* ANI stats */
    wlan_halphy_tx_stats_t tx_stats;          /* HALPHY calibration specific TX stats */
} wlan_halphy_dbg_stats_t;

typedef struct {
    A_UINT32 coex_version; /* Current COEX version */
    A_UINT32 is_coex_enabled; /* Current COEX configuration */
    /*
     * num_coex_int high,low -
     * How many times a GPIO line used for coex interrupts has been toggled
     * from low -> high and high -> low.
     * In theory, num_coex_int_high and num_coex_int_low should always be
     * either equal or have a different of 1, since low -> high and
     * high -> low transitions happen interspersed.  But if some interrupts
     * are lost, the counters may not be equal or different by one.
     * Thus, having these counter values provides some indication that
     * some coex GPIO interrupts were lost.
     */
    A_UINT32 num_coex_int_high; /* COEX interrupt line is used differently in different feature sets and is denoted by different names - like wlan_deny/lte_active/btcoex_interrupt/non-wlan radio request line */
    A_UINT32 num_coex_int_low;
    A_UINT32 num_coex_tx_aborts; /* Number of COEX TX aborts */
    A_UINT32 num_beacons_missed;
    A_UINT32 is_priority_line_stuck;  /* counter to denote if a non-wlan radio holds the priority line for a longer time beyond a threshold */
    A_UINT32 reserved[25];
} wlan_coex_common_stats_t;
 
typedef struct {
    A_UINT32 dc_duration; /* Duty cycle duration - milliseconds */
    A_UINT32 configured_wlan_duration; /* milliseconds */
    A_UINT32 actual_wlan_duration; /* milliseconds */
} wlan_coex_dc_stats_t;
 
typedef struct {
   wlan_coex_common_stats_t coex_cmn_stats; /* COEX general stats which are common to all feature sets */
   wlan_coex_dc_stats_t     coex_dc_stats; /* COEX duty cycle stats */
} wlan_coex_dbg_stats_t;


#endif /* __WLANDEFS_H__ */
