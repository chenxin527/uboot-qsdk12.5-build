/*
 * sfe_drv.h
 *	simulated driver headers for shortcut forwarding engine.
 *
 * Copyright (c) 2015,2016 The Linux Foundation. All rights reserved.
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
 */

#ifndef __SFE_DRV_H
#define __SFE_DRV_H

#define MAX_VLAN_DEPTH 2
#define SFE_VLAN_ID_NOT_CONFIGURED 0xfff
#define SFE_MC_IF_MAX 16

#define SFE_SPECIAL_INTERFACE_BASE 0x7f00
#define SFE_SPECIAL_INTERFACE_IPV4 (SFE_SPECIAL_INTERFACE_BASE + 1)
#define SFE_SPECIAL_INTERFACE_IPV6 (SFE_SPECIAL_INTERFACE_BASE + 2)
#define SFE_SPECIAL_INTERFACE_IPSEC (SFE_SPECIAL_INTERFACE_BASE + 3)
#define SFE_SPECIAL_INTERFACE_L2TP (SFE_SPECIAL_INTERFACE_BASE + 4)
#define SFE_SPECIAL_INTERFACE_PPTP (SFE_SPECIAL_INTERFACE_BASE + 5)

/**
 * Rule creation & rule update flags.
 */
#define SFE_RULE_CREATE_FLAG_NO_SEQ_CHECK (1<<0) /**< Do not perform TCP sequence number checks */
#define SFE_RULE_CREATE_FLAG_BRIDGE_FLOW  (1<<1) /**< This is a pure bridge forwarding flow */
#define SFE_RULE_CREATE_FLAG_ROUTED       (1<<2) /**< Rule is for a routed connection */
#define SFE_RULE_CREATE_FLAG_DSCP_MARKING (1<<3) /**< Rule has for a DSCP marking configured*/
#define SFE_RULE_CREATE_FLAG_VLAN_MARKING (1<<4) /**< Rule has for a VLAN marking configured*/
#define SFE_RULE_UPDATE_FLAG_CHANGE_MTU   (1<<5) /**< Update MTU of connection interfaces */
#define SFE_RULE_CREATE_FLAG_ICMP_NO_CME_FLUSH (1<<6)/**< Rule for not flushing CME on ICMP pkt */
#define SFE_RULE_CREATE_FLAG_L2_ENCAP     (1<<7) /**< consists of an encapsulating protocol that carries an IPv4 payload within it. */
#define SFE_RULE_CREATE_FLAG_MC_JOIN      (1<<8) /**< Interface has joined the flow */
#define SFE_RULE_CREATE_FLAG_MC_LEAVE     (1<<9) /**< Interface has left the flow */
#define SFE_RULE_CREATE_FLAG_MC_UPDATE    (1<<10)/**< Multicast Rule update */
/**
 * Rule creation validity flags.
 */
#define SFE_RULE_CREATE_CONN_VALID         (1<<0) /**< IPv4 Connection is valid */
#define SFE_RULE_CREATE_TCP_VALID          (1<<1) /**< TCP Protocol fields are valid */
#define SFE_RULE_CREATE_PPPOE_VALID        (1<<2) /**< PPPoE fields are valid */
#define SFE_RULE_CREATE_QOS_VALID          (1<<3) /**< QoS fields are valid */
#define SFE_RULE_CREATE_VLAN_VALID         (1<<4) /**< VLAN fields are valid */
#define SFE_RULE_CREATE_DSCP_MARKING_VALID (1<<5) /**< DSCP marking fields are valid */
#define SFE_RULE_CREATE_VLAN_MARKING_VALID (1<<6) /**< VLAN marking fields are valid */
#define SFE_RULE_CREATE_MC_NAT_VALID       (1<<7) /**< Interface is configured with Source-NAT */
#define SFE_RULE_CREATE_DIRECTION_VALID    (1<<8) /**< specify acceleration directions */

typedef enum sfe_rule_sync_reason {
	SFE_RULE_SYNC_REASON_STATS,	/* Sync is to synchronize stats */
	SFE_RULE_SYNC_REASON_FLUSH,	/* Sync is to flush a entry */
	SFE_RULE_SYNC_REASON_EVICT,	/* Sync is to evict a entry */
	SFE_RULE_SYNC_REASON_DESTROY	/* Sync is to destroy a entry(requested by connection manager) */

} sfe_rule_sync_reason_t;

/**
 * Tx command status
 */
typedef enum {
	SFE_TX_SUCCESS = 0,	/**< Success */
	SFE_TX_FAILURE,		/**< Command failure other than descriptor not available */
	SFE_TX_FAILURE_QUEUE,	/**< Command failure due to descriptor not available */
	SFE_TX_FAILURE_NOT_READY,	/**< Command failure due to SFE state uninitialized */
	SFE_TX_FAILURE_TOO_LARGE,	/**< Command is too large to fit in one message */
	SFE_TX_FAILURE_TOO_SHORT,	/**< Command/Packet is shorter than expected size */
	SFE_TX_FAILURE_NOT_SUPPORTED,	/**< Command/Packet not accepted for forwarding */
	SFE_TX_FAILURE_BAD_PARAM,	/**< Command failure due to bad parameters */
	SFE_TX_FAILURE_NOT_ENABLED,	/**< Command failure due to SFE feature is not enabled */
} sfe_tx_status_t;

/**
 * Common response structure
 */
enum sfe_cmn_response {
	SFE_CMN_RESPONSE_ACK,		/**< Message Acknowledge */
	SFE_CMN_RESPONSE_EVERSION,	/**< Message Version Error */
	SFE_CMN_RESPONSE_EINTERFACE,	/**< Message Interface Error */
	SFE_CMN_RESPONSE_ELENGTH,	/**< Message Length Error */
	SFE_CMN_RESPONSE_EMSG,		/**< Message Error */
	SFE_CMM_RESPONSE_NOTIFY,	/**< Message Independant of Request */
	SFE_CMN_RESPONSE_LAST
};

/**
 * IPv4 bridge/route rule messages
 */
enum sfe_message_types {
	SFE_TX_CREATE_RULE_MSG,		/**< IPv4/6 create rule message */
	SFE_TX_DESTROY_RULE_MSG,	/**< IPv4/6 destroy rule message */
	SFE_RX_CONN_STATS_SYNC_MSG,	/**< IPv4/6 connection stats sync message */
	SFE_TX_CREATE_MC_RULE_MSG,	/**< IPv4/6 multicast create rule message */
	SFE_TUN6RD_ADD_UPDATE_PEER,	/**< Add/update peer for 6rd tunnel */
	SFE_MAX_MSG_TYPES,		/**< IPv4/6 message max type number */
};

/**
 * Common message structure
 */
struct sfe_cmn_msg {
	u16 version;		/**< Version id for main message format */
	u16 interface;		/**< Primary Key for all messages */
	enum sfe_cmn_response response;	/**< Primary response */
	u32 type;			/**< Decetralized request #, to be used to match response # */
	u32 error;			/**< Decentralized specific error message, response == EMSG */
	u32 cb;			/**< Place for callback pointer */
	u32 app_data;		/**< Place for app data */
	u32 len;			/**< What is the length of the message excluding this header */
};

/**
 * Common 5 tuple structure
 */
struct sfe_ipv4_5tuple {
	__be32 flow_ip;			/**< Flow IP address */
	__be32 return_ip;		/**< Return IP address */
	__be16 flow_ident;		/**< Flow ident (e.g. TCP/UDP port) */
	__be16 return_ident;		/**< Return ident (e.g. TCP/UDP port) */
	u8 protocol;		/**< Protocol number */
	u8 reserved[3];		/**< Padded for alignment */
};

/**
 * Common 5 tuple structure
 */
struct sfe_ipv6_5tuple {
	__be32 flow_ip[4];		/**< Flow IP address */
	__be32 return_ip[4];		/**< Return IP address */
	__be16 flow_ident;		/**< Flow ident (e.g. TCP/UDP port) */
	__be16 return_ident;		/**< Return ident (e.g. TCP/UDP port) */
	u8  protocol;		/**< Protocol number */
	u8  reserved[3];		/**< Padded for alignment */
};

/**
 * Connection create structure
 */
struct sfe_ipv4_connection_rule {
	u8 flow_mac[6];		/**< Flow MAC address */
	u8 return_mac[6];		/**< Return MAC address */
	s32 flow_interface_num;	/**< Flow interface number */
	s32 return_interface_num;	/**< Return interface number */
	s32 flow_top_interface_num;	/* Top flow interface number */
	s32 return_top_interface_num;/* Top return interface number */
	u32 flow_mtu;		/**< Flow interface`s MTU */
	u32 return_mtu;		/**< Return interface`s MTU */
	__be32 flow_ip_xlate;		/**< Translated flow IP address */
	__be32 return_ip_xlate;		/**< Translated return IP address */
	__be16 flow_ident_xlate;	/**< Translated flow ident (e.g. port) */
	__be16 return_ident_xlate;	/**< Translated return ident (e.g. port) */
};

/**
 * Connection create structure
 */
struct sfe_ipv6_connection_rule {
	u8 flow_mac[6];		/**< Flow MAC address */
	u8 return_mac[6];		/**< Return MAC address */
	s32 flow_interface_num;	/**< Flow interface number */
	s32 return_interface_num;	/**< Return interface number */
	s32 flow_top_interface_num;	/* Top flow interface number */
	s32 return_top_interface_num;/* Top return interface number */
	u32 flow_mtu;		/**< Flow interface's MTU */
	u32 return_mtu;		/**< Return interface's MTU */
};

/**
 * TCP connection rule structure
 */
struct sfe_protocol_tcp_rule {
	u32 flow_max_window;	/**< Flow direction's largest seen window */
	u32 return_max_window;	/**< Return direction's largest seen window */
	u32 flow_end;		/**< Flow direction's largest seen sequence + segment length */
	u32 return_end;		/**< Return direction's largest seen sequence + segment length */
	u32 flow_max_end;		/**< Flow direction's largest seen ack + max(1, win) */
	u32 return_max_end;	/**< Return direction's largest seen ack + max(1, win) */
	u8 flow_window_scale;	/**< Flow direction's window scaling factor */
	u8 return_window_scale;	/**< Return direction's window scaling factor */
	u16 reserved;		/**< Padded for alignment */
};

/**
 * PPPoE connection rules structure
 */
struct sfe_pppoe_rule {
	u16 flow_pppoe_session_id;		/**< Flow direction`s PPPoE session ID. */
	u16 flow_pppoe_remote_mac[3];	/**< Flow direction`s PPPoE Server MAC address */
	u16 return_pppoe_session_id;	/**< Return direction's PPPoE session ID. */
	u16 return_pppoe_remote_mac[3];	/**< Return direction's PPPoE Server MAC address */
};

/**
 * QoS connection rule structure
 */
struct sfe_qos_rule {
	u32 flow_qos_tag;		/**< QoS tag associated with this rule for flow direction */
	u32 return_qos_tag;	/**< QoS tag associated with this rule for return direction */
};

/**
 * DSCP connection rule structure
 */
struct sfe_dscp_rule {
	u8 flow_dscp;		/**< Egress DSCP value for flow direction */
	u8 return_dscp;		/**< Egress DSCP value for return direction */
	u8 reserved[2];		/**< Padded for alignment */
};

/**
 * VLAN connection rule structure
 */
struct sfe_vlan_rule {
	u32 ingress_vlan_tag;	/**< VLAN Tag for the ingress packets */
	u32 egress_vlan_tag;	/**< VLAN Tag for egress packets */
};

/**
 * Acceleration direction rule structure
 * 	Sometimes we just want to accelerate traffic in one direction but not in another.
 */
struct sfe_acceleration_direction_rule {
	u8 flow_accel;		/**< Accelerate in flow direction */
	u8 return_accel;		/**< Accelerate in return direction */
	u8 reserved[2];		/**< Padded for alignment */
};

/**
 * The IPv4 rule create sub-message structure.
 */
struct sfe_ipv4_rule_create_msg {
	/* Request */
	u16 valid_flags;				/**< Bit flags associated with the validity of parameters */
	u16 rule_flags;				/**< Bit flags associated with the rule */

	struct sfe_ipv4_5tuple tuple;			/**< Holds values of the 5 tuple */

	struct sfe_ipv4_connection_rule conn_rule;	/**< Basic connection specific data */
	struct sfe_protocol_tcp_rule tcp_rule;		/**< TCP related accleration parameters */
	struct sfe_pppoe_rule pppoe_rule;		/**< PPPoE related accleration parameters */
	struct sfe_qos_rule qos_rule;			/**< QoS related accleration parameters */
	struct sfe_dscp_rule dscp_rule;			/**< DSCP related accleration parameters */
	struct sfe_vlan_rule vlan_primary_rule;		/**< Primary VLAN related accleration parameters */
	struct sfe_vlan_rule vlan_secondary_rule;	/**< Secondary VLAN related accleration parameters */
#ifdef CONFIG_XFRM
	struct sfe_acceleration_direction_rule direction_rule;/* Direction related accleration parameters*/
#endif
	/* Response */
	u32 index;					/**< Slot ID for cache stats to host OS */
};

/**
 * The IPv4 rule destroy sub-message structure.
 */
struct sfe_ipv4_rule_destroy_msg {
	struct sfe_ipv4_5tuple tuple;	/**< Holds values of the 5 tuple */
};

/**
 * The SFE IPv4 rule sync structure.
 */
struct sfe_ipv4_conn_sync {
	u32 index;			/**< Slot ID for cache stats to host OS */
	u8 protocol;		/**< Protocol number */
	__be32 flow_ip;			/**< Flow IP address */
	__be32 flow_ip_xlate;		/**< Translated flow IP address */
	__be16 flow_ident;		/**< Flow ident (e.g. port) */
	__be16 flow_ident_xlate;	/**< Translated flow ident (e.g. port) */
	u32 flow_max_window;	/**< Flow direction's largest seen window */
	u32 flow_end;		/**< Flow direction's largest seen sequence + segment length */
	u32 flow_max_end;		/**< Flow direction's largest seen ack + max(1, win) */
	u32 flow_rx_packet_count;	/**< Flow interface's RX packet count */
	u32 flow_rx_byte_count;	/**< Flow interface's RX byte count */
	u32 flow_tx_packet_count;	/**< Flow interface's TX packet count */
	u32 flow_tx_byte_count;	/**< Flow interface's TX byte count */
	u16 flow_pppoe_session_id; /**< Flow interface`s PPPoE session ID. */
	u16 flow_pppoe_remote_mac[3];
					/**< Flow interface's PPPoE remote server MAC address if there is any */
	__be32 return_ip;		/**< Return IP address */
	__be32 return_ip_xlate;		/**< Translated return IP address */
	__be16 return_ident;		/**< Return ident (e.g. port) */
	__be16 return_ident_xlate;	/**< Translated return ident (e.g. port) */
	u32 return_max_window;	/**< Return direction's largest seen window */
	u32 return_end;		/**< Return direction's largest seen sequence + segment length */
	u32 return_max_end;	/**< Return direction's largest seen ack + max(1, win) */
	u32 return_rx_packet_count;
					/**< Return interface's RX packet count */
	u32 return_rx_byte_count;	/**< Return interface's RX byte count */
	u32 return_tx_packet_count;
					/**< Return interface's TX packet count */
	u32 return_tx_byte_count;	/**< Return interface's TX byte count */
	u16 return_pppoe_session_id;
					/**< Return interface`s PPPoE session ID. */
	u16 return_pppoe_remote_mac[3];
					/**< Return interface's PPPoE remote server MAC address if there is any */
	u32 inc_ticks;		/**< Number of ticks since the last sync */
	u32 reason;		/**< Reason for the sync */

	u8 flags;			/**< Bit flags associated with the rule */
	u32 qos_tag;		/**< QoS Tag */
	u32 cause;			/**< Flush Cause */
};

/*
 * Message structure to send/receive IPv4 bridge/route commands
 */
struct sfe_ipv4_msg {
	struct sfe_cmn_msg cm;		/**< Message Header */
	union {
		struct sfe_ipv4_rule_create_msg rule_create;	/**< Message: rule create */
		struct sfe_ipv4_rule_destroy_msg rule_destroy;	/**< Message: rule destroy */
		struct sfe_ipv4_conn_sync conn_stats;	/**< Message: connection stats sync */
	} msg;
};

/**
 * Callback to be called when IPv4 message is received
 */
typedef void (*sfe_ipv4_msg_callback_t)(void *app_data, struct sfe_ipv4_msg *msg);

/**
 * The IPv6 rule create sub-message structure.
 */
struct sfe_ipv6_rule_create_msg {
	/*
	 * Request
	 */
	u16 valid_flags;				/**< Bit flags associated with the validity of parameters */
	u16 rule_flags;				/**< Bit flags associated with the rule */
	struct sfe_ipv6_5tuple tuple;			/**< Holds values of the 5 tuple */
	struct sfe_ipv6_connection_rule conn_rule;	/**< Basic connection specific data */
	struct sfe_protocol_tcp_rule tcp_rule;		/**< Protocol related accleration parameters */
	struct sfe_pppoe_rule pppoe_rule;		/**< PPPoE related accleration parameters */
	struct sfe_qos_rule qos_rule;			/**< QoS related accleration parameters */
	struct sfe_dscp_rule dscp_rule;			/**< DSCP related accleration parameters */
	struct sfe_vlan_rule vlan_primary_rule;		/**< VLAN related accleration parameters */
	struct sfe_vlan_rule vlan_secondary_rule;	/**< VLAN related accleration parameters */
#ifdef CONFIG_XFRM
	struct sfe_acceleration_direction_rule direction_rule;/* Direction related accleration parameters*/
#endif
	/*
	 * Response
	 */
	u32 index;					/**< Slot ID for cache stats to host OS */
};

/**
 * The IPv6 rule destroy sub-message structure.
 */
struct sfe_ipv6_rule_destroy_msg {
	struct sfe_ipv6_5tuple tuple;	/**< Holds values of the 5 tuple */
};

/**
 * The SFE IPv6 rule sync structure.
 */
struct sfe_ipv6_conn_sync {
	u32 index;			/**< Slot ID for cache stats to host OS */
	u8 protocol;		/**< Protocol number */
	__be32 flow_ip[4];		/**< Flow IP address */
	__be16 flow_ident;		/**< Flow ident (e.g. port) */
	u32 flow_max_window;	/**< Flow direction's largest seen window */
	u32 flow_end;		/**< Flow direction's largest seen sequence + segment length */
	u32 flow_max_end;		/**< Flow direction's largest seen ack + max(1, win) */
	u32 flow_rx_packet_count;	/**< Flow interface's RX packet count */
	u32 flow_rx_byte_count;	/**< Flow interface's RX byte count */
	u32 flow_tx_packet_count;	/**< Flow interface's TX packet count */
	u32 flow_tx_byte_count;	/**< Flow interface's TX byte count */
	u16 flow_pppoe_session_id; /**< Flow interface`s PPPoE session ID. */
	u16 flow_pppoe_remote_mac[3];
					/**< Flow interface's PPPoE remote server MAC address if there is any */
	__be32 return_ip[4];		/**< Return IP address */
	__be16 return_ident;		/**< Return ident (e.g. port) */
	u32 return_max_window;	/**< Return direction's largest seen window */
	u32 return_end;		/**< Return direction's largest seen sequence + segment length */
	u32 return_max_end;	/**< Return direction's largest seen ack + max(1, win) */
	u32 return_rx_packet_count;
					/**< Return interface's RX packet count */
	u32 return_rx_byte_count;	/**< Return interface's RX byte count */
	u32 return_tx_packet_count;
					/**< Return interface's TX packet count */
	u32 return_tx_byte_count;	/**< Return interface's TX byte count */
	u16 return_pppoe_session_id;
					/**< Return interface`s PPPoE session ID. */
	u16 return_pppoe_remote_mac[3];
					/**< Return interface's PPPoE remote server MAC address if there is any */
	u32 inc_ticks;		/**< Number of ticks since the last sync */
	u32 reason;		/**< Reason for the sync */
	u8 flags;			/**< Bit flags associated with the rule */
	u32 qos_tag;		/**< QoS Tag */
	u32 cause;			/**< Flush cause associated with the rule */
};

/**
 * Message structure to send/receive IPv6 bridge/route commands
 */
struct sfe_ipv6_msg {
	struct sfe_cmn_msg cm;					/**< Message Header */
	union {
		struct sfe_ipv6_rule_create_msg rule_create;	/**< Message: rule create */
		struct sfe_ipv6_rule_destroy_msg rule_destroy;	/**< Message: rule destroy */
		struct sfe_ipv6_conn_sync conn_stats;		/**< Message: stats sync */
	} msg;
};

/**
 * Callback to be called when IPv6 message is received
 */
typedef void (*sfe_ipv6_msg_callback_t)(void *app_data, struct sfe_ipv6_msg *msg);

/**
 * 6rd tunnel peer addr.
 */
struct sfe_tun6rd_set_peer_msg {
	__be32 ipv6_address[4];	/* The peer's ipv6 addr*/
	__be32 dest;		/* The peer's ipv4 addr*/
};

/**
 * Message structure to send/receive 6rd tunnel messages
 */
struct sfe_tun6rd_msg {
	struct sfe_cmn_msg cm;					/* Message Header */
	union {
		struct sfe_tun6rd_set_peer_msg peer;		/* Message: add/update peer */
	} msg;
};

/*
 * sfe driver context instance
 */
struct sfe_drv_ctx_instance {
	int not_used;
};

/*
 * sfe_drv_ipv4_max_conn_count()
 * 	Return the maximum number of IPv4 connections that the sfe acceleration engine supports
 *
 * @return int The number of connections that can be accelerated by the sfe
 */
int sfe_drv_ipv4_max_conn_count(void);

/*
 * sfe_drv_ipv4_tx()
 * 	Transmit an IPv4 message to the sfe
 *
 * @param sfe_drv_ctx sfe driver context
 * @param msg The IPv4 message
 *
 * @return sfe_tx_status_t The status of the Tx operation
 */
extern sfe_tx_status_t sfe_drv_ipv4_tx(struct sfe_drv_ctx_instance *sfe_drv_ctx, struct sfe_ipv4_msg *msg);

/*
 * sfe_drv_ipv4_notify_register()
 * 	Register a notifier callback for IPv4 messages from sfe driver
 *
 * @param cb The callback pointer
 * @param app_data The application context for this message
 *
 * @return struct sfe_drv_ctx_instance * The sfe driver context
 */
extern struct sfe_drv_ctx_instance *sfe_drv_ipv4_notify_register(sfe_ipv4_msg_callback_t cb, void *app_data);

/*
 * sfe_drv_ipv4_notify_unregister()
 * 	Un-Register a notifier callback for IPv4 messages from sfe driver
 */
extern void sfe_drv_ipv4_notify_unregister(void);

/*
 * sfe_ipv4_msg_init()
 * 	IPv4 message init
 */
extern void sfe_ipv4_msg_init(struct sfe_ipv4_msg *nim, u16 if_num, u32 type, u32 len,
			sfe_ipv4_msg_callback_t cb, void *app_data);

/*
 * sfe_drv_ipv6_max_conn_count()
 * 	Return the maximum number of IPv6 connections that the sfe acceleration engine supports
 *
 * @return int The number of connections that can be accelerated by the sfe
 */
int sfe_drv_ipv6_max_conn_count(void);

/*
 * sfe_drv_ipv6_tx()
 * 	Transmit an IPv6 message to the sfe
 *
 * @param sfe_drv_ctx sfe driver context
 * @param msg The IPv6 message
 *
 * @return sfe_tx_status_t The status of the Tx operation
 */
extern sfe_tx_status_t sfe_drv_ipv6_tx(struct sfe_drv_ctx_instance *sfe_drv_ctx, struct sfe_ipv6_msg *msg);

/*
 * sfe_drv_ipv6_notify_register()
 * 	Register a notifier callback for IPv6 messages from sfe driver
 *
 * @param cb The callback pointer
 * @param app_data The application context for this message
 *
 * @return struct sfe_drv_ctx_instance * The sfe driver context
 */
extern struct sfe_drv_ctx_instance *sfe_drv_ipv6_notify_register(sfe_ipv6_msg_callback_t cb, void *app_data);

/*
 * sfe_drv_ipv6_notify_unregister()
 * Un-Register a notifier callback for IPv6 messages from sfe driver
 */
extern void sfe_drv_ipv6_notify_unregister(void);

/*
 * sfe_ipv6_msg_init()
 * 	IPv6 message init
 */
extern void sfe_ipv6_msg_init(struct sfe_ipv6_msg *nim, u16 if_num, u32 type, u32 len,
			sfe_ipv6_msg_callback_t cb, void *app_data);

/*
 * sfe_tun6rd_tx()
 * 	Transmit a tun6rd message to sfe engine
 */
sfe_tx_status_t sfe_tun6rd_tx(struct sfe_drv_ctx_instance *sfe_ctx, struct sfe_tun6rd_msg *msg);

/*
 * sfe_tun6rd_msg_init()
 *      Initialize sfe_tun6rd msg.
 */
void sfe_tun6rd_msg_init(struct sfe_tun6rd_msg *ncm, u16 if_num, u32 type,  u32 len,
			 void *cb, void *app_data);

#endif /* __SFE_DRV_H */
