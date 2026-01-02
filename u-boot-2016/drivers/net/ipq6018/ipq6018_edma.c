/*
 * Copyright (c) 2016-2019 The Linux Foundation. All rights reserved.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE
 * USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <common.h>
#include <net.h>
#include <asm-generic/errno.h>
#include <asm/io.h>
#include <malloc.h>
#include <phy.h>
#include <net.h>
#include <miiphy.h>
#include <asm/arch-ipq6018/edma_regs.h>
#include <asm/global_data.h>
#include <fdtdec.h>
#include "ipq6018_edma.h"
#include "ipq_phy.h"

DECLARE_GLOBAL_DATA_PTR;
#ifdef DEBUG
#define pr_debug(fmt, args...) printf(fmt, ##args);
#else
#define pr_debug(fmt, args...)
#endif

#define pr_info(fmt, args...) printf(fmt, ##args);
#define pr_warn(fmt, args...) printf(fmt, ##args);

#ifndef CONFIG_IPQ6018_BRIDGED_MODE
#define IPQ6018_EDMA_MAC_PORT_NO	3
#endif

static struct ipq6018_eth_dev *ipq6018_edma_dev[IPQ6018_EDMA_DEV];

uchar ipq6018_def_enetaddr[6] = {0x00, 0x03, 0x7F, 0xBA, 0xDB, 0xAD};
phy_info_t *phy_info[IPQ6018_PHY_MAX] = {0};
phy_info_t *swt_info[QCA8084_MAX_PORTS] = {0};
int sgmii_mode[2] = {0};

extern void qca8075_ess_reset(void);
extern void psgmii_self_test(void);
extern void clear_self_test_config(void);
extern int ipq_sw_mdio_init(const char *);
extern void ipq_qca8075_dump_phy_regs(u32);
extern int ipq_mdio_read(int mii_id,
		int regnum, ushort *data);
extern void ipq_qca8075_phy_map_ops(struct phy_ops **ops);
extern int ipq_qca8075_phy_init(struct phy_ops **ops);
extern void qca8075_phy_interface_set_mode(uint32_t phy_id,
		uint32_t mode);
extern int ipq_qca8033_phy_init(struct phy_ops **ops, u32 phy_id);
extern int ipq_qca8081_phy_init(struct phy_ops **ops, u32 phy_id);
extern int ipq_qca_aquantia_phy_init(struct phy_ops **ops, u32 phy_id);
extern int ipq_board_fw_download(unsigned int phy_addr);
static int tftp_acl_our_port;

#ifdef CONFIG_QCA8084_SWT_MODE
extern int ipq_qca8084_hw_init(phy_info_t * phy_info[]);
extern void ipq_phy_addr_fixup(void);
extern void ipq_clock_init(void);
extern int ipq_qca8084_link_update(phy_info_t * phy_info[]);
extern void ipq_qca8084_switch_hw_reset(int gpio);

static int qca8084_swt_port = -1;
#endif /* CONFIG_QCA8084_SWT_MODE */

/*
 * EDMA hardware instance
 */
static u32 ipq6018_edma_hw_addr;

void ipq6018_edma_dump_data(uchar *data, int len)
{
	int i;

	if (data == NULL)
		return;

	pr_info("data address = 0x%x, len = %d \n", (unsigned int)data, len);

	for (i = 0; i < len; i++) {
		if ((i % 16) == 0)
			printf("\n");
		pr_info("%02x ", (unsigned int)data[i]);
	}

	pr_info("\n\n");
}

/*
 * ipq6018_edma_reg_read()
 *	Read EDMA register
 */
uint32_t ipq6018_edma_reg_read(uint32_t reg_off)
{
	return (uint32_t)readl(ipq6018_edma_hw_addr + reg_off);
}

/*
 * ipq6018_edma_reg_write()
 *	Write EDMA register
 */
void ipq6018_edma_reg_write(uint32_t reg_off, uint32_t val)
{
	pr_debug("%s: reg_off = %x, val =%x\n", __func__, reg_off, val);
	writel(val, (ipq6018_edma_hw_addr + reg_off));
}

/*
 * ipq6018_edma_alloc_rx_buffer()
 *	Alloc Rx buffers for one RxFill ring
 */
int ipq6018_edma_alloc_rx_buffer(struct ipq6018_edma_hw *ehw,
		struct ipq6018_edma_rxfill_ring *rxfill_ring)
{
	uint16_t num_alloc = 0;
	uint16_t cons, next, counter;
	struct ipq6018_edma_rxfill_desc *rxfill_desc;
	uint32_t reg_data;
	struct ipq6018_edma_rx_preheader *rxph;

	/*
	 * Read RXFILL ring producer index
	 */
	reg_data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_RXFILL_PROD_IDX(
					rxfill_ring->id));

	next = reg_data & IPQ6018_EDMA_RXFILL_PROD_IDX_MASK & (rxfill_ring->count - 1);

	/*
	 * Read RXFILL ring consumer index
	 */
	reg_data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_RXFILL_CONS_IDX(
					rxfill_ring->id));

	cons = reg_data & IPQ6018_EDMA_RXFILL_CONS_IDX_MASK;

	while (1) {

		counter = next;

		if (++counter == rxfill_ring->count)
			counter = 0;

		if (counter == cons)
			break;

		if (counter >= CONFIG_SYS_RX_ETH_BUFFER) {
			pr_info("%s: counter >= CONFIG_SYS_RX_ETH_BUFFER counter = %d\n",
				__func__, counter);
			break;
		}
		/*
		 * Get RXFILL descriptor
		 */
		rxfill_desc = IPQ6018_EDMA_RXFILL_DESC(rxfill_ring, next);

		/*
		 * Make room for Rx preheader
		 */
		rxph = (struct ipq6018_edma_rx_preheader *)rxfill_desc->buffer_addr;

		/*
		 * Fill the opaque value
		 */
		rxph->opaque = next;

		/*
		 * Save buffer size in RXFILL descriptor
		 */
		rxfill_desc->word1 = cpu_to_le32(IPQ6018_EDMA_RX_BUFF_SIZE &
					 IPQ6018_EDMA_RXFILL_BUF_SIZE_MASK);

		num_alloc++;
		next = counter;
	}

	if (num_alloc) {
		/*
		 * Update RXFILL ring producer index
		 */
		reg_data = next & IPQ6018_EDMA_RXFILL_PROD_IDX_MASK;

		/*
		 * make sure the producer index updated before
		 * updating the hardware
		 */
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_PROD_IDX(
					rxfill_ring->id), reg_data);

		pr_debug("%s: num_alloc = %d\n", __func__, num_alloc);
	}

	return num_alloc;
}

/*
 * ipq6018_edma_clean_tx()
 *	Reap Tx descriptors
 */
uint32_t ipq6018_edma_clean_tx(struct ipq6018_edma_hw *ehw,
			struct ipq6018_edma_txcmpl_ring *txcmpl_ring)
{
	struct ipq6018_edma_txcmpl_desc *txcmpl_desc;
	uint16_t prod_idx, cons_idx;
	uint32_t data;
	uint32_t txcmpl_consumed = 0;
	uchar *skb;

	/*
	 * Get TXCMPL ring producer index
	 */
	data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_TXCMPL_PROD_IDX(
					txcmpl_ring->id));
	prod_idx = data & IPQ6018_EDMA_TXCMPL_PROD_IDX_MASK;

	/*
	 * Get TXCMPL ring consumer index
	 */
	data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_TXCMPL_CONS_IDX(
					txcmpl_ring->id));
	cons_idx = data & IPQ6018_EDMA_TXCMPL_CONS_IDX_MASK;

	while (cons_idx != prod_idx) {

		txcmpl_desc = IPQ6018_EDMA_TXCMPL_DESC(txcmpl_ring, cons_idx);

		skb = (uchar *)txcmpl_desc->buffer_addr;

		if (unlikely(!skb)) {
			pr_debug("Invalid skb: cons_idx:%u prod_idx:%u status %x\n",
				cons_idx, prod_idx, txcmpl_desc->status);
		}

		if (++cons_idx == txcmpl_ring->count)
			cons_idx = 0;

		txcmpl_consumed++;
	}

	pr_debug("%s :%u txcmpl_consumed:%u prod_idx:%u cons_idx:%u\n",
		__func__, txcmpl_ring->id, txcmpl_consumed, prod_idx,
		cons_idx);

	if (txcmpl_consumed == 0)
		return 0;

	/*
	 * Update TXCMPL ring consumer index
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXCMPL_CONS_IDX(
				txcmpl_ring->id), cons_idx);

	return txcmpl_consumed;
}

/*
 * ipq6018_edma_clean_rx()
 *	Reap Rx descriptors
 */
uint32_t ipq6018_edma_clean_rx(struct ipq6018_edma_common_info *c_info,
				struct ipq6018_edma_rxdesc_ring *rxdesc_ring)
{
	void *skb;
	struct ipq6018_edma_rxdesc_desc *rxdesc_desc;
	struct ipq6018_edma_rx_preheader *rxph;
	uint16_t prod_idx, cons_idx;
	int src_port_num;
	int pkt_length;
	int rx = CONFIG_SYS_RX_ETH_BUFFER;
	u16 cleaned_count = 0;

	pr_debug("%s: rxdesc_ring->id = %d\n", __func__, rxdesc_ring->id);
	/*
	 * Read Rx ring consumer index
	 */
	cons_idx = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_RXDESC_CONS_IDX(
					rxdesc_ring->id)) &
					IPQ6018_EDMA_RXDESC_CONS_IDX_MASK;

	while (rx) {
		/*
		 * Read Rx ring producer index
		 */
		prod_idx = ipq6018_edma_reg_read(
			IPQ6018_EDMA_REG_RXDESC_PROD_IDX(rxdesc_ring->id))
			& IPQ6018_EDMA_RXDESC_PROD_IDX_MASK;

		if (cons_idx == prod_idx) {
			pr_debug("%s: cons = prod \n", __func__);
			break;
		}

		rxdesc_desc = IPQ6018_EDMA_RXDESC_DESC(rxdesc_ring, cons_idx);

		skb = (void *)rxdesc_desc->buffer_addr;

		/*
		 * Get Rx preheader
		 */
		rxph = (struct ipq6018_edma_rx_preheader *)skb;

		rx--;

		/*
		 * Check src_info from Rx preheader
		 */
		if (IPQ6018_EDMA_RXPH_SRC_INFO_TYPE_GET(rxph) ==
				IPQ6018_EDMA_PREHDR_DSTINFO_PORTID_IND) {
			src_port_num = rxph->src_info &
				IPQ6018_EDMA_PREHDR_PORTNUM_BITS;
		} else {
			pr_warn("WARN: src_info_type:0x%x. Drop skb:%p\n",
				IPQ6018_EDMA_RXPH_SRC_INFO_TYPE_GET(rxph),
				skb);
			goto next_rx_desc;
		}

		/*
		 * Get packet length
		 */
		pkt_length = rxdesc_desc->status &
				 IPQ6018_EDMA_RXDESC_PACKET_LEN_MASK;

		if (unlikely((src_port_num < IPQ6018_NSS_DP_START_PHY_PORT)  ||
			(src_port_num > IPQ6018_NSS_DP_MAX_PHY_PORTS))) {
			pr_warn("WARN: Port number error :%d. Drop skb:%p\n",
					src_port_num, skb);
			goto next_rx_desc;
		}

		cleaned_count++;

		/*
		 * Remove Rx preheader
		 */
		skb = skb + IPQ6018_EDMA_RX_PREHDR_SIZE;

		pr_debug("%s: received pkt %p with length %d\n",
			__func__, skb, pkt_length);

		net_process_received_packet(skb, pkt_length);
next_rx_desc:
		/*
		 * Update consumer index
		 */
		if (++cons_idx == rxdesc_ring->count)
			cons_idx = 0;
	}

	if (cleaned_count) {
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_CONS_IDX(
						rxdesc_ring->id), cons_idx);
	}

	return 0;
}

/*
 * ip6018_edma_rx_complete()
 */
static int ipq6018_edma_rx_complete(struct ipq6018_edma_common_info *c_info)
{
	struct ipq6018_edma_hw *ehw = &c_info->hw;
	struct ipq6018_edma_txcmpl_ring *txcmpl_ring;
	struct ipq6018_edma_rxdesc_ring *rxdesc_ring;
	struct ipq6018_edma_rxfill_ring *rxfill_ring;
	uint32_t misc_intr_status, reg_data;
	int i;

	for (i = 0; i < ehw->rxdesc_rings; i++) {
		rxdesc_ring = &ehw->rxdesc_ring[i];
		ipq6018_edma_clean_rx(c_info, rxdesc_ring);
	}

	for (i = 0; i < ehw->txcmpl_rings; i++) {
		txcmpl_ring = &ehw->txcmpl_ring[i];
		ipq6018_edma_clean_tx(ehw, txcmpl_ring);
	}

	for (i = 0; i < ehw->rxfill_rings; i++) {
		rxfill_ring = &ehw->rxfill_ring[i];
		ipq6018_edma_alloc_rx_buffer(ehw, rxfill_ring);
	}

	/*
	 * Set RXDESC ring interrupt mask
	 */
	for (i = 0; i < ehw->rxdesc_rings; i++) {
		rxdesc_ring = &ehw->rxdesc_ring[i];
		ipq6018_edma_reg_write(
			IPQ6018_EDMA_REG_RXDESC_INT_MASK(rxdesc_ring->id),
			ehw->rxdesc_intr_mask);
	}

	/*
	 * Set TXCMPL ring interrupt mask
	 */
	for (i = 0; i < ehw->txcmpl_rings; i++) {
		txcmpl_ring = &ehw->txcmpl_ring[i];
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TX_INT_MASK(
					txcmpl_ring->id),
					ehw->txcmpl_intr_mask);
	}

	/*
	 * Set RXFILL ring interrupt mask
	 */
	for (i = 0; i < ehw->rxfill_rings; i++) {
		rxfill_ring = &ehw->rxfill_ring[i];
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_INT_MASK(
					rxfill_ring->id),
					ehw->rxfill_intr_mask);
	}

	/*
	 * Read Misc intr status
	 */
	reg_data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_MISC_INT_STAT);
	misc_intr_status = reg_data & ehw->misc_intr_mask;

	if (misc_intr_status != 0) {
		pr_info("%s: misc_intr_status = 0x%x\n", __func__,
			misc_intr_status);
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_MISC_INT_MASK,
					IPQ6018_EDMA_MASK_INT_DISABLE);
	}

	return 0;
}

/*
 * ipq6018_eth_snd()
 *	Transmit a packet using an EDMA ring
 */
static int ipq6018_eth_snd(struct eth_device *dev, void *packet, int length)
{
	struct ipq6018_eth_dev *priv = dev->priv;
	struct ipq6018_edma_common_info *c_info = priv->c_info;
	struct ipq6018_edma_hw *ehw = &c_info->hw;
	struct ipq6018_edma_txdesc_desc *txdesc;
	struct ipq6018_edma_tx_preheader *txph;
	struct ipq6018_edma_txdesc_ring *txdesc_ring;
	uint16_t hw_next_to_use, hw_next_to_clean, chk_idx;
	uint32_t data;
	uchar *skb;

	txdesc_ring = ehw->txdesc_ring;

	if (tftp_acl_our_port != tftp_our_port) {
		/* Allowing tftp packets */
		ipq6018_ppe_acl_set(3, 0x4, 0x1, tftp_our_port, 0xffff, 0, 0);
		tftp_acl_our_port = tftp_our_port;
	}
	/*
	 * Read TXDESC ring producer index
	 */
	data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_TXDESC_PROD_IDX(
					txdesc_ring->id));

	hw_next_to_use = data & IPQ6018_EDMA_TXDESC_PROD_IDX_MASK;

	pr_debug("%s: txdesc_ring->id = %d\n", __func__, txdesc_ring->id);

	/*
	 * Read TXDESC ring consumer index
	 */
	/*
	 * TODO - read to local variable to optimize uncached access
	 */
	data = ipq6018_edma_reg_read(
			IPQ6018_EDMA_REG_TXDESC_CONS_IDX(txdesc_ring->id));

	hw_next_to_clean = data & IPQ6018_EDMA_TXDESC_CONS_IDX_MASK;

	/*
	 * Check for available Tx descriptor
	 */
	chk_idx = (hw_next_to_use + 1) & (txdesc_ring->count-1);

	if (chk_idx == hw_next_to_clean) {
		return NETDEV_TX_BUSY;
	}

	/*
	 * Get Tx descriptor
	 */
	txdesc = IPQ6018_EDMA_TXDESC_DESC(txdesc_ring, hw_next_to_use);

	txdesc->word1 = 0;

	skb = (uchar *)txdesc->buffer_addr;

	pr_debug("%s: txdesc->buffer_addr = 0x%x length = %d \
			prod_idx = %d cons_idx = %d\n",
			__func__, txdesc->buffer_addr, length,
			hw_next_to_use, hw_next_to_clean);

	/*
	 * Make room for Tx preheader
	 */
	txph = (struct ipq6018_edma_tx_preheader *)skb;

	memset((void *)txph, 0, IPQ6018_EDMA_TX_PREHDR_SIZE);

#ifdef CONFIG_IPQ6018_BRIDGED_MODE
	/* VP 0x0 share vsi 2 with port 1-4 */
	txph->src_info = 0x2000;
	txph->dst_info = 0x0;
#else
	/*
	 * Populate Tx preheader dst info, port id is macid in dp_dev
	 */

	txph->dst_info = (IPQ6018_EDMA_PREHDR_DSTINFO_PORTID_IND << 8) |
			(IPQ6018_EDMA_MAC_PORT_NO & 0x0fff);

#endif

	/*
	 * Set opaque field in preheader
	 */
	txph->opaque = cpu_to_le32(skb);

	/*
	 * copy the packet
	 */
	memcpy(skb + IPQ6018_EDMA_TX_PREHDR_SIZE, packet, length);

	/*
	 * Populate Tx descriptor
	 */
	txdesc->word1 |= (1 << IPQ6018_EDMA_TXDESC_PREHEADER_SHIFT)
			| ((IPQ6018_EDMA_TX_PREHDR_SIZE &
			IPQ6018_EDMA_TXDESC_DATA_OFFSET_MASK)
			   << IPQ6018_EDMA_TXDESC_DATA_OFFSET_SHIFT);
	txdesc->word1 |= ((length & IPQ6018_EDMA_TXDESC_DATA_LENGTH_MASK)
			<< IPQ6018_EDMA_TXDESC_DATA_LENGTH_SHIFT);

	/*
	 * Update producer index
	 */
	hw_next_to_use = (hw_next_to_use + 1) & (txdesc_ring->count - 1);

	/*
	 * make sure the hw_next_to_use is updated before the
	 * write to hardware
	 */

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXDESC_PROD_IDX(
				txdesc_ring->id), hw_next_to_use &
				 IPQ6018_EDMA_TXDESC_PROD_IDX_MASK);

	pr_debug("%s: successfull\n", __func__);

	return EDMA_TX_OK;
}

static int ipq6018_eth_recv(struct eth_device *dev)
{
	struct ipq6018_eth_dev *priv = dev->priv;
	struct ipq6018_edma_common_info *c_info = priv->c_info;
	struct ipq6018_edma_rxdesc_ring *rxdesc_ring;
	struct ipq6018_edma_txcmpl_ring *txcmpl_ring;
	struct ipq6018_edma_rxfill_ring *rxfill_ring;
	struct ipq6018_edma_hw *ehw = &c_info->hw;
	volatile u32 reg_data;
	u32 rxdesc_intr_status = 0, txcmpl_intr_status = 0, rxfill_intr_status = 0;
	int i;

	/*
	 * Read RxDesc intr status
	 */
	for (i = 0; i < ehw->rxdesc_rings; i++) {
		rxdesc_ring = &ehw->rxdesc_ring[i];

		reg_data = ipq6018_edma_reg_read(
				IPQ6018_EDMA_REG_RXDESC_INT_STAT(
					rxdesc_ring->id));
		rxdesc_intr_status |= reg_data &
				IPQ6018_EDMA_RXDESC_RING_INT_STATUS_MASK;

		/*
		 * Disable RxDesc intr
		 */
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_INT_MASK(
					rxdesc_ring->id),
					IPQ6018_EDMA_MASK_INT_DISABLE);
	}

	/*
	 * Read TxCmpl intr status
	 */
	for (i = 0; i < ehw->txcmpl_rings; i++) {
		txcmpl_ring = &ehw->txcmpl_ring[i];

		reg_data = ipq6018_edma_reg_read(
				IPQ6018_EDMA_REG_TX_INT_STAT(
					txcmpl_ring->id));
		txcmpl_intr_status |= reg_data &
				IPQ6018_EDMA_TXCMPL_RING_INT_STATUS_MASK;

		/*
		 * Disable TxCmpl intr
		 */
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TX_INT_MASK(
					txcmpl_ring->id),
					IPQ6018_EDMA_MASK_INT_DISABLE);
	}

	/*
	 * Read RxFill intr status
	 */
	for (i = 0; i < ehw->rxfill_rings; i++) {
		rxfill_ring = &ehw->rxfill_ring[i];

		reg_data = ipq6018_edma_reg_read(
				IPQ6018_EDMA_REG_RXFILL_INT_STAT(
					rxfill_ring->id));
		rxfill_intr_status |= reg_data &
				IPQ6018_EDMA_RXFILL_RING_INT_STATUS_MASK;

		/*
		 * Disable RxFill intr
		 */
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_INT_MASK(
					rxfill_ring->id),
					IPQ6018_EDMA_MASK_INT_DISABLE);
	}

	if ((rxdesc_intr_status != 0) || (txcmpl_intr_status != 0) ||
	    (rxfill_intr_status != 0)) {
		for (i = 0; i < ehw->rxdesc_rings; i++) {
			rxdesc_ring = &ehw->rxdesc_ring[i];
			ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_INT_MASK(
						rxdesc_ring->id),
						IPQ6018_EDMA_MASK_INT_DISABLE);
		}
		ipq6018_edma_rx_complete(c_info);
	}

	return 0;
}

/*
 * ipq6018_edma_setup_ring_resources()
 *	Allocate/setup resources for EDMA rings
 */
static int ipq6018_edma_setup_ring_resources(struct ipq6018_edma_hw *ehw)
{
	struct ipq6018_edma_txcmpl_ring *txcmpl_ring;
	struct ipq6018_edma_txdesc_ring *txdesc_ring;
	struct ipq6018_edma_rxfill_ring *rxfill_ring;
	struct ipq6018_edma_rxdesc_ring *rxdesc_ring;
	struct ipq6018_edma_txdesc_desc *tx_desc;
	struct ipq6018_edma_rxfill_desc *rxfill_desc;
	int i, j, index;
	void *tx_buf;
	void *rx_buf;

	/*
	 * Allocate Rx fill ring descriptors
	 */
	for (i = 0; i < ehw->rxfill_rings; i++) {
		rxfill_ring = &ehw->rxfill_ring[i];
		rxfill_ring->count = IPQ6018_EDMA_RXFILL_RING_SIZE;
		rxfill_ring->id = ehw->rxfill_ring_start + i;
		rxfill_ring->desc = (void *)noncached_alloc(
				sizeof(struct ipq6018_edma_rxfill_desc) *
				rxfill_ring->count,
				CONFIG_SYS_CACHELINE_SIZE);

		if (rxfill_ring->desc == NULL) {
			pr_info("%s: rxfill_ring->desc alloc error\n", __func__);
			return -ENOMEM;
		}
		rxfill_ring->dma = virt_to_phys(rxfill_ring->desc);
		rx_buf = (void *)noncached_alloc(PKTSIZE_ALIGN *
					rxfill_ring->count,
					CONFIG_SYS_CACHELINE_SIZE);

		if (rx_buf == NULL) {
			pr_info("%s: rxfill_ring->desc buffer alloc error\n",
				 __func__);
			return -ENOMEM;
		}

		for (j = 0; j < rxfill_ring->count; j++) {
			rxfill_desc = IPQ6018_EDMA_RXFILL_DESC(rxfill_ring, j);
			rxfill_desc->buffer_addr = virt_to_phys(rx_buf);
			rx_buf += PKTSIZE_ALIGN;
		}
	}

	/*
	 * Allocate RxDesc ring descriptors
	 */
	for (i = 0; i < ehw->rxdesc_rings; i++) {
		rxdesc_ring = &ehw->rxdesc_ring[i];
		rxdesc_ring->count = IPQ6018_EDMA_RXDESC_RING_SIZE;
		rxdesc_ring->id = ehw->rxdesc_ring_start + i;

		/*
		 * Create a mapping between RX Desc ring and Rx fill ring.
		 * Number of fill rings are lesser than the descriptor rings
		 * Share the fill rings across descriptor rings.
		 */

		index = ehw->rxfill_ring_start + (i % ehw->rxfill_rings);
		rxdesc_ring->rxfill =
			&ehw->rxfill_ring[index - ehw->rxfill_ring_start];
		rxdesc_ring->rxfill = ehw->rxfill_ring;

		rxdesc_ring->desc = (void *)noncached_alloc(
				sizeof(struct ipq6018_edma_rxdesc_desc) *
				rxdesc_ring->count,
				CONFIG_SYS_CACHELINE_SIZE);

		if (rxdesc_ring->desc == NULL) {
			pr_info("%s: rxdesc_ring->desc alloc error\n", __func__);
			return -ENOMEM;
		}
		rxdesc_ring->dma = virt_to_phys(rxdesc_ring->desc);
	}

	/*
	 * Allocate TxCmpl ring descriptors
	 */
	for (i = 0; i < ehw->txcmpl_rings; i++) {
		txcmpl_ring = &ehw->txcmpl_ring[i];
		txcmpl_ring->count = IPQ6018_EDMA_TXCMPL_RING_SIZE;
		txcmpl_ring->id = ehw->txcmpl_ring_start + i;
		txcmpl_ring->desc = (void *)noncached_alloc(
				sizeof(struct ipq6018_edma_txcmpl_desc) *
				txcmpl_ring->count,
				CONFIG_SYS_CACHELINE_SIZE);

		if (txcmpl_ring->desc == NULL) {
			pr_info("%s: txcmpl_ring->desc alloc error\n", __func__);
			return -ENOMEM;
		}
		txcmpl_ring->dma = virt_to_phys(txcmpl_ring->desc);
	}


	/*
	 * Allocate TxDesc ring descriptors
	 */
	for (i = 0; i < ehw->txdesc_rings; i++) {
		txdesc_ring = &ehw->txdesc_ring[i];
		txdesc_ring->count = IPQ6018_EDMA_TXDESC_RING_SIZE;
		txdesc_ring->id = ehw->txdesc_ring_start + i;
		txdesc_ring->desc = (void *)noncached_alloc(
					sizeof(struct ipq6018_edma_txdesc_desc) *
					txdesc_ring->count,
					CONFIG_SYS_CACHELINE_SIZE);

		if (txdesc_ring->desc == NULL) {
			pr_info("%s: txdesc_ring->desc alloc error\n", __func__);
			return -ENOMEM;
		}

		txdesc_ring->dma = virt_to_phys(txdesc_ring->desc);
		tx_buf = (void *)noncached_alloc(IPQ6018_EDMA_TX_BUF_SIZE *
					txdesc_ring->count,
					CONFIG_SYS_CACHELINE_SIZE);

		if (tx_buf == NULL) {
			pr_info("%s: txdesc_ring->desc buffer alloc error\n",
				 __func__);
			return -ENOMEM;
		}

		for (j = 0; j < txdesc_ring->count; j++) {
			tx_desc = IPQ6018_EDMA_TXDESC_DESC(txdesc_ring, j);
			tx_desc->buffer_addr = virt_to_phys(tx_buf);
			tx_buf += IPQ6018_EDMA_TX_BUF_SIZE;
		}
	}

	pr_info("%s: successfull\n", __func__);

	return 0;

}

/*
 * ipq6018_edma_free_desc()
 *	Free EDMA desc memory
 */
static void ipq6018_edma_free_desc(struct ipq6018_edma_common_info *c_info)
{
	struct ipq6018_edma_hw *ehw = &c_info->hw;
	struct ipq6018_edma_txcmpl_ring *txcmpl_ring;
	struct ipq6018_edma_txdesc_ring *txdesc_ring;
	struct ipq6018_edma_rxfill_ring *rxfill_ring;
	struct ipq6018_edma_rxdesc_ring *rxdesc_ring;
	struct ipq6018_edma_txdesc_desc *tx_desc;
	int i;

	for (i = 0; i < ehw->rxfill_rings; i++) {
		rxfill_ring = &ehw->rxfill_ring[i];
		if (rxfill_ring->desc)
			ipq6018_free_mem(rxfill_ring->desc);
	}

	for (i = 0; i < ehw->rxdesc_rings; i++) {
		rxdesc_ring = &ehw->rxdesc_ring[i];
		if (rxdesc_ring->desc)
			ipq6018_free_mem(rxdesc_ring->desc);
	}

	for (i = 0; i < ehw->txcmpl_rings; i++) {
		txcmpl_ring = &ehw->txcmpl_ring[i];
		if (txcmpl_ring->desc) {
			ipq6018_free_mem(txcmpl_ring->desc);
		}
	}

	for (i = 0; i < ehw->txdesc_rings; i++) {
		txdesc_ring = &ehw->txdesc_ring[i];
		if (txdesc_ring->desc) {
			tx_desc = IPQ6018_EDMA_TXDESC_DESC(txdesc_ring, 0);
			if (tx_desc->buffer_addr)
				ipq6018_free_mem((void *)tx_desc->buffer_addr);
			ipq6018_free_mem(txdesc_ring->desc);
		}
	}
}

/*
 * ipq6018_edma_free_rings()
 *	Free EDMA software rings
 */
static void ipq6018_edma_free_rings(struct ipq6018_edma_common_info *c_info)
{
	struct ipq6018_edma_hw *ehw = &c_info->hw;
	ipq6018_free_mem(ehw->rxfill_ring);
	ipq6018_free_mem(ehw->rxdesc_ring);
	ipq6018_free_mem(ehw->txdesc_ring);
	ipq6018_free_mem(ehw->txcmpl_ring);
}

static void ipq6018_edma_disable_rings(struct ipq6018_edma_hw *edma_hw)
{
	int i, desc_index;
	u32 data;

	/*
	 * Disable Rx rings
	 */
	for (i = 0; i < IPQ6018_EDMA_MAX_RXDESC_RINGS; i++) {
		data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_RXDESC_CTRL(i));
		data &= ~IPQ6018_EDMA_RXDESC_RX_EN;
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_CTRL(i), data);
	}

	/*
	 * Disable RxFill Rings
	 */
	for (i = 0; i < IPQ6018_EDMA_MAX_RXFILL_RINGS; i++) {
		data = ipq6018_edma_reg_read(
				IPQ6018_EDMA_REG_RXFILL_RING_EN(i));
		data &= ~IPQ6018_EDMA_RXFILL_RING_EN;
		ipq6018_edma_reg_write(
				IPQ6018_EDMA_REG_RXFILL_RING_EN(i), data);
	}

	/*
	 * Disable Tx rings
	 */
	for (desc_index = 0; desc_index <
			 IPQ6018_EDMA_MAX_TXDESC_RINGS; desc_index++) {
		data = ipq6018_edma_reg_read(
				IPQ6018_EDMA_REG_TXDESC_CTRL(desc_index));
		data &= ~IPQ6018_EDMA_TXDESC_TX_EN;
		ipq6018_edma_reg_write(
				IPQ6018_EDMA_REG_TXDESC_CTRL(desc_index), data);
	}
}

static void ipq6018_edma_disable_intr(struct ipq6018_edma_hw *ehw)
{
	int i;

	/*
	 * Disable interrupts
	 */
	for (i = 0; i < IPQ6018_EDMA_MAX_TXCMPL_RINGS; i++)
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TX_INT_MASK(i), 0);

	for (i = 0; i < IPQ6018_EDMA_MAX_RXFILL_RINGS; i++)
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_INT_MASK(i), 0);

	for (i = 0; i < IPQ6018_EDMA_MAX_RXDESC_RINGS; i++)
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RX_INT_CTRL(i), 0);

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_MISC_INT_MASK,
				IPQ6018_EDMA_MASK_INT_DISABLE);
}

static void set_sgmii_mode(int port_id, int sg_mode)
{
	if (port_id == 3)
		sgmii_mode[0] = sg_mode;
	else if (port_id == 4)
		sgmii_mode[1] = sg_mode;
}

static int get_sgmii_mode(int port_id)
{
	if (port_id == 3)
		return sgmii_mode[0];
	else if (port_id == 4)
		return sgmii_mode[1];
	else
		return -1;
}

static int ipq6018_eth_init(struct eth_device *eth_dev, bd_t *this)
{
	struct ipq6018_eth_dev *priv = eth_dev->priv;
	int i;
	u8 status;
	struct phy_ops *phy_get_ops;
	static fal_port_speed_t old_speed[IPQ6018_PHY_MAX] = {[0 ... IPQ6018_PHY_MAX-1] = FAL_SPEED_BUTT};
	static fal_port_speed_t curr_speed[IPQ6018_PHY_MAX];
	static int current_active_port = -1, previous_active_port = -1;
	fal_port_duplex_t duplex;
	char *lstatus[] = {"up", "Down"};
	char *dp[] = {"Half", "Full"};
	int linkup=0;
	int mac_speed = 0, speed_clock1 = 0, speed_clock2 = 0;
	int phy_addr, port_8033 = -1, node, aquantia_port = -1;
	int sfp_port = -1;
	int phy_node = -1;
	int ret_sgmii_mode;
	int sfp_mode, sgmii_fiber = -1;
	char *active_port = NULL;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0)
		port_8033 = fdtdec_get_uint(gd->fdt_blob, node, "8033_port", -1);

	if (node >= 0)
		aquantia_port = fdtdec_get_uint(gd->fdt_blob, node, "aquantia_port", -1);

	if (node >= 0)
		 sfp_port = fdtdec_get_uint(gd->fdt_blob, node, "sfp_port", -1);

	phy_node = fdt_path_offset(gd->fdt_blob, "/ess-switch/port_phyinfo");

	active_port = getenv("active_port");
	if (active_port != NULL) {
		current_active_port = simple_strtol(active_port, NULL, 10);
		if (current_active_port < 0 || current_active_port > 4)
			printf("active_port must be in the range of 0 to 4 in ipq6018 platform\n");
	} else {
		current_active_port = -1;
	}

	if (previous_active_port != current_active_port && current_active_port != -1) {
		previous_active_port = current_active_port;
		printf("Port%d has been set as the active_port\n", current_active_port);
	}

	/*
	 * Check PHY link, speed, Duplex on all phys.
	 * we will proceed even if single link is up
	 * else we will return with -1;
	 */
	for (i =  0; i < IPQ6018_PHY_MAX; i++) {
		if (current_active_port != -1 && i != current_active_port) {
			ipq6018_gmac_port_disable(i);
			ppe_port_bridge_txmac_set(i + 1, 1);
			old_speed[i] = FAL_SPEED_BUTT;
			/*
			 * Old speed has been set as FAL_SPEED_BUTT here so that
			 * if again the previous active_port is made as active,
			 * the configurations required will be done again and MAC
			 * would be enabled.
			 *
			 * Note that only for the active port TX/RX MAC would be
			 * enabled and for all other ports, the same would be
			 * disabled.
			 */
			continue;
		}

		if(phy_info[i]->phy_type == UNUSED_PHY_TYPE)
			continue;

		if (i == sfp_port) {
			status = phy_status_get_from_ppe(i);
			duplex = FAL_FULL_DUPLEX;
			sfp_mode = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode1", -1);
			if (sfp_mode < 0) {
				printf("\nError: switch_mac_mode1 not specified in dts");
				return sfp_mode;
			}
			if (sfp_mode == PORT_WRAPPER_SGMII_FIBER) {
				sgmii_fiber = 1;
				curr_speed[i] = FAL_SPEED_1000;
			} else if (sfp_mode == PORT_WRAPPER_10GBASE_R) {
				sgmii_fiber = 0;
				curr_speed[i] = FAL_SPEED_10000;
			} else {

				printf("\nError: wrong mode specified for SFP Port");
				return sfp_mode;
			}
#ifdef CONFIG_QCA8084_SWT_MODE
		} else if ((qca8084_swt_port == i)&& (phy_info[i]->phy_type == QCA8084_PHY_TYPE)) {
			if (!ipq_qca8084_link_update(swt_info))
				linkup++;
			continue;
#endif /* CONFIG_QCA8084_SWT_MODE */
		} else {
			if (!priv->ops[i]) {
				printf ("Phy ops not mapped\n");
				continue;
			}
			phy_get_ops = priv->ops[i];

			if (!phy_get_ops->phy_get_link_status ||
					!phy_get_ops->phy_get_speed ||
					!phy_get_ops->phy_get_duplex) {
				printf ("Link status/Get speed/Get duplex not mapped\n");
				return -1;
			}

			if (phy_node >= 0) {
				phy_addr = phy_info[i]->phy_address;
			} else {

				if (i == port_8033)
					phy_addr = QCA8033_PHY_ADDR;
				else if (i == aquantia_port)
					phy_addr = AQU_PHY_ADDR;
				else
					phy_addr = i;
			}
			status = phy_get_ops->phy_get_link_status(priv->mac_unit, phy_addr);
			phy_get_ops->phy_get_speed(priv->mac_unit, phy_addr, &curr_speed[i]);
			phy_get_ops->phy_get_duplex(priv->mac_unit, phy_addr, &duplex);
		}

		if (status == 0) {
			linkup++;
			if (old_speed[i] == curr_speed[i]) {
				printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
					priv->mac_unit, i, lstatus[status], curr_speed[i],
					dp[duplex]);
				continue;
			} else {
				old_speed[i] = curr_speed[i];
			}
		} else {
			printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
				priv->mac_unit, i, lstatus[status], curr_speed[i],
				dp[duplex]);
			continue;
		}

		switch (curr_speed[i]) {
			case FAL_SPEED_10:
				mac_speed = 0x0;
				if (i == aquantia_port) {
					printf("10M speed not supported\n");
					ppe_port_bridge_txmac_set(i + 1, status);
					continue;
				}
				speed_clock1 = 0x109;
				speed_clock2 = 0x9;
				printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
						priv->mac_unit, i, lstatus[status], curr_speed[i],
						dp[duplex]);
				if (phy_node >= 0) {
					if (phy_info[i]->phy_type == QCA8081_PHY_TYPE) {
						set_sgmii_mode(i, 1);
						if (i == 4)
							speed_clock1 = 0x309;
					}
				}
				break;
			case FAL_SPEED_100:
				mac_speed = 0x1;
				if (i == aquantia_port) {
					speed_clock1 = 0x309;
					speed_clock2 = 0x4;
				} else {
					speed_clock1 = 0x109;
					speed_clock2 = 0x0;
				}
				printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
						priv->mac_unit, i, lstatus[status], curr_speed[i],
						dp[duplex]);
				if (phy_node >= 0) {
					if (phy_info[i]->phy_type == QCA8081_PHY_TYPE) {
						set_sgmii_mode(i, 1);
						if (i == 4)
							speed_clock1 = 0x309;
					}
				}
				break;
			case FAL_SPEED_1000:
				mac_speed = 0x2;
				if (i == aquantia_port)
					speed_clock1 = 0x304;
				else if (i == sfp_port)
					speed_clock1 = 0x301;
				else
					speed_clock1 = 0x101;
				speed_clock2 = 0x0;
				printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
						priv->mac_unit, i, lstatus[status], curr_speed[i],
						dp[duplex]);
				if (phy_node >= 0) {
					if (phy_info[i]->phy_type == QCA8081_PHY_TYPE) {
						set_sgmii_mode(i, 1);
						if (i == 4)
							speed_clock1 = 0x301;
					}
				}
				break;
			case FAL_SPEED_2500:
				if (i == aquantia_port) {
					mac_speed = 0x4;
					speed_clock1 = 0x307;
					speed_clock2 = 0x0;
				}
				if (phy_node >= 0) {
					if (phy_info[i]->phy_type == QCA8081_PHY_TYPE) {
						mac_speed = 0x2;
						set_sgmii_mode(i, 0);
						if (i == 4)
							speed_clock1 = 0x301;
						else if  (i == 3)
							speed_clock1 = 0x101;
						speed_clock2 = 0x0;
					}
				}
				printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
						priv->mac_unit, i, lstatus[status], curr_speed[i],
						dp[duplex]);
				break;
			case FAL_SPEED_5000:
				mac_speed = 0x5;
				speed_clock1 = 0x303;
				speed_clock2 = 0x0;
				printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
						priv->mac_unit, i, lstatus[status], curr_speed[i],
						dp[duplex]);
				break;
			case FAL_SPEED_10000:
				mac_speed = 0x3;
				speed_clock1 = 0x301;
				speed_clock2 = 0x0;
				printf ("eth%d PHY%d %s Speed :%d %s duplex\n",
						priv->mac_unit, i, lstatus[status], curr_speed[i],
						dp[duplex]);
				break;
			default:
				printf("Unknown speed\n");
				break;
		}

		if (phy_node >= 0) {
			if (phy_info[i]->phy_type == QCA8081_PHY_TYPE) {
				ret_sgmii_mode = get_sgmii_mode(i);
				ppe_port_bridge_txmac_set(i + 1, 1);
				if (ret_sgmii_mode == 1) {
					if (i == 4)
						ppe_uniphy_mode_set(0x1, PORT_WRAPPER_SGMII0_RGMII4);
					else if (i == 3)
						ppe_uniphy_mode_set(0x0, PORT_WRAPPER_SGMII0_RGMII4);

				} else if (ret_sgmii_mode == 0) {
					if (i == 4)
						ppe_uniphy_mode_set(0x1, PORT_WRAPPER_SGMII_PLUS);
					else if (i == 3)
						ppe_uniphy_mode_set(0x0, PORT_WRAPPER_SGMII_PLUS);
				}
			}
		}

		if (i == sfp_port) {
			if (sgmii_fiber) {
				ppe_port_bridge_txmac_set(i + 1, 1);
				ppe_uniphy_mode_set(0x1, PORT_WRAPPER_SGMII_FIBER);
				ppe_port_mux_mac_type_set(i + 1, PORT_WRAPPER_SGMII_FIBER);
			} else {
				ppe_uniphy_mode_set(0x1, PORT_WRAPPER_10GBASE_R);
				ppe_port_mux_mac_type_set(i + 1, PORT_WRAPPER_10GBASE_R);
			}
		}

		ipq6018_speed_clock_set(i, speed_clock1, speed_clock2);

		ipq6018_port_mac_clock_reset(i);

		if (i == aquantia_port)
			ipq6018_uxsgmii_speed_set(i, mac_speed, duplex, status);
		else if (i == sfp_port && sgmii_fiber == 0)
			ipq6018_10g_r_speed_set(i, status);
		else
			ipq6018_pqsgmii_speed_set(i, mac_speed, status);
	}

	if (linkup <= 0) {
		/* No PHY link is alive */
		return -1;
	}

	pr_info("%s: done\n", __func__);

	return 0;
}

static int ipq6018_edma_wr_macaddr(struct eth_device *dev)
{
	return 0;
}

static void ipq6018_eth_halt(struct eth_device *dev)
{
	pr_info("%s: done\n", __func__);
}

static void ipq6018_edma_set_ring_values(struct ipq6018_edma_hw *edma_hw)
{
	edma_hw->txdesc_ring_start = IPQ6018_EDMA_TX_DESC_RING_START;
	edma_hw->txdesc_rings = IPQ6018_EDMA_TX_DESC_RING_NOS;
	edma_hw->txdesc_ring_end = IPQ6018_EDMA_TX_DESC_RING_SIZE;

	edma_hw->txcmpl_ring_start = IPQ6018_EDMA_TX_CMPL_RING_START;
	edma_hw->txcmpl_rings = IPQ6018_EDMA_RX_FILL_RING_NOS;
	edma_hw->txcmpl_ring_end = IPQ6018_EDMA_TX_CMPL_RING_SIZE;

	edma_hw->rxfill_ring_start = IPQ6018_EDMA_RX_FILL_RING_START;
	edma_hw->rxfill_rings = IPQ6018_EDMA_RX_FILL_RING_NOS;
	edma_hw->rxfill_ring_end = IPQ6018_EDMA_RX_FILL_RING_SIZE;

	edma_hw->rxdesc_ring_start = IPQ6018_EDMA_RX_DESC_RING_START;
	edma_hw->rxdesc_rings = IPQ6018_EDMA_RX_DESC_RING_NOS;
	edma_hw->rxdesc_ring_end = IPQ6018_EDMA_RX_DESC_RING_SIZE;

	pr_info("Num rings - TxDesc:%u (%u-%u) TxCmpl:%u (%u-%u)\n",
		edma_hw->txdesc_rings, edma_hw->txdesc_ring_start,
		(edma_hw->txdesc_ring_start + edma_hw->txdesc_rings - 1),
		edma_hw->txcmpl_rings, edma_hw->txcmpl_ring_start,
		(edma_hw->txcmpl_ring_start + edma_hw->txcmpl_rings - 1));

	pr_info("RxDesc:%u (%u-%u) RxFill:%u (%u-%u)\n",
		edma_hw->rxdesc_rings, edma_hw->rxdesc_ring_start,
		(edma_hw->rxdesc_ring_start + edma_hw->rxdesc_rings - 1),
		edma_hw->rxfill_rings, edma_hw->rxfill_ring_start,
		(edma_hw->rxfill_ring_start + edma_hw->rxfill_rings - 1));
}

/*
 * ipq6018_edma_alloc_rings()
 *	Allocate EDMA software rings
 */
static int ipq6018_edma_alloc_rings(struct ipq6018_edma_hw *ehw)
{
	ehw->rxfill_ring = (void *)noncached_alloc((sizeof(
				struct ipq6018_edma_rxfill_ring) *
				ehw->rxfill_rings),
				CONFIG_SYS_CACHELINE_SIZE);

	if (!ehw->rxfill_ring) {
		pr_info("%s: rxfill_ring alloc error\n", __func__);
		return -ENOMEM;
	}

	ehw->rxdesc_ring = (void *)noncached_alloc((sizeof(
				struct ipq6018_edma_rxdesc_ring) *
				ehw->rxdesc_rings),
				CONFIG_SYS_CACHELINE_SIZE);

	if (!ehw->rxdesc_ring) {
		pr_info("%s: rxdesc_ring alloc error\n", __func__);
		return -ENOMEM;
	}

	ehw->txdesc_ring = (void *)noncached_alloc((sizeof(
				struct ipq6018_edma_txdesc_ring) *
				ehw->txdesc_rings),
				CONFIG_SYS_CACHELINE_SIZE);
	if (!ehw->txdesc_ring) {
		pr_info("%s: txdesc_ring alloc error\n", __func__);
		return -ENOMEM;
	}

	ehw->txcmpl_ring = (void *)noncached_alloc((sizeof(
				struct ipq6018_edma_txcmpl_ring) *
				ehw->txcmpl_rings),
				CONFIG_SYS_CACHELINE_SIZE);

	if (!ehw->txcmpl_ring) {
		pr_info("%s: txcmpl_ring alloc error\n", __func__);
		return -ENOMEM;
	}

	pr_info("%s: successfull\n", __func__);

	return 0;

}


/*
 * ipq6018_edma_init_rings()
 *	Initialize EDMA rings
 */
static int ipq6018_edma_init_rings(struct ipq6018_edma_hw *ehw)
{
	int ret;

	/*
	 * Setup ring values
	 */
	ipq6018_edma_set_ring_values(ehw);

	/*
	 * Allocate desc rings
	 */
	ret = ipq6018_edma_alloc_rings(ehw);
	if (ret)
		return ret;

	/*
	 * Setup ring resources
	 */
	ret = ipq6018_edma_setup_ring_resources(ehw);
	if (ret)
		return ret;

	return 0;
}

/*
 * ipq6018_edma_configure_txdesc_ring()
 *	Configure one TxDesc ring
 */
static void ipq6018_edma_configure_txdesc_ring(struct ipq6018_edma_hw *ehw,
					struct ipq6018_edma_txdesc_ring *txdesc_ring)
{
	uint32_t data;
	uint16_t hw_cons_idx;

	/*
	 * Configure TXDESC ring
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXDESC_BA(txdesc_ring->id),
			(uint32_t)(txdesc_ring->dma &
			IPQ6018_EDMA_RING_DMA_MASK));

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXDESC_RING_SIZE(
			txdesc_ring->id), (uint32_t)(txdesc_ring->count &
			IPQ6018_EDMA_TXDESC_RING_SIZE_MASK));

	data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_TXDESC_CONS_IDX(
				txdesc_ring->id));

	data &= ~(IPQ6018_EDMA_TXDESC_CONS_IDX_MASK);
	hw_cons_idx = data;

	data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_TXDESC_PROD_IDX(
					txdesc_ring->id));

	data &= ~(IPQ6018_EDMA_TXDESC_PROD_IDX_MASK);
	data |= hw_cons_idx & IPQ6018_EDMA_TXDESC_PROD_IDX_MASK;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXDESC_PROD_IDX(
					txdesc_ring->id), data);
}

/*
 * ipq6018_edma_configure_txcmpl_ring()
 *	Configure one TxCmpl ring
 */
static void ipq6018_edma_configure_txcmpl_ring(struct ipq6018_edma_hw *ehw,
					struct ipq6018_edma_txcmpl_ring *txcmpl_ring)
{
	uint32_t txcmpl_ugt_thre, low_thre = 0, txcmpl_fc_thre = 0;
	uint32_t tx_mod_timer;

	/*
	 * Configure TxCmpl ring base address
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXCMPL_BA(txcmpl_ring->id),
			(uint32_t)(txcmpl_ring->dma &
			 IPQ6018_EDMA_RING_DMA_MASK));

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXCMPL_RING_SIZE(
			txcmpl_ring->id), (uint32_t)(txcmpl_ring->count &
			 IPQ6018_EDMA_TXDESC_RING_SIZE_MASK));

	/*
	 * Set TxCmpl ret mode to opaque
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXCMPL_CTRL(txcmpl_ring->id),
			IPQ6018_EDMA_TXCMPL_RETMODE_OPAQUE);

	txcmpl_ugt_thre = (low_thre & IPQ6018_EDMA_TXCMPL_LOW_THRE_MASK) <<
				 IPQ6018_EDMA_TXCMPL_LOW_THRE_SHIFT;

	txcmpl_ugt_thre |= (txcmpl_fc_thre & IPQ6018_EDMA_TXCMPL_FC_THRE_MASK)
			<< IPQ6018_EDMA_TXCMPL_FC_THRE_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXCMPL_UGT_THRE(
				txcmpl_ring->id), txcmpl_ugt_thre);

	tx_mod_timer = (IPQ6018_EDMA_TX_MOD_TIMER &
			 IPQ6018_EDMA_TX_MOD_TIMER_INIT_MASK) <<
			 IPQ6018_EDMA_TX_MOD_TIMER_INIT_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TX_MOD_TIMER(txcmpl_ring->id),
				tx_mod_timer);

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TX_INT_CTRL(txcmpl_ring->id),
							 0x2);
}

/*
 * ipq6018_edma_configure_rxdesc_ring()
 *	Configure one RxDesc ring
 */
static void ipq6018_edma_configure_rxdesc_ring(struct ipq6018_edma_hw *ehw,
					struct ipq6018_edma_rxdesc_ring *rxdesc_ring)
{
	uint32_t data;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_BA(rxdesc_ring->id),
			(uint32_t)(rxdesc_ring->dma & 0xffffffff));

	data = rxdesc_ring->count & IPQ6018_EDMA_RXDESC_RING_SIZE_MASK;
	data |= (ehw->rx_payload_offset &
			 IPQ6018_EDMA_RXDESC_PL_OFFSET_MASK) <<
			 IPQ6018_EDMA_RXDESC_PL_OFFSET_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_RING_SIZE(
				rxdesc_ring->id), data);

	data = (IPQ6018_EDMA_RXDESC_XON_THRE &
			 IPQ6018_EDMA_RXDESC_FC_XON_THRE_MASK) <<
			 IPQ6018_EDMA_RXDESC_FC_XON_THRE_SHIFT;

	data |= (IPQ6018_EDMA_RXDESC_XOFF_THRE &
			 IPQ6018_EDMA_RXDESC_FC_XOFF_THRE_MASK) <<
			 IPQ6018_EDMA_RXDESC_FC_XOFF_THRE_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_FC_THRE(
					rxdesc_ring->id), data);

	data = (IPQ6018_EDMA_RXDESC_LOW_THRE &
			 IPQ6018_EDMA_RXDESC_LOW_THRE_MASK) <<
			 IPQ6018_EDMA_RXDESC_LOW_THRE_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_UGT_THRE(
				rxdesc_ring->id), data);

	data = (IPQ6018_EDMA_RX_MOD_TIMER_INIT &
			 IPQ6018_EDMA_RX_MOD_TIMER_INIT_MASK) <<
			 IPQ6018_EDMA_RX_MOD_TIMER_INIT_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RX_MOD_TIMER(
				rxdesc_ring->id), data);

	/*
	 * Enable ring. Set ret mode to 'opaque'.
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RX_INT_CTRL(
					rxdesc_ring->id), 0x2);
}

/*
 * ipq6018_edma_configure_rxfill_ring()
 *	Configure one RxFill ring
 */
static void ipq6018_edma_configure_rxfill_ring(struct ipq6018_edma_hw *ehw,
					struct ipq6018_edma_rxfill_ring *rxfill_ring)
{
	uint32_t rxfill_low_thre = (rxfill_ring->count / 4);
	uint32_t rxfill_xon_thre = (rxfill_ring->count / 8);
	uint32_t rxfill_xoff_thre = (rxfill_ring->count / 16);
	uint32_t rxfill_fc_thre;
	uint32_t rxfill_ugt_thre;
	uint32_t data;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_BA(rxfill_ring->id),
			(uint32_t)(rxfill_ring->dma & IPQ6018_EDMA_RING_DMA_MASK));

	data = rxfill_ring->count & IPQ6018_EDMA_RXFILL_RING_SIZE_MASK;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_RING_SIZE(rxfill_ring->id), data);

	rxfill_fc_thre = (rxfill_xon_thre & IPQ6018_EDMA_RXFILL_FC_XON_THRE_MASK)
				<< IPQ6018_EDMA_RXFILL_FC_XON_THRE_SHIFT;
	rxfill_fc_thre |= (rxfill_xoff_thre & IPQ6018_EDMA_RXFILL_FC_XOFF_THRE_MASK)
				<< IPQ6018_EDMA_RXFILL_FC_XOFF_THRE_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_FC_THRE(rxfill_ring->id),
				rxfill_fc_thre);

	rxfill_ugt_thre = (rxfill_low_thre & IPQ6018_EDMA_RXFILL_LOW_THRE_MASK)
				<< IPQ6018_EDMA_RXFILL_LOW_THRE_SHIFT;

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_UGT_THRE(rxfill_ring->id),
				rxfill_ugt_thre);

}


/*
 * ipq6018_edma_configure_rings()
 *	Configure EDMA rings
 */
static void ipq6018_edma_configure_rings(struct ipq6018_edma_hw *ehw)
{
	int i;

	/*
	 * Configure TXDESC ring
	 */
	for (i = 0; i < ehw->txdesc_rings; i++)
		ipq6018_edma_configure_txdesc_ring(ehw, &ehw->txdesc_ring[i]);

	/*
	 * Configure TXCMPL ring
	 */
	for (i = 0; i < ehw->txcmpl_rings; i++)
		ipq6018_edma_configure_txcmpl_ring(ehw, &ehw->txcmpl_ring[i]);

	/*
	 * Configure RXFILL rings
	 */
	for (i = 0; i < ehw->rxfill_rings; i++)
		ipq6018_edma_configure_rxfill_ring(ehw, &ehw->rxfill_ring[i]);

	/*
	 * Configure RXDESC ring
	 */
	for (i = 0; i < ehw->rxdesc_rings; i++)
		ipq6018_edma_configure_rxdesc_ring(ehw, &ehw->rxdesc_ring[i]);

	pr_info("%s: successfull\n", __func__);
}

/*
 * ipq6018_edma_hw_reset()
 *	EDMA hw reset
 */
void ipq6018_edma_hw_reset(void)
{
	writel(GCC_EDMA_HW_RESET_ASSERT, GCC_NSS_PPE_RESET);
	udelay(100);
	writel(GCC_EDMA_HW_RESET_DEASSERT, GCC_NSS_PPE_RESET);
	udelay(100);
}

/*
 * ipq6018_edma_hw_init()
 *	EDMA hw init
 */
int ipq6018_edma_hw_init(struct ipq6018_edma_hw *ehw)
{
	int ret, desc_index;
	uint32_t i, reg;
	volatile uint32_t data;

	struct ipq6018_edma_rxdesc_ring *rxdesc_ring = NULL;

	ipq6018_ppe_provision_init();

	data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_MAS_CTRL);
	printf("EDMA ver %d hw init\n", data);

	/*
	 * Setup private data structure
	 */
	ehw->rxfill_intr_mask = IPQ6018_EDMA_RXFILL_INT_MASK;
	ehw->rxdesc_intr_mask = IPQ6018_EDMA_RXDESC_INT_MASK_PKT_INT;
	ehw->txcmpl_intr_mask = IPQ6018_EDMA_TX_INT_MASK_PKT_INT |
				IPQ6018_EDMA_TX_INT_MASK_UGT_INT;
	ehw->misc_intr_mask = 0;
	ehw->rx_payload_offset = IPQ6018_EDMA_RX_PREHDR_SIZE;

	/*
	 * Reset EDMA
	 */
	ipq6018_edma_hw_reset();

	/*
	 * Disable interrupts
	 */
	ipq6018_edma_disable_intr(ehw);

	/*
	 * Disable rings
	 */
	ipq6018_edma_disable_rings(ehw);

	ret = ipq6018_edma_init_rings(ehw);

	if (ret)
		return ret;

	ipq6018_edma_configure_rings(ehw);

	/*
	 * Set PPE QID to EDMA Rx ring mapping.
	 * When coming up use only queue 0.
	 * HOST EDMA rings. FW EDMA comes up and overwrites as required.
	 * Each entry can hold mapping for 8 PPE queues and entry size is
	 * 4 bytes
	 */
	desc_index = ehw->rxdesc_ring_start;
	reg = IPQ6018_EDMA_QID2RID_TABLE_MEM(0);
	data = 0;
	data |= (desc_index & 0xF);
	ipq6018_edma_reg_write(reg, data);
	pr_debug("Configure QID2RID reg:0x%x to 0x%x\n", reg, data);

	/*
	 * Set RXDESC2FILL_MAP_xx reg.
	 * There are two registers RXDESC2FILL_0 and RXDESC2FILL_1
	 * 3 bits holds the rx fill ring mapping for each of the
	 * rx descriptor ring.
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC2FILL_MAP_0, 0);
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC2FILL_MAP_1, 0);

	for (i = ehw->rxdesc_ring_start;
			i < ehw->rxdesc_ring_end; i++) {
		if ((i >= 0) && (i <= 9))
			reg = IPQ6018_EDMA_REG_RXDESC2FILL_MAP_0;
		else
			reg = IPQ6018_EDMA_REG_RXDESC2FILL_MAP_1;

		rxdesc_ring = &ehw->rxdesc_ring[i - ehw->rxdesc_ring_start];

		pr_debug("Configure RXDESC:%u to use RXFILL:%u\n",
				rxdesc_ring->id, rxdesc_ring->rxfill->id);

		data = ipq6018_edma_reg_read(reg);
		data |= (rxdesc_ring->rxfill->id & 0x7) << ((i % 10) * 3);
		ipq6018_edma_reg_write(reg, data);
	}

	reg = IPQ6018_EDMA_REG_RXDESC2FILL_MAP_0;
	pr_debug("EDMA_REG_RXDESC2FILL_MAP_0: 0x%x\n",
		ipq6018_edma_reg_read(reg));
	reg = IPQ6018_EDMA_REG_RXDESC2FILL_MAP_1;
	pr_debug("EDMA_REG_RXDESC2FILL_MAP_1: 0x%x\n",
		 ipq6018_edma_reg_read(reg));

	/*
	 * Enable EDMA
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_PORT_CTRL,
				 IPQ6018_EDMA_PORT_CTRL_EN);

	/*
	 * Enable Rx rings
	 */
	for (i = ehw->rxdesc_ring_start; i < ehw->rxdesc_ring_end; i++) {
		data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_RXDESC_CTRL(i));
		data |= IPQ6018_EDMA_RXDESC_RX_EN;
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXDESC_CTRL(i), data);
	}

	for (i = ehw->rxfill_ring_start; i < ehw->rxfill_ring_end; i++) {
		data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_RXFILL_RING_EN(i));
		data |= IPQ6018_EDMA_RXFILL_RING_EN;
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_RXFILL_RING_EN(i), data);
	}

	/*
	 * Enable Tx rings
	 */
	for (i = ehw->txdesc_ring_start; i < ehw->txdesc_ring_end; i++) {
		data = ipq6018_edma_reg_read(IPQ6018_EDMA_REG_TXDESC_CTRL(i));
		data |= IPQ6018_EDMA_TXDESC_TX_EN;
		ipq6018_edma_reg_write(IPQ6018_EDMA_REG_TXDESC_CTRL(i), data);
	}

	/*
	 * Enable MISC interrupt
	 */
	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_MISC_INT_MASK,
				ehw->misc_intr_mask);

	pr_info("%s: successfull\n", __func__);
	return 0;
}

void get_phy_address(int offset)
{
	int phy_type;
	int phy_address;
	int i;

	for (i = 0; i < IPQ6018_PHY_MAX; i++)
		phy_info[i] = ipq6018_alloc_mem(sizeof(phy_info_t));
	i = 0;
	for (offset = fdt_first_subnode(gd->fdt_blob, offset); offset > 0;
	     offset = fdt_next_subnode(gd->fdt_blob, offset)) {

		phy_address = fdtdec_get_uint(gd->fdt_blob,
							  offset, "phy_address", 0);
		phy_type = fdtdec_get_uint(gd->fdt_blob,
							  offset, "phy_type", 0);
		phy_info[i]->phy_address = phy_address;
		phy_info[i++]->phy_type = phy_type;
	}
}

#ifdef CONFIG_QCA8084_SWT_MODE
void get_phy_qca8084_address(int offset)
{
	int phy_type;
	int phy_address;
	int forced_speed, forced_duplex;
	int i;

	for (i = 0; i < QCA8084_MAX_PORTS; i++)
		swt_info[i] = ipq6018_alloc_mem(sizeof(phy_info_t));
	i = 0;
	for (offset = fdt_first_subnode(gd->fdt_blob, offset); offset > 0;
	     offset = fdt_next_subnode(gd->fdt_blob, offset)) {

		phy_address = fdtdec_get_uint(gd->fdt_blob,
							  offset, "phy_address", 0);
		phy_type = fdtdec_get_uint(gd->fdt_blob,
							  offset, "phy_type", 0);
		forced_speed = fdtdec_get_uint(gd->fdt_blob,
					   offset, "forced-speed", 0);
		forced_duplex = fdtdec_get_uint(gd->fdt_blob,
					   offset, "forced-duplex", 0);
		swt_info[i]->phy_address = phy_address;
		swt_info[i]->forced_speed = forced_speed;
		swt_info[i]->forced_duplex = forced_duplex;
		swt_info[i++]->phy_type = phy_type;
	}
}
#endif

int ipq6018_edma_init(void *edma_board_cfg)
{
	struct eth_device *dev[IPQ6018_EDMA_DEV];
	struct ipq6018_edma_common_info *c_info[IPQ6018_EDMA_DEV];
	struct ipq6018_edma_hw *hw[IPQ6018_EDMA_DEV];
	uchar enet_addr[IPQ6018_EDMA_DEV * 6];
	int i, phy_id;
	uint32_t phy_chip_id, phy_chip_id1, phy_chip_id2;
	int ret = -1;
	ipq6018_edma_board_cfg_t ledma_cfg, *edma_cfg;
	static int sw_init_done = 0;
	int port_8033 = -1, node, phy_addr, aquantia_port = -1;
	int mode, phy_node = -1;
#ifdef CONFIG_QCA8084_SWT_MODE
	static int qca8084_init_done = 0;
	int phy_type = 0;
	int qca8084_gpio = 0;
	int swt_node = -1;
#endif /* CONFIG_QCA8084_SWT_MODE */

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0)
		port_8033 = fdtdec_get_uint(gd->fdt_blob, node, "8033_port", -1);

	if (node >= 0)
		aquantia_port = fdtdec_get_uint(gd->fdt_blob, node, "aquantia_port", -1);

#ifdef CONFIG_QCA8084_SWT_MODE
	qca8084_swt_port = fdtdec_get_uint(gd->fdt_blob, node, "qca8084_swt_port", -1);
	qca8084_gpio =  fdtdec_get_uint(gd->fdt_blob, node, "qca808x_gpio", 0);
	if (qca8084_swt_port != -1) {
		if (qca8084_gpio)
			ipq_qca8084_switch_hw_reset(qca8084_gpio);
	}

	swt_node = fdt_path_offset(gd->fdt_blob, "/ess-switch/qca8084_swt_info");
	if (swt_node >= 0)
		get_phy_qca8084_address(swt_node);
#endif

	phy_node = fdt_path_offset(gd->fdt_blob, "/ess-switch/port_phyinfo");
	if (phy_node >= 0)
		get_phy_address(phy_node);

	mode = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode", -1);
	if (mode < 0) {
		printf("Error: switch_mac_mode not specified in dts");
		return mode;
	}

	memset(c_info, 0, (sizeof(c_info) * IPQ6018_EDMA_DEV));
	memset(enet_addr, 0, sizeof(enet_addr));
	memset(&ledma_cfg, 0, sizeof(ledma_cfg));
	edma_cfg = &ledma_cfg;
	strlcpy(edma_cfg->phy_name, "IPQ MDIO0", sizeof(edma_cfg->phy_name));

	/* Getting the MAC address from ART partition */
	ret = get_eth_mac_address(enet_addr, IPQ6018_EDMA_DEV);

	/*
	 * Register EDMA as single ethernet
	 * interface.
	 */
	for (i = 0; i < IPQ6018_EDMA_DEV; edma_cfg++, i++) {
		dev[i] = ipq6018_alloc_mem(sizeof(struct eth_device));

		if (!dev[i])
			goto init_failed;

		memset(dev[i], 0, sizeof(struct eth_device));

		c_info[i] = ipq6018_alloc_mem(
			sizeof(struct ipq6018_edma_common_info));

		if (!c_info[i])
			goto init_failed;

		memset(c_info[i], 0,
			sizeof(struct ipq6018_edma_common_info));

		hw[i] = &c_info[i]->hw;

		c_info[i]->hw.hw_addr = (unsigned long  __iomem *)
						IPQ6018_EDMA_CFG_BASE;

		ipq6018_edma_dev[i] = ipq6018_alloc_mem(
				sizeof(struct ipq6018_eth_dev));

		if (!ipq6018_edma_dev[i])
			goto init_failed;

		memset (ipq6018_edma_dev[i], 0,
			sizeof(struct ipq6018_eth_dev));

		dev[i]->iobase = IPQ6018_EDMA_CFG_BASE;
		dev[i]->init = ipq6018_eth_init;
		dev[i]->halt = ipq6018_eth_halt;
		dev[i]->recv = ipq6018_eth_recv;
		dev[i]->send = ipq6018_eth_snd;
		dev[i]->write_hwaddr = ipq6018_edma_wr_macaddr;
		dev[i]->priv = (void *)ipq6018_edma_dev[i];

		if ((ret < 0) ||
			(!is_valid_ethaddr(&enet_addr[edma_cfg->unit * 6]))) {
			memcpy(&dev[i]->enetaddr[0], ipq6018_def_enetaddr, 6);
		} else {
			memcpy(&dev[i]->enetaddr[0],
				&enet_addr[edma_cfg->unit * 6], 6);
		}

		printf("MAC%x addr:%x:%x:%x:%x:%x:%x\n",
			edma_cfg->unit, dev[i]->enetaddr[0],
			dev[i]->enetaddr[1],
			dev[i]->enetaddr[2],
			dev[i]->enetaddr[3],
			dev[i]->enetaddr[4],
			dev[i]->enetaddr[5]);

		snprintf(dev[i]->name, sizeof(dev[i]->name), "eth%d", i);

		ipq6018_edma_dev[i]->dev  = dev[i];
		ipq6018_edma_dev[i]->mac_unit = edma_cfg->unit;
		ipq6018_edma_dev[i]->c_info = c_info[i];
		ipq6018_edma_hw_addr = IPQ6018_EDMA_CFG_BASE;

		ret = ipq_sw_mdio_init(edma_cfg->phy_name);
		if (ret)
			goto init_failed;

		for (phy_id =  0; phy_id < IPQ6018_PHY_MAX; phy_id++) {
			if(phy_info[phy_id]->phy_type == UNUSED_PHY_TYPE)
				continue;

			if (phy_node >= 0) {
				phy_addr = phy_info[phy_id]->phy_address;
#ifdef CONFIG_QCA8084_SWT_MODE
				phy_type = phy_info[phy_id]->phy_type;
#endif
			} else {
				if (phy_id == port_8033)
					phy_addr = QCA8033_PHY_ADDR;
				else if (phy_id == aquantia_port)
					phy_addr = AQU_PHY_ADDR;
				else
					phy_addr = phy_id;
			}

#ifdef CONFIG_QCA8084_PHY
			if (phy_type == QCA8084_PHY_TYPE) {
				if ((qca8084_swt_port == phy_id) ||
					!qca8084_init_done) {
					ipq_phy_addr_fixup();
					ipq_clock_init();
					if (qca8084_swt_port != phy_id)
						qca8084_init_done = 1;
				}
			}
#endif

			phy_chip_id1 = ipq_mdio_read(phy_addr, QCA_PHY_ID1, NULL);
			phy_chip_id2 = ipq_mdio_read(phy_addr, QCA_PHY_ID2, NULL);
			phy_chip_id = (phy_chip_id1 << 16) | phy_chip_id2;
			if (phy_id == aquantia_port) {
				phy_chip_id1 = ipq_mdio_read(phy_addr, (1<<30) |(1<<16) | QCA_PHY_ID1, NULL);
				phy_chip_id2 = ipq_mdio_read(phy_addr, (1<<30) |(1<<16) | QCA_PHY_ID2, NULL);
				phy_chip_id = (phy_chip_id1 << 16) | phy_chip_id2;
			}

			switch(phy_chip_id) {
				case QCA8075_PHY_V1_0_5P:
				case QCA8075_PHY_V1_1_5P:
				case QCA8075_PHY_V1_1_2P:

					if (!sw_init_done) {
						if (ipq_qca8075_phy_init(&ipq6018_edma_dev[i]->ops[phy_id]) == 0) {
							sw_init_done = 1;
						}
					} else {
						ipq_qca8075_phy_map_ops(&ipq6018_edma_dev[i]->ops[phy_id]);
					}

					if (mode == PORT_WRAPPER_PSGMII)
						qca8075_phy_interface_set_mode(0x0, 0x0);
					else if ( mode == PORT_WRAPPER_QSGMII)
						qca8075_phy_interface_set_mode(0x0, 0x4);
					break;
#ifdef CONFIG_QCA8033_PHY
				case QCA8033_PHY:
					ipq_qca8033_phy_init(&ipq6018_edma_dev[i]->ops[phy_id], phy_addr);
					break;
#endif
#ifdef CONFIG_QCA8081_PHY
				case QCA8081_PHY:
				case QCA8081_1_1_PHY:
					ipq_qca8081_phy_init(&ipq6018_edma_dev[i]->ops[phy_id], phy_addr);
					break;
#endif
#ifdef CONFIG_IPQ6018_QCA_AQUANTIA_PHY
				case AQUANTIA_PHY_107:
				case AQUANTIA_PHY_109:
				case AQUANTIA_PHY_111:
				case AQUANTIA_PHY_112:
				case AQUANTIA_PHY_111B0:
				case AQUANTIA_PHY_112C:
					ipq_board_fw_download(phy_addr);
					ipq_qca_aquantia_phy_init(&ipq6018_edma_dev[i]->ops[phy_id], phy_addr);
					break;
#endif
#ifdef CONFIG_QCA8084_PHY_MODE
				case QCA8084_PHY:
					break;
#endif
				default:
					ipq_qca8075_phy_map_ops(&ipq6018_edma_dev[i]->ops[phy_id]);
					break;
			}
		}

		ret = ipq6018_edma_hw_init(hw[i]);

		if (ret)
			goto init_failed;

#ifdef CONFIG_QCA8084_SWT_MODE
		/** QCA8084 switch specific configurations */
		if (qca8084_swt_port != -1) {
			/** Force speed alder 1st port for QCA8084 switch mode */
			ipq6018_speed_clock_set(qca8084_swt_port, 0x100, 0x0);

			/** Force Link-speed: 1000M
			 *  Force Link-status: enable */
			ipq6018_pqsgmii_speed_set(qca8084_swt_port, 0x2, 0x0);

			ret = ipq_qca8084_hw_init(swt_info);
			if (ret < 0) {
				printf("Error: ipq_qca8084_hw_init failed \n");
				qca8084_swt_port =  -1;
			}
		}
#endif
		eth_register(dev[i]);
	}

	return 0;

init_failed:
	printf("Error in allocating Mem\n");

	for (i = 0; i < IPQ6018_EDMA_DEV; i++) {
		if (dev[i]) {
			eth_unregister(dev[i]);
			ipq6018_free_mem(dev[i]);
		}
		if (c_info[i]) {
			ipq6018_edma_free_desc(c_info[i]);
			ipq6018_edma_free_rings(c_info[i]);
			ipq6018_free_mem(c_info[i]);
		}
		if (ipq6018_edma_dev[i]) {
			ipq6018_free_mem(ipq6018_edma_dev[i]);
		}
	}

	return -1;
}

void ipq_eth_cleanup(struct eth_device *dev)
{
	struct ipq6018_eth_dev *priv = dev->priv;
	struct ipq6018_edma_common_info *c_info = priv->c_info;
	struct ipq6018_edma_hw *ehw = &c_info->hw;

	ipq6018_edma_disable_intr(ehw);

	ipq6018_edma_disable_rings(ehw);

	ipq6018_edma_reg_write(IPQ6018_EDMA_REG_PORT_CTRL, 0);

	return;
}
