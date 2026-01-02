#ifndef __EVENTS_H__
#define __EVENTS_H__

#ifndef MAX_SSID_LEN
#define MAX_SSID_LEN            32
#endif

struct ev_msg {
    u_int32_t status;
    u_int32_t reason;
    u_int8_t addr[IEEE80211_ADDR_LEN];
    u_int8_t frame_subtype;
};

struct ev_recv_probereq {
    u_int8_t mac_addr[IEEE80211_ADDR_LEN]; /* mac addr */
    u_int32_t rssi;       /* rssi */
    u_int32_t rate;       /* data rate */
    u_int8_t channel_num; /* operating channel number */
};

struct ev_node_authorized {
    u_int8_t  mac_addr[IEEE80211_ADDR_LEN]; /* mac addr */
    u_int8_t  channel_num; /* operating channel number */
    u_int16_t assoc_id;    /* assoc id */
    /* HW capabilities */
    u_int16_t phymode;     /* phymode(11ac/abgn)  */
    u_int8_t  nss;         /* tx/rx chains */
    u_int8_t  is_256qam;         /* tx/rx chains */
};

struct ev_sta_leave {
    u_int8_t  mac_addr[IEEE80211_ADDR_LEN]; /* mac addr */
    u_int8_t  channel_num; /* operating channel number */
    u_int16_t assoc_id;    /* assoc id */
    u_int32_t reason;      /* leave reason */
};

struct ev_sta_external_auth_params {
    u_int8_t action;
    u_int8_t bssid[IEEE80211_ADDR_LEN];
    u_int8_t ssid[MAX_SSID_LEN];
    u_int32_t ssid_len;
    u_int32_t keymgmt_suite;
    u_int16_t status;
}__packed;
#endif
