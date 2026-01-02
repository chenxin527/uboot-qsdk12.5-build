/*
 **************************************************************************
 * Copyright (c) 2019, The Linux Foundation. All rights reserved.
 * Permission to use, copy, modify, and/or distribute this software for
 * any purpose with or without fee is hereby granted, provided that the
 * above copyright notice and this permission notice appear in all copies.
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 **************************************************************************
 */

#ifndef __ECM_NOTIFIER_H__
#define __ECM_NOTIFIER_H__

/*
 * ecm_connection_tuple
 * 	ECM connection tuple.
 */
struct ecm_notifier_connection_tuple {
		union {
			struct in_addr in;	/* IPv4 address in host order */
			struct in6_addr in6;	/* IPv6 address in host order */
		} src;
		union {
			struct in_addr in;	/* IPv4 address in host order */
			struct in6_addr in6;	/* IPv6 address in host order */
		} dest;
		uint16_t dst_port;		/* Destination port in host order*/
		uint16_t src_port;		/* Source port port in host order*/
		uint8_t protocol;		/* Next protocol header number */
		uint8_t ip_ver;			/* IP version 4 or 6 */
};

/*
 * ecm_connection_state
 * 	State of the connection in ECM.
 */
enum ecm_notifier_connection_state {
	ECM_NOTIFIER_CONNECTION_STATE_ACCEL,		/* Connection rule is pushed to NSS */
	ECM_NOTIFIER_CONNECTION_STATE_ACCEL_PENDING,	/* Connection is in the process of being accelerated to NSS */
	ECM_NOTIFIER_CONNECTION_STATE_DECEL,		/* Connection rule is not pushed to NSS */
	ECM_NOTIFIER_CONNECTION_STATE_DECEL_PENDING,	/* Connection is in the process of being decelerated to NSS */
	ECM_NOTIFIER_CONNECTION_STATE_FAILED,		/* Connection is failed to accelerated */
	ECM_NOTIFIER_CONNECTION_STATE_INVALID,		/* Connection is not present in ECM DB */
	ECM_NOTIFIER_CONNECTION_STATE_MAX
};

/*
 * ecm_notifier_connection_data
 * 	Event data for a connection notification.
 */
struct ecm_notifier_connection_data {
	struct net_device *to_dev;			/* First device in ECM 'to' iface hierarchy */
	struct net_device *from_dev;			/* First device in ECM 'from' iface hierarchy */
	struct ecm_notifier_connection_tuple tuple;	/* Connection tuple information */
};

/*
 * ecm_notifier_action
 * 	Notifier action for all ECM events.
 */
enum ecm_notifier_action {
	ECM_NOTIFIER_ACTION_CONNECTION_ADDED,
	ECM_NOTIFIER_ACTION_CONNECTION_REMOVED,
	ECM_NOTIFIER_ACTION_MAX
};

extern int ecm_notifier_register_connection_notify(struct notifier_block *nb);
extern int ecm_notifier_unregister_connection_notify(struct notifier_block *nb);
extern enum ecm_notifier_connection_state ecm_notifier_connection_state_get(struct ecm_notifier_connection_tuple *conn);
#endif
