/*
 * Copyright (c) 2014, 2018, The Linux Foundation. All rights reserved.
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

#ifndef _NSS_MACSEC_SECY_H_
#define _NSS_MACSEC_SECY_H_

#include "nss_macsec_types.h"

#define FAL_SECY_ID_NUM_MAX     3
#define FAL_SECY_DEFAULT_MTU    1500
#define FAL_SCI_LEN             8
#define FAL_SECY_SC_MAX_NUM     32
#define FAL_SAK_DEFAULT_LEN     16
#define FAL_MACSEC_IP_VER_STR_LEN    32
#define FAL_TX_RX_MTU_MAX 0x7fff
#define FAL_AN_MAX  3

typedef enum {
	FAL_SC_SA_MAP_1_1 = 0,
	FAL_SC_SA_MAP_1_2 = 1,
	FAL_SC_SA_MAP_1_4 = 2,
	FAL_SC_SA_MAP_MAX = 3
} fal_sc_sa_mapping_mode_e;

typedef enum {
	FAL_CIPHER_SUITE_AES_GCM_128 = 0,
	FAL_CIPHER_SUITE_AES_GCM_256,
	FAL_CIPHER_SUITE_AES_GCM_XPN_128,
	FAL_CIPHER_SUITE_AES_GCM_XPN_256,
	FAL_CIPHER_SUITE_MAX
} fal_cipher_suite_e;

typedef struct {
	u8 sci[FAL_SCI_LEN];
} fal_tx_sc_t;

typedef struct {
	fal_sc_sa_mapping_mode_e sc_sa_map_mode;
	fal_cipher_suite_e cipher_suite;
	u32 mtu;
	bool enable;		/* 1: the secy is enabled and
				 *    GMAC bypass is disabled */
	fal_tx_sc_t tx_sc[FAL_SECY_SC_MAX_NUM];
} fal_secy_cfg_t;

extern fal_secy_cfg_t g_secy_cfg[];

enum fal_packet_type_t {
	FAL_PACKET_STP   = 0,   /**< Spanning Tree Protocol Packet */
	FAL_PACKET_CDP   = 1,   /**< Cisco Discovery Protocol Packet */
	FAL_PACKET_LLDP  = 2   /**< Link Layer Discovery Protocol Packet */
};

enum fal_packet_action_t {
	FAL_PACKET_CRYPTO_OR_DISCARD = 0X0,
	FAL_PACKET_CRYPTO_OR_UPLOAD  = 0X1,
	FAL_PACKET_PLAIN_OR_DISCARD  = 0X2,
	FAL_PACKET_PLAIN_OR_UPLOAD   = 0X3
};

enum fal_loopback_type_t {
	FAL_MACSEC_NORMAL     = 0x0,    /**< MACsec works normally */
	FAL_MACSEC_PHY_LB     = 0x1,    /**< Phy side loopback */
	FAL_MACSEC_SWITCH_LB  = 0x2,    /**< Switch side loopback */
	FAL_MACSEC_BYPASS     = 0x3    /**< MACsec bypassed */
};

/**
* @param[in] secy_id
**/
u32 nss_macsec_secy_reset(u32 secy_id);

/**
* @param[in] secy_id
**/
u32 nss_macsec_secy_tx_sw_reset(u32 secy_id);	//tiger: is this API necessary?

/**
* @param[in] secy_id
**/
u32 nss_macsec_secy_init(u32 secy_id);

/**
* @param[in] secy_id
* @param[out] pmode
**/
u32 nss_macsec_secy_sc_sa_mapping_mode_get(u32 secy_id,
					   fal_sc_sa_mapping_mode_e *pmode);
/**
* @param[in] secy_id
* @param[in] mode
**/
u32 nss_macsec_secy_sc_sa_mapping_mode_set(u32 secy_id,
					   fal_sc_sa_mapping_mode_e mode);

/**
* @param[in] secy_id
* @param[out] penable
**/
u32 nss_macsec_secy_controlled_port_en_get(u32 secy_id, bool *penable);

/**
* @param[in] secy_id
* @param[in] enable
**/
u32 nss_macsec_secy_controlled_port_en_set(u32 secy_id, bool enable);

/**
* @param[in] secy_id
* @param[out] ver_str
* @param[in] str_len
**/
u32 nss_macsec_secy_ip_version_get(u32 secy_id, char *ver_str, u32 ver_str_len); /* [64] */

/**
* @param[in] secy_id
* @param[out] p_cipher_suite
**/
u32 nss_macsec_secy_cipher_suite_get(u32 secy_id,
                                    fal_cipher_suite_e *p_cipher_suite);

/**
* @param[in] secy_id
* @param[in] cipher_suite
**/
u32 nss_macsec_secy_cipher_suite_set(u32 secy_id,
                                    fal_cipher_suite_e cipher_suite);

/**
* @param[in] secy_id
* @param[out] pmtu
**/
u32 nss_macsec_secy_mtu_get(u32 secy_id, u32 *pmtu);

/**
* @param[in] secy_id
* @param[in] mtu
**/
u32 nss_macsec_secy_mtu_set(u32 secy_id, u32 mtu);

/**
* @param[in] secy_id
* @param[out] penable
**/
u32 nss_macsec_secy_en_get(u32 secy_id, bool *penable);

/**
* @param[in] secy_id
* @param[in] enable
**/
u32 nss_macsec_secy_en_set(u32 secy_id, bool enable);

u32 nss_macsec_secy_xpn_en_get(u32 secy_id, bool *penable);

u32 nss_macsec_secy_xpn_en_set(u32 secy_id, bool enable);

u32 nss_macsec_secy_flow_control_en_get(u32 secy_id, bool *penable);

u32 nss_macsec_secy_flow_control_en_set(u32 secy_id, bool enable);

u32 nss_macsec_secy_special_pkt_ctrl_get(u32 secy_id,
	enum fal_packet_type_t packet_type,
	enum fal_packet_action_t *packet_action);

u32 nss_macsec_secy_special_pkt_ctrl_set(u32 secy_id,
	enum fal_packet_type_t packet_type,
	enum fal_packet_action_t packet_action);

u32 nss_macsec_secy_udf_ethtype_get(u32 secy_id, bool *penable, u16 *type);

u32 nss_macsec_secy_udf_ethtype_set(u32 secy_id, bool enable, u16 type);

u32 nss_macsec_secy_loopback_get(u32 secy_id,
	enum fal_loopback_type_t *type);

u32 nss_macsec_secy_loopback_set(u32 secy_id,
	enum fal_loopback_type_t type);


#endif /* _NSS_MACSEC_SECY_H_ */
