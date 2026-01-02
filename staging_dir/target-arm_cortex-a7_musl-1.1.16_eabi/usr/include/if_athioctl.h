/*
 * Copyright (c) 2011, 2017 Qualcomm Innovation Center, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary . Qualcomm Innovation Center, Inc.
 *
 * Copyright (c) 2010, Atheros Communications Inc.
 * All Rights Reserved.
 *
 * 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 *
 */

/*
 * Ioctl-related defintions for the Atheros Wireless LAN controller driver.
 */
#ifndef _DEV_ATH_ATHIOCTL_H
#define _DEV_ATH_ATHIOCTL_H

/* add by David.Dai, for support ath_tool - athtweak */
#ifndef SIOC80211SCOMMONCMD
#define SIOC80211SCOMMONCMD    _IOWR('i', 247, struct ieee80211req)
#endif
#ifndef SIOC80211GCOMMONCMD
 #define SIOC80211GCOMMONCMD    _IOWR('i', 248, struct ieee80211req)
#endif

#define ATH_STATS_VI_LOG_LEN 10

#define MAX_BB_PANICS 3

/* end add, David.Dai */
/*
 * 11n tx/rx stats
 */
struct ath_11n_stats {
    u_int32_t   tx_pkts;            /* total tx data packets */
    u_int32_t   tx_checks;          /* tx drops in wrong state */
    u_int32_t   tx_drops;           /* tx drops due to qdepth limit */
    u_int32_t   tx_minqdepth;       /* tx when h/w queue depth is low */
    u_int32_t   tx_queue;           /* tx pkts when h/w queue is busy */
    u_int32_t   tx_resetq;          /* tx reset queue instances */
    u_int32_t   tx_comps;           /* tx completions */
    u_int32_t   tx_comperror;       /* tx error completions on global failures */
    u_int32_t   tx_unaggr_comperror; /* tx error completions of unaggregted frames */
    u_int32_t   tx_stopfiltered;    /* tx pkts filtered for requeueing */
    u_int32_t   tx_qnull;           /* txq empty occurences */
    u_int32_t   tx_noskbs;          /* tx no skbs for encapsulations */
    u_int32_t   tx_nobufs;          /* tx no descriptors */
    u_int32_t   tx_badsetups;       /* tx key setup failures */
    u_int32_t   tx_normnobufs;      /* tx no desc for legacy packets */
    u_int32_t   tx_schednone;       /* tx schedule pkt queue empty */
    u_int32_t   tx_bars;            /* tx bars sent */
    u_int32_t   tx_legacy;          /* tx legacy frames sent */
    u_int32_t   txunaggr_single;    /* tx unaggregate singles sent */
    u_int32_t   txbar_xretry;       /* tx bars excessively retried */
    u_int32_t   txbar_compretries;  /* tx bars retried */
    u_int32_t   txbar_errlast;      /* tx bars last frame failed */
    u_int32_t   tx_compunaggr;      /* tx unaggregated frame completions */
    u_int32_t   txunaggr_xretry;    /* tx unaggregated excessive retries */
    u_int32_t   tx_compaggr;        /* tx aggregated completions */
    u_int32_t   tx_bawadv;          /* tx block ack window advanced */
    u_int32_t   tx_bawretries;      /* tx block ack window retries */
    u_int32_t   tx_bawnorm;         /* tx block ack window additions */
    u_int32_t   tx_bawupdates;      /* tx block ack window updates */
    u_int32_t   tx_bawupdtadv;      /* tx block ack window advances */
    u_int32_t   tx_retries;         /* tx retries of sub frames */
    u_int32_t   tx_xretries;        /* tx excessive retries of aggregates */
    u_int32_t   tx_aggregates;      /* tx aggregated pkts sent */
    u_int32_t   tx_sf_hw_xretries;  /* sub-frames excessively retried in h/w */
    u_int32_t   tx_aggr_frames;     /* tx total frames aggregated */
    u_int32_t   txaggr_noskbs;      /* tx no skbs for aggr encapsualtion */
    u_int32_t   txaggr_nobufs;      /* tx no desc for aggr */
    u_int32_t   txaggr_badkeys;     /* tx enc key setup failures */
    u_int32_t   txaggr_schedwindow; /* tx no frame scheduled: baw limited */
    u_int32_t   txaggr_single;      /* tx frames not aggregated */
    u_int32_t   txaggr_mimo;        /* tx frames aggregated for mimo */
    u_int32_t   txaggr_compgood;    /* tx aggr good completions */
    u_int32_t   txaggr_comperror;   /* tx aggr error completions */
    u_int32_t   txaggr_compxretry;  /* tx aggr excessive retries */
    u_int32_t   txaggr_compretries; /* tx aggr unacked subframes */
    u_int32_t   txunaggr_compretries; /* tx non-aggr unacked subframes */
    u_int32_t   txaggr_prepends;    /* tx aggr old frames requeued */
    u_int32_t   txaggr_filtered;    /* filtered aggr packet */
    u_int32_t   txaggr_fifo;        /* fifo underrun of aggregate */
    u_int32_t   txaggr_xtxop;       /* txop exceeded for an aggregate */
    u_int32_t   txaggr_desc_cfgerr; /* aggregate descriptor config error */
    u_int32_t   txaggr_data_urun;   /* data underrun for an aggregate */
    u_int32_t   txaggr_delim_urun;  /* delimiter underrun for an aggregate */
    u_int32_t   txaggr_errlast;     /* tx aggr: last sub-frame failed */
    u_int32_t   txunaggr_errlast;   /* tx non-aggr: last frame failed */
    u_int32_t   txaggr_longretries; /* tx aggr h/w long retries */
    u_int32_t   txaggr_shortretries;/* tx aggr h/w short retries */
    u_int32_t   txaggr_timer_exp;   /* tx aggr : tx timer expired */
    u_int32_t   txaggr_babug;       /* tx aggr : BA bug */
    u_int32_t   txrifs_single;      /* tx frames not bursted */
    u_int32_t   txrifs_babug;       /* tx rifs : BA bug */
    u_int32_t   txaggr_badtid;      /* tx aggr : Bad TID */
    u_int32_t   txrifs_compretries; /* tx rifs unacked subframes */
    u_int32_t   txrifs_bar_alloc;   /* tx rifs bars allocated */
    u_int32_t   txrifs_bar_freed;   /* tx rifs bars freed */
    u_int32_t   txrifs_compgood;    /* tx rifs good completions */
    u_int32_t   txrifs_prepends;    /* tx rifs old frames requeued */
    u_int32_t   tx_comprifs;        /* tx rifs completions */
    u_int32_t   tx_compnorifs;      /* tx not a rifs completion */
    u_int32_t   rx_pkts;            /* rx pkts */
    u_int32_t   rx_aggr;            /* rx aggregated packets */
    u_int32_t   rx_aggrbadver;      /* rx pkts with bad version */
    u_int32_t   rx_bars;            /* rx bars */
    u_int32_t   rx_nonqos;          /* rx non qos-data frames */
    u_int32_t   rx_seqreset;        /* rx sequence resets */
    u_int32_t   rx_oldseq;          /* rx old packets */
    u_int32_t   rx_bareset;         /* rx block ack window reset */
    u_int32_t   rx_baresetpkts;     /* rx pts indicated due to baw resets */
    u_int32_t   rx_dup;             /* rx duplicate pkts */
    u_int32_t   rx_baadvance;       /* rx block ack window advanced */
    u_int32_t   rx_recvcomp;        /* rx pkt completions */
    u_int32_t   rx_bardiscard;      /* rx bar discarded */
    u_int32_t   rx_barcomps;        /* rx pkts unblocked on bar reception */
    u_int32_t   rx_barrecvs;        /* rx pkt completions on bar reception */
    u_int32_t   rx_skipped;         /* rx pkt sequences skipped on timeout */
    u_int32_t   rx_comp_to;         /* rx indications due to timeout */
    u_int32_t   rx_timer_starts;    /* rx countdown timers started */
    u_int32_t   rx_timer_stops;     /* rx countdown timers stopped */
    u_int32_t   rx_timer_run;       /* rx timeout occurences */
    u_int32_t   rx_timer_more;      /* rx partial timeout of pending packets */
    u_int32_t   wd_tx_active;       /* watchdog: tx is active */
    u_int32_t   wd_tx_inactive;     /* watchdog: tx is not active */
    u_int32_t   wd_tx_hung;         /* watchdog: tx is hung */
    u_int32_t   wd_spurious;        /* watchdog: spurious tx hang */
    u_int32_t   tx_requeue;         /* filter & requeue on 20/40 transitions */
    u_int32_t   tx_drain_txq;       /* draining tx queue on error */
    u_int32_t   tx_drain_tid;       /* draining tid buf queue on error */
    u_int32_t   tx_cleanup_tid;     /* draining tid buf queue on node cleanup */
    u_int32_t   tx_drain_bufs;      /* buffers drained from pending tid queue */
    u_int32_t   tx_tidpaused;       /* pausing tx on tid */
    u_int32_t   tx_tidresumed;      /* resuming tx on tid */
    u_int32_t   tx_unaggr_filtered; /* unaggregated tx pkts filtered */
    u_int32_t   tx_aggr_filtered;   /* aggregated tx pkts filtered */
    u_int32_t   tx_filtered;        /* total sub-frames filtered */
    u_int32_t   rx_rb_on;           /* total rb-s on  */
    u_int32_t   rx_rb_off;          /* total rb-s off */
    u_int32_t   rx_dsstat_err;      /* rx descriptor status corrupted */
#ifdef ATH_SUPPORT_TxBF
    u_int32_t   bf_stream_miss;     /* beamform stream mismatch */
    u_int32_t   bf_bandwidth_miss;  /* beamform bandwidth mismatch */
    u_int32_t   bf_destination_miss;/* beamform destination mismatch */
#endif
    u_int32_t   tx_deducted_tokens; /* ATF txtokens deducted */
    u_int32_t   tx_unusable_tokens; /* ATF txtokens unusable */
    u_int32_t   sub_frm[33];        /* Aggr stats */
    u_int32_t   aggr_limit_txbf;    /* Reason for breaking aggr - txbf */
    u_int32_t   aggr_limit_baw;     /* Reason for breaking aggr - baw */
    u_int32_t   aggr_limit_minrate; /* Reason for breaking aggr - min-rate*/
    u_int32_t   aggr_limit_8k;      /* Reason for breaking aggr - dynamic pwrsave */
    u_int32_t   aggr_limit_size;    /* Reason for breaking aggr - size of aggr */
    u_int32_t   aggr_limit_frames;  /* Reason for breaking aggr - frames in aggr */
    u_int32_t   aggr_limit_pkt_size;/* Reason for breaking aggr - short packet */
    u_int32_t   aggr_limit_empty_q; /* Reason for breaking aggr - queue empty */
};



/*
 * DFS stats
 */
#define DFS_MAX_FILTER  32

struct dfs_filter_stats {
    u_int32_t       max_pri_count;
    u_int32_t       max_used_pri;
    u_int32_t       excess_pri;
    u_int32_t       pri_threshold_reached;
    u_int32_t       dur_threshold_reached;
    u_int32_t       rssi_threshold_reached;
    u_int32_t       filter_id;
};

struct ath_dfs_stats {
    u_int32_t       dfs_stats_valid;
    u_int32_t       event_count;
    u_int32_t       chirp_count;
    u_int32_t       num_filter;
    struct dfs_filter_stats fstat[DFS_MAX_FILTER];
};

struct ath_bb_panic_info {
    int valid;
    u_int32_t status;
    u_int32_t tsf;
    u_int32_t phy_panic_wd_ctl1;
    u_int32_t phy_panic_wd_ctl2;
    u_int32_t phy_gen_ctrl;
    u_int32_t rxc_pcnt;
    u_int32_t rxf_pcnt;
    u_int32_t txf_pcnt;
    u_int32_t cycles;
    u_int32_t wd;
    u_int32_t det;
    u_int32_t rdar;
    u_int32_t r_odfm;
    u_int32_t r_cck;
    u_int32_t t_odfm;
    u_int32_t t_cck;
    u_int32_t agc;
    u_int32_t src;
};

struct ath_phy_stats {
    u_int64_t   ast_tx_rts;   /* RTS success count */
    u_int64_t   ast_tx_shortretry;/* tx on-chip retries (short). RTSFailCnt */
    u_int64_t   ast_tx_longretry;/* tx on-chip retries (long). DataFailCnt */
    u_int64_t   ast_rx_tooshort;/* rx discarded 'cuz frame too short */
    u_int64_t   ast_rx_toobig;    /* rx discarded 'cuz frame too large */
    u_int64_t   ast_rx_err; /* rx error */
    u_int64_t   ast_rx_crcerr;    /* rx failed 'cuz of bad CRC */
    u_int64_t   ast_rx_fifoerr;    /* rx failed 'cuz of FIFO overrun */
    u_int64_t   ast_rx_phyerr;    /* rx PHY error summary count */
    u_int64_t   ast_rx_decrypterr; /* rx decryption error */
    u_int64_t   ast_rx_demicerr; /* rx demic error */
    u_int64_t   ast_rx_demicok; /* rx demic ok */
    u_int64_t   ast_rx_delim_pre_crcerr; /* pre-delimiter crc errors */
    u_int64_t   ast_rx_delim_post_crcerr; /* post-delimiter crc errors */
    u_int64_t   ast_rx_decrypt_busyerr; /* decrypt busy errors */
    u_int64_t   ast_rx_phy[32];    /* rx PHY error per-code counts */
};

struct ast_mib_mac_stats {
    u_int32_t   ast_ackrcv_bad;
    u_int32_t   ast_rts_bad;
    u_int32_t   ast_rts_good;
    u_int32_t   ast_fcs_bad;
    u_int32_t   ast_beacons;
};

struct ath_stats {
    u_int32_t    ast_resetOnError; /* resets on error */
    u_int32_t    ast_hardware;     /* fatal hardware error interrupts */
    u_int32_t    ast_halresets;    /* HAL resets */
    u_int32_t    ast_bmiss;        /* beacon miss interrupts */
    u_int32_t    ast_mib;          /* mib interrupts */
    u_int32_t    ast_brssi;        /* beacon rssi threshold interrupts */
    u_int32_t    ast_tx_mgmt;      /* management frames transmitted */
    u_int32_t    ast_tx_fifoerr;   /* tx failed 'cuz FIFO underrun */
    u_int32_t    ast_tx_filtered;  /* tx failed 'cuz xmit filtered */
    u_int32_t    ast_tx_noack;     /* tx frames with no ack marked */
    u_int32_t    ast_tx_shortpre;  /* tx frames with short preamble */
    u_int32_t    ast_tx_altrate;   /* tx frames with alternate rate */
    u_int32_t    ast_tx_protect;   /* tx frames with protection */
    u_int32_t    ast_rx_nobuf;     /* rx setup failed 'cuz no skbuff */
    u_int32_t    ast_rx_hal_in_progress;
    u_int32_t    ast_rx_num_mgmt;
    u_int32_t    ast_rx_num_ctl;
    u_int32_t    ast_rx_num_unknown;
    u_int32_t    ast_be_xmit;                    /* beacons transmitted */
    u_int32_t    ast_be_nobuf;                    /* no skbuff available for beacon */
    u_int32_t    ast_per_cal;                    /* periodic calibration calls */
    u_int32_t    ast_per_calfail;                /* periodic calibration failed */
    u_int32_t    ast_per_rfgain;                    /* periodic calibration rfgain reset */
    u_int32_t    ast_ant_defswitch;              /* rx/default antenna switches */
    u_int32_t    ast_bb_hang;                    /* BB hang detected */
    u_int32_t    ast_mac_hang;                   /* MAC hang detected */
#if ATH_WOW
    u_int32_t    ast_wow_wakeups;                /* count of hibernate and standby wakeups */
    u_int32_t    ast_wow_wakeupsok;              /* count of wakeups thru WoW */
#endif
#if ATH_SUPPORT_CFEND
    u_int32_t    ast_cfend_sched;			/* count of CF-END frames scheduled */
    u_int32_t    ast_cfend_sent;   		/* count of CF-END frames sent */
#endif
#if ATH_RX_LOOPLIMIT_TIMER
    u_int32_t    ast_rx_looplimit_start;
    u_int32_t    ast_rx_looplimit_end;
#endif
    u_int32_t    ast_chan_clr_cnt;
    u_int32_t    ast_cycle_cnt;
    int16_t      ast_noise_floor;

    u_int32_t    ast_watchdog;     /* device reset by watchdog */
    u_int32_t    ast_mat_ucast_encrypted;
    u_int32_t    ast_mat_rx_recrypt;
    u_int32_t    ast_mat_rx_decrypt;
    u_int32_t    ast_mat_key_switch;
    u_int32_t    ast_rxorn;        /* rx overrun interrupts */
    u_int32_t    ast_rxorn_bmiss;  /* rx overrun and bmiss interrupts: indicate descriptor corruption */
    u_int32_t    ast_rxeol;        /* rx eol interrupts */
    u_int32_t    ast_rxeol_recover;/* rx eol interrupt hang recoveries */
    u_int32_t    ast_txurn;        /* tx underrun interrupts */
    u_int32_t    ast_txto;         /* tx timeout interrupts */
    u_int32_t    ast_cst;          /* carrier sense timeout interrupts */
    u_int32_t    ast_rx;           /* rx interrupts */
    u_int32_t    ast_rxdesc;       /* rx descriptor interrupts */
    u_int32_t    ast_rxerr;        /* rx error interrupts */
    u_int32_t    ast_rxnofrm;      /* rx no frame interrupts */
    u_int32_t    ast_tx;           /* tx interrupts */
    u_int32_t    ast_txdesc;       /* tx descriptor interrupts */
    u_int32_t    ast_tim_timer;    /* tim timer interrupts */
    u_int32_t    ast_bbevent;      /* baseband event interrupts */
    u_int32_t    ast_rxphy;        /* rx phy error interrupts */
    u_int32_t    ast_rxkcm;        /* rx key cache miss interrupts */
    u_int32_t    ast_swba;         /* sw beacon alert interrupts */
    u_int32_t    ast_bnr;          /* beacon not ready interrupts */
    u_int32_t    ast_tim;          /* tim interrupts */
    u_int32_t    ast_dtim;         /* dtim interrupts */
    u_int32_t    ast_dtimsync;     /* dtimsync interrupts */
    u_int32_t    ast_gpio;         /* general purpose IO interrupts */
    u_int32_t    ast_cabend;       /* cab end interrupts */
    u_int32_t    ast_tsfoor;       /* tsf out-of-range interrupts */
    u_int32_t    ast_gentimer;     /* generic timer interrupts */
    u_int32_t    ast_gtt;          /* global transmit timeout interrupts */
    u_int32_t    ast_fatal;        /* fatal interrupts */
    u_int32_t    ast_tx_packets;   /* packet sent on the interface */
    u_int32_t    ast_rx_packets;   /* packet received on the interface */
    u_int32_t    ast_tx_discard;   /* frames discarded prior to assoc */
    u_int32_t    ast_tx_invalid;   /* frames discarded 'cuz device gone */
    u_int32_t    ast_tx_qstop;     /* tx queue stopped 'cuz full */
    u_int32_t    ast_tx_encap;     /* tx encapsulation failed */
    u_int32_t    ast_tx_nonode;    /* tx failed 'cuz no node */
    u_int32_t    ast_tx_nobuf;     /* tx failed 'cuz no tx buffer (data) */
    u_int32_t    ast_tx_stop;      /* number of times the netif_stop called*/
    u_int32_t    ast_tx_resume;    /* number of times netif_wake_queue called */
    u_int32_t    ast_tx_nobufmgt;  /* tx failed 'cuz no tx buffer (mgmt)*/
    u_int32_t    ast_tx_xretries;  /* tx failed 'cuz too many retries */
    u_int64_t    ast_tx_hw_retries;/* tx retries in hw, not including RTS and
                                      successes.
                                      (approximation only) */
    u_int64_t    ast_tx_hw_success;/* tx successes indicated by hw */
    u_int32_t    ast_tx_badrate;   /* tx failed 'cuz bogus xmit rate */
    u_int32_t    ast_tx_cts;       /* tx frames with cts enabled */
    u_int32_t    ast_rx_orn;       /* rx failed 'cuz of desc overrun */
    u_int32_t    ast_rx_badcrypt;  /* rx failed 'cuz decryption */
    u_int32_t    ast_rx_badmic;    /* rx failed 'cuz MIC failure */
    u_int32_t    ast_rx_swdecrypt; /* rx frames sw decrypted due to key miss */
        u_int32_t       ast_rx_num_data;
        u_int8_t        ast_self_bss_util;
        u_int8_t        ast_obss_util;
        u_int32_t       ast_max_pkts_per_intr;
#define ATH_STATS_MAX_INTR_BKT  512
    u_int32_t   ast_pkts_per_intr[ATH_STATS_MAX_INTR_BKT+1]; /* counter bucket of packets handled in a single iteration */
    int8_t      ast_tx_rssi;                    /* tx rssi of last ack */
    int8_t      ast_tx_rssi_ctl0;               /* tx rssi of last ack [ctl, chain 0] */
    int8_t      ast_tx_rssi_ctl1;               /* tx rssi of last ack [ctl, chain 1] */
    int8_t      ast_tx_rssi_ctl2;               /* tx rssi of last ack [ctl, chain 2] */
    int8_t      ast_tx_rssi_ext0;               /* tx rssi of last ack [ext, chain 0] */
    int8_t      ast_tx_rssi_ext1;               /* tx rssi of last ack [ext, chain 1] */
    int8_t      ast_tx_rssi_ext2;               /* tx rssi of last ack [ext, chain 2] */
    int8_t      ast_rx_rssi;                    /* rx rssi from histogram [combined]*/
    int8_t      ast_rx_rssi_ctl0;               /* rx rssi from histogram [ctl, chain 0] */
    int8_t      ast_rx_rssi_ctl1;               /* rx rssi from histogram [ctl, chain 1] */
    int8_t      ast_rx_rssi_ctl2;               /* rx rssi from histogram [ctl, chain 2] */
    int8_t      ast_rx_rssi_ext0;               /* rx rssi from histogram [ext, chain 0] */
    int8_t      ast_rx_rssi_ext1;               /* rx rssi from histogram [ext, chain 1] */
    int8_t      ast_rx_rssi_ext2;               /* rx rssi from histogram [ext, chain 2] */
    u_int32_t   ast_rate_calls;                    /* rate control checks */
    u_int32_t   ast_rate_raise;                    /* rate control raised xmit rate */
    u_int32_t   ast_rate_drop;                    /* rate control dropped xmit rate */
    u_int32_t   ast_ant_txswitch;               /* tx antenna switches */
    u_int32_t   ast_ant_rx[8];                    /* rx frames with antenna */
    u_int32_t   ast_ant_tx[8];                    /* tx frames with antenna */
    u_int64_t   ast_rx_bytes;                    /* total number of bytes received */
    u_int64_t   ast_tx_bytes;                    /* total number of bytes transmitted */
    u_int32_t   ast_rx_num_qos_data[16];        /* per tid rx packets (includes duplicates)*/
    u_int32_t   ast_rx_num_nonqos_data;         /* non qos rx packets    */
    u_int32_t   ast_txq_packets[16];            /* perq packets sent on the interface for each category */
    u_int32_t   ast_txq_xretries[16];           /* per q tx failed 'cuz too many retries */
    u_int32_t   ast_txq_fifoerr[16];            /* per q tx failed 'cuz FIFO underrun */
    u_int32_t   ast_txq_filtered[16];           /*per q  tx failed 'cuz xmit filtered */
    u_int32_t   ast_txq_athbuf_limit[16];       /* tx dropped 'cuz of athbuf limit */
    u_int32_t   ast_txq_nobuf[16];              /* tx dropped 'cuz no athbufs */
    u_int8_t    ast_num_rxchain;                /* Number of rx chains */
    u_int8_t    ast_num_txchain;                /* Number of tx chains */
    struct ath_11n_stats ast_11n_stats;         /* 11n statistics */
    struct ath_dfs_stats ast_dfs_stats;         /* DFS statistics */
#if ATH_WOW
    u_int32_t   ast_wow_wakeupserror;           /* count of errored wakeups */
#if ATH_WOW_DEBUG
    u_int32_t   ast_normal_sleeps;              /* count of normal sleeps */
    u_int32_t   ast_normal_wakeups;             /* count of normal wakeups*/
    u_int32_t   ast_wow_sleeps;                 /* count of wow sleeps */
    u_int32_t   ast_wow_sleeps_nonet;           /* w/o IP config */
#endif
#endif
#ifdef ATH_SUPPORT_UAPSD
    u_int32_t   ast_uapsdqnulbf_unavail;        /* no qos null buffers available */
    u_int32_t   ast_uapsdqnul_pkts;             /* count of qos null frames sent */
    u_int32_t   ast_uapsdtriggers;              /* count of UAPSD triggers received */
    u_int32_t   ast_uapsdnodeinvalid;           /* count of triggers for non-UAPSD node */
    u_int32_t   ast_uapsdeospdata;              /* count of QoS Data with EOSP sent */
    u_int32_t   ast_uapsddata_pkts;             /* count of UAPSD QoS Data frames sent */
    u_int32_t   ast_uapsddatacomp;              /* count of UAPSD QoS Data frames completed */
    u_int32_t   ast_uapsdqnulcomp;              /* count of UAPSD QoS NULL frames completed */
    u_int32_t   ast_uapsddataqueued;            /* count of UAPSD QoS Data Queued */
    u_int32_t   ast_uapsdedmafifofull;          /* count of UAPSD trigger frames not processed due to EDMA HW FIFO being full */
#endif
#ifdef ATH_SUPPORT_VOWEXT
    /* VOWEXT stats only. Literally some of the iqueue stats can be re-used here
     * As part of current release, all vow stats will be added extra and
     * re-using will be thought for next release
     */
    /*
     * ast_vow_ul_tx_calls : Number of frames Upper Layer ( ieee ) tried to send
     * over each access category. For each of the AC this would denote how many
     * frames reached ATH layer.
     *
     * ast_vow_ath_txq_calls: Subset of ( ast_vow_ul_tx_calls ) that can be
     * either queued or can be sent immediate, either as an aggregate or as an
     * normal frame. This counts only frames that can be sent.
    */
    u_int32_t   ast_vow_ul_tx_calls[4];
    u_int32_t   ast_vow_ath_txq_calls[4];
    u_int32_t   ast_vow_ath_be_drop, ast_vow_ath_bk_drop;
#endif

#if UMAC_SUPPORT_VI_DBG
    u_int32_t   vi_timestamp[ATH_STATS_VI_LOG_LEN];      /* h/w assigned timestamp        */
    u_int8_t    vi_rssi_ctl0[ATH_STATS_VI_LOG_LEN];      /* rx frame RSSI [ctl, chain 0]  */
    u_int8_t    vi_rssi_ctl1[ATH_STATS_VI_LOG_LEN];      /* rx frame RSSI [ctl, chain 1]  */
    u_int8_t    vi_rssi_ctl2[ATH_STATS_VI_LOG_LEN];      /* rx frame RSSI [ctl, chain 2]  */
    u_int8_t    vi_rssi_ext0[ATH_STATS_VI_LOG_LEN];      /* rx frame RSSI [ext, chain 0]  */
    u_int8_t    vi_rssi_ext1[ATH_STATS_VI_LOG_LEN];      /* rx frame RSSI [ext, chain 1]  */
    u_int8_t    vi_rssi_ext2[ATH_STATS_VI_LOG_LEN];      /* rx frame RSSI [ext, chain 2]  */
    u_int8_t    vi_rssi[ATH_STATS_VI_LOG_LEN];
    u_int8_t    vi_evm0[ATH_STATS_VI_LOG_LEN];           /* evm - chain 0                 */
    u_int8_t    vi_evm1[ATH_STATS_VI_LOG_LEN];           /* evm - chain 1                 */
    u_int8_t    vi_evm2[ATH_STATS_VI_LOG_LEN];           /* evm - chain 2                 */
    u_int8_t    vi_rs_rate[ATH_STATS_VI_LOG_LEN];        /* h/w receive rate index        */
    u_int32_t   vi_tx_frame_cnt[ATH_STATS_VI_LOG_LEN];   /* Profile count transmit frames */
    u_int32_t   vi_rx_frame_cnt[ATH_STATS_VI_LOG_LEN];   /* Profile count receive frames  */
    u_int32_t   vi_rx_clr_cnt[ATH_STATS_VI_LOG_LEN];     /* Profile count receive clear   */
    u_int32_t   vi_rx_ext_clr_cnt[ATH_STATS_VI_LOG_LEN]; /* Profile count receive clear on ext channel */
    u_int32_t   vi_cycle_cnt[ATH_STATS_VI_LOG_LEN];      /* Profile count cycle counter   */
    u_int8_t    vi_stats_index;                          /* Used to index circular buffer used to hold video stats */
#endif
#ifdef ATH_SUPPORT_TxBF
#define MCS_RATE 0x1f
    u_int8_t    ast_txbf;
    u_int8_t    ast_lastratecode;
    u_int32_t   ast_sounding_count;
    u_int32_t   ast_txbf_rpt_count;
    u_int32_t   ast_mcs_count[MCS_RATE+1];
#endif
    struct ast_mib_mac_stats ast_mib_stats;
    struct ath_bb_panic_info ast_bb_panic[MAX_BB_PANICS];
};

struct ath_stats_container {
    u_int32_t         size;
    struct ath_stats  *address;
    u_int32_t         offload_if;
    u_int16_t         flag_ext;
};

struct ath_phy_stats_container {
    u_int32_t              size;
    struct ath_phy_stats  *address;
};


/*
** Enumeration of parameter IDs
** This is how the external users refer to specific parameters, which is
** why it's defined in the external interface
*/

typedef enum {
    ATH_PARAM_TXCHAINMASK           =1,
    ATH_PARAM_RXCHAINMASK           =2,
    ATH_PARAM_TXCHAINMASKLEGACY     =3,
    ATH_PARAM_RXCHAINMASKLEGACY     =4,
    ATH_PARAM_CHAINMASK_SEL         =5,
    ATH_PARAM_AMPDU                 =6,
    ATH_PARAM_AMPDU_LIMIT           =7,
    ATH_PARAM_AMPDU_SUBFRAMES       =8,
    ATH_PARAM_AGGR_PROT             =9,
    ATH_PARAM_AGGR_PROT_DUR         =10,
    ATH_PARAM_AGGR_PROT_MAX         =11,
    ATH_PARAM_TXPOWER_LIMIT2G       =12,
    ATH_PARAM_TXPOWER_LIMIT5G       =13,
    ATH_PARAM_TXPOWER_OVERRIDE      =14,
    ATH_PARAM_PCIE_DISABLE_ASPM_WK  =15,
    ATH_PARAM_PCID_ASPM             =16,
    ATH_PARAM_BEACON_NORESET        =17,
    ATH_PARAM_CAB_CONFIG            =18,
    ATH_PARAM_ATH_DEBUG             =19,
    ATH_PARAM_ATH_TPSCALE           =20,
    ATH_PARAM_ACKTIMEOUT            =21,
    ATH_PARAM_AMSDU_ENABLE          =26,
#if ATH_SUPPORT_IQUE
    ATH_PARAM_RETRY_DURATION        =27,
    ATH_PARAM_HBR_HIGHPER           =28,
    ATH_PARAM_HBR_LOWPER            =29,
#endif
    ATH_PARAM_RX_STBC               =30,
    ATH_PARAM_TX_STBC               =31,
    ATH_PARAM_LDPC                  =32,
    ATH_PARAM_LIMIT_LEGACY_FRM      =33,
    ATH_PARAM_TOGGLE_IMMUNITY       =34,
    ATH_PARAM_WEP_TKIP_AGGR_TX_DELIM    =35,
    ATH_PARAM_WEP_TKIP_AGGR_RX_DELIM    =36,
    ATH_PARAM_GPIO_LED_CUSTOM       =37,
    ATH_PARAM_SWAP_DEFAULT_LED      =38,
#if defined(ATH_SUPPORT_WIRESHARK)
    ATH_PARAM_TAPMONITOR            =39,
#endif
#if ATH_SUPPORT_VOWEXT
    ATH_PARAM_VOWEXT                =40,
    /*ATH_PARAM_RCA                   =41,*/ /* rate control and
                                       aggregation parameters */
	ATH_PARAM_VSP_ENABLE            =42,
	ATH_PARAM_VSP_THRESHOLD         =43,
	ATH_PARAM_VSP_EVALINTERVAL      =44,
#endif
#if ATH_VOW_EXT_STATS
    ATH_PARAM_VOWEXT_STATS          =45,
#endif
    /*Thresholds for interrupt mitigation*/
    ATH_PARAM_RIMT_FIRST                =64,
    ATH_PARAM_RIMT_LAST                 =65,
    ATH_PARAM_TIMT_FIRST                =66,
    ATH_PARAM_TIMT_LAST                 =67,
    ATH_PARAM_TXBF_SW_TIMER             =69,
    ATH_PARAM_PHYRESTART_WAR            =70,
    ATH_PARAM_CHANNEL_SWITCHING_TIME_USEC    =71,
    ATH_PARAM_KEYSEARCH_ALWAYS_WAR      = 72,
#ifdef ATH_SUPPORT_DYN_TX_CHAINMASK
    ATH_PARAM_DYN_TX_CHAINMASK          =73,
#endif /* ATH_SUPPORT_DYN_TX_CHAINMASK */
#if ATH_SUPPORT_VOWEXT
    ATH_PARAM_VSP_STATS                 =74,
    ATH_PARAM_VSP_STATSCLR              =75,
#endif

    ATH_PARAM_AGGR_BURST                =77,
    ATH_PARAM_AGGR_BURST_DURATION       =78,

#if ATH_SUPPORT_FLOWMAC_MODULE
    ATH_PARAM_FLOWMAC                   =79,
#endif
    ATH_PARAM_BCN_BURST                 =80,
#if ATH_ANI_NOISE_SPUR_OPT
    ATH_PARAM_NOISE_SPUR_OPT            =81,
#endif
    ATH_PARAM_DCS_ENABLE                =82,
    ATH_PARAM_TOTAL_PER                = 89,
    ATH_PARAM_AMPDU_RX_BSIZE            =90,
#if ATH_SUPPORT_RX_PROC_QUOTA
    ATH_PARAM_CNTRX_NUM                =91,
#endif
   ATH_PARAM_RTS_CTS_RATE              =92,
#if ATH_SUPPORT_VOW_DCS
    ATH_PARAM_DCS_COCH                  =93,
    ATH_PARAM_DCS_TXERR                 =94,
    ATH_PARAM_DCS_PHYERR                =95,
#endif
#if ATH_RX_LOOPLIMIT_TIMER
    ATH_PARAM_LOOPLIMIT_NUM                 =  111,
#endif
#if ATH_TX_DUTY_CYCLE
    ATH_PARAM_TX_DUTY_CYCLE            = 112,
#endif
    ATH_PARAM_NODEBUG              = 113,
    ATH_PARAM_GET_IF_ID			= 114,
    ATH_PARAM_ALLOW_PROMISC = 115,
    ATH_PARAM_ANTENNA_GAIN_2G           =116,
    ATH_PARAM_ANTENNA_GAIN_5G           =117,
    ATH_PARAM_ACS_ENABLE_BK_SCANTIMEREN = 118,  /*Enable Acs back Ground Channel selection Scan timer in AP mode*/
    ATH_PARAM_ACS_SCANTIME = 119,  /* ACS scan timer value in Seconds */
    ATH_PARAM_ACS_RSSIVAR = 120,   /*Negligence Delta RSSI between two channel */
    ATH_PARAM_ACS_CHLOADVAR = 121, /*Negligence Delta Channel load between two channel*/
    ATH_PARAM_ACS_LIMITEDOBSS = 122, /* Enable Limited OBSS check */
    ATH_PARAM_ACS_CTRLFLAG   = 123, /* Acs control flag for Scan timer */
    ATH_PARAM_ACS_DEBUGTRACE = 124, /* Acs Run time Debug level*/
#if ATH_SUPPORT_HYFI_ENHANCEMENTS
    ATH_PARAM_BUFF_THRESH               =125,
#endif
    ATH_PARAM_BLK_REPORT_FLOOD          =126,
    ATH_PARAM_DROP_STA_QUERY            =127,
#if ATH_SUPPORT_DSCP_OVERRIDE
    ATH_PARAM_DSCP_OVERRIDE             =128,
    ATH_PARAM_DSCP_TID_MAP_RESET        =129,
    ATH_PARAM_IGMP_DSCP_OVERRIDE        =130,
    ATH_PARAM_IGMP_DSCP_TID_MAP         =131,
    ATH_PARAM_HMMC_DSCP_OVERRIDE        =132,
    ATH_PARAM_HMMC_DSCP_TID_MAP         =133,
    ATH_PARAM_UPNP_DSCP_OVERRIDE        =134,
    ATH_PARAM_UPNP_DSCP_TID_MAP         =135,
#endif
#if ATH_SUPPORT_HYFI_ENHANCEMENTS
	ATH_PARAM_ALDSTATS                  = 136,
#endif
    ATH_PARAM_SET_FW_HANG_ID            = 137,
    ATH_PARAM_RADIO_TYPE                = 138,
    ATH_PARAM_FW_RECOVERY_ID		= 139,
    ATH_PARAM_RATE_ENABLE_RTS           = 140,
    ATH_PARAM_EN_SELECTIVE_RTS          = 141,
    ATH_PARAM_ATH_RXQ_INFO              = 142,
    ATH_PARAM_RESET_OL_STATS            = 143,
    ATH_PARAM_DISABLE_DFS               = 144,
#if ATH_CHANNEL_BLOCKING
    ATH_PARAM_ACS_BLOCK_MODE            = 145,
#endif
#if ATH_SUPPORT_DFS && ATH_SUPPORT_STA_DFS
    ATH_PARAM_STADFS_ENABLE             = 300,
#endif
    ATH_PARAM_ATF_STRICT_SCHED          = 301,
#if DBDC_REPEATER_SUPPORT
    ATH_PARAM_PRIMARY_RADIO             = 302,
    ATH_PARAM_DBDC_ENABLE               = 303,
#endif
    ATH_PARAM_ATH_CTL_POWER_SCALE       = 304,
    ATH_PARAM_ATF_OBSS_SCHED            = 306,
    ATH_PARAM_ATF_OBSS_SCALE            = 307,
    ATH_PARAM_PHY_OFDM_ERR              = 308,
    ATH_PARAM_PHY_CCK_ERR               = 309,
    ATH_PARAM_FCS_ERR                   = 310,
    ATH_PARAM_CHAN_UTIL                 = 311,
#if DBDC_REPEATER_SUPPORT
    ATH_PARAM_CLIENT_MCAST              = 312,
#endif
    ATH_PARAM_ATF_GROUP_SCHED_POLICY    = 313,
#if UMAC_SUPPORT_ACFG
    ATH_PARAM_DIAG_ENABLE               = 314,
#endif
    ATH_PARAM_CHAN_STATS_TH             = 316,
    ATH_PARAM_PASSIVE_SCAN_ENABLE       = 317,
    ATH_MIN_RSSI_ENABLE                 = 318,
    ATH_MIN_RSSI                        = 319,
#if QCA_AIRTIME_FAIRNESS
    ATH_PARAM_ATF_ADJUST_POSSIBLE_TPUT  = 320,
    ATH_PARAM_ATF_ADJUST_TPUT           = 321,
    ATH_PARAM_ATF_ADJUST_TPUT_MORE      = 322,
#endif
#if ATH_BT_COEX_3WIRE_MODE
    ATH_PARAM_ATH_3WIRE_BT_COEX         = 323,
    ATH_PARAM_ATH_3WIRE_BT_WEIGHT       = 324,
    ATH_PARAM_ATH_3WIRE_WL_WEIGHT       = 325,
#endif
    ATH_PARAM_ACS_2G_ALLCHAN           =  326,
#if DBDC_REPEATER_SUPPORT
    ATH_PARAM_DELAY_STAVAP_UP           = 327,
#endif
    ATH_PARAM_CHANSWITCH_OPTIONS        = 329,  /* It is used to set the channel switch options */
    ATH_PARAM_TID_OVERRIDE_QUEUE_MAPPING = 330,
    ATH_PARAM_NO_VLAN                   = 331,
    ATH_PARAM_ATF_LOGGING               = 332,
    ATH_PARAM_STRICT_DOTH               = 333,
    ATH_PARAM_DISCONNECTION_TIMEOUT     = 334,
    ATH_PARAM_RECONFIGURATION_TIMEOUT   = 335,
    ATH_PARAM_CHANNEL_SWITCH_COUNT      = 336,
#if DBDC_REPEATER_SUPPORT
    ATH_PARAM_ALWAYS_PRIMARY               = 337,
    ATH_PARAM_FAST_LANE                    = 338,
#endif
    ATH_PARAM_SECONDARY_OFFSET_IE       = 339,
    ATH_PARAM_WIDE_BAND_SUB_ELEMENT     = 340,
#if DBDC_REPEATER_SUPPORT
    ATH_PARAM_PREFERRED_UPLINK          = 341,
#endif
    ATH_PARAM_DUMP_OBJECTS              = 342,
    ATH_PARAM_ACS_SRLOADVAR             = 343, /* Negligence Delta SR load between two channels */
    ATH_PARAM_ACS_RANK                  = 344,
#if ATH_PARAMETER_API
    ATH_PARAM_PAPI_ENABLE               = 345,
#endif
    ATH_PARAM_MAX_CLIENTS_PER_RADIO     = 346,
    ATH_PARAM_NF_THRESH                 = 347,
} ath_param_ID_t;

#define ATH_TX_POWER_SRM 0

#ifndef WIN32
struct ath_diag {
    char    ad_name[IFNAMSIZ];    /* if name, e.g. "ath0" */
    u_int16_t ad_id;
#define    ATH_DIAG_DYN    0x8000        /* allocate buffer in caller */
#define    ATH_DIAG_IN    0x4000        /* copy in parameters */
#define    ATH_DIAG_OUT    0x0000        /* copy out results (always) */
#define    ATH_DIAG_ID    0x0fff
    u_int16_t ad_in_size;        /* pack to fit, yech */
    caddr_t    ad_in_data;
    caddr_t    ad_out_data;
    u_int    ad_out_size;
};

#define CTL_5G_SIZE 1536
#define CTL_2G_SIZE 684
#define MAX_CTL_SIZE (CTL_5G_SIZE > CTL_2G_SIZE ? CTL_5G_SIZE : CTL_2G_SIZE)

typedef struct ath_ctl_table {
    u_int32_t   len;
    u_int8_t   band;
    u_int8_t    ctl_tbl[MAX_CTL_SIZE];
} ath_ctl_table_t;


#define    ATH_RADAR_MUTE_TIME    1    /* Set dfs mute time for dfs test mode */


enum extended_ioctl_command {
    EXTENDED_SUBIOCTL_INVALID = 0,
    EXTENDED_SUBIOCTL_THERMAL_SET_PARAM,
    EXTENDED_SUBIOCTL_THERMAL_GET_PARAM,
    EXTENDED_SUBIOCTL_OL_RESERVE_PROXY_MACADDR,
    EXTENDED_SUBIOCTL_OL_GET_PROXY_NOACK_WAR,
    EXTENDED_SUBIOCTL_CHANNEL_SWITCH,
    EXTENDED_SUBIOCTL_CHANNEL_SCAN,
    EXTENDED_SUBIOCTL_GET_PRIMARY_RADIO,
    EXTENDED_SUBIOCTL_GET_MPSTA_MAC_ADDR,
    EXTENDED_SUBIOCTL_DISASSOC_CLIENTS,
    EXTENDED_SUBIOCTL_GET_FORCE_CLIENT_MCAST,
    EXTENDED_SUBIOCTL_GET_STAVAP_CONNECTION,
    EXTENDED_SUBIOCTL_GET_DISCONNECTION_TIMEOUT,
    EXTENDED_SUBIOCTL_IFACE_MGR_STATUS,
    EXTENDED_SUBIOCTL_GET_MAX_PRIORITY_RADIO,
    EXTENDED_SUBIOCTL_GET_PREF_UPLINK,
    EXTENDED_SUBIOCTL_GET_CHAN_VENDORSURVEY_INFO,
    EXTENDED_SUBIOCTL_REPEATER_MOVE,
    EXTENDED_SUBIOCTL_GET_CAC_STATE,
    /* Add New subioctls just above this comment */
};


#ifdef __linux__
#define SIOCGATHSTATS       (SIOCDEVPRIVATE+0)
#define SIOCGATHDIAG        (SIOCDEVPRIVATE+1)
#define SIOCGATHCWMINFO     (SIOCDEVPRIVATE+2)
#define SIOCGATHCWMDBG      (SIOCDEVPRIVATE+3)
#define SIOCGATHSTATSCLR    (SIOCDEVPRIVATE+4)
#define SIOCGATHPHYERR      (SIOCDEVPRIVATE+5)
#define SIOCGATHEACS        (SIOCDEVPRIVATE+6)
#define SIOCGATHEXTENDED    (SIOCDEVPRIVATE+8)
#define SIOCSATHSUSPEND     (SIOCDEVPRIVATE+10)
/* Currently exposed only for Linux, as part of some Access Point
   statistics.
   TODO: Implement for other platforms, if required. */
#define SIOCGATHPHYSTATS    (SIOCDEVPRIVATE+11)
#define SIOCG80211PROFILE     (SIOCDEVPRIVATE+12)
/* 13 for TX99 */
#define SIOCGATHPHYSTATSCUR (SIOCDEVPRIVATE+14)
#define SIOCGSETCTLPOW   	(SIOCDEVPRIVATE+15)

#define ATH_HAL_IOCTL_SETPARAM              (SIOCIWFIRSTPRIV+0)
#define ATH_HAL_IOCTL_GETPARAM              (SIOCIWFIRSTPRIV+1)
#define ATH_IOCTL_SETCOUNTRY                (SIOCIWFIRSTPRIV+2)
#define ATH_IOCTL_GETCOUNTRY                (SIOCIWFIRSTPRIV+3)
#define ATH_IOCTL_SETHWADDR                 (SIOCIWFIRSTPRIV+4)
#define ATH_IOCTL_GETHWADDR                 (SIOCIWFIRSTPRIV+5)
#define ATH_IOCTL_SET_DSCP_TID_MAP          (SIOCIWFIRSTPRIV+6)
#define ATH_IOCTL_GET_DSCP_TID_MAP          (SIOCIWFIRSTPRIV+7)
#if ATH_SUPPORT_DSCP_OVERRIDE
#define OL_ATH_IOCTL_SET_DSCP_TID_MAP       (SIOCIWFIRSTPRIV+8)
#define OL_ATH_IOCTL_GET_DSCP_TID_MAP       (SIOCIWFIRSTPRIV+9)
#endif
/* Both Direct attach and OL uses same IOCTL defines */
#define ATH_IOCTL_SET_SMART_ANTENNA   	(SIOCIWFIRSTPRIV+11)
#define ATH_IOCTL_GET_SMART_ANTENNA   	(SIOCIWFIRSTPRIV+12)





#define ATH_GET_COUNTRY                     1
#define ATH_SET_COUNTRY                     2

/* NOTE that ATH_IOCTL_EXTENDED corresponds to AR6000_IOCTL_EXTENDED from
 * the TOBA tree - this was necessary for interoperation between simulator
 * binary built in toba and the driver built in the newma tree.
 *
 * With qca_main, the simulator is built in the same workspace as the host
 * driver, but the idea of using ATH_IOCTL_EXTENDED to allow an expanded
 * range of ioctls remains.
 * The simulator ioctls are defined in sim_io.h, and start at 200.
 */
#if !defined(ATH_IOCTL_EXTENDED)
#define ATH_IOCTL_EXTENDED               (SIOCIWFIRSTPRIV+31)
#endif


/*
** We have to do a "split" of ID values, since they are all combined
** into the same table.  This value is a "shift" value for ATH parameters
*/

#define ATH_PARAM_SHIFT     0x1000
#define SPECIAL_PARAM_SHIFT 0x2000

#else /* __linux__ */

struct ath_privreq {
    char        ap_name[IFNAMSIZ];    /* if_name, e.g. "wi0" */
    u_int16_t    ap_type;        /* req type */
    int16_t        ap_val;            /* Index or simple value */
    int16_t        ap_len;            /* Index or simple value */
    void        *ap_data;        /* Extra data */
};
#define SIOCATHPRIV        _IOWR('i', 140, struct ath_privreq)
#define SIOCGATHSTATS       _IOWR('i', 137, struct ifreq)
#define SIOCGATHDIAG        _IOWR('i', 138, struct ath_diag)
#define SIOCGATHCWMINFO     _IOWR('i', 139, struct ath_cwminfo)
#ifndef REMOVE_PKT_LOG
#define SIOCGATHPKT         _IOWR('i', 141, struct ath_pktlog_ioctl)
#endif /* REMOVE_PKT_LOG */
#define SIOCGATHPHYERR      _IOWR('i', 142, struct ath_diag)
#define SIOCGATHTX99        _IOWR('i', 143, struct ath_diag)
#define SIOCGATHEACS        _IOWR('i', 145, struct ifreq)
#define SIOCGATHCWMDBG      _IOWR('i', 146, struct ath_cwmdbg)
#define SIOCGATHSTATSCLR    _IOWR('i', 147, struct ifreq)

/* ifreq, for athstats */
/* the system version of struct ifreq hides ifru_data64 from us in userland */
struct	ath_ifreq {
	char	ifr_name[IFNAMSIZ];		/* if name, e.g. "en0" */
	union {
		caddr_t	ifru_data;
	} ifr_ifru;
};

/*
 * packet_log support.
 */
#ifndef REMOVE_PKT_LOG
struct ieee80211com;
int ath_ioctl_pktlog(struct ieee80211com *, u_long, caddr_t);

struct ath_pktlog_ioctl {
    char    ap_name[IFNAMSIZ];    /* ifname, e.g. "ath0" */
    u_int16_t    ap_cmd;
    u_int32_t    ap_val;
    caddr_t    ap_data;
    u_int32_t    ap_data_size;
};


#define    ATH_PKT_ENABLE        1
#define    ATH_PKT_SETSIZE       2
#define    ATH_PKT_READ          3 /* Kept for compatibility with the old code */
#define    ATH_PKT_RESET         4
#define    ATH_PKT_GETSIZE       5
#define    ATH_PKT_GETBUF        6
#define    ATH_PKT_GET_LOGSTATE  7

#endif /* REMOVE_PKT_LOG */

#endif /* __linux__ */

#endif /* #ifndef WIN32 */
#endif /* _DEV_ATH_ATHIOCTL_H */

