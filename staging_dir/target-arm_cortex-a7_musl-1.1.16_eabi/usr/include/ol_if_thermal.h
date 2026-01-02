/*
 * Copyright (c) 2014,2017 Qualcomm Innovation Center, Inc.
 *
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Innovation Center, Inc.
 *
 * 2014 Qualcomm Atheros, Inc..
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef __OL_IF_THERMAL_H
#define __OL_IF_THERMAL_H
#include <qwrap_structure.h>
#define THERMAL_ALL_UNICAST_DATA_QUEUES             7
#define THERMAL_MINUS_INFINITE                     -100
#define THERMAL_MAX_TEMPERATURE                     150
#define INVALID_BYTE                                0xff
#define INVALID_THERMAL_PARAM                       0xffffffff
#define TH_FALSE                                    0
#define TH_TRUE                                     1
#define TH_SUCCESS                                  0
#define TH_FAIL                                    -1
#define THERMAL_MITIGATION_ENABLED                  1
#define THERMAL_MITIGATION_DISABLED                 0
#define THERMAL_POLICY_QUEUE_PAUSE                  0x01
#define TMD_CONFIG_LEVEL                            0x01
#define TMD_CONFIG_DCOFF_PERCENT                    0x04
#define TMD_CONFIG_READY                            (TMD_CONFIG_LEVEL | TMD_CONFIG_DCOFF_PERCENT)
#define THERMAL_MAX_DUTY_CYCLE                      50 /* milliseconds */
#define THERMAL_MIN_DUTY_CYCLE                      5 /* milliseconds */
#define THERMAL_MAX_OFF_PERCENT                     100
#define THERMAL_MIN_OFF_PERCENT                     0

/* Default thermal mitigation config defines*/
#define THERMAL_CONFIG_DEFAULT_DUTY_CYCLE           100
#define THERMAL_WMI_EVENT_DC                        2
#define THERMAL_CONFIG_TMPLWM0                      THERMAL_MINUS_INFINITE
#define THERMAL_CONFIG_TMPLWM1                      100
#define THERMAL_CONFIG_TMPLWM2                      110
#define THERMAL_CONFIG_TMPLWM3                      125
#define THERMAL_CONFIG_TMPHWM0                      110
#define THERMAL_CONFIG_TMPHWM1                      120
#define THERMAL_CONFIG_TMPHWM2                      135
#define THERMAL_CONFIG_TMPHWM3                      THERMAL_MAX_TEMPERATURE
#define THERMAL_CONFIG_DCOFF0                       0
#define THERMAL_CONFIG_DCOFF1                       50
#define THERMAL_CONFIG_DCOFF2                       90
#define THERMAL_CONFIG_DCOFF3                       100

#define THERMAL_DEBUG                               1

#define TH_DEBUG_LVL0 0x0
#define TH_DEBUG_LVL1 0x1
#define TH_DEBUG_LVL2 0x2
#define TH_DEBUG_LVL3 0x4
#define TH_DEBUG_LVL4 0x8

#ifndef __KERNEL__
#define PRINT fprintf
#else
#define PRINT qdf_print
#endif

#if THERMAL_DEBUG
#define TH_DEBUG_IS_ENABLED(_mask,_scn)  (_mask & _scn->thermal_param.th_cfg.log_lvl)
#define TH_DEBUG_PRINT(_mask,_scn, _args...) do {                                   \
    if ((_mask == TH_DEBUG_LVL0) || (TH_DEBUG_IS_ENABLED(_mask,_scn))) {            \
        PRINT(_args);                                                               \
    }                                                                               \
} while (0)
#else
#define TH_DEBUG_PRINT(_mask, _scn, _args...) do {  \
    if (_mask == TH_DEBUG_LVL0) {                   \
        PRINT(_args);                               \
    }                                               \
} while(0)
#endif

#if 0
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
    struct th_config_t          th_cfg;
    struct th_stats_t           th_stats;
    struct tmd_level_config_t   tmd_cfg;
};
#endif

#ifdef __KERNEL__
u_int32_t get_tt_supported (struct ol_ath_softc_net80211 *scn);
int32_t __ol_ath_thermal_mitigation_attach (struct ol_ath_softc_net80211 *scn);
int32_t __ol_ath_thermal_mitigation_detach (struct ol_ath_softc_net80211 *scn);
int32_t ol_ath_thermal_stats_event_handler (ol_scn_t scn, u_int8_t *data, uint32_t datalen);
int32_t ol_ath_ioctl_set_thermal_handler (struct ol_ath_softc_net80211 *scn, caddr_t param);
int32_t ol_ath_ioctl_get_thermal_handler (struct ol_ath_softc_net80211 *scn, caddr_t param);
ssize_t wifi_thermal_temp_show (struct device *dev, struct device_attribute *attr, char *buf);
ssize_t wifi_thermal_mode_store (struct device *dev, struct device_attribute *attr, const char *buf, size_t size);
ssize_t wifi_thermal_mode_show (struct device *dev, struct device_attribute *attr, char *buf);
ssize_t wifi_thermal_thlvl_store (struct device *dev, struct device_attribute *attr, const char *buf, size_t size);
ssize_t wifi_thermal_thlvl_show (struct device *dev, struct device_attribute *attr, char *buf);
ssize_t wifi_thermal_dutycycle_store (struct device *dev, struct device_attribute *attr, const char *buf, size_t size);
ssize_t wifi_thermal_dutycycle_show (struct device *dev, struct device_attribute *attr, char *buf);
ssize_t wifi_thermal_offpercent_store (struct device *dev, struct device_attribute *attr, const char *buf, size_t size);
ssize_t wifi_thermal_offpercent_show (struct device *dev, struct device_attribute *attr, char *buf);
#endif

#endif /* __OL_IF_THERMAL_H */
