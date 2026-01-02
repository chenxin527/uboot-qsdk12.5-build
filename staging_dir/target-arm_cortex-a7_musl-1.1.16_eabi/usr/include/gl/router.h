#ifndef _GL_ROUTER_H_
#define _GL_ROUTER_H_

#include <stdio.h>
#include <stdbool.h>
#include <ifaddrs.h>
#include <json-c/json.h>

extern bool check_blueconfig_is_configured();

extern bool check_router_is_configured();

extern bool check_router_is_bridge();



extern const char* get_default_mac();


extern int get_network_info(const char* ifname, struct ifaddrs value);

extern int set_lan_ip(const char *ip, int start, int end);

/**
 * get_ddns_name
 * get the ddns from flash
 * @value char[]
 */
const extern char* get_ddns_name();

/**
 * get_service_cde
 */
const extern char* get_service_code();

/**
 * get_mode_name
 * get the name of this router model, e.g. ar150, ar300m, mt300n etc
 */
const extern char* get_model_name();
const extern char* get_wan_name();
const extern char* get_lan_name();

extern int get_flash_ready();

extern int get_flash_total_size();


/**
 * Get a list of storage devices and their status
 * including label, mount path, uuid, filesystem, size, available size,
 */
extern json_object* get_storage_devices();


extern int generate_mt_mac(const char* mac, char* newmac);

json_object* get_wifi_scanlist(void);
json_object* get_channel_list(char *ifname);
extern int get_channel_by_ifname(char *ifname);
#ifdef MV1000
extern int get_sta_channel_by_ifname(char *device);
#else
extern int get_sta_channel_by_ifname(void);
#endif


extern char *get_2_4G_ssid(char *ssid);
extern char *get_5G_ssid(char *ssid);

#endif
