/*
 * cmm.h
 * 
 * Created on: Fri 20 Apr 2018 09:43:56 AM CST
 *     Author: lancer
 *      Email: luoyejiang0701@qq.com
 */

#ifndef CMM_H
#define CMM_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <json-c/json.h>
#include <libubox/list.h>

#define HTTPS 1
#ifdef HTTPS
#define DOWNLOAD_URL "https://fw.gl-inet.com"
#else
#define DOWNLOAD_URL "http://download.gl-inet.com"
#endif

#define LOG10_MAGIC	1.25892541179

#define MAX(a, b) ((a) > (b)) ? (a) : (b)
#define MIN(a, b) ((a) > (b)) ? (b) : (a)


struct list_head *list_init();

void ubus_call(const char *path, const char *method, int timeout, char **str);
bool cmm_curl(const char *url, int timeout_ms, char **str);
bool cmm_mwan3track_online();
bool cmm_check_file_is_exist (const char *name);
bool cmm_check_net_interface_exist(const char *iface);
bool cmm_check_wireless_abort(void);
bool cmm_check_file_include_data(const char *name);
bool cmm_check_gl_manufacture(unsigned int iSeed);
bool cmm_check_manufacture(unsigned int iSeed);
int cmm_check_factory(void);
bool cmm_check_net_reachable(void);
char* cmm_get_public_ip(char *ip);
bool cmm_ovpn_client_enable(void);
bool cmm_ovpn_server_enable(void);
bool cmm_wg_client_enable(void);
bool cmm_wg_server_enable(void);
bool cmm_ss_client_enable(void);
bool cmm_ss_server_enable(void);
bool cmm_check_vpn_conflict(const char *service);
bool cmm_ipv4_legal(const char *ipv4);
bool cmm_ipv4_range_legal(const char *ip_range);
bool cmm_mac_legal(const char *mac);
bool cmm_domain_legal(const char *url);
bool cmm_net_reachable(void);
bool cmm_check_is_nand();
void cmm_get_frimware_url(char* firmware_path_url);
void cmm_read_if_status(const char* caIfCmd, json_object* output);
void cmm_read_ifstatus(json_object* output, const char *path, const char *method, int timeout);
int cmm_read_ip_info(const char* iface, json_object* output);
int cmm_get_firmware_max_size(void);
int system_uptime(void);
int wireless_mw2dbm(int in);
int wireless_dbm2mw(int in);
bool check_ar300md_target();






#endif /* CMM_H */

