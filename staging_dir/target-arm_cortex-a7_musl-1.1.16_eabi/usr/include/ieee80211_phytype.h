/*
* Copyright (c) 2012, 2018 Qualcomm Innovation Center, Inc.
* All Rights Reserved.
* Confidential and Proprietary - Qualcomm Innovation Center, Inc.
*
*/

/*
 * 2012 Qualcomm Atheros, Inc.
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary.
 */

#ifndef _IEEE80211_PHYTYPE__H_
#define _IEEE80211_PHYTYPE__H_


/*
 * phy type definitions.
 * do not change the order of these
 * defines .
 */
enum ieee80211_phytype {
    IEEE80211_T_DS,                 /* direct sequence spread spectrum */
    IEEE80211_T_FH,                 /* frequency hopping */
    IEEE80211_T_OFDM,               /* frequency division multiplexing */
    IEEE80211_T_TURBO,              /* high rate OFDM, aka turbo mode */
    IEEE80211_T_HT,                 /* HT - full GI */
    IEEE80211_T_ERP,
    IEEE80211_T_ANY,
    IEEE80211_T_MAX
};
#define IEEE80211_T_CCK IEEE80211_T_DS  /* more common nomenclature */


#endif /* _IEEE80211_PHYTYPE__H_ */
