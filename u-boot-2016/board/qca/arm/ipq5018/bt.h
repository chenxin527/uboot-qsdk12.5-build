/*
 * Copyright (c) 2020 The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef _BT_H
#define _BT_H

#include <asm/atomic.h>

#define	PAS_ID	0xC
#define	CMD_ID	0x14
#define BT_M0_WARM_RST_ORIDE	0x0
#define BT_M0_WARM_RST		0x4

#define IOCTL_IPC_BOOT		0xBE
#define IPC_TX_QSIZE		0x20

#define BT_ECO_BIT_SET		0x4
#define BT_ECO_BIT_RESET	0x0

#define	TO_APPS_ADDR(a)		(btmem->virt + (int)(uintptr_t)a)
#define	TO_BT_ADDR(a)		(a - btmem->virt)
#define IPC_LBUF_SZ(w, x, y, z)	(((TO_BT_ADDR((void *)w) + w->x) - w->y) / w->z)

#define IPC_MSG_HDR_SZ		(4u)
#define IPC_MSG_PLD_SZ		(40u)
#define IPC_TOTAL_MSG_SZ	(IPC_MSG_HDR_SZ + IPC_MSG_PLD_SZ)

#define IPC_LMSG_MASK		(0x8000u)
#define IPC_RACK_MASK		(0x4000u)
#define IPC_PKT_TYPE_MASK	(0x0300u)
#define IPC_MSG_ID_MASK		(0x00FFu)

#define IPC_LMSG_TYPE		((uint16_t) IPC_LMSG_MASK)
#define IPC_SMSG_TYPE		((uint16_t) 0x0000u)
#define IPC_REQ_ACK		((uint16_t) IPC_RACK_MASK)
#define IPC_NO_ACK		((uint16_t) 0x0000u)
#define IPC_PKT_TYPE_CUST	((uint16_t) 0x0000u)
#define IPC_PKT_TYPE_HCI	((uint16_t) 0x0100u)
#define IPC_PKT_TYPE_AUDIO	((uint16_t) 0x0200u)
#define IPC_PKT_TYPE_RFU	(IPC_PKT_TYPE_MASK)

#define IPC_LMSG_SHIFT		(15u)
#define IPC_RACK_SHIFT		(14u)
#define IPC_PKT_TYPE_SHIFT	(8u)

#define	GET_NO_OF_BLOCKS(a, b) ((a + b - 1) / b)

#define GET_RX_INDEX_FROM_BUF(x, y)	((x - btmem->rx_ctxt->lring_buf) / y)

#define GET_TX_INDEX_FROM_BUF(x, y)	((x - btmem->tx_ctxt->lring_buf) / y)

#define IS_RX_MEM_NON_CONTIGIOUS(pBuf, len, sz)		\
	((pBuf + len) >			\
	(btmem->rx_ctxt->lring_buf +	\
	(sz * btmem->rx_ctxt->lmsg_buf_cnt)))

/** Message header format.
 *
 *         ---------------------------------------------------------------
 * BitPos |    15    | 14 | 13 | 12 | 11 | 10 |  9  |  8  |    7 - 0     |
 *         ---------------------------------------------------------------
 * Field  | Long Msg |rAck|        RFU        |  PktType  |    msgID     |
 *         ---------------------------------------------------------------
 *
 * - Long Msg   :
 *
 * - reqAck     : This is interpreted by receiver for sending acknowledegement
 *                to sender i.e. send a ack IPC interrupt if set.
 *                Use @ref IS_REQ_ACK or @ref IS_NO_ACK
 *                to determine ack is requested or not.
 *
 * - RFU        : Reserved for future use.
 *
 * - pktType    :
 *
 * - msgID      : Contains unique message ID within a Category.
 *                Use @ref IPC_GET_MSG_ID to get message ID.
 */
#define IPC_ConstructMsgHeader(msgID, reqAck, pktType, longMsg)	\
	(((uint8_t) longMsg << IPC_LMSG_SHIFT) |		\
	((uint8_t) reqAck << IPC_RACK_SHIFT) |			\
	((uint16_t) pktType << IPC_PKT_TYPE_SHIFT) | msgID)

#define IPC_GET_PKT_TYPE(hdr)	\
	((enum ipc_pkt_type)((hdr & IPC_PKT_TYPE_MASK) >> IPC_PKT_TYPE_SHIFT))

#define IS_LONG_MSG(hdr)	((hdr & IPC_LMSG_MASK) == IPC_LMSG_TYPE)
#define IS_SHORT_MSG(hdr)	((hdr & IPC_LMSG_MASK) == IPC_SMSG_TYPE)

#define IS_REQ_ACK(hdr)		((hdr & IPC_RACK_MASK) == IPC_REQ_ACK)
#define IS_NO_ACK(hdr)		((hdr & IPC_RACK_MASK) == IPC_NO_ACK)

#define IS_HCI_PKT(hdr)		((hdr & IPC_PKT_TYPE_MASK) == IPC_PKT_TYPE_HCI)
#define IS_CUST_PKT(hdr)	((hdr & IPC_PKT_TYPE_MASK) == IPC_PKT_TYPE_CUST)

#define IPC_GET_MSG_ID(hdr)	((uint8_t)(hdr & IPC_MSG_ID_MASK))

#define IPC_CMD_IPC_STOP	(0x01)
#define IPC_CMD_SWITCH_TO_UART	(0x02)
#define IPC_CMD_PREPARE_DUMP	(0x03)
#define IPC_CMD_COLLECT_DUMP	(0x04)
#define IPC_CMD_IPC_START	(0x05)

#define BT_RAM_START 0x7000000
#define BT_RAM_PATCH 0x7020250
#define BT_RAM_SIZE 0x58000
#define SYSCON 0x0B111000

/*-------------------------------------------------------------------------
 * Type Declarations
 * ------------------------------------------------------------------------
 */

enum ipc_pkt_type {
	IPC_CUST_PKT,
	IPC_HCI_PKT,
	IPC_AUDIO_PKT,
	IPC_PKT_MAX
};

struct long_msg_info {
	uint16_t smsg_free_cnt;
	uint16_t lmsg_free_cnt;
	uint8_t ridx;
	uint8_t widx;
};

struct ipc_aux_ptr {
	uint32_t len;
	uint32_t buf;
};

struct ring_buffer {
	uint16_t msg_hdr;
	uint16_t len;

	union {
		uint8_t  smsg_data[IPC_MSG_PLD_SZ];
		uint32_t  lmsg_data;
	} payload;
};

struct ring_buffer_info {
	uint32_t rbuf;
	uint8_t ring_buf_cnt;
	uint8_t ridx;
	uint8_t widx;
	uint8_t tidx;
	uint32_t next;
};

struct context_info {
	uint16_t TotalMemorySize;
	uint8_t lmsg_buf_cnt;
	uint8_t smsg_buf_cnt;
	struct ring_buffer_info sring_buf_info;
	uint32_t sring_buf;
	uint32_t lring_buf;
	uint32_t reserved;
};


struct bt_mem {
	phys_addr_t phys;
	phys_addr_t reloc;
	void __iomem *virt;
	size_t size;
	struct context_info *tx_ctxt;
	struct context_info *rx_ctxt;
	struct long_msg_info lmsg_ctxt;
};

struct bt_ipc {
	uint32_t regmap;
	int offset;
	int bit;
	int irq;
	atomic_t tx_q_cnt;
};

struct bt_descriptor {
	void __iomem *warm_reset;
	struct bt_ipc ipc;
	struct bt_mem btmem;
	int (*sendmsg_cb)(struct bt_descriptor *, unsigned char *, int);
	void (*recvmsg_cb)(struct bt_descriptor *, unsigned char *, int);
	atomic_t state;
	atomic_t tx_in_progress;
	unsigned char *buf;
	uint32_t len;
};

struct ipc_intent {
	uint8_t *buf;
	uint16_t len;
};

extern int bt_ipc_sendmsg(struct bt_descriptor *btDesc, unsigned char *buf, int len );
extern void bt_ipc_init(struct bt_descriptor *btDesc);
extern void bt_ipc_worker(struct bt_descriptor *btDesc);
extern int bt_running;
#endif /* _BT_H */
