/*
 * Copyright (c) 2016,2017 Qualcomm Innovation Center, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 *
 * 2016 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */
#ifndef __QWRAP_STRUCTURE_H
#define __QWRAP_STRUCTURE_H
#define THERMAL_LEVELS                              4

struct qwrap_config_t
{
    u_int8_t addr[6];
    u_int32_t status;
    u_int32_t primary_radio;
    u_int32_t proxy_noack_war;
    u_int32_t force_client_mcast;
    char max_priority_radio[IFNAMSIZ];
};

struct th_level_config_t {
    u_int32_t tmplwm;            /* sensor value in celsius when to exit to lower state */
    u_int32_t tmphwm;            /* sensor value in celsius when to exit to higher state */
    u_int32_t dcoffpercent;      /* duty cycle off percent 0-100. 0 means no off, 100 means no on (shutdown the phy). */
    u_int32_t priority;          /* disable only the queues that have lower priority than configured. 0 means disable all queues */
    u_int32_t policy;            /* thermal throttling policy for this level */
};

struct th_config_t {
    u_int32_t log_lvl;                                   /* Log level */
    u_int32_t enable;                                    /* 0:disable, 1:enable */
    u_int32_t dc;                                        /* duty cycle in ms */
    u_int32_t dc_per_event;                              /* how often (for how many duty cycles) the FW sends stats to host */
    struct th_level_config_t levelconf[THERMAL_LEVELS];  /* per zone config parameters */
};
struct th_level_stats_t {
    u_int32_t levelcount;        /* count of each time TT entered this state */
    u_int32_t dccount;           /* total number of duty cycles spent in this state. */
                                 /* this number increments by one each time we are in this state and we finish one full duty cycle. */
};

struct th_stats_t {
    struct th_level_stats_t levstats[THERMAL_LEVELS];    /* stats for each level */
    int32_t temp;                                        /* Temperature reading in celsius */
    u_int32_t level;                                     /* current level */
};

struct tmd_level_config_t {
    u_int32_t level;
    u_int32_t dcoffpercent;
    u_int8_t cfg_ready;
};

struct thermal_param {
    u_int32_t                   tt_support;
    struct th_config_t          th_cfg;
    struct th_stats_t           th_stats;
    struct tmd_level_config_t   tmd_cfg;
};

struct iface_config_t {
    u_int16_t timeout;
    u_int8_t iface_mgr_up;
    u_int8_t stavap_up;
    int is_preferredUplink;
    u_int8_t cac_state;
};
#endif
