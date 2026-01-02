/*
 * =====================================================================================
 *
 *       Filename:  spectral.h
 *
 *    Description:  Spectral scan related 
 *
 *        Version:  1.0
 *        Created:  Wednesday 05 August 2009 05:37:02  IST
 *       Revision:  none
 *       Compiler:  gcc
 *
 *      Copyright (c) 2011 Qualcomm Atheros, Inc.
 *      All Rights Reserved.
 *      Qualcomm Atheros Confidential and Proprietary.
 *
 * =====================================================================================
 */


#ifndef _SPECTRAL_H_
#define _SPECTRAL_H_


#include "classifier.h"
#include "spec_msg_proto.h"
#include "spectral_data.h"

#define SPECTRAL_MIN(a,b) ((a)<(b)?(a):(b))
#define SPECTRAL_MAX(a,b) ((a)>(b)?(a):(b))
#define SPECTRAL_DIFF(a,b) (SPECTRAL_MAX(a,b) - SPECTRAL_MIN(a,b))
#define SPECTRAL_ABS_DIFF(a,b) (SPECTRAL_MAX(a,b) - SPECTRAL_MIN(a,b))


#define SPECTRAL_TSMASK         0xFFFFFFFF      	    /* Mask for time stamp from descriptor */
#define SPECTRAL_TSSHIFT        32              	    /* Shift for time stamp from descriptor */
#define	SPECTRAL_TSF_WRAP	    0xFFFFFFFFFFFFFFFFULL	/* 64 bit TSF wrap value */
#define	SPECTRAL_64BIT_TSFMASK	0x0000000000007FFFULL	/* TS mask for 64 bit value */


#define	SPECTRAL_MAX_EVENTS		1024	        /* Max number of spectral events which can be q'd */

#define SPECTRAL_MAX_PULSE_BUFFER_SIZE 	1024    /* Max number of pulses kept in buffer */
#define SPECTRAL_MAX_PULSE_BUFFER_MASK 	0x3ff


/* statistical data */
struct spectral_stats {
    u_int32_t       num_spectral_detects;      /* total num. of spectral detects */
    u_int32_t       num_bad_length_discards;
};

/* This should match the table from if_ath.c */
enum {
    ATH_DEBUG_SPECTRAL       = 0x00000100,   /* Minimal SPECTRAL debug */
    ATH_DEBUG_SPECTRAL1      = 0x00000200,   /* Normal SPECTRAL debug */
    ATH_DEBUG_SPECTRAL2      = 0x00000400,   /* Maximal SPECTRAL debug */
    ATH_DEBUG_SPECTRAL3      = 0x00000800,   /* matched filterID display */
};

#define	HAL_CAP_RADAR	0
#define	HAL_CAP_AR	1
#define HAL_CAP_STRONG_DIV 2


/* These definations are related to the data format for spectral scan */
#define SPECTRAL_SCAN_BITMASK (0x10)
#define SPECTRAL_SCAN_BW_INFO_OFFSET_FROM_END (3)

/* Defines the maximum values for the spectral scan register field */
#define SPECTRAL_FFT_PERIOD_MAX_VAL  (15)
#define SPECTRAL_SCAN_PERIOD_MAX_VAL (128)
#define SPECTRAL_SCAN_COUNT_MAX_VAL  (128)

/* Data length boundry conditions */
#define SPECTRAL_20HT_MIN_LEN (62)
#define SPECTRAL_20HT_MAX_LEN (65)
#define SPECTRAL_40HT_MIN_LEN (137)
#define SPECTRAL_40HT_MAX_LEN (140)


/* classifier related */

#define SPECTRAL_HT20_NUM_BINS                      56
#define SPECTRAL_HT20_FFT_LEN                       56
#define SPECTRAL_HT20_DC_INDEX                      (SPECTRAL_HT20_FFT_LEN / 2)
#define SPECTRAL_HT40_NUM_BINS                      64
#define SPECTRAL_HT40_TOTAL_NUM_BINS                128
#define SPECTRAL_HT40_FFT_LEN                       128
#define SPECTRAL_HT40_DC_INDEX                      (SPECTRAL_HT40_FFT_LEN / 2)
#define SPECTRAL_HT20_DATA_LEN                      60
#define SPECTRAL_HT20_TOTAL_DATA_LEN                (SPECTRAL_HT20_DATA_LEN + 3)
#define SPECTRAL_HT40_DATA_LEN                      135
#define SPECTRAL_HT40_TOTAL_DATA_LEN                (SPECTRAL_HT40_DATA_LEN + 3)


#define CLASSIFY_TIMEOUT_S             2
//#define CLASSIFY_TIMEOUT_MS            (CLASSIFY_TIMEOUT_S * 1000)
//#define CLASSIFY_TIMEOUT_MS            (200)
#define DEBUG_TIMEOUT_S                1
//#define DEBUG_TIMEOUT_MS               (DEBUG_TIMEOUT_S * 1000)
#define DEBUG_TIMEOUT_MS               (100)

#ifndef	__ATTRIB_PACK
#define	__ATTRIB_PACK	__attribute__ ((packed))
#endif



typedef struct ht20_bin_mag_data {
    u_int8_t bin_magnitude[SPECTRAL_HT20_NUM_BINS];
} __ATTRIB_PACK HT20_BIN_MAG_DATA;


typedef struct ht40_bin_mag_data {
    u_int8_t bin_magnitude[SPECTRAL_HT40_NUM_BINS];
} __ATTRIB_PACK HT40_BIN_MAG_DATA;


typedef struct max_mag_index_data {
        u_int8_t 
            max_mag_bits01:2,
            bmap_wt:6;
        u_int8_t max_mag_bits29;
        u_int8_t 
            max_index_bits05:6,
            max_mag_bits1110:2;
}__ATTRIB_PACK MAX_MAG_INDEX_DATA;

typedef struct ht20_fft_packet {
    HT20_BIN_MAG_DATA lower_bins;
    MAX_MAG_INDEX_DATA  lower_bins_max;
    u_int8_t       max_exp;
} __ATTRIB_PACK HT20_FFT_PACKET;

typedef struct ht40_fft_packet {
    HT40_BIN_MAG_DATA lower_bins;
    HT40_BIN_MAG_DATA upper_bins;
    MAX_MAG_INDEX_DATA  lower_bins_max;
    MAX_MAG_INDEX_DATA  upper_bins_max;
    u_int8_t       max_exp;
} __ATTRIB_PACK HT40_FFT_PACKET;

#ifdef	__ATTRIB_PACK
#undef	__ATTRIB_PACK
#endif

struct spectral_pulseparams {
        u_int64_t       p_time;                 /* time for start of pulse in usecs*/
        u_int8_t        p_dur;                  /* Duration of pulse in usecs*/
        u_int8_t        p_rssi;                 /* Duration of pulse in usecs*/
};


#define HAL_SPECTRAL_DEFAULT_SS_COUNT     128
#define HAL_SPECTRAL_DEFAULT_SS_SHORT_REPORT 1
#define HAL_SPECTRAL_DEFAULT_SS_PERIOD     35
#define HAL_SPECTRAL_DEFAULT_SS_FFT_PERIOD      1

#if 0
struct spectral_event {
	u_int32_t	se_ts;		/* Original 15 bit recv timestamp */
	u_int64_t	se_full_ts;	/* 64-bit full timestamp from interrupt time */
	u_int8_t	se_rssi;	/* rssi of spectral event */
	u_int8_t	se_bwinfo;	/* rssi of spectral event */
	u_int8_t	se_dur;		/* duration of spectral pulse */
	u_int8_t	se_chanindex;	/* Channel of event */
	STAILQ_ENTRY(spectral_event)	se_list;	/* List of spectral events */
};
#endif

#define int8_t   char
#define uint8_t  unsigned char
#define uint16_t unsigned short
#define uint32_t unsigned int

struct samp_msg_params {
    int8_t rssi;
    int8_t lower_rssi; 
    int8_t upper_rssi;
    uint16_t bwinfo;
    uint16_t datalen; 
    uint32_t tstamp; 
    uint16_t max_mag;
    uint16_t max_index;
    uint8_t max_exp; 
    int peak; 
    int pwr_count;
    u_int8_t **bin_pwr_data;
    u_int16_t freq;
    struct interf_src_rsp interf_list;
    int16_t noise_floor;
};

/*
 * Spectral classifier related code and macros
 * Need to purged later or maintain this as a
 * seprate feature
 */



/* Function exports */
extern void spectral_add_interf_samp_msg(struct samp_msg_params *params);
extern void spectral_create_samp_msg(struct samp_msg_params *params);
extern void fake_ht40_data_packet(HT40_FFT_PACKET *ht40pkt);
extern void send_fake_ht40_data();
extern u_int8_t return_max_value(u_int8_t* datap, u_int8_t numdata, u_int8_t *max_index);
extern void process_mag_data(MAX_MAG_INDEX_DATA *imag, u_int16_t *mmag, u_int8_t *bmap_wt, u_int8_t *max_index);

#endif  /* _SPECTRAL_H_ */
