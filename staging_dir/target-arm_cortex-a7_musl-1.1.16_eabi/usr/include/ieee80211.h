/*
 * Copyright (c) 2011,2017-2018 Qualcomm Innovation Center, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 *
 * Copyright (c) 2008 Atheros Communications Inc.
 * All Rights Reserved.
 *
 * 2011 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 *
 */

#ifndef EXTERNAL_USE_ONLY
#include <osdep.h>
#endif /* EXTERNAL_USE_ONLY */
#include "_ieee80211.h"
#ifndef _NET80211_IEEE80211_H_
#define _NET80211_IEEE80211_H_

#ifdef WIN32
#include <pshpack1.h>
#endif

/*
 * 802.11 protocol definitions.
 */

/* is 802.11 address multicast/broadcast? */
#define IEEE80211_IS_MULTICAST(_a)  (*(_a) & 0x01)

#define IEEE80211_IS_IPV4_MULTICAST(_a)  (*(_a) == 0x01)

#define IEEE80211_IS_IPV6_MULTICAST(_a)         \
    ((_a)[0] == 0x33 &&                         \
     (_a)[1] == 0x33)


#define IEEE80211_IS_BROADCAST(_a)              \
    ((_a)[0] == 0xff &&                         \
     (_a)[1] == 0xff &&                         \
     (_a)[2] == 0xff &&                         \
     (_a)[3] == 0xff &&                         \
     (_a)[4] == 0xff &&                         \
     (_a)[5] == 0xff)

/* Verify if the Addba Request frame contains Addba Extension Element */
#define IEEE80211_IS_ADDBA_EXT_PRESENT(_len)            \
    (_len >= sizeof(struct ieee80211_ba_addbaext))


/* IEEE 802.11 PLCP header */
struct ieee80211_plcp_hdr {
    u_int16_t   i_sfd;
    u_int8_t    i_signal;
    u_int8_t    i_service;
    u_int16_t   i_length;
    u_int16_t   i_crc;
} __packed;

#define IEEE80211_PLCP_SFD      0xF3A0
#define IEEE80211_PLCP_SERVICE  0x00
/*
 * generic definitions for IEEE 802.11 frames
 */
struct ieee80211_frame {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    union {
        struct {
            u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
            u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
            u_int8_t    i_addr3[IEEE80211_ADDR_LEN];
        };
        u_int8_t    i_addr_all[3 * IEEE80211_ADDR_LEN];
    };
    u_int8_t    i_seq[2];
    /* possibly followed by addr4[IEEE80211_ADDR_LEN]; */
    /* see below */
} __packed;

struct ieee80211_qosframe {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr3[IEEE80211_ADDR_LEN];
    u_int8_t    i_seq[2];
    u_int8_t    i_qos[2];
    /* possibly followed by addr4[IEEE80211_ADDR_LEN]; */
    /* see below */
} __packed;

struct ieee80211_qoscntl {
    u_int8_t    i_qos[2];
};

struct ieee80211_frame_addr4 {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr3[IEEE80211_ADDR_LEN];
    u_int8_t    i_seq[2];
    u_int8_t    i_addr4[IEEE80211_ADDR_LEN];
} __packed;

struct ieee80211_qosframe_addr4 {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr3[IEEE80211_ADDR_LEN];
    u_int8_t    i_seq[2];
    u_int8_t    i_addr4[IEEE80211_ADDR_LEN];
    u_int8_t    i_qos[2];
} __packed;

/* HTC frame for TxBF*/
// for TxBF RC
struct ieee80211_frame_min_one {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];

} __packed;// For TxBF RC

struct ieee80211_qosframe_htc {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr3[IEEE80211_ADDR_LEN];
    u_int8_t    i_seq[2];
    u_int8_t    i_qos[2];
    u_int8_t    i_htc[4];
    /* possibly followed by addr4[IEEE80211_ADDR_LEN]; */
    /* see below */
} __packed;
struct ieee80211_qosframe_htc_addr4 {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr3[IEEE80211_ADDR_LEN];
    u_int8_t    i_seq[2];
    u_int8_t    i_addr4[IEEE80211_ADDR_LEN];
    u_int8_t    i_qos[2];
    u_int8_t    i_htc[4];
} __packed;
struct ieee80211_htc {
    u_int8_t    i_htc[4];
};
/*HTC frame for TxBF*/

struct ieee80211_ctlframe_addr2 {
    u_int8_t    i_fc[2];
    u_int8_t    i_aidordur[2]; /* AID or duration */
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
} __packed;

#define	IEEE80211_WHQ(wh)		((struct ieee80211_qosframe *)(wh))
#define	IEEE80211_WH4(wh)		((struct ieee80211_frame_addr4 *)(wh))
#define	IEEE80211_WHQ4(wh)		((struct ieee80211_qosframe_addr4 *)(wh))

#define IEEE80211_FC0_VERSION_MASK          0x03
#define IEEE80211_FC0_VERSION_SHIFT         0
#define IEEE80211_FC0_VERSION_0             0x00
#define IEEE80211_FC0_TYPE_MASK             0x0c
#define IEEE80211_FC0_TYPE_SHIFT            2
#define IEEE80211_FC0_TYPE_MGT              0x00
#define IEEE80211_FC0_TYPE_CTL              0x04
#define IEEE80211_FC0_TYPE_DATA             0x08

#define IEEE80211_FC0_SUBTYPE_MASK          0xf0
#define IEEE80211_FC0_SUBTYPE_SHIFT         4
/* for TYPE_MGT */
#define IEEE80211_FC0_SUBTYPE_ASSOC_REQ     0x00
#define IEEE80211_FC0_SUBTYPE_ASSOC_RESP    0x10
#define IEEE80211_FC0_SUBTYPE_REASSOC_REQ   0x20
#define IEEE80211_FC0_SUBTYPE_REASSOC_RESP  0x30
#define IEEE80211_FC0_SUBTYPE_PROBE_REQ     0x40
#define IEEE80211_FC0_SUBTYPE_PROBE_RESP    0x50
#define IEEE80211_FC0_SUBTYPE_BEACON        0x80
#define IEEE80211_FC0_SUBTYPE_ATIM          0x90
#define IEEE80211_FC0_SUBTYPE_DISASSOC      0xa0
#define IEEE80211_FC0_SUBTYPE_AUTH          0xb0
#define IEEE80211_FC0_SUBTYPE_DEAUTH        0xc0
#define IEEE80211_FC0_SUBTYPE_ACTION        0xd0
#define IEEE80211_FCO_SUBTYPE_ACTION_NO_ACK 0xe0
/* for TYPE_CTL */
#define IEEE80211_FC0_SUBTYPE_TRIGGER       0x20
#define IEEE80211_FC0_SUBTYPE_BRPOLL        0x40
#define IEEE80211_FC0_SUBTYPE_NDPA          0x50
#define IEEE80211_FCO_SUBTYPE_Control_Wrapper   0x70    // For TxBF RC
#define IEEE80211_FC0_SUBTYPE_BAR           0x80
#define IEEE80211_FC0_BLOCK_ACK             0x90
#define IEEE80211_FC0_SUBTYPE_PS_POLL       0xa0
#define IEEE80211_FC0_SUBTYPE_RTS           0xb0
#define IEEE80211_FC0_SUBTYPE_CTS           0xc0
#define IEEE80211_FC0_SUBTYPE_ACK           0xd0
#define IEEE80211_FC0_SUBTYPE_CF_END        0xe0
#define IEEE80211_FC0_SUBTYPE_CF_END_ACK    0xf0
/* for TYPE_DATA (bit combination) */
#define IEEE80211_FC0_SUBTYPE_DATA          0x00
#define IEEE80211_FC0_SUBTYPE_CF_ACK        0x10
#define IEEE80211_FC0_SUBTYPE_CF_POLL       0x20
#define IEEE80211_FC0_SUBTYPE_CF_ACPL       0x30
#define IEEE80211_FC0_SUBTYPE_NODATA        0x40
#define IEEE80211_FC0_SUBTYPE_CFACK         0x50
#define IEEE80211_FC0_SUBTYPE_CFPOLL        0x60
#define IEEE80211_FC0_SUBTYPE_CF_ACK_CF_ACK 0x70
#define IEEE80211_FC0_SUBTYPE_QOS           0x80
#define IEEE80211_FC0_SUBTYPE_QOS_NULL      0xc0

#define IEEE80211_FC1_DIR_MASK              0x03
#define IEEE80211_FC1_DIR_NODS              0x00    /* STA->STA */
#define IEEE80211_FC1_DIR_TODS              0x01    /* STA->AP  */
#define IEEE80211_FC1_DIR_FROMDS            0x02    /* AP ->STA */
#define IEEE80211_FC1_DIR_DSTODS            0x03    /* AP ->AP  */

#define IEEE80211_FC1_MORE_FRAG             0x04
#define IEEE80211_FC1_RETRY                 0x08
#define IEEE80211_FC1_PWR_MGT               0x10
#define IEEE80211_FC1_MORE_DATA             0x20
#define IEEE80211_FC1_WEP                   0x40
#define IEEE80211_FC1_ORDER                 0x80

#define IEEE80211_SEQ_FRAG_MASK             0x000f
#define IEEE80211_SEQ_FRAG_SHIFT            0
#define IEEE80211_SEQ_SEQ_MASK              0xfff0
#define IEEE80211_SEQ_SEQ_SHIFT             4
#define IEEE80211_SEQ_MAX                   4096

#define IEEE80211_SEQ_LEQ(a,b)  ((int)((a)-(b)) <= 0)


#define IEEE80211_QOS_TXOP                  0x00ff

#define IEEE80211_QOS_AMSDU                 0x80
#define IEEE80211_QOS_AMSDU_S               7
#define IEEE80211_QOS_ACKPOLICY             0x60
#define IEEE80211_QOS_ACKPOLICY_S           5
#define IEEE80211_QOS_EOSP                  0x10
#define IEEE80211_QOS_EOSP_S                4
#define IEEE80211_QOS_TID                   0x0f
#define IEEE80211_MFP_TID                   0xff

#define IEEE80211_HTC0_TRQ                  0x02
#define	IEEE80211_HTC2_CalPos               0x03
#define	IEEE80211_HTC2_CalSeq               0x0C
#define	IEEE80211_HTC2_CSI_NONCOMP_BF       0x80
#define	IEEE80211_HTC2_CSI_COMP_BF          0xc0

/* Set bits 14 and 15 to 1 when duration field carries Association ID */
#define IEEE80211_FIELD_TYPE_AID            0xC000

#define IEEE80211_IS_BEACON(_frame)    ((((_frame)->i_fc[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_MGT) && \
                                        (((_frame)->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK) == IEEE80211_FC0_SUBTYPE_BEACON))
#define IEEE80211_IS_DATA(_frame)      (((_frame)->i_fc[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_DATA)

#define IEEE80211_IS_MFP_FRAME(_frame) ((((_frame)->i_fc[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_MGT) && \
                                        ((_frame)->i_fc[1] & IEEE80211_FC1_WEP) && \
                                        ((((_frame)->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK) == IEEE80211_FC0_SUBTYPE_DEAUTH) || \
                                         (((_frame)->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK) == IEEE80211_FC0_SUBTYPE_DISASSOC) || \
                                         (((_frame)->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK) == IEEE80211_FC0_SUBTYPE_ACTION)))
#define IEEE80211_IS_AUTH(_frame)      ((((_frame)->i_fc[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_MGT) && \
                                        (((_frame)->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK) == IEEE80211_FC0_SUBTYPE_AUTH))
#define IEEE80211_IS_PROBEREQ(_frame)  ((((_frame)->i_fc[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_MGT) && \
                                        (((_frame)->i_fc[0] & IEEE80211_FC0_SUBTYPE_MASK) == IEEE80211_FC0_SUBTYPE_PROBE_REQ))

/* MCS Set */
#define IEEE80211_RX_MCS_1_STREAM_BYTE_OFFSET 0
#define IEEE80211_RX_MCS_2_STREAM_BYTE_OFFSET 1
#define IEEE80211_RX_MCS_3_STREAM_BYTE_OFFSET 2
#define IEEE80211_RX_MCS_4_STREAM_BYTE_OFFSET 3
#define IEEE80211_RX_MCS_ALL_NSTREAM_RATES 0xff
#define IEEE80211_TX_MCS_OFFSET 12

#define IEEE80211_TX_MCS_SET_DEFINED 0x01
#define IEEE80211_TX_RX_MCS_SET_NOT_EQUAL 0x02
#define IEEE80211_TX_1_SPATIAL_STREAMS 0x0
#define IEEE80211_TX_2_SPATIAL_STREAMS 0x06
#define IEEE80211_TX_3_SPATIAL_STREAMS 0x08
#define IEEE80211_TX_4_SPATIAL_STREAMS 0x0c
#define IEEE80211_MAX_SPATIAL_STREAMS 4
#define IEEE80211_TX_MAXIMUM_STREAMS_MASK     0x0c
#define IEEE80211_TX_UNEQUAL_MODULATION_MASK  0x10

#define IEEE80211_TX_MCS_SET 0x1f

/*
 * Subtype data: If bit 6 is set then the data frame contains no actual data.
 */
#define IEEE80211_FC0_SUBTYPE_NO_DATA_MASK  0x40
#define IEEE80211_CONTAIN_DATA(_subtype) \
    (! ((_subtype) & IEEE80211_FC0_SUBTYPE_NO_DATA_MASK))

#define IEEE8023_MAX_LEN 0x600 /* 1536 - larger is Ethernet II */
#define RFC1042_SNAP_ORGCODE_0 0x00
#define RFC1042_SNAP_ORGCODE_1 0x00
#define RFC1042_SNAP_ORGCODE_2 0x00

#define BTEP_SNAP_ORGCODE_0 0x00
#define BTEP_SNAP_ORGCODE_1 0x00
#define BTEP_SNAP_ORGCODE_2 0xf8

/* BT 3.0 */
#define BTAMP_SNAP_ORGCODE_0 0x00
#define BTAMP_SNAP_ORGCODE_1 0x19
#define BTAMP_SNAP_ORGCODE_2 0x58

/* Aironet OUI Codes */
#define AIRONET_SNAP_CODE_0  0x00
#define AIRONET_SNAP_CODE_1  0x40
#define AIRONET_SNAP_CODE_2  0x96

#define IEEE80211_LSIG_LEN  3
#define IEEE80211_HTSIG_LEN 6
#define IEEE80211_SB_LEN    2

/* Specification IEEE80211-2003 Section 7.3.1.8:
 * AID is in the range 1(0x1)-2007(0x7d7)
 */
#define IEEE80211_ASSOC_ID_MASK 0x7ff

/*
 * Information element header format
 */
struct ieee80211_ie_header {
    u_int8_t    element_id;     /* Element Id */
    u_int8_t    length;         /* IE Length */
} __packed;

/*
 * Country information element.
 */
#define IEEE80211_COUNTRY_MAX_TRIPLETS (83)
struct ieee80211_ie_country {
    u_int8_t    country_id;
    u_int8_t    country_len;
    u_int8_t    country_str[3];
    u_int8_t    country_triplet[IEEE80211_COUNTRY_MAX_TRIPLETS*3];
} __packed;

/* does frame have QoS sequence control data */
#define IEEE80211_QOS_HAS_SEQ(wh) \
    (((wh)->i_fc[0] & \
      (IEEE80211_FC0_TYPE_MASK | IEEE80211_FC0_SUBTYPE_QOS)) == \
      (IEEE80211_FC0_TYPE_DATA | IEEE80211_FC0_SUBTYPE_QOS))

#define WME_QOSINFO_UAPSD   0x80  /* Mask for U-APSD field */
#define WME_QOSINFO_COUNT   0x0f  /* Mask for Param Set Count field */
/*
 * WME/802.11e information element.
 */
struct ieee80211_ie_wme {
    u_int8_t    wme_id;         /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    wme_len;        /* length in bytes */
    u_int8_t    wme_oui[3];     /* 0x00, 0x50, 0xf2 */
    u_int8_t    wme_type;       /* OUI type */
    u_int8_t    wme_subtype;    /* OUI subtype */
    u_int8_t    wme_version;    /* spec revision */
    u_int8_t    wme_info;       /* QoS info */
} __packed;

struct ieee80211_ie_timeout {
    u_int8_t ie_type; /* Timeout IE */
    u_int8_t ie_len;
    u_int8_t interval_type;
    u_int32_t value;
} __packed;

/*
 * TS INFO part of the tspec element is a collection of bit flags
 */
#if _BYTE_ORDER == _BIG_ENDIAN
struct ieee80211_tsinfo_bitmap {
    u_int8_t    one       : 1,
                direction : 2,
                tid       : 4,
                reserved1 : 1;
    u_int8_t    reserved2 : 2,
                dot1Dtag  : 3,
                psb       : 1,
                reserved3 : 1,
                zero      : 1;
    u_int8_t    reserved5 : 7,
                reserved4 : 1;
} __packed;
#else
struct ieee80211_tsinfo_bitmap {
    u_int8_t    reserved1 : 1,
                tid       : 4,
                direction : 2,
                one       : 1;
    u_int8_t    zero      : 1,
                reserved3 : 1,
                psb       : 1,
                dot1Dtag  : 3,
                reserved2 : 2;
    u_int8_t    reserved4 : 1,
                reserved5 : 7;
}  __packed;
#endif

/*
 * WME/802.11e Tspec Element
 */
struct ieee80211_wme_tspec {
    u_int8_t    ts_id;
    u_int8_t    ts_len;
    u_int8_t    ts_oui[3];
    u_int8_t    ts_oui_type;
    u_int8_t    ts_oui_subtype;
    u_int8_t    ts_version;
    union {
        struct {
            u_int8_t    ts_tsinfo[3];
            u_int8_t    ts_nom_msdu[2];
            u_int8_t    ts_max_msdu[2];
            u_int8_t    ts_min_svc[4];
            u_int8_t    ts_max_svc[4];
            u_int8_t    ts_inactv_intv[4];
            u_int8_t    ts_susp_intv[4];
            u_int8_t    ts_start_svc[4];
            u_int8_t    ts_min_rate[4];
            u_int8_t    ts_mean_rate[4];
            u_int8_t    ts_peak_rate[4];
            u_int8_t    ts_max_burst[4];
            u_int8_t    ts_delay[4];
            u_int8_t    ts_min_phy[4];
            u_int8_t    ts_surplus[2];
            u_int8_t    ts_medium_time[2];
        };
        u_int8_t wme_info_all[55];
    };
} __packed;

/*
 * WME AC parameter field
 */
struct ieee80211_wme_acparams {
    u_int8_t    acp_aci_aifsn;
    u_int8_t    acp_logcwminmax;
    u_int16_t   acp_txop;
} __packed;

#define IEEE80211_WME_PARAM_LEN 24
#define WME_NUM_AC              4       /* 4 AC categories */

#define WME_PARAM_ACI           0x60    /* Mask for ACI field */
#define WME_PARAM_ACI_S         5       /* Shift for ACI field */
#define WME_PARAM_ACM           0x10    /* Mask for ACM bit */
#define WME_PARAM_ACM_S         4       /* Shift for ACM bit */
#define WME_PARAM_AIFSN         0x0f    /* Mask for aifsn field */
#define WME_PARAM_AIFSN_S       0       /* Shift for aifsn field */
#define WME_PARAM_LOGCWMIN      0x0f    /* Mask for CwMin field (in log) */
#define WME_PARAM_LOGCWMIN_S    0       /* Shift for CwMin field */
#define WME_PARAM_LOGCWMAX      0xf0    /* Mask for CwMax field (in log) */
#define WME_PARAM_LOGCWMAX_S    4       /* Shift for CwMax field */

#define WME_AC_TO_TID(_ac) (       \
    ((_ac) == WME_AC_VO) ? 6 : \
    ((_ac) == WME_AC_VI) ? 5 : \
    ((_ac) == WME_AC_BK) ? 1 : \
    0)

#define TID_TO_WME_AC(_tid) (      \
    (((_tid) == 0) || ((_tid) == 3)) ? WME_AC_BE : \
    (((_tid) == 1) || ((_tid) == 2)) ? WME_AC_BK : \
    (((_tid) == 4) || ((_tid) == 5)) ? WME_AC_VI : \
    WME_AC_VO)

/*
 * WME Parameter Element
 */
struct ieee80211_wme_param {
    u_int8_t                        param_id;
    u_int8_t                        param_len;
    u_int8_t                        param_oui[3];
    u_int8_t                        param_oui_type;
    u_int8_t                        param_oui_sybtype;
    u_int8_t                        param_version;
    u_int8_t                        param_qosInfo;
    u_int8_t                        param_reserved;
    struct ieee80211_wme_acparams   params_acParams[WME_NUM_AC];
} __packed;

/*
 * WME U-APSD qos info field defines
 */
#define WME_CAPINFO_UAPSD_EN                    0x00000080
#define WME_CAPINFO_UAPSD_VO                    0x00000001
#define WME_CAPINFO_UAPSD_VI                    0x00000002
#define WME_CAPINFO_UAPSD_BK                    0x00000004
#define WME_CAPINFO_UAPSD_BE                    0x00000008
#define WME_CAPINFO_UAPSD_ACFLAGS_SHIFT         0
#define WME_CAPINFO_UAPSD_ACFLAGS_MASK          0xF
#define WME_CAPINFO_UAPSD_MAXSP_SHIFT           5
#define WME_CAPINFO_UAPSD_MAXSP_MASK            0x3
#define WME_CAPINFO_IE_OFFSET                   8
#define WME_UAPSD_MAXSP(_qosinfo) (((_qosinfo) >> WME_CAPINFO_UAPSD_MAXSP_SHIFT) & WME_CAPINFO_UAPSD_MAXSP_MASK)
#define WME_UAPSD_AC_ENABLED(_ac, _qosinfo) ( (1<<(3 - (_ac))) &   \
        (((_qosinfo) >> WME_CAPINFO_UAPSD_ACFLAGS_SHIFT) & WME_CAPINFO_UAPSD_ACFLAGS_MASK) )

/* Mask used to determined whether all queues are UAPSD-enabled */
#define WME_CAPINFO_UAPSD_ALL                   (WME_CAPINFO_UAPSD_VO | \
                                                 WME_CAPINFO_UAPSD_VI | \
                                                 WME_CAPINFO_UAPSD_BK | \
                                                 WME_CAPINFO_UAPSD_BE)
#define WME_CAPINFO_UAPSD_NONE                  0

#define WME_UAPSD_AC_MAX_VAL 		1
#define WME_UAPSD_AC_INVAL		 	WME_UAPSD_AC_MAX_VAL+1

#define MUEDCA_NUM_AC WME_NUM_AC
#define MUEDCA_MAX_UPDATE_CNT 15
#define MUEDCA_ECW_MAX 15
#define MUEDCA_AIFSN_MAX 15
#define MUEDCA_TIMER_MAX 255
#define MUEDCA_TIMER_MIN 40

#define IEEE80211_MUEDCA_LENGTH 14
#define IEEE80211_ELEMID_EXT_MUEDCA 38

#define IEEE80211_MUEDCA_AIFSN          0X0f
#define IEEE80211_MUEDCA_AIFSN_S        0
#define IEEE80211_MUEDCA_ACM            0x10
#define IEEE80211_MUEDCA_ACM_S          4
#define IEEE80211_MUEDCA_ACI            0x60
#define IEEE80211_MUEDCA_ACI_S          5
#define IEEE80211_MUEDCA_ECWMIN         0X0f
#define IEEE80211_MUEDCA_ECWMIN_S       0
#define IEEE80211_MUEDCA_ECWMAX         0Xf0
#define IEEE80211_MUEDCA_ECWMAX_S       4
#define IEEE80211_MUEDCA_UPDATE_COUNT   0X0f
#define IEEE80211_MUEDCA_UPDATE_COUNT_S 0

typedef struct ieee80211_muedca_param_record {
    u_int8_t    aifsn_aci;       /* AIFSN/ACI field
                                 * B3-B0: AIFSN
                                 * B4: ACM
                                 * B6-B5: ACI
                                 * B7: Reserved */
    u_int8_t    ecwminmax;      /* ECWmin/ECWmax field
                                 * B3-B0: ECWmin
                                 * B7-B4: ECWmax */
    u_int8_t    timer;          /* MU EDCA timer */
} ieee80211_muedca_param;

/* MU EDCA parameter set element structure */
struct ieee80211_ie_muedca {
    u_int8_t                muedca_id;              /* IEEE80211_ELEMID */
    u_int8_t                muedca_len;             /* length in bytes */
    u_int8_t                muedca_id_ext;          /* Element ID extension */
    u_int8_t                muedca_qosinfo;         /* QoS Info field */
    ieee80211_muedca_param  muedca_param_record[MUEDCA_NUM_AC]; /* MU EDCA param
                                                                 * record */
} __packed;

/*
 * Atheros Advanced Capability information element.
 */
struct ieee80211_ie_athAdvCap {
    u_int8_t    athAdvCap_id;           /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    athAdvCap_len;          /* length in bytes */
    u_int8_t    athAdvCap_oui[3];       /* 0x00, 0x03, 0x7f */
    u_int8_t    athAdvCap_type;         /* OUI type */
    u_int16_t   athAdvCap_version;      /* spec revision */
    u_int8_t    athAdvCap_capability;   /* Capability info */
    u_int16_t   athAdvCap_defKeyIndex;
} __packed;

/*
 * Atheros Extended Capability information element.
 */
struct ieee80211_ie_ath_extcap {
    u_int8_t    ath_extcap_id;          /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    ath_extcap_len;         /* length in bytes */
    u_int8_t    ath_extcap_oui[3];      /* 0x00, 0x03, 0x7f */
    u_int8_t    ath_extcap_type;        /* OUI type */
    u_int8_t    ath_extcap_subtype;     /* OUI subtype */
    u_int8_t    ath_extcap_version;     /* spec revision */
    u_int32_t   ath_extcap_extcap              : 16,  /* B0-15  extended capabilities */
                ath_extcap_weptkipaggr_rxdelim : 8,   /* B16-23 num delimiters for receiving WEP/TKIP aggregates */
                ath_extcap_reserved            : 8;   /* B24-31 reserved */
} __packed;

/*
 * Atheros XR information element.
 */
struct ieee80211_xr_param {
    u_int8_t    param_id;
    u_int8_t    param_len;
    u_int8_t    param_oui[3];
    u_int8_t    param_oui_type;
    u_int8_t    param_oui_sybtype;
    u_int8_t    param_version;
    u_int8_t    param_Info;
    u_int8_t    param_base_bssid[IEEE80211_ADDR_LEN];
    u_int8_t    param_xr_bssid[IEEE80211_ADDR_LEN];
    u_int16_t   param_xr_beacon_interval;
    u_int8_t    param_base_ath_capability;
    u_int8_t    param_xr_ath_capability;
} __packed;

/*
 * QCA Whole Home Coverage Rept Info information element.
 */
struct ieee80211_ie_whc_rept_info {
    u_int8_t    whc_rept_info_id;           /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    whc_rept_info_len;          /* length in bytes */
    u_int8_t    whc_rept_info_oui[3];       /* 0x8c, 0xfd, 0xf0 */
    u_int8_t    whc_rept_info_type;
    u_int8_t    whc_rept_info_subtype;
    u_int8_t    whc_rept_info_version;
} __packed;

/*
 * QCA Whole Home Coverage AP Info information element.
 */
struct ieee80211_ie_whc_apinfo {
    u_int8_t    whc_apinfo_id;           /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    whc_apinfo_len;          /* length in bytes */
    u_int8_t    whc_apinfo_oui[3];       /* 0x8c, 0xfd, 0xf0 */
    u_int8_t    whc_apinfo_type;
    u_int8_t    whc_apinfo_subtype;
    u_int8_t    whc_apinfo_version;
    u_int16_t   whc_apinfo_capabilities; /* SON/WDS/both */
    u_int8_t    whc_apinfo_root_ap_dist; /* in hops */
    u_int8_t    whc_apinfo_is_root_ap; /* is rootap or not */
    u_int8_t    whc_apinfo_num_conn_re; /* number of connected REs to this device */
    u_int8_t    whc_apinfo_uplink_bssid[IEEE80211_ADDR_LEN]; /* Parent device's BSSID */
    u_int16_t   whc_apinfo_uplink_rate; /* Rate in Mbps with parent device */
    u_int8_t    whc_apinfo_5g_bssid[IEEE80211_ADDR_LEN]; /* This device's 5G backhaulAP BSSID */
    u_int8_t    whc_apinfo_24g_bssid[IEEE80211_ADDR_LEN]; /* This device's 2.4G backhaulAP BSSID */
} __packed;

/*
 * SFA information element.
 */
struct ieee80211_ie_sfa {
    u_int8_t    sfa_id;         /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    sfa_len;        /* length in bytes */
    u_int8_t    sfa_oui[3];     /* 0x00, 0x40, 0x96 */
    u_int8_t    sfa_type;       /* OUI type */
    u_int8_t    sfa_caps;       /* Capabilities */
} __packed;

/* Atheros capabilities */
#define IEEE80211_ATHC_TURBOP   0x0001      /* Turbo Prime */
#define IEEE80211_ATHC_COMP     0x0002      /* Compression */
#define IEEE80211_ATHC_FF       0x0004      /* Fast Frames */
#define IEEE80211_ATHC_XR       0x0008      /* Xtended Range support */
#define IEEE80211_ATHC_AR       0x0010      /* Advanced Radar support */
#define IEEE80211_ATHC_BURST    0x0020      /* Bursting - not negotiated */
#define IEEE80211_ATHC_WME      0x0040      /* CWMin tuning */
#define IEEE80211_ATHC_BOOST    0x0080      /* Boost */
/* Atheros extended capabilities */
/* OWL device capable of WDS workaround */
#define IEEE80211_ATHEC_OWLWDSWAR        0x0001
#define IEEE80211_ATHEC_WEPTKIPAGGR	     0x0002
#define IEEE80211_ATHEC_EXTRADELIMWAR    0x0004
#define IEEE80211_ATHEC_PN_CHECK_WAR     0x0008
/*
 * Management Frames
 */

/*
 * *** Platform-specific code?? ***
 * In Vista one must use bit fields of type (unsigned short = u_int16_t) to
 * ensure data structure is of the correct size. ANSI C used to specify only
 * "int" bit fields, which led to a larger structure size in Windows (32 bits).
 *
 * We must make sure the following construction is valid in all OS's.
 */
union ieee80211_capability {
    struct {
        u_int16_t    ess                 : 1;
        u_int16_t    ibss                : 1;
        u_int16_t    cf_pollable         : 1;
        u_int16_t    cf_poll_request     : 1;
        u_int16_t    privacy             : 1;
        u_int16_t    short_preamble      : 1;
        u_int16_t    pbcc                : 1;
        u_int16_t    channel_agility     : 1;
        u_int16_t    spectrum_management : 1;
        u_int16_t    qos                 : 1;
        u_int16_t    short_slot_time     : 1;
        u_int16_t    apsd                : 1;
        u_int16_t    reserved2           : 1;
        u_int16_t    dsss_ofdm           : 1;
        u_int16_t    del_block_ack       : 1;
        u_int16_t    immed_block_ack     : 1;
    };

    u_int16_t   value;
} __packed;

struct ieee80211_beacon_frame {
    u_int8_t                      timestamp[8];    /* the value of sender's TSFTIMER */
    u_int16_t                     beacon_interval; /* the number of time units between target beacon transmission times */
    union ieee80211_capability    capability;
/* Value of capability for every bit
#define IEEE80211_CAPINFO_ESS               0x0001
#define IEEE80211_CAPINFO_IBSS              0x0002
#define IEEE80211_CAPINFO_CF_POLLABLE       0x0004
#define IEEE80211_CAPINFO_CF_POLLREQ        0x0008
#define IEEE80211_CAPINFO_PRIVACY           0x0010
#define IEEE80211_CAPINFO_SHORT_PREAMBLE    0x0020
#define IEEE80211_CAPINFO_PBCC              0x0040
#define IEEE80211_CAPINFO_CHNL_AGILITY      0x0080
#define IEEE80211_CAPINFO_SPECTRUM_MGMT     0x0100
#define IEEE80211_CAPINFO_QOS               0x0200
#define IEEE80211_CAPINFO_SHORT_SLOTTIME    0x0400
#define IEEE80211_CAPINFO_APSD              0x0800
#define IEEE80211_CAPINFO_RADIOMEAS         0x1000
#define IEEE80211_CAPINFO_DSSSOFDM          0x2000
bits 14-15 are reserved
*/
    struct ieee80211_ie_header    info_elements;
} __packed;

/*
 * Management Action Frames
 */

/* generic frame format */
struct ieee80211_action {
    u_int8_t    ia_category;
    u_int8_t    ia_action;
} __packed;

 /* FTMRR request */
struct ieee80211_ftmrrreq {
    struct ieee80211_action  header;
    u_int8_t    dialogtoken;
    u_int16_t   num_repetitions;
    u_int8_t     elem[1];     /* varialbe len sub element fileds */
} __packed;

/* spectrum action frame header */
struct ieee80211_action_measrep_header {
    struct ieee80211_action action_header;
    u_int8_t                dialog_token;
} __packed;

/*
 * MIMO Control VHT
 */
struct ieee80211_vht_mimo_ctrl {
   u_int32_t    nc:3,
                nr:3,
                bw:2,
                ng:2,
                cb:1,
                fb_type:5,
                reserved:2,
                sound_dialog_toknum:6,
                unused:8;
} __packed;


/*
 * VHT Action Group ID Management
 */
struct ieee80211_action_vht_gid_mgmt {
    struct ieee80211_action      action_header;
    u_int8_t                     member_status[8];
    u_int8_t                     user_position[16];
} __packed;

/* categories */
#define IEEE80211_ACTION_CAT_SPECTRUM             0   /* Spectrum management */
#define IEEE80211_ACTION_CAT_QOS                  1   /* IEEE QoS  */
#define IEEE80211_ACTION_CAT_DLS                  2   /* DLS */
#define IEEE80211_ACTION_CAT_BA                   3   /* BA */
#define IEEE80211_ACTION_CAT_PUBLIC               4   /* Public Action Frame */
#define IEEE80211_ACTION_CAT_RADIO                5   /* Radio management */
#define IEEE80211_ACTION_CAT_HT                   7   /* HT per IEEE802.11n-D1.06 */
#define IEEE80211_ACTION_CAT_SA_QUERY             8   /* SA Query per IEEE802.11w, PMF */
#define IEEE80211_ACTION_CAT_PROT_DUAL            9   /* Protected Dual of public action frame */
#define IEEE80211_ACTION_CAT_WNM                 10   /* WNM Action frame */
#define IEEE80211_ACTION_CAT_UNPROT_WNM          11   /* Unprotected WNM action frame */
#define IEEE80211_ACTION_CAT_WMM_QOS             17   /* QoS from WMM specification */
#define IEEE80211_ACTION_CAT_FST                 18   /* FST action frame */
#define IEEE80211_ACTION_CAT_VHT                 21   /* VHT Action */
#define IEEE80211_ACTION_CAT_VENDOR             127   /* Vendor specific action frame */

/* Spectrum Management actions */
#define IEEE80211_ACTION_MEAS_REQUEST       0   /* Measure channels */
#define IEEE80211_ACTION_MEAS_REPORT        1
#define IEEE80211_ACTION_TPC_REQUEST        2   /* Transmit Power control */
#define IEEE80211_ACTION_TPC_REPORT         3
#define IEEE80211_ACTION_CHAN_SWITCH        4   /* 802.11h Channel Switch Announcement */

/* HT actions */
#define IEEE80211_ACTION_HT_TXCHWIDTH       0   /* recommended transmission channel width */
#define IEEE80211_ACTION_HT_SMPOWERSAVE     1   /* Spatial Multiplexing (SM) Power Save */
#define IEEE80211_ACTION_HT_CSI             4   /* CSI Frame */
#define IEEE80211_ACTION_HT_NONCOMP_BF      5   /* Non-compressed Beamforming*/
#define IEEE80211_ACTION_HT_COMP_BF         6   /* Compressed Beamforming*/

/* VHT actions */
#define IEEE80211_ACTION_VHT_OPMODE         2  /* Operating  mode notification */


/* VHT Group ID management*/
#define IEEE80211_ACTION_VHT_GROUP_ID       1  /* Group ID management */

/* Spectrum channel switch action frame after IE*/
/* Public Actions*/

/* HT - recommended transmission channel width */
struct ieee80211_action_ht_txchwidth {
    struct ieee80211_action     at_header;
    u_int8_t                    at_chwidth;
} __packed;

#define IEEE80211_A_HT_TXCHWIDTH_20         0
#define IEEE80211_A_HT_TXCHWIDTH_2040       1

/* HT - Spatial Multiplexing (SM) Power Save */
struct ieee80211_action_ht_smpowersave {
    struct ieee80211_action     as_header;
    u_int8_t                    as_control;
} __packed;

/*HT - CSI Frame */     //for TxBF RC
#define MIMO_CONTROL_LEN 6
struct ieee80211_action_ht_CSI {
    struct ieee80211_action     as_header;
    u_int8_t                   mimo_control[MIMO_CONTROL_LEN];
} __packed;

/*HT - V/CV report frame*/
struct ieee80211_action_ht_txbf_rpt {
    struct ieee80211_action     as_header;
    u_int8_t                   mimo_control[MIMO_CONTROL_LEN];
} __packed;

/*
 * 802.11ac Operating Mode  Notification
 */
struct ieee80211_ie_op_mode {
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int8_t rx_nss_type        : 1,
                 rx_nss             : 3,
                 reserved           : 1,
                 bw_160_80p80       : 1,
                 ch_width           : 2;
#else
        u_int8_t ch_width           : 2,
                 bw_160_80p80       : 1,
                 reserved           : 1,
                 rx_nss             : 3,
                 rx_nss_type        : 1;
#endif
} __packed;

struct ieee80211_ie_op_mode_ntfy {
        u_int8_t    elem_id;
        u_int8_t    elem_len;
        struct ieee80211_ie_op_mode opmode;
} __packed;


/* VHT - recommended Channel width and Nss */
struct ieee80211_action_vht_opmode {
    struct ieee80211_action     at_header;
    struct ieee80211_ie_op_mode at_op_mode;
} __packed;

/* Vendor specific IE for bandwidth NSS mapping*/
struct ieee80211_bwnss_mapping {
    u_int8_t    bnm_id;              /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    bnm_len;             /* length in bytes */
    u_int8_t    bnm_oui[3];          /* 0x00, 0x03, 0x7f */
    u_int8_t    bnm_oui_type;        /* OUI type */
    u_int8_t    bnm_oui_subtype;     /* OUI Subtype */
    u_int8_t    bnm_oui_version;     /* OUI Version */
    u_int8_t    bnm_mapping;         /* bandwidth-NSS Mapping*/
} __packed;

/* Values defined for Bandwidth NSS Mapping */
#define IEEE80211_BW_NSS_MAP_1x1                (1)
#define IEEE80211_BW_NSS_MAP_2x2                (2)
#define IEEE80211_BW_NSS_MAP_3x3                (3)
#define IEEE80211_BW_NSS_MAP_4x4                (4)
#define IEEE80211_BW_NSS_MAP_5x5                (5)
#define IEEE80211_BW_NSS_MAP_6x6                (6)
#define IEEE80211_BW_NSS_MAP_7x7                (7)
#define IEEE80211_BW_NSS_MAP_8x8                (8)

/* Values defined for Bandwidth NSS Mapping advertising in prop IE */
#define IEEE80211_BW_NSS_ADV_IE_LEN                 (7)
#define IEEE80211_BW_NSS_ADV_MAP_160MHZ_S           (0)
#define IEEE80211_BW_NSS_ADV_MAP_160MHZ_M           (0x00000007)

/* Value defined to advertise 160/80_80 MHz Bandwidth NSS Mapping.
 * Note: Separate values for 160 MHz and 80+80 MHz are not advertised in
 * proprietary IE, since our architecture supports only same values for
 * 160 MHz and 80+80 MHz
 */
#define IEEE80211_BW_NSS_ADV_160(x)             (((x - 1) << IEEE80211_BW_NSS_ADV_MAP_160MHZ_S)\
                                                 & IEEE80211_BW_NSS_ADV_MAP_160MHZ_M)

/* Values defined for Bandwidth NSS Mapping being sent to FW */
#define IEEE80211_BW_NSS_FWCONF_MAP_ENABLE             (1 << 31)
#define IEEE80211_BW_NSS_FWCONF_MAP_160MHZ_S           (0)
#define IEEE80211_BW_NSS_FWCONF_MAP_160MHZ_M           (0x00000007)
#define IEEE80211_BW_NSS_FWCONF_MAP_80_80MHZ_S         (3)
#define IEEE80211_BW_NSS_FWCONF_MAP_80_80MHZ_M         (0x00000038)
#define IEEE80211_BW_NSS_FWCONF_MAP_M                  (0x0000003F)


#define IEEE80211_GET_BW_NSS_FWCONF_160(x)             ((((x) & IEEE80211_BW_NSS_FWCONF_MAP_160MHZ_M)\
                                                 >> IEEE80211_BW_NSS_FWCONF_MAP_160MHZ_S) + 1)

#define IEEE80211_GET_BW_NSS_FWCONF_80_80(x)           ((((x) & IEEE80211_BW_NSS_FWCONF_MAP_80_80MHZ_M)\
                                                    >> IEEE80211_BW_NSS_FWCONF_MAP_80_80MHZ_S) + 1)

/* Values defined to set 160 MHz Bandwidth NSS Mapping into FW*/

#define IEEE80211_BW_NSS_FWCONF_160(x)          (IEEE80211_BW_NSS_FWCONF_MAP_ENABLE |\
                                                 (((x - 1) << IEEE80211_BW_NSS_FWCONF_MAP_160MHZ_S) \
                                                   & IEEE80211_BW_NSS_FWCONF_MAP_160MHZ_M))

#define IEEE80211_BW_NSS_FWCONF_80_80(x)        (IEEE80211_BW_NSS_FWCONF_MAP_ENABLE |\
                                                 (((x - 1) << IEEE80211_BW_NSS_FWCONF_MAP_80_80MHZ_S) \
                                                   & IEEE80211_BW_NSS_FWCONF_MAP_80_80MHZ_M))

/* values defined for 'as_control' field per 802.11n-D1.06 */
#define IEEE80211_A_HT_SMPOWERSAVE_DISABLED     0x00   /* SM Power Save Disabled, SM packets ok  */
#define IEEE80211_A_HT_SMPOWERSAVE_ENABLED      0x01   /* SM Power Save Enabled bit  */
#define IEEE80211_A_HT_SMPOWERSAVE_MODE         0x02   /* SM Power Save Mode bit */
#define IEEE80211_A_HT_SMPOWERSAVE_RESERVED     0xFC   /* SM Power Save Reserved bits */

/* values defined for SM Power Save Mode bit */
#define IEEE80211_A_HT_SMPOWERSAVE_STATIC       0x00   /* Static, SM packets not ok */
#define IEEE80211_A_HT_SMPOWERSAVE_DYNAMIC      0x02   /* Dynamic, SM packets ok if preceded by RTS */

/* DLS actions */
#define IEEE80211_ACTION_DLS_REQUEST            0
#define IEEE80211_ACTION_DLS_RESPONSE           1
#define IEEE80211_ACTION_DLS_TEARDOWN           2

struct ieee80211_dls_request {
	struct ieee80211_action hdr;
    u_int8_t dst_addr[IEEE80211_ADDR_LEN];
    u_int8_t src_addr[IEEE80211_ADDR_LEN];
    u_int16_t capa_info;
    u_int16_t timeout;
} __packed;

struct ieee80211_dls_response {
	struct ieee80211_action hdr;
    u_int16_t statuscode;
    u_int8_t dst_addr[IEEE80211_ADDR_LEN];
    u_int8_t src_addr[IEEE80211_ADDR_LEN];
} __packed;

/* BA actions */
#define IEEE80211_ACTION_BA_ADDBA_REQUEST       0   /* ADDBA request */
#define IEEE80211_ACTION_BA_ADDBA_RESPONSE      1   /* ADDBA response */
#define IEEE80211_ACTION_BA_DELBA               2   /* DELBA */

/* Default BA window size to use
 * if requested window size is 0
 */
#define DEFAULT_SELF_BA_SIZE 64

struct ieee80211_ba_parameterset {
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int16_t   buffersize      : 10,   /* B6-15  buffer size */
                    tid             : 4,    /* B2-5   TID */
                    bapolicy        : 1,    /* B1   block ack policy */
                    amsdusupported  : 1;    /* B0   amsdu supported */
#else
        u_int16_t   amsdusupported  : 1,    /* B0   amsdu supported */
                    bapolicy        : 1,    /* B1   block ack policy */
                    tid             : 4,    /* B2-5   TID */
                    buffersize      : 10;   /* B6-15  buffer size */
#endif
} __packed;

#define  IEEE80211_BA_POLICY_DELAYED      0
#define  IEEE80211_BA_POLICY_IMMEDIATE    1
#define  IEEE80211_BA_AMSDU_SUPPORTED     1

#define  IEEE80211_ADDBA_EXT_ELEM_ID     0x9f
#define  IEEE80211_ADDBA_EXT_ELEM_ID_LEN 0x01

struct ieee80211_ba_seqctrl {
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int16_t   startseqnum     : 12,    /* B4-15  starting sequence number */
                    fragnum         : 4;     /* B0-3  fragment number */
#else
        u_int16_t   fragnum         : 4,     /* B0-3  fragment number */
                    startseqnum     : 12;    /* B4-15  starting sequence number */
#endif
} __packed;

struct ieee80211_ba_addbaext {
        u_int8_t    elemid;                     /* element id of ADDBA
                                                 * extension element */
        u_int8_t    length;                     /* length of ADDBA
                                                 * extension element */
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int8_t    reserved            :5,     /* B3-7 Reserved Bits  */
                    he_fragmentation    :2,     /* B2-1 He Fragmentation Bits */
                    no_frag_bit         :1;     /* B0 No-fragmentation bit */
#else
        u_int8_t    no_frag_bit         :1,     /* B0 No-fragmentation bit */
                    he_fragmentation    :2,     /* B2-1 He Fragmentation Bits */
                    reserved            :5;     /* B3-7 Reserved Bits  */
#endif
} __packed;


struct ieee80211_delba_parameterset {
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int16_t   tid             : 4,     /* B12-15  tid */
                    initiator       : 1,     /* B11     initiator */
                    reserved0       : 11;    /* B0-10   reserved */
#else
        u_int16_t   reserved0       : 11,    /* B0-10   reserved */
                    initiator       : 1,     /* B11     initiator */
                    tid             : 4;     /* B12-15  tid */
#endif
} __packed;

/* BA - ADDBA request */
struct ieee80211_action_ba_addbarequest {
    struct ieee80211_action             rq_header;
    u_int8_t                            rq_dialogtoken;
    struct ieee80211_ba_parameterset    rq_baparamset;
    u_int16_t                           rq_batimeout;   /* in TUs */
    struct ieee80211_ba_seqctrl         rq_basequencectrl;
} __packed;

/* BA - ADDBA response */
struct ieee80211_action_ba_addbaresponse {
    struct ieee80211_action             rs_header;
    u_int8_t                            rs_dialogtoken;
    u_int16_t                           rs_statuscode;
    struct ieee80211_ba_parameterset    rs_baparamset;
    u_int16_t                           rs_batimeout;   /* in TUs */
} __packed;

/* BA - DELBA */
struct ieee80211_action_ba_delba {
    struct ieee80211_action                dl_header;
    struct ieee80211_delba_parameterset    dl_delbaparamset;
    u_int16_t                              dl_reasoncode;
} __packed;

/* MGT Notif actions */
#define IEEE80211_WMM_QOS_ACTION_SETUP_REQ    0
#define IEEE80211_WMM_QOS_ACTION_SETUP_RESP   1
#define IEEE80211_WMM_QOS_ACTION_TEARDOWN     2

#define IEEE80211_WMM_QOS_DIALOG_TEARDOWN     0
#define IEEE80211_WMM_QOS_DIALOG_SETUP        1

#define IEEE80211_WMM_QOS_TSID_DATA_TSPEC     6
#define IEEE80211_WMM_QOS_TSID_SIG_TSPEC      7

struct ieee80211_action_wmm_qos {
    struct ieee80211_action             ts_header;
    u_int8_t                            ts_dialogtoken;
    u_int8_t                            ts_statuscode;
    struct ieee80211_wme_tspec          ts_tspecie;
} __packed;

/*
 * Control frames.
 */
struct ieee80211_frame_min {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_addr1[IEEE80211_ADDR_LEN];
    u_int8_t    i_addr2[IEEE80211_ADDR_LEN];
    /* FCS */
} __packed;

/*
 * BAR frame format
 */
#define IEEE80211_BAR_CTL_TID_M     0xF000      /* tid mask             */
#define IEEE80211_BAR_CTL_TID_S         12      /* tid shift            */
#define IEEE80211_BAR_CTL_NOACK     0x0001      /* no-ack policy        */
#define IEEE80211_BAR_CTL_COMBA     0x0004      /* compressed block-ack */

/*
 * SA Query Action mgmt Frame
 */
struct ieee80211_action_sa_query {
    struct ieee80211_action     sa_header;
    u_int16_t                   sa_transId;
};

typedef enum ieee80211_action_sa_query_type{
    IEEE80211_ACTION_SA_QUERY_REQUEST,
    IEEE80211_ACTION_SA_QUERY_RESPONSE
}ieee80211_action_sa_query_type_t;

struct ieee80211_frame_bar {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_ra[IEEE80211_ADDR_LEN];
    u_int8_t    i_ta[IEEE80211_ADDR_LEN];
    u_int16_t   i_ctl;
    u_int16_t   i_seq;
    /* FCS */
} __packed;

struct ieee80211_frame_rts {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_ra[IEEE80211_ADDR_LEN];
    u_int8_t    i_ta[IEEE80211_ADDR_LEN];
    /* FCS */
} __packed;

struct ieee80211_frame_cts {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_ra[IEEE80211_ADDR_LEN];
    /* FCS */
} __packed;

struct ieee80211_frame_ack {
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];
    u_int8_t    i_ra[IEEE80211_ADDR_LEN];
    /* FCS */
} __packed;

struct ieee80211_frame_pspoll {
    u_int8_t    i_fc[2];
    u_int8_t    i_aid[2];
    u_int8_t    i_bssid[IEEE80211_ADDR_LEN];
    u_int8_t    i_ta[IEEE80211_ADDR_LEN];
    /* FCS */
} __packed;

struct ieee80211_frame_cfend {      /* NB: also CF-End+CF-Ack */
    u_int8_t    i_fc[2];
    u_int8_t    i_dur[2];   /* should be zero */
    u_int8_t    i_ra[IEEE80211_ADDR_LEN];
    u_int8_t    i_bssid[IEEE80211_ADDR_LEN];
    /* FCS */
} __packed;

/*
 * BEACON management packets
 *
 *  octet timestamp[8]
 *  octet beacon interval[2]
 *  octet capability information[2]
 *  information element
 *      octet elemid
 *      octet length
 *      octet information[length]
 */

typedef u_int8_t *ieee80211_mgt_beacon_t;

#define IEEE80211_BEACON_INTERVAL(beacon) \
    ((beacon)[8] | ((beacon)[9] << 8))
#define IEEE80211_BEACON_CAPABILITY(beacon) \
    ((beacon)[10] | ((beacon)[11] << 8))

#define IEEE80211_CAPINFO_ESS               0x0001
#define IEEE80211_CAPINFO_IBSS              0x0002
#define IEEE80211_CAPINFO_CF_POLLABLE       0x0004
#define IEEE80211_CAPINFO_CF_POLLREQ        0x0008
#define IEEE80211_CAPINFO_PRIVACY           0x0010
#define IEEE80211_CAPINFO_SHORT_PREAMBLE    0x0020
#define IEEE80211_CAPINFO_PBCC              0x0040
#define IEEE80211_CAPINFO_CHNL_AGILITY      0x0080
#define IEEE80211_CAPINFO_SPECTRUM_MGMT     0x0100
#define IEEE80211_CAPINFO_QOS               0x0200
#define IEEE80211_CAPINFO_SHORT_SLOTTIME    0x0400
#define IEEE80211_CAPINFO_APSD              0x0800
#define IEEE80211_CAPINFO_RADIOMEAS         0x1000
#define IEEE80211_CAPINFO_DSSSOFDM          0x2000
/* bits 14-15 are reserved */

/*
 * 802.11i/WPA information element (maximally sized).
 */
struct ieee80211_ie_wpa {
    u_int8_t    wpa_id;          /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    wpa_len;         /* length in bytes */
    u_int8_t    wpa_oui[3];      /* 0x00, 0x50, 0xf2 */
    u_int8_t    wpa_type;        /* OUI type */
    u_int16_t   wpa_version;     /* spec revision */
    u_int32_t   wpa_mcipher[1];  /* multicast/group key cipher */
    u_int16_t   wpa_uciphercnt;  /* # pairwise key ciphers */
    u_int32_t   wpa_uciphers[8]; /* ciphers */
    u_int16_t   wpa_authselcnt;  /* authentication selector cnt */
    u_int32_t   wpa_authsels[8]; /* selectors */
    u_int16_t   wpa_caps;        /* 802.11i capabilities */
    u_int16_t   wpa_pmkidcnt;    /* 802.11i pmkid count */
    u_int16_t   wpa_pmkids[8];   /* 802.11i pmkids */
} __packed;

#ifndef _BYTE_ORDER
#error "Don't know native byte order"
#endif

#ifndef IEEE80211N_IE
/* Temporary vendor specific IE for 11n pre-standard interoperability */
#define VENDOR_HT_OUI       0x00904c
#define VENDOR_HT_CAP_ID    51
#define VENDOR_HT_INFO_ID   52
#endif

#ifdef ATH_SUPPORT_TxBF
union ieee80211_hc_txbf {
    struct {
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int32_t   reserved              : 3,
                channel_estimation_cap    : 2,
                csi_max_rows_bfer         : 2,
                comp_bfer_antennas        : 2,
                noncomp_bfer_antennas     : 2,
                csi_bfer_antennas         : 2,
                minimal_grouping          : 2,
                explicit_comp_bf          : 2,
                explicit_noncomp_bf       : 2,
                explicit_csi_feedback     : 2,
                explicit_comp_steering    : 1,
                explicit_noncomp_steering : 1,
                explicit_csi_txbf_capable : 1,
                calibration               : 2,
                implicit_txbf_capable     : 1,
                tx_ndp_capable            : 1,
                rx_ndp_capable            : 1,
                tx_staggered_sounding     : 1,
                rx_staggered_sounding     : 1,
                implicit_rx_capable       : 1;
#else
        u_int32_t   implicit_rx_capable   : 1,
                rx_staggered_sounding     : 1,
                tx_staggered_sounding     : 1,
                rx_ndp_capable            : 1,
                tx_ndp_capable            : 1,
                implicit_txbf_capable     : 1,
                calibration               : 2,
                explicit_csi_txbf_capable : 1,
                explicit_noncomp_steering : 1,
                explicit_comp_steering    : 1,
                explicit_csi_feedback     : 2,
                explicit_noncomp_bf       : 2,
                explicit_comp_bf          : 2,
                minimal_grouping          : 2,
                csi_bfer_antennas         : 2,
                noncomp_bfer_antennas     : 2,
                comp_bfer_antennas        : 2,
                csi_max_rows_bfer         : 2,
                channel_estimation_cap    : 2,
                reserved                  : 3;
#endif
    };

    u_int32_t value;
} __packed;
#endif

struct ieee80211_ie_htcap_cmn {
    u_int16_t   hc_cap;         /* HT capabilities */
#if _BYTE_ORDER == _BIG_ENDIAN
    u_int8_t    hc_reserved     : 3,    /* B5-7 reserved */
                hc_mpdudensity  : 3,    /* B2-4 MPDU density (aka Minimum MPDU Start Spacing) */
                hc_maxampdu     : 2;    /* B0-1 maximum rx A-MPDU factor */
#else
    u_int8_t    hc_maxampdu     : 2,    /* B0-1 maximum rx A-MPDU factor */
                hc_mpdudensity  : 3,    /* B2-4 MPDU density (aka Minimum MPDU Start Spacing) */
                hc_reserved     : 3;    /* B5-7 reserved */
#endif
    u_int8_t    hc_mcsset[16];          /* supported MCS set */
    u_int16_t   hc_extcap;              /* extended HT capabilities */
#ifdef ATH_SUPPORT_TxBF
    union ieee80211_hc_txbf hc_txbf;    /* txbf capabilities */
#else
    u_int32_t   hc_txbf;                /* txbf capabilities */
#endif
    u_int8_t    hc_antenna;             /* antenna capabilities */
} __packed;

/*
 * 802.11n HT Capability IE
 */
struct ieee80211_ie_htcap {
    u_int8_t                         hc_id;      /* element ID */
    u_int8_t                         hc_len;     /* length in bytes */
    struct ieee80211_ie_htcap_cmn    hc_ie;
} __packed;

/*
 * Temporary vendor private HT Capability IE
 */
struct vendor_ie_htcap {
    u_int8_t                         hc_id;          /* element ID */
    u_int8_t                         hc_len;         /* length in bytes */
    u_int8_t                         hc_oui[3];
    u_int8_t                         hc_ouitype;
    struct ieee80211_ie_htcap_cmn    hc_ie;
} __packed;

/* HT capability flags */
#define IEEE80211_HTCAP_C_ADVCODING             0x0001
#define IEEE80211_HTCAP_C_CHWIDTH40             0x0002
#define IEEE80211_HTCAP_C_SMPOWERSAVE_STATIC    0x0000 /* Capable of SM Power Save (Static) */
#define IEEE80211_HTCAP_C_SMPOWERSAVE_DYNAMIC   0x0004 /* Capable of SM Power Save (Dynamic) */
#define IEEE80211_HTCAP_C_SM_RESERVED           0x0008 /* Reserved */
#define IEEE80211_HTCAP_C_SMPOWERSAVE_DISABLED            0x000c /* SM enabled, no SM Power Save */
#define IEEE80211_HTCAP_C_GREENFIELD            0x0010
#define IEEE80211_HTCAP_C_SHORTGI20             0x0020
#define IEEE80211_HTCAP_C_SHORTGI40             0x0040
#define IEEE80211_HTCAP_C_TXSTBC                0x0080
#define IEEE80211_HTCAP_C_TXSTBC_S                   7
#define IEEE80211_HTCAP_C_RXSTBC                0x0300  /* 2 bits */
#define IEEE80211_HTCAP_C_RXSTBC_S                   8
#define IEEE80211_HTCAP_C_DELAYEDBLKACK         0x0400
#define IEEE80211_HTCAP_C_MAXAMSDUSIZE          0x0800  /* 1 = 8K, 0 = 3839B */
#define IEEE80211_HTCAP_C_DSSSCCK40             0x1000
#define IEEE80211_HTCAP_C_PSMP                  0x2000
#define IEEE80211_HTCAP_C_INTOLERANT40          0x4000
#define IEEE80211_HTCAP_C_LSIGTXOPPROT          0x8000

#define IEEE80211_HTCAP_C_SM_MASK               0x000c /* Spatial Multiplexing (SM) capabitlity bitmask */

/* ldpc */
#define IEEE80211_HTCAP_C_LDPC_NONE		0
#define IEEE80211_HTCAP_C_LDPC_RX		0x1
#define IEEE80211_HTCAP_C_LDPC_TX		0x2
#define IEEE80211_HTCAP_C_LDPC_TXRX		0x3

/* B0-1 maximum rx A-MPDU factor 2^(13+Max Rx A-MPDU Factor) */
enum {
    IEEE80211_HTCAP_MAXRXAMPDU_8192,    /* 2 ^ 13 */
    IEEE80211_HTCAP_MAXRXAMPDU_16384,   /* 2 ^ 14 */
    IEEE80211_HTCAP_MAXRXAMPDU_32768,   /* 2 ^ 15 */
    IEEE80211_HTCAP_MAXRXAMPDU_65536,   /* 2 ^ 16 */
};
#define IEEE80211_HTCAP_MAXRXAMPDU_FACTOR   13

/* B2-4 MPDU density (usec) */
enum {
    IEEE80211_HTCAP_MPDUDENSITY_NA,     /* No time restriction */
    IEEE80211_HTCAP_MPDUDENSITY_0_25,   /* 1/4 usec */
    IEEE80211_HTCAP_MPDUDENSITY_0_5,    /* 1/2 usec */
    IEEE80211_HTCAP_MPDUDENSITY_1,      /* 1 usec */
    IEEE80211_HTCAP_MPDUDENSITY_2,      /* 2 usec */
    IEEE80211_HTCAP_MPDUDENSITY_4,      /* 4 usec */
    IEEE80211_HTCAP_MPDUDENSITY_8,      /* 8 usec */
    IEEE80211_HTCAP_MPDUDENSITY_16,     /* 16 usec */
    IEEE80211_HTCAP_MPDUDENSITY_MAX = IEEE80211_HTCAP_MPDUDENSITY_16,
    IEEE80211_HTCAP_MPDUDENSITY_INVALID, /* Invalid */
};

/* HT extended capability flags */
#define IEEE80211_HTCAP_EXTC_PCO                0x0001
#define IEEE80211_HTCAP_EXTC_TRANS_TIME_RSVD    0x0000
#define IEEE80211_HTCAP_EXTC_TRANS_TIME_400     0x0002 /* 20-40 switch time */
#define IEEE80211_HTCAP_EXTC_TRANS_TIME_1500    0x0004 /* in us             */
#define IEEE80211_HTCAP_EXTC_TRANS_TIME_5000    0x0006
#define IEEE80211_HTCAP_EXTC_RSVD_1             0x00f8
#define IEEE80211_HTCAP_EXTC_MCS_FEEDBACK_NONE  0x0000
#define IEEE80211_HTCAP_EXTC_MCS_FEEDBACK_RSVD  0x0100
#define IEEE80211_HTCAP_EXTC_MCS_FEEDBACK_UNSOL 0x0200
#define IEEE80211_HTCAP_EXTC_MCS_FEEDBACK_FULL  0x0300
#define IEEE80211_HTCAP_EXTC_RSVD_2             0xfc00
#ifdef ATH_SUPPORT_TxBF
#define IEEE80211_HTCAP_EXTC_HTC_SUPPORT        0x0400
#endif

struct ieee80211_ie_htinfo_cmn {
    u_int8_t    hi_ctrlchannel;     /* control channel */
#if _BYTE_ORDER == _BIG_ENDIAN
    u_int8_t    hi_serviceinterval    : 3,    /* B5-7 svc interval granularity */
                hi_ctrlaccess         : 1,    /* B4   controlled access only */
                hi_rifsmode           : 1,    /* B3   rifs mode */
                hi_txchwidth          : 1,    /* B2   recommended xmiss width set */
                hi_extchoff           : 2;    /* B0-1 extension channel offset */


/*

 * The following 2 consecutive bytes are defined in word in 80211n spec.

 * Some processors store MSB byte into lower memory address which causes wrong

 * wrong byte sequence in beacon. Thus we break into byte definition which should

 * avoid the problem for all processors

 */

    u_int8_t    hi_ccfs2_1            : 3,    /* CCFS2 for ext NSS B5-B7 */

                hi_obssnonhtpresent   : 1,    /* B4   OBSS non-HT STA present */

                hi_txburstlimit       : 1,    /* B3   transmit burst limit */

                hi_nongfpresent       : 1,    /* B2   non greenfield devices present */

                hi_opmode             : 2;    /* B0-1 operating mode */

    u_int8_t    hi_reserved0          : 3,    /* B5-7 (B13-15 in 11n) reserved */
                hi_ccfs2_2            : 5;    /* CCFS2 for ext NSS B0-B4 */

/* The following 2 consecutive bytes are defined in word in 80211n spec. */

    u_int8_t    hi_dualctsprot        : 1,    /* B7   dual CTS protection */
                hi_dualbeacon         : 1,    /* B6   dual beacon */
                hi_reserved2          : 6;    /* B0-5 reserved */
    u_int8_t    hi_reserved1          : 4,    /* B4-7 (B12-15 in 11n) reserved */
                hi_pcophase           : 1,    /* B3   (B11 in 11n)  pco phase */
                hi_pcoactive          : 1,    /* B2   (B10 in 11n)  pco active */
                hi_lsigtxopprot       : 1,    /* B1   (B9 in 11n)   l-sig txop protection full support */
                hi_stbcbeacon         : 1;    /* B0   (B8 in 11n)   STBC beacon */
#else
    u_int8_t    hi_extchoff           : 2,    /* B0-1 extension channel offset */
                hi_txchwidth          : 1,    /* B2   recommended xmiss width set */
                hi_rifsmode           : 1,    /* B3   rifs mode */
                hi_ctrlaccess         : 1,    /* B4   controlled access only */
                hi_serviceinterval    : 3;    /* B5-7 svc interval granularity */
    u_int16_t   hi_opmode             : 2,    /* B0-1 operating mode */
                hi_nongfpresent       : 1,    /* B2   non greenfield devices present */
                hi_txburstlimit       : 1,    /* B3   transmit burst limit */
                hi_obssnonhtpresent   : 1,    /* B4   OBSS non-HT STA present */
                hi_ccfs2_1            : 3,    /* B5-B12 ccfs2 for ext nss */
                hi_ccfs2_2            : 5,    /* B5-B12 ccfs2 for ext nss */
                hi_reserved0          : 3;   /* B13-15 reserved */
    u_int16_t   hi_reserved2          : 6,    /* B0-5 reserved */
                hi_dualbeacon         : 1,    /* B6   dual beacon */
                hi_dualctsprot        : 1,    /* B7   dual CTS protection */
                hi_stbcbeacon         : 1,    /* B8   STBC beacon */
                hi_lsigtxopprot       : 1,    /* B9   l-sig txop protection full support */
                hi_pcoactive          : 1,    /* B10  pco active */
                hi_pcophase           : 1,    /* B11  pco phase */
                hi_reserved1          : 4;    /* B12-15 reserved */
#endif
    u_int8_t    hi_basicmcsset[16];     /* basic MCS set */
} __packed;

#define IEEE80211_HTINFO_CCFS2_GET_S     0x03
#define IEEE80211_HTINFO_CCFS2_SET_S     0x03

/*
 * 802.11n HT Information IE
 */
struct ieee80211_ie_htinfo {
    u_int8_t                        hi_id;          /* element ID */
    u_int8_t                        hi_len;         /* length in bytes */
    struct ieee80211_ie_htinfo_cmn  hi_ie;
} __packed;

/*
 * Temporary vendor private HT Information IE
 */
struct vendor_ie_htinfo {
    u_int8_t                        hi_id;          /* element ID */
    u_int8_t                        hi_len;         /* length in bytes */
    u_int8_t                        hi_oui[3];
    u_int8_t                        hi_ouitype;
    struct ieee80211_ie_htinfo_cmn  hi_ie;
} __packed;

/* extension channel offset (2 bit signed number) */
enum {
    IEEE80211_HTINFO_EXTOFFSET_NA    = 0,   /* 0  no extension channel is present */
    IEEE80211_HTINFO_EXTOFFSET_ABOVE = 1,   /* +1 extension channel above control channel */
    IEEE80211_HTINFO_EXTOFFSET_UNDEF = 2,   /* -2 undefined */
    IEEE80211_HTINFO_EXTOFFSET_BELOW = 3    /* -1 extension channel below control channel*/
};

/* recommended transmission width set */
enum {
    IEEE80211_HTINFO_TXWIDTH_20,
    IEEE80211_HTINFO_TXWIDTH_2040
};

/* operating flags */
#define IEEE80211_HTINFO_OPMODE_PURE                0x00 /* no protection */
#define IEEE80211_HTINFO_OPMODE_MIXED_PROT_OPT      0x01 /* prot optional (legacy device maybe present) */
#define IEEE80211_HTINFO_OPMODE_MIXED_PROT_40       0x02 /* prot required (20 MHz) */
#define IEEE80211_HTINFO_OPMODE_MIXED_PROT_ALL      0x03 /* prot required (legacy devices present) */
#define IEEE80211_HTINFO_OPMODE_NON_GF_PRESENT      0x04 /* non-greenfield devices present */

#define IEEE80211_HTINFO_OPMODE_MASK                0x03 /* For protection 0x00-0x03 */

/* Non-greenfield STAs present */
enum {
    IEEE80211_HTINFO_NON_GF_NOT_PRESENT,    /* Non-greenfield STAs not present */
    IEEE80211_HTINFO_NON_GF_PRESENT,        /* Non-greenfield STAs present */
};

/* Transmit Burst Limit */
enum {
    IEEE80211_HTINFO_TXBURST_UNLIMITED,     /* Transmit Burst is unlimited */
    IEEE80211_HTINFO_TXBURST_LIMITED,       /* Transmit Burst is limited */
};

/* OBSS Non-HT STAs present */
enum {
    IEEE80211_HTINFO_OBSS_NONHT_NOT_PRESENT, /* OBSS Non-HT STAs not present */
    IEEE80211_HTINFO_OBSS_NONHT_PRESENT,     /* OBSS Non-HT STAs present */
};

/* misc flags */
#define IEEE80211_HTINFO_DUALBEACON               0x0040 /* B6   dual beacon */
#define IEEE80211_HTINFO_DUALCTSPROT              0x0080 /* B7   dual stbc protection */
#define IEEE80211_HTINFO_STBCBEACON               0x0100 /* B8   secondary beacon */
#define IEEE80211_HTINFO_LSIGTXOPPROT             0x0200 /* B9   lsig txop prot full support */
#define IEEE80211_HTINFO_PCOACTIVE                0x0400 /* B10  pco active */
#define IEEE80211_HTINFO_PCOPHASE                 0x0800 /* B11  pco phase */

/* Secondary Channel offset for for 40MHz direct link */
#define IEEE80211_SECONDARY_CHANNEL_ABOVE         1
#define IEEE80211_SECONDARY_CHANNEL_BELOW         3

/* RIFS mode */
enum {
    IEEE80211_HTINFO_RIFSMODE_PROHIBITED,   /* use of rifs prohibited */
    IEEE80211_HTINFO_RIFSMODE_ALLOWED,      /* use of rifs permitted */
};

/*
 * Management information element payloads.
 */
enum {
    IEEE80211_ELEMID_SSID             = 0,
    IEEE80211_ELEMID_RATES            = 1,
    IEEE80211_ELEMID_FHPARMS          = 2,
    IEEE80211_ELEMID_DSPARMS          = 3,
    IEEE80211_ELEMID_CFPARMS          = 4,
    IEEE80211_ELEMID_TIM              = 5,
    IEEE80211_ELEMID_IBSSPARMS        = 6,
    IEEE80211_ELEMID_COUNTRY          = 7,
    IEEE80211_ELEMID_REQINFO          = 10,
    IEEE80211_ELEMID_QBSS_LOAD        = 11,
    IEEE80211_ELEMID_TCLAS            = 14,
    IEEE80211_ELEMID_CHALLENGE        = 16,
    /* 17-31 reserved for challenge text extension */
    IEEE80211_ELEMID_PWRCNSTR         = 32,
    IEEE80211_ELEMID_PWRCAP           = 33,
    IEEE80211_ELEMID_TPCREQ           = 34,
    IEEE80211_ELEMID_TPCREP           = 35,
    IEEE80211_ELEMID_SUPPCHAN         = 36,
    IEEE80211_ELEMID_CHANSWITCHANN    = 37,
    IEEE80211_ELEMID_MEASREQ          = 38,
    IEEE80211_ELEMID_MEASREP          = 39,
    IEEE80211_ELEMID_QUIET            = 40,
    IEEE80211_ELEMID_IBSSDFS          = 41,
    IEEE80211_ELEMID_ERP              = 42,
    IEEE80211_ELEMID_TCLAS_PROCESS    = 44,
    IEEE80211_ELEMID_HTCAP_ANA        = 45,
    IEEE80211_ELEMID_RESERVED_47      = 47,
    IEEE80211_ELEMID_RSN              = 48,
    IEEE80211_ELEMID_XRATES           = 50,
    IEEE80211_ELEMID_AP_CHAN_RPT      = 51,
    IEEE80211_ELEMID_HTCAP_VENDOR     = 51,
    IEEE80211_ELEMID_HTINFO_VENDOR    = 52,
    IEEE80211_ELEMID_MOBILITY_DOMAIN  = 54,
    IEEE80211_ELEMID_FT               = 55,
    IEEE80211_ELEMID_TIMEOUT_INTERVAL = 56,
    IEEE80211_ELEMID_SUPP_OP_CLASS    = 59,
    IEEE80211_ELEMID_EXTCHANSWITCHANN = 60,
    IEEE80211_ELEMID_HTINFO_ANA       = 61,
    IEEE80211_ELEMID_SECCHANOFFSET    = 62,
	IEEE80211_ELEMID_WAPI		      = 68,   /*IE for WAPI*/
    IEEE80211_ELEMID_TIME_ADVERTISEMENT = 69,
    IEEE80211_ELEMID_RRM              = 70,   /* Radio resource measurement */
    IEEE80211_ELEMID_MBSSID           = 71,   /* MBSSID element */
    IEEE80211_ELEMID_2040_COEXT       = 72,
    IEEE80211_ELEMID_2040_INTOL       = 73,
    IEEE80211_ELEMID_OBSS_SCAN        = 74,
    IEEE80211_ELEMID_MMIE             = 76,   /* 802.11w Management MIC IE */
    IEEE80211_ELEMID_MBSSID_NON_TRANS_CAP = 83, /* 802.11ax MBSS IE Non-transmitting VAP */
    IEEE80211_ELEMID_MBSSID_INDEX    = 85,    /* 8021.11ax MBSS IE BSSID Index */
    IEEE80211_ELEMID_FMS_DESCRIPTOR   = 86,   /* 802.11v FMS descriptor IE */
    IEEE80211_ELEMID_FMS_REQUEST      = 87,   /* 802.11v FMS request IE */
    IEEE80211_ELEMID_FMS_RESPONSE     = 88,   /* 802.11v FMS response IE */
    IEEE80211_ELEMID_BSSMAX_IDLE_PERIOD = 90, /* BSS MAX IDLE PERIOD */
    IEEE80211_ELEMID_TFS_REQUEST      = 91,
    IEEE80211_ELEMID_TFS_RESPONSE     = 92,
    IEEE80211_ELEMID_TIM_BCAST_REQUEST  = 94,
    IEEE80211_ELEMID_TIM_BCAST_RESPONSE = 95,
    IEEE80211_ELEMID_INTERWORKING     = 107,
    IEEE80211_ELEMID_QOS_MAP          = 110,
    IEEE80211_ELEMID_XCAPS            = 127,
    IEEE80211_ELEMID_RESERVED_133     = 133,
    IEEE80211_ELEMID_TPC              = 150,
    IEEE80211_ELEMID_CCKM             = 156,
    IEEE80211_ELEMID_VHTCAP           = 191,  /* VHT Capabilities */
    IEEE80211_ELEMID_VHTOP            = 192,  /* VHT Operation */
    IEEE80211_ELEMID_EXT_BSS_LOAD     = 193,  /* Extended BSS Load */
    IEEE80211_ELEMID_WIDE_BAND_CHAN_SWITCH = 194,  /* Wide Band Channel Switch */
    IEEE80211_ELEMID_VHT_TX_PWR_ENVLP = 195,  /* VHT Transmit Power Envelope */
    IEEE80211_ELEMID_CHAN_SWITCH_WRAP = 196,  /* Channel Switch Wrapper */
    IEEE80211_ELEMID_AID              = 197,  /* AID */
    IEEE80211_ELEMID_QUIET_CHANNEL    = 198,  /* Quiet Channel */
    IEEE80211_ELEMID_OP_MODE_NOTIFY   = 199,  /* Operating Mode Notification */
    IEEE80211_ELEMID_REDUCED_NBR_RPT  = 201,  /* Reduced Neighbor Report */
    IEEE80211_ELEMID_VENDOR           = 221,  /* vendor private */
    IEEE80211_ELEMID_EXTN             = 255,
};

#define IEEE80211_MBSSID_SUB_ELEMID	0

/* Element ID extensions
 */
enum {
    IEEE80211_ELEMID_EXT_ESP_ELEMID_EXTENSION = 11,
    IEEE80211_ELEMID_EXT_MAX_CHAN_SWITCH_TIME = 34,
    IEEE80211_ELEMID_EXT_HECAP                = 35,
    IEEE80211_ELEMID_EXT_HEOP                 = 36,
    IEEE80211_ELEMID_EXT_SRP                  = 39,
    IEEE80211_ELEMID_EXT_BSSCOLOR_CHG         = 42,
};

#define IEEE80211_MAX_IE_LEN                255
#define IEEE80211_RSN_IE_LEN                22
/* max time to remain on offchannel */
#define IEEE80211_MAX_REMAIN_ON_CHANNEL     (5000)

#define IEEE80211_CHANSWITCHANN_BYTES        5
#define IEEE80211_CHANSWITCHANN_MODE_QUIET   1
#define IEEE80211_EXTCHANSWITCHANN_BYTES     6
#define IEEE80211_MAXCHANSWITCHTIME_BYTES    6


#define IEEE80211_INVALID_MBSS_BSSIDX        0
#define IEEE80211_DEFAULT_MBSS_SET_IDX       0

struct ieee80211_ath_tim_ie {
    u_int8_t    tim_ie;         /* IEEE80211_ELEMID_TIM */
    u_int8_t    tim_len;
    u_int8_t    tim_count;      /* DTIM count */
    u_int8_t    tim_period;     /* DTIM period */
    u_int8_t    tim_bitctl;     /* bitmap control */
    u_int8_t    tim_bitmap[1];  /* variable-length bitmap */
} __packed;

/* Country IE channel triplet */
struct country_ie_triplet {
    union{
        u_int8_t schan;             /* starting channel */
        u_int8_t regextid;          /* Regulatory Extension Identifier */
    };
    union{
        u_int8_t nchan;             /* number of channels */
        u_int8_t regclass;          /* Regulatory Class */
    };
    union{
        u_int8_t maxtxpwr;          /* tx power  */
        u_int8_t coverageclass;     /* Coverage Class */
    };
}__packed;

struct ieee80211_country_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_COUNTRY */
    u_int8_t    len;
    u_int8_t    cc[3];              /* ISO CC+(I)ndoor/(O)utdoor */
    struct country_ie_triplet triplet[1];
} __packed;

struct ieee80211_fh_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_FHPARMS */
    u_int8_t    len;
    u_int16_t   dwell_time;    // endianess??
    u_int8_t    hop_set;
    u_int8_t    hop_pattern;
    u_int8_t    hop_index;
} __packed;

struct ieee80211_ds_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_DSPARMS */
    u_int8_t    len;
    u_int8_t    current_channel;
} __packed;

struct ieee80211_erp_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_ERP */
    u_int8_t    len;
    u_int8_t    value;
} __packed;

struct ieee80211_ath_quiet_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_QUIET */
    u_int8_t    len;
    u_int8_t    tbttcount;          /* quiet start */
    u_int8_t    period;             /* beacon intervals between quiets*/
    u_int16_t   duration;           /* TUs of each quiet*/
    u_int16_t   offset;             /* TUs of from TBTT of quiet start*/
} __packed;

#if ATH_SUPPORT_IBSS_DFS
struct map_field {
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int8_t       reserved:3,
                       unmeasured:1,
                       radar:1,
                       und_signal:1,
                       ofdem_preamble:1,
                       bss:1;
#else
        u_int8_t       bss:1,
                       ofdem_preamble:1,
                       und_signal:1,
                       radar:1,
                       unmeasured:1,
                       reserved:3;
#endif
}__packed;

#define IEEE80211_MEASUREMENT_REPORT_BASIC_SIZE 12
struct ieee80211_measurement_report_basic_report {
    u_int8_t          channel;
    u_int64_t         measurement_start_time;
    u_int16_t         measurement_duration;
    union {
        struct map_field  map;
        u_int8_t          chmap_in_byte;
    };
}__packed;

struct ieee80211_measurement_report_ie {
    u_int8_t    ie;                         /* IEEE80211_ELEMID_MEASREP */
    u_int8_t    len;
    u_int8_t    measurement_token;
    u_int8_t    measurement_report_mode;
    u_int8_t    measurement_type;
    u_int8_t    pmeasurement_report[IEEE80211_MEASUREMENT_REPORT_BASIC_SIZE];    /* variable, assume basic report */
}__packed;

struct channel_map_field {
    u_int8_t            ch_num;             /* channel number*/
    union {
        struct map_field  ch_map;
        u_int8_t          chmap_in_byte;
    };
}__packed;

struct ieee80211_ibssdfs_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_QUIET */
    u_int8_t    len;
    u_int8_t    owner[IEEE80211_ADDR_LEN];           /*dfs owner */
    u_int8_t    rec_interval;       /* dfs_recover_interval*/
    struct channel_map_field    ch_map_list[IEEE80211_CHAN_MAX+1];    /* channel map filed */ //need to be max
} __packed;
#endif /* ATH_SUPPORT_IBSS_DFS */

struct ieee80211_ath_channelswitch_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_CHANSWITCHANN */
    u_int8_t    len;
    u_int8_t    switchmode;
    u_int8_t    newchannel;
    u_int8_t    tbttcount;
} __packed;

/* channel switch action frame format definition */
struct ieee80211_action_spectrum_channel_switch {
    struct ieee80211_action             csa_header;
    struct ieee80211_ath_channelswitch_ie   csa_element;
}__packed;

/* Vendor Specific  action frame format definition */
struct ieee80211_action_vendor_specific {
    u_int8_t    ia_category;
    u_int8_t    vendor_oui[3];         /* 0x00, 0x03, 0x7f for Atheros */
    /* followed by vendor specific variable length content */
}__packed;

#define IEEE80211_CSA_MODE_STA_TX_ALLOWED        0
#define IEEE80211_CSA_MODE_STA_TX_RESTRICTED     1
#define IEEE80211_CSA_MODE_AUTO                  2

struct ieee80211_extendedchannelswitch_ie {
    u_int8_t    ie;                 /* IEEE80211_ELEMID_EXTCHANSWITCHANN */
    u_int8_t    len;
    u_int8_t    switchmode;
    u_int8_t    newClass;
    u_int8_t    newchannel;
    u_int8_t    tbttcount;
} __packed;

/* Maximum Channel-Switch-Time element format
 *
 * "The Switch Time field is a 3 octet field indicating
 * the maximum time delta between the time the last Beacon
 * frame is transmitted by the AP in the current channel and
 * the expected time of the first Beacon frame in the
 * new channel, expressed in TUs."  -- Quote from ieee80211 standard
 *
 * @ elem_id: Element ID (= IEEE80211_ELEMID_EXTN).
 * @ elem_id_ext: Element ID Extension
 *               (= IEEE80211_ELEMID_EXT_MAX_CHAN_SWITCH_TIME).
 * @ switch_time: Max channel switch time in TU. 24 bit unsigned
 *                integer stored in Little-Endian format.
 */
#define MAX_CHAN_SWITCH_TIME_IE_LEN 4
#define SIZE_OF_MAX_TIME_INT 3
#define ONE_BYTE_MASK 0xFF
#define BITS_IN_A_BYTE 8
struct ieee80211_max_chan_switch_time_ie {
    u_int8_t elem_id;
    u_int8_t elem_len;
    u_int8_t elem_id_ext;
    u_int8_t switch_time[3];
} __packed;

/* Add to NOL information element format (Vendor Specific, following RCSA).
 *
 * RCSA required more information about subchannels affected to
 * be sent to root to actually perform channel change effectively.
 * Hence the following IE structure is introduced.
 *
 * This IE will have:
 * 1). Element ID (IEEE80211_ELEMID_VENDOR) - ELEM ID,
 * 2). Length of the element  - LEN,
 * 1). The bandwidth of each subchannel - BW,
 * 2). The centre frequency of the first subchannel
 *     in channel list - Start Frequency,
 * 3). The bitmap of subchannels that are affected by radar - Bitmap.
 *
 * The Information Element has the following structure:
 *
 * SIZE:(in bits)
 *
 *     8         8        8            16             8
 *  _________ ________ ________ _________________ ___________
 * |         |        |        |                 |           |
 * | ELEM ID |  LEN   |   BW   | Start Frequency |  Bitmap   |
 * |_________|________|________|_________________|___________|
 *                    ________________________________||___________
 *                   |                                             |
 *             ______ ______ ______ ______ ______ ______ ______ ______
 *            | sub  | sub  | sub  | sub  | sub  | sub  | sub  | sub  |
 *            | chan | chan | chan | chan | chan | chan | chan | chan |
 *            |__1___|__2___|__3___|__4___|__5___|__6___|__7___|__8___|
 *  NETWORK
 *   ORDER
 *   BYTE:       0      1      2      3      4      5      6      7
 *
 */
struct vendor_add_to_nol_ie {
	u_int8_t  ie; /* IEEE80211_ELEMID_VENDOR */
	u_int8_t  len;
	u_int8_t  bandwidth;
	u_int16_t startfreq; /* Little Endian */
	u_int8_t  bitmap;
} __packed;

struct ieee80211_tpc_ie {
    u_int8_t    ie;
    u_int8_t    len;
    u_int8_t    pwrlimit;
} __packed;

/*
 * MHDRIE included in TKIP MFP protected management frames
 */
struct ieee80211_ccx_mhdr_ie {
    u_int8_t    mhdr_id;
    u_int8_t    mhdr_len;
    u_int8_t    mhdr_oui[3];
    u_int8_t    mhdr_oui_type;
    u_int8_t    mhdr_fc[2];
    u_int8_t    mhdr_bssid[6];
} __packed;

/*
 * SSID IE
 */
struct ieee80211_ie_ssid {
    u_int8_t    ssid_id;
    u_int8_t    ssid_len;
    u_int8_t    ssid[32];
} __packed;

/*
 * Supported rates
 */
#define IEEE80211_MAX_SUPPORTED_RATES      8

struct ieee80211_ie_rates {
    u_int8_t    rate_id;     /* Element Id */
    u_int8_t    rate_len;    /* IE Length */
    u_int8_t    rate[IEEE80211_MAX_SUPPORTED_RATES];     /* IE Length */
} __packed;

/*
 * Extended rates
 */
#define IEEE80211_MAX_EXTENDED_RATES     256

struct ieee80211_ie_xrates {
    u_int8_t    xrate_id;     /* Element Id */
    u_int8_t    xrate_len;    /* IE Length */
    u_int8_t    xrate[IEEE80211_MAX_EXTENDED_RATES];   /* IE Length */
} __packed;

/*
 * 802.11h Channels supported information element
 */
struct ieee80211_ie_supp_channels {
    u_int8_t    supp_chan_id;     /* Element Id IEEE80211_ELEMID_SUPPCHAN */
    u_int8_t    supp_chan_len;    /* IE Length */
    u_int8_t    first_channel;   /* Channel number of first channel in band */
    u_int8_t    nr_channels;     /* Number of contiguous channels in band */
} __packed;

/*
 * WPS SSID list information element (maximally sized).
 */
struct ieee80211_ie_ssidl {
    u_int8_t    ssidl_id;     /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    ssidl_len;    /* length in bytes */
    u_int8_t    ssidl_oui[3]; /* 0x00, 0x50, 0xf2 */
    u_int8_t    ssidl_type;   /* OUI type */
    u_int8_t    ssidl_prim_cap; /* Primary capabilities */
    u_int8_t    ssidl_count;  /* # of secondary SSIDs */
    u_int16_t   ssidl_value[248];
} __packed;

#if _BYTE_ORDER == _BIG_ENDIAN
struct ieee80211_sec_ssid_cap {
    u_int32_t       reserved0   :1,
                    akmlist     :6,
                    reserved1   :4,
                    reeserved2  :2,
                    ucipher     :15,
                    mcipher     :4;
};
#else
struct ieee80211_sec_ssid_cap {
    u_int32_t       mcipher     :4,
                    ucipher     :15,
                    reserved2   :2,
                    reserved1   :4,
                    akmlist     :6,
                    reserved0   :1;
};
#endif

struct ieee80211_ie_qbssload {
    u_int8_t     elem_id;                /* IEEE80211_ELEMID_QBSS_LOAD */
    u_int8_t     length;                 /* length in bytes */
    u_int16_t    station_count;          /* number of station associated */
    u_int8_t     channel_utilization;    /* channel busy time in 0-255 scale */
    u_int16_t    aac;                    /* available admission capacity */
} __packed;

#define SEC_SSID_HEADER_LEN  6
#define SSIDL_IE_HEADER_LEN  6

struct ieee80211_sec_ssid {
    u_int8_t                        sec_ext_cap;
    struct ieee80211_sec_ssid_cap   sec_cap;
    u_int8_t                        sec_ssid_len;
    u_int8_t                        sec_ssid[32];
} __packed;

struct ieee80211_build_version_ie {
    u_int8_t    build_variant[3];
    u_int8_t    sw_build_version;
    u_int8_t    sw_build_maj_ver;
    u_int8_t    sw_build_min_ver;
    u_int8_t    sw_build_rel_variant;
    u_int8_t    sw_build_rel_num;
    u_int32_t   chip_vendorid;  /* For AHB devices, vendorid=0x0
                                   Little Endian format*/
    u_int32_t   chip_devid; /* Little Endian Format*/
} __packed;

/*Values of the SW_BUILD macros in this file are default values.
  Build/Integration team shall modify the values according to the meta
  build information before they build the driver */

#define SW_BUILD_VARIANT          "ILQ"
#define SW_BUILD_VERSION             3
#define SW_BUILD_MAJ_VER             2
#define SW_BUILD_MIN_VER             9
#define SW_BUILD_REL_VARIANT        'r'
#define SW_BUILD_REL_NUM             1
#define SW_BUILD_VARIANT_LEN         3

/* Definitions of SSIDL IE */
enum {
    CAP_MCIPHER_ENUM_NONE = 0,
    CAP_MCIPHER_ENUM_WEP40,
    CAP_MCIPHER_ENUM_WEP104,
    CAP_MCIPHER_ENUM_TKIP,
    CAP_MCIPHER_ENUM_CCMP,
    CAP_MCIPHER_ENUM_CKIP_CMIC,
    CAP_MCIPHER_ENUM_CKIP,
    CAP_MCIPHER_ENUM_CMIC
};


#define CAP_UCIPHER_BIT_NONE           0x0001
#define CAP_UCIPHER_BIT_WEP40          0x0002
#define CAP_UCIPHER_BIT_WEP104         0x0004
#define CAP_UCIPHER_BIT_TKIP           0x0008
#define CAP_UCIPHER_BIT_CCMP           0x0010
#define CAP_UCIPHER_BIT_CKIP_CMIC      0x0020
#define CAP_UCIPHER_BIT_CKIP           0x0040
#define CAP_UCIPHER_BIT_CMIC           0x0080
#define CAP_UCIPHER_BIT_WPA2_WEP40     0x0100
#define CAP_UCIPHER_BIT_WPA2_WEP104    0x0200
#define CAP_UCIPHER_BIT_WPA2_TKIP      0x0400
#define CAP_UCIPHER_BIT_WPA2_CCMP      0x0800
#define CAP_UCIPHER_BIT_WPA2_CKIP_CMIC 0x1000
#define CAP_UCIPHER_BIT_WPA2_CKIP      0x2000
#define CAP_UCIPHER_BIT_WPA2_CMIC      0x4000

#define CAP_AKM_BIT_WPA1_1X            0x01
#define CAP_AKM_BIT_WPA1_PSK           0x02
#define CAP_AKM_BIT_WPA2_1X            0x04
#define CAP_AKM_BIT_WPA2_PSK           0x08
#define CAP_AKM_BIT_WPA1_CCKM          0x10
#define CAP_AKM_BIT_WPA2_CCKM          0x20

#define IEEE80211_CHALLENGE_LEN         128

#define IEEE80211_SUPPCHAN_LEN          26

#define IEEE80211_RATE_BASIC            0x80
#define IEEE80211_RATE_VAL              0x7f

/* EPR information element flags */
#define IEEE80211_ERP_NON_ERP_PRESENT   0x01
#define IEEE80211_ERP_USE_PROTECTION    0x02
#define IEEE80211_ERP_LONG_PREAMBLE     0x04

/* Atheros private advanced capabilities info */
#define ATHEROS_CAP_TURBO_PRIME         0x01
#define ATHEROS_CAP_COMPRESSION         0x02
#define ATHEROS_CAP_FAST_FRAME          0x04
/* bits 3-6 reserved */
#define ATHEROS_CAP_BOOST               0x80

#define ATH_OUI                     0x7f0300    /* Atheros OUI */
#define ATH_OUI_TYPE                    0x01
#define ATH_OUI_SUBTYPE                 0x01
#define ATH_OUI_VERSION                 0x00
#define ATH_OUI_TYPE_XR                 0x03
#define ATH_OUI_VER_XR                  0x01
#define ATH_OUI_EXTCAP_TYPE             0x04    /* Atheros Extended Cap Type */
#define ATH_OUI_EXTCAP_SUBTYPE          0x01    /* Atheros Extended Cap Sub-type */
#define ATH_OUI_EXTCAP_VERSION          0x00    /* Atheros Extended Cap Version */
#define ATH_OUI_BW_NSS_MAP_TYPE         0x05    /* QCA Bandwidth NSS Mapping Type */
#define ATH_OUI_BW_NSS_MAP_SUBTYPE      0x01    /* QCA Bandwidth NSS Mapping sub-Type */
#define ATH_OUI_BW_NSS_VERSION          0x00    /* QCA Bandwidth NSS Mapping Version */

#define QCA_OUI                     0xf0fd8c   /* QCA OUI (in little endian) */
#define QCA_OUI_BYTE_MASK           0xff
#define QCA_OUI_ONE_BYTE_SHIFT       8
#define QCA_OUI_TWO_BYTE_SHIFT      16
#define QCA_OUI_LEN                  6
#define IE_LEN_ID_LEN                2 /* Length (ID and Length) of IE*/

#define DDT_OUI                     0x181000
#define DEDICATE_OUI_CAP_TYPE           0x02

/* Whole Home Coverage vendor specific IEs */
#define QCA_OUI_WHC_TYPE                0x00
#define QCA_OUI_WHC_REPT_TYPE           0x01

/* QCN IE */
#define QCN_OUI_TYPE                    0x01

/* apriori Next-channel vendor specific IE */
#define QCA_OUI_NC_TYPE                 0x02
/* Extender vendor specific IE */
#define QCA_OUI_EXTENDER_TYPE           0x03
/* Generic vendor specific IE */
#define QCA_OUI_GENERIC_TYPE_1          0x04/* WARNING: Please do not define
                                               new type for VIE. Please use this
                                               type and use the subtype for
                                               future use until subtype reaches
                                               255,then define GENERIC_TYPE_2
                                               as 5 and proceed.*/
#define QCA_OUI_BUILD_INFO_SUBTYPE      0x00 /* This has Radio and
                                                SW build info. */
#define QCA_OUI_BUILD_INFO_VERSION      0x00 /* This has version of Radio and SW
                                                build info .*/

/* Fields and bit mask for the Whole Home Coverage AP Info Sub-type */
#define QCA_OUI_WHC_AP_INFO_SUBTYPE     0x00
#define QCA_OUI_WHC_AP_INFO_VERSION     0x01
#define QCA_OUI_WHC_AP_INFO_CAP_WDS     0x01
#define QCA_OUI_WHC_AP_INFO_CAP_SON     0x02

#define QCA_OUI_WHC_REPT_INFO_SUBTYPE   0x00
#define QCA_OUI_WHC_REPT_INFO_VERSION   0x00

/* Vendor specific IEs for channel change in repeater during DFS */
#define QCA_OUI_NC_SUBTYPE             0x00
#define QCA_OUI_NC_VERSION             0x00
#define QCA_UNHANDLED_SUB_ELEM_ID       255

#define WPA_OUI                     0xf25000
#define WPA_OUI_TYPE                    0x01
#define WPA_VERSION                        1    /* current supported version */

#define WSC_OUI                   0x0050f204

#define WPA_CSE_NULL                    0x00
#define WPA_CSE_WEP40                   0x01
#define WPA_CSE_TKIP                    0x02
#define WPA_CSE_CCMP                    0x04
#define WPA_CSE_WEP104                  0x05

#define WPA_ASE_NONE                    0x00
#define WPA_ASE_8021X_UNSPEC            0x01
#define WPA_ASE_8021X_PSK               0x02
#define WPA_ASE_FT_IEEE8021X            0x20
#define WPA_ASE_FT_PSK                  0x40
#define WPA_ASE_SHA256_IEEE8021X        0x80
#define WPA_ASE_SHA256_PSK              0x100
#define WPA_ASE_WPS                     0x200


#define RSN_OUI                     0xac0f00
#define RSN_VERSION                        1    /* current supported version */

#define RSN_CSE_NULL                    0x00
#define RSN_CSE_WEP40                   0x01
#define RSN_CSE_TKIP                    0x02
#define RSN_CSE_WRAP                    0x03
#define RSN_CSE_CCMP                    0x04
#define RSN_CSE_WEP104                  0x05
#define RSN_CSE_AES_CMAC                0x06
#define RSN_CSE_GCMP_128                0x08
#define RSN_CSE_GCMP_256                0x09
#define RSN_CSE_CCMP_256                0x0A
#define RSN_CSE_BIP_GMAC_128            0x0B
#define RSN_CSE_BIP_GMAC_256            0x0C
#define RSN_CSE_BIP_CMAC_256            0x0D

#define RSN_ASE_NONE                    0x00
#define RSN_ASE_8021X_UNSPEC            0x01
#define RSN_ASE_8021X_PSK               0x02
#define RSN_ASE_FT_IEEE8021X            0x20
#define RSN_ASE_FT_PSK                  0x40
#define RSN_ASE_SHA256_IEEE8021X        0x80
#define RSN_ASE_SHA256_PSK              0x100
#define RSN_ASE_WPS                     0x200

#define AKM_SUITE_TYPE_IEEE8021X        0x01
#define AKM_SUITE_TYPE_PSK              0x02
#define AKM_SUITE_TYPE_FT_IEEE8021X     0x03
#define AKM_SUITE_TYPE_FT_PSK           0x04
#define AKM_SUITE_TYPE_SHA256_IEEE8021X 0x05
#define AKM_SUITE_TYPE_SHA256_PSK       0x06

#define RSN_CAP_PREAUTH                 0x01
#define RSN_CAP_MFP_REQUIRED            0x40
#define RSN_CAP_MFP_ENABLED             0x80

#define CCKM_OUI                    0x964000
#define CCKM_ASE_UNSPEC                    0
#define WPA_CCKM_AKM              0x00964000
#define RSN_CCKM_AKM              0x00964000

#define WME_OUI                     0xf25000
#define WME_OUI_TYPE                    0x02
#define WME_INFO_OUI_SUBTYPE            0x00
#define WME_PARAM_OUI_SUBTYPE           0x01
#define WME_TSPEC_OUI_SUBTYPE           0x02

#define MBO_OUI                     0x9a6f50
#define MBO_OUI_TYPE                    0x16

#define VHT_INTEROP_OUI                 0x00904c
#define VHT_INTEROP_TYPE                0x04
#define VHT_INTEROP_OUI_SUBTYPE         0x08
#define VHT_INTEROP_OUI_SUBTYPE_VENDORSPEC     0x18

#define WME_PARAM_OUI_VERSION              1
#define WME_TSPEC_OUI_VERSION              1
#define WME_VERSION                        1

/* WME stream classes */
#define WME_AC_BE                          0    /* best effort */
#define WME_AC_BK                          1    /* background */
#define WME_AC_VI                          2    /* video */
#define WME_AC_VO                          3    /* voice */

/* MUEDCA Access Categories */
#define MUEDCA_AC_BE                       WME_AC_BE    /* best effort */
#define MUEDCA_AC_BK                       WME_AC_BK    /* background */
#define MUEDCA_AC_VI                       WME_AC_VI    /* video */
#define MUEDCA_AC_VO                       WME_AC_VO    /* voice */

#define WPS_OUI                     0xf25000    /* Microsoft OUI */
#define WPS_OUI_TYPE                    0x05    /* Wireless Provisioning Services */
#define SSIDL_OUI_TYPE          WPS_OUI_TYPE

/* WCN IE */
#define WCN_OUI                     0xf25000    /* Microsoft OUI */
#define WCN_OUI_TYPE                    0x04    /* WCN */

/* Atheros htoui  for ht vender ie; use Epigram OUI for compatibility with pre11n devices */
#define ATH_HTOUI                   0x00904c

#define SFA_OUI                     0x964000
#define SFA_OUI_TYPE                    0x14
#define SFA_IE_CAP_MFP                  0x01
#define SFA_IE_CAP_DIAG_CHANNEL         0x02
#define SFA_IE_CAP_LOCATION_SVCS        0x04
#define SFA_IE_CAP_EXP_BANDWIDTH        0x08

#define WPA_OUI_BYTES       0x00, 0x50, 0xf2
#define RSN_OUI_BYTES       0x00, 0x0f, 0xac
#define WME_OUI_BYTES       0x00, 0x50, 0xf2
#define ATH_OUI_BYTES       0x00, 0x03, 0x7f
#define SFA_OUI_BYTES       0x00, 0x40, 0x96
#define CCKM_OUI_BYTES      0x00, 0x40, 0x96
#define WPA_SEL(x)          (((x)<<24)|WPA_OUI)
#define RSN_SEL(x)          (((x)<<24)|RSN_OUI)
#define SFA_SEL(x)          (((x)<<24)|SFA_OUI)
#define CCKM_SEL(x)         (((x)<<24)|CCKM_OUI)

#define VHT_INTEROP_OUI_BYTES  0x00, 0x90, 0x4c

#define IEEE80211_RV(v)     ((v) & IEEE80211_RATE_VAL)
#define IEEE80211_N(a)      (sizeof(a) / sizeof(a[0]))
/*
 * AUTH management packets
 *
 *  octet algo[2]
 *  octet seq[2]
 *  octet status[2]
 *  octet chal.id
 *  octet chal.length
 *  octet chal.text[253]
 */

typedef u_int8_t *ieee80211_mgt_auth_t;

#define IEEE80211_AUTH_ALGORITHM(auth) \
    ((auth)[0] | ((auth)[1] << 8))
#define IEEE80211_AUTH_TRANSACTION(auth) \
    ((auth)[2] | ((auth)[3] << 8))
#define IEEE80211_AUTH_STATUS(auth) \
    ((auth)[4] | ((auth)[5] << 8))

#define IEEE80211_AUTH_ALG_OPEN         0x0000
#define IEEE80211_AUTH_ALG_SHARED       0x0001
#define IEEE80211_AUTH_ALG_FT           0x0002
#define IEEE80211_AUTH_ALG_SAE          0x0003
#define IEEE80211_AUTH_ALG_FILS_SK      0x0004
#define IEEE80211_AUTH_ALG_FILS_SK_PFS  0x0005
#define IEEE80211_AUTH_ALG_FILS_PK      0x0006
#define IEEE80211_AUTH_ALG_LEAP         0x0080

enum {
    IEEE80211_AUTH_OPEN_REQUEST     = 1,
    IEEE80211_AUTH_OPEN_RESPONSE    = 2,
};

enum {
    IEEE80211_AUTH_SHARED_REQUEST   = 1,
    IEEE80211_AUTH_SHARED_CHALLENGE = 2,
    IEEE80211_AUTH_SHARED_RESPONSE  = 3,
    IEEE80211_AUTH_SHARED_PASS      = 4,
};

enum {
    IEEE80211_AUTH_FT_REQUEST       = 1,
    IEEE80211_AUTH_FT_RESPONSE      = 2,
};

/*
 * external auth mode support
 */
enum {
    IEEE80211_EXTERNAL_AUTH_START   = 0,
    IEEE80211_EXTERNAL_AUTH_ABORT   = 1,
};

/*
 * Reason codes
 *
 * Unlisted codes are reserved
 */

enum {
    IEEE80211_REASON_UNSPECIFIED        = 1,
    IEEE80211_REASON_AUTH_EXPIRE        = 2,
    IEEE80211_REASON_AUTH_LEAVE         = 3,
    IEEE80211_REASON_ASSOC_EXPIRE       = 4,
    IEEE80211_REASON_ASSOC_TOOMANY      = 5,
    IEEE80211_REASON_NOT_AUTHED         = 6,
    IEEE80211_REASON_NOT_ASSOCED        = 7,
    IEEE80211_REASON_ASSOC_LEAVE        = 8,
    IEEE80211_REASON_ASSOC_NOT_AUTHED   = 9,

    IEEE80211_REASON_ASSOC_BSSTM        = 12,
    IEEE80211_REASON_IE_INVALID         = 13,
    IEEE80211_REASON_MIC_FAILURE        = 14,
    IEEE80211_REASON_KICK_OUT           = 15,
    IEEE80211_REASON_INVALID_GROUP_CIPHER = 18,
    IEEE80211_REASON_INVALID_PAIRWISE_CIPHER = 19,
    IEEE80211_REASON_INVALID_AKMP         = 20,
    IEEE80211_REASON_UNSUPPORTED_RSNE_VER = 21,
    IEEE80211_REASON_RSN_REQUIRED         = 22,

    IEEE80211_REASON_QOS                = 32,
    IEEE80211_REASON_QOS_BANDWITDH      = 33,
    IEEE80211_REASON_DISASSOC_LOW_ACK  = 34,
    IEEE80211_REASON_QOS_TXOP           = 35,
    IEEE80211_REASON_QOS_LEAVE          = 36,
    IEEE80211_REASON_QOS_DECLINED       = 37,
    IEEE80211_REASON_QOS_SETUP_REQUIRED = 38,
    IEEE80211_REASON_QOS_TIMEOUT        = 39,
    IEEE80211_REASON_QOS_CIPHER         = 45,

    IEEE80211_STATUS_SUCCESS            = 0,
    IEEE80211_STATUS_UNSPECIFIED        = 1,
    IEEE80211_STATUS_CAPINFO            = 10,
    IEEE80211_STATUS_NOT_ASSOCED        = 11,
    IEEE80211_STATUS_OTHER              = 12,
    IEEE80211_STATUS_ALG                = 13,
    IEEE80211_STATUS_SEQUENCE           = 14,
    IEEE80211_STATUS_CHALLENGE          = 15,
    IEEE80211_STATUS_TIMEOUT            = 16,
    IEEE80211_STATUS_TOOMANY            = 17,
    IEEE80211_STATUS_BASIC_RATE         = 18,
    IEEE80211_STATUS_SP_REQUIRED        = 19,
    IEEE80211_STATUS_PBCC_REQUIRED      = 20,
    IEEE80211_STATUS_CA_REQUIRED        = 21,
    IEEE80211_STATUS_TOO_MANY_STATIONS  = 22,
    IEEE80211_STATUS_RATES              = 23,
    IEEE80211_STATUS_SHORTSLOT_REQUIRED = 25,
    IEEE80211_STATUS_DSSSOFDM_REQUIRED  = 26,
    IEEE80211_STATUS_NO_HT              = 27,
    IEEE80211_STATUS_REJECT_TEMP        = 30,
    IEEE80211_STATUS_MFP_VIOLATION      = 31,
    IEEE80211_STATUS_POOR_CHAN_CONDITION = 34,
    IEEE80211_STATUS_REFUSED            = 37,
    IEEE80211_STATUS_INVALID_PARAM      = 38,
    IEEE80211_STATUS_INVALID_ELEMENT    = 40,
    IEEE80211_STATUS_INVALID_GROUP_CIPHER = 41,
    IEEE80211_STATUS_INVALID_PAIRWISE_CIPHER = 42,
    IEEE80211_STATUS_INVALID_AKMP         = 43,
    IEEE80211_STATUS_UNSUPPORTED_RSNE_VER = 44,
    IEEE80211_STATUS_INVALID_RSNE_CAP     = 45,

    IEEE80211_STATUS_DLS_NOT_ALLOWED    = 48,
    IEEE80211_STATUS_INVALID_PMKID         = 53,
    IEEE80211_STATUS_ANTI_CLOGGING_TOKEN_REQ = 76,
    IEEE80211_STATUS_FINITE_CYCLIC_GROUP_NOT_SUPPORTED = 77,
    IEEE80211_STATUS_NO_VHT             = 104,
    IEEE80211_STATUS_RADAR_DETECTED     = 105,
};

/* private IEEE80211_STATUS */
#define    IEEE80211_STATUS_CANCEL             -1
#define    IEEE80211_STATUS_INVALID_IE         -2
#define    IEEE80211_STATUS_INVALID_CHANNEL    -3

/* private IEEE80211_REASON */
/* Only clean up local association state, don't send disassociation frame OTA */
#define    IEEE80211_REASON_LOCAL              252

#define IEEE80211_WEP_KEYLEN        5   /* 40bit */
#define IEEE80211_WEP_IVLEN         3   /* 24bit */
#define IEEE80211_WEP_KIDLEN        1   /* 1 octet */
#define IEEE80211_WEP_CRCLEN        4   /* CRC-32 */
#define IEEE80211_WEP_NKID          4   /* number of key ids */

/*
 * 802.11i defines an extended IV for use with non-WEP ciphers.
 * When the EXTIV bit is set in the key id byte an additional
 * 4 bytes immediately follow the IV for TKIP.  For CCMP the
 * EXTIV bit is likewise set but the 8 bytes represent the
 * CCMP header rather than IV+extended-IV.
 */
#define IEEE80211_WEP_EXTIV      0x20
#define IEEE80211_WEP_EXTIVLEN      4   /* extended IV length */
#define IEEE80211_WEP_MICLEN        8   /* trailing MIC */

#define IEEE80211_CRC_LEN           4

#define IEEE80211_8021Q_HEADER_LEN  4
/*
 * Maximum acceptable MTU is:
 *  IEEE80211_MAX_LEN - WEP overhead - CRC -
 *      QoS overhead - RSN/WPA overhead
 * Min is arbitrarily chosen > IEEE80211_MIN_LEN.  The default
 * mtu is Ethernet-compatible; it's set by ether_ifattach.
 */
#define IEEE80211_MTU_MAX       2290
#define IEEE80211_MTU_MIN       32

/* Rather than using this default value, customer platforms can provide a custom value for this constant.
  Coustomer platform will use the different define value by themself */
#ifndef IEEE80211_MAX_MPDU_LEN
#define IEEE80211_MAX_MPDU_LEN      (3840 + IEEE80211_CRC_LEN + \
    (IEEE80211_WEP_IVLEN + IEEE80211_WEP_KIDLEN + IEEE80211_WEP_CRCLEN))
#endif
#define IEEE80211_ACK_LEN \
    (sizeof(struct ieee80211_frame_ack) + IEEE80211_CRC_LEN)
#define IEEE80211_MIN_LEN \
    (sizeof(struct ieee80211_frame_min) + IEEE80211_CRC_LEN)

/* An 802.11 data frame can be one of three types:
1. An unaggregated frame: The maximum length of an unaggregated data frame is 2324 bytes + headers.
2. A data frame that is part of an AMPDU: The maximum length of an AMPDU may be upto 65535 bytes, but data frame is limited to 2324 bytes + header.
3. An AMSDU: The maximum length of an AMSDU is eihther 3839 or 7095 bytes.
The maximum frame length supported by hardware is 4095 bytes.
A length of 3839 bytes is chosen here to support unaggregated data frames, any size AMPDUs and 3839 byte AMSDUs.
*/
#define IEEE80211N_MAX_FRAMELEN  3839
#define IEEE80211N_MAX_LEN (IEEE80211N_MAX_FRAMELEN + IEEE80211_CRC_LEN + \
    (IEEE80211_WEP_IVLEN + IEEE80211_WEP_KIDLEN + IEEE80211_WEP_CRCLEN))

#define IEEE80211_TX_CHAINMASK_MIN  1
#define IEEE80211_RX_CHAINMASK_MIN  1
#define IEE80211_TX_MAX_CHAINMASK(ic) ((1 << ic->ic_num_tx_chain)-1)
#define IEE80211_RX_MAX_CHAINMASK(ic) ((1 << ic->ic_num_rx_chain)-1)

#if QCA_SUPPORT_5SS_TO_8SS
#define IEEE80211_TX_CHAINMASK_MAX  (0xff)
#define IEEE80211_RX_CHAINMASK_MAX  (0xff)
#define IEEE80211_MAX_TX_CHAINS 8
#else
#define IEEE80211_TX_CHAINMASK_MAX  7
#define IEEE80211_RX_CHAINMASK_MAX  7
#define IEEE80211_MAX_TX_CHAINS 3
#endif
#define MAX_HE_NSS              8

#define IEEE80211_MAX_11N_CHAINS        4
#define IEEE80211_MAX_11N_STREAMS       IEEE80211_MAX_11N_CHAINS
#define IEEE80211_MAX_PRE11AC_CHAINS    IEEE80211_MAX_11N_CHAINS
#define IEEE80211_MAX_PRE11AC_STREAMS   IEEE80211_MAX_PRE11AC_CHAINS

/*
 * The 802.11 spec says at most 2007 stations may be
 * associated at once.  For most AP's this is way more
 * than is feasible so we use a default of 128.  This
 * number may be overridden by the driver and/or by
 * user configuration.
 */
#define IEEE80211_MAX_AID       2007
#define IEEE80211_33_AID        33
#define IEEE80211_128_AID       128
#define IEEE80211_200_AID       200
#define IEEE80211_512_AID       512
#define IEEE80211_AID(b)    ((b) &~ 0xc000)

/*
 * RTS frame length parameters.  The default is specified in
 * the 802.11 spec.  The max may be wrong for jumbo frames.
 */
#define IEEE80211_RTS_DEFAULT       512
#define IEEE80211_RTS_MIN           0
#define IEEE80211_RTS_MAX           2347

/*
 * Fragmentation limits
 */
#define IEEE80211_FRAGMT_THRESHOLD_MIN        256      /* min frag threshold */
#define IEEE80211_FRAGMT_THRESHOLD_MAX       2346      /* max frag threshold */

/*
 * Regulatory extention identifier for country IE.
 */
#define IEEE80211_REG_EXT_ID        201

/*
 * overlapping BSS
 */
#define IEEE80211_OBSS_SCAN_PASSIVE_DWELL_DEF  20
#define IEEE80211_OBSS_SCAN_ACTIVE_DWELL_DEF   10
#define IEEE80211_OBSS_SCAN_INTERVAL_DEF       300
#define IEEE80211_OBSS_SCAN_PASSIVE_TOTAL_DEF  200
#define IEEE80211_OBSS_SCAN_ACTIVE_TOTAL_DEF   20
#define IEEE80211_OBSS_SCAN_THRESH_DEF   25
#define IEEE80211_OBSS_SCAN_DELAY_DEF   5

/*
 * overlapping BSS scan ie
 */
struct ieee80211_ie_obss_scan {
        u_int8_t elem_id;
        u_int8_t elem_len;
        u_int16_t scan_passive_dwell;
        u_int16_t scan_active_dwell;
        u_int16_t scan_interval;
        u_int16_t scan_passive_total;
        u_int16_t scan_active_total;
        u_int16_t scan_delay;
        u_int16_t scan_thresh;
} __packed;

/*
 * overlapping spatial reuse
 */
#define IEEE80211_SRP_SR_CONTROL                        0x3

/* Self OBSS SR Defaults */
#define IEEE80211_SRP_NON_SRG_SELF_OBSS_PD_THRESHOLD    0x80
#define IEEE80211_SRP_NON_SRG_SELF_OBSS_PD_ENABLE       0

/* BSS Non-SRG OBSS SR Deaults */
#define IEEE80211_SRP_NON_SRG_OBSS_PD_MAX_OFFSET        0

/* BSS SRG OBSS SR Defaults */
#define IEEE80211_SRP_SRG_OBSS_PD_MIN_OFFSET            0
#define IEEE80211_SRP_SRG_OBSS_PD_MAX_OFFSET            0
#define IEEE80211_SRP_SRG_BSS_COLOR_BITMAP              0
#define IEEE80211_SRP_SRG_PARTIAL_BSSID_BITMAP          0

/* Spatial Reuse Control Field bitmasks */
#define IEEE80211_SRP_DISALLOWED_MASK                   0x01
#define IEEE80211_SRP_NON_SRG_OBSS_PD_SR_DISALLOWED_MASK 0x02
#define IEEE80211_SRP_SRG_INFO_PRESENT_MASK             0x08
#define IEEE80211_SRP_HESIGA_SR_VALUE15_ALLOWED_MASK    0x10

/* Misc SR Defaults */
#define IEEE80211_ALLOW_MON_VAPS_IN_SR                  0
#define IEEE80211_SR_ENABLE_PER_AC                      0x0

#if OBSS_PD
union ieee80211_sr_ctrl_field {
    struct {
#if (_BYTE_ORDER == _BIG_ENDIAN)
        u_int8_t rsvd                            : 3;
        u_int8_t HESIGA_sp_reuse_value15_allowed : 1;
        u_int8_t srg_information_present         : 1;
        u_int8_t non_srg_offset_present          : 1;
        u_int8_t non_srg_obss_pd_sr_disallowed   : 1;
        u_int8_t srp_disallow                    : 1;
#else
        u_int8_t srp_disallow                    : 1;
        u_int8_t non_srg_obss_pd_sr_disallowed   : 1;
        u_int8_t non_srg_offset_present          : 1;
        u_int8_t srg_information_present         : 1;
        u_int8_t HESIGA_sp_reuse_value15_allowed : 1;
        u_int8_t rsvd                            : 3;
#endif // if (_BYTE_ORDER == _BIG_ENDIAN)
    };

    u_int8_t value;
} __packed;

/*
 * overlapping spatial reuse ie
 */
struct ieee80211_ie_spatial_reuse {
    u_int8_t elem_id;
    u_int8_t elem_len;
    u_int8_t ext_id;
    /* sr_control */
    union ieee80211_sr_ctrl_field sr_ctrl;
    u_int8_t non_srg_obss_pd_max_offset;
    u_int8_t srg_obss_pd_min_offset;
    u_int8_t srg_obss_pd_max_offset;
    u_int8_t srg_obss_color_bitmap[8];
    u_int8_t srg_obss_color_partial_bitmap[8];
} __packed;

/* Below structures are related to OBSS_PD_SPATIAL Reuse */
struct ieee80211_spatial_reuse_handle {
    /** Minimum OBSS level to use */
    uint8_t obss_min;
    /** Maximum OBSS level to use */
    uint8_t obss_max;
};
#endif //OBSS_PD

/*
 * Extended capability ie
 */
struct ieee80211_ie_ext_cap {
        u_int8_t elem_id;
        u_int8_t elem_len;
        u_int32_t ext_capflags;
        u_int32_t ext_capflags2;
        u_int8_t ext_capflags3;
        u_int8_t ext_capflags4;
        u_int8_t ext_capflags5;
} __packed;

/* Extended capability IE flags */
#define IEEE80211_EXTCAPIE_2040COEXTMGMT        0x00000001
#define IEEE80211_EXTCAPIE_ECSA                 0x00000004
#define IEEE80211_EXTCAPIE_TFS                  0x00010000
#define IEEE80211_EXTCAPIE_FMS                  0x00000800
#define IEEE80211_EXTCAPIE_PROXYARP             0x00001000
#define IEEE80211_EXTCAPIE_CIVLOC               0x00004000
#define IEEE80211_EXTCAPIE_GEOLOC               0x00008000
#define IEEE80211_EXTCAPIE_WNMSLEEPMODE         0x00020000
#define IEEE80211_EXTCAPIE_TIMBROADCAST         0x00040000
#define IEEE80211_EXTCAPIE_BSSTRANSITION        0x00080000
#define IEEE80211_EXTCAPIE_MBSSID               0x00400000
#define IEEE80211_EXTCAPIE_PEER_UAPSD_BUF_STA   0x10000000
/* 2nd Extended capability IE flags bit32-bit63*/
#define IEEE80211_EXTCAPIE_QOS_MAP          0x00000001 /* bit-32 QoS Map Support */
#define IEEE80211_EXTCAPIE_OP_MODE_NOTIFY   0x40000000 /* bit-62 Operating Mode notification */
/* 3rd Extended capability IE flags bit64-bit71*/
#define IEEE80211_EXTCAPIE_FTM_RES          0x40 /* bit-70 RTT FTM responder bits*/
#define IEEE80211_EXTCAPIE_FTM_INIT         0x80 /* bit-71 RTT FTM initiator bits*/
/* 4th Extended capability IE flags bit72-bit79*/
#define IEEE80211_EXTCAPIE_FILS             0x01 /* bit-72 FILS capability */
#define IEEE80211_EXTCAPIE_TWT_REQ          0x20 /* bit-77 TWT Requester support */
#define IEEE80211_EXTCAPIE_TWT_RESP         0x40 /* bit-78 TWT Responder support */
#define IEEE80211_EXTCAPIE_OBSS_NBW_RU      0x80 /* bit-79 OBSS Narrow Bandwidth RU in OFDMA Tolerance Support */
/* Extended capability IE flags bits 80-87 */
#define IEEE80211_EXTCAPIE_COMPL_LIST_MBSS  0x01 /* bit-80 Complete list of NonTxBSSID profiles */
#define IEEE80211_EXTCAPIE_SAE_PWID        0x02 /* bit-81 SAE PWD id used */
#define IEEE80211_EXTCAPIE_SAE_PWID_ALL    0x04 /* bit-82 SAE PWD id used exclusively*/

struct ieee80211_ie_qos_map_set {
        u_int8_t elem_id;
        u_int8_t elem_len;
        u_int8_t qos_map_set[0];
} __packed;

/*
 * 20/40 BSS coexistence ie
 */
struct ieee80211_ie_bss_coex {
        u_int8_t elem_id;
        u_int8_t elem_len;
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int8_t reserved1          : 1,
                 reserved2          : 1,
                 reserved3          : 1,
                 obss_exempt_grant  : 1,
                 obss_exempt_req    : 1,
                 ht20_width_req       : 1,
                 ht40_intolerant      : 1,
                 inf_request        : 1;
#else
        u_int8_t inf_request        : 1,
                 ht40_intolerant      : 1,
                 ht20_width_req       : 1,
                 obss_exempt_req    : 1,
                 obss_exempt_grant  : 1,
                 reserved3          : 1,
                 reserved2          : 1,
                 reserved1          : 1;
#endif
} __packed;

/*
 * 20/40 BSS intolerant channel report ie
 */
struct ieee80211_ie_intolerant_report {
        u_int8_t elem_id;
        u_int8_t elem_len;
        u_int8_t reg_class;
        u_int8_t chan_list[1];          /* variable-length channel list */
} __packed;

/*
 * 20/40 coext management action frame
 */
struct ieee80211_action_bss_coex_frame {
        struct ieee80211_action                ac_header;
        struct ieee80211_ie_bss_coex           coex;
        struct ieee80211_ie_intolerant_report    chan_report;
} __packed;

typedef enum ieee80211_tie_interval_type{
    IEEE80211_TIE_INTERVAL_TYPE_RESERVED                  = 0,
    IEEE80211_TIE_INTERVAL_TYPE_REASSOC_DEADLINE_INTERVAL = 1,
    IEEE80211_TIE_INTERVAL_TYPE_KEY_LIFETIME_INTERVAL     = 2,
    IEEE80211_TIE_INTERVAL_TYPE_ASSOC_COMEBACK_TIME       = 3,
}ieee80211_tie_interval_type_t;

struct ieee80211_ie_timeout_interval {
        u_int8_t elem_id;
        u_int8_t elem_len;
        u_int8_t interval_type;
        u_int32_t value;
} __packed;


/* Management MIC information element (IEEE 802.11w) */
struct ieee80211_ath_mmie {
    u_int8_t element_id;
    u_int8_t length;
    u_int16_t key_id;
    u_int8_t sequence_number[6];
    u_int8_t mic[16];
} __packed;

/* VHT capability flags */
/* B0-B1 Maximum MPDU Length */
#define IEEE80211_VHTCAP_MAX_MPDU_LEN_3839     0x00000000 /* A-MSDU Length 3839 octets */
#define IEEE80211_VHTCAP_MAX_MPDU_LEN_7935     0x00000001 /* A-MSDU Length 7991 octets */
#define IEEE80211_VHTCAP_MAX_MPDU_LEN_11454    0x00000002 /* A-MSDU Length 11454 octets */

/* B2-B3 Supported Channel Width */
#define IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80     0x00000000 /* Does not support 160 or 80+80 */
#define IEEE80211_VHTCAP_SUP_CHAN_WIDTH_160    0x00000004 /* Supports 160 */
#define IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80_160 0x00000008 /* Support both 160 or 80+80 */
#define IEEE80211_VHTCAP_SUP_CHAN_WIDTH_S      2          /* B2-B3 */
#define IEEE80211_VHTCAP_SUP_CHAN_WIDTH_MASK   0x0000000C

#define IEEE80211_VHTCAP_RX_LDPC             0x00000010 /* B4 RX LDPC */
#define IEEE80211_VHTCAP_SHORTGI_80          0x00000020 /* B5 Short GI for 80MHz */
#define IEEE80211_VHTCAP_SHORTGI_160         0x00000040 /* B6 Short GI for 160 and 80+80 MHz */
#define IEEE80211_VHTCAP_TX_STBC             0x00000080 /* B7 Tx STBC */
#define IEEE80211_VHTCAP_TX_STBC_S           7

#define IEEE80211_VHTCAP_RX_STBC             0x00000700 /* B8-B10 Rx STBC */
#define IEEE80211_VHTCAP_RX_STBC_S           8

#define IEEE80211_VHTCAP_SU_BFORMER          0x00000800 /* B11 SU Beam former capable */
#define IEEE80211_VHTCAP_SU_BFORMER_S        11
#define IEEE80211_VHTCAP_SU_BFORMEE          0x00001000 /* B12 SU Beam formee capable */
#define IEEE80211_VHTCAP_SU_BFORMEE_S        12

#define IEEE80211_VHTCAP_BF_MAX_ANT          0x0000E000 /* B13-B15 Compressed steering number of
                                                         * beacomformer Antennas supported */
#define IEEE80211_VHTCAP_BF_MAX_ANT_S        13

#define IEEE80211_VHTCAP_STS_CAP_S           13         /* B13-B15 Beamformee STS Capability */
#define IEEE80211_VHTCAP_STS_CAP_M           0x7



//#define IEEE80211_VHTCAP_SOUND_DIMENSIONS    0x00070000 /* B16-B18 Sounding Dimensions */
//#define IEEE80211_VHTCAP_SOUND_DIMENSIONS_S  16
#define IEEE80211_VHTCAP_SOUND_DIM           0x00070000 /* B16-B18 Sounding Dimensions */
#define IEEE80211_VHTCAP_SOUND_DIM_S         16

#define IEEE80211_VHTCAP_MU_BFORMER          0x00080000 /* B19 MU Beam Former */
#define IEEE80211_VHTCAP_MU_BFORMER_S        19
#define IEEE80211_VHTCAP_MU_BFORMEE          0x00100000 /* B20 MU Beam Formee */
#define IEEE80211_VHTCAP_MU_BFORMEE_S        20
#define IEEE80211_VHTCAP_TXOP_PS             0x00200000 /* B21 VHT TXOP PS */
#define IEEE80211_VHTCAP_PLUS_HTC_VHT        0x00400000 /* B22 +HTC-VHT capable */

#define IEEE80211_VHTCAP_MAX_AMPDU_LEN_FACTOR  13
#define IEEE80211_VHTCAP_MAX_AMPDU_LEN_EXP   0x03800000 /* B23-B25 maximum AMPDU Length Exponent */
#define IEEE80211_VHTCAP_MAX_AMPDU_LEN_EXP_S 23

#define IEEE80211_VHTCAP_LINK_ADAPT          0x0C000000 /* B26-B27 VHT Link Adaptation capable */
#define IEEE80211_VHTCAP_RX_ANTENNA_PATTERN  0x10000000 /* Rx Antenna Pattern Consistency Supported */
#define IEEE80211_VHTCAP_TX_ANTENNA_PATTERN  0x20000000 /* Tx Antenna Pattern Consistency Supported */
#define IEEE80211_VHTCAP_RESERVED            0xC0000000 /* B28-B31 Reserved */

#define IEEE80211_VHTCAP_NO_EXT_NSS_BW_SUPPORT  0x00000000 /* B30-B31 Extended NSS Bandwidth Support */
#define IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_1   0x40000000 /* B30-B31 Extended NSS Bandwidth Support */
#define IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_2   0x80000000 /* B30-B31 Extended NSS Bandwidth Support */
#define IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_3   0xC0000000 /* B30-B31 Extended NSS Bandwidth Support */
#define IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_S   30
#define IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_MASK   0xC0000000

#define IEEE80211_VHTCAP_EXT_NSS_MASK   (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_MASK | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_MASK)
/* VHTCAP combinations of "supported channel width" and "ext nss support"
 * which determine the NSS value supported by STA for <=80 MHz, 160 MHz
 * and 80+80 MHz. The macros to be read as combination of
 * "supported channel width" and "ext nss support" followed by NSS for 80MHz,
 * 160MHz and 80+80MHz defined as a function of Max VHT NSS supported.
 * Ex: IEEE80211_EXTNSS_MAP_01_80F1_160FDOT5_80P80NONE - To be reas as
 * supported channel width = 0
 * ext nss support = 1
 * NSS value for <=80MHz = max_vht_nss * 1
 * NSS value for 160MHz = max_vht_nss * (.5)
 * NSS value for 80+80MHz = not supported
 */
#define IEEE80211_EXTNSS_MAP_00_80F1_160NONE_80P80NONE      (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80 | IEEE80211_VHTCAP_NO_EXT_NSS_BW_SUPPORT)
#define IEEE80211_EXTNSS_MAP_01_80F1_160FDOT5_80P80NONE     (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80 | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_1)
#define IEEE80211_EXTNSS_MAP_02_80F1_160FDOT5_80P80FDOT5    (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80 | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_2)
#define IEEE80211_EXTNSS_MAP_03_80F1_160FDOT75_80P80FDOT75  (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80 | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_3)
#define IEEE80211_EXTNSS_MAP_10_80F1_160F1_80P80NONE        (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_160 | IEEE80211_VHTCAP_NO_EXT_NSS_BW_SUPPORT)
#define IEEE80211_EXTNSS_MAP_11_80F1_160F1_80P80FDOT5       (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_160 | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_1)
#define IEEE80211_EXTNSS_MAP_12_80F1_160F1_80P80FDOT75      (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_160 | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_2)
#define IEEE80211_EXTNSS_MAP_13_80F2_160F2_80P80F1          (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_160 | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_3)
#define IEEE80211_EXTNSS_MAP_20_80F1_160F1_80P80F1          (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80_160 | IEEE80211_VHTCAP_NO_EXT_NSS_BW_SUPPORT)
#define IEEE80211_EXTNSS_MAP_23_80F2_160F1_80P80F1          (IEEE80211_VHTCAP_SUP_CHAN_WIDTH_80_160 | IEEE80211_VHTCAP_EXT_NSS_BW_SUPPORT_3)

/*
 * 802.11ac VHT Capability IE
 */
struct supp_tx_mcs_extnss {
#if _BYTE_ORDER == _BIG_ENDIAN
        u_int16_t   reserved:2,             /* B62-B63 reserved */
                    ext_nss_capable:1,      /* B61 Ext NSS capability */
                    tx_high_data_rate:13;   /* B48-B60 Max Tx data rate */
#else
        u_int16_t   tx_high_data_rate:13,   /* B48-B60 Max Tx data rate */
                    ext_nss_capable:1,      /* B61 Ext NSS capability */
                    reserved:2;             /* B62-B63 reserved */
#endif
}__packed;

struct ieee80211_ie_vhtcap {
        u_int8_t    elem_id;
        u_int8_t    elem_len;
        u_int32_t   vht_cap_info;
        u_int16_t   rx_mcs_map;          /* B0-B15 Max Rx MCS for each SS */
        u_int16_t   rx_high_data_rate;   /* B16-B28 Max Rx data rate,
                                            Note:  B29-B31 reserved */
        u_int16_t   tx_mcs_map;          /* B32-B47 Max Tx MCS for each SS */
        struct supp_tx_mcs_extnss tx_mcs_extnss_cap;
} __packed;

/* VHT MCS map */
#define IEEE80211_VHT_LOWER_MCS_MAP             0xffff
#define IEEE80211_VHT_HIGHER_MCS_MAP            0xff0000
#define IEEE80211_VHT_MCS10_11_SUPP             0x1000000
#define IEEE80211_VHT_HIGHER_MCS_S              16
#define IEEE80211_VHT_MCS0_9_VALUE              0x2
#define IEEE80211_VHT_BITS_PER_SS_IN_MCSNSS_SET 2

#define MAX_VHT_NSS     8
/* Calculate peer NSS support for VHT MCS10/11 based on the self SS support for
 * MCS10/11 and peer SS support advertised in VHT mcsnssmap
 */
#define VHT_INTRSCTD_SS_MCS10_11_CAP(self_nss, peer_mcsnssmap, val) {       \
    uint8_t count, nss = 1;                                                 \
    for(count = 0; count < MAX_VHT_NSS; count++) {                          \
        if(((peer_mcsnssmap & 0x3) == IEEE80211_VHT_MCS0_9_VALUE)           \
                                                    && (self_nss & 1)) {    \
            val |= nss;                                                     \
        }                                                                   \
        peer_mcsnssmap =                                                    \
            (peer_mcsnssmap >> IEEE80211_VHT_BITS_PER_SS_IN_MCSNSS_SET);    \
        self_nss = (self_nss >> 1);                                         \
        nss = (nss << 1);                                                   \
    }                                                                       \
}


/* VHT Operation  */
#define IEEE80211_VHTOP_CHWIDTH_2040          0 /* 20/40 MHz Operating Channel */
#define IEEE80211_VHTOP_CHWIDTH_80            1 /* 80 MHz Operating Channel */
#define IEEE80211_VHTOP_CHWIDTH_160           2 /* 160 MHz Operating Channel */
#define IEEE80211_VHTOP_CHWIDTH_80_80         3 /* 80 + 80 MHz Operating
                                                   Channel */
#define IEEE80211_VHTOP_CHWIDTH_REVSIG_160    1 /* 160 MHz Operating Channel
                                                   (revised signalling) */
#define IEEE80211_VHTOP_CHWIDTH_REVSIG_80_80  1 /* 80 + 80 MHz Operating Channel
                                                   (revised signalling) */

/*
 * 802.11ac VHT Operation IE
 */
struct ieee80211_ie_vhtop {
        u_int8_t    elem_id;
        u_int8_t    elem_len;
        u_int8_t    vht_op_chwidth;              /* BSS Operational Channel width */
        u_int8_t    vht_op_ch_freq_seg1;         /* Channel Center frequency */
        u_int8_t    vht_op_ch_freq_seg2;         /* Channel Center frequency applicable
                                                  * for 80+80MHz mode of operation */
        u_int16_t   vhtop_basic_mcs_set;         /* Basic MCS set */
} __packed;

/*
 * 802.11ac Extended BSS Load IE
 */
struct ieee80211_ie_ext_bssload {
        u_int8_t     elem_id;              /* IEEE80211_ELEMID_EXT_BSS_LOAD */
        u_int8_t     length;               /* length in bytes */
        u_int16_t    mu_bformee_sta_count; /* MU-MIMO beamformee capable station count*/
        u_int8_t     ss_under_util_20;     /* spatial stream underutilize for primary 20 */
        u_int8_t     sec_20_util;          /* Secondary 20MHz utilization */
        u_int8_t     sec_40_util;          /* Secondary 40MHz utilization */
        u_int8_t     sec_80_util;          /* Secondary 80MHz utilization */
} __packed;

/*
 * 802.11ng vendor specific VHT Interop Capability
 * with Vht cap & Vht op IE
 */
struct ieee80211_ie_interop_vhtcap {
        u_int8_t    elem_id;
        u_int8_t    elem_len;
        u_int32_t   vht_interop_oui;
        u_int8_t    sub_type;
        struct ieee80211_ie_vhtcap  vhtcapie;
        struct ieee80211_ie_vhtop   vhtopie;
} __packed;

/*
 * 11ax specific spatial reuse parameter ie
 */
#define IEEE80211_SRP_SRCTRL_SRP_DISALLOWED_MASK          0x01 /* B0 */
#define IEEE80211_SRP_SRCTRL_OBSS_PD_DISALLOWED_MASK      0x02 /* B1 */
#define IEEE80211_SRP_SRCTRL_NON_SRG_OFFSET_PRESENT_MASK  0x04 /* B2 */
#define IEEE80211_SRP_SRCTRL_SRG_INFO_PRESENT_MASK        0x08 /* B3 */

struct ieee80211_ie_srp_extie {
    u_int8_t srp_id;
    u_int8_t srp_len;
    u_int8_t srp_id_extn;
    u_int8_t sr_control;
    union {
        struct {
            u_int8_t non_srg_obsspd_max_offset;
            u_int8_t srg_obss_pd_min_offset;
            u_int8_t srg_obss_pd_max_offset;
            u_int8_t srg_bss_color_bitmap[8];
            u_int8_t srg_partial_bssid_bitmap[8];
        } __packed nonsrg_srg_info;
        struct {
            u_int8_t non_srg_obsspd_max_offset;
        } __packed nonsrg_info;
        struct {
            u_int8_t srg_obss_pd_min_offset;
            u_int8_t srg_obss_pd_max_offset;
            u_int8_t srg_bss_color_bitmap[8];
            u_int8_t srg_partial_bssid_bitmap[8];
        } __packed srg_info;
    };
} __packed;

#define IEEE80211_FC0_SUBTYPE_DEBUG          0xff

#define IEEE80211_IE_ID_LEN                     1
#define IEEE80211_IE_LENGTH_LEN                 1
#define IEEE80211_IE_ID_EXT_LEN                 1
#define IEEE80211_IE_HDR_LEN                    \
        (IEEE80211_IE_ID_LEN +                  \
         IEEE80211_IE_LENGTH_LEN)
#define IEEE80211_HE_IE_HDR_OFFSET_TO_ID_EXT    \
        (IEEE80211_IE_ID_LEN +                  \
         IEEE80211_IE_LENGTH_LEN)


/* GI Modes. */
#define IEEE80211_GI_0DOT8_US           0   /*800 nano secs/0.8 us is default/GI disabled mode in HT,VHT, HE*/
#define IEEE80211_GI_0DOT4_US           1   /*400 nano secs/0.4 us is supported in HT and VHT modes */
#define IEEE80211_GI_1DOT6_US           2   /*1600 nano secs/1.6 us is only in HE mode */
#define IEEE80211_GI_3DOT2_US           3   /*3600 nano secs/3.2 us is only in HE mode */

/* HE MU MIMO */
#define IEEE80211_HE_MU_DISABLE               0
#define IEEE80211_HE_DL_MU_MIMO_DISABLE       1
#define IEEE80211_HE_DL_MU_OFDMA_DISABLE      2
#define IEEE80211_HE_UL_MU_MIMO_DISABLE       3
#define IEEE80211_HE_UL_MU_OFDMA_DISABLE      4
#define IEEE80211_HE_MU_ENABLE                5
#define IEEE80211_HE_DL_MU_MIMO_ENABLE        6
#define IEEE80211_HE_DL_MU_OFDMA_ENABLE       7
#define IEEE80211_HE_UL_MU_MIMO_ENABLE        8
#define IEEE80211_HE_UL_MU_OFDMA_ENABLE       9

/* HE AR LDPC VALUES */
#define IEEE80211_HE_AR_LDPC_DEFAULT   3
#define IEEE80211_HE_AR_LDPC_SHIFT     16

/* HE LTF VALUES */
#define IEEE80211_HE_LTF_DEFAULT 0x0
#define IEEE80211_HE_LTF_1X      0x1
#define IEEE80211_HE_LTF_2X      0x2
#define IEEE80211_HE_LTF_4X      0x3

/* Auto Rate HE SGI & LTF is set using the WMI
 * WMI_VDEV_PARAM_AUTORATE_MISC_CFG. The bit
 * ordering for this WMI is as follows:
 *
 * bits 7:0 (LTF): When a bit in the bitmask is
 * set, then corresponding LTF value is used for
 * auto rate.
 *     BIT0   = 1 (HE_LTF_1X)
 *     BIT1   = 1 (HE_LTF_2X)
 *     BIT2   = 1 (HE_LTF_4X)
 *     BIT3-7 = Reserved bits.
 *
 * bits 15:8 (SGI): When a bit in the bitmask is
 * set, then corresponding SGI value is used for
 * auto rate.
 *     BIT8     = 1 (400 NS)
 *     BIT9     = 1 (800 NS)
 *     BIT10    = 1 (1600 NS)
 *     BIT11    = 1 (3200 NS)
 *     BIT12-15 = Reserved bits.
 *
 *  Following bit masks are defined based on these
 *  bit ordering.
 */
/* Auto Rate HE SGI & LTF Masks */
#define IEEE80211_HE_AR_LTF_MASK                    0x00ff
#define IEEE80211_HE_AR_SGI_MASK                    0xff00
/* Auto Rate HE SGI shift */
#define IEEE80211_HE_AR_SGI_S                       8
/* All 1 values for auto rate HE GI and LTF combinations
 * will allow the FW to choose the best combination from
 * all possible set of combinations
 */
#define IEEE80211_HE_AR_DEFAULT_LTF_SGI_COMBINATION 0xffff
#define IEEE80211_HE_AR_SGI_DEFAULT                 0xff

/* Calculate best case SGI value from iv_he_ar_gi_ltf setting */
#define IEEE80211_GET_MAX_AR_SGI(he_ar_gi, he_ar_gi_max)        \
{                                                               \
    /* (he_ar_gi == IEEE80211_HE_AR_SGI_DEFAULT) corresponds
     * to default 800ns SGI*/                                   \
    he_ar_gi_max = 1;                                           \
                                                                \
    if(he_ar_gi != IEEE80211_HE_AR_SGI_DEFAULT) {               \
        he_ar_gi_max = 0;                                       \
        while(!(he_ar_gi & 1)) {                                \
            he_ar_gi_max++;                                     \
            he_ar_gi >>= 1;                                     \
        }                                                       \
    }                                                           \
}

/* HE Rate */
#define IEEE80211_HE_MCS_IDX_MAX              11   /* Supported MCS idx range  0 -11 */

/* Trigger Interval maximum setting in ms */
#define IEEE80211_HE_TRIG_INT_MAX             65535 /* Supported Trigger interval range 0 - 65535ms */

/* UL PPDU Duration maximum setting in usec */
#define IEEE80211_UL_PPDU_DURATION_MAX        5484

/* Channel BW */
#define IEEE80211_HE_BW_IDX_MAX               3 /* Supported BW IDX range 0-3
                                                 * 0 - 20MHz
                                                 * 1 - 40MHz
                                                 * 2 - 80MHz
                                                 * 3 - 160MHz
                                                 */

/* HE Fragmentation */
#define IEEE80211_HE_FRAG_DISABLED            0
#define IEEE80211_HE_FRAG_LEVEL1              1
#define IEEE80211_HE_FRAG_LEVEL2              2
#define IEEE80211_HE_FRAG_LEVEL3              3
#define IEEE80211_HE_FRAG_LEVEL_MAX           4

#define IEEE80211_HE_MIN_FRAG_SIZE_MAX        3

/* HE BSS color */
#define IEEE80211_HE_BSS_COLOR_MIN            0
#define IEEE80211_HE_BSS_COLOR_MAX            63
#define IEEE80211_HE_BSS_COLOR_ENABLE         0

/* NAV config */
#define IEEE80211_NAV_CTRL_STATUS_MAX         3
#define IEEE80211_NAV_CTRL_STATUS_MASK        0x3
#define IEEE80211_NAV_CTRL_STATUS_BITS        2
/* Spatial Reuse */
#define IEEE80211_HE_SR_VALUE15_ENABLE        1
#define HE_SR_OBSS_PD_THRESH_ENABLE           1
#define HE_SR_OBSS_PD_THRESH_ENABLE_S         31
#define HE_OBSS_PD_THRESH_MASK                0x000000FF
#define HE_OBSS_PD_THRESH_ENABLE_OFFSET(value)            \
    (value << HE_SR_OBSS_PD_THRESH_ENABLE_S)
#define GET_HE_OBSS_PD_THRESH_ENABLE(max_offset)       \
    ((HE_OBSS_PD_THRESH_ENABLE_OFFSET(1) \
    & max_offset ) >> HE_SR_OBSS_PD_THRESH_ENABLE_S)

/* BSR Support */
#define IEEE80211_BSR_SUPPORT_ENABLE          1

/* BA BUF Size */
#define IEEE80211_MIN_BA_BUFFER_SIZE          0 /* Minimum user value setting for
                                                 * BA buffer size. Sets buffer size to 64 */
#define IEEE80211_MAX_BA_BUFFER_SIZE          1 /* Maximum user value setting for
                                                 * BA buffer size. Sets buffer size to 255 */
#define IEEE80211_BA_MODE_BUFFER_SIZE_OFFSET  2 /* Maps the user set 0, 1 values to 2 and 3
                                                 * to set the VDEV PARAM used by target for
                                                 * configuring the BA buffer size */
/* Pre-11AX MAX BA BUF Size */
#define IEEE80211_LEGACY_BA_BUFFER_SIZE_MAX  64
/* 11AX MAX BA BUF Size */
#define IEEE80211_HE_BA_BUFFER_SIZE_MAX     256
/* Macro to return the max BA BUF size
 * based on current phy mode
 */
#define IEEE80211_ABSOLUTE_BA_BUFFERSIZE(cur_phy_mode, _ba_buf_size)  \
    (((_ba_buf_size == IEEE80211_MAX_BA_BUFFER_SIZE)    \
      && (cur_phy_mode >= IEEE80211_MODE_11AXA_HE20)) ?  \
     IEEE80211_HE_BA_BUFFER_SIZE_MAX : IEEE80211_LEGACY_BA_BUFFER_SIZE_MAX)

/* 11AX Default configs. Clean up once
 * when user control knobs are defined.
 * Will be addressed in 11AX TODO (Phase II)
 */
#define ENABLE_HE_MULTITID              1
#define ENABLE_HE_ALL_ACK               1
#define ENABLE_HE_MAX_FRAG_MSDU         1
#define ENABLE_HE_MIN_FRAG_SIZE         1
#define ENABLE_HE_FRAG                  1
#define ENABLE_HE_RELAXED_EDCA          1
#define ENABLE_HE_SPATIAL_REUSE         1
#define ENABLE_HE_CTRL_FIELD            1
#define ENABLE_HE_CTRL_MBA              1
#define ENABLE_HE_UL_MU_SCHEDULING      1
#define ENABLE_HE_ACTRL_BSR             1
#define ENABLE_HE_32BIT_BA              1
#define ENABLE_HE_MU_CASCADE            1
#define ENABLE_HE_OMI                   1
#define ENABLE_HE_OFDMA_RA              1
#define ENABLE_HE_AMSDU_FRAG            1
#define ENABLE_HE_FLEX_TWT              1
#define ENABLE_HE_LINK_ADAPT            1
#define ENABLE_HE_BF_STATUS_RPT         1
#define ENABLE_HE_TWT_REQ               1
#define ENABLE_HE_TWT_RES               1
#define ENABLE_HE_BCAST_TWT             1
#define ENABLE_HE_MU_RTS                1
#define ENABLE_HE_MULTI_BSS             1
#define ENABLE_HE_TX_LDPC               1
#define ENABLE_HE_RX_LDPC               1
#define ENABLE_HE_UL_MUMIMO             1
#define ENABLE_HE_TWT_REQUIRED          1
#define ENABLE_HE_MU_BFEE               1
#define ENABLE_HE_MU_BFER               1
#define ENABLE_HE_SU_BFEE               1
#define ENABLE_HE_SU_BFER               1
#define ENABLE_HE_DL_MUOFDMA            1
#define ENABLE_HE_UL_MUOFDMA            1
#define ENABLE_HE_MUEDCA                1
#define ENABLE_HE_DL_MUMIMO             1
#define ENABLE_HE_DYNAMIC_MUEDCA        1
#define MUEDCA_DYNAMIC_ALGO_ENABLE_STATE_MASK 0x01
#define MUEDCA_DYNAMIC_ALGO_UPDATE_STATE_MASK 0x02

/* Sounding mode bit values for SU AX sounding is as follows:
 * bit(0) --> 1 [1:AX | 0:AC]
 * bit(1) --> Reserved
 * bit(2) --> 0 [1:MU | 0:SU]
 * bit(3) --> 0 [1:Triggered | 0:Non-Triggered]
 * Value to enable AX SU sounding will be 0x1
 */
#define ENABLE_SU_AX_SOUNDING           0x1

#define HECAP_PHYBYTE_IDX0      0
#define HECAP_PHYBYTE_IDX1      1
#define HECAP_PHYBYTE_IDX2      2
#define HECAP_PHYBYTE_IDX3      3
#define HECAP_PHYBYTE_IDX4      4
#define HECAP_PHYBYTE_IDX5      5
#define HECAP_PHYBYTE_IDX6      6
#define HECAP_PHYBYTE_IDX7      7
#define HECAP_PHYBYTE_IDX8      8
#define HECAP_PHYBYTE_IDX9      9
#define HECAP_PHYBYTE_IDX10     10

/* HE PHY capabilities , field
 * starting idx and no of bits
 * postions as per IE spec
 */
#define HECAP_PHY_DUAL_BAND_IDX                       0
#define HECAP_PHY_DUAL_BAND_BITS                      1
#define HECAP_PHY_CHANNEL_WIDTH_IDX                   1
#define HECAP_PHY_CHANNEL_WIDTH_BITS                  7
#define HECAP_PHY_PREAMBLE_PUNC_RX_IDX                8
#define HECAP_PHY_PREAMBLE_PUNC_RX_BITS               4
#define HECAP_PHY_DEVICE_CLASS_IDX                    12
#define HECAP_PHY_DEVICE_CLASS_BITS                   1
#define HECAP_PHY_LDPC_IN_PAYLOAD_IDX                 13
#define HECAP_PHY_LDPC_IN_PAYLOAD_BITS                1
#define HECAP_PHY_LTF_GI_HE_PPDU_IDX                  14
#define HECAP_PHY_LTF_GI_HE_PPDU_BITS                 1
#if SUPPORT_11AX_D3
#define HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX             15
#define HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS            2
#else
#define HECAP_PHY_MIDAMBLERXMAXNSTS_IDX               15
#define HECAP_PHY_MIDAMBLERXMAXNSTS_BITS              2
#endif
#define HECAP_PHY_LTF_GI_FOR_NDP_IDX                  17
#define HECAP_PHY_LTF_GI_FOR_NDP_BITS                 1
#define HECAP_PHY_STBC_TX_IDX                         18
#define HECAP_PHY_STBC_TX_BITS                        1
#define HECAP_PHY_STBC_RX_IDX                         19
#define HECAP_PHY_STBC_RX_BITS                        1
#define HECAP_PHY_DOPPLER_TX_IDX                      20
#define HECAP_PHY_DOPPLER_TX_BITS                     1
#define HECAP_PHY_DOPPLER_RX_IDX                      21
#define HECAP_PHY_DOPPLER_RX_BITS                     1
#define HECAP_PHY_UL_MUMIMO_IDX                       22
#define HECAP_PHY_UL_MUMIMO_BITS                      1
#define HECAP_PHY_UL_MUOFDMA_IDX                      23
#define HECAP_PHY_UL_MUOFDMA_BITS                     1
#define HECAP_PHY_DCM_TX_IDX                          24
#define HECAP_PHY_DCM_TX_BITS                         3
#define HECAP_PHY_DCM_RX_IDX                          27
#define HECAP_PHY_DCM_RX_BITS                         3
#define HECAP_PHY_UL_MU_PPDU_PAYLOAD_IDX              30
#define HECAP_PHY_UL_MU_PPDU_PAYLOAD_BITS             1
#define HECAP_PHY_SU_BFER_IDX                         31
#define HECAP_PHY_SU_BFER_BITS                        1
#define HECAP_PHY_SU_BFEE_IDX                         32
#define HECAP_PHY_SU_BFEE_BITS                        1
#define HECAP_PHY_MU_BFER_IDX                         33
#define HECAP_PHY_MU_BFER_BITS                        1
#define HECAP_PHY_BFEE_STS_LESS_OR_EQ_80MHZ_IDX       34
#define HECAP_PHY_BFEE_STS_LESS_OR_EQ_80MHZ_BITS      3
#define HECAP_PHY_BFEE_STS_GREATER_80MHZ_IDX          37
#define HECAP_PHY_BFEE_STS_GREATER_80MHZ_BITS         3
#define HECAP_PHY_NOOF_SOUNDDIM_LESS_OR_EQ_80MHZ_IDX  40
#define HECAP_PHY_NOOF_SOUNDDIM_LESS_OR_EQ_80MHZ_BITS 3
#define HECAP_PHY_NOOF_SOUNDDIM_GREAT_80MHZ_IDX       43
#define HECAP_PHY_NOOF_SOUNDDIM_GREAT_80MHZ_BITS      3
#define HECAP_PHY_NG_16_SU_FEEDBACK_IDX               46
#define HECAP_PHY_NG_16_SU_FEEDBACK_BITS              1
#define HECAP_PHY_NG_16_MU_FEEDBACK_IDX               47
#define HECAP_PHY_NG_16_MU_FEEDBACK_BITS              1
#define HECAP_PHY_CODEBOOK_SIZE4_2_SU_IDX             48
#define HECAP_PHY_CODEBOOK_SIZE4_2_SU_BITS            1
#define HECAP_PHY_CODEBOOK_SIZE7_5_MU_IDX             49
#define HECAP_PHY_CODEBOOK_SIZE7_5_MU_BITS            1
#define HECAP_PHY_BF_FEEBACK_TRIGGER_IDX              50
#define HECAP_PHY_BF_FEEBACK_TRIGGER_BITS             3
#define HECAP_PHY_ER_SU_PPDU_PAYLOAD_IDX              53
#define HECAP_PHY_ER_SU_PPDU_PAYLOAD_BITS             1
#define HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_IDX           54
#define HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_BITS          1
#define HECAP_PHY_PPET_THRESHOLD_PRESENT_IDX          55
#define HECAP_PHY_PPET_THRESHOLD_PRESENT_BITS         1
#define HECAP_PHY_SRP_SR_IDX                          56
#define HECAP_PHY_SRP_SR_BITS                         1
#define HECAP_PHY_POWER_BOOST_AR_IDX                  57
#define HECAP_PHY_POWER_BOOST_AR_BITS                 1
#define HECAP_PHY_4X_LTF_0_8_GI_IDX                   58
#define HECAP_PHY_4X_LTF_0_8_GI_BITS                  1
#define HECAP_PHY_MAX_NC_IDX                          59
#define HECAP_PHY_MAX_NC_BITS                         3
#define HECAP_PHY_STBC_TX_GREATER_80MHZ_IDX           62
#define HECAP_PHY_STBC_TX_GREATER_80MHZ_BITS          1
#define HECAP_PHY_STBC_RX_GREATER_80MHZ_IDX           63
#define HECAP_PHY_STBC_RX_GREATER_80MHZ_BITS          1
#define HECAP_PHY_ERSU_4X_LTF_800_NS_GI_IDX           64
#define HECAP_PHY_ERSU_4X_LTF_800_NS_GI_BITS          1
#define HECAP_PHY_HEPPDU_20_IN_40MHZ2G_IDX            65
#define HECAP_PHY_HEPPDU_20_IN_40MHZ2G_BITS           1
#define HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_IDX    66
#define HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_BITS   1
#define HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_IDX    67
#define HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_BITS   1
#define HECAP_PHY_ERSU_1X_LTF_800_NS_GI_IDX           68
#define HECAP_PHY_ERSU_1X_LTF_800_NS_GI_BITS          1
#if SUPPORT_11AX_D3
#define HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_IDX       69
#define HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_BITS      1
#else
#define HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_IDX         69
#define HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_BITS        1
#endif

#if SUPPORT_11AX_D3

#define HECAP_PHY_DCM_MAXBW_IDX                                 70
#define HECAP_PHY_DCM_MAXBW_BITS                                2
#define HECAP_PHY_LT16_HESIGB_OFDM_SYM_IDX                      72
#define HECAP_PHY_LT16_HESIGB_OFDM_SYM_BITS                     1
#define HECAP_PHY_NON_TRIG_CQI_FDBK_IDX                         73
#define HECAP_PHY_NON_TRIG_CQI_FDBK_BITS                        1
#define HECAP_PHY_TX_1024QAM_LT_242TONE_RU_IDX                  74
#define HECAP_PHY_TX_1024QAM_LT_242TONE_RU_BITS                 1
#define HECAP_PHY_RX_1024QAM_LT_242TONE_RU_IDX                  75
#define HECAP_PHY_RX_1024QAM_LT_242TONE_RU_BITS                 1
#define HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_IDX           76
#define HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_BITS          1
#define HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_IDX       77
#define HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_BITS      1
#define HECAP_PHY_RESERVED_IDX1                                 0
#define HECAP_PHY_RESERVED_BITS1                                1
#define HECAP_PHY_RESERVED_IDX2                                 78
#define HECAP_PHY_RESERVED_BITS2                                10

#endif


#define HE_GET_BITS(_val,_index,_num_bits)      \
    (((_val) >> (_index)) & ((1 << (_num_bits)) - 1))

#define HE_SET_BITS(_var,_index,_num_bits,_val) do {              \
    (_var) &= ~(((1 << (_num_bits)) - 1) << (_index));            \
    (_var) |= (((_val) & ((1 << (_num_bits)) - 1)) << (_index));  \
    } while (0)


#define IC_HECAP_PHYDWORD_IDX0  0
#define IC_HECAP_PHYDWORD_IDX1  1
#define IC_HECAP_PHYDWORD_IDX2  2

#define HECAP_MCS_IDX           0
#define HECAP_TOT_MCS_CNT       3


/* HE PHY capabilities , field starting idx and
 * no of bits postions as per IC HE populated
 * capabilities from target
 */
#define IC_HECAP_PHY_DUAL_BAND_IDX                       0
#define IC_HECAP_PHY_DUAL_BAND_BITS                      1
#define IC_HECAP_PHY_CHANNEL_WIDTH_IDX                   1
#define IC_HECAP_PHY_CHANNEL_WIDTH_BITS                  7
#define IC_HECAP_PHY_PREAMBLE_PUNC_RX_IDX                8
#define IC_HECAP_PHY_PREAMBLE_PUNC_RX_BITS               4
#define IC_HECAP_PHY_DEVICE_CLASS_IDX                    12
#define IC_HECAP_PHY_DEVICE_CLASS_BITS                   1
#define IC_HECAP_PHY_LDPC_IN_PAYLOAD_IDX                 13
#define IC_HECAP_PHY_LDPC_IN_PAYLOAD_BITS                1
#define IC_HECAP_PHY_LTF_GI_HE_PPDU_IDX                  14
#define IC_HECAP_PHY_LTF_GI_HE_PPDU_BITS                 1
#if SUPPORT_11AX_D3
#define IC_HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX             15
#define IC_HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS            2
#else
#define IC_HECAP_PHY_MIDAMBLERXMAXNSTS_IDX               15
#define IC_HECAP_PHY_MIDAMBLERXMAXNSTS_BITS              2
#endif
#define IC_HECAP_PHY_LTF_GI_FOR_NDP_IDX                  17
#define IC_HECAP_PHY_LTF_GI_FOR_NDP_BITS                 1
#define IC_HECAP_PHY_TX_STBC_IDX                         18
#define IC_HECAP_PHY_TX_STBC_BITS                        1
#define IC_HECAP_PHY_RX_STBC_IDX                         19
#define IC_HECAP_PHY_RX_STBC_BITS                        1
#define IC_HECAP_PHY_TX_DOPPLER_IDX                      20
#define IC_HECAP_PHY_TX_DOPPLER_BITS                     1
#define IC_HECAP_PHY_RX_DOPPLER_IDX                      21
#define IC_HECAP_PHY_RX_DOPPLER_BITS                     1
#define IC_HECAP_PHY_UL_MUMIMO_IDX                       22
#define IC_HECAP_PHY_UL_MUMIMO_BITS                      1
#define IC_HECAP_PHY_UL_MUOFDMA_IDX                      23
#define IC_HECAP_PHY_UL_MUOFDMA_BITS                     1
#define IC_HECAP_PHY_DCM_TX_IDX                          24
#define IC_HECAP_PHY_DCM_TX_BITS                         3
#define IC_HECAP_PHY_DCM_RX_IDX                          27
#define IC_HECAP_PHY_DCM_RX_BITS                         3
#define IC_HECAP_PHY_UL_MU_PPDU_PAYLOAD_IDX              30
#define IC_HECAP_PHY_UL_MU_PPDU_PAYLOAD_BITS             1
#define IC_HECAP_PHY_SU_BFER_IDX                         31
#define IC_HECAP_PHY_SU_BFER_BITS                        1
#define IC_HECAP_PHY_SU_BFEE_IDX                         0
#define IC_HECAP_PHY_SU_BFEE_BITS                        1
#define IC_HECAP_PHY_MU_BFER_IDX                         1
#define IC_HECAP_PHY_MU_BFER_BITS                        1
#define IC_HECAP_PHY_BFEE_STS_IDX                        2
#define IC_HECAP_PHY_BFEE_STS_BITS                       3
#define IC_HECAP_PHY_BFEE_STS_GREATER_80MHZ_IDX          5
#define IC_HECAP_PHY_BFEE_STS_GREATER_80MHZ_BITS         3
#define IC_HECAP_PHY_NOOF_SOUNDDIMENS_LESS_80MHZ_IDX     8
#define IC_HECAP_PHY_NOOF_SOUNDDIMENS_LESS_80MHZ_BITS    3
#define IC_HECAP_PHY_NOOF_SOUNDDIMENS_GREAT_80MHZ_IDX    11
#define IC_HECAP_PHY_NOOF_SOUNDDIMENS_GREAT_80MHZ_BITS   3
#define IC_HECAP_PHY_NG_16_SU_FEEDBACK_IDX               14
#define IC_HECAP_PHY_NG_16_SU_FEEDBACK_BITS              1
#define IC_HECAP_PHY_NG_16_MU_FEEDBACK_IDX               15
#define IC_HECAP_PHY_NG_16_MU_FEEDBACK_BITS              1
#define IC_HECAP_PHY_CODEBOOK_SIZE4_2_SU_IDX             16
#define IC_HECAP_PHY_CODEBOOK_SIZE4_2_SU_BITS            1
#define IC_HECAP_PHY_CODEBOOK_SIZE7_5_MU_IDX             17
#define IC_HECAP_PHY_CODEBOOK_SIZE7_5_MU_BITS            1
#define IC_HECAP_PHY_BF_FEEBACK_TRIGGER_IDX              18
#define IC_HECAP_PHY_BF_FEEBACK_TRIGGER_BITS             3
#define IC_HECAP_PHY_ER_SU_PPDU_PAYLOAD_IDX              21
#define IC_HECAP_PHY_ER_SU_PPDU_PAYLOAD_BITS             1
#define IC_HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_IDX           22
#define IC_HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_BITS          1
#define IC_HECAP_PHY_PPET_THRESHOLD_PRESENT_IDX          23
#define IC_HECAP_PHY_PPET_THRESHOLD_PRESENT_BITS         1
#define IC_HECAP_PHY_SRP_SR_IDX                          24
#define IC_HECAP_PHY_SRP_SR_BITS                         1
#define IC_HECAP_PHY_POWER_BOOST_AR_IDX                  25
#define IC_HECAP_PHY_POWER_BOOST_AR_BITS                 1
#define IC_HECAP_PHY_4X_LTF_0_8_GI_IDX                   26
#define IC_HECAP_PHY_4X_LTF_0_8_GI_BITS                  1
#define IC_HECAP_PHY_MAX_NC_IDX                          27
#define IC_HECAP_PHY_MAX_NC_BITS                         3
#define IC_HECAP_PHY_STBC_TX_GREATER_80MHZ_IDX           30
#define IC_HECAP_PHY_STBC_TX_GREATER_80MHZ_BITS          1
#define IC_HECAP_PHY_STBC_RX_GREATER_80MHZ_IDX           31
#define IC_HECAP_PHY_STBC_RX_GREATER_80MHZ_BITS          1
#define IC_HECAP_PHY_ERSU_4X_LTF_800_NS_GI_IDX           0
#define IC_HECAP_PHY_ERSU_4X_LTF_800_NS_GI_BITS          1
#define IC_HECAP_PHY_HEPPDU_20_IN_40MHZ2G_IDX            1
#define IC_HECAP_PHY_HEPPDU_20_IN_40MHZ2G_BITS           1
#define IC_HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_IDX    2
#define IC_HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_BITS   1
#define IC_HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_IDX    3
#define IC_HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_BITS   1
#define IC_HECAP_PHY_ERSU_1X_LTF_800_NS_GI_IDX           4
#define IC_HECAP_PHY_ERSU_1X_LTF_800_NS_GI_BITS          1
#if SUPPORT_11AX_D3
#define IC_HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_IDX       5
#define IC_HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_BITS      1
#else
#define IC_HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_IDX         5
#define IC_HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_BITS        1
#endif
#define IC_HECAP_PHY_RESERVED_IDX                        6
#define IC_HECAP_PHY_RESERVED_BITS                       26

#if SUPPORT_11AX_D3

#define IC_HECAP_PHY_DCM_MAXBW_IDX                                 6
#define IC_HECAP_PHY_DCM_MAXBW_BITS                                2
#define IC_HECAP_PHY_LT16_HESIGB_OFDM_SYM_IDX                      8
#define IC_HECAP_PHY_LT16_HESIGB_OFDM_SYM_BITS                     1
#define IC_HECAP_PHY_NON_TRIG_CQI_FDBK_IDX                         9
#define IC_HECAP_PHY_NON_TRIG_CQI_FDBK_BITS                        1
#define IC_HECAP_PHY_TX_1024QAM_LT_242TONE_RU_IDX                  10
#define IC_HECAP_PHY_TX_1024QAM_LT_242TONE_RU_BITS                 1
#define IC_HECAP_PHY_RX_1024QAM_LT_242TONE_RU_IDX                  11
#define IC_HECAP_PHY_RX_1024QAM_LT_242TONE_RU_BITS                 1
#define IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_IDX           12
#define IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_BITS          1
#define IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_IDX       13
#define IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_BITS      1

#endif

/* HE PHY Capabilities Get/Set to IC / Node HE handle */

/* Dual Band both 2.4 GHz and 5 GHz Supported */
#define HECAP_PHY_DB_GET_FROM_IC(hecap_phy)                \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],     \
	IC_HECAP_PHY_DUAL_BAND_IDX, IC_HECAP_PHY_DUAL_BAND_BITS)
#define HECAP_PHY_DB_SET_TO_IC(hecap_phy, value)           \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],     \
        IC_HECAP_PHY_DUAL_BAND_IDX, IC_HECAP_PHY_DUAL_BAND_BITS, value)

/*
B0: Indicates STA support 40 MHz channel width in 2.4 GHz
B1: STA supports 40 MHz and 80 MHz channel width in 5 GHz
B2: STA supports 160 MHz channel width in 5 GHz
B3: STA supports 160/80+80 MHz channel width in 5 GHz
B4: If B1 is set to 0, then B5 indicates support of 242/106/52/26-tone
    RU mapping in 40 MHz channel width in 2.4 GHz. Otherwise Reserved.
B5: If B2, B3, and B4 are set to 0, then B6 indicates support of
    242-tone RU mapping in 40 MHz and 80MHz channel width in 5 GHz.
    Otherwise Reserved.
B6: Reserved
*/
#define HECAP_PHY_CBW_GET_FROM_IC(hecap_phy)           \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_CHANNEL_WIDTH_IDX, IC_HECAP_PHY_CHANNEL_WIDTH_BITS)
#define HECAP_PHY_CBW_SET_TO_IC(hecap_phy, value)      \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_CHANNEL_WIDTH_IDX, IC_HECAP_PHY_CHANNEL_WIDTH_BITS, value)

/*
B0: STA supports reception of preamble puncturing in 80 MHz,
    where in the preamble only the secondary 20 MHz is punctured
B1: STA supports reception of preamble puncturing in 80 MHz,
    where in the preamble only one of the two 20 MHz sub-channels
    in the secondary 40 MHz is punctured
B2: STA supports reception of preamble puncturing in 160 MHz or
    80+80 MHz, where in the primary 80 MHz of the preamble only
    the secondary 20 MHz is punctured
B3: Indicates STA supports reception of preamble puncturing in
    160 MHz or 80+80 MHz, where in the primary 80 MHz of the
    preamble, the primary 40 MHz is present
*/
#define HECAP_PHY_PREAMBLEPUNCRX_GET_FROM_IC(hecap_phy)    \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],     \
        IC_HECAP_PHY_PREAMBLE_PUNC_RX_IDX,                 \
        IC_HECAP_PHY_PREAMBLE_PUNC_RX_BITS)
#define HECAP_PHY_PREAMBLEPUNCRX_SET_TO_IC(hecap_phy, value) \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],       \
        IC_HECAP_PHY_PREAMBLE_PUNC_RX_IDX,                   \
        IC_HECAP_PHY_PREAMBLE_PUNC_RX_BITS, value)

/*Indicates transmitting STA is a Class A (1) or a Class B (0) device*/
#define HECAP_PHY_COD_GET_FROM_IC(hecap_phy)           \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_DEVICE_CLASS_IDX, IC_HECAP_PHY_DEVICE_CLASS_BITS)
#define HECAP_PHY_COD_SET_TO_IC(hecap_phy, value)      \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_DEVICE_CLASS_IDX, IC_HECAP_PHY_DEVICE_CLASS_BITS, value)

/*Indicates support of transmission and reception ofLDPC encoded packets*/
#define HECAP_PHY_LDPC_GET_FROM_IC(hecap_phy)          \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_LDPC_IN_PAYLOAD_IDX,              \
        IC_HECAP_PHY_LDPC_IN_PAYLOAD_BITS)
#define HECAP_PHY_LDPC_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_LDPC_IN_PAYLOAD_IDX,              \
        IC_HECAP_PHY_LDPC_IN_PAYLOAD_BITS, value)


/*
B0: Indicates support of reception of 1x LTF and 0.8us guard interval
    duration for HE SU PPDUs.
B1: Indicates support of reception of 1x LTF and 1.6us guard interval
*/
#define HECAP_PHY_SU_1XLTFAND800NSECSGI_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],    \
        IC_HECAP_PHY_LTF_GI_HE_PPDU_IDX, IC_HECAP_PHY_LTF_GI_HE_PPDU_BITS)
#define HECAP_PHY_SU_1XLTFAND800NSECSGI_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],    \
        IC_HECAP_PHY_LTF_GI_HE_PPDU_IDX, IC_HECAP_PHY_LTF_GI_HE_PPDU_BITS, value)

/*
When the Doppler Rx subfield is 1, indicates the maximum
number of space-time streams supported for reception when
midamble is used in the Data field
*/
#if SUPPORT_11AX_D3
#define HECAP_PHY_MIDAMBLETXRXMAXNSTS_GET_FROM_IC(hecap_phy)      \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],          \
        IC_HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX,   \
        IC_HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS)
#define HECAP_PHY_MIDAMBLETXRXMAXNSTS_SET_TO_IC(hecap_phy, value) \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],          \
        IC_HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX,   \
        IC_HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS, value)
#else
#define HECAP_PHY_MIDAMBLERXMAXNSTS_GET_FROM_IC(hecap_phy)      \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],          \
        IC_HECAP_PHY_MIDAMBLERXMAXNSTS_IDX,   \
        IC_HECAP_PHY_MIDAMBLERXMAXNSTS_BITS)
#define HECAP_PHY_MIDAMBLERXMAXNSTS_SET_TO_IC(hecap_phy, value) \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],          \
        IC_HECAP_PHY_MIDAMBLERXMAXNSTS_IDX,   \
        IC_HECAP_PHY_MIDAMBLERXMAXNSTS_BITS, value)
#endif

/*
B0: For a transmitting STA acting as beamformer, it indicates support
    of NDP transmission using 4x LTFand 3.2 us guard interval duration
B1: For a transmitting STA acting as beamformee, it indicates support
    of NDP reception using 4x LTF and 3.2 us guard intervalduration
*/
#define HECAP_PHY_LTFGIFORNDP_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],     \
        IC_HECAP_PHY_LTF_GI_FOR_NDP_IDX, IC_HECAP_PHY_LTF_GI_FOR_NDP_BITS)
#define HECAP_PHY_LTFGIFORNDP_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],     \
        IC_HECAP_PHY_LTF_GI_FOR_NDP_IDX, IC_HECAP_PHY_LTF_GI_FOR_NDP_BITS, value)

/* support for the transmission of HE PPDUs
  using STBC with one spatial stream */
#define HECAP_PHY_TXSTBC_GET_FROM_IC(hecap_phy)          \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],   \
        IC_HECAP_PHY_TX_STBC_IDX, IC_HECAP_PHY_TX_STBC_BITS)
#define HECAP_PHY_TXSTBC_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],   \
        IC_HECAP_PHY_TX_STBC_IDX, IC_HECAP_PHY_TX_STBC_BITS, value)

/* support for the reception of HE PPDUs
   using STBC with one spatial stream */
#define HECAP_PHY_RXSTBC_GET_FROM_IC(hecap_phy)         \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],  \
        IC_HECAP_PHY_RX_STBC_IDX, IC_HECAP_PHY_RX_STBC_BITS)
#define HECAP_PHY_RXSTBC_SET_TO_IC(hecap_phy, value)    \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],  \
        IC_HECAP_PHY_RX_STBC_IDX, IC_HECAP_PHY_RX_STBC_BITS, value)

/* transmitting STA supports transmitting HE PPDUs with Doppler procedure*/
#define HECAP_PHY_TXDOPPLER_GET_FROM_IC(hecap_phy)      \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],  \
        IC_HECAP_PHY_TX_DOPPLER_IDX, IC_HECAP_PHY_TX_DOPPLER_BITS)
#define HECAP_PHY_TXDOPPLER_SET_TO_IC(hecap_phy, value) \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],  \
        IC_HECAP_PHY_TX_DOPPLER_IDX, IC_HECAP_PHY_TX_DOPPLER_BITS, value)

/* transmitting STA supports receiving HE PPDUs with Doppler procedure*/
#define HECAP_PHY_RXDOPPLER_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],   \
        IC_HECAP_PHY_RX_DOPPLER_IDX, IC_HECAP_PHY_RX_DOPPLER_BITS)
#define HECAP_PHY_RXDOPPLER_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],   \
        IC_HECAP_PHY_RX_DOPPLER_IDX, IC_HECAP_PHY_RX_DOPPLER_BITS, value)

/*
If the transmitting STA is an AP: indicates STA supports of reception
of full bandwidth UL MU-MIMO transmission.
If the transmitting STA is a non-AP STA: indicates STA supports of
transmission of full bandwidth UL MU-MIMO transmission.
*/
#define HECAP_PHY_UL_MU_MIMO_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],  \
        IC_HECAP_PHY_UL_MUMIMO_IDX, IC_HECAP_PHY_UL_MUMIMO_BITS)
#define HECAP_PHY_UL_MU_MIMO_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],    \
        IC_HECAP_PHY_UL_MUMIMO_IDX, IC_HECAP_PHY_UL_MUMIMO_BITS, value)

/*
If the transmitting STA is an AP: indicates STA supports of reception
of UL  MUMIMO transmission on an RU in an HE MU PPDU where the RU
does not span the entire PPDU bandwidth.
If the transmitting STA is a non-AP STA: indicates STA supports of
transmission of UL MU-MIMO transmission on an RU in an HE MU PPDU
where the RU does not span the entire PPDU bandwidth.
*/
#define HECAP_PHY_ULOFDMA_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_UL_MUOFDMA_IDX, IC_HECAP_PHY_UL_MUOFDMA_BITS)
#define HECAP_PHY_ULOFDMA_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_UL_MUOFDMA_IDX, IC_HECAP_PHY_UL_MUOFDMA_BITS, value)

/*
Tx DCM- B0:B1-00: Does not support DCM, 01:BPSK , 10: QPSK,
11: 16-QAM . B2 signals maximum number of spatial streams
with DCM 0: 1 spatial stream, 1: 2 spatial
*/
#define HECAP_PHY_DCMTX_GET_FROM_IC(hecap_phy)         \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_DCM_TX_IDX, IC_HECAP_PHY_DCM_TX_BITS)
#define HECAP_PHY_DCMTX_SET_TO_IC(hecap_phy, value)    \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0], \
        IC_HECAP_PHY_DCM_TX_IDX, IC_HECAP_PHY_DCM_TX_BITS, value)

/*
Rx DCM- B0:B1-00: Does not support DCM, 01:BPSK , 10: QPSK,
11: 16-QAM. B2 signals maximum number of spatial streams with
DCM 0: 1 spatial stream, 1: 2 spatial
*/
#define HECAP_PHY_DCMRX_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],\
        IC_HECAP_PHY_DCM_RX_IDX, IC_HECAP_PHY_DCM_RX_BITS)
#define HECAP_PHY_DCMRX_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],\
        IC_HECAP_PHY_DCM_RX_IDX, IC_HECAP_PHY_DCM_RX_BITS, value)

/*
Indicates that the STA supports the reception of an HE MU PPDU
payload over full bandwidth and partial bandwidth (106-tone RU
within 20 MHz).
*/
#define HECAP_PHY_ULHEMU_PPDU_PAYLOAD_GET_FROM_IC(hecap_phy)      \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],            \
        IC_HECAP_PHY_UL_MU_PPDU_PAYLOAD_IDX,                      \
        IC_HECAP_PHY_UL_MU_PPDU_PAYLOAD_BITS)
#define HECAP_PHY_ULHEMU_PPDU_PAYLOAD_SET_TO_IC(hecap_phy, value) \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],            \
        IC_HECAP_PHY_UL_MU_PPDU_PAYLOAD_IDX,                      \
        IC_HECAP_PHY_UL_MU_PPDU_PAYLOAD_BITS, value)

/*Indicates support for operation as an SU beamformer.*/
#define HECAP_PHY_SUBFMR_GET_FROM_IC(hecap_phy)          \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],   \
        IC_HECAP_PHY_SU_BFER_IDX, IC_HECAP_PHY_SU_BFER_BITS)
#define HECAP_PHY_SUBFMR_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX0],   \
        IC_HECAP_PHY_SU_BFER_IDX, IC_HECAP_PHY_SU_BFER_BITS, value)

/*Indicates support for operation as an SU beamformee*/
#define HECAP_PHY_SUBFME_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1], \
        IC_HECAP_PHY_SU_BFEE_IDX, IC_HECAP_PHY_SU_BFEE_BITS)
#define HECAP_PHY_SUBFME_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1], \
        IC_HECAP_PHY_SU_BFEE_IDX, IC_HECAP_PHY_SU_BFEE_BITS, value)

/*Indicates support for operation as an MU Beamformer*/
#define HECAP_PHY_MUBFMR_GET_FROM_IC(hecap_phy)         \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],  \
        IC_HECAP_PHY_MU_BFER_IDX, IC_HECAP_PHY_MU_BFER_BITS)
#define HECAP_PHY_MUBFMR_SET_TO_IC(hecap_phy, value)    \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],  \
        IC_HECAP_PHY_MU_BFER_IDX, IC_HECAP_PHY_MU_BFER_BITS, value)

/*
Num STS -1 for < =80MHz (min val 3) . The maximum number of
space-time streams minus 1 that the STA can receive in an HE NDP
*/
#define HECAP_PHY_BFMENSTSLT80MHZ_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_BFEE_STS_IDX, IC_HECAP_PHY_BFEE_STS_BITS)
#define HECAP_PHY_BFMENSTSLT80MHZ_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_BFEE_STS_IDX, IC_HECAP_PHY_BFEE_STS_BITS, value)

/*
Num STS -1 for >80MHz(min val 3). The maximum number of space-time
streams minus 1 that the STA can receive in an HE NDP
*/
#define HECAP_PHY_BFMENSTSGT80MHZ_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_BFEE_STS_GREATER_80MHZ_IDX,                \
        IC_HECAP_PHY_BFEE_STS_GREATER_80MHZ_BITS)
#define HECAP_PHY_BFMENSTSGT80MHZ_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_BFEE_STS_GREATER_80MHZ_IDX,                \
        IC_HECAP_PHY_BFEE_STS_GREATER_80MHZ_BITS, value)

/*
Number Of Sounding Dimensions For <= 80 MHz.If SU beamformer capable,
set to the maximum supported value of the TXVECTOR parameter
NUM_STS minus 1. Otherwise,reserved
*/
#define HECAP_PHY_NUMSOUNDLT80MHZ_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_LESS_80MHZ_IDX,           \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_LESS_80MHZ_BITS)
#define HECAP_PHY_NUMSOUNDLT80MHZ_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_LESS_80MHZ_IDX,           \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_LESS_80MHZ_BITS, value)

/*
Number Of Sounding Dimensions For > 80 MHz. If SU beamformer capable,
set to the maximum supported value of the TXVECTOR parameter NUM_STS
minus 1. Otherwise,reserved
*/
#define HECAP_PHY_NUMSOUNDGT80MHZ_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_GREAT_80MHZ_IDX,          \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_GREAT_80MHZ_BITS)
#define HECAP_PHY_NUMSOUNDGT80MHZ_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_GREAT_80MHZ_IDX,          \
        IC_HECAP_PHY_NOOF_SOUNDDIMENS_GREAT_80MHZ_BITS, value)

/*
Indicates if the HE beamformee is capable of feedback with tone grouping of
16 in the HE Compressed Beamforming Report field for a SU-type feedback.
*/
#define HECAP_PHY_NG16SUFEEDBACKLT80_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_NG_16_SU_FEEDBACK_IDX,                       \
        IC_HECAP_PHY_NG_16_SU_FEEDBACK_BITS)
#define HECAP_PHY_NG16SUFEEDBACKLT80_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_NG_16_SU_FEEDBACK_IDX,                       \
        IC_HECAP_PHY_NG_16_SU_FEEDBACK_BITS, value)

/*
Indicates if the HE beamformee is capable of feedback with tone grouping
of 16 in the HE Compressed Beamforming Report field for a MU-type feedback
*/
#define HECAP_PHY_NG16MUFEEDBACKGT80_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],             \
        IC_HECAP_PHY_NG_16_MU_FEEDBACK_IDX,                        \
        IC_HECAP_PHY_NG_16_MU_FEEDBACK_BITS)
#define HECAP_PHY_NG16MUFEEDBACKGT80_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],             \
        IC_HECAP_PHY_NG_16_MU_FEEDBACK_IDX,                        \
        IC_HECAP_PHY_NG_16_MU_FEEDBACK_BITS, value)

/*
Indicates if HE beamformee is capable of feedback with codebook size {4, 2}
in the HECompressed Beamforming Report field for a SU-type feedback.
*/
#define HECAP_PHY_CODBK42SU_GET_FROM_IC(hecap_phy)                 \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],             \
        IC_HECAP_PHY_CODEBOOK_SIZE4_2_SU_IDX,                      \
        IC_HECAP_PHY_CODEBOOK_SIZE4_2_SU_BITS)
#define HECAP_PHY_CODBK42SU_SET_TO_IC(hecap_phy, value)            \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],             \
        IC_HECAP_PHY_CODEBOOK_SIZE4_2_SU_IDX,                      \
        IC_HECAP_PHY_CODEBOOK_SIZE4_2_SU_BITS, value)

/*
Indicates if HE beamformee is capable of feedback with codebook size {7, 5}
in the HE Compressed Beamforming Report field for a MU-typefeedback
*/
#define HECAP_PHY_CODBK75MU_GET_FROM_IC(hecap_phy)               \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],           \
        IC_HECAP_PHY_CODEBOOK_SIZE7_5_MU_IDX,                    \
        IC_HECAP_PHY_CODEBOOK_SIZE7_5_MU_BITS)
#define HECAP_PHY_CODBK75MU_SET_TO_IC(hecap_phy, value)          \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],           \
        IC_HECAP_PHY_CODEBOOK_SIZE7_5_MU_IDX,                    \
        IC_HECAP_PHY_CODEBOOK_SIZE7_5_MU_BITS, value)

/*Beamforming Feedback With Trigger Frame
If the transmitting STA is an AP STA:
B0: indicates support of reception of SU-Type partial(1) and full
    bandwidth feedback(0)
B1: indicates support of reception of MU-Type partial(1) bandwidth
    feedback
B2: indicates support of reception of CQI-Only partial and full
    bandwidth feedback
If the transmitting STA is a non-AP STA:
B3: indicates support of transmission of SU-Type partial(1) and
    full bandwidth(0) feedback
B4: indicates support of transmission of MU-Type partial(1) bandwidth
     feedback
B5: indicates support of transmission of CQI-Onlypartial (1)and full
    bandwidth feedback
*/
#define HECAP_PHY_BFFEEDBACKTRIG_GET_FROM_IC(hecap_phy)          \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],           \
        IC_HECAP_PHY_BF_FEEBACK_TRIGGER_IDX,                     \
        IC_HECAP_PHY_BF_FEEBACK_TRIGGER_BITS)
#define HECAP_PHY_BFFEEDBACKTRIG_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],           \
        IC_HECAP_PHY_BF_FEEBACK_TRIGGER_IDX,                     \
        IC_HECAP_PHY_BF_FEEBACK_TRIGGER_BITS, value)

/*
Indicates the support of transmission and reception of an HE
extended range SU PPDU payload transmitted over the right 106-tone RU
*/
#define HECAP_PHY_HEERSU_GET_FROM_IC(hecap_phy)            \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],     \
        IC_HECAP_PHY_ER_SU_PPDU_PAYLOAD_IDX,               \
        IC_HECAP_PHY_ER_SU_PPDU_PAYLOAD_BITS)
#define HECAP_PHY_HEERSU_SET_TO_IC(hecap_phy, value)       \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],     \
        IC_HECAP_PHY_ER_SU_PPDU_PAYLOAD_IDX,               \
        IC_HECAP_PHY_ER_SU_PPDU_PAYLOAD_BITS, value)

/*
Indicates that the non-AP STA supports reception of a DL
MU-MIMO transmission on an RU in an HE MU PPDU where the
RU does not span the entire PPDU bandwidth.
*/
#define HECAP_PHY_DLMUMIMOPARTIALBW_GET_FROM_IC(hecap_phy)    \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],        \
        IC_HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_IDX,               \
        IC_HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_BITS)
#define HECAP_PHY_DLMUMIMOPARTIALBW_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],           \
        IC_HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_IDX,                  \
        IC_HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_BITS, value)

/*Indicates whether or not the PPE Threshold field is present*/
#define HECAP_PHY_PPETHRESPRESENT_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_PPET_THRESHOLD_PRESENT_IDX,                \
        IC_HECAP_PHY_PPET_THRESHOLD_PRESENT_BITS)
#define HECAP_PHY_PPETHRESPRESENT_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],          \
        IC_HECAP_PHY_PPET_THRESHOLD_PRESENT_IDX,                \
        IC_HECAP_PHY_PPET_THRESHOLD_PRESENT_BITS, value)

/*Indicates that the STA supports SRP-based SR operation*/
#define HECAP_PHY_SRPSPRESENT_GET_FROM_IC(hecap_phy)      \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],    \
        IC_HECAP_PHY_SRP_SR_IDX, IC_HECAP_PHY_SRP_SR_BITS)
#define HECAP_PHY_SRPPRESENT_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],    \
        IC_HECAP_PHY_SRP_SR_IDX, IC_HECAP_PHY_SRP_SR_BITS, value)

/*
Indicates that the STA supports a power boost factor
alpha-r for the r-th RU in the range [0.5, 2]
*/
#define HECAP_PHY_PWRBOOSTAR_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],  \
        IC_HECAP_PHY_POWER_BOOST_AR_IDX,                \
        IC_HECAP_PHY_POWER_BOOST_AR_BITS)
#define HECAP_PHY_PWRBOOSTAR_SET_TO_IC(hecap_phy, value) \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],   \
        IC_HECAP_PHY_POWER_BOOST_AR_IDX,                 \
        IC_HECAP_PHY_POWER_BOOST_AR_BITS, value)

/*
Indicates support for the reception of 4x LTF and 0.8us
guard interval duration for HE SU PPDUs.
*/
#define HECAP_PHY_4XLTFAND800NSECSGI_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_4X_LTF_0_8_GI_IDX, IC_HECAP_PHY_4X_LTF_0_8_GI_BITS)
#define HECAP_PHY_4XLTFAND800NSECSGI_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_4X_LTF_0_8_GI_IDX, IC_HECAP_PHY_4X_LTF_0_8_GI_BITS, value)

/*
For a transmitting STA acting as a beamformee, it indicates
the maximum Nc for beamforming sounding feedback supported.
If SU beamformee capable, then set to the maximum Nc for
beamforming sounding feedback minus 1. Otherwise, reserved.
*/
#define HECAP_PHY_MAX_NC_GET_FROM_IC(hecap_phy)                   \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_MAX_NC_IDX, IC_HECAP_PHY_MAX_NC_BITS)
#define HECAP_PHY_MAX_NC_SET_TO_IC(hecap_phy, value)              \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_MAX_NC_IDX, IC_HECAP_PHY_MAX_NC_BITS, value)

/*
Indicates support for the transmission of an HE PPDU that
has a bandwidth greater than 80 MHz and is using STBC with
one spatial stream
*/
#define HECAP_PHY_STBCTXGT80_GET_FROM_IC(hecap_phy)               \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_STBC_TX_GREATER_80MHZ_IDX,                   \
        IC_HECAP_PHY_STBC_TX_GREATER_80MHZ_BITS)
#define HECAP_PHY_STBCTXGT80_SET_TO_IC(hecap_phy, value)          \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_STBC_TX_GREATER_80MHZ_IDX,                   \
        IC_HECAP_PHY_STBC_TX_GREATER_80MHZ_BITS, value)

/*
Indicates support for the reception of an HE PPDU that
has a bandwidth greater than 80 MHz and is using STBC with
one spatial stream
*/
#define HECAP_PHY_STBCRXGT80_GET_FROM_IC(hecap_phy)               \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_STBC_RX_GREATER_80MHZ_IDX,                   \
        IC_HECAP_PHY_STBC_RX_GREATER_80MHZ_BITS)
#define HECAP_PHY_STBCRXGT80_SET_TO_IC(hecap_phy, value)          \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX1],            \
        IC_HECAP_PHY_STBC_RX_GREATER_80MHZ_IDX,                   \
        IC_HECAP_PHY_STBC_RX_GREATER_80MHZ_BITS, value)

/* Indicates support for the reception of an HE ER SU PPDU
with 4x LTF and 0.8 us guard interval duration
*/
#define HECAP_PHY_ERSU_4XLTF800NSGI_GET_FROM_IC(hecap_phy)        \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],            \
        IC_HECAP_PHY_ERSU_4X_LTF_800_NS_GI_IDX,                   \
        IC_HECAP_PHY_ERSU_4X_LTF_800_NS_GI_BITS)
#define HECAP_PHY_ERSU_4XLTF800NSGI_SET_TO_IC(hecap_phy, value)   \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],            \
        IC_HECAP_PHY_ERSU_4X_LTF_800_NS_GI_IDX,                   \
        IC_HECAP_PHY_ERSU_4X_LTF_800_NS_GI_BITS, value)


/* Indicates support of 26-, 52-, and 106-tone mapping for
a 20 MHz operating non-AP HE STA that is the receiver of a
40 MHz HE MU PPDU in 2.4 GHz band, or the transmitter of a
40 MHz HE TB PPDU in 2.4GHz band.
*/
#define HECAP_PHY_HEPPDU20IN40MHZ2G_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],           \
        IC_HECAP_PHY_HEPPDU_20_IN_40MHZ2G_IDX,                   \
        IC_HECAP_PHY_HEPPDU_20_IN_40MHZ2G_BITS)
#define HECAP_PHY_HEPPDU20IN40MHZ2G_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],           \
        IC_HECAP_PHY_HEPPDU_20_IN_40MHZ2G_IDX,                   \
        IC_HECAP_PHY_HEPPDU_20_IN_40MHZ2G_BITS, value)

/* Indicates support of 26-, 52-, and 106-tone mapping for
a 20 MHz operating non-AP HE STA that is the receiver of a
80+80 MHz or a 160 MHz HE MU PPDU, or the transmitter of a
80+80 MHz or 160 MHz HE TB PPDU.
*/
#define HECAP_PHY_HEPPDU20IN160OR80P80MHZ_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                 \
        IC_HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_IDX,                 \
        IC_HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_BITS)
#define HECAP_PHY_HEPPDU20IN160OR80P80MHZ_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                 \
        IC_HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_IDX,                 \
        IC_HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_BITS, value)

/* Indicates supports of 160 MHz OFDMA for a non-AP HE STA
that sets bit B1 of Channel Width Set to 1, and sets B2 and
B3 of Channel Width Set each to 0, when operating with 80 MHz
channel width. The capability bit is applicable while receiving
a 80+80 MHz or a 160 MHz HE MU PPDU, or transmitting a 80+80 MHz
or a 160 MHz HE TB PPDU.
*/
#define HECAP_PHY_HEPPDU80IN160OR80P80MHZ_GET_FROM_IC(hecap_phy)       \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                 \
        IC_HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_IDX,                 \
        IC_HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_BITS)
#define HECAP_PHY_HEPPDU80IN160OR80P80MHZ_SET_TO_IC(hecap_phy, value)  \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                 \
        IC_HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_IDX,                 \
        IC_HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_BITS, value)

/* Indicates support for the reception of an HE ER SU PPDU
with 1x LTF and 0.8 us guard interval duration
*/
#define HECAP_PHY_ERSU1XLTF800NSGI_GET_FROM_IC(hecap_phy)              \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                 \
        IC_HECAP_PHY_ERSU_1X_LTF_800_NS_GI_IDX,                        \
        IC_HECAP_PHY_ERSU_1X_LTF_800_NS_GI_BITS)
#define HECAP_PHY_ERSU1XLTF800NSGI_SET_TO_IC(hecap_phy, value)         \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                 \
        IC_HECAP_PHY_ERSU_1X_LTF_800_NS_GI_IDX,                        \
        IC_HECAP_PHY_ERSU_1X_LTF_800_NS_GI_BITS, value)

#if SUPPORT_11AX_D3
/* When the Doppler Tx/Rx subfield is 1, indicates support
for receiving midambles with 2x HE-LTF, 1x HE-LTF in HE
SU PPDU if the HE SU PPDU With 1x HE-LTF And 0.8s GI
subfield is set to 1, and 1x HE-LTF in HE ER SU PPDU if
the HE ER SU PPDU With 1x HELTF And 0.8 s GI subfield is
set to 1; and also support for transmitting midambles with
2x HE-LTF, 1x HE-LTF in HE TB PPDU when allowed.
*/
#define HECAP_PHY_MIDAMBLETXRX2XAND1XLTF_GET_FROM_IC(hecap_phy)         \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                  \
        IC_HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_IDX,                     \
        IC_HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_BITS)
#define HECAP_PHY_MIDAMBLETXRX2XAND1XLTF_SET_TO_IC(hecap_phy, value)    \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                  \
        IC_HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_IDX,                     \
        IC_HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_BITS, value)
#else
/* When the Doppler Rx subfield is 1, indicates support
for receiving midambles with 2x HE-LTF, 1x HE-LTF in HE
SU PPDU if the HE SU PPDU With 1x HE-LTF And 0.8s GI
subfield is set to 1, and 1x HE-LTF in HE ER SU PPDU if
the HE ER SU PPDU With 1x HELTF And 0.8 s GI subfield is
set to 1.
*/
#define HECAP_PHY_MIDAMBLERX2XAND1XLTF_GET_FROM_IC(hecap_phy)           \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                  \
        IC_HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_IDX,                       \
        IC_HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_BITS)
#define HECAP_PHY_MIDAMBLERX2XAND1XLTF_SET_TO_IC(hecap_phy, value)    \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],                  \
        IC_HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_IDX,                       \
        IC_HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_BITS, value)
#endif

#if SUPPORT_11AX_D3

/* DCM Max BW - When the DCM Max Constellation Tx subfield is greater
 * than 0, then the DCM Max BW subfield indicates the maximum bandwidth of a
 * PPDU that the STA might transmit with DCM applied. When the the DCM Max
 * Constellation Rx subfield is greater than 0, then the DCM Max BW subfield
 * indicates the maximum bandwidth of a PPDU with DCM applied that the STA
 * can receive.
 */
#define HECAP_PHY_DCMMAXBW_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_DCM_MAXBW_IDX, IC_HECAP_PHY_DCM_MAXBW_BITS)
#define HECAP_PHY_DCMMAXBW_SET_TO_IC(hecap_phy, value)             \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_DCM_MAXBW_IDX, IC_HECAP_PHY_DCM_MAXBW_BITS, value)

/* Longer Than 16 HE SIG-B OFDM Symbols Support - For a non-AP STA,
 * indicates support for receiving a DL HE MU PPDU where the number of OFDM
 * symbols in the HE SIG-B field is greater than 16.
 */
#define HECAP_PHY_LT16HESIGBOFDMSYM_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_LT16_HESIGB_OFDM_SYM_IDX,              \
        IC_HECAP_PHY_LT16_HESIGB_OFDM_SYM_BITS)
#define HECAP_PHY_LT16HESIGBOFDMSYM_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_LT16_HESIGB_OFDM_SYM_IDX,              \
        IC_HECAP_PHY_LT16_HESIGB_OFDM_SYM_BITS, value)

/* Non- Triggered CQI Feedback - For an AP, indicates support for the
 * reception of full bandwidth non-triggered CQI-only feedback. For a non-AP
 * STA, indicates support for the transmission of full bandwidth non-triggered
 * CQI-only feedback.
 */
#define HECAP_PHY_NONTRIGCQIFDBK_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_NON_TRIG_CQI_FDBK_IDX,                 \
        IC_HECAP_PHY_NON_TRIG_CQI_FDBK_BITS)
#define HECAP_PHY_NONTRIGCQIFDBK_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_NON_TRIG_CQI_FDBK_IDX,                 \
        IC_HECAP_PHY_NON_TRIG_CQI_FDBK_BITS, value)

/* Tx 1024- QAM < 242-tone RU Support - For a non-AP STA, indicates support
 * for transmitting 1024-QAM on a 26-, 52-, and 106-tone RU. Reserved for an AP.
 */
#define HECAP_PHY_TX1024QAMLT242TONERU_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_TX_1024QAM_LT_242TONE_RU_IDX,                 \
        IC_HECAP_PHY_TX_1024QAM_LT_242TONE_RU_BITS)
#define HECAP_PHY_TX1024QAMLT242TONERU_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_TX_1024QAM_LT_242TONE_RU_IDX,                 \
        IC_HECAP_PHY_TX_1024QAM_LT_242TONE_RU_BITS, value)

/* Rx 1024- QAM < 242-tone RU Support - Indicates support fro receiving
 * 1024-QAM on a 26-, 52-, and 106-tone RU.
 */
#define HECAP_PHY_RX1024QAMLT242TONERU_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_RX_1024QAM_LT_242TONE_RU_IDX,                 \
        IC_HECAP_PHY_RX_1024QAM_LT_242TONE_RU_BITS)
#define HECAP_PHY_RX1024QAMLT242TONERU_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_RX_1024QAM_LT_242TONE_RU_IDX,                 \
        IC_HECAP_PHY_RX_1024QAM_LT_242TONE_RU_BITS, value)

/* Rx Full BW SU Using HE MU PPDU With Compressed SIGB - Indicates support
 * for reception of an HE MU PPDU with an RU spanning the entire PPDU bandwidth
 * and a compressed HE-SIG-B format.
 */
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_COMPSIGB_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_IDX,        \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_BITS)
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_COMPSIGB_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_IDX,                 \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_BITS, value)

/* Rx Full BW SU Using HE MU PPDU With Non-Compressed SIGB - Indicates support
 * for reception of an HE MU PPDU with a bandwidth less than or equal to 80 MHz,
 * an RU spanning the entire PPDU bandwidth and a non-compressed HE-SIG-B format.
 */
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_NONCOMPSIGB_GET_FROM_IC(hecap_phy)     \
        HE_GET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_IDX,        \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_BITS)
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_NONCOMPSIGB_SET_TO_IC(hecap_phy, value)     \
        HE_SET_BITS(hecap_phy[IC_HECAP_PHYDWORD_IDX2],      \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_IDX,                 \
        IC_HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_BITS, value)

#endif

/*
HE capabilities , get/set to IE as per draft
standard,  this may change until draft gets evolved
*/

#if !SUPPORT_11AX_D3
/*Dual Band both 2.4 GHz and 5 GHz Supported*/
#define HECAP_PHY_DB_GET_FROM_IE(hecap_phy)         \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX0], \
        HECAP_PHY_DUAL_BAND_IDX, HECAP_PHY_DUAL_BAND_BITS)
#define HECAP_PHY_DB_SET_TO_IE(hecap_phy, value)    \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX0], \
        HECAP_PHY_DUAL_BAND_IDX, HECAP_PHY_DUAL_BAND_BITS, value)
#endif

/*
B0: Indicates STA support 40 MHz channel width in 2.4 GHz
B1: Indicates STA support 40 MHz and 80 MHz channel width in 5 GHz
B2: Indicates STA supports 160 MHz channel width in 5 GHz
B3: Indicates STA supports 160/80+80 MHz channel width in 5 GHz
B4: If B1 is set to 0, then B5 indicates support of 242/106/52/26-tone
    RU mapping in 40 MHz channel width in 2.4 GHz. Otherwise Reserved.
B5: If B2, B3, and B4 are set to 0, then B6 indicates support of 242-tone
     RU mapping in 40 MHz and 80MHz channel width in 5 GHz. Otherwise Reserved.
B6: Reserved
*/
#define HECAP_PHY_CBW_GET_FROM_IE(hecap_phy)                 \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX0],          \
        HECAP_PHY_CHANNEL_WIDTH_IDX, HECAP_PHY_CHANNEL_WIDTH_BITS)
#define HECAP_PHY_CBW_SET_TO_IE(hecap_phy, value)            \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX0],          \
        HECAP_PHY_CHANNEL_WIDTH_IDX, HECAP_PHY_CHANNEL_WIDTH_BITS, value)

/*
B0: Indicates STA supports reception of preamble puncturing in 80 MHz,
    where in the preamble only the secondary 20 MHz is punctured
B1: Indicates STA supports reception of preamble puncturing in 80 MHz,
    where in the preamble only one of the two 20 MHz sub-channels in the secondary
    40 MHz is punctured
B2: Indicates STA supports reception of preamble puncturing in 160 MHz or 80+80 MHz,
     where in the primary 80 MHz of the preamble only the secondary 20 MHz is punctured
B3: Indicates STA supports reception of preamble puncturing in 160 MHz or 80+80 MHz,
    where in the primary 80 MHz of the preamble, the primary 40 MHz is present
*/
#define HECAP_PHY_PREAMBLEPUNCRX_GET_FROM_IE(hecap_phy)          \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX1],              \
        HECAP_PHY_PREAMBLE_PUNC_RX_IDX, HECAP_PHY_PREAMBLE_PUNC_RX_BITS)
#define HECAP_PHY_PREAMBLEPUNCRX_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX1],              \
        HECAP_PHY_PREAMBLE_PUNC_RX_IDX, HECAP_PHY_PREAMBLE_PUNC_RX_BITS, value)

/*Indicates transmitting STA is a Class A (1) or a Class B (0) device*/
#define HECAP_PHY_COD_GET_FROM_IE(hecap_phy)                  \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX1],           \
        HECAP_PHY_DEVICE_CLASS_IDX, HECAP_PHY_DEVICE_CLASS_BITS)
#define HECAP_PHY_COD_SET_TO_IE(hecap_phy, value)             \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX1],           \
        HECAP_PHY_DEVICE_CLASS_IDX, HECAP_PHY_DEVICE_CLASS_BITS, value)

/*Indicates support of transmission and reception of LDPC encoded packets*/
#define HECAP_PHY_LDPC_GET_FROM_IE(hecap_phy)                 \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX1],           \
        HECAP_PHY_LDPC_IN_PAYLOAD_IDX, HECAP_PHY_LDPC_IN_PAYLOAD_BITS)
#define HECAP_PHY_LDPC_SET_TO_IE(hecap_phy, value)            \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX1],           \
        HECAP_PHY_LDPC_IN_PAYLOAD_IDX, HECAP_PHY_LDPC_IN_PAYLOAD_BITS, value)

/*
B0: Indicates support of reception of 1x LTF and 0.8us guard interval
    duration for HE SU PPDUs.
B1: Indicates support of reception of 1x LTF and 1.6us guard interval
*/
#define HECAP_PHY_SU_1XLTFAND800NSECSGI_GET_FROM_IE(hecap_phy)            \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX1],            \
        HECAP_PHY_LTF_GI_HE_PPDU_IDX, HECAP_PHY_LTF_GI_HE_PPDU_BITS)
#define HECAP_PHY_SU_1XLTFAND800NSECSGI_SET_TO_IE(hecap_phy, value)       \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX1],            \
        HECAP_PHY_LTF_GI_HE_PPDU_IDX, HECAP_PHY_LTF_GI_HE_PPDU_BITS, value)

#if SUPPORT_11AX_D3
/* When both Doppler Rx and Doppler Tx subfields are 1,
 * indicates the maximum number of space-time streams
 * supported for transmission and reception when a midamble
 * is present in the Data field.
 */
#define HECAP_PHY_MIDAMBLETXRXMAXNSTS_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX1],            \
        HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX,                       \
                HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS - 1) |         \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],            \
        HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX + 1,                   \
                HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS - 1) << 1
#define HECAP_PHY_MIDAMBLETXRXMAXNSTS_SET_TO_IE(hecap_phy, value) do{        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX1],                        \
        HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX,                                   \
                HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS - 1, value & 0x1);        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],                        \
        HECAP_PHY_MIDAMBLETXRXMAXNSTS_IDX + 1,                               \
                HECAP_PHY_MIDAMBLETXRXMAXNSTS_BITS - 1, (value & 0x2) >> 1); \
} while(0)
#else
/*
When the Doppler Rx subfield is 1, indicates the maximum
number of space-time streams supported for reception when
midamble is used in the Data field
*/
#define HECAP_PHY_MIDAMBLERXMAXNSTS_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX1],            \
        HECAP_PHY_MIDAMBLERXMAXNSTS_IDX,                       \
                HECAP_PHY_MIDAMBLERXMAXNSTS_BITS - 1) |         \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],            \
        HECAP_PHY_MIDAMBLERXMAXNSTS_IDX + 1,                   \
                HECAP_PHY_MIDAMBLERXMAXNSTS_BITS - 1) << 1
#define HECAP_PHY_MIDAMBLERXMAXNSTS_SET_TO_IE(hecap_phy, value) do{        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX1],                        \
        HECAP_PHY_MIDAMBLERXMAXNSTS_IDX,                                   \
                HECAP_PHY_MIDAMBLERXMAXNSTS_BITS - 1, value & 0x1);        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],                        \
        HECAP_PHY_MIDAMBLERXMAXNSTS_IDX + 1,                               \
                HECAP_PHY_MIDAMBLERXMAXNSTS_BITS - 1, (value & 0x2) >> 1); \
} while(0)
#endif

/*
B0: For a transmitting STA acting as beamformer, it indicates support of
    NDP transmission using 4x LTFand 3.2 us guard interval duration
B1: For a transmitting STA acting as beamformee, it indicates support of
    NDP reception using 4x LTF and 3.2 us guard intervalduration
*/
#define HECAP_PHY_LTFGIFORNDP_GET_FROM_IE(hecap_phy)           \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],            \
        HECAP_PHY_LTF_GI_FOR_NDP_IDX, HECAP_PHY_LTF_GI_FOR_NDP_BITS)
#define HECAP_PHY_LTFGIFORNDP_SET_TO_IE(hecap_phy, value)      \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],            \
        HECAP_PHY_LTF_GI_FOR_NDP_IDX, HECAP_PHY_LTF_GI_FOR_NDP_BITS, value)

/*indicates support for the transmission of HE PPDUs using STBC with one spatial stream*/
#define HECAP_PHY_TXSTBC_GET_FROM_IE(hecap_phy)             \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],         \
        HECAP_PHY_STBC_TX_IDX, HECAP_PHY_STBC_TX_BITS)
#define HECAP_PHY_TXSTBC_SET_TO_IE(hecap_phy, value)        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],         \
        HECAP_PHY_STBC_TX_IDX, HECAP_PHY_STBC_TX_BITS, value)

/*indicates support for the reception of HE PPDUs using STBC with one spatial stream*/
#define HECAP_PHY_RXSTBC_GET_FROM_IE(hecap_phy)          \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],      \
        HECAP_PHY_STBC_RX_IDX, HECAP_PHY_STBC_RX_BITS)
#define HECAP_PHY_RXSTBC_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],      \
        HECAP_PHY_STBC_RX_IDX, HECAP_PHY_STBC_RX_BITS, value)

/* indicates transmitting STA supports transmitting HE PPDUs with Doppler procedure*/
#define HECAP_PHY_TXDOPPLER_GET_FROM_IE(hecap_phy)        \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],       \
        HECAP_PHY_DOPPLER_TX_IDX, HECAP_PHY_DOPPLER_TX_BITS)
#define HECAP_PHY_TXDOPPLER_SET_TO_IE(hecap_phy, value)   \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],       \
        HECAP_PHY_DOPPLER_TX_IDX, HECAP_PHY_DOPPLER_TX_BITS, value)

/*indicates transmitting STA supports receiving HE PPDUs with Doppler procedure*/
#define HECAP_PHY_RXDOPPLER_GET_FROM_IE(hecap_phy)        \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],       \
        HECAP_PHY_DOPPLER_RX_IDX, HECAP_PHY_DOPPLER_RX_BITS)
#define HECAP_PHY_RXDOPPLER_SET_TO_IE(hecap_phy, value)   \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],       \
        HECAP_PHY_DOPPLER_RX_IDX, HECAP_PHY_DOPPLER_RX_BITS, value)

/*
If the transmitting STA is an AP: indicates STA supports of reception
of full bandwidth UL MU-MIMO transmission.
If the transmitting STA is a non-AP STA: indicates STA supports of
transmission of full bandwidth UL MU-MIMO transmission.
*/
#define HECAP_PHY_UL_MU_MIMO_GET_FROM_IE(hecap_phy)        \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],        \
        HECAP_PHY_UL_MUMIMO_IDX, HECAP_PHY_UL_MUMIMO_BITS)
#define HECAP_PHY_UL_MU_MIMO_SET_TO_IE(hecap_phy, value)   \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],        \
        HECAP_PHY_UL_MUMIMO_IDX, HECAP_PHY_UL_MUMIMO_BITS, value)

/*
If the transmitting STA is an AP: indicates STA supports of reception of UL
MUMIMO transmission on an RU in an HE MU PPDU where the RU does not span the
entire PPDU bandwidth.
If the transmitting STA is a non-AP STA: indicates STA supports of transmission
of UL MU-MIMO transmission on an RU in an HE MU PPDU where the RU does not span
the entire PPDU bandwidth.
*/
#define HECAP_PHY_ULOFDMA_GET_FROM_IE(hecap_phy)           \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX2],        \
        HECAP_PHY_UL_MUOFDMA_IDX, HECAP_PHY_UL_MUOFDMA_BITS)
#define HECAP_PHY_ULOFDMA_SET_TO_IE(hecap_phy, value)      \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX2],        \
        HECAP_PHY_UL_MUOFDMA_IDX, HECAP_PHY_UL_MUOFDMA_BITS, value)

/*
Tx DCM- B0:B1-00: Does not support DCM, 01:BPSK , 10: QPSK,
11: 16-QAM. B2 signals maximum number of spatial streams with
DCM 0: 1 spatial stream, 1: 2 spatial
*/
#define HECAP_PHY_DCMTX_GET_FROM_IE(hecap_phy)         \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX3],    \
        HECAP_PHY_DCM_TX_IDX, HECAP_PHY_DCM_TX_BITS)
#define HECAP_PHY_DCMTX_SET_TO_IE(hecap_phy, value)    \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX3],    \
        HECAP_PHY_DCM_TX_IDX, HECAP_PHY_DCM_TX_BITS, value)

/*
Rx DCM- B0:B1-00: Does not support DCM, 01:BPSK , 10: QPSK,
11: 16-QAM. B2 signals maximum number of spatial streams with
DCM 0: 1 spatial stream, 1: 2 spatial
*/
#define HECAP_PHY_DCMRX_GET_FROM_IE(hecap_phy)         \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX3],    \
        HECAP_PHY_DCM_RX_IDX, HECAP_PHY_DCM_RX_BITS)
#define HECAP_PHY_DCMRX_SET_TO_IE(hecap_phy, value)    \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX3],    \
        HECAP_PHY_DCM_RX_IDX, HECAP_PHY_DCM_RX_BITS, value)

/*
Indicates that the STA supports the reception of an HE MU PPDU
payload over full bandwidth and partial bandwidth (106-tone RU
within 20 MHz).
*/
#define HECAP_PHY_ULHEMU_PPDU_PAYLOAD_GET_FROM_IE(hecap_phy)       \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX3],                \
        HECAP_PHY_UL_MU_PPDU_PAYLOAD_IDX, HECAP_PHY_UL_MU_PPDU_PAYLOAD_BITS)
#define HECAP_PHY_ULHEMU_PPDU_PAYLOAD_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX3],                \
        HECAP_PHY_UL_MU_PPDU_PAYLOAD_IDX, HECAP_PHY_UL_MU_PPDU_PAYLOAD_BITS, value)

/*Indicates support for operation as an SU beamformer.*/
#define HECAP_PHY_SUBFMR_GET_FROM_IE(hecap_phy)              \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX3],          \
        HECAP_PHY_SU_BFER_IDX, HECAP_PHY_SU_BFER_BITS)
#define HECAP_PHY_SUBFMR_SET_TO_IE(hecap_phy, value)         \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX3],          \
        HECAP_PHY_SU_BFER_IDX, HECAP_PHY_SU_BFER_BITS, value)

/*Indicates support for operation as an SU beamformee*/
#define HECAP_PHY_SUBFME_GET_FROM_IE(hecap_phy)             \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX4],         \
        HECAP_PHY_SU_BFEE_IDX, HECAP_PHY_SU_BFEE_BITS)
#define HECAP_PHY_SUBFME_SET_TO_IE(hecap_phy, value)        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX4],         \
        HECAP_PHY_SU_BFEE_IDX, HECAP_PHY_SU_BFEE_BITS, value)

/*Indicates support for operation as an MU Beamformer*/
#define HECAP_PHY_MUBFMR_GET_FROM_IE(hecap_phy)             \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX4],         \
        HECAP_PHY_MU_BFER_IDX, HECAP_PHY_MU_BFER_BITS)
#define HECAP_PHY_MUBFMR_SET_TO_IE(hecap_phy, value)        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX4],         \
        HECAP_PHY_MU_BFER_IDX, HECAP_PHY_MU_BFER_BITS, value)

/*
Num STS -1 for < =80MHz (min val 3). The maximum number of space-time
streams minus 1 that the STA can receive in an HE NDP
*/
#define HECAP_PHY_BFMENSTSLT80MHZ_GET_FROM_IE(hecap_phy)       \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX4],            \
        HECAP_PHY_BFEE_STS_LESS_OR_EQ_80MHZ_IDX,               \
        HECAP_PHY_BFEE_STS_LESS_OR_EQ_80MHZ_BITS)
#define HECAP_PHY_BFMENSTSLT80MHZ_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX4],            \
        HECAP_PHY_BFEE_STS_LESS_OR_EQ_80MHZ_IDX,               \
        HECAP_PHY_BFEE_STS_LESS_OR_EQ_80MHZ_BITS, value)

/*
Num STS -1 for >80MHz(min val 3). The maximum number of space-time streams
minus 1 that the STA can receive in an HE NDP
*/
#define HECAP_PHY_BFMENSTSGT80MHZ_GET_FROM_IE(hecap_phy)            \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX4],                 \
        HECAP_PHY_BFEE_STS_GREATER_80MHZ_IDX,                       \
        HECAP_PHY_BFEE_STS_GREATER_80MHZ_BITS)
#define HECAP_PHY_BFMENSTSGT80MHZ_SET_TO_IE(hecap_phy, value)       \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX4],                 \
        HECAP_PHY_BFEE_STS_GREATER_80MHZ_IDX,                       \
        HECAP_PHY_BFEE_STS_GREATER_80MHZ_BITS, value)

/*
Number Of Sounding Dimensions For <= 80 MHz. If SU beamformer capable,
set to the maximum supported value of the TXVECTOR parameter NUM_STS
minus 1. Otherwise,reserved
*/
#define HECAP_PHY_NUMSOUNDLT80MHZ_GET_FROM_IE(hecap_phy)              \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX5],                   \
        HECAP_PHY_NOOF_SOUNDDIM_LESS_OR_EQ_80MHZ_IDX,                 \
        HECAP_PHY_NOOF_SOUNDDIM_LESS_OR_EQ_80MHZ_BITS)
#define HECAP_PHY_NUMSOUNDLT80MHZ_SET_TO_IE(hecap_phy, value)         \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX5],                   \
        HECAP_PHY_NOOF_SOUNDDIM_LESS_OR_EQ_80MHZ_IDX,                 \
        HECAP_PHY_NOOF_SOUNDDIM_LESS_OR_EQ_80MHZ_BITS, value)

/*
Number Of Sounding Dimensions For > 80 MHz . If SU beamformer capable,
set to the maximum supported value of the TXVECTOR parameter NUM_STS
minus 1. Otherwise,reserved
*/
#define HECAP_PHY_NUMSOUNDGT80MHZ_GET_FROM_IE(hecap_phy)           \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX5],                \
        HECAP_PHY_NOOF_SOUNDDIM_GREAT_80MHZ_IDX,                   \
        HECAP_PHY_NOOF_SOUNDDIM_GREAT_80MHZ_BITS)
#define HECAP_PHY_NUMSOUNDGT80MHZ_SET_TO_IE(hecap_phy, value)      \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX5],                \
        HECAP_PHY_NOOF_SOUNDDIM_GREAT_80MHZ_IDX,                   \
        HECAP_PHY_NOOF_SOUNDDIM_GREAT_80MHZ_BITS, value)

/*
Indicates if the HE beamformee is capable of feedback with tone grouping
of 16 in the HE Compressed Beamforming Report field for a SU-type feedback.
*/
#define HECAP_PHY_NG16SUFEEDBACKLT80_GET_FROM_IE(hecap_phy)         \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX5],                 \
        HECAP_PHY_NG_16_SU_FEEDBACK_IDX, HECAP_PHY_NG_16_SU_FEEDBACK_BITS)
#define HECAP_PHY_NG16SUFEEDBACKLT80_SET_TO_IE(hecap_phy, value)    \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX5],                 \
        HECAP_PHY_NG_16_SU_FEEDBACK_IDX, HECAP_PHY_NG_16_SU_FEEDBACK_BITS, value)

/*
Indicates if the HE beamformee is capable of feedback with tone grouping of
16 in the HE Compressed Beamforming Report field for a MU-type feedback
*/
#define HECAP_PHY_NG16MUFEEDBACKGT80_GET_FROM_IE(hecap_phy)          \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX5],                  \
        HECAP_PHY_NG_16_MU_FEEDBACK_IDX, HECAP_PHY_NG_16_MU_FEEDBACK_BITS)
#define HECAP_PHY_NG16MUFEEDBACKGT80_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX5],                  \
        HECAP_PHY_NG_16_MU_FEEDBACK_IDX, HECAP_PHY_NG_16_MU_FEEDBACK_BITS, value)

/*
Indicates if HE beamformee is capable of feedback with codebook size {4, 2}
in the HECompressed Beamforming Report field for a SU-type feedback.
*/
#define HECAP_PHY_CODBK42SU_GET_FROM_IE(hecap_phy)                    \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX6],                   \
        HECAP_PHY_CODEBOOK_SIZE4_2_SU_IDX,                            \
        HECAP_PHY_CODEBOOK_SIZE4_2_SU_BITS)
#define HECAP_PHY_CODBK42SU_SET_TO_IE(hecap_phy, value)               \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX6],                   \
        HECAP_PHY_CODEBOOK_SIZE4_2_SU_IDX,                            \
        HECAP_PHY_CODEBOOK_SIZE4_2_SU_BITS, value)

/*
Indicates if HE beamformee is capable of feedback with codebook size {7, 5}
in the HE Compressed Beamforming Report field for a MU-typefeedback
*/
#define HECAP_PHY_CODBK75MU_GET_FROM_IE(hecap_phy)                     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX6],                    \
        HECAP_PHY_CODEBOOK_SIZE7_5_MU_IDX,                             \
        HECAP_PHY_CODEBOOK_SIZE7_5_MU_BITS)
#define HECAP_PHY_CODBK75MU_SET_TO_IE(hecap_phy, value)                \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX6],                    \
        HECAP_PHY_CODEBOOK_SIZE7_5_MU_IDX,                             \
        HECAP_PHY_CODEBOOK_SIZE7_5_MU_BITS, value)

/*
Beamforming Feedback With Trigger Frame.
If the transmitting STA is an AP STA:
B0: support of reception of SU-Type partial(1) and full bandwidth
    feedback(0)
B1: support of reception of MU-Type partial(1) bandwidth feedback
B2: support of reception of CQI-Only partial and full bandwidth
    feedback
If the transmitting STA is a non-AP STA:
B3: support of transmission of SU-Type partial(1) and full bandwidth(0)
    feedback
B4: support of transmission of MU-Type partial(1) bandwidth feedback
B5: support of transmission of CQI-Onlypartial (1)and full bandwidth
    feedback
*/
#define HECAP_PHY_BFFEEDBACKTRIG_GET_FROM_IE(hecap_phy)           \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX6],               \
        HECAP_PHY_BF_FEEBACK_TRIGGER_IDX, HECAP_PHY_BF_FEEBACK_TRIGGER_BITS)
#define HECAP_PHY_BFFEEDBACKTRIG_SET_TO_IE(hecap_phy, value)      \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX6],               \
        HECAP_PHY_BF_FEEBACK_TRIGGER_IDX,                         \
        HECAP_PHY_BF_FEEBACK_TRIGGER_BITS, value)

/*
Indicates the support of transmission and reception of an HE extended
range SU PPDU payload transmitted over the right 106-tone RU
*/
#define HECAP_PHY_HEERSU_GET_FROM_IE(hecap_phy)                  \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX6],              \
        HECAP_PHY_ER_SU_PPDU_PAYLOAD_IDX, HECAP_PHY_ER_SU_PPDU_PAYLOAD_BITS)
#define HECAP_PHY_HEERSU_SET_TO_IE(hecap_phy, value)             \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX6],              \
        HECAP_PHY_ER_SU_PPDU_PAYLOAD_IDX,                        \
        HECAP_PHY_ER_SU_PPDU_PAYLOAD_BITS, value)

/*
Indicates that the non-AP STA supports reception of a DL MU-MIMO
transmission on an RU in an HE MU PPDU where the RU does not span
the entire PPDU bandwidth.
*/
#define HECAP_PHY_DLMUMIMOPARTIALBW_GET_FROM_IE(hecap_phy)            \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX6],                   \
        HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_IDX,                          \
        HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_BITS)
#define HECAP_PHY_DLMUMIMOPARTIALBW_SET_TO_IE(hecap_phy, value)       \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX6],                   \
        HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_IDX,                          \
        HECAP_PHY_DL_MU_MIMO_PARTIAL_BW_BITS, value)

/*Indicates whether or not the PPE Threshold field is present*/
#define HECAP_PHY_PPETHRESPRESENT_GET_FROM_IE(hecap_phy)             \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX6],                  \
        HECAP_PHY_PPET_THRESHOLD_PRESENT_IDX,                        \
        HECAP_PHY_PPET_THRESHOLD_PRESENT_BITS)
#define HECAP_PHY_PPETHRESPRESENT_SET_TO_IE(hecap_phy, value)        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX6],                  \
        HECAP_PHY_PPET_THRESHOLD_PRESENT_IDX,                        \
        HECAP_PHY_PPET_THRESHOLD_PRESENT_BITS, value)

/*Indicates that the STA supports SRP-based SR operation*/
#define HECAP_PHY_SRPSPRESENT_GET_FROM_IE(hecap_phy)                 \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX7],                  \
        HECAP_PHY_SRP_SR_IDX, HECAP_PHY_SRP_SR_BITS)
#define HECAP_PHY_SRPPRESENT_SET_TO_IE(hecap_phy, value)             \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX7],                  \
        HECAP_PHY_SRP_SR_IDX, HECAP_PHY_SRP_SR_BITS, value)

/*
Indicates that the STA supports a power boost factor alpha-r
for the r-th RU in the range [0.5, 2]
*/
#define HECAP_PHY_PWRBOOSTAR_GET_FROM_IE(hecap_phy)             \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX7],             \
        HECAP_PHY_POWER_BOOST_AR_IDX, HECAP_PHY_POWER_BOOST_AR_BITS)
#define HECAP_PHY_PWRBOOSTAR_SET_TO_IE(hecap_phy, value)        \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX7],             \
        HECAP_PHY_POWER_BOOST_AR_IDX, HECAP_PHY_POWER_BOOST_AR_BITS, value)

/*
Indicates support for the reception of 4x LTF and 0.8us guard
interval duration for HE SU PPDUs.
*/
#define HECAP_PHY_4XLTFAND800NSECSGI_GET_FROM_IE(hecap_phy)        \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX7],                \
        HECAP_PHY_4X_LTF_0_8_GI_IDX, HECAP_PHY_4X_LTF_0_8_GI_BITS)
#define HECAP_PHY_4XLTFAND800NSECSGI_SET_TO_IE(hecap_phy, value)   \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX7],                \
        HECAP_PHY_4X_LTF_0_8_GI_IDX, HECAP_PHY_4X_LTF_0_8_GI_BITS, value)

/*
For a transmitting STA acting as a beamformee, it indicates
the maximum Nc for beamforming sounding feedback supported.
If SU beamformee capable, then set to the maximum Nc for
beamforming sounding feedback minus 1. Otherwise, reserved.
*/
#define HECAP_PHY_MAX_NC_GET_FROM_IE(hecap_phy)                     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX7],                 \
        HECAP_PHY_MAX_NC_IDX, HECAP_PHY_MAX_NC_BITS)
#define HECAP_PHY_MAX_NC_SET_TO_IE(hecap_phy, value)                \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX7],                 \
        HECAP_PHY_MAX_NC_IDX, HECAP_PHY_MAX_NC_BITS, value)

/*
Indicates support for the transmission of an HE PPDU that
has a bandwidth greater than 80 MHz and is using STBC with
one spatial stream
*/
#define HECAP_PHY_STBCTXGT80_GET_FROM_IE(hecap_phy)               \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX7],               \
        HECAP_PHY_STBC_TX_GREATER_80MHZ_IDX,                      \
        HECAP_PHY_STBC_TX_GREATER_80MHZ_BITS)
#define HECAP_PHY_STBCTXGT80_SET_TO_IE(hecap_phy, value)          \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX7],               \
        HECAP_PHY_STBC_TX_GREATER_80MHZ_IDX,                      \
        HECAP_PHY_STBC_TX_GREATER_80MHZ_BITS, value)

/*
Indicates support for the reception of an HE PPDU that
has a bandwidth greater than 80 MHz and is using STBC with
one spatial stream
*/
#define HECAP_PHY_STBCRXGT80_GET_FROM_IE(hecap_phy)               \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX7],               \
        HECAP_PHY_STBC_RX_GREATER_80MHZ_IDX,                      \
        HECAP_PHY_STBC_RX_GREATER_80MHZ_BITS)
#define HECAP_PHY_STBCRXGT80_SET_TO_IE(hecap_phy, value)          \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX7],               \
        HECAP_PHY_STBC_RX_GREATER_80MHZ_IDX,                      \
        HECAP_PHY_STBC_RX_GREATER_80MHZ_BITS, value)

/* Indicates support for the reception of an HE ER SU PPDU
with 4x LTF and 0.8 us guard interval duration
*/
#define HECAP_PHY_ERSU_4XLTF800NSGI_GET_FROM_IE(hecap_phy)        \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],               \
        HECAP_PHY_ERSU_4X_LTF_800_NS_GI_IDX,                      \
        HECAP_PHY_ERSU_4X_LTF_800_NS_GI_BITS)
#define HECAP_PHY_ERSU_4XLTF800NSGI_SET_TO_IE(hecap_phy, value)   \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],               \
        HECAP_PHY_ERSU_4X_LTF_800_NS_GI_IDX,                      \
        HECAP_PHY_ERSU_4X_LTF_800_NS_GI_BITS, value)

/* Indicates support of 26-, 52-, and 106-tone mapping for
a 20 MHz operating non-AP HE STA that is the receiver of a
40 MHz HE MU PPDU in 2.4 GHz band, or the transmitter of a
40 MHz HE TB PPDU in 2.4GHz band.
*/
#define HECAP_PHY_HEPPDU20IN40MHZ2G_GET_FROM_IE(hecap_phy)       \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],              \
        HECAP_PHY_HEPPDU_20_IN_40MHZ2G_IDX,                      \
        HECAP_PHY_HEPPDU_20_IN_40MHZ2G_BITS)
#define HECAP_PHY_HEPPDU20IN40MHZ2G_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],              \
        HECAP_PHY_HEPPDU_20_IN_40MHZ2G_IDX,                      \
        HECAP_PHY_HEPPDU_20_IN_40MHZ2G_BITS, value)

/* Indicates support of 26-, 52-, and 106-tone mapping for
a 20 MHz operating non-AP HE STA that is the receiver of a
80+80 MHz or a 160 MHz HE MU PPDU, or the transmitter of a
80+80 MHz or 160 MHz HE TB PPDU.
*/
#define HECAP_PHY_HEPPDU20IN160OR80P80MHZ_GET_FROM_IE(hecap_phy) \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],              \
        HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_IDX,              \
        HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_BITS)
#define HECAP_PHY_HEPPDU20IN160OR80P80MHZ_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],                    \
        HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_IDX,                    \
        HECAP_PHY_HEPPDU_20_IN_160_OR_80P80MHZ_BITS, value)

/* Indicates supports of 160 MHz OFDMA for a non-AP HE STA
that sets bit B1 of Channel Width Set to 1, and sets B2 and
B3 of Channel Width Set each to 0, when operating with 80 MHz
channel width. The capability bit is applicable while receiving
a 80+80 MHz or a 160 MHz HE MU PPDU, or transmitting a 80+80 MHz
or a 160 MHz HE TB PPDU.
*/
#define HECAP_PHY_HEPPDU80IN160OR80P80MHZ_GET_FROM_IE(hecap_phy) \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],              \
        HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_IDX,              \
        HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_BITS)
#define HECAP_PHY_HEPPDU80IN160OR80P80MHZ_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],                    \
        HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_IDX,                    \
        HECAP_PHY_HEPPDU_80_IN_160_OR_80P80MHZ_BITS, value)

/* Indicates support for the reception of an HE ER SU PPDU
with 1x LTF and 0.8 us guard interval duration
*/
#define HECAP_PHY_ERSU1XLTF800NSGI_GET_FROM_IE(hecap_phy)       \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],             \
        HECAP_PHY_ERSU_1X_LTF_800_NS_GI_IDX,                    \
        HECAP_PHY_ERSU_1X_LTF_800_NS_GI_BITS)
#define HECAP_PHY_ERSU1XLTF800NSGI_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],             \
        HECAP_PHY_ERSU_1X_LTF_800_NS_GI_IDX,                    \
        HECAP_PHY_ERSU_1X_LTF_800_NS_GI_BITS, value)

#if SUPPORT_11AX_D3
/* When the Doppler Tx/Rx subfield is 1, indicates support
for receiving midambles with 2x HE-LTF, 1x HE-LTF in HE
SU PPDU if the HE SU PPDU With 1x HE-LTF And 0.8s GI
subfield is set to 1, and 1x HE-LTF in HE ER SU PPDU if
the HE ER SU PPDU With 1x HELTF And 0.8 s GI subfield is
set to 1; and also support for transmitting midambles with
2x HE-LTF, 1x HE-LTF in HE TB PPDU when allowed.
*/
#define HECAP_PHY_MIDAMBLETXRX2XAND1XLTF_GET_FROM_IE(hecap_phy)   \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],             \
        HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_IDX,                  \
        HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_BITS)
#define HECAP_PHY_MIDAMBLETXRX2XAND1XLTF_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],                 \
        HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_IDX,                      \
        HECAP_PHY_MIDAMBLE_TXRX_2XAND1X_LTF_BITS, value)
#else
/* When the Doppler Rx subfield is 1, indicates support
for receiving midambles with 2x HE-LTF, 1x HE-LTF in HE
SU PPDU if the HE SU PPDU With 1x HE-LTF And 0.8s GI
subfield is set to 1, and 1x HE-LTF in HE ER SU PPDU if
the HE ER SU PPDU With 1x HELTF And 0.8 s GI subfield is
set to 1.
*/
#define HECAP_PHY_MIDAMBLERX2XAND1XLTF_GET_FROM_IE(hecap_phy)   \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],             \
        HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_IDX,                  \
        HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_BITS)
#define HECAP_PHY_MIDAMBLERX2XAND1XLTF_SET_TO_IE(hecap_phy, value)  \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],                 \
        HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_IDX,                      \
        HECAP_PHY_MIDAMBLE_RX_2XAND1X_LTF_BITS, value)
#endif

#if SUPPORT_11AX_D3

/* DCM Max BW - When the DCM Max Constellation Tx subfield is greater
 * than 0, then the DCM Max BW subfield indicates the maximum bandwidth of a
 * PPDU that the STA might transmit with DCM applied. When the the DCM Max
 * Constellation Rx subfield is greater than 0, then the DCM Max BW subfield
 * indicates the maximum bandwidth of a PPDU with DCM applied that the STA
 * can receive.
 */
#define HECAP_PHY_DCMMAXBW_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX8],      \
        HECAP_PHY_DCM_MAXBW_IDX, HECAP_PHY_DCM_MAXBW_BITS)
#define HECAP_PHY_DCMMAXBW_SET_TO_IE(hecap_phy, value)             \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX8],      \
        HECAP_PHY_DCM_MAXBW_IDX, HECAP_PHY_DCM_MAXBW_BITS, value)

/* Longer Than 16 HE SIG-B OFDM Symbols Support - For a non-AP STA,
 * indicates support for receiving a DL HE MU PPDU where the number of OFDM
 * symbols in the HE SIG-B field is greater than 16.
 */
#define HECAP_PHY_LT16HESIGBOFDMSYM_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_LT16_HESIGB_OFDM_SYM_IDX,              \
        HECAP_PHY_LT16_HESIGB_OFDM_SYM_BITS)
#define HECAP_PHY_LT16HESIGBOFDMSYM_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_LT16_HESIGB_OFDM_SYM_IDX,              \
        HECAP_PHY_LT16_HESIGB_OFDM_SYM_BITS, value)

/* Non- Triggered CQI Feedback - For an AP, indicates support for the
 * reception of full bandwidth non-triggered CQI-only feedback. For a non-AP
 * STA, indicates support for the transmission of full bandwidth non-triggered
 * CQI-only feedback.
 */
#define HECAP_PHY_NONTRIGCQIFDBK_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_NON_TRIG_CQI_FDBK_IDX,                 \
        HECAP_PHY_NON_TRIG_CQI_FDBK_BITS)
#define HECAP_PHY_NONTRIGCQIFDBK_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_NON_TRIG_CQI_FDBK_IDX,                 \
        HECAP_PHY_NON_TRIG_CQI_FDBK_BITS, value)

/* Tx 1024- QAM < 242-tone RU Support - For a non-AP STA, indicates support
 * for transmitting 1024-QAM on a 26-, 52-, and 106-tone RU. Reserved for an AP.
 */
#define HECAP_PHY_TX1024QAMLT242TONERU_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_TX_1024QAM_LT_242TONE_RU_IDX,                 \
        HECAP_PHY_TX_1024QAM_LT_242TONE_RU_BITS)
#define HECAP_PHY_TX1024QAMLT242TONERU_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_TX_1024QAM_LT_242TONE_RU_IDX,                 \
        HECAP_PHY_TX_1024QAM_LT_242TONE_RU_BITS, value)

/* Rx 1024- QAM < 242-tone RU Support - Indicates support fro receiving
 * 1024-QAM on a 26-, 52-, and 106-tone RU.
 */
#define HECAP_PHY_RX1024QAMLT242TONERU_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_RX_1024QAM_LT_242TONE_RU_IDX,                 \
        HECAP_PHY_RX_1024QAM_LT_242TONE_RU_BITS)
#define HECAP_PHY_RX1024QAMLT242TONERU_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_RX_1024QAM_LT_242TONE_RU_IDX,                 \
        HECAP_PHY_RX_1024QAM_LT_242TONE_RU_BITS, value)

/* Rx Full BW SU Using HE MU PPDU With Compressed SIGB - Indicates support
 * for reception of an HE MU PPDU with an RU spanning the entire PPDU bandwidth
 * and a compressed HE-SIG-B format.
 */
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_COMPSIGB_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_IDX,        \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_BITS)
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_COMPSIGB_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_IDX,                 \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_COMP_SIGB_BITS, value)

/* Rx Full BW SU Using HE MU PPDU With Non-Compressed SIGB - Indicates support
 * for reception of an HE MU PPDU with a bandwidth less than or equal to 80 MHz,
 * an RU spanning the entire PPDU bandwidth and a non-compressed HE-SIG-B format.
 */
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_NONCOMPSIGB_GET_FROM_IE(hecap_phy)     \
        hecap_ie_get(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_IDX,        \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_BITS)
#define HECAP_PHY_RXFULLBWSUHEMUPPDU_NONCOMPSIGB_SET_TO_IE(hecap_phy, value)     \
        hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX9],      \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_IDX,                 \
        HECAP_PHY_RX_FULLBWSU_HEMU_PPDU_NON_COMP_SIGB_BITS, value)


#define HECAP_PHY_RESERVED_SET_TO_IE(hecap_phy, value) do {                 \
       hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX0],                          \
       HECAP_PHY_RESERVED_IDX1, HECAP_PHY_RESERVED_BITS1, value);           \
       hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX9],                          \
       HECAP_PHY_RESERVED_IDX2, HECAP_PHY_RESERVED_BITS2 - 8, value);       \
       hecap_ie_set(hecap_phy[HECAP_PHYBYTE_IDX10],                         \
       HECAP_PHY_RESERVED_IDX2 + 2, HECAP_PHY_RESERVED_BITS2 - 2, value);   \
} while(0)

#endif

/* HE MAC capabilities , field starting idx and
 * no of bits postions as per IC HE populated
 * capabilities from target
 */

#define IC_HECAP_MAC_HTC_HE_IDX                       0
#define IC_HECAP_MAC_HTC_HE_BITS                      1
#define IC_HECAP_MAC_TWT_REQU_IDX                     1
#define IC_HECAP_MAC_TWT_REQU_BITS                    1
#define IC_HECAP_MAC_TWT_RESP_IDX                     2
#define IC_HECAP_MAC_TWT_RESP_BITS                    1
#define IC_HECAP_MAC_FRAG_IDX                         3
#define IC_HECAP_MAC_FRAG_BITS                        2
#if SUPPORT_11AX_D3
#define IC_HECAP_MAC_MAX_FRAG_MSDUS_EXP_IDX           5
#define IC_HECAP_MAC_MAX_FRAG_MSDUS_EXP_BITS          3
#else
#define IC_HECAP_MAC_MAX_FRAG_MSDUS_IDX               5
#define IC_HECAP_MAC_MAX_FRAG_MSDUS_BITS              3
#endif
#define IC_HECAP_MAC_MIN_FRAG_SIZE_IDX                8
#define IC_HECAP_MAC_MIN_FRAG_SIZE_BITS               2
#define IC_HECAP_MAC_TRIG_FR_MAC_PADD_DUR_IDX         10
#define IC_HECAP_MAC_TRIG_FR_MAC_PADD_DUR_BITS        2
#if SUPPORT_11AX_D3
#define IC_HECAP_MAC_MULTI_TID_AGGR_RX_IDX            12
#define IC_HECAP_MAC_MULTI_TID_AGGR_RX_BITS           3
#else
#define IC_HECAP_MAC_MULTI_TID_AGGR_IDX               12
#define IC_HECAP_MAC_MULTI_TID_AGGR_BITS              3
#endif
#define IC_HECAP_MAC_HTC_HE_LINK_ADAPT_IDX            15
#define IC_HECAP_MAC_HTC_HE_LINK_ADAPT_BITS           2
#define IC_HECAP_MAC_ALL_ACK_IDX                      17
#define IC_HECAP_MAC_ALL_ACK_BITS                     1
#if SUPPORT_11AX_D3
#define IC_HECAP_MAC_TRIG_RESP_SCHED_IDX              18
#define IC_HECAP_MAC_TRIG_RESP_SCHED_BITS             1
#else
#define IC_HECAP_MAC_UL_MU_RESP_SCHED_IDX             18
#define IC_HECAP_MAC_UL_MU_RESP_SCHED_BITS            1
#endif
#define IC_HECAP_MAC_ACTRL_BSR_IDX                    19
#define IC_HECAP_MAC_ACTRL_BSR_BITS                   1
#define IC_HECAP_MAC_BCAST_TWT_IDX                    20
#define IC_HECAP_MAC_BCAST_TWT_BITS                   1
#define IC_HECAP_MAC_32BIT_BA_BITMAP_IDX              21
#define IC_HECAP_MAC_32BIT_BA_BITMAP_BITS             1
#define IC_HECAP_MAC_MU_CASCADE_IDX                   22
#define IC_HECAP_MAC_MU_CASCADE_BITS                  1
#define IC_HECAP_MAC_ACK_MULTI_TID_AGGR_IDX           23
#define IC_HECAP_MAC_ACK_MULTI_TID_AGGR_BITS          1
#define IC_HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_IDX      24
#define IC_HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_BITS     1
#define IC_HECAP_MAC_ACTRL_OMI_IDX                    25
#define IC_HECAP_MAC_ACTRL_OMI_BITS                   1
#define IC_HECAP_MAC_OFDMA_RA_IDX                     26
#define IC_HECAP_MAC_OFDMA_RA_BITS                    1
#if SUPPORT_11AX_D3
#define IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_IDX    27
#define IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_BITS   2
#else
#define IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_IDX        27
#define IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_BITS       2
#endif
#define IC_HECAP_MAC_AMSDU_FRAGMENTATION_IDX          29
#define IC_HECAP_MAC_AMSDU_FRAGMENTATION_BITS         1
#define IC_HECAP_MAC_FLEX_TWT_SCHEDULE_IDX            30
#define IC_HECAP_MAC_FLEX_TWT_SCHEDULE_BITS           1
#define IC_HECAP_MAC_RX_CTRL_FR_MULTI_BSS_IDX         31
#define IC_HECAP_MAC_RX_CTRL_FR_MULTI_BSS_BITS        1
#define IC_HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_IDX         32
#define IC_HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_BITS        1
#define IC_HECAP_MAC_QTP_IDX                          33
#define IC_HECAP_MAC_QTP_BITS                         1
#define IC_HECAP_MAC_ACTRL_BQR_IDX                    34
#define IC_HECAP_MAC_ACTRL_BQR_BITS                   1
#if SUPPORT_11AX_D3
#define IC_HECAP_MAC_SRPRESP_IDX                      35
#define IC_HECAP_MAC_SRPRESP_BITS                     1
#else
#define IC_HECAP_MAC_SRRESP_IDX                       35
#define IC_HECAP_MAC_SRRESP_BITS                      1
#endif
#define IC_HECAP_MAC_NDPFDBKRPT_IDX                   36
#define IC_HECAP_MAC_NDPFDBKRPT_BITS                  1
#define IC_HECAP_MAC_OPS_IDX                          37
#define IC_HECAP_MAC_OPS_BITS                         1
#if !SUPPORT_11AX_D3
/* FW is re-using these 2 bits starting at idx 15
 * for the time being as HE link-adaptation is not yet
 * supported. 1 bit is reused for the AMSDU in AMPDU
 * field and the other bit is kept as reserved. We
 * will use IC_HECAP_MAC_HTC_HE_LINK_ADAPT_IDX for
 * IC_HECAP_MAC_AMSDUINAMPDU_IDX untill FW re-enables
 * HE links adaptation and redefines the idx for AMSDU
 * in AMPDU field.
 */
#define IC_HECAP_MAC_AMSDUINAMPDU_IDX                 IC_HECAP_MAC_HTC_HE_LINK_ADAPT_IDX
#define IC_HECAP_MAC_AMSDUINAMPDU_BITS                1
#else
#define IC_HECAP_MAC_AMSDUINAMPDU_IDX                 38
#define IC_HECAP_MAC_AMSDUINAMPDU_BITS                1
#define IC_HECAP_MAC_MTID_TX_SUP_IDX                  39
#define IC_HECAP_MAC_MTID_TX_SUP_BITS                 3
#define IC_HECAP_MAC_HESUB_CHAN_TX_SUP_IDX            42
#define IC_HECAP_MAC_HESUB_CHAN_TX_SUP_BITS           1
#define IC_HECAP_MAC_UL_2X996_TONE_RU_IDX             43
#define IC_HECAP_MAC_UL_2X996_TONE_RU_BITS            1
#define IC_HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_IDX         44
#define IC_HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_BITS        1
#define IC_HECAP_MAC_DYNAMIC_SM_POWER_SAVE_IDX        45
#define IC_HECAP_MAC_DYNAMIC_SM_POWER_SAVE_BITS       1
#define IC_HECAP_MAC_PUNCTURED_SOUND_SUPP_IDX         46
#define IC_HECAP_MAC_PUNCTURED_SOUND_SUPP_BITS        1
#define IC_HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_IDX      47
#define IC_HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_BITS     1
#endif



/* HE MAC Capabilities Get/Set to IC / Node
 * HE handle. These macros should be in sync
 * with WMI HE MAC capabilities
 */

/*
HTC + HE Support  Set to 1 if STA supports
reception of HE Variant HT control Field
*/
#define HECAP_MAC_HECTRL_GET_FROM_IC(hecap_mac)          \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_HTC_HE_IDX,  \
        IC_HECAP_MAC_HTC_HE_BITS)
#define HECAP_MAC_HECTRL_SET_TO_IC(hecap_mac, value)     \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_HTC_HE_IDX,  \
        IC_HECAP_MAC_HTC_HE_BITS, value)

/* set to 1 to for TWT Requestor support*/
#define HECAP_MAC_TWTREQ_GET_FROM_IC(hecap_mac)           \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_TWT_REQU_IDX, \
        IC_HECAP_MAC_TWT_REQU_BITS)
#define HECAP_MAC_TWTREQ_SET_TO_IC(hecap_mac, value)      \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_TWT_REQU_IDX, \
        IC_HECAP_MAC_TWT_REQU_BITS, value)

/* set to 1 to for TWT Responder support*/
#define HECAP_MAC_TWTRSP_GET_FROM_IC(hecap_mac)           \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_TWT_RESP_IDX, \
        IC_HECAP_MAC_TWT_RESP_BITS)
#define HECAP_MAC_TWTRSP_SET_TO_IC(hecap_mac, value)      \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_TWT_RESP_IDX, \
        IC_HECAP_MAC_TWT_RESP_BITS, value)

/*
Level of frag support
Set to 0 for no support for dynamic fragmentation.
Set to 1 for support for dynamic fragments that are
contained within a S-MPDU
Set to 2 for support for dynamic fragments that are
contained within a Single MPDU and support for up to
one dynamic fragment for each MSDU and each MMPDU
within an A-MPDU or multi-TID A-MPDU.
Set to 3 for support for dynamic fragments that are
contained within a Single MPDU and support for multiple
dynamic fragments for each MSDU within an AMPDU or
multi-TID AMPDU and up to one dynamic fragment for each
MMPDU in a multi-TID A-MPDU that is not a Single MPDU
*/
#define HECAP_MAC_HEFRAG_GET_FROM_IC(hecap_mac)          \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_FRAG_IDX,    \
        IC_HECAP_MAC_FRAG_BITS)
#define HECAP_MAC_HEFRAG_SET_TO_IC(hecap_mac, value)     \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_FRAG_IDX,    \
        IC_HECAP_MAC_FRAG_BITS, value)

/*
The maximum number of fragmented MSDUs, Nmax,defined by
this field is Nmax = 2 Maximum Number Of FMPDUs
*/
#if SUPPORT_11AX_D3
#define HECAP_MAC_MAXFRAGMSDUEXP_GET_FROM_IC(hecap_mac)            \
        HE_GET_BITS(hecap_mac,  \
        IC_HECAP_MAC_MAX_FRAG_MSDUS_EXP_IDX, \
        IC_HECAP_MAC_MAX_FRAG_MSDUS_EXP_BITS)
#define HECAP_MAC_MAXFRAGMSDUEXP_SET_TO_IC(hecap_mac, value)       \
        HE_SET_BITS(hecap_mac,  \
        IC_HECAP_MAC_MAX_FRAG_MSDUS_EXP_IDX, \
        IC_HECAP_MAC_MAX_FRAG_MSDUS_EXP_BITS, value)
#else
#define HECAP_MAC_MAXFRAGMSDU_GET_FROM_IC(hecap_mac)            \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_MAX_FRAG_MSDUS_IDX, \
        IC_HECAP_MAC_MAX_FRAG_MSDUS_BITS)
#define HECAP_MAC_MAXFRAGMSDU_SET_TO_IC(hecap_mac, value)       \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_MAX_FRAG_MSDUS_IDX, \
        IC_HECAP_MAC_MAX_FRAG_MSDUS_BITS, value)
#endif

/*
0 =  no restriction on the minimum payload , 1 = 128
octets min, 2 = 256 octets min, 3 = 512 octets min
*/
#define HECAP_MAC_MINFRAGSZ_GET_FROM_IC(hecap_mac)              \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_MIN_FRAG_SIZE_IDX,  \
        IC_HECAP_MAC_MIN_FRAG_SIZE_BITS)
#define HECAP_MAC_MINFRAGSZ_SET_TO_IC(hecap_mac, value)         \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_MIN_FRAG_SIZE_IDX,  \
        IC_HECAP_MAC_MIN_FRAG_SIZE_BITS, value)

/*0 = no additional processing time, 1 = 8us,2 = 16us */
#define HECAP_MAC_TRIGPADDUR_GET_FROM_IC(hecap_mac)                   \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_TRIG_FR_MAC_PADD_DUR_IDX, \
        IC_HECAP_MAC_TRIG_FR_MAC_PADD_DUR_BITS)
#define HECAP_MAC_TRIGPADDUR_SET_TO_IC(hecap_mac, value)              \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_TRIG_FR_MAC_PADD_DUR_IDX, \
        IC_HECAP_MAC_TRIG_FR_MAC_PADD_DUR_BITS, value)

#if SUPPORT_11AX_D3
#define HECAP_MAC_MTIDRXSUP_GET_FROM_IC(hecap_mac)                    \
        HE_GET_BITS(hecap_mac,          \
        IC_HECAP_MAC_MULTI_TID_AGGR_RX_IDX,  \
        IC_HECAP_MAC_MULTI_TID_AGGR_RX_BITS)
#define HECAP_MAC_MTID_SET_TO_IC(hecap_mac, value)               \
        HE_SET_BITS(hecap_mac,  \
        IC_HECAP_MAC_MULTI_TID_AGGR_RX_IDX,  \
        IC_HECAP_MAC_MULTI_TID_AGGR_RX_BITS, value)
#else
/*
number of TIDs minus 1 of QoS Data frames that
HE STA can aggregate in  multi-TID AMPDU
*/
#define HECAP_MAC_MTID_GET_FROM_IC(hecap_mac)                    \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_MULTI_TID_AGGR_IDX,  \
        IC_HECAP_MAC_MULTI_TID_AGGR_BITS)
#define HECAP_MAC_MTID_SET_TO_IC(hecap_mac, value)               \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_MULTI_TID_AGGR_IDX,  \
        IC_HECAP_MAC_MULTI_TID_AGGR_BITS, value)
#endif

/*0=No Feedback,2=Unsolicited,3=Both*/
/* FW is re-using these 2 bits starting at idx 15
 * for the time being as HE link-adaptation is not yet
 * supported. 1 bit is reused for the AMSDU in AMPDU
 * field and the other bit is kept as reserved. The
 * following code will remain commented till FW re-
 * enables it or the spec removes HE link adaptation
 * field in HE CAP
 */
#if 0
#define HECAP_MAC_HELKAD_GET_FROM_IC(hecap_mac)                    \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_HTC_HE_LINK_ADAPT_IDX, \
        IC_HECAP_MAC_HTC_HE_LINK_ADAPT_BITS)
#define HECAP_MAC_HELKAD_SET_TO_IC(hecap_mac, value)               \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_HTC_HE_LINK_ADAPT_IDX, \
        IC_HECAP_MAC_HTC_HE_LINK_ADAPT_BITS, value)
#endif
#define HECAP_MAC_HELKAD_GET_FROM_IC(hecap_mac) 0
#define HECAP_MAC_HELKAD_SET_TO_IC(hecap_mac, value) {;}

/*Set to 1 for reception of AllAck support*/
#define HECAP_MAC_AACK_GET_FROM_IC(hecap_mac)                      \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_ALL_ACK_IDX,           \
        IC_HECAP_MAC_ALL_ACK_BITS)
#define HECAP_MAC_AACK_SET_TO_IC(hecap_mac, value)                 \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_ALL_ACK_IDX,           \
        IC_HECAP_MAC_ALL_ACK_BITS, value)

/*
Set to 1 if the STA supports reception of the
UL MU Response Scheduling A-Control field
*/
#if SUPPORT_11AX_D3
#define HECAP_MAC_TRSSUP_GET_FROM_IC(hecap_mac)                    \
        HE_GET_BITS(hecap_mac,             \
        IC_HECAP_MAC_TRIG_RESP_SCHED_IDX,                          \
        IC_HECAP_MAC_TRIG_RESP_SCHED_BITS)
#define HECAP_MAC_TRSSUP_SET_TO_IC(hecap_mac, value)               \
        HE_SET_BITS(hecap_mac,             \
        IC_HECAP_MAC_TRIG_RESP_SCHED_IDX,                          \
        IC_HECAP_MAC_TRIG_RESP_SCHED_BITS, value)
#else
#define HECAP_MAC_ULMURSP_GET_FROM_IC(hecap_mac)                    \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_UL_MU_RESP_SCHED_IDX,   \
        IC_HECAP_MAC_UL_MU_RESP_SCHED_BITS)
#define HECAP_MAC_ULMURSP_SET_TO_IC(hecap_mac, value)               \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_UL_MU_RESP_SCHED_IDX,   \
        IC_HECAP_MAC_UL_MU_RESP_SCHED_BITS, value)
#endif

/*Set to 1 if the STA supports the BSR A-Control field functionality.*/
#define HECAP_MAC_BSR_GET_FROM_IC(hecap_mac)                      \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_ACTRL_BSR_IDX,        \
        IC_HECAP_MAC_ACTRL_BSR_BITS)
#define HECAP_MAC_BSR_SET_TO_IC(hecap_mac, value)                 \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_ACTRL_BSR_IDX,        \
        IC_HECAP_MAC_ACTRL_BSR_BITS, value)

/*Set to 1 when the STA supports broadcast TWT functionality.*/
#define HECAP_MAC_BCSTTWT_GET_FROM_IC(hecap_mac)                  \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_BCAST_TWT_IDX,        \
        IC_HECAP_MAC_BCAST_TWT_BITS)
#define HECAP_MAC_BCSTTWT_SET_TO_IC(hecap_mac, value)             \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_BCAST_TWT_IDX,        \
        IC_HECAP_MAC_BCAST_TWT_BITS, value)

/*Set to 1 if STA supports rx of Multi-STA BA that has 32-bit Block Ack Bitmap*/
#define HECAP_MAC_32BITBA_GET_FROM_IC(hecap_mac)                  \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_32BIT_BA_BITMAP_IDX,  \
        IC_HECAP_MAC_32BIT_BA_BITMAP_BITS)
#define HECAP_MAC_32BITBA_SET_TO_IC(hecap_mac, value)             \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_32BIT_BA_BITMAP_IDX,  \
        IC_HECAP_MAC_32BIT_BA_BITMAP_BITS, value)

/*Set to 1 if the STA supports MU cascading operation*/
#define HECAP_MAC_MUCASCADE_GET_FROM_IC(hecap_mac)                \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_MU_CASCADE_IDX,       \
        IC_HECAP_MAC_MU_CASCADE_BITS)
#define HECAP_MAC_MUCASCADE_SET_TO_IC(hecap_mac, value)           \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_MU_CASCADE_IDX,       \
        IC_HECAP_MAC_MU_CASCADE_BITS, value)

/*Set to 1 when the STA supports reception of this multi-TID A-MPDU format*/
#define HECAP_MAC_ACKMTIDAMPDU_GET_FROM_IC(hecap_mac)               \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_ACK_MULTI_TID_AGGR_IDX, \
        IC_HECAP_MAC_ACK_MULTI_TID_AGGR_BITS)
#define HECAP_MAC_ACKMTIDAMPDU_SET_TO_IC(hecap_mac, value)          \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_ACK_MULTI_TID_AGGR_IDX, \
        IC_HECAP_MAC_ACK_MULTI_TID_AGGR_BITS, value)

#define HECAP_MAC_GROUPMSTABA_GET_FROM_IC(hecap_mac)                      \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_IDX,  \
        IC_HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_BITS)
#define HECAP_MAC_GROUPMSTABA_SET_TO_IC(hecap_mac, value)                 \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_IDX,  \
        IC_HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_BITS, value)

/*Set to 1 if the STA supports reception of the OMI A-Control field*/
#define HECAP_MAC_OMI_GET_FROM_IC(hecap_mac)                          \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_ACTRL_OMI_IDX,            \
        IC_HECAP_MAC_ACTRL_OMI_BITS)
#define HECAP_MAC_OMI_SET_TO_IC(hecap_mac, value)                     \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_ACTRL_OMI_IDX,            \
        IC_HECAP_MAC_ACTRL_OMI_BITS, value)

/*1 if OFDMA Random Access Supported*/
#define HECAP_MAC_OFDMARA_GET_FROM_IC(hecap_mac)                      \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_OFDMA_RA_IDX,             \
        IC_HECAP_MAC_OFDMA_RA_BITS)
#define HECAP_MAC_OFDMARA_SET_TO_IC(hecap_mac, value)                 \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_OFDMA_RA_IDX,             \
        IC_HECAP_MAC_OFDMA_RA_BITS, value)

#if SUPPORT_11AX_D3
/*Maximum AMPDU Length Exponent*/
#define HECAP_MAC_MAXAMPDULEN_EXPEXT_GET_FROM_IC(hecap_mac)                \
        HE_GET_BITS(hecap_mac,                     \
        IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_IDX,                        \
        IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_BITS)
#define HECAP_MAC_MAXAMPDULEN_EXPEXT_SET_TO_IC(hecap_mac, value)           \
        HE_SET_BITS(hecap_mac,                     \
        IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_IDX,  \
        IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_BITS, value)
#else
#define HECAP_MAC_MAXAMPDULEN_EXP_GET_FROM_IC(hecap_mac)                \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_IDX,  \
        IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_BITS)
#define HECAP_MAC_MAXAMPDULEN_EXP_SET_TO_IC(hecap_mac, value)           \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_IDX,  \
        IC_HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_BITS, value)
#endif

/*A-MSDU Fragmentation Support*/
#define HECAP_MAC_AMSDUFRAG_GET_FROM_IC(hecap_mac)                     \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_AMSDU_FRAGMENTATION_IDX,   \
        IC_HECAP_MAC_AMSDU_FRAGMENTATION_BITS)
#define HECAP_MAC_AMSDUFRAG_SET_TO_IC(hecap_mac, value)                \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_AMSDU_FRAGMENTATION_IDX,   \
        IC_HECAP_MAC_AMSDU_FRAGMENTATION_BITS, value)

/*Flexible TWT Schedule Support*/
#define HECAP_MAC_FLEXTWT_GET_FROM_IC(hecap_mac)                       \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_FLEX_TWT_SCHEDULE_IDX,     \
        IC_HECAP_MAC_FLEX_TWT_SCHEDULE_BITS)
#define HECAP_MAC_FLEXTWT_SET_TO_IC(hecap_mac, value)                  \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_FLEX_TWT_SCHEDULE_IDX,     \
        IC_HECAP_MAC_FLEX_TWT_SCHEDULE_BITS, value)

/*Rx Control Frame to MultiBSS*/
#define HECAP_MAC_MBSS_GET_FROM_IC(hecap_mac)                          \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_RX_CTRL_FR_MULTI_BSS_IDX,  \
        IC_HECAP_MAC_RX_CTRL_FR_MULTI_BSS_BITS)
#define HECAP_MAC_MBSS_SET_TO_IC(hecap_mac, value)                     \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_RX_CTRL_FR_MULTI_BSS_IDX,  \
        IC_HECAP_MAC_RX_CTRL_FR_MULTI_BSS_BITS, value)

/*
BSRP/BQRP A-MPDU Aggregation
*/
#define HECAP_MAC_BSRP_BQRP_AMPDU_AGGR_GET_FROM_IC(hecap_mac)          \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_IDX,  \
        IC_HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_BITS)
#define HECAP_MAC_BSRP_BQRP_AMPDU_AGGR_SET_TO_IC(hecap_mac, value)     \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_IDX,  \
        IC_HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_BITS, value)

/*
Quiet Time Period (QTP) operation
*/
#define HECAP_MAC_QTP_GET_FROM_IC(hecap_mac)                   \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_QTP_IDX,           \
        IC_HECAP_MAC_QTP_BITS)
#define HECAP_MAC_QTP_SET_TO_IC(hecap_mac, value)              \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_QTP_IDX,           \
        IC_HECAP_MAC_QTP_BITS, value)

/*
support by an AP for receiving an (A-)MPDU that contains a BQR in
the A-Control subfield and support by a non-AP STA for generating
an (A-)MPDU   that contains a BQR in the A-Control subfield
*/
#define HECAP_MAC_ABQR_GET_FROM_IC(hecap_mac)                 \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_ACTRL_BQR_IDX,    \
        IC_HECAP_MAC_ACTRL_BQR_BITS)
#define HECAP_MAC_ABQR_SET_TO_IC(hecap_mac, value)            \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_ACTRL_BQR_IDX,    \
        IC_HECAP_MAC_ACTRL_BQR_BITS, value)

/*
SRP Responder - support by the STA for the role of SRP Responder
*/
#if SUPPORT_11AX_D3
#define HECAP_MAC_SRPRESP_GET_FROM_IC(hecap_mac)              \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_SRPRESP_IDX,      \
        IC_HECAP_MAC_SRPRESP_BITS)
#define HECAP_MAC_SRPRESP_SET_TO_IC(hecap_mac, value)         \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_SRPRESP_IDX,      \
        IC_HECAP_MAC_SRPRESP_BITS, value)
#else
#define HECAP_MAC_SRRESP_GET_FROM_IC(hecap_mac)               \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_SRRESP_IDX,       \
        IC_HECAP_MAC_SRRESP_BITS)
#define HECAP_MAC_SRRESP_SET_TO_IC(hecap_mac, value)          \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_SRRESP_IDX,       \
        IC_HECAP_MAC_SRRESP_BITS, value)
#endif

/*
NDP Feedback Report Support - support for a non-AP STA to
follow the NDP feedback report procedure and respond to the NDP
Feedback Report Poll Trigger frame
*/
#define HECAP_MAC_NDPFDBKRPT_GET_FROM_IC(hecap_mac)           \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_NDPFDBKRPT_IDX,   \
        IC_HECAP_MAC_NDPFDBKRPT_BITS)
#define HECAP_MAC_NDPFDBKRPT_SET_TO_IC(hecap_mac, value)      \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_NDPFDBKRPT_IDX,   \
        IC_HECAP_MAC_NDPFDBKRPT_BITS, value)

/*
OPS Support - support for an AP to encode OPS information to
TIM element of the FILS Discovery frames or TIM frames as
described in 27.14.3.2 (AP operation for opportunistic power save).
Indicates support for a non-AP STA to receive the opportunistic power
save encoded TIM elements
*/
#define HECAP_MAC_OPS_GET_FROM_IC(hecap_mac)                  \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_OPS_IDX,          \
        IC_HECAP_MAC_OPS_BITS)
#define HECAP_MAC_OPS_SET_TO_IC(hecap_mac, value)             \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_OPS_IDX,          \
        IC_HECAP_MAC_OPS_BITS, value)


/*
A-MSDU in A-MPDU - support by a STA to receive an ack-enabled
A-MPDU in which an A-MSDU is carried in a QoS Data frame for
which no block ack agreement exists.
*/
#define HECAP_MAC_AMSDUINAMPDU_GET_FROM_IC(hecap_mac)                          \
        HE_GET_BITS(hecap_mac, IC_HECAP_MAC_AMSDUINAMPDU_IDX,  \
        IC_HECAP_MAC_AMSDUINAMPDU_BITS)
#define HECAP_MAC_AMSDUINAMPDU_SET_TO_IC(hecap_mac, value)                     \
        HE_SET_BITS(hecap_mac, IC_HECAP_MAC_AMSDUINAMPDU_IDX,  \
        IC_HECAP_MAC_AMSDUINAMPDU_BITS, value)

#if SUPPORT_11AX_D3
/* Multi-TID Aggregation Tx Support - Indicates the number of TIDs of
 * QoS Data frames that an HE STA can transmit in a multi-TID A-MPDU.
 */
#define HECAP_MAC_MTIDTXSUP_GET_FROM_IC(hecap_mac)  \
        HE_GET_BITS(hecap_mac,          \
        IC_HECAP_MAC_MTID_TX_SUP_IDX,    \
        IC_HECAP_MAC_MTID_TX_SUP_BITS)
#define HECAP_MAC_MTIDTXSUP_SET_TO_IC(hecap_mac, value)    \
        HE_SET_BITS(hecap_mac,          \
        IC_HECAP_MAC_MTID_TX_SUP_IDX,    \
        IC_HECAP_MAC_MTID_TX_SUP_BITS, value)

/* HE Subchannel Selective Transmission Support - Indicates whether an HE STA
 * supports an HE subchannel selective transmission operation.
 */
#define HECAP_MAC_HESUBCHAN_TXSUP_GET_FROM_IC(hecap_mac)  \
        HE_GET_BITS(hecap_mac,      \
        IC_HECAP_MAC_HESUB_CHAN_TX_SUP_IDX,    \
        IC_HECAP_MAC_HESUB_CHAN_TX_SUP_BITS)
#define HECAP_MAC_HESUBCHAN_TXSUP_SET_TO_IC(hecap_mac, value)    \
        HE_SET_BITS(hecap_mac,      \
        IC_HECAP_MAC_HESUB_CHAN_TX_SUP_IDX,    \
        IC_HECAP_MAC_HESUB_CHAN_TX_SUP_BITS, value)

/* UL 2×996-tone RU Support - Indicates support by a STA to receive a TRS
 * Control subfield or a Trigger frame with a User Info field addressed
 * to the STA with the RU Allocation subfield of the TRS Control subfield
 * or the User Info field indicating 2996-tone.
 */
#define HECAP_MAC_UL2X996TONERU_GET_FROM_IC(hecap_mac)  \
        HE_GET_BITS(hecap_mac,  \
        IC_HECAP_MAC_UL_2X996_TONE_RU_IDX,    \
        IC_HECAP_MAC_UL_2X996_TONE_RU_BITS)
#define HECAP_MAC_UL2X996TONERU_SET_TO_IC(hecap_mac, value)    \
        HE_SET_BITS(hecap_mac,  \
        IC_HECAP_MAC_UL_2X996_TONE_RU_IDX,    \
        IC_HECAP_MAC_UL_2X996_TONE_RU_BITS, value)

/* OM Control UL MU Data Disable RX Support - Indicates whether an AP supports
 * interpretation of the UL MU Data Disable subfield of the OM Control subfield.
 */
#define HECAP_MAC_OMCTRLULMU_DISRX_GET_FROM_IC(hecap_mac)  \
        HE_GET_BITS(hecap_mac,      \
        IC_HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_IDX,    \
        IC_HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_BITS)
#define HECAP_MAC_OMCTRLULMU_DISRX_SET_TO_IC(hecap_mac, value)    \
        HE_SET_BITS(hecap_mac,      \
        IC_HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_IDX,    \
        IC_HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_BITS, value)

/* Dynamic SM Power Save - Indicates the spatial multiplexing power save mode
 * after receiving a Trigger frame that is in operation immediately after
 * (re)association.
 */
#define HECAP_MAC_DYNAMICSMPS_GET_FROM_IC(hecap_mac)        \
        HE_GET_BITS(hecap_mac,                              \
        IC_HECAP_MAC_DYNAMIC_SM_POWER_SAVE_IDX,             \
        IC_HECAP_MAC_DYNAMIC_SM_POWER_SAVE_BITS)
#define HECAP_MAC_DYNAMICSMPS_SET_TO_IC(hecap_mac, value)   \
        HE_SET_BITS(hecap_mac,                              \
        IC_HECAP_MAC_DYNAMIC_SM_POWER_SAVE_IDX,             \
        IC_HECAP_MAC_DYNAMIC_SM_POWER_SAVE_BITS, value)

/* Punctured Sounding Support - Indicatges support for Punctured Sounding. */
#define HECAP_MAC_PUNCSOUNDSUPP_GET_FROM_IC(hecap_mac)          \
        HE_GET_BITS(hecap_mac,                                  \
        IC_HECAP_MAC_PUNCTURED_SOUND_SUPP_IDX,                  \
        IC_HECAP_MAC_PUNCTURED_SOUND_SUPP_BITS)
#define HECAP_MAC_PUNCSOUNDSUPP_SET_TO_IC(hecap_mac, value)     \
        HE_SET_BITS(hecap_mac,                                  \
        IC_HECAP_MAC_PUNCTURED_SOUND_SUPP_IDX,                  \
        IC_HECAP_MAC_PUNCTURED_SOUND_SUPP_BITS, value)

/* HT and VHT Trigger Frame Rx Support - Indictaes support for receiving a
 * Trigger frame in an HT PPDU and receiving a Trigger frame in a VHT PPDU.
 */
#define HECAP_MAC_HTVHT_TFRXSUPP_GET_FROM_IC(hecap_mac)         \
        HE_GET_BITS(hecap_mac,                                  \
        IC_HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_IDX,               \
        IC_HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_BITS)
#define HECAP_MAC_HTVHT_TFRXSUPP_SET_TO_IC(hecap_mac, value)    \
        HE_SET_BITS(hecap_mac,                                  \
        IC_HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_IDX,               \
        IC_HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_BITS, value)
#endif


/* HE MAC capabilities , field
 * starting idx and no of bits
 * postions as per IE spec
 */
#define HECAP_MAC_HTC_HE_IDX                          0
#define HECAP_MAC_HTC_HE_BITS                         1
#define HECAP_MAC_TWT_REQU_IDX                        1
#define HECAP_MAC_TWT_REQU_BITS                       1
#define HECAP_MAC_TWT_RESP_IDX                        2
#define HECAP_MAC_TWT_RESP_BITS                       1
#define HECAP_MAC_FRAG_IDX                            3
#define HECAP_MAC_FRAG_BITS                           2
#if SUPPORT_11AX_D3
#define HECAP_MAC_MAX_FRAG_MSDUS_EXP_IDX              5
#define HECAP_MAC_MAX_FRAG_MSDUS_EXP_BITS             3
#else
#define HECAP_MAC_MAX_FRAG_MSDUS_IDX                  5
#define HECAP_MAC_MAX_FRAG_MSDUS_BITS                 3
#endif
#define HECAP_MAC_MIN_FRAG_SIZE_IDX                   8
#define HECAP_MAC_MIN_FRAG_SIZE_BITS                  2
#define HECAP_MAC_TRIG_FR_MAC_PADD_DUR_IDX            10
#define HECAP_MAC_TRIG_FR_MAC_PADD_DUR_BITS           2
#if SUPPORT_11AX_D3
#define HECAP_MAC_MULTI_TID_AGGR_RX_IDX               12
#define HECAP_MAC_MULTI_TID_AGGR_RX_BITS              3
#else
#define HECAP_MAC_MULTI_TID_AGGR_IDX                  12
#define HECAP_MAC_MULTI_TID_AGGR_BITS                 3
#endif
#define HECAP_MAC_HTC_HE_LINK_ADAPT_IDX               15
#define HECAP_MAC_HTC_HE_LINK_ADAPT_BITS              2
#define HECAP_MAC_ALL_ACK_IDX                         17
#define HECAP_MAC_ALL_ACK_BITS                        1
#if SUPPORT_11AX_D3
#define HECAP_MAC_TRIG_RESP_SCHED_IDX                 18
#define HECAP_MAC_TRIG_RESP_SCHED_BITS                1
#else
#define HECAP_MAC_UL_MU_RESP_SCHED_IDX                18
#define HECAP_MAC_UL_MU_RESP_SCHED_BITS               1
#endif
#define HECAP_MAC_ACTRL_BSR_IDX                       19
#define HECAP_MAC_ACTRL_BSR_BITS                      1
#define HECAP_MAC_BCAST_TWT_IDX                       20
#define HECAP_MAC_BCAST_TWT_BITS                      1
#define HECAP_MAC_32BIT_BA_BITMAP_IDX                 21
#define HECAP_MAC_32BIT_BA_BITMAP_BITS                1
#define HECAP_MAC_MU_CASCADE_IDX                      22
#define HECAP_MAC_MU_CASCADE_BITS                     1
#define HECAP_MAC_ACK_MULTI_TID_AGGR_IDX              23
#define HECAP_MAC_ACK_MULTI_TID_AGGR_BITS             1
#define HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_IDX         24
#define HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_BITS        1
#define HECAP_MAC_ACTRL_OMI_IDX                       25
#define HECAP_MAC_ACTRL_OMI_BITS                      1
#define HECAP_MAC_OFDMA_RA_IDX                        26
#define HECAP_MAC_OFDMA_RA_BITS                       1
#if SUPPORT_11AX_D3
#define HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_IDX       27
#define HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_BITS      2
#else
#define HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_IDX           27
#define HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_BITS          2
#endif
#define HECAP_MAC_AMSDU_FRAGMENTATION_IDX             29
#define HECAP_MAC_AMSDU_FRAGMENTATION_BITS            1
#define HECAP_MAC_FLEX_TWT_SCHEDULE_IDX               30
#define HECAP_MAC_FLEX_TWT_SCHEDULE_BITS              1
#define HECAP_MAC_RX_CTRL_FR_MULTI_BSS_IDX            31
#define HECAP_MAC_RX_CTRL_FR_MULTI_BSS_BITS           1
#define HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_IDX            32
#define HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_BITS           1
#define HECAP_MAC_QTP_IDX                             33
#define HECAP_MAC_QTP_BITS                            1
#define HECAP_MAC_ACTRL_BQR_IDX                       34
#define HECAP_MAC_ACTRL_BQR_BITS                      1
#if SUPPORT_11AX_D3
#define HECAP_MAC_SRPRESP_IDX                         35
#define HECAP_MAC_SRPRESP_BITS                        1
#else
#define HECAP_MAC_SRRESP_IDX                          35
#define HECAP_MAC_SRRESP_BITS                         1
#endif
#define HECAP_MAC_NDPFDBKRPT_IDX                      36
#define HECAP_MAC_NDPFDBKRPT_BITS                     1
#define HECAP_MAC_OPS_IDX                             37
#define HECAP_MAC_OPS_BITS                            1
#define HECAP_MAC_AMSDUINAMPDU_IDX                    38
#define HECAP_MAC_AMSDUINAMPDU_BITS                   1
#if SUPPORT_11AX_D3
#define HECAP_MAC_MTID_TX_SUP_IDX                     39
#define HECAP_MAC_MTID_TX_SUP_BITS                    3
#define HECAP_MAC_HESUB_CHAN_TX_SUP_IDX               42
#define HECAP_MAC_HESUB_CHAN_TX_SUP_BITS              1
#define HECAP_MAC_UL_2X996_TONE_RU_IDX                43
#define HECAP_MAC_UL_2X996_TONE_RU_BITS               1
#define HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_IDX            44
#define HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_BITS           1
#define HECAP_MAC_DYNAMIC_SM_POWER_SAVE_IDX           45
#define HECAP_MAC_DYNAMIC_SM_POWER_SAVE_BITS          1
#define HECAP_MAC_PUNCTURED_SOUND_SUPP_IDX            46
#define HECAP_MAC_PUNCTURED_SOUND_SUPP_BITS           1
#define HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_IDX         47
#define HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_BITS        1
#define HECAP_MAC_RESERVED_IDX1                       24
#define HECAP_MAC_RESERVED_BITS1                      1
#else
#define HECAP_MAC_RESERVED_IDX                        39
#define HECAP_MAC_RESERVED_BITS                       1
#endif

#define HECAP_MACBYTE_IDX0      0
#define HECAP_MACBYTE_IDX1      1
#define HECAP_MACBYTE_IDX2      2
#define HECAP_MACBYTE_IDX3      3
#define HECAP_MACBYTE_IDX4      4
#define HECAP_MACBYTE_IDX5      5

#define HECAP_TXRX_MCS_NSS_IDX0  0
#define HECAP_TXRX_MCS_NSS_IDX1  1
#define HECAP_TXRX_MCS_NSS_IDX2  2
#define HECAP_TXRX_MCS_NSS_IDX3  3
#define HECAP_TXRX_MCS_NSS_IDX4  4
#define HECAP_TXRX_MCS_NSS_IDX5  5
#define HECAP_TXRX_MCS_NSS_IDX6  6
#define HECAP_TXRX_MCS_NSS_IDX7  7
#define HECAP_TXRX_MCS_NSS_IDX8  8
#define HECAP_TXRX_MCS_NSS_IDX9  9
#define HECAP_TXRX_MCS_NSS_IDX10  10
#define HECAP_TXRX_MCS_NSS_IDX11  11

#define HECAP_TXRX_MCS_NSS_IDX_80    (0)
#define HECAP_TXRX_MCS_NSS_IDX_160   (1)
#define HECAP_TXRX_MCS_NSS_IDX_80_80 (2)

/* HE MAC definitions . Currently
 * using the MASK idx and bits
 * defined above for MAC capabitlies.
 * These macros should be in sync with WMI
 * HE MAC capabilities
 */

/*HTC + HE Support  Set to 1 if STA supports reception of HE Variant HT control Field*/
#define HECAP_MAC_HECTRL_GET_FROM_IE(hecap_mac)   \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX0], \
        HECAP_MAC_HTC_HE_IDX, HECAP_MAC_HTC_HE_BITS)
#define HECAP_MAC_HECTRL_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX0], \
       HECAP_MAC_HTC_HE_IDX, HECAP_MAC_HTC_HE_BITS, value)

/* set to 1 to for TWT Requestor support*/
#define HECAP_MAC_TWTREQ_GET_FROM_IE(hecap_mac)   \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX0], \
       HECAP_MAC_TWT_REQU_IDX, HECAP_MAC_TWT_REQU_BITS)
#define HECAP_MAC_TWTREQ_SET_TO_IE(hecap_mac, value)  \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX0], \
       HECAP_MAC_TWT_REQU_IDX, HECAP_MAC_TWT_REQU_BITS, value)

/* set to 1 to for TWT Responder support*/
#define HECAP_MAC_TWTRSP_GET_FROM_IE(hecap_mac) \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX0], \
        HECAP_MAC_TWT_RESP_IDX, HECAP_MAC_TWT_RESP_BITS)
#define HECAP_MAC_TWTRSP_SET_TO_IE(hecap_mac, value) \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX0], \
        HECAP_MAC_TWT_RESP_IDX, HECAP_MAC_TWT_RESP_BITS, value)

/* Level of frag support
 * Set to 0 for no support for dynamic fragmentation.
 * Set to 1 for support for dynamic fragments that are
 * contained within a S-MPDU
 * Set to 2 for support for dynamic fragments that are
 * contained within a Single MPDU and support for up to
 * one dynamic fragment for each MSDU and each MMPDU within
 * an A-MPDU or multi-TID A-MPDU.
 * Set to 3 for support for dynamic fragments that are
 * contained within a Single MPDU and support for multiple
 * dynamic fragments for each MSDU within an AMPDU or multi-TID
 * AMPDU and up to one dynamic fragment  for each MMPDU in a
 * multi-TID A-MPDU that is not a Single MPDU
*/
#define HECAP_MAC_HEFRAG_GET_FROM_IE(hecap_mac) \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX0], \
        HECAP_MAC_FRAG_IDX, HECAP_MAC_FRAG_BITS)
#define HECAP_MAC_HEFRAG_SET_TO_IE(hecap_mac, value) \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX0], \
        HECAP_MAC_FRAG_IDX, HECAP_MAC_FRAG_BITS, value)

#if SUPPORT_11AX_D3
#define HECAP_MAC_MAXFRAGMSDUEXP_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX0], \
       HECAP_MAC_MAX_FRAG_MSDUS_EXP_IDX, HECAP_MAC_MAX_FRAG_MSDUS_EXP_BITS)
#define HECAP_MAC_MAXFRAGMSDUEXP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX0], \
       HECAP_MAC_MAX_FRAG_MSDUS_EXP_IDX, HECAP_MAC_MAX_FRAG_MSDUS_EXP_BITS, value)
#else
/*
The maximum number of fragmented MSDUs, Nmax,defined
by this field is Nmax = 2 Maximum Number Of FMPDUs
*/
#define HECAP_MAC_MAXFRAGMSDU_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX0], \
       HECAP_MAC_MAX_FRAG_MSDUS_IDX, HECAP_MAC_MAX_FRAG_MSDUS_BITS)
#define HECAP_MAC_MAXFRAGMSDU_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX0], \
       HECAP_MAC_MAX_FRAG_MSDUS_IDX, HECAP_MAC_MAX_FRAG_MSDUS_BITS, value)
#endif

/*
0 =  no restriction on the minimum payload ,
1 = 128 octets min, 2 = 256 octets min, 3 = 512 octets min
*/
#define HECAP_MAC_MINFRAGSZ_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_MIN_FRAG_SIZE_IDX, HECAP_MAC_MIN_FRAG_SIZE_BITS)
#define HECAP_MAC_MINFRAGSZ_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_MIN_FRAG_SIZE_IDX, HECAP_MAC_MIN_FRAG_SIZE_BITS, value)

/*0 = no additional processing time, 1 = 8us,2 = 16us */
#define HECAP_MAC_TRIGPADDUR_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_TRIG_FR_MAC_PADD_DUR_IDX, HECAP_MAC_TRIG_FR_MAC_PADD_DUR_BITS)
#define HECAP_MAC_TRIGPADDUR_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_TRIG_FR_MAC_PADD_DUR_IDX,         \
       HECAP_MAC_TRIG_FR_MAC_PADD_DUR_BITS, value)

#if SUPPORT_11AX_D3
/*
number of TIDs minus 1 of QoS Data frames that HE
STA can aggregate in  multi-TID AMPDU
*/
#define HECAP_MAC_MTIDRXSUP_GET_FROM_IE(hecap_mac)    \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_MULTI_TID_AGGR_RX_IDX, HECAP_MAC_MULTI_TID_AGGR_RX_BITS)
#define HECAP_MAC_MTIDRXSUP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_MULTI_TID_AGGR_RX_IDX, HECAP_MAC_MULTI_TID_AGGR_RX_BITS, value)
#else
#define HECAP_MAC_MTID_GET_FROM_IE(hecap_mac)    \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_MULTI_TID_AGGR_IDX, HECAP_MAC_MULTI_TID_AGGR_BITS)
#define HECAP_MAC_MTID_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX1], \
       HECAP_MAC_MULTI_TID_AGGR_IDX, HECAP_MAC_MULTI_TID_AGGR_BITS, value)
#endif

/*0=No Feedback,2=Unsolicited,3=Both*/
#define HECAP_MAC_HELKAD_GET_FROM_IE(hecap_mac)           \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX1],        \
       HECAP_MAC_HTC_HE_LINK_ADAPT_IDX,                   \
               HECAP_MAC_HTC_HE_LINK_ADAPT_BITS)
#define HECAP_MAC_HELKAD_SET_TO_IE(hecap_mac, value)      \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX1],        \
       HECAP_MAC_HTC_HE_LINK_ADAPT_IDX,                   \
               HECAP_MAC_HTC_HE_LINK_ADAPT_BITS, value)

/*Set to 1 for reception of AllAck support*/
#define HECAP_MAC_AACK_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_ALL_ACK_IDX, HECAP_MAC_ALL_ACK_BITS)
#define HECAP_MAC_AACK_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_ALL_ACK_IDX, HECAP_MAC_ALL_ACK_BITS, value)

/*
Set to 1 if the STA supports reception of the UL
MU Response Scheduling A-Control field
*/
#if SUPPORT_11AX_D3
#define HECAP_MAC_TRSSUP_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_TRIG_RESP_SCHED_IDX, HECAP_MAC_TRIG_RESP_SCHED_BITS)
#define HECAP_MAC_TRSSUP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_TRIG_RESP_SCHED_IDX, HECAP_MAC_TRIG_RESP_SCHED_BITS, value)
#else
#define HECAP_MAC_ULMURSP_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_UL_MU_RESP_SCHED_IDX, HECAP_MAC_UL_MU_RESP_SCHED_BITS)
#define HECAP_MAC_ULMURSP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_UL_MU_RESP_SCHED_IDX, HECAP_MAC_UL_MU_RESP_SCHED_BITS, value)
#endif

/*Set to 1 if the STA supports the BSR A-Control field functionality.*/
#define HECAP_MAC_BSR_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_ACTRL_BSR_IDX, HECAP_MAC_ACTRL_BSR_BITS)
#define HECAP_MAC_BSR_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_ACTRL_BSR_IDX, HECAP_MAC_ACTRL_BSR_BITS, value)

/*Set to 1 when the STA supports broadcast TWT functionality.*/
#define HECAP_MAC_BCSTTWT_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_BCAST_TWT_IDX , HECAP_MAC_BCAST_TWT_BITS)
#define HECAP_MAC_BCSTTWT_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_BCAST_TWT_IDX, HECAP_MAC_BCAST_TWT_BITS, value)

/*Set to 1 if STA supports rx of Multi-STA BA that has 32-bit Block Ack Bitmap*/
#define HECAP_MAC_32BITBA_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
        HECAP_MAC_32BIT_BA_BITMAP_IDX, HECAP_MAC_32BIT_BA_BITMAP_BITS)
#define HECAP_MAC_32BITBA_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_32BIT_BA_BITMAP_IDX, HECAP_MAC_32BIT_BA_BITMAP_BITS, value)

/*Set to 1 if the STA supports MU cascading operation*/
#define HECAP_MAC_MUCASCADE_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_MU_CASCADE_IDX, HECAP_MAC_MU_CASCADE_BITS)
#define HECAP_MAC_MUCASCADE_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_MU_CASCADE_IDX, HECAP_MAC_MU_CASCADE_BITS, value)

/*Set to 1 when the STA supports reception of this multi-TID A-MPDU format*/
#define HECAP_MAC_ACKMTIDAMPDU_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_ACK_MULTI_TID_AGGR_IDX , HECAP_MAC_ACK_MULTI_TID_AGGR_BITS)
#define HECAP_MAC_ACKMTIDAMPDU_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX2], \
       HECAP_MAC_ACK_MULTI_TID_AGGR_IDX, HECAP_MAC_ACK_MULTI_TID_AGGR_BITS, value)

#define HECAP_MAC_GROUPMSTABA_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_IDX,      \
       HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_BITS)
#define HECAP_MAC_GROUPMSTABA_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_IDX,      \
       HECAP_MAC_GROUP_ADDR_MSTA_BA_DLMU_BITS, value)

/*Set to 1 if the STA supports reception of the OMI A-Control field*/
#define HECAP_MAC_OMI_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_ACTRL_OMI_IDX, HECAP_MAC_ACTRL_OMI_BITS)
#define HECAP_MAC_OMI_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_ACTRL_OMI_IDX, HECAP_MAC_ACTRL_OMI_BITS, value)

/*1 if OFDMA Random Access Supported*/
#define HECAP_MAC_OFDMARA_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_OFDMA_RA_IDX, HECAP_MAC_OFDMA_RA_BITS)
#define HECAP_MAC_OFDMARA_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_OFDMA_RA_IDX, HECAP_MAC_OFDMA_RA_BITS, value)

#if SUPPORT_11AX_D3
/*Maximum AMPDU Length Exponent*/
#define HECAP_MAC_MAXAMPDULEN_EXPEXT_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_IDX,    \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_BITS)
#define HECAP_MAC_MAXAMPDULEN_EXPEXT_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_IDX,        \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_EXT_BITS, value)
#else
#define HECAP_MAC_MAXAMPDULEN_EXP_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_IDX,    \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_BITS)
#define HECAP_MAC_MAXAMPDULEN_EXP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_IDX,        \
       HECAP_MAC_MAX_AGGR_MPDU_LEN_EXP_BITS, value)
#endif

/*A-MSDU Fragmentation Support*/
#define HECAP_MAC_AMSDUFRAG_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_AMSDU_FRAGMENTATION_IDX, HECAP_MAC_AMSDU_FRAGMENTATION_BITS)
#define HECAP_MAC_AMSDUFRAG_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_AMSDU_FRAGMENTATION_IDX,          \
       HECAP_MAC_AMSDU_FRAGMENTATION_BITS, value)

/*Flexible TWT Schedule Support*/
#define HECAP_MAC_FLEXTWT_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_FLEX_TWT_SCHEDULE_IDX, HECAP_MAC_FLEX_TWT_SCHEDULE_BITS)
#define HECAP_MAC_FLEXTWT_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_FLEX_TWT_SCHEDULE_IDX, HECAP_MAC_FLEX_TWT_SCHEDULE_BITS, value)

/*Rx Control Frame to MultiBSS*/
#define HECAP_MAC_MBSS_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_RX_CTRL_FR_MULTI_BSS_IDX, HECAP_MAC_RX_CTRL_FR_MULTI_BSS_BITS)
#define HECAP_MAC_MBSS_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3], \
       HECAP_MAC_RX_CTRL_FR_MULTI_BSS_IDX,         \
       HECAP_MAC_RX_CTRL_FR_MULTI_BSS_BITS, value)

/*BSRP A-MPDU Aggregation */
#define HECAP_MAC_BSRP_BQRP_AMPDU_AGGR_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_IDX, HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_BITS)
#define HECAP_MAC_BSRP_BQRP_AMPDU_AGGR_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_IDX, HECAP_MAC_BSPR_BQRP_AMPDU_AGGR_BITS, value)

/* Quiet Time Period (QTP) operation */
#define HECAP_MAC_QTP_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_QTP_IDX, HECAP_MAC_QTP_BITS)
#define HECAP_MAC_QTP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_QTP_IDX, HECAP_MAC_QTP_BITS, value)

/*support by an AP for receiving an (A-)MPDU that contains a BQR in the
  A-Control subfield and support by a non-AP STA for generating an (A-)MPDU
  that contains a BQR in the A-Control subfield */
#define HECAP_MAC_ABQR_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_ACTRL_BQR_IDX, HECAP_MAC_ACTRL_BQR_BITS)
#define HECAP_MAC_ABQR_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_ACTRL_BQR_IDX, HECAP_MAC_ACTRL_BQR_BITS, value)

#if SUPPORT_11AX_D3
/*
support by the STA for the role of SR Responder
*/
#define HECAP_MAC_SRPRESP_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_SRPRESP_IDX, HECAP_MAC_SRPRESP_BITS)
#define HECAP_MAC_SRPRESP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_SRPRESP_IDX, HECAP_MAC_SRPRESP_BITS, value)
#else
#define HECAP_MAC_SRRESP_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_SRRESP_IDX, HECAP_MAC_SRRESP_BITS)
#define HECAP_MAC_SRRESP_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_SRRESP_IDX, HECAP_MAC_SRRESP_BITS, value)
#endif

/*
support for a non-AP STA to follow the NDP feedback report procedure and
respond to the NDP Feedback Report Poll Trigger frame
*/
#define HECAP_MAC_NDPFDBKRPT_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_NDPFDBKRPT_IDX, HECAP_MAC_NDPFDBKRPT_BITS)
#define HECAP_MAC_NDPFDBKRPT_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_NDPFDBKRPT_IDX, HECAP_MAC_NDPFDBKRPT_BITS, value)

/*
support for an AP to encode OPS information to TIM element of the FILS
Discovery frames or TIM frames as described in 27.14.3.2 (AP operation
for opportunistic power save). Indicates support for a non-AP STA to
receive the opportunistic power save encoded TIM elements
*/
#define HECAP_MAC_OPS_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_OPS_IDX, HECAP_MAC_OPS_BITS)
#define HECAP_MAC_OPS_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_OPS_IDX, HECAP_MAC_OPS_BITS, value)

/*
support by a STA to receive an ack-enabled
A-MPDU in which an A-MSDU is carried in a QoS Data frame for
which no block ack agreement exists.
*/
#define HECAP_MAC_AMSDUINAMPDU_GET_FROM_IE(hecap_mac) \
       hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_AMSDUINAMPDU_IDX, HECAP_MAC_AMSDUINAMPDU_BITS)
#define HECAP_MAC_AMSDUINAMPDU_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_AMSDUINAMPDU_IDX, HECAP_MAC_AMSDUINAMPDU_BITS, value)

#if SUPPORT_11AX_D3
/* Multi-TID Aggregation Tx Support - Indicates the number of TIDs of
 * QoS Data frames that an HE STA can transmit in a multi-TID A-MPDU.
 */
#define HECAP_MAC_MTIDTXSUP_GET_FROM_IE(hecap_mac)              \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX4],             \
        IC_HECAP_MAC_MTID_TX_SUP_IDX,                           \
        IC_HECAP_MAC_MTID_TX_SUP_BITS - 2) |                    \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX5],             \
        IC_HECAP_MAC_MTID_TX_SUP_IDX + 1,                       \
        IC_HECAP_MAC_MTID_TX_SUP_BITS - 1) << 1
#define HECAP_MAC_MTIDTXSUP_SET_TO_IE(hecap_mac, value) do {    \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4],             \
        IC_HECAP_MAC_MTID_TX_SUP_IDX,                           \
        IC_HECAP_MAC_MTID_TX_SUP_BITS - 2, (value & 0x1));      \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX5],             \
        HECAP_MAC_MTID_TX_SUP_IDX + 1,                          \
        HECAP_MAC_MTID_TX_SUP_BITS - 1, (value & 0x6));         \
} while(0)

/* HE Subchannel Selective Transmission Support - Indicates whether an HE STA
 * supports an HE subchannel selective transmission operation.
 */
#define HECAP_MAC_HESUBCHAN_TXSUP_GET_FROM_IE(hecap_mac)                    \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX5],                         \
        HECAP_MAC_HESUB_CHAN_TX_SUP_IDX, HECAP_MAC_HESUB_CHAN_TX_SUP_BITS)
#define HECAP_MAC_HESUBCHAN_TXSUP_SET_TO_IE(hecap_mac, value)               \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX5],                         \
        HECAP_MAC_HESUB_CHAN_TX_SUP_IDX,                                    \
        HECAP_MAC_HESUB_CHAN_TX_SUP_BITS, value)

/* UL 2×996-tone RU Support - Indicates support by a STA to receive a TRS
 * Control subfield or a Trigger frame with a User Info field addressed
 * to the STA with the RU Allocation subfield of the TRS Control subfield
 * or the User Info field indicating 2996-tone.
 */
#define HECAP_MAC_UL2X996TONERU_GET_FROM_IE(hecap_mac)  \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX5],      \
        HECAP_MAC_UL_2X996_TONE_RU_IDX, HECAP_MAC_UL_2X996_TONE_RU_BITS)
#define HECAP_MAC_UL2X996TONERU_SET_TO_IE(hecap_mac, value)    \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX5],  \
        HECAP_MAC_UL_2X996_TONE_RU_IDX, HECAP_MAC_UL_2X996_TONE_RU_BITS, value)

/* OM Control UL MU Data Disable RX Support - Indicates whether an AP supports
 * interpretation of the UL MU Data Disable subfield of the OM Control subfield.
 */
#define HECAP_MAC_OMCTRLULMU_DISRX_GET_FROM_IE(hecap_mac)  \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX5],     \
        HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_IDX, HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_BITS)
#define HECAP_MAC_OMCTRLULMU_DISRX_SET_TO_IE(hecap_mac, value)    \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX5],     \
        HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_IDX,    \
        HECAP_MAC_OM_CTRL_UL_MU_DIS_RX_BITS, value)

/* Dynamic SM Power Save - Indicates the spatial multiplexing power save mode
 * after receiving a Trigger frame that is in operation immediately after
 * (re)association.
 */
#define HECAP_MAC_DYNAMICSMPS_GET_FROM_IE(hecap_mac)        \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX5],         \
        HECAP_MAC_DYNAMIC_SM_POWER_SAVE_IDX,                \
        HECAP_MAC_DYNAMIC_SM_POWER_SAVE_BITS)
#define HECAP_MAC_DYNAMICSMPS_SET_TO_IE(hecap_mac, value)   \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX5],         \
        HECAP_MAC_DYNAMIC_SM_POWER_SAVE_IDX,                \
        HECAP_MAC_DYNAMIC_SM_POWER_SAVE_BITS, value)

/* Punctured Sounding Support - Indicatges support for Punctured Sounding. */
#define HECAP_MAC_PUNCSOUNDSUPP_GET_FROM_IE(hecap_mac)          \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX5],             \
        HECAP_MAC_PUNCTURED_SOUND_SUPP_IDX,                     \
        HECAP_MAC_PUNCTURED_SOUND_SUPP_BITS)
#define HECAP_MAC_PUNCSOUNDSUPP_SET_TO_IE(hecap_mac, value)     \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX5],             \
        HECAP_MAC_PUNCTURED_SOUND_SUPP_IDX,                     \
        HECAP_MAC_PUNCTURED_SOUND_SUPP_BITS, value)

/* HT and VHT Trigger Frame Rx Support - Indictaes support for receiving a
 * Trigger frame in an HT PPDU and receiving a Trigger frame in a VHT PPDU.
 */
#define HECAP_MAC_HTVHT_TFRXSUPP_GET_FROM_IE(hecap_mac)         \
        hecap_ie_get(hecap_mac[HECAP_MACBYTE_IDX5],             \
        HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_IDX,                  \
        HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_BITS)
#define HECAP_MAC_HTVHT_TFRXSUPP_SET_TO_IE(hecap_mac, value)    \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX5],             \
        HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_IDX,                  \
        HECAP_MAC_HTVHT_TRIGFRAME_RX_SUPP_BITS, value)

#define HECAP_MAC_RESERVED_SET_TO_IE(hecap_mac, value) do {                 \
        hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX3],                         \
        HECAP_MAC_RESERVED_IDX1, HECAP_MAC_RESERVED_BITS1, value);          \
} while(0)

#else
#define HECAP_MAC_RESERVED_SET_TO_IE(hecap_mac, value) \
       hecap_ie_set(hecap_mac[HECAP_MACBYTE_IDX4], \
       HECAP_MAC_RESERVED_IDX, HECAP_MAC_RESERVED_BITS, value)
#endif

#define HE_CAP_PPET_NSS_RU_BITS_FIXED           7       /* nss(3) bits + ru(4) mask bits */
#define HE_PPET_TOT_RU_BITS                     4       /* 4 bits , each 1 for each ru */
#define HE_TOT_BITS_PPET16_PPET8                6       /* ppet16 3bits + ppet8 3bits */
#define HE_PPET_FIELD                           3       /* 3 bit field */
#define HE_PPET_BYTE                            8       /* 8 bit field */
#define HE_PPET16_PPET8                         2
#define HE_PPET_MAX_BIT_POS_FIT_IN_BYTE         5       /* Max Bit Pos where PPET can fit in a byte */
#define HE_PPET_RGT_ONE_BIT                     4       /* mask out last 2 bit */
#define HE_PPET_RGT_TWO_BIT                     6   	/* mask out last 1 bit */
#define HE_PPET16_PPET8_MASK                    0x07
#define HE_PPET_NONE                            7
#define HE_PPET_MAX_CI                          8       /* 11ax spec defines 8 values of
                                                         * conststallation indexes - 0: BPSK,
                                                         * 1: QPSK etc.
                                                         */




/*
11AX TODO (Phase II) . Width parsing needs to be
revisited for addressing grey areas in width field
*/
#define IEEE80211_HECAP_PHY_CHWIDTH_11AX_BW_ONLY_ZEROOUT_MASK            0x70
#define IEEE80211_HECAP_PHY_CHWIDTH_11AX_HE20_MASK                       0x0
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXG_HE40                           0x1
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXG_HE40_MASK                      0x1
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE40                           0x0
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE40_MASK                      0x2
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE80                           0x2
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE40_HE80_MASK                 0x2
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE160                          0x4
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE40_HE80_HE160_MASK           0x6
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE80_80                        0x8
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_HE40_HE80_HE160_HE80_80_MASK   0xe
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXG_RU_MASK                        0x10
#define IEEE80211_HECAP_PHY_CHWIDTH_11AXA_RU_MASK                        0x20
#define IEEE80211_HECAP_PHY_CHWIDTH_11AX_RU_ONLY_ZEROOUT_MASK            0x4f


/* PPET */
#define IEEE80211_HE_PPET_NUM_SS                0x00000007 /* B0-2 PPET field */
#define IEEE80211_HE_PPET_RU_MASK               0x00000078 /* B3-6 PPET field */
#define IEEE80211_HE_PPET_RU_COUNT_S            3

/* HECAP info internal bits */
#define IEEE80211_HE_0DOT4US_IN_1XLTF_SUPP_BITS      0x1
#define IEEE80211_HE_0DOT4US_IN_2XLTF_SUPP_BITS      0x2
#define IEEE80211_HE_2XLTF_IN_160_80P80_SUPP_BITS    0X4
#define IEEE80211_HE_0DOT4US_IN_1XLTF_SUPP_S         0
#define IEEE80211_HE_0DOT4US_IN_2XLTF_SUPP_S         1
#define IEEE80211_HE_2XLTF_IN_160_80P80_SUPP_S       2
#define IEEE80211_HE_DL_OFDMA_SUPP_S                 3
#define IEEE80211_HE_DL_MUMIMO_SUPP_S                5

#define IEEE80211_HE_DL_MU_SUPPORT_DEFAULT       0
#define IEEE80211_HE_DL_MU_SUPPORT_DISABLE       1
#define IEEE80211_HE_DL_MU_SUPPORT_ENABLE        2
#define IEEE80211_HE_DL_MU_SUPPORT_INVALID       3

#define IEEE80211_HE_PE_DURATION_NONE           0
#define IEEE80211_HE_PE_DURATION_8US            2
#define IEEE80211_HE_PE_DURATION_MAX            4 /* Max value of PE duration
                                                   * in 3 bit subfield in HE
                                                   * OP params field. The unit
                                                   * here is in terms of micro-
                                                   * seconds - value 4 indicates
                                                   * 4*4 = 16 us. Values 5-7 are
                                                   * reserved
                                                   */

/*
 * PPE Threshold Info field format , PPET16 and PPET8 are packed
 * for four RU's in one element of array.
 *
 * ppet16_ppet8_ru3_ru0 array element 0 holds:
 *     |  PPET8 | PPET16 | PPET8  | PPET16 | PPET8  | PPET16 | PPET8  | PPET16 |
 *rsvd |NSS1,RU4|NSS1,RU4|NSS1,RU3|NSS1,RU3|NSS1,RU2|NSS1,RU2|NSS1,RU1|NSS1,RU1|
 *31:23|  22:20 |  19:17 |  17:15 |  14:12 |  11:9  |   8:6  |   5:3  |   2:0  |
 *
 * ppet16_ppet8_ru3_ru0 array element 1 holds:
 *     | PPET8  | PPET16 | PPET8  | PPET16 | PPET8  | PPET16 | PPET8  | PPET16 |
 *rsvd |NSS2,RU4|NSS2,RU4|NSS2,RU3|NSS2,RU3|NSS2,RU2|NSS2,RU2|NSS2,RU1|NSS2,RU1|
 *31:23|  22:20 |  19:17 |  17:15 |  14:12 |  11:9  |   8:6  |   5:3  |   2:0  |
 *
 * etc.
 */

 /*
  * "ru" is one-based, not zero-based, while
  * nssm1 is zero-based.
  */
 #define HE_SET_PPET16(ppet16_ppet8_ru3_ru0, ppet, ru, nssm1) \
     do { \
         (ppet16_ppet8_ru3_ru0)[(nssm1)] &= ~(7 << ((((ru) - 1) % 4) * 6)); \
         (ppet16_ppet8_ru3_ru0)[(nssm1)] |= (((ppet) & 7) << ((((ru) - 1) % 4) * 6)); \
     } while (0)

 #define HE_GET_PPET16(ppet16_ppet8_ru3_ru0, ru, nssm1) \
     (((ppet16_ppet8_ru3_ru0)[(nssm1)] >> ((((ru) - 1) % 4) * 6)) & 7)

 #define HE_SET_PPET8(ppet16_ppet8_ru3_ru0, ppet, ru, nssm1) \
     do { \
         (ppet16_ppet8_ru3_ru0)[(nssm1)] &= ~(7 << ((((ru) - 1) % 4) * 6 + 3)); \
         (ppet16_ppet8_ru3_ru0)[(nssm1)] |= (((ppet) & 7) << ((((ru) - 1) % 4) * 6 + 3)); \
     } while (0)

 #define HE_GET_PPET8(ppet16_ppet8_ru3_ru0, ru, nssm1) \
     (((ppet16_ppet8_ru3_ru0)[(nssm1)] >> ((((ru) - 1) % 4) * 6 + 3)) & 7)

/* Get RU bit set count from RU mask */
#define HE_GET_RU_BIT_SET_COUNT_FROM_RU_MASK(mask, count) \
     while ((mask)) { \
        if((mask) & (0x1))  \
            (count) = (count) +1; \
        (mask) = (mask) >> 1;  \
     }

/* Get next index from RU bit mask and old index*/
#define HE_NEXT_IDX_FROM_RU_MASK_AND_OLD_IDX(mask, idx) \
     while ((mask)) { \
        (idx)++; \
        if((mask) & (0x1)) \
          break;   \
        (mask) = (mask) >> 1; \
     };

#define HE_MCS_NSS_MAP_MASK      0x7
#define HE_NO_OF_BITS_PER_MCS    2
#define HE_ZERO_OUT_TX_RX_BITMAP 0x3f

/* Fill MCS NSS based on hightest MCS and NSS */
#define HE_FILL_MCSNSS_MAP_FROM_MCSNSS(mcs, nss, value, shift) \
    while((nss)) {                                             \
        (value) |= ((mcs) << (shift));                         \
        (shift) = (shift) + HE_NO_OF_BITS_PER_MCS;             \
        (nss) = (nss) -1;                                      \
    }

/* Target sends HE MCS-NSS info for less than equal to 80MHz encoded
 * in the lower 16 bits */
#define HECAP_TXRX_MCS_NSS_GET_LT80_INFO(x) qdf_cpu_to_le32(x) & 0xffff
/* Target sends HE MCS-NSS info for greater than 80MHz encoded in the
 * upper 16 bits */
#define HECAP_TXRX_MCS_NSS_GET_GT80_INFO(x) (qdf_cpu_to_le32(x) >> 16) & 0xffff

/* Get 2*nss bitmask */
/* We are trying to pack 2bit mcs values per nss in a 16 bit
 * wide field. IEEE80211ax spec defines the following format
 * for the 16 bit.
 *
 *    B0     B1   B2      B3   B4      B5  B6      B7 B8      B9 B10    B11 B12    B13  B14   B15
 *    Max HE-MCS  Max HE-MCS   Max HE-MCS  Max HE-MCS Max HE-MCS Max HE-MCS Max HE-MCS  Max HE-MCS
 *    for 1 SS    for 2 SS     for 3 SS    for 4 SS   for 5 SS   for 6 SS   for 7 SS    for 8 SS
 *    2           2            2           2          2          2          2           2
 *
 * The following macro provides a nss*2 bit wide all 1 mask
 */
#define HE_GET_MCS_NSS_PACK_MASK(nss) ((1 << ((nss) << 1)) - 1)
#define HE_GET_MCS_NSS_BITS_TO_PACK(mcsnssmap, nss) \
    (qdf_cpu_to_le16(mcsnssmap) & HE_GET_MCS_NSS_PACK_MASK(nss))

/* This macro derives 2 bit mcs value corresponding
 * to 'nss' ss from 'bits'
 */
#define mcsbits(bits, nss)                               \
    (((bits) >> (((nss)-1) << 1)) & 0x3)

/* This macro provides the intersection of 2 bit mcs value.
 * The result of the intersection is leftshifted by 2*(nss-1)
 * bits so that it positioned correctly in a 16 bit mcsnssmap
 */
#define INTERSECT_MCS_BITS(selfmcs, peermcs, nss)           \
     (((((selfmcs) == 0x3) || ((peermcs) == 0x3)) ? 0x3 :   \
      MIN(selfmcs, peermcs)) << (((nss)-1) << 1))

/* Intersect 16 bit self-mcsnssmap with 16bit peer-mcsnssmap */
/* IEEE80211ax spec defines the following format for the 16 bit.
 *
 *    B0     B1   B2      B3   B4      B5  B6      B7 B8      B9 B10    B11 B12    B13  B14   B15
 *    Max HE-MCS  Max HE-MCS   Max HE-MCS  Max HE-MCS Max HE-MCS Max HE-MCS Max HE-MCS  Max HE-MCS
 *    for 1 SS    for 2 SS     for 3 SS    for 4 SS   for 5 SS   for 6 SS   for 7 SS    for 8 SS
 *    2           2            2           2          2          2          2           2
 *
 * The following macro provides an intersection of self vs peer
 * mcsnssmap
 */
#define INTERSECT_11AX_MCSNSS_MAP(self, peer)                                \
  (((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 1), mcsbits(peer, 1), 1))) | \
   ((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 2), mcsbits(peer, 2), 2))) | \
   ((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 3), mcsbits(peer, 3), 3))) | \
   ((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 4), mcsbits(peer, 4), 4))) | \
   ((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 5), mcsbits(peer, 5), 5))) | \
   ((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 6), mcsbits(peer, 6), 6))) | \
   ((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 7), mcsbits(peer, 7), 7))) | \
   ((uint16_t)(INTERSECT_MCS_BITS(mcsbits(self, 8), mcsbits(peer, 8), 8))))

/* Derive nss from mcsnssmap */
#define HE_DERIVE_PEER_NSS_FROM_MCSMAP(mcsnssmap, nss) {                      \
    uint16_t temp_mcsnssmap = mcsnssmap;                                      \
    nss = MAX_HE_NSS;                                                         \
    while (nss && ((qdf_cpu_to_le16(temp_mcsnssmap) & 0x03)                   \
                != HE_MCS_VALUE_INVALID)) {                                   \
        temp_mcsnssmap = qdf_cpu_to_le16(temp_mcsnssmap) >>                   \
                            HE_NBITS_PER_SS_IN_HE_MCS_NSS_SET;                \
        nss--;                                                                \
    }                                                                         \
    nss = MAX_HE_NSS - nss;                                                   \
}

/* Derive max mcs value from mcsnssmap */
#define HE_DERIVE_MAX_MCS_VALUE(mcsnssmap, nss, maxmcs) {                     \
    uint8_t temp_nss = 0;                                                     \
    uint8_t mcs      = HE_MCS_VALUE_INVALID;                                  \
    maxmcs           = HE_MCS_VALUE_INVALID;                                  \
    if (nss > 0) {                                                            \
        /* Considering there may be invalid mcs values
         * at the beginning of the mcsnss map, initialize
         * maxmcs with the first valid mcs value in the map
         */                                                                   \
        while ((temp_nss < nss) && (maxmcs == HE_MCS_VALUE_INVALID)) {        \
            maxmcs = (qdf_cpu_to_le16(mcsnssmap) >>                           \
                     (temp_nss*HE_NBITS_PER_SS_IN_HE_MCS_NSS_SET)) & 0x03;    \
            temp_nss++;                                                       \
        }                                                                     \
        while(temp_nss < nss) {                                               \
            mcs = (qdf_cpu_to_le16(mcsnssmap) >>                              \
                  (temp_nss*HE_NBITS_PER_SS_IN_HE_MCS_NSS_SET)) & 0x03;       \
            if ((mcs != HE_MCS_VALUE_INVALID) && (mcs > maxmcs)) {            \
                maxmcs = mcs;                                                 \
            }                                                                 \
            temp_nss++;                                                       \
        }                                                                     \
    }                                                                         \
}

#if SUPPORT_11AX_D3
#define HE_CAP_OFFSET_TO_PPET (20)
#else
#define HE_CAP_OFFSET_TO_PPET (17)
#endif
/* We have per nss 2 bit mss value in a 2 octet fiels for
 * a prticular band as per 11ax spec. RxMCS and TxMCS each
 * has 2 octets for a prticular band (<=80, 160 and 80_80).
 * This function resets the mcs values to '11' (not supported)
 * for the not supported SSs in a particular band.
 */
static inline void HE_RESET_MCS_VALUES_FOR_UNSUPPORTED_SS(u_int8_t *mcsnssmap,
                                                          u_int8_t nss) {
    u_int8_t nssmask;
    if (nss <= 4) {
        nssmask       = ~HE_GET_MCS_NSS_PACK_MASK(nss);
        mcsnssmap[0] |= nssmask;
        mcsnssmap[1] = 0xff;
    } else if (nss > 4 && nss <=8 ){
        nssmask       = ~HE_GET_MCS_NSS_PACK_MASK(nss - 4);
        mcsnssmap[0] &= 0xff;
        mcsnssmap[1] |= nssmask;
    }
}

#define IEEE80211_IS_HECAP_MACINFO(hecap_macinfo)  \
    ((hecap_macinfo)[HECAP_MACBYTE_IDX0] ||        \
     (hecap_macinfo)[HECAP_MACBYTE_IDX1] ||        \
     (hecap_macinfo)[HECAP_MACBYTE_IDX2] ||        \
     (hecap_macinfo)[HECAP_MACBYTE_IDX3])


#define HE_PPET16_PPET8_SIZE                            (8)

/*
 * 802.11ax PPE (PPDU packet Extension) threshold
 *
 */
struct ieee80211_he_ppe_threshold {
        u_int32_t numss_m1; /** NSS - 1*/
        u_int32_t ru_mask; /** RU Bit mask */
        u_int32_t ppet16_ppet8_ru3_ru0[HE_PPET16_PPET8_SIZE]; /** ppet8 and ppet16 for max num ss */
};

#define HE_DEFAULT_SS_IN_MCS_NSS_SET                    (1)
#define HE_RESRVD_BITS_FOR_ALL_SS_IN_HE_MCS_NSS_SET     (0xFFFFFF)
#define HE_INVALID_MCSNSSMAP                            (0xFFFFFFFF)
#define HE_MCS_VALUE_INVALID                            (0x03)
#define HE_MCS_VALUE_FOR_MCS_0_11                       (0x02)
#define HE_MCS_VALUE_FOR_MCS_0_9                        (0x01)
#define HE_MCS_VALUE_FOR_MCS_0_7                        (0x00)
#define HE_NBITS_PER_SS_IN_HE_MCS_NSS_SET               (0x02)
#define HE_NBYTES_MCS_NSS_FIELD_PER_BAND                (4)
#define HE_UNUSED_MCSNSS_NBYTES                         (12) /* no of unused bytes
                                                                taken by the mcsnss field */
#define HE_MAC_TRIGPADDUR_VALUE_RESERVED                (0x0)

#define HEHANDLE_CAP_PHYINFO_SIZE       3
#define HEHANDLE_CAP_TXRX_MCS_NSS_SIZE  3
#if SUPPORT_11AX_D3
#define HECAP_PHYINFO_SIZE              11
#define HECAP_MACINFO_SIZE              6
#else
#define HECAP_PHYINFO_SIZE              9
#define HECAP_MACINFO_SIZE              5
#endif
#define HECAP_TXRX_MCS_NSS_SIZE         12
#define HECAP_PPET16_PPET8_MAX_SIZE     25

#define HEOP_PARAM_RTS_THRSHLD_DURATION_DISABLED_VALUE 0x3ff

#if SUPPORT_11AX_D3
#define IEEE80211_HEOP_DEFAULT_PE_DUR_MASK      0x00000007 /* B0 - 2 */
#define IEEE80211_HEOP_DEFAULT_PE_DUR_S         0
#define IEEE80211_HEOP_TWT_REQUIRED_MASK        0x00000008 /* B3 */
#define IEEE80211_HEOP_TWT_REQUIRED_S           3
#define IEEE80211_HEOP_RTS_THRESHOLD_MASK       0x00003FF0 /* B4 - 13*/
#define IEEE80211_HEOP_RTS_THRESHOLD_S          4
#define IEEE80211_HEOP_VHTOP_PRESENT_MASK       0x00004000 /* B14 */
#define IEEE80211_HEOP_VHTOP_PRESENT_S          14
#define IEEE80211_HEOP_CO_LOCATED_BSS_MASK      0x00008000 /* B15 */
#define IEEE80211_HEOP_CO_LOCATED_BSS_S         15
#define IEEE80211_HEOP_ER_SU_DISABLE_MASK       0X00010000 /* B16 */
#define IEEE80211_HEOP_ER_SU_DISABLE_S          16
#define IEEE80211_HEOP_RESERVED_MASK            0x00FE0000 /* B17 - 23*/
#define IEEE80211_HEOP_RESERVED_S               17

#define IEEE80211_HEOP_BSS_COLOR_MASK           0x3F /* B0 - 5 */
#define IEEE80211_HEOP_BSS_COLOR_S              0
#define IEEE80211_HEOP_PARTIAL_BSS_COLOR_MASK   0x40 /* B6 */
#define IEEE80211_HEOP_PARTIAL_BSS_COLOR_S      6
#define IEEE80211_HEOP_BSS_COLOR_DISABLD_MASK   0x80 /* B7 */
#define IEEE80211_HEOP_BSS_COLOR_DISABLD_S      7
#else
#define IEEE80211_HEOP_BSS_COLOR_MASK           0x0000003F /* B0-5 */
#define IEEE80211_HEOP_BSS_COLOR_S              0
#define IEEE80211_HEOP_DEFAULT_PE_DUR_MASK      0x000001C0 /* B6-8 */
#define IEEE80211_HEOP_DEFAULT_PE_DUR_S         6
#define IEEE80211_HEOP_TWT_REQUIRED_MASK        0x00000200 /* B9 */
#define IEEE80211_HEOP_TWT_REQUIRED_S           9
#define IEEE80211_HEOP_RTS_THRESHOLD_MASK       0x000FFC00 /* B10- 19*/
#define IEEE80211_HEOP_RTS_THRESHOLD_S          10
#define IEEE80211_HEOP_PARTIAL_BSS_COLOR_MASK   0x00100000 /* B20 */
#define IEEE80211_HEOP_PARTIAL_BSS_COLOR_S      20
#define IEEE80211_HEOP_VHTOP_PRESENT_MASK       0x00200000 /* B21 */
#define IEEE80211_HEOP_VHTOP_PRESENT_S          21
#define IEEE80211_HEOP_RESERVED_MASK            0x0FC00000 /* B22-27 */
#define IEEE80211_HEOP_RESERVED_S               22
#define IEEE80211_HEOP_MULT_BSSID_AP_MASK       0x10000000 /* B28 */
#define IEEE80211_HEOP_MULT_BSSID_AP_S          28
#define IEEE80211_HEOP_TX_MBSSID_MASK           0x20000000 /* B29 */
#define IEEE80211_HEOP_TX_MBSSID_S              29
#define IEEE80211_HEOP_BSS_COLOR_DISABLD_MASK   0x40000000 /* B30 */
#define IEEE80211_HEOP_BSS_COLOR_DISABLD_S      30
#define IEEE80211_HEOP_RESERVED1_MASK           0x80000000 /* B31 */
#define IEEE80211_HEOP_RESERVED1_S              31

#define IEEE80211_HEOP_MCS_NSS_MASK             0x00FFFFFF /* B31 */

#endif

#if SUPPORT_11AX_D3
struct he_op_param {
    u_int16_t   def_pe_dur:3,          /* HE default Packet Extension duration */
                twt_required:1,        /* HE TWT required  */
                rts_threshold:10,      /* HE RTS threshold duration */
                vht_op_info_present:1, /* VHT Op Info field is present
                                        * in the HEOP IE or not
                                        */
                co_located_bss:1;      /* AP transmitting this element
                                        * belongs to a Multiple BSSID
                                        * set or not
                                        */
    u_int8_t    er_su_disable:1,       /* 242-tone HE ER SU PPDU reception*/
                reserved:7;            /* 1 bit reserved field */
};

struct he_op_bsscolor_info {
    u_int8_t    bss_color:6,           /* HE BSS color */
                part_bss_color:1,      /* HE partial BSS color */
                bss_color_dis:1;       /* HE BSS color disabled */
};


#else
struct he_op_param {
    u_int32_t   bss_color:6,           /* HE BSS color */
                def_pe_dur:3,          /* HE default Packet Extension duration */
                twt_required:1,        /* HE TWT required  */
                rts_threshold:10,      /* HE RTS threshold duration */
                part_bss_color:1,      /* HE partial BSS color */
                vht_op_info_present:1, /* VHT Op Info field is present
                                        * in the HEOP IE or not
                                        */
                reserved:6,            /* 6 bit reserved field */
                multiple_bssid_ap:1,   /* AP transmitting this element
                                        * belongs to a Multiple BSSID
                                        * set or not
                                        */
                tx_mbssid:1,           /* HE Transmit MBSSID*/
                bss_color_dis:1,       /* HE BSS color disabled */
                reserved_1:1;          /* 1 bit reserved field */
};
#endif

struct ieee80211_he_handle {
        u_int8_t                            hecap_macinfo[HECAP_MACINFO_SIZE];
        u_int16_t                           hecap_rxmcsnssmap[HEHANDLE_CAP_TXRX_MCS_NSS_SIZE];
        u_int16_t                           hecap_txmcsnssmap[HEHANDLE_CAP_TXRX_MCS_NSS_SIZE];
        u_int32_t                           hecap_phyinfo[HEHANDLE_CAP_PHYINFO_SIZE];
        struct ieee80211_he_ppe_threshold   hecap_ppet;      /* PPDU packet Extension) threshold */
        u_int32_t                           heop_param;      /* HE OP Info */
        u_int32_t                           hecap_info_internal;
#if SUPPORT_11AX_D3
        u_int8_t                            heop_bsscolor_info; /* HE BSS Color information */
#endif

};

/*
 * 802.11ax HE Capability
 * with cabability & PPE (PPDU packet Extension) threshold
 */
struct ieee80211_ie_hecap {
        u_int8_t                  elem_id;
        u_int8_t                  elem_len;
        u_int8_t                  elem_id_ext;
        u_int8_t                  hecap_macinfo[HECAP_MACINFO_SIZE];
        u_int8_t                  hecap_phyinfo[HECAP_PHYINFO_SIZE];
        u_int8_t                  hecap_txrx[HECAP_TXRX_MCS_NSS_SIZE];
        u_int8_t                  hecap_ppet[HECAP_PPET16_PPET8_MAX_SIZE];
} __packed;

#if SUPPORT_11AX_D3
#define HEOP_PARAM               3
#define HEOP_PARAM_S             24
#else
#define HEOP_PARAM               4
#endif
#define HEOP_MCS_NSS             2
#define HEOP_VHT_OPINFO          3
#define HEOP_MAX_BSSID_INDICATOR 1

#define IEEE80211_HE_VHT_CAP_MAX_AMPDU_LEN_FACTOR 20
#define IEEE80211_HE_HT_CAP_MAX_AMPDU_LEN_FACTOR 16

/*
 * 802.11ax HE Operation IE with OP IE param
 */
struct ieee80211_ie_heop {
        u_int8_t        elem_id;
        u_int8_t        elem_len;
        u_int8_t        elem_id_ext;
        u_int8_t        heop_param[HEOP_PARAM];
#if SUPPORT_11AX_D3
        u_int8_t        heop_bsscolor_info;
#endif
        u_int8_t        heop_mcs_nss[HEOP_MCS_NSS];
        u_int8_t        heop_vht_opinfo[HEOP_VHT_OPINFO];
        u_int8_t        heop_max_bssid_indicator;
} __packed;

struct ieee80211_ie_hebsscolor_change {
        u_int8_t        elem_id;
        u_int8_t        elem_len;
        u_int8_t        elem_id_ext;
        u_int8_t        color_switch_cntdown;
        u_int8_t        new_bss_color; /* B0-B5: new bss color; B6-B7: reserved */
};

/*
 * 802.11n Secondary Channel Offset element
 */
#define IEEE80211_SEC_CHAN_OFFSET_BYTES             3 /* size of sec chan offset element */
#define IEEE80211_SEC_CHAN_OFFSET_SCN               0 /* no secondary channel */
#define IEEE80211_SEC_CHAN_OFFSET_SCA               1 /* secondary channel above */
#define IEEE80211_SEC_CHAN_OFFSET_SCB               3 /* secondary channel below */

struct ieee80211_ie_sec_chan_offset {
     u_int8_t    elem_id;
     u_int8_t    len;
     u_int8_t    sec_chan_offset;
} __packed;

/*
 * 802.11ac Transmit Power Envelope element
 */
#define IEEE80211_VHT_TXPWR_IS_SUB_ELEMENT          1  /* It checks whether its  sub element */
#define IEEE80211_VHT_TXPWR_IS_VENDOR_SUB_ELEMENT   2  /* It checks whether its  sub element of vendor specific element */
#define IEEE80211_VHT_TXPWR_MAX_POWER_COUNT         4 /* Max TX power elements valid */
#define IEEE80211_VHT_TXPWR_NUM_POWER_SUPPORTED     4 /* Max TX power elements supported */
#define IEEE80211_VHT_TXPWR_LCL_MAX_PWR_UNITS_SHFT  3 /* B3-B5 Local Max transmit power units */

struct ieee80211_ie_vht_txpwr_env {
        u_int8_t    elem_id;
        u_int8_t    elem_len;
        u_int8_t    txpwr_info;       /* Transmit Power Information */
        u_int8_t    local_max_txpwr[4]; /* Local Max TxPower for 20,40,80,160MHz */
} __packed;

/*
 * 802.11ac Wide Bandwidth Channel Switch Element
 */

#define IEEE80211_VHT_EXTCH_SWITCH             1   /* For extension channel switch */
#define CHWIDTH_VHT20                          20  /* Channel width 20 */
#define CHWIDTH_VHT40                          40  /* Channel width 40 */
#define CHWIDTH_VHT80                          80  /* Channel width 80 */
#define CHWIDTH_VHT160                         160 /* Channel width 160 */

#define CHWIDTH_20                             20  /* Channel width 20 */
#define CHWIDTH_40                             40  /* Channel width 40 */
#define CHWIDTH_80                             80  /* Channel width 80 */
#define CHWIDTH_160                            160 /* Channel width 160 */

struct ieee80211_ie_wide_bw_switch {
        u_int8_t    elem_id;
        u_int8_t    elem_len;
        u_int8_t    new_ch_width;       /* New channel width */
        u_int8_t    new_ch_freq_seg1;   /* Channel Center frequency 1 */
        u_int8_t    new_ch_freq_seg2;   /* Channel Center frequency 2 */
} __packed;

#define IEEE80211_RSSI_RX       0x00000001
#define IEEE80211_RSSI_TX       0x00000002
#define IEEE80211_RSSI_EXTCHAN  0x00000004
#define IEEE80211_RSSI_BEACON   0x00000008
#define IEEE80211_RSSI_RXDATA   0x00000010

#define IEEE80211_RATE_TX 0
#define IEEE80211_RATE_RX 1
#define IEEE80211_LASTRATE_TX 2
#define IEEE80211_LASTRATE_RX 3
#define IEEE80211_RATECODE_TX 4
#define IEEE80211_RATECODE_RX 5
#define IEEE80211_RATEFLAGS_TX 6
#define IEEE80211_RATEFLAGS_RX 7

#define IEEE80211_MAX_RATE_PER_CLIENT 10
/* Define for the P2P Wildcard SSID */
#define IEEE80211_P2P_WILDCARD_SSID         "DIRECT-"

#define IEEE80211_P2P_WILDCARD_SSID_LEN     (sizeof(IEEE80211_P2P_WILDCARD_SSID) - 1)

#ifdef WIN32
#include <poppack.h>
#endif

#define IEEE80211_MAX_IFNAME 16

struct ieee80211_clone_params {
	char		icp_name[IEEE80211_MAX_IFNAME];	/* device name */
	u_int16_t	icp_opmode;		/* operating mode */
	u_int32_t	icp_flags;		/* see IEEE80211_CLONE_BSSID for e.g */
    u_int8_t icp_bssid[IEEE80211_ADDR_LEN];    /* optional mac/bssid address */
        int32_t         icp_vapid;             /* vap id for MAC addr req */
    u_int8_t icp_mataddr[IEEE80211_ADDR_LEN];    /* optional MAT address */
};

#define	    IEEE80211_CLONE_BSSID       0x0001		/* allocate unique mac/bssid */
#define	    IEEE80211_NO_STABEACONS	    0x0002		/* Do not setup the station beacon timers */
#define    IEEE80211_CLONE_WDS          0x0004      /* enable WDS processing */
#define    IEEE80211_CLONE_WDSLEGACY    0x0008      /* legacy WDS operation */

#define LIST_STA_SPLIT_UNIT 8

/*
 * Station information block; the mac address is used
 * to retrieve other data like stats, unicast key, etc.
 */
struct ieee80211req_sta_info {
        u_int16_t       isi_len;                /* length (mult of 4) */
        u_int16_t       isi_freq;               /* MHz */
        int32_t         isi_nf;                 /* noise floor */
        u_int16_t       isi_ieee;               /* IEEE channel number */
        u_int32_t       awake_time;             /* time is active mode */
        u_int32_t       ps_time;                /* time in power save mode */
        u_int64_t       isi_flags;              /* channel flags */
        u_int16_t       isi_state;              /* state flags */
        u_int8_t        isi_authmode;           /* authentication algorithm */
        int8_t          isi_rssi;
    int8_t          isi_min_rssi;
    int8_t          isi_max_rssi;
        u_int16_t       isi_capinfo;            /* capabilities */
        u_int16_t       isi_pwrcapinfo;         /* power capabilities */
        u_int8_t        isi_athflags;           /* Atheros capabilities */
        u_int8_t        isi_erp;                /* ERP element */
    u_int8_t    isi_ps;         /* psmode */
        u_int8_t        isi_macaddr[IEEE80211_ADDR_LEN];
        u_int8_t        isi_nrates;
                                                /* negotiated rates */
        u_int8_t        isi_rates[IEEE80211_RATE_MAXSIZE];
        u_int8_t        isi_txrate;             /* index to isi_rates[] */
    u_int32_t   isi_txratekbps; /* tx rate in Kbps, for 11n */
        u_int16_t       isi_ie_len;             /* IE length */
        u_int16_t       isi_associd;            /* assoc response */
        u_int16_t       isi_txpower;            /* current tx power */
        u_int16_t       isi_vlan;               /* vlan tag */
        u_int16_t       isi_txseqs[17];         /* seq to be transmitted */
        u_int16_t       isi_rxseqs[17];         /* seq previous for qos frames*/
        u_int16_t       isi_inact;              /* inactivity timer */
        u_int8_t        isi_uapsd;              /* UAPSD queues */
        u_int8_t        isi_opmode;             /* sta operating mode */
        u_int8_t        isi_cipher;
        u_int32_t       isi_assoc_time;         /* sta association time */
        struct timespec isi_tr069_assoc_time;   /* sta association time in timespec format */


    u_int16_t   isi_htcap;      /* HT capabilities */
    u_int32_t   isi_rxratekbps; /* rx rate in Kbps */
                                /* We use this as a common variable for legacy rates
                                   and lln. We do not attempt to make it symmetrical
                                   to isi_txratekbps and isi_txrate, which seem to be
                                   separate due to legacy code. */
        /* XXX frag state? */
        /* variable length IE data */
    u_int32_t isi_maxrate_per_client; /* Max rate per client */
        u_int16_t   isi_stamode;        /* Wireless mode for connected sta */
    u_int32_t isi_ext_cap;              /* Extended capabilities */
    u_int32_t isi_ext_cap2;              /* Extended capabilities 2 */
    u_int32_t isi_ext_cap3;              /* Extended capabilities 3 */
    u_int32_t isi_ext_cap4;              /* Extended capabilities 4 */
    u_int8_t isi_nss;         /* number of tx and rx chains */
    u_int8_t isi_is_256qam;    /* 256 QAM support */
    u_int8_t isi_operating_bands : 2; /* Operating bands */
#if ATH_SUPPORT_EXT_STAT
    u_int8_t  isi_chwidth;            /* communication band width */
    u_int32_t isi_vhtcap;             /* VHT capabilities */
#endif
#if ATH_EXTRA_RATE_INFO_STA
    u_int8_t isi_tx_rate_mcs;
    u_int8_t isi_tx_rate_flags;
    u_int8_t isi_rx_rate_mcs;
    u_int8_t isi_rx_rate_flags;
#endif
    u_int8_t isi_curr_op_class;
    u_int8_t isi_num_of_supp_class;
    u_int8_t isi_supp_class[MAX_NUM_OPCLASS_SUPPORTED];
    u_int8_t isi_nr_channels;
    u_int8_t isi_first_channel;
    u_int16_t isi_curr_mode;
    u_int8_t isi_beacon_measurement_support;
};

u_int32_t
hecap_ie_get(u_int8_t *hecap, u_int8_t idx, u_int32_t
                tot_bits);

#define IEEE80211_MAX_2G_SUPPORTED_CHAN 14
#define IEEE80211_OVERLAPPING_INDEX_MAX 5

/*
 * Extender information element.
 */
struct ieee80211_ie_extender {
    u_int8_t    ie_id;     /* IEEE80211_ELEMID_VENDOR */
    u_int8_t    ie_len;    /* length in bytes */
    u_int8_t    ie_oui[3]; /* 0x00, 0x50, 0xf2 */
    u_int8_t    ie_type;   /* OUI type */
    u_int8_t    extender_info;
} __packed;

#if QCN_ESP_IE
/* ESP element format
 */
struct ieee80211_est_ie{
    u_int8_t element_id;
    u_int8_t len;
    u_int8_t element_id_extension;
    u_int8_t esp_information_list[0];
} __packed;

/* ESP Information Field Attribute
 */
struct ieee80211_esp_info_field{
    u_int8_t esp_info_field_head;
    u_int8_t air_time_fraction;
    u_int8_t ppdu_duration_target;
} __packed;
#endif /* QCN_ESP_IE */


/* MBSS IE elements */
struct ieee80211_mbss_ie {
    struct ieee80211_ie_header header;
    u_int8_t max_bssid_indicator;
};
struct ieee80211_mbss_ie_capability {
    struct ieee80211_ie_header hdr;
    u_int8_t non_tx_cap[2];
} __packed;;
struct ieee80211_mbss_ie_ssid {
    struct ieee80211_ie_header hdr;
    uint8_t  ssid[IEEE80211_NWID_LEN+1];
} __packed;;
struct ieee80211_mbss_ie_bssid_index {
    struct ieee80211_ie_header hdr;
    u_int8_t bssid_idx;
    u_int8_t dtim_period;
    u_int8_t dtim_count;
} __packed;

/* Enum to switch between Manual,
 * host and FW dynamic method of
 * selecting MU Edca Params.
 */
enum {
    HEMUEDCA_MANUAL_MODE = 0,
    HEMUEDCA_HOST_DYNAMIC_MODE = 1,
    HEMUEDCA_FW_DYNAMIC_MODE = 2,
    HEMUEDCA_MODE_MAX = 3,
};

enum {
    FW_MUEDCA_DYNAMIC_MODE_DISABLE = 0,
    FW_MUEDCA_DYNAMIC_MODE_ENABLE = 1,
};
#endif /* _NET80211_IEEE80211_H_ */

