/*
 *  Copyright (c) 2014,2017-2018 Qualcomm Innovation Center, Inc.
 *
 *  All Rights Reserved.
 *  Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 *
 *  2014 Qualcomm Atheros, Inc.  All rights reserved.
 *
 *  Qualcomm is a trademark of Qualcomm Technologies Incorporated, registered in the United
 *  States and other countries.  All Qualcomm Technologies Incorporated trademarks are used with
 *  permission.  Atheros is a trademark of Qualcomm Atheros, Inc., registered in
 *  the United States and other countries.  Other products and brand names may be
 *  trademarks or registered trademarks of their respective owners. 
 */

#ifndef _IEEE80211_WNM_PROTO_H_
#define _IEEE80211_WNM_PROTO_H_ 

#include <sys/queue.h>

/*
 * Wireless Network management Protocol definitions
 */

/* categories */
#define IEEE80211_ACTION_CAT_WNM    10   /* Wireless Network Management */
#define IEEE80211_ACTION_CAT_UNPROTECTED_WNM    11   /* UnProtected WNM */


/* WNM action fields */
#define IEEE80211_ACTION_TIM_FRAME     0
#define IEEE80211_ACTION_BSTM_QUERY    6
#define IEEE80211_ACTION_BSTM_REQ      7
#define IEEE80211_ACTION_BSTM_RESP     8
#define IEEE80211_ACTION_FMS_REQ       9 
#define IEEE80211_ACTION_FMS_RESP      10
#define IEEE80211_ACTION_TFS_REQ       13
#define IEEE80211_ACTION_TFS_RESP      14
#define IEEE80211_ACTION_TFS_NOTIFY    15
#define IEEE80211_ACTION_WNMSLEEP_REQ  16
#define IEEE80211_ACTION_WNMSLEEP_RESP 17
#define IEEE80211_ACTION_TIM_REQ       18
#define IEEE80211_ACTION_TIM_RESP      19
#define IEEE80211_ACTION_WNM_REQ       26

/* Information Element IDs */
#define IEEE80211_ELEMID_WNMSLEEP_MODE  93
enum {
    IEEE80211_SUBELEMID_KEYDATA_GTK = 0,
    IEEE80211_SUBELEMID_KEYDATA_IGTK = 1,
};

#define IEEE80211_WNMSLEEP_ACTION_ENTER 0
#define IEEE80211_WNMSLEEP_ACTION_EXIT  1

/* WNM action frame dialogtokens */
#define IEEE80211_ACTION_RM_TOKEN    1

#define IEEE80211_TFS_DELETE   0x01
#define IEEE80211_TFS_NOTIFY   0x02
#define IEEE80211_IPV4_LEN 4
#define IEEE80211_IPV6_LEN 16

#define IEEE80211_FMS_MAX_COUNTERS     8
#define IEEE80211_FMS_STATUS_SUBELE    1
#define IEEE80211_TCLASS_STATUS_SUBELE 2

#define IEEE80211_FMS_SUBELEMENT_ID 1

#define IEEE80211_WNM_NETLINKBUF 4096
#define MAC_ADDR_LEN 6

#define IEEE80211_BSSTERM_DURATION_SUBELEMENT_ID    4

typedef struct wnm_netlink_event {
    u_int32_t type;
    u_int8_t mac[MAC_ADDR_LEN];
    u_int32_t datalen;
    u_int8_t event_data[IEEE80211_WNM_NETLINKBUF];
}__packed wnm_netlink_event_t;


enum {
    IEEE80211_WNM_TIMREQUEST_ACCEPT,
    IEEE80211_WNM_TIMREQUEST_ACCEPT_VALID_TSF,
    IEEE80211_WNM_TIMREQUEST_DENIED,
    IEEE80211_WNM_TIMREQUEST_OVERRIDDEN,
};
enum {
    IEEE80211_WNM_FMSSUBELE_ACCEPT,
    IEEE80211_WNM_FMSSUBELE_DENY_FORMAT,
    IEEE80211_WNM_FMSSUBELE_DENY_RESOURCES,
    IEEE80211_WNM_FMSSUBELE_DENY_CLASSIFIER,
    IEEE80211_WNM_FMSSUBELE_DENY_POLICY,
    IEEE80211_WNM_FMSSUBELE_DENY_UNSPECIFIED,
    IEEE80211_WNM_FMSSUBELE_ALTE_DEL_ITVL,
    IEEE80211_WNM_FMSSUBELE_ALTE_POLICY,
    IEEE80211_WNM_FMSSUBELE_ALTE_DEL_ITVL_CHANGE,
    IEEE80211_WNM_FMSSUBELE_ALTE_MCAST_RATE_CHANGE,
    IEEE80211_WNM_FMSSUBELE_TERM_POLICY_CHANGE,
    IEEE80211_WNM_FMSSUBELE_TERM_LACK_RESOURCES,
    IEEE80211_WNM_FMSSUBELE_TERM_HIGHER_PRI,
    IEEE80211_WNM_FMSSUBELE_ALTE_MAX_DEL_ITVL_CHG,
    IEEE80211_WNM_FMSSUBELE_ALTE_TCLASS,
    IEEE80211_WNM_FMSSUBELE_RESERVED,
};


struct tclas_type3 {
    u_int16_t filter_offset;
    u_int8_t  *filter_value;
    u_int8_t  *filter_mask;
    u_int8_t  filter_len;
} __packed;


struct tclas_type14_v4 {
    u_int8_t  version;
    u_int8_t  src_ip[IEEE80211_IPV4_LEN];
    u_int8_t  dst_ip[IEEE80211_IPV4_LEN];
    u_int16_t src_port;
    u_int16_t dst_port;
    u_int8_t  dscp;
    u_int8_t  protocol;
    u_int8_t  reserved;
} __packed;

struct tclas_type14_v6 {
    u_int8_t version;
    u_int8_t  src_ip[IEEE80211_IPV6_LEN];
    u_int8_t  dst_ip[IEEE80211_IPV6_LEN];
    u_int16_t src_port;
    u_int16_t dst_port;
    u_int8_t  type4_dscp;
    u_int8_t  type4_next_header;
    u_int8_t  flow_label[3];
} __packed;

typedef struct tclas_element {
    u_int8_t  elemid;
    u_int8_t  len;
    u_int8_t  up;
    u_int8_t  type;
    u_int8_t  mask;
    union {
        union {
            struct tclas_type14_v4  type14_v4;
            struct tclas_type14_v6  type14_v6;
        } type14;
        struct tclas_type3  type3;
    } tclas;
    TAILQ_ENTRY(tclas_element) tclas_next;
} ieee80211_tclas_element;

typedef struct ieee80211_tclas_processing {
    u_int8_t elem_id;
    u_int8_t length;
    u_int8_t tclas_process;
} __packed ieee80211_tclas_processing;
    

typedef struct ieee80211_tfs_subelement_rsp {
    u_int8_t elem_id;
    u_int8_t length;
    u_int8_t status;
    u_int8_t tfsid;
    TAILQ_ENTRY(ieee80211_tfs_subelement_rsp) tsub_next;
} __packed ieee80211_tfs_subelement_rsp;

typedef struct ieee80211_tfs_subelement_req {
    TAILQ_HEAD(, tclas_element) tclas_head;
    u_int8_t elem_id;
    u_int8_t length;
    struct ieee80211_tclas_processing tclasprocess;
    TAILQ_ENTRY(ieee80211_tfs_subelement_req) tsub_next;
} ieee80211_tfs_subelement_req;

typedef struct ieee80211_tfs_response {
    TAILQ_ENTRY(ieee80211_tfs_response) tfs_rsp_next;
    u_int8_t tfs_elemid;
    u_int8_t length;
    TAILQ_HEAD(, ieee80211_tfs_subelement_rsp) tfs_rsp_sub;
} __packed ieee80211_tfs_response;

typedef struct ieee80211_tfs_request {
    TAILQ_ENTRY(ieee80211_tfs_request) tfs_req_next;
    u_int8_t tfs_elemid;
    u_int8_t length;
    u_int8_t tfs_id;
    u_int8_t tfs_action_code;
    TAILQ_HEAD(, ieee80211_tfs_subelement_req) tfs_req_sub;
} ieee80211_tfs_request;

struct ieee80211_tfsreq {
    u_int8_t dialogtoken;
    TAILQ_HEAD(, ieee80211_tfs_request) tfs_req_head;
};

struct ieee80211_tfsrsp {
    u_int8_t dialogtoken;
    TAILQ_HEAD(, ieee80211_tfs_response) tfs_rsp_head;
}__packed;

/**
 * @brief BSS Transition Management response status codes 
 * Taken from 802.11v standard 
 */
enum IEEE80211_WNM_BSTM_RESP_STATUS {
    IEEE80211_WNM_BSTM_RESP_SUCCESS,
    IEEE80211_WNM_BSTM_RESP_REJECT_UNSPECIFIED,
    IEEE80211_WNM_BSTM_RESP_REJECT_INSUFFICIENT_BEACONS,
    IEEE80211_WNM_BSTM_RESP_REJECT_INSUFFICIENT_CAPACITY,
    IEEE80211_WNM_BSTM_RESP_REJECT_BSS_TERMINATION_UNDESIRED,
    IEEE80211_WNM_BSTM_RESP_REJECT_BSS_TERMINATION_DELAY,
    IEEE80211_WNM_BSTM_RESP_REJECT_STA_CANDIDATE_LIST_PROVIDED,
    IEEE80211_WNM_BSTM_RESP_REJECT_NO_SUITABLE_CANDIDATES,
    IEEE80211_WNM_BSTM_RESP_REJECT_LEAVING_ESS,

    IEEE80211_WNM_BSTM_RESP_INVALID
};

/* BSTM MBO/QCN Transition Rejection Reason Code */
enum IEEE80211_BSTM_REJECT_REASON_CODE {
    IEEE80211_BSTM_REJECT_REASON_UNSPECIFIED,
    IEEE80211_BSTM_REJECT_REASON_FRAME_LOSS_RATE,        /* Excessive frame loss rate is expected by STA */
    IEEE80211_BSTM_REJECT_REASON_DELAY_FOR_TRAFFIC,      /* Excessive traffic delay will be incurred this time */
    IEEE80211_BSTM_REJECT_REASON_INSUFFICIENT_CAPACITY,  /* Insufficient QoS capacity for current traffic stream expected by STA */
    IEEE80211_BSTM_REJECT_REASON_LOW_RSSI,               /* STA receiving low RSSI in frames from suggested channel(s) */
    IEEE80211_BSTM_REJECT_REASON_HIGH_INTERFERENCE,      /* High Interference is expected at the candidate channel(s) */
    IEEE80211_BSTM_REJECT_REASON_SERVICE_UNAVAILABLE,    /* Required services by STA are not available on requested channel */

    IEEE80211_BSTM_REJECT_REASON_INVALID                 /* value 7 - 255 is reserved and considered invalid */
};

/* BSTM MBO/QCN Transition Request Reason Code */
enum IEEE80211_BSTM_REQ_REASON_CODE {
    IEEE80211_BSTM_REQ_REASON_UNSPECIFIED,
    IEEE80211_BSTM_REQ_REASON_FRAME_LOSS_RATE,
    IEEE80211_BSTM_REQ_REASON_DELAY_FOR_TRAFFIC,
    IEEE80211_BSTM_REQ_REASON_INSUFFICIENT_BANDWIDTH,
    IEEE80211_BSTM_REQ_REASON_LOAD_BALANCING,
    IEEE80211_BSTM_REQ_REASON_LOW_RSSI,
    IEEE80211_BSTM_REQ_REASON_EXCESSIVE_RETRANSMISSION,
    IEEE80211_BSTM_REQ_REASON_HIGH_INTERFERENCE,
    IEEE80211_BSTM_REQ_REASON_GRAY_ZONE,
    IEEE80211_BSTM_REQ_REASON_PREMIUM_AP,

    IEEE80211_BSTM_REQ_REASON_INVALID
};

struct ieee80211_bstm_reqinfo {
    u_int8_t dialogtoken;
    u_int8_t candidate_list;
    u_int8_t disassoc;
    u_int16_t disassoc_timer;
    u_int8_t validity_itvl;
    u_int8_t bssterm_inc;
    u_int64_t bssterm_tsf;
    u_int16_t bssterm_duration;
    u_int8_t abridged;
} __packed;

/* candidate BSSID for BSS Transition Management Request */
struct ieee80211_bstm_candidate {
    /* candidate BSSID */
    u_int8_t bssid[MAC_ADDR_LEN];
    /* channel number for the candidate BSSID */
    u_int8_t channel_number;
    /* preference from 1-255 (higher number = higher preference) */
    u_int8_t preference;
    /* operating class */
    u_int8_t op_class;
    /* PHY type */
    u_int8_t phy_type;
} __packed;

/* maximum number of candidates in the list.  Value 3 was selected based on a
   2 AP network, so may be increased if needed */
#define ieee80211_bstm_req_max_candidates 3
/* BSS Transition Management Request information that can be specified via ioctl */
struct ieee80211_bstm_reqinfo_target {
    u_int8_t dialogtoken;
    u_int8_t num_candidates;
#if QCN_IE
    /*If we use trans reason code in QCN IE */
    u_int8_t qcn_trans_reason;
#endif
    struct ieee80211_bstm_candidate candidates[ieee80211_bstm_req_max_candidates];
    u_int8_t trans_reason;
    u_int8_t disassoc;
    u_int16_t disassoc_timer;
} __packed;

/*
 * When user, via "wifitool athX setbssidpref mac_addr pref_val"
 * command enters a bssid with preference value needed to
 * be assigned to that bssid, it is stored in a structure
 * as given below
 */
struct ieee80211_user_bssid_pref {
    u_int8_t bssid[MAC_ADDR_LEN];
    u_int8_t pref_val;
    u_int8_t regclass;
    u_int8_t chan;
}__packed;

struct ieee80211_bssterm_duration {
    u_int8_t sub_id;
    u_int8_t len;
    u_int64_t tsf;
    u_int16_t duration;
} __packed;

enum IEEE80211_TFS_ERRORS {
    IEEE80211_TFS_ACCEPT = 0,
    IEEE80211_TFS_INVALID_CLASSIFIER,
    IEEE80211_TFS_RESOURCE_UNAVAILABLE,
    IEEE80211_TFS_REASON_UNKNOWN = 5,
};

/* Flexible Multicast Service(FMS) Types */

typedef struct ieee80211_rate_identifier_s {
    u_int8_t mask;
    u_int8_t mcs_idx;
    u_int16_t rate;
}__packed ieee80211_fms_rate_identifier_t;

typedef struct ieee80211_fmsreq_subele_s
{
    TAILQ_ENTRY(ieee80211_fmsreq_subele_s) fmssubele_next;
    u_int8_t accepted;
    u_int8_t num_tclas;
    u_int8_t elem_id;
    u_int8_t len;
    u_int8_t del_itvl;
    u_int8_t max_del_itvl;
    ieee80211_fms_rate_identifier_t rate_id;
    u_int8_t mcast_addr[6];
    TAILQ_HEAD(, tclas_element) tclas_head;
    struct ieee80211_tclas_processing tclasprocess;
}__packed ieee80211_fmsreq_subele_t;


typedef struct ieee80211_fms_subelement_status_s 
{
    TAILQ_ENTRY (ieee80211_fms_subelement_status_s) subele_status_next;
    u_int8_t len;
    u_int8_t element_status;
    u_int8_t del_itvl;
    u_int8_t max_del_itvl;
    u_int8_t fmsid;
    u_int8_t fms_counter;
    ieee80211_fms_rate_identifier_t rate_id;
    u_int8_t mcast_addr[6];
}ieee80211_fms_subelement_status_t;

typedef struct ieee80211_tclass_subelement_status_s
{
    u_int8_t subelementid;
    u_int8_t len;
    u_int8_t fmsid;
    TAILQ_HEAD(, tclas_element) tclas_head;
    ieee80211_tclas_processing tclasprocess;
}ieee80211_tclass_subelement_status_t;

typedef struct ieee80211_fms_status_subelement_s 
{
    TAILQ_ENTRY(ieee80211_fms_status_subelement_s) status_subele_next;
    u_int8_t subelementid;
    void     *subele_status;
}ieee80211_fms_status_subelement_t;

typedef struct ieee80211_fms_response_s
{ 
    TAILQ_ENTRY(ieee80211_fms_response_s) fmsrsp_next;
    u_int8_t elemid;
    u_int8_t len;
    u_int8_t fms_token;
    TAILQ_HEAD(, ieee80211_fms_status_subelement_s) status_subele_head;
}ieee80211_fms_response_t;


typedef struct ieee80211_fms_request_s {
    TAILQ_ENTRY(ieee80211_fms_request_s) fmsreq_next;
    u_int8_t elem_id;
    u_int8_t len;
    u_int8_t fms_token;
    TAILQ_HEAD(, ieee80211_fmsreq_subele_s) fmssubele_head;
}ieee80211_fms_request_t;

struct ieee80211_wnmreq {
    u_int8_t dialog_token;
    u_int8_t type;
    u_int8_t elem_id;
};
typedef struct ieee80211_fmsreq_active_element {
    TAILQ_ENTRY(ieee80211_fmsreq_active_element) fmsreq_act_next;
    u_int8_t fms_token;
    TAILQ_HEAD(, ieee80211_fms_act_stream_ptr) fmsact_strmptr_head;
}ieee80211_fmsreq_active_element_t;

struct ieee80211_fmsreq {
    u_int8_t dialog_token;
    TAILQ_HEAD(, ieee80211_fms_request_s) fmsreq_head;
};
struct ieee80211_fmsrsp {
    u_int8_t dialog_token;
    TAILQ_HEAD(, ieee80211_fms_response_s) fmsrsp_head;
};

typedef struct ieee80211_fms_action_hdr_s {
    u_int8_t  ia_category;
    u_int8_t  ia_action;
    u_int8_t  dialogtoken;
    u_int8_t  fms_ies[1];
} __packed ieee80211_fms_action_hdr_t;

typedef struct ieee80211_fms_status_tclass_subelement_s {
    u_int8_t subelement_id;
    u_int8_t len;
    u_int8_t fmsid;
    u_int8_t tclass_elements[1];
}__packed ieee80211_fms_status_tclass_subelement_t;

typedef struct ieee80211_fms_status_subelements_s {
    u_int8_t subelement_id;
    u_int8_t len;
    u_int8_t element_status;
    u_int8_t del_itvl;
    u_int8_t max_del_itvl;
    u_int8_t fmsid;
    u_int8_t fms_counter;
    ieee80211_fms_rate_identifier_t rate_id;
    u_int8_t mcast_addr[6];
}__packed ieee80211_fms_status_subelements_t;

typedef struct ieee80211_fms_hdr_s {
    u_int8_t elementid;
    u_int8_t len;
    u_int8_t fms_token;
}__packed ieee80211_fms_hdr_t;

typedef struct ieee80211_fms_descr_s {
    u_int8_t elementid;
    u_int8_t len;
    u_int8_t num_ctrs;
    u_int8_t fms_ctrs[1];
}__packed ieee80211_fms_descr_t;

typedef struct ieee80211_fms_req_s {
    ieee80211_fms_hdr_t hdr;
    u_int8_t subelements[1];
}__packed ieee80211_fms_req_t;

typedef struct ieee80211_fms_resp_s {
    ieee80211_fms_hdr_t hdr;
    u_int8_t subelements[1];
}__packed ieee80211_fms_resp_t;

#endif /* _IEEE80211_WNM_PROTO_H_ */
