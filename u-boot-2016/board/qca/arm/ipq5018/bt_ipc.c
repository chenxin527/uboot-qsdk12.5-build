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

#include <linux/io.h>
#include <asm/atomic.h>
#include <asm-generic/atomic-long.h>

#include <linux/ctype.h>
#include "bt.h"

#include <common.h>
#include <memalign.h>

#include <linux/err.h>
#include <asm/arch-qca-common/scm.h>

static void *bt_ipc_alloc_lmsg(struct bt_descriptor *btDesc, uint32_t len,
		struct ipc_aux_ptr *aux_ptr, uint8_t *is_lbuf_full)
{
	uint8_t idx;
	uint8_t blks;
	uint8_t blks_consumed;
	struct bt_mem *btmem = &btDesc->btmem;
	uint32_t lsz = IPC_LBUF_SZ(btmem->tx_ctxt, TotalMemorySize, lring_buf,
				   lmsg_buf_cnt);

	if (btmem->tx_ctxt->lring_buf == 0) {
		printf("no long message buffer not initialized\n");
		return ERR_PTR(-ENODEV);
	}

	blks = GET_NO_OF_BLOCKS(len, lsz);

	if (!btmem->lmsg_ctxt.lmsg_free_cnt ||
			(blks > btmem->lmsg_ctxt.lmsg_free_cnt))
		return ERR_PTR(-EAGAIN);

	idx = btmem->lmsg_ctxt.widx;

	if ((btmem->lmsg_ctxt.widx + blks) > btmem->tx_ctxt->lmsg_buf_cnt) {
		blks_consumed = btmem->tx_ctxt->lmsg_buf_cnt - idx;
		aux_ptr->len = len - (blks_consumed * lsz);
		aux_ptr->buf = btmem->tx_ctxt->lring_buf;
	}

	btmem->lmsg_ctxt.widx = (btmem->lmsg_ctxt.widx + blks) %
		btmem->tx_ctxt->lmsg_buf_cnt;

	btmem->lmsg_ctxt.lmsg_free_cnt -= blks;

	if (btmem->lmsg_ctxt.lmsg_free_cnt <=
			((btmem->tx_ctxt->lmsg_buf_cnt * 20) / 100))
		*is_lbuf_full = 1;

	return (TO_APPS_ADDR(btmem->tx_ctxt->lring_buf) + (idx * lsz));
}

static struct ring_buffer_info *bt_ipc_get_tx_rbuf(struct bt_descriptor *btDesc,
		uint8_t *is_sbuf_full)
{
	uint8_t idx;
	struct ring_buffer_info *rinfo;
	struct bt_mem *btmem = &btDesc->btmem;

	for (rinfo = &(btmem->tx_ctxt->sring_buf_info);	rinfo != NULL;
		rinfo = (struct ring_buffer_info *)(uintptr_t)(rinfo->next)) {
		idx = (rinfo->widx + 1) % (btmem->tx_ctxt->smsg_buf_cnt);

		if (idx != rinfo->tidx) {
			btmem->lmsg_ctxt.smsg_free_cnt--;

			if (btmem->lmsg_ctxt.smsg_free_cnt <=
				((btmem->tx_ctxt->smsg_buf_cnt * 20) / 100))
				*is_sbuf_full = 1;

			return rinfo;
		}
	}

	return ERR_PTR(-EAGAIN);
}

int bt_ipc_send_msg(struct bt_descriptor *btDesc, uint16_t msg_hdr,
		const uint8_t *pData, uint16_t len, bool dequeue)
{
	int ret = 0;
	struct bt_mem *btmem = &btDesc->btmem;
	struct ring_buffer_info *rinfo;
	struct ring_buffer *rbuf;
	uint8_t is_lbuf_full = 0;
	uint8_t is_sbuf_full = 0;
	struct ipc_aux_ptr aux_ptr;
	void *lmsg_data;

	rinfo = bt_ipc_get_tx_rbuf(btDesc, &is_sbuf_full);
	if (IS_ERR(rinfo)) {
		printf("short msg buf full, queuing msg[%d]\n",
				atomic_read(&btDesc->ipc.tx_q_cnt));
		ret = PTR_ERR(rinfo);
		return ret;
	}

	rbuf = &((struct ring_buffer *)(TO_APPS_ADDR(
						rinfo->rbuf)))[rinfo->widx];
	rbuf->msg_hdr = msg_hdr;
	rbuf->len = len;

	if (len > IPC_MSG_PLD_SZ) {
		rbuf->msg_hdr = rbuf->msg_hdr | IPC_LMSG_MASK;

		aux_ptr.len = 0;
		aux_ptr.buf = 0;

		lmsg_data = bt_ipc_alloc_lmsg(btDesc, len,
				&aux_ptr, &is_lbuf_full);

		if (IS_ERR(lmsg_data)) {
			printf("long msg buf full, queuing msg[%d]\n",
					atomic_read(&btDesc->ipc.tx_q_cnt));
			ret = PTR_ERR(lmsg_data);
			return ret;
		}

		memcpy_toio(lmsg_data, pData,
				(len - aux_ptr.len));

		if (aux_ptr.buf) {
			memcpy_toio(TO_APPS_ADDR(aux_ptr.buf),
				(pData + (len - aux_ptr.len)), aux_ptr.len);
		}

		rbuf->payload.lmsg_data = TO_BT_ADDR(lmsg_data);
	} else {
		memcpy_toio(rbuf->payload.smsg_data, pData, len);
	}

	if (is_sbuf_full || is_lbuf_full)
		rbuf->msg_hdr = rbuf->msg_hdr | IPC_RACK_MASK;

	rinfo->widx = (rinfo->widx + 1) % btmem->tx_ctxt->smsg_buf_cnt;

	writel( BIT(btDesc->ipc.bit), btDesc->ipc.regmap+ btDesc->ipc.offset);

	return ret;
}

static
void bt_ipc_free_lmsg(struct bt_descriptor *btDesc, uint32_t lmsg, uint16_t len)
{
	uint8_t idx;
	uint8_t blks;
	struct bt_mem *btmem = &btDesc->btmem;
	uint32_t lsz = IPC_LBUF_SZ(btmem->tx_ctxt, TotalMemorySize, lring_buf,
				   lmsg_buf_cnt);

	idx = GET_TX_INDEX_FROM_BUF(lmsg, lsz);

	if (idx != btmem->lmsg_ctxt.ridx)
		return;

	blks = GET_NO_OF_BLOCKS(len, lsz);

	btmem->lmsg_ctxt.ridx  = (btmem->lmsg_ctxt.ridx  + blks) %
		btmem->tx_ctxt->lmsg_buf_cnt;

	btmem->lmsg_ctxt.lmsg_free_cnt += blks;
}

static void bt_ipc_cust_msg(struct bt_descriptor *btDesc, uint8_t msgid)
{
	struct bt_mem *btmem = &btDesc->btmem;
	uint16_t msg_hdr = 0;
	int ret;

	msg_hdr |= msgid;

	switch (msgid) {
	case IPC_CMD_IPC_STOP:
		ret = qti_scm_toggle_bt_eco_bit(PAS_ID, BT_ECO_BIT_SET);
		if (ret) {
			printf("Failed to set BT ECO\n");
			return;
		}
		printf("BT IPC Stopped, gracefully stopping APSS IPC\n");
		break;
	case IPC_CMD_SWITCH_TO_UART:
		printf("Configured UART, Swithing BT to debug mode\n");
		break;
	case IPC_CMD_PREPARE_DUMP:
		printf("IPQ crashed, inform BT to prepare dump\n");
		break;
	case IPC_CMD_COLLECT_DUMP:
		printf("BT Crashed, gracefully stopping IPC\n");
		return;
	case IPC_CMD_IPC_START:
		ret = qti_scm_toggle_bt_eco_bit(PAS_ID, BT_ECO_BIT_RESET);
		if (ret) {
			printf("Failed to reset BT ECO\n");
			return;
		}

		btmem->tx_ctxt = (struct context_info *)((void *)
			btmem->rx_ctxt + btmem->rx_ctxt->TotalMemorySize);
		btmem->lmsg_ctxt.widx = 0;
		btmem->lmsg_ctxt.ridx = 0;
		btmem->lmsg_ctxt.smsg_free_cnt = btmem->tx_ctxt->smsg_buf_cnt;
		btmem->lmsg_ctxt.lmsg_free_cnt = btmem->tx_ctxt->lmsg_buf_cnt;
		atomic_set(&btDesc->state, 1);

		printf("BT IPC Started, starting APSS IPC\n");
		return;
	default:
		printf("invalid custom message\n");
		return;
	}

	if (unlikely(!atomic_read(&btDesc->state))) {
		printf("BT IPC not initialized, no message sent\n");
		return;
	}

	atomic_set(&btDesc->state, 0);

	ret = bt_ipc_send_msg(btDesc, msg_hdr, NULL, 0, true);
	if (ret)
		printf("err: sending message\n");
}

static bool bt_ipc_process_peer_msgs(struct bt_descriptor *btDesc,
		struct ring_buffer_info *rinfo, uint8_t *pRxMsgCount)
{
	struct bt_mem *btmem = &btDesc->btmem;
	struct ring_buffer *rbuf;
	uint8_t ridx, lbuf_idx;
	uint8_t blks_consumed;
	struct ipc_aux_ptr aux_ptr;
	enum ipc_pkt_type pktType = IPC_CUST_PKT;
	bool ackReqd = false;
	uint8_t *rxbuf = NULL;
	uint32_t lsz = IPC_LBUF_SZ(btmem->rx_ctxt, TotalMemorySize, lring_buf,
				   lmsg_buf_cnt);

	ridx = rinfo->ridx;

	rbuf = &((struct ring_buffer *)(TO_APPS_ADDR(
			btmem->rx_ctxt->sring_buf_info.rbuf)))[ridx];

	while (ridx != rinfo->widx) {
		memset(&aux_ptr, 0, sizeof(struct ipc_aux_ptr));

		rbuf = &((struct ring_buffer *)(TO_APPS_ADDR(
				btmem->rx_ctxt->sring_buf_info.rbuf)))[ridx];

		if (IS_LONG_MSG(rbuf->msg_hdr)) {
			rxbuf = TO_APPS_ADDR(rbuf->payload.lmsg_data);

			if (IS_RX_MEM_NON_CONTIGIOUS(rbuf->payload.lmsg_data,
							rbuf->len, lsz)) {

				lbuf_idx = GET_RX_INDEX_FROM_BUF(
						rbuf->payload.lmsg_data, lsz);

				blks_consumed = btmem->rx_ctxt->lmsg_buf_cnt -
					lbuf_idx;
				aux_ptr.len = rbuf->len - (blks_consumed * lsz);
				aux_ptr.buf = btmem->rx_ctxt->lring_buf;
			}
		} else {
			rxbuf = rbuf->payload.smsg_data;
		}

		if (IS_REQ_ACK(rbuf->msg_hdr))
			ackReqd = true;

		pktType = IPC_GET_PKT_TYPE(rbuf->msg_hdr);

		switch (pktType) {
		case IPC_HCI_PKT:
			btDesc->buf = kzalloc(rbuf->len, GFP_ATOMIC);
			if (!btDesc->buf)
				return -ENOMEM;

			memcpy_fromio(btDesc->buf, rxbuf, (rbuf->len - aux_ptr.len));

			if (aux_ptr.buf)
				memcpy_fromio(btDesc->buf + (rbuf->len - aux_ptr.len),
					TO_APPS_ADDR(aux_ptr.buf), aux_ptr.len);

			btDesc->len = rbuf->len;
			atomic_set(&btDesc->tx_in_progress, 0);
			break;
		case IPC_CUST_PKT:
			bt_ipc_cust_msg(btDesc, IPC_GET_MSG_ID(rbuf->msg_hdr));
			break;
		case IPC_AUDIO_PKT:
			break;
		default:
			break;
		}

		ridx = (ridx + 1) % rinfo->ring_buf_cnt;
	}

	rinfo->ridx = ridx;

	return ackReqd;
}

static void bt_ipc_process_ack(struct bt_descriptor *btDesc)
{
	struct ring_buffer_info *rinfo;
	struct bt_mem *btmem = &btDesc->btmem;

	for (rinfo = &btmem->tx_ctxt->sring_buf_info; rinfo != NULL;
		rinfo = (struct ring_buffer_info *)(uintptr_t)(rinfo->next)) {
		uint8_t tidx = rinfo->tidx;
		struct ring_buffer *rbuf = (struct ring_buffer *)
			TO_APPS_ADDR(rinfo->rbuf);

		while (tidx != rinfo->ridx) {
			if (IS_LONG_MSG(rbuf[tidx].msg_hdr)) {
				bt_ipc_free_lmsg(btDesc,
						 rbuf[tidx].payload.lmsg_data,
						 rbuf[tidx].len);
			}

			tidx = (tidx + 1) % btmem->tx_ctxt->smsg_buf_cnt;
			btmem->lmsg_ctxt.smsg_free_cnt++;
		}

		rinfo->tidx = tidx;
	}
}

int bt_ipc_sendmsg(struct bt_descriptor *btDesc, unsigned char *buf, int len)
{
	int ret;
	uint16_t msg_hdr = 0x100;

	if (unlikely(!atomic_read(&btDesc->state))) {
		printf("BT IPC not initialized, no message sent\n");
		return -ENODEV;
	}

	atomic_set(&btDesc->tx_in_progress, 1);
	ret = bt_ipc_send_msg(btDesc, msg_hdr, (uint8_t *)buf, (uint16_t)len,
				true);
	if (ret)
		printf("err: sending message\n");

	return ret;
}

void bt_ipc_worker(struct bt_descriptor *btDesc)
{
	struct ring_buffer_info *rinfo;

	struct bt_mem *btmem = &btDesc->btmem;
	bool ackReqd = false;

	if (unlikely(!atomic_read(&btDesc->state))) {
		btmem->rx_ctxt = (struct context_info *)(btmem->virt + 0xe000);
		if (btmem->rx_ctxt->sring_buf_info.widx != 0x1)
			return;
	}
	else
		bt_ipc_process_ack(btDesc);

	for (rinfo = &(btmem->rx_ctxt->sring_buf_info); rinfo != NULL;
		rinfo = (struct ring_buffer_info *)(uintptr_t)(rinfo->next)) {
		if (bt_ipc_process_peer_msgs(btDesc, rinfo,
					&btmem->rx_ctxt->smsg_buf_cnt)) {
			ackReqd = true;
		}
	}

	if (ackReqd) {
		writel( BIT(btDesc->ipc.bit), btDesc->ipc.regmap+ btDesc->ipc.offset);
	}

}

void  bt_ipc_init(struct bt_descriptor *btDesc)
{
	struct bt_mem *btmem;

	btmem = &btDesc->btmem;
	btmem->phys = BT_RAM_START;
        btmem->reloc = BT_RAM_START;
        btmem->size = BT_RAM_SIZE;
        btmem->virt = (void __iomem *)BT_RAM_START;

	btDesc->ipc.regmap = SYSCON;
	btDesc->ipc.offset = 8;
	btDesc->ipc.bit = 23;
	atomic_set(&btDesc->state, 0);
	atomic_set(&btDesc->tx_in_progress, 0);
}
