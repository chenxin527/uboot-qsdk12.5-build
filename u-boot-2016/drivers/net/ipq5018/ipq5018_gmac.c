/*
* Copyright (c) 2019-2021 The Linux Foundation. All rights reserved.
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

#include <common.h>
#include <net.h>
#include <asm-generic/errno.h>
#include <asm/io.h>
#include <malloc.h>
#include <phy.h>
#include <net.h>
#include <asm/global_data.h>
#include "ipq_phy.h"
#include <asm/arch-ipq5018/ipq5018_gmac.h>

DECLARE_GLOBAL_DATA_PTR;

#define ipq_info        printf
#define ipq_dbg         printf
#define DESC_SIZE       (sizeof(ipq_gmac_desc_t))
#define DESC_FLUSH_SIZE (((DESC_SIZE + (CONFIG_SYS_CACHELINE_SIZE - 1)) \
                        / CONFIG_SYS_CACHELINE_SIZE) * \
                        (CONFIG_SYS_CACHELINE_SIZE))

static struct ipq_eth_dev *ipq_gmac_macs[IPQ5018_GMAC_PORT];

uchar ipq_def_enetaddr[6] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55};
phy_info_t *phy_info[IPQ5018_PHY_MAX] = {0};

extern int ipq_mdio_read(int mii_id, int regnum, ushort *data);
extern int ipq_mdio_write(int mii_id, int regnum, u16 value);
extern int ipq5018_mdio_write(int mii_id, int regnum, u16 value);
extern int ipq5018_mdio_read(int mii_id, int regnum, ushort *data);
extern int ipq_qca8033_phy_init(struct phy_ops **ops, u32 phy_id);
extern int ipq_qca8081_phy_init(struct phy_ops **ops, u32 phy_id);
extern int ipq_gephy_phy_init(struct phy_ops **ops, u32 phy_id);
extern int ipq_sw_mdio_init(const char *);
extern int ipq5018_sw_mdio_init(const char *);
extern void ppe_uniphy_mode_set(uint32_t mode, uint32_t phy_mode);
extern void uniphy_channel0_input_output_6_get(int mode, u32 gpio, u8 *status,
					       fal_port_speed_t *speed,
					       fal_port_duplex_t *duplex);
extern int ipq_athrs17_init(ipq_gmac_board_cfg_t *gmac_cfg);

static int ipq_eth_wr_macaddr(struct eth_device *dev)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_mac_regs *mac_p = (struct eth_mac_regs *)priv->mac_regs_p;
	u32 macid_lo, macid_hi;
	u8 *mac_id = &dev->enetaddr[0];

	macid_lo = mac_id[0] + (mac_id[1] << 8) +
		   (mac_id[2] << 16) + (mac_id[3] << 24);
	macid_hi = mac_id[4] + (mac_id[5] << 8);

	writel(macid_hi, &mac_p->macaddr0hi);
	writel(macid_lo, &mac_p->macaddr0lo);

	return 0;
}

static void ipq_mac_reset(struct eth_device *dev)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_dma_regs *dma_reg = (struct eth_dma_regs *)priv->dma_regs_p;
	u32 val;

	writel(DMAMAC_SRST, &dma_reg->busmode);
	do {
		udelay(10);
		val = readl(&dma_reg->busmode);
	} while (val & DMAMAC_SRST);

}

static void ipq_eth_mac_cfg(struct eth_device *dev)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_mac_regs *mac_reg = (struct eth_mac_regs *)priv->mac_regs_p;
	uint speed = 0;
	uint ipq_mac_cfg = 0;
	uint ipq_mac_framefilter = 0;

	ipq_mac_framefilter = PROMISCUOUS_MODE_ON;

	if (priv->mac_unit) {
		if (priv->phy_type == QCA8081_1_1_PHY || priv->phy_type == QCA8033_PHY)
			speed = priv->speed;

		ipq_mac_cfg |= (FRAME_BURST_ENABLE | JUMBO_FRAME_ENABLE | JABBER_DISABLE |
				TX_ENABLE | RX_ENABLE | FULL_DUPLEX_ENABLE | speed);

		writel(ipq_mac_cfg, &mac_reg->conf);
	} else {
		ipq_mac_cfg |= (priv->speed | FULL_DUPLEX_ENABLE | FRAME_BURST_ENABLE |
				TX_ENABLE | RX_ENABLE);
		writel(ipq_mac_cfg, &mac_reg->conf);
	}

	writel(ipq_mac_framefilter, &mac_reg->framefilt);

}

static void ipq_eth_dma_cfg(struct eth_device *dev)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_dma_regs *dma_reg = (struct eth_dma_regs *)priv->dma_regs_p;
	uint ipq_dma_bus_mode;
	uint ipq_dma_op_mode;

	ipq_dma_op_mode = DmaStoreAndForward | DmaRxThreshCtrl128 |
				DmaTxSecondFrame;
	ipq_dma_bus_mode = DmaFixedBurstEnable | DmaBurstLength16 |
				DmaDescriptorSkip0 | DmaDescriptor8Words |
				DmaArbitPr;

	writel(ipq_dma_bus_mode, &dma_reg->busmode);
	writel(ipq_dma_op_mode, &dma_reg->opmode);
}

static void ipq_eth_flw_cntl_cfg(struct eth_device *dev)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_mac_regs *mac_reg = (struct eth_mac_regs *)priv->mac_regs_p;
	struct eth_dma_regs *dma_reg = (struct eth_dma_regs *)priv->dma_regs_p;
	uint ipq_dma_flw_cntl;
	uint ipq_mac_flw_cntl;

	ipq_dma_flw_cntl = DmaRxFlowCtrlAct3K | DmaRxFlowCtrlDeact4K |
				DmaEnHwFlowCtrl;
	ipq_mac_flw_cntl = GmacRxFlowControl | GmacTxFlowControl | 0xFFFF0000;

	setbits_le32(&dma_reg->opmode, ipq_dma_flw_cntl);
	setbits_le32(&mac_reg->flowcontrol, ipq_mac_flw_cntl);
}

static int ipq_gmac_alloc_fifo(int ndesc, ipq_gmac_desc_t **fifo)
{
	int i;
	void *addr;

	addr = memalign((CONFIG_SYS_CACHELINE_SIZE),
			(ndesc * DESC_FLUSH_SIZE));

	for (i = 0; i < ndesc; i++) {
		fifo[i] = (ipq_gmac_desc_t *)((unsigned long)addr +
			  (i * DESC_FLUSH_SIZE));
		if (fifo[i] == NULL) {
			ipq_info("Can't allocate desc fifos\n");
			return -1;
		}
	}
	return 0;
}

static int ipq_gmac_rx_desc_setup(struct ipq_eth_dev  *priv)
{
	struct eth_dma_regs *dma_reg = (struct eth_dma_regs *)priv->dma_regs_p;
	ipq_gmac_desc_t *rxdesc;
	int i;

	for (i = 0; i < NO_OF_RX_DESC; i++) {
		rxdesc = priv->desc_rx[i];
		rxdesc->length |= ((ETH_MAX_FRAME_LEN << DescSize1Shift) &
					DescSize1Mask);
		rxdesc->buffer1 = virt_to_phys(net_rx_packets[i]);
		rxdesc->data1 = (unsigned long)priv->desc_rx[(i + 1) %
				NO_OF_RX_DESC];

		rxdesc->extstatus = 0;
		rxdesc->reserved1 = 0;
		rxdesc->timestamplow = 0;
		rxdesc->timestamphigh = 0;
		rxdesc->status = DescOwnByDma;


		flush_dcache_range((unsigned long)rxdesc,
			(unsigned long)rxdesc + DESC_SIZE);

	}
	/* Assign Descriptor base address to dmadesclist addr reg */
	writel((uint)priv->desc_rx[0], &dma_reg->rxdesclistaddr);

	return 0;
}

static int ipq_gmac_tx_rx_desc_ring(struct ipq_eth_dev  *priv)
{
	int i;
	ipq_gmac_desc_t *desc;

	if (ipq_gmac_alloc_fifo(NO_OF_TX_DESC, priv->desc_tx))
		return -1;

	for (i = 0; i < NO_OF_TX_DESC; i++) {
		desc = priv->desc_tx[i];
		memset(desc, 0, DESC_SIZE);

		desc->status =
		(i == (NO_OF_TX_DESC - 1)) ? TxDescEndOfRing : 0;

		desc->status |= TxDescChain;

		desc->data1 = (unsigned long)priv->desc_tx[(i + 1) %
				NO_OF_TX_DESC ];

		flush_dcache_range((unsigned long)desc,
			(unsigned long)desc + DESC_SIZE);

	}

	if (ipq_gmac_alloc_fifo(NO_OF_RX_DESC, priv->desc_rx))
		return -1;

	for (i = 0; i < NO_OF_RX_DESC; i++) {
		desc = priv->desc_rx[i];
		memset(desc, 0, DESC_SIZE);
		desc->length =
		(i == (NO_OF_RX_DESC - 1)) ? RxDescEndOfRing : 0;
		desc->length |= RxDescChain;

		desc->data1 = (unsigned long)priv->desc_rx[(i + 1) %
				NO_OF_RX_DESC];

		flush_dcache_range((unsigned long)desc,
			(unsigned long)desc + DESC_SIZE);

	}

	priv->next_tx = 0;
	priv->next_rx = 0;

	return 0;
}

static inline void ipq_gmac_give_to_dma(ipq_gmac_desc_t *fr)
{
	fr->status |= DescOwnByDma;
}

static inline u32 ipq_gmac_owned_by_dma(ipq_gmac_desc_t *fr)
{
	return (fr->status & DescOwnByDma);
}

static inline u32 ipq_gmac_is_desc_empty(ipq_gmac_desc_t *fr)
{
	return ((fr->length & DescSize1Mask) == 0);
}

static void ipq5018_gmac0_speed_clock_set(int speed_clock1,
	int speed_clock2, int gmacid)
{
	int iTxRx;
	uint32_t reg_value;
	/*
	 * iTxRx indicates Tx and RX register
	 * 0 = Rx and 1 = Tx
	 */
	for (iTxRx = 0; iTxRx < 2; ++iTxRx){
		/* gcc port first clock divider */
		reg_value = 0;
		reg_value = readl(GCC_GMAC0_RX_CFG_RCGR +
				(iTxRx * 8) + (gmacid * 0x10));
		reg_value &= ~0x1f;
		reg_value |= speed_clock1;
		writel(reg_value, GCC_GMAC0_RX_CFG_RCGR +
				(iTxRx * 8) + (gmacid * 0x10));
		/* gcc port second clock divider */
		reg_value = 0;
		reg_value = readl(GCC_GMAC0_RX_MISC +
				(iTxRx * 4) + (gmacid * 0x10));
		reg_value &= ~0xf;
		reg_value |= speed_clock2;
		writel(reg_value, GCC_GMAC0_RX_MISC +
				(iTxRx * 4) + (gmacid * 0x10));
		/* update above clock configuration */
		reg_value = 0;
		reg_value = readl(GCC_GMAC0_RX_CMD_RCGR +
				(iTxRx * 8) + (gmacid * 0x10));
		reg_value &= ~0x1;
		reg_value |= 0x1;
		writel(reg_value, GCC_GMAC0_RX_CMD_RCGR +
				(iTxRx * 8) + (gmacid * 0x10));
	}
}

static void ipq5018_enable_gephy(void)
{
	uint32_t reg_val;

	reg_val = readl(GCC_GEPHY_RX_CBCR);
	reg_val |= GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GEPHY_RX_CBCR);
	mdelay(20);

	reg_val = readl(GCC_GEPHY_TX_CBCR);
	reg_val |= GCC_CBCR_CLK_ENABLE;
	writel(reg_val, GCC_GEPHY_TX_CBCR);
	mdelay(20);
}

static int ipq5018_s17c_Link_Update(struct ipq_eth_dev *priv)
{
	uint16_t phy_data;
	int status = 1;

	for(int i = 0;
		i < priv->gmac_board_cfg->switch_port_count; ++i){
		phy_data = ipq_mdio_read(
			priv->gmac_board_cfg->switch_port_phy_address[i],
			0x11,
			NULL);

		if (phy_data == 0x50)
			continue;

		/* Atleast one port should be link up*/
		if (phy_data & LINK_UP)
			status = 0;

		printf("Port%d %s ", i + 1, LINK(phy_data));

		switch(SPEED(phy_data)){
		case SPEED_1000M:
			printf("Speed :1000M ");
			break;
		case SPEED_100M:
			printf("Speed :100M ");
			break;
		default:
			printf("Speed :10M ");
		}

		printf ("%s \n", DUPLEX(phy_data));
	}
	return status;
}

static int ipq5018_phy_link_update(struct eth_device *dev)
{
	struct ipq_eth_dev *priv = dev->priv;
	u8 status = 1;
	struct phy_ops *phy_get_ops;
	fal_port_speed_t speed;
	fal_port_duplex_t duplex;
	char *lstatus[] = {"up", "Down"};
	char *dp[] = {"Half", "Full"};
	int speed_clock1 = 0, speed_clock2 = 0;
	int mode = PORT_WRAPPER_SGMII0_RGMII4;
	uint32_t phy_mode = 0x70;

	phy_get_ops = priv->ops;

	if (priv->ipq_swith) {
		speed_clock1 = 1;
		speed_clock2 = 0;
		status = ipq5018_s17c_Link_Update(priv);
	}

	if (priv->sfp_tx_gpio || phy_get_ops) {
		if (phy_get_ops &&
		    phy_get_ops->phy_get_link_status != NULL &&
		    phy_get_ops->phy_get_speed != NULL &&
		    phy_get_ops->phy_get_duplex != NULL){

			status = phy_get_ops->phy_get_link_status(priv->mac_unit,
				 priv->phy_address);
			phy_get_ops->phy_get_speed(priv->mac_unit,
				 priv->phy_address, &speed);
			phy_get_ops->phy_get_duplex(priv->mac_unit,
				 priv->phy_address, &duplex);
		}

		if (priv->sfp_tx_gpio) {
			mode = priv->sfp_mode;
			uniphy_channel0_input_output_6_get(priv->sfp_mode,
							   priv->sfp_rx_gpio,
							   &status,
							   &speed, &duplex);
		}

		switch (speed) {
		case FAL_SPEED_10:
			speed_clock1 = 9;
			speed_clock2 = 9;
			priv->speed = MII_PORT_SELECT;
			printf ("eth%d  %s Speed :%d %s duplex\n",
					priv->mac_unit,
					lstatus[status], speed,
					dp[duplex]);
			break;
		case FAL_SPEED_100:
			priv->speed = MII_PORT_SELECT | FES_PORT_SPEED;
			speed_clock1 = 9;
			speed_clock2 = 0;
			printf ("eth%d %s Speed :%d %s duplex\n",
					priv->mac_unit,
					lstatus[status], speed,
					dp[duplex]);
			break;
		case FAL_SPEED_1000:
			priv->speed = SGMII_PORT_SELECT;
			speed_clock1 = 1;
			speed_clock2 = 0;
			if (priv->sfp_tx_gpio)
				phy_mode = 0x30;
			printf ("eth%d %s Speed :%d %s duplex\n",
					priv->mac_unit,
					lstatus[status], speed,
					dp[duplex]);
			break;
		case FAL_SPEED_2500:
			priv->speed = SGMII_PORT_SELECT;
			mode = PORT_WRAPPER_SGMII_PLUS;
			speed_clock1 = 1;
			speed_clock2 = 0;

			if (priv->sfp_tx_gpio)
				phy_mode = 0x50;
			else
				phy_mode = 0x30;
			printf ("eth%d %s Speed :%d %s duplex\n",
					priv->mac_unit,
					lstatus[status], speed,
					dp[duplex]);
			break;
		default:
			printf("Unknown speed\n");
			break;
		}
	}

	if (status) {
		/* No PHY link is alive */
		if (priv->ipq_swith == 0 && phy_get_ops == NULL)
			printf("Link status/Get speed/Get duplex not mapped\n");
		return -1;
	}

	if (priv->mac_unit){
		ppe_uniphy_mode_set(mode, phy_mode);
	} else {
		ipq5018_enable_gephy();
	}

	ipq5018_gmac0_speed_clock_set(speed_clock1, speed_clock2, priv->mac_unit);

	return 0;
}

int ipq_eth_init(struct eth_device *dev, bd_t *this)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_dma_regs *dma_reg = (struct eth_dma_regs *)priv->dma_regs_p;
	u32 data;

	if(ipq5018_phy_link_update(dev) < 0) {
		return -1;
	}

	priv->next_rx = 0;
	priv->next_tx = 0;

	ipq_mac_reset(dev);
	ipq_eth_wr_macaddr(dev);

	/* DMA, MAC configuration for Synopsys GMAC */
	ipq_eth_dma_cfg(dev);
	ipq_eth_mac_cfg(dev);
	ipq_eth_flw_cntl_cfg(dev);

	/* clear all pending interrupts if any */
	data = readl(&dma_reg->status);
	writel(data, &dma_reg->status);

	/* Setup Rx fifos and assign base address to */
	ipq_gmac_rx_desc_setup(priv);

	writel((uint)priv->desc_tx[0], &dma_reg->txdesclistaddr);
	setbits_le32(&dma_reg->opmode, (RXSTART));
	setbits_le32(&dma_reg->opmode, (TXSTART));

	return 1;
}

static int ipq_eth_send(struct eth_device *dev, void *packet, int length)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_dma_regs *dma_p = (struct eth_dma_regs *)priv->dma_regs_p;
	ipq_gmac_desc_t *txdesc = priv->desc_tx[priv->next_tx];
	int i;

	invalidate_dcache_range((unsigned long)txdesc,
		       (unsigned long)txdesc + DESC_FLUSH_SIZE);

	/* Check if the dma descriptor is still owned by DMA */
	if (ipq_gmac_owned_by_dma(txdesc)) {
		ipq_info("BUG: Tx descriptor is owned by DMA %p\n", txdesc);
		return NETDEV_TX_BUSY;
	}

	txdesc->length |= ((length <<DescSize1Shift) & DescSize1Mask);
	txdesc->status |= (DescTxFirst | DescTxLast | DescTxIntEnable);
	txdesc->buffer1 = virt_to_phys(packet);
	ipq_gmac_give_to_dma(txdesc);

	flush_dcache_range((unsigned long)txdesc,
			(unsigned long)txdesc + DESC_SIZE);

	flush_dcache_range((unsigned long)(txdesc->buffer1),
		(unsigned long)(txdesc->buffer1) + PKTSIZE_ALIGN);

	/* Start the transmission */
	writel(POLL_DATA, &dma_p->txpolldemand);

	for (i = 0; i < MAX_WAIT; i++) {

		udelay(10);

		invalidate_dcache_range((unsigned long)txdesc,
		(unsigned long)txdesc + DESC_FLUSH_SIZE);

		if (!ipq_gmac_owned_by_dma(txdesc))
			break;
	}

	if (i == MAX_WAIT) {
		ipq_info("Tx Timed out\n");
	}

	/* reset the descriptors */
	txdesc->status = (priv->next_tx == (NO_OF_TX_DESC - 1)) ?
	TxDescEndOfRing : 0;
	txdesc->status |= TxDescChain;
	txdesc->length = 0;
	txdesc->buffer1 = 0;

	priv->next_tx = (priv->next_tx + 1) % NO_OF_TX_DESC;

	txdesc->data1 = (unsigned long)priv->desc_tx[priv->next_tx];


	flush_dcache_range((unsigned long)txdesc,
			(unsigned long)txdesc + DESC_SIZE);

	return 0;
}

static int ipq_eth_recv(struct eth_device *dev)
{
	struct ipq_eth_dev *priv = dev->priv;
	struct eth_dma_regs *dma_p = (struct eth_dma_regs *)priv->dma_regs_p;
	int length = 0;
	ipq_gmac_desc_t *rxdesc = priv->desc_rx[priv->next_rx];
	uint status;

	invalidate_dcache_range((unsigned long)(priv->desc_rx[0]),
			(unsigned long)(priv->desc_rx[NO_OF_RX_DESC - 1]) +
			DESC_FLUSH_SIZE);

	for (rxdesc = priv->desc_rx[priv->next_rx];
		!ipq_gmac_owned_by_dma(rxdesc);
		rxdesc = priv->desc_rx[priv->next_rx]) {

		status = rxdesc->status;
		length = ((status & DescFrameLengthMask) >>
				DescFrameLengthShift);

		invalidate_dcache_range(
			(unsigned long)(net_rx_packets[priv->next_rx]),
			(unsigned long)(net_rx_packets[priv->next_rx]) +
			PKTSIZE_ALIGN);
		net_process_received_packet(net_rx_packets[priv->next_rx], length - 4);

		rxdesc->length = ((ETH_MAX_FRAME_LEN << DescSize1Shift) &
				   DescSize1Mask);

		rxdesc->length |= (priv->next_rx == (NO_OF_RX_DESC - 1)) ?
					RxDescEndOfRing : 0;
		rxdesc->length |= RxDescChain;

		rxdesc->buffer1 = virt_to_phys(net_rx_packets[priv->next_rx]);

		priv->next_rx = (priv->next_rx + 1) % NO_OF_RX_DESC;

		rxdesc->data1 = (unsigned long)priv->desc_rx[priv->next_rx];

		rxdesc->extstatus = 0;
		rxdesc->reserved1 = 0;
		rxdesc->timestamplow = 0;
		rxdesc->timestamphigh = 0;
		rxdesc->status = DescOwnByDma;

		flush_dcache_range((unsigned long)rxdesc,
			(unsigned long)rxdesc + DESC_SIZE);

		writel(POLL_DATA, &dma_p->rxpolldemand);
	}

	return length;
}

static void ipq_eth_halt(struct eth_device *dev)
{
	if (dev->state != ETH_STATE_ACTIVE)
		return;
	/* reset the mac */
	ipq_mac_reset(dev);
}

static int QCA8337_switch_init(ipq_gmac_board_cfg_t *gmac_cfg)
{
	for (int port = 0;
		port < gmac_cfg->switch_port_count;
		++port) {
		u32 phy_val;
		/* phy powerdown */
		ipq_mdio_write(
			gmac_cfg->switch_port_phy_address[port],
			0x0,
			0x0800
			);
		phy_val = ipq_mdio_read(
				gmac_cfg->switch_port_phy_address[port],
				0x3d,
				NULL
				);
		phy_val &= ~0x0040;
		ipq_mdio_write(
			gmac_cfg->switch_port_phy_address[port],
			0x3d,
			phy_val
			);
		/*
		* PHY will stop the tx clock for a while when link is down
		* en_anychange  debug port 0xb bit13 = 0  //speed up link down tx_clk
		* sel_rst_80us  debug port 0xb bit10 = 0  //speed up speed mode change to 2'b10 tx_clk
		*/
		phy_val = ipq_mdio_read(
				gmac_cfg->switch_port_phy_address[port],
				0xb,
				NULL
				);
		phy_val &= ~0x2400;
		ipq_mdio_write(
			gmac_cfg->switch_port_phy_address[port],
			0xb,
			phy_val
			);
		mdelay(100);
	}
	if (ipq_athrs17_init(gmac_cfg) != 0){
		printf("QCA_8337 switch init failed \n");
		return 0;
	}
	for (int port = 0;
		port < gmac_cfg->switch_port_count;
		++port) {
		ipq_mdio_write(
			gmac_cfg->switch_port_phy_address[port],
			MII_ADVERTISE,
			ADVERTISE_ALL | ADVERTISE_PAUSE_CAP | ADVERTISE_PAUSE_ASYM
			);
		/* phy reg 0x9, b10,1 = Prefer multi-port device (master) */
		ipq_mdio_write(
			gmac_cfg->switch_port_phy_address[port],
			MII_CTRL1000,
			(0x0400|ADVERTISE_1000FULL)
			);
		ipq_mdio_write(
			gmac_cfg->switch_port_phy_address[port],
			MII_BMCR,
			BMCR_RESET | BMCR_ANENABLE
			);
		mdelay(100);
	}
	return 1;
}

static void gephy_mdac_edac_config(ipq_gmac_board_cfg_t *gmac_cfg)
{
	uint16_t phy_data;
	uint32_t phy_dac = PHY_DAC(0x10);
	uint32_t C45_id = QCA808X_REG_C45_ADDRESS(MPGE_PHY_MMD1_NUM,
				MPGE_PHY_MMD1_DAC);
	/*set mdac value*/
	phy_data = ipq5018_mdio_read(
			gmac_cfg->phy_addr,
			C45_id,
			NULL
			);
	phy_data &= ~(MPGE_PHY_MMD1_DAC_MASK);
	ipq5018_mdio_write(
		gmac_cfg->phy_addr,
		C45_id,
		(phy_data | phy_dac)
		);
	mdelay(1);
	/*
	|| set edac value debug register write follows indirect
	|| adressing so first write address in port address and
	|| write value in data register
	*/
	ipq5018_mdio_write(gmac_cfg->phy_addr,
			QCA808X_DEBUG_PORT_ADDRESS,
			MPGE_PHY_DEBUG_EDAC);
	phy_data = ipq5018_mdio_read(
			gmac_cfg->phy_addr,
			QCA808X_DEBUG_PORT_DATA,
			NULL);

	phy_data &= ~(MPGE_PHY_MMD1_DAC_MASK);

	ipq5018_mdio_write(gmac_cfg->phy_addr,
			QCA808X_DEBUG_PORT_ADDRESS,
			MPGE_PHY_DEBUG_EDAC);
	ipq5018_mdio_write(gmac_cfg->phy_addr,
			QCA808X_DEBUG_PORT_DATA,
			(phy_data | phy_dac));
	mdelay(1);
}

static void mdio_init(void)
{
	if(ipq5018_sw_mdio_init("IPQ MDIO0"))
		printf("MDIO Failed to init for GMAC0\n");

	if(ipq_sw_mdio_init("IPQ MDIO1"))
		printf("MDIO Failed to init for GMAC1\n");
}

int ipq_gmac_init(ipq_gmac_board_cfg_t *gmac_cfg)
{
	struct eth_device *dev[CONFIG_IPQ_NO_MACS];
	uchar enet_addr[CONFIG_IPQ_NO_MACS * 6];
	int i;
	uint32_t phy_chip_id, phy_chip_id1, phy_chip_id2;
	uint32_t phy_mode = 0x70;
	int ret;

	memset(enet_addr, 0, sizeof(enet_addr));

	/* Mdio init */
	mdio_init();

	/* Getting the MAC address from ART partition */
	ret = get_eth_mac_address(enet_addr, CONFIG_IPQ_NO_MACS);

	for (i = 0; gmac_cfg_is_valid(gmac_cfg); gmac_cfg++, i++) {

		dev[i] = malloc(sizeof(struct eth_device));
		if (dev[i] == NULL)
			goto init_failed;

		ipq_gmac_macs[i] = malloc(sizeof(struct ipq_eth_dev));
		if (ipq_gmac_macs[i] == NULL)
			goto init_failed;

		memset(dev[i], 0, sizeof(struct eth_device));
		memset(ipq_gmac_macs[i], 0, sizeof(struct ipq_eth_dev));

		dev[i]->iobase = gmac_cfg->base;
		dev[i]->init = ipq_eth_init;
		dev[i]->halt = ipq_eth_halt;
		dev[i]->recv = ipq_eth_recv;
		dev[i]->send = ipq_eth_send;
		dev[i]->write_hwaddr = ipq_eth_wr_macaddr;
		dev[i]->priv = (void *) ipq_gmac_macs[i];
		/*
		 * Setting the Default MAC address
		 * if the MAC read from ART partition is invalid
		 */
		if ((ret < 0) ||
			(!is_valid_ethaddr(&enet_addr[i * 6]))) {
				memcpy(&dev[i]->enetaddr[0], ipq_def_enetaddr, 6);
				dev[i]->enetaddr[5] = dev[i]->enetaddr[5] +  i;
		} else {
			memcpy(&dev[i]->enetaddr[0], &enet_addr[i * 6], 6);
		}

		ipq_info("MAC%x addr:%x:%x:%x:%x:%x:%x\n",
			gmac_cfg->unit, dev[i]->enetaddr[0],
			dev[i]->enetaddr[1],
			dev[i]->enetaddr[2],
			dev[i]->enetaddr[3],
			dev[i]->enetaddr[4],
			dev[i]->enetaddr[5]);

		snprintf(dev[i]->name, sizeof(dev[i]->name), "eth%d", i);

		ipq_gmac_macs[i]->dev = dev[i];
		ipq_gmac_macs[i]->mac_unit = gmac_cfg->unit;
		ipq_gmac_macs[i]->mac_regs_p =
			(struct eth_mac_regs *)(gmac_cfg->base);
		ipq_gmac_macs[i]->dma_regs_p =
			(struct eth_dma_regs *)(gmac_cfg->base + DW_DMA_BASE_OFFSET);
		ipq_gmac_macs[i]->phy_address = gmac_cfg->phy_addr;
		ipq_gmac_macs[i]->gmac_board_cfg = gmac_cfg;
		ipq_gmac_macs[i]->interface = gmac_cfg->phy_interface_mode;
		ipq_gmac_macs[i]->phy_type = gmac_cfg->phy_type;
		ipq_gmac_macs[i]->phy_external_link = gmac_cfg->phy_external_link;
		ipq_gmac_macs[i]->sfp_tx_gpio = gmac_cfg->sfp_tx_gpio;
		ipq_gmac_macs[i]->sfp_rx_gpio = gmac_cfg->sfp_rx_gpio;
		ipq_gmac_macs[i]->sfp_mode = gmac_cfg->sfp_mode;

		if (gmac_cfg->sfp_mode == PORT_WRAPPER_SGMII_PLUS)
			phy_mode = 0x50;
		else if (gmac_cfg->sfp_mode == PORT_WRAPPER_SGMII_FIBER)
			phy_mode = 0x30;

		snprintf((char *)ipq_gmac_macs[i]->phy_name,
				sizeof(ipq_gmac_macs[i]->phy_name), "IPQ MDIO%d", i);

		if (gmac_cfg->unit){
			phy_chip_id1 = ipq_mdio_read(
					ipq_gmac_macs[i]->phy_address,
					QCA_PHY_ID1,
					NULL);
			phy_chip_id2 = ipq_mdio_read(
					ipq_gmac_macs[i]->phy_address,
					QCA_PHY_ID2,
					NULL);
			phy_chip_id = (phy_chip_id1 << 16) | phy_chip_id2;
		} else {
			phy_chip_id1 = ipq5018_mdio_read(
					ipq_gmac_macs[i]->phy_address,
					QCA_PHY_ID1,
					NULL);
			phy_chip_id2 = ipq5018_mdio_read(
					ipq_gmac_macs[i]->phy_address,
					QCA_PHY_ID2,
					NULL);
			phy_chip_id = (phy_chip_id1 << 16) | phy_chip_id2;
		}
		switch(phy_chip_id) {
#ifdef CONFIG_QCA8081_PHY
			/* NAPA PHY For GMAC1 */
			case QCA8081_PHY:
			case QCA8081_1_1_PHY:
				ipq_gmac_macs[i]->phy_type = QCA8081_1_1_PHY;
				ipq_qca8081_phy_init(
					&ipq_gmac_macs[i]->ops,
					ipq_gmac_macs[i]->phy_address);
				break;
#endif
			/* Internel GEPHY only for GMAC0 */
			case GEPHY:
				ipq_gmac_macs[i]->phy_type = GEPHY;
				ipq_gephy_phy_init(
					&ipq_gmac_macs[i]->ops,
					ipq_gmac_macs[i]->phy_address);
				if(ipq_gmac_macs[i]->phy_external_link)
					gephy_mdac_edac_config(gmac_cfg);
				break;
#ifdef CONFIG_QCA8033_PHY
			/* 1G PHY */
			case QCA8033_PHY:
				ipq_gmac_macs[i]->phy_type = QCA8033_PHY;
				ipq_qca8033_phy_init(
					&ipq_gmac_macs[i]->ops,
					ipq_gmac_macs[i]->phy_address);
				break;
#endif
			case QCA_8337:
				if(gmac_cfg->ipq_swith){
					ipq_gmac_macs[i]->ipq_swith =
						QCA8337_switch_init(gmac_cfg);
				}
				break;
			default:
				if (gmac_cfg->sfp_tx_gpio) {
					ppe_uniphy_mode_set(gmac_cfg->sfp_mode,
							    phy_mode);
				} else {
					printf("GMAC%d:Invalid PHY ID \n", i);
				}
				break;
		}
		/* Initialize 8337 switch */
		if (gmac_cfg->ipq_swith &&
			ipq_gmac_macs[i]->phy_external_link &&
			!ipq_gmac_macs[i]->ipq_swith){
			ipq_gmac_macs[i]->ipq_swith =
				QCA8337_switch_init(gmac_cfg);
		}
		/* Tx/Rx Descriptor initialization */
		if (ipq_gmac_tx_rx_desc_ring(dev[i]->priv) == -1)
			goto init_failed;

		eth_register(dev[i]);
	}
	return 0;

init_failed:
	for (i = 0; i < IPQ5018_GMAC_PORT; i++) {
		if (dev[i]) {
			free(dev[i]);
		}
		if (ipq_gmac_macs[i])
			free(ipq_gmac_macs[i]);
	}

	return -ENOMEM;
}

