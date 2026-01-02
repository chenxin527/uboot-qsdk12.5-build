/*
* Copyright (c) 2018 Qualcomm Innovation Center, Inc.
* All Rights Reserved.
* Confidential and Proprietary - Qualcomm Innovation Center, Inc.
*
*/

/*
 * Copyright (c) 2010, Atheros Communications Inc.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */


#ifndef __BYP_TYPES_H__
#define __BYP_TYPES_H__

#include <qdf_types.h>

/** Maximum Size Settings */
#define BYP_SZ_IFNAME       32
#define BYP_SZ_VIDNAME      4   /** Max VLAN ID = "4096" */
#define BYP_SZ_IFADDR       6
#define BYP_SZ_REPLAYCMD    1024
#define BYP_SZ_CMD          1024

#define BYP_RPLAYCMD_SUCCESS    1


enum BYP_CMD_TYPE {
    BYP_CMD_BYPEN = 0,
    BYP_CMD_VAPCTRL,
    BYP_CMD_ADDMAC,
    BYP_CMD_DELMAC,
    BYP_CMD_VLGRPCREATE,
    BYP_CMD_VLGRPDELETE,
    BYP_CMD_VLGRPADDVAP,
    BYP_CMD_VLGRPDELVAP,
    BYP_CMD_VLCREATE,
    BYP_CMD_VLDELETE,
    BYP_CMD_BRCREATE,
    BYP_CMD_BRDELETE,
    BYP_CMD_BRIFUP,
    BYP_CMD_BRIFDOWN,
    BYP_CMD_BRLISTMAC,
    BYP_CMD_LAST
};

/* LAN Bypass mode definitions for command selection */
#define     LANBYP_MODE_DISABLED    0x0
#define     LANBYP_MODE_TUNNEL      0x1
#define     LANBYP_MODE_VLAN        0x2
#define     LANBYP_MODE_NOTSET      0x4
#define     LANBYP_MODE_ALL         0x7

/*
 * @brief
 *  Command Header
 *  byte 0:
 *  bits[3:0] - Reserved
 *  bits[4:4] - Node Id (0: kernel/1: peer)
 *  bits[5:5] - Command Type (Req/Resp)
 *  bits[6:6] - Acknowledgement Required (0/1)
 *  bits[7:7] - Response Required (0/1)
 *
 *  byte 1:
 *  bits[7:0] - Command Identifier (0 - 247)
 *
 *  byte 3:
 *  bits[7:0] - Parameters length (LSB)
 *
 *  byte 4:
 *  bits[7:0] - Parameters length (MSB)
 */

/* Byte 0 Masks */
#define BYP_CMD_APPID_MASK	0xF
#define BYP_CMD_NODE_MASK		0x10
#define BYP_CMD_REQ_MASK		0x20
#define BYP_CMD_ACK_MASK		0x40
#define BYP_CMD_RESP_MASK		0x80

/* Byte 0 Values */
#define BYP_NODE_ALL          0x00
#define BYP_NODE_REMOTE       0x10

#define BYP_CMD_REQ           0x20
#define BYP_CMD_RESP          0x00

#define BYP_ACK_REQD          0x40
#define BYP_RESP_REQD         0x80

/* ACK return values */
#define BYP_ACK_SUCCESS       1
#define BYP_ACK_FAILURE       0

#define BYP_VAPCTRL_SETMASK       0x10
#define BYP_VAPCTRL_SET           0x10
#define BYP_VAPCTRL_RESET         0x0
#define BYP_VAPCTRL_ACCMASK       0x3
#define BYP_VAPCTRL_BR_EN         0x1
#define BYP_VAPCTRL_LAN_EN        0x2

typedef uint8_t   byp_vapctrl_flg_t;

/* Common structures for BypassH <-> BypassT communication */
typedef struct byp_common {
    uint8_t data[4];
} byp_common_t;

typedef struct byp_br {
    struct byp_common   common;
    char                br_name[BYP_SZ_IFNAME];
    char                if_name[BYP_SZ_IFNAME];
    uint8_t           br_addr[BYP_SZ_IFADDR];
} byp_br_t;

typedef struct byp_vapctrl {
    struct byp_common common;
    char              if_name[BYP_SZ_IFNAME];
    char              br_name[BYP_SZ_IFNAME];
    uint8_t         ctrl;
} byp_vapctrl_t;

typedef struct byp_stat {
    struct byp_common common;
    uint8_t         byp_status;
} byp_stat_t;

typedef struct byp_vlan {
    struct byp_common   common;
    char                if_name[BYP_SZ_IFNAME];
    char                vlan_id[BYP_SZ_VIDNAME];
} byp_vlan_t;

#endif /* __AC_COMMON_H__ */
