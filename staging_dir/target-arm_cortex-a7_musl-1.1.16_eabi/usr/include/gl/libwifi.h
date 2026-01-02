/*
 * libwifi.h
 *
 *  Created on: May 24, 2019
 *      Author: lancer
 */


#ifndef LIBWIFI_H
#define LIBWIFI_H

#include <libubox/list.h>
#include <json-c/json.h>

#ifdef MV1000
int get_wifi_scan_result(json_object *input,json_object *output);
#else
int get_wifi_scan_result(json_object *output);
#endif

json_object* get_channel_quality_distributed(void);

char* get_ssid_by_ifname(char *ifname);
int get_optimal_channel_by_ifname_for_open_dirver(char *ifname);
int get_optimal_channel_by_ifname_for_mt76x8_private(char *ifname);
int get_optimal_channel_by_ifname_for_mt7615_private(char *ifname);
int get_optimal_channel_by_ifname_for_ipq40xx_private(char *ifname);
int get_wifi_radio_index(char *name);
int wifi_ap_detect(char *name);

#ifdef MV1000
int get_optimal_channel_by_ifname_for_open_driver(char *ifname,int dongle);
#else
int get_optimal_channel_by_ifname_for_open_driver(char *ifname);
#endif



#endif /* LIBWIFI_H */
