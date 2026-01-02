#ifndef _SPECTRALSCAN_CLASSIFIER_H_
#define _SPECTRALSCAN_CLASSIFIER_H_

#include <sys/types.h>
#include "spectral_types.h"

#ifdef WIN32
#pragma pack(push, pktlog_fmt, 1)
#define __ATTRIB_PACK
#else
#ifndef __ATTRIB_PACK
#define __ATTRIB_PACK __attribute__ ((packed))
#endif
#endif

typedef struct spectral_burst {
    u_int8_t prev_narrowb;
    u_int8_t prev_wideb;
    u_int8_t max_bin;
    u_int8_t min_bin;
    u_int16_t burst_width;
    u_int16_t burst_rssi;
    u_int64_t burst_start;
    u_int64_t burst_stop;
    u_int16_t burst_wideb_width;
    u_int16_t burst_wideb_rssi;

} __ATTRIB_PACK SPECTRAL_BURST;

#ifdef __ATTRIB_PACK
#undef __ATTRIB_PACK
#endif

extern int spectral_debug_level;
extern int BTH_MIN_NUMBER_OF_FRAMES;

#define SPECTRAL_MIN(a,b) ((a)<(b)?(a):(b))
#define SPECTRAL_MAX(a,b) ((a)>(b)?(a):(b))
#define SPECTRAL_DIFF(a,b) (SPECTRAL_MAX(a,b) - SPECTRAL_MIN(a,b))
#define SPECTRAL_ABS_DIFF(a,b) (SPECTRAL_MAX(a,b) - SPECTRAL_MIN(a,b))


#define MIN_PREVIOUS_NB 1
#define MIN_PREVIOUS_WB 2
#define OBSERVATION_WINDOW 1000000


// CW PARAMETERS
#define CWA_WIDTH_THRESHOLD 10000
#define CWA_PRESENT 0
#define CWA_SILENCE_DURATION 1000000 
#define CWA_MIN_NUMBER_OF_FRAMES 10


// MICROWAVE PARAMETERS
#define MWO_LONG_BURST_TIMESTAMP 0
#define MWO_WIDTH_THRESHOLD 2500 // OTHER WORST CASE IS 625*5US
#define MWO_MIN_SEPARATION  8000
#define MWO_MINIMUM_BURST_DIFF 10000
#define MWO_MAX_LENGTH 8000
#define MWO_MAX_BINSPAN 8
#define MWO_MIN_NUMBER_OF_FRAMES 5

// CORDLESS PHONE
#define CPH_ONE_HANDSET_PERIOD_MIN 4000
#define CPH_ONE_HANDSET_PERIOD_MAX 6000
#define CPH_TWO_HANDSET_PERIOD_MIN 2000
#define CPH_TWO_HANDSET_PERIOD_MAX 3000
#define CPH_BURST_WIDTH_DELTA 1000
#define CPH_MIN_NUMBER_OF_FRAMES 5 

// BLUETOOTH HANDSFREE
#define BTH_MAX_BURST_DIFF 1000
#define BTH_MIN_PREVBURST_DIFF 3500

//Mon Jan 12 13:43:04 PST 2009 - make BTH num frames parameter
//#define BTH_MIN_NUMBER_OF_FRAMES 8

// BLUETOOTH 
#define BTS_MAX_BURST_SEPARATION 9500 // MIGHT NEED TO MODIFY FOR BT FA DUE TO MW
#define BTS_MIN_NUMBER_OF_FRAMES 2

// VIDEO BRIDGE 
#define VBR_MAX_GAP 1000
#define VBR_MAX_BURST_SEPARATION 9500 // MIGHT NEED TO MODIFY FOR BT FA DUE TO MW
#define VBR_MIN_NUMBER_OF_FRAMES 5
#define VBR_FREQ1_KHZ 2408200
#define VBR_FREQ2_KHZ 2431600
#define VBR_FREQ3_KHZ 2451600
#define VBR_FREQ4_KHZ 2470600
#define VBR_FREQ_RANGE 2500

// WLAN
#define WLN_MIN_WIDTH 1000
#define WLN_MAX_WIDTH 3000
#define WLN_POWER_RATIO 6
#define WLN_MIN_NUMBER_OF_FRAMES 3

#define SBURST_MIN_BURSTWIDTH 110
#define SBURST_MAX_BURSTWIDTH 600 // EVENTHOUGH THERE ARE LONGER BURSTS, WE DON'T USE THEM. WE ARE LOOKING FOR 625US BURSTS FOR UL/DL.
#define LBURST_MIN_BURSTWIDTH 110

#define SAMPLING_FREQUENCY 40000000
//#define SUBCARRIER_SPACING SAMPLING_FREQUENCY/128
#define SUBCARRIER_SPACING 312.5
#define SUBCARRIER_SPACING_NO_DECIMAL (3125)
#define CPH_MAX_WIDTH 1100
#define FREQUENCY_HOPPING_MIN_FREQ_CHANGE SUBCARRIER_SPACING // 500KHZ
#define DOUBLE_FREQUENCY_HOPPING_MIN_FREQ_CHANGE (SUBCARRIER_SPACING*2) // 500KHZ
#define TRIPLE_FREQUENCY_HOPPING_MIN_FREQ_CHANGE (SUBCARRIER_SPACING*3) // 500KHZ
#define SINGLE_FREQUENCY_MAX_BINSPAN 3
#define MAXIMUM_SAMPLING_INTERVAL 500
#define MINIMUM_RSSI 5

#define HT20_FFT_LENGTH 56
#define HT40_FFT_LENGTH 128
#define HT20_DATA_LENGTH 63
#define HT40_DATA_LENGTH 138


// DECT/CP
#define DECT_RSSI_THRESH -5
#define IS_DECT_PRESENT 0
#define DECT_TEST_REPEAT_TIME 60000000 // 60 SEC
#define DECT_DETECT_TIME 0
#define NEW_DECT_CASE_TIME 0
#define NEW_DECT_CASE_TIME2 0

// SPUR DETECTION PARAMETERS
#define SPUR_TOTAL_CAPTURES 0
#define SPUR_RATIO_HT20 2
#define SPUR_RATIO_HT40 3
#define SPUR_NUMCAPTURES 1000 // USE THIS MANY CAPTURES BEFORE MAKING A DECISION.


/* STRUCT DEFINITIONS */
struct ss {
  int dynamic_ht2040_en;
  int dc_index;
  int b_chan_in_mhz;
  int lwr_band_data;
  int previous_nb;
  int previous_wb;
  int max_bin;
  int min_bin;
  int wideband;
  int narrowband;
  int peak_index;
  int current_burst_width;
  int current_burst_rssi;
  int current_burst_start_time;
  int current_burst_stop;
  int current_burst_width_wb;
  int current_burst_rssi_wb;
  int current_burst_wb_sum1;
  int current_burst_wb_sum2;
  int current_burst_wb_sum3;
  int current_burst_wb_sum4;
  int current_burst_start_time_wb;
  int current_burst_stop_wb;
  int num_identified_bursts;
  int num_identified_short_bursts;
  int do_burst_check;
  int do_burst_check_wb;
  int burst_frequency;
  int burst_width;
  int burst_start;
  int burst_stop;
  int burst_rssi;
  int burst_previous_nb;
  int burst_max_min;
  int burstprev1_frequency;
  int burstprev1_width;
  int burstprev1_start;
  int burstprev1_rssi;
  int burstprev1_previous_nb;
  int burstprev2_frequency;
  int burstprev2_width;
  int burstprev2_start;
  int burstprev2_rssi;
  int burstprev2_previous_nb;
  int burstprev3_frequency;
  int burstprev3_width;
  int burstprev3_start;
  int burstprev3_rssi;
  int burstprev3_previous_nb;
  int burstprev1_max_min;
  int burstprev2_max_min;
  int burstprev3_max_min;
  int burstprev1_stop;
  int burstprev2_stop;
  int sburst_frequency;
  int sburst_width;
  int sburst_start;
  int sburst_stop;
  int sburst_rssi;
  int sburst_previous_nb;
  int sburst_max_min;
  int sburstprev1_frequency;
  int sburstprev1_width;
  int sburstprev1_start;
  int sburstprev1_rssi;
  int sburstprev1_previous_nb;
  int sburstprev2_frequency;
  int sburstprev2_width;
  int sburstprev2_start;
  int sburstprev2_rssi;
  int sburstprev2_previous_nb;
  int sburstprev3_frequency;
  int sburstprev3_width;
  int sburstprev3_start;
  int sburstprev3_rssi;
  int sburstprev3_previous_nb;
  int sburstprev1_max_min;
  int sburstprev2_max_min;
  int sburstprev1_stop;
  int burst0_freq_bin;
  int burst1_freq_bin;
  int burst2_freq_bin;
  int burst0_in_freq_range;
  int burst1_in_freq_range;
  int burst2_in_freq_range;
  int prev_burst_stop;
  int count_mwo;
  int count_bts;
  int count_bth;
  int count_cph;
  int count_cwa;
  int count_wln;
  int count_vbr;
  int mwo_long_burst_timestamp;
  int mwo_long_burst_timestamp1;
  int mwo_long_burst_timestamp2;
  int mwo_long_burst_frequency_bins;
  int mwo_long_burst_frequency_bins1;
  int vbr_timestamps[VBR_MIN_NUMBER_OF_FRAMES];
  int vbr_rssi[VBR_MIN_NUMBER_OF_FRAMES];
  //int bth_timestamps[BTH_MIN_NUMBER_OF_FRAMES];
  int bth_timestamps[8];
  //int bth_rssi[BTH_MIN_NUMBER_OF_FRAMES];
  int bth_rssi[8];
  int bts_timestamps[BTS_MIN_NUMBER_OF_FRAMES];
  int bts_rssi[BTS_MIN_NUMBER_OF_FRAMES];
  int cph_timestamps[CPH_MIN_NUMBER_OF_FRAMES];
  int cph_rssi[CPH_MIN_NUMBER_OF_FRAMES];
  int cwa_timestamps[CWA_MIN_NUMBER_OF_FRAMES];
  int cwa_rssi[CWA_MIN_NUMBER_OF_FRAMES];
  int mwo_timestamps[MWO_MIN_NUMBER_OF_FRAMES];
  int mwo_rssi[MWO_MIN_NUMBER_OF_FRAMES];
  int wln_timestamps[WLN_MIN_NUMBER_OF_FRAMES];
  int wln_rssi[WLN_MIN_NUMBER_OF_FRAMES];
  int print_to_screen;
  int last_report_time;
  int mwo_mean_rssi;
  int cph_mean_rssi;
  int bth_mean_rssi;
  int bts_mean_rssi;
  int cwa_mean_rssi;
  int vbr_mean_rssi;
  int wln_mean_rssi;
  long int average_rssi_total;
  int average_rssi_numbr;
  int dc_in_mhz;
  //Wed Oct 29 18:20:20 PDT 2008 - Added some variables for reporting to GUI
  int cph_min_freq;
  int cph_max_freq;
  int cwa_min_freq;
  int cwa_max_freq;
  int bts_min_freq;
  int bts_max_freq;
  int bth_min_freq;
  int bth_max_freq;
  int mwo_min_freq;
  int mwo_max_freq;

  int detects_extension_channel;
  int detects_control_channel;
  int  detects_below_dc;
  int detects_above_dc;
};

void reset_vbr(struct ss *bd);
void reset_bth(struct ss *bd);
void reset_bts(struct ss *bd);
void reset_cph(struct ss *bd);
void reset_cwa(struct ss *bd);
void reset_mwo(struct ss *bd);
void reset_mwo_long(struct ss *bd);
void reset_wln(struct ss *bd);
void reset_nb_counters(struct ss *bd);

#endif //ifndef _SPECTRALSCAN_CLASSIFIER_H_
