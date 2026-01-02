/*
 * Copyright (c) 2016, 2017 Qualcomm Technologies, Inc.
 * All Rights Reserved.
 * Confidential and Proprietary - Qualcomm Technologies, Inc.
 */

#ifndef _CFG80211_NLWRAPPER_PVT_H_
#define _CFG80211_NLWRAPPER_PVT_H_

#include <stdint.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netlink/genl/genl.h>
#include <netlink/genl/family.h>
#include <netlink/genl/ctrl.h>
#include <linux/rtnetlink.h>
#include <netpacket/packet.h>
#include <linux/filter.h>
#include <linux/errqueue.h>
#include <netlink-private/object-api.h>
#include <netlink-private/types.h>
#include <netlink/object-api.h>
#include <netlink/netlink.h>
#include <netlink/socket.h>

#include <sys/types.h>
#include <unistd.h>
#include <pthread.h>
#include "cfg80211_nlwrapper_api.h"

#define NCT_CMD_SOCK_PORT       777
#define NCT_EVENT_SOCK_PORT     778
#define QCA_VENDOR_OUI 0x001374


enum qca_wlan_genric_data {
	QCA_WLAN_VENDOR_ATTR_PARAM_INVALID = 0,
	QCA_WLAN_VENDOR_ATTR_PARAM_DATA,
	QCA_WLAN_VENDOR_ATTR_PARAM_LENGTH,
	QCA_WLAN_VENDOR_ATTR_PARAM_FLAGS,

	/* keep last */
	QCA_WLAN_VENDOR_ATTR_PARAM_LAST,
	QCA_WLAN_VENDOR_ATTR_PARAM_MAX =
		QCA_WLAN_VENDOR_ATTR_PARAM_LAST - 1
};

enum qca_wlan_get_params {
	QCA_WLAN_VENDOR_ATTR_GETPARAM_INVALID = 0,
	QCA_WLAN_VENDOR_ATTR_GETPARAM_COMMAND,

	/* keep last */
	QCA_WLAN_VENDOR_ATTR_GETPARAM_LAST,
	QCA_WLAN_VENDOR_ATTR_GETPARAM_MAX =
		QCA_WLAN_VENDOR_ATTR_GETPARAM_LAST - 1
};

int valid_handler(struct nl_msg *msg, void *arg);
int ack_handler(struct nl_msg *msg, void *arg);
int finish_handler(struct nl_msg *msg, void *arg);
int error_handler(struct sockaddr_nl *nla, struct nlmsgerr *err, void *arg);
int no_seq_check(struct nl_msg *msg, void *arg);
int put_u32(struct nl_msg *nlmsg, int attribute, uint32_t value);
int set_iface_id(struct nl_msg *nlmsg, const char *iface);
int sendNLMsg(wifi_cfg80211_context *ctx, struct nl_msg *nlmsg, void *data);
void wifi_socket_set_local_port(struct nl_sock *sock, uint32_t port);
struct nl_sock *wifi_create_nl_socket(int port, int protocol);
#endif
