/*
 * Copyright (c) 2017 Qualcomm Innovation Center, Inc.
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 *
 */

#ifndef _WLAN_ATF_UTILS_DEFS_H_
#define _WLAN_ATF_UTILS_DEFS_H_

/* Disable ATF */
#define ATF_DISABLED                     0
/* ATF airtime based */
#define ATF_AIRTIME_BASED                1
/* Throughput based */
#define ATF_TPUT_BASED                   2
/* 1 - Strict, 0 - Fair */
#define ATF_SCHED_STRICT                 0x00000001
#define ATF_SCHED_OBSS                   0x00000002
#define ATF_GROUP_SCHED_POLICY           0x00000004
/* Factor used to convert airtime between user space and driver */
#define ATF_AIRTIME_CONVERSION_FACTOR    10
/* Maximum number of clients supported for ATF */
#define ATF_ACTIVED_MAX_CLIENTS          50
/* Maximum number of SSID group supported for ATF */
#define ATF_ACTIVED_MAX_ATFGROUPS        16
/* Maximum number of subgroups supported for ATF */
#define ATF_ACTIVED_MAX_SUBGROUPS        20
/* Number of VDEV in AP mode can be configured under PDEV */
#define ATF_CFG_NUM_VDEV                 16
#define ATF_CFG_GLOBAL_INDEX             0
#define ATF_PER_NOT_ALLOWED              1
#define ATF_SSID_NOT_EXIST               2

#define ATF_TPUT_MASK                    0x00ffffff
#define ATF_AIRTIME_MASK                 0xff000000
#define ATF_AIRTIME_SHIFT                24
#define ATF_SHOW_PER_PEER_TABLE          1
#define SSID_MAX_LEN                     32
#define MAC_ADDR_SIZE                    6
#define WME_NUM_AC                       4

/* Block traffic on all TID's */
#define ATF_TX_BLOCK_AC_ALL              0xF

/**
 * enum ATF_PEER_CFG - ATF Peer configuration Type
 *
 * @ATF_PEER_CFG_HIERARCHY: Peer configured for a particular SSID/ group
 *
 * @ATF_PEER_CFG_GLOBAL: Global peer airtime configuration
 *
 * @ATF_PEER_CFG_UNCONFIGURED: Peer is not configured with airtime value
 *
 * @ATF_PEER_CFG_NOTASSOCIATED: Peer is not connected to SSID/ GROUP
 *
 * This is used in the ATF algorithm to manage Peer based allocation.
 *
 */
enum ATF_PEER_CFG {
	ATF_PEER_CFG_HIERARCHY = 0x1,
	ATF_PEER_CFG_GLOBAL,
	ATF_PEER_CFG_UNCONFIGURED,
	ATF_PEER_CFG_NOTASSOCIATED,
};

/**
 * enum ATF_BUFFER_ALLOC_STATUS - ATF Buffer Allocation Status
 *
 * @ATF_BUF_ALLOC: Alloc Buffer
 *
 * @ATF_BUF_NOALLOC: Do not allocate buffer
 *
 * @ATF_BUF_ALLOC_SKIP: Skip ATF Buffer alloc
 *
 * This is being used internally to manage ATF Buffer Allocation.
 */
typedef enum {
	ATF_BUF_ALLOC,
	ATF_BUF_NOALLOC,
	ATF_BUF_ALLOC_SKIP
}ATF_BUFFER_ALLOC_STATUS;

/**
 * struct atfcntbl - Structure for ATF config table element
 * @ssid            : SSID
 * @sta_mac         : STA MAC address
 * @value           : value to configure
 * @info_mark       : 1 -- STA, 0 -- VDEV
 * @assoc_status    : 1 -- Yes, 0 -- No
 * @all_tokens_used : 1 -- Yes, 0 -- No
 * @cfg_value       : Config value
 * @atf_ac_cfg      : Set if AC rule is configured
 * @grpname         : Group name
 */
struct atfcntbl {
	u_int8_t     ssid[SSID_MAX_LEN + 1];
	u_int8_t     sta_mac[MAC_ADDR_SIZE];
	u_int32_t    value;
	u_int8_t     info_mark;
	u_int8_t     assoc_status;
	u_int8_t     all_tokens_used;
	u_int32_t    cfg_value;
	u_int8_t     atf_ac_cfg;
	u_int8_t     grpname[SSID_MAX_LEN + 1];
};

struct atf_data {
	u_int16_t     id_type;
	u_int8_t      *buf;
	u_int32_t     len;
};

/**
 * struct atftable - ATF table
 * @id_type             : Sub command
 * @atf_info            : Array of atfcntbl
 * @info_cnt            : Count of info entry
 * @busy                : Busy state flag
 * @atf_group           : Group ID
 * @show_per_peer_table : Flag to show per peer table
 */
struct atftable {
	u_int16_t         id_type;
	struct atfcntbl   atf_info[ATF_ACTIVED_MAX_CLIENTS + ATF_CFG_NUM_VDEV];
	u_int16_t         info_cnt;
	u_int8_t          atf_status;
	u_int32_t         busy;
	u_int32_t         atf_group;
	u_int8_t          show_per_peer_table;
};

/**
 * struct atfgroups - ATF group table element
 * @grpname       : Group name
 * @grp_num_ssid  : Number of ssids added in this group
 * @grp_cfg_value : Airtime for this group
 * @grp_sched     : Group scheduling policy
 * @grp_ssid      : List of SSIDs in the group
 */
struct atfgroups {
	u_int8_t    grpname[SSID_MAX_LEN + 1];
	u_int32_t   grp_num_ssid;
	u_int32_t   grp_cfg_value;
	u_int8_t    grp_sched;
	u_int8_t    grp_ssid[ATF_CFG_NUM_VDEV][SSID_MAX_LEN + 1];
};

/** struct atfsubgroup_tbl - ATF subgroup table element
 * @subgrpname       : Subgroup name
 * @subgrp_type      : Subgroup type - SSID/PEER/AC
 * @subgrp_value     : Airtime allocated for this subgroup
 * @subgrp_cfg_value : Airtime configured by user
 * @subgrp_ac_id     : Access category
 * @peermac          : Peer MAC
 */
struct atfsubgroup_tbl {
	u_int8_t    subgrpname[SSID_MAX_LEN + 1];
	u_int8_t    subgrp_type;
	u_int32_t   subgrp_value;
	u_int32_t   subgrp_cfg_value;
	u_int8_t    subgrp_ac_id;
	u_int8_t    peermac[MAC_ADDR_SIZE];
};

/** struct atfgroup_list - ATF group list entry
 * @grpname      : Group name
 * @num_subgroup : Num of subgroups in this group
 * @grp_value    : Group Airtime
 * @sg_table     : Subgroup table
 */
struct atfgroup_list {
	u_int8_t                grpname[SSID_MAX_LEN + 1];
	u_int32_t               num_subgroup;
	u_int32_t               grp_value;
	struct atfsubgroup_tbl sg_table[ATF_ACTIVED_MAX_SUBGROUPS];
};

/** struct atfgrouplist_table - ATF group list table
 * @id_type    : ID type
 * @info_cnt   : Info count
 * @atf_list   : ATF group list entry
 */
struct atfgrouplist_table {
	u_int16_t             id_type;
	u_int16_t             info_cnt;
	struct atfgroup_list atf_list[ATF_ACTIVED_MAX_ATFGROUPS];
};

/**
 * struct atfgrouptable - ATF group table
 * @id_type    : Sub command
 * @atf_groups : List of ATF groups
 * @info_cnt   : Number os entries in groups list
 */
struct atfgrouptable {
	u_int16_t         id_type;
	struct atfgroups  atf_groups[ATF_ACTIVED_MAX_ATFGROUPS];
	u_int16_t         info_cnt;
};

/**
 * struct macaddr - WMI MAC address
 * @mac_addr31to0:  upper 4 bytes of  MAC address
 * @mac_addr47to32: lower 2 bytes of  MAC address
 */
struct macaddr {
	u_int32_t   mac_addr31to0;
	u_int32_t   mac_addr47to32;
};

/**
 * struct pdev_atf_req - ATF request
 * @num_peers:            Number of peers
 * @percentage_unit:      Percentage unit
 * @struct atf_peer_info: ATF peer info
 * @    peer_macaddr:    Peer MAC address
 * @    percentage_peer: Peer percentage
 * @    vdev_id:         Associated vdev ID
 * @    pdev_id:         Associated pdev ID
 */
struct pdev_atf_req {
	u_int32_t   num_peers;
	u_int32_t   percentage_uint;
	struct {
		struct macaddr   peer_macaddr;
		u_int32_t        percentage_peer;
		u_int32_t        vdev_id;
		u_int32_t        pdev_id;
	} atf_peer_info[ATF_ACTIVED_MAX_CLIENTS];
};

/**
 * struct pdev_atf_peer_ext_request - Peer extended request
 * @num_peers:                Number of peers
 * @struct atf_peer_ext_info: Array of extended info
 * @    peer_macaddr:        Peer MAC address
 * @    group_index:         Group index it belongs to
 * @    atf_units_reserved:  Peer congestion threshold for future use
 * @    vdev_id:             Associated vdev ID
 * @    pdev_id:             Associated pdev ID
 */
struct pdev_atf_peer_ext_request {
	u_int32_t   num_peers;
	struct {
		struct macaddr   peer_macaddr;
		u_int32_t        group_index;
		u_int32_t        atf_units_reserved;
		u_int16_t        vdev_id;
		u_int16_t        pdev_id;
	} atf_peer_ext_info[ATF_ACTIVED_MAX_CLIENTS];
};

/**
 * struct pdev_atf_ssid_group_req - WMI request for ATF group
 * @num_groups:            Number of groups
 * @struct atf_group_info: Group details
 * @percentage_group:         Alloted percentage to group
 * @atf_group_units_reserved: Group congestion threshold for future use
 * @pdev_id:                  Associated pdev_id
 */
struct pdev_atf_ssid_group_req {
	u_int32_t   num_groups;
	struct {
		u_int32_t   percentage_group;
		u_int32_t   atf_group_units_reserved;
		u_int32_t   pdev_id;
	} atf_group_info[ATF_ACTIVED_MAX_ATFGROUPS];
};

/**
 * struct pdev_atf_group_wmm_ac_req - WMI request for ATF AC group
 * @num_groups:            Number of groups
 * @struct atf_group_wmm_ac_info: WMM AC configuration
 * @atf_config_ac_be:         Alloted percentage to BE Access Category
 * @atf_config_ac_bk:         Alloted percentage to BK Access Category
 * @atf_config_ac_vi:         Alloted percentage to VI Access Category
 * @atf_config_ac_vo:         Alloted percentage to VO Access Category
 * @reserved:                 Reserved for future use
 */
struct pdev_atf_group_wmm_ac_req {
	u_int32_t    num_groups;
	struct{
		u_int32_t    atf_config_ac_be;/* Relative ATF % for BE */
		u_int32_t    atf_config_ac_bk;/* Relative ATF % for BK */
		u_int32_t    atf_config_ac_vi;/* Relative ATF % for VI */
		u_int32_t    atf_config_ac_vo;/* Relative ATF % for VO */
		u_int32_t    reserved[2];
	}atf_group_wmm_ac_info[ATF_ACTIVED_MAX_ATFGROUPS];
};

/**
 * struct pdev_bwf_req - WMI radio specific Bandwidth fairness request data
 * @num_peers:            Number of peers
 * @reserved:             Reserved
 * @struct bwf_peer_info: Peer details for Bandwidth fairness
 * @    peer_macaddr: Peer MAC address
 * @    throughput:   Allocated throughput
 * @    max_airtime:  Maximum airtime
 * @    priority:     priority
 * @    reserved:     Reserved
 * @    vdev_id:      Associated vdev ID
 * @    pdev_id:      Associated pdev ID
 */
struct pdev_bwf_req {
	u_int32_t   num_peers;
	u_int32_t   reserved[8];
	struct {
		struct macaddr   peer_macaddr;
		u_int32_t        throughput;
		u_int32_t        max_airtime;
		u_int32_t        priority;
		u_int32_t        reserved[4];
		u_int32_t        vdev_id;
		u_int32_t        pdev_id;
	} bwf_peer_info[ATF_ACTIVED_MAX_CLIENTS];
};

/**
 * struct atf_peerstate - ATF peerstate
 * @peerstate:        peerstate
 * @atf_tidbitmap:    Bitmap indicating the TID
 * @subgroup_name:    Subgroup name to which peer belongs
 */
struct atf_peerstate {
	u_int32_t peerstate;
	u_int32_t atf_tidbitmap;
	u_int8_t  subgroup_name[WME_NUM_AC][SSID_MAX_LEN + 1];
};

/**
 * struct atf_stats - ATF statistics
 * @tokens:                         tokens distributed by strictq/fairq
 * @act_tokens:                     tokens available, after adjustemnt of
 *                                  excess consumed in prev cycle
 * @total:                          total tokens distributed by strictq/fairq
 * @contribution:                   tokens contributed by this node
 * @tot_contribution:               tokens contributed by all nodes
 * @borrow:                         tokens borrowed by this node
 * @unused:                         tokens not used
 * @pkt_drop_nobuf:                 packets dropped as node is already holding
 *                                  it's share of tx buffers
 * @allowed_bufs:                   max tx buffers that this node can hold
 * @max_num_buf_held:               max tx buffers held by this node
 * @min_num_buf_held:               min tx buffers held by this node
 * @num_tx_bufs:                    packets sent for this node
 * @num_tx_bytes:                   bytes sent for this node
 * @tokens_common:                  tokens distributed by strictq/fairq
 *                                  (for non-atf nodes)
 * @act_tokens_common:              tokens available, after adjustemnt of
 *                                  excess consumed in prev cycle
 *                                  (for non-atf nodes)
 * @timestamp:                      time when stats are updated
 * @unusedtokens_percent:           weighted unused tokens percent
 * @weighted_unusedtokens_percent:  weighted unused tokens percent
 * @raw_tx_tokens:                  raw tokens
 * @throughput:                     attainable throughput assuming 100% airtime
 * @contr_level:                    Level of contribution
 * @atftidstate:                    TID state
 * @tokens_unassigned:              unassigned tokens in the previous cycle
 * @total_used_tokens:              total of used tokens
 * @group_name:                     Group name
 * @subgroup_name:                  Subgroup name
 */
struct atf_stats {
	u_int32_t   tokens;
	u_int32_t   act_tokens;
	u_int32_t   total;
	u_int32_t   contribution;
	u_int32_t   tot_contribution;
	u_int32_t   borrow;
	u_int32_t   unused;
	u_int32_t   pkt_drop_nobuf;
	u_int16_t   allowed_bufs;
	u_int16_t   max_num_buf_held;
	u_int16_t   min_num_buf_held;
	u_int16_t   num_tx_bufs;
	u_int32_t   num_tx_bytes;
	u_int32_t   tokens_common;
	u_int32_t   act_tokens_common;
	u_int32_t   timestamp;
	u_int32_t   unusedtokens_percent;
	u_int32_t   weighted_unusedtokens_percent;
	u_int32_t   raw_tx_tokens;
	u_int32_t   throughput;
	u_int32_t   contr_level;
	u_int32_t   atftidstate;
	u_int32_t   tokens_unassigned;
	u_int64_t   total_used_tokens;
	u_int8_t    group_name[SSID_MAX_LEN + 1];
	u_int8_t    subgroup_name[SSID_MAX_LEN + 1];
};

/**
 * struct atf_debug_req_t - ATF debug structure
 * @ptr:    Buffer pointer
 * @size:   Buffer size
 */
typedef struct {
	void        *ptr;
	u_int32_t   size;
} atf_debug_req_t;

#endif /* _WLAN_ATF_UTILS_DEFS_H_*/
