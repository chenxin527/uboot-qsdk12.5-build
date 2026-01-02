/*
 **************************************************************************
 * Copyright (c) 2016-2019, 2021, The Linux Foundation. All rights reserved.
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
 **************************************************************************
*/

#include <common.h>
#include <asm/global_data.h>
#include "ipq9574_ppe.h"
#include "ipq9574_uniphy.h"
#include <fdtdec.h>
#include "ipq_phy.h"

DECLARE_GLOBAL_DATA_PTR;
#ifdef DEBUG
#define pr_debug(fmt, args...) printf(fmt, ##args);
#else
#define pr_debug(fmt, args...)
#endif

#define pr_info(fmt, args...) printf(fmt, ##args);

int uniphy_force_mode;

extern int is_uniphy_enabled(int uniphy_index);
extern void uniphy_port5_clock_source_set(void);

/*
 * ipq9574_ppe_reg_read()
 */
static inline void ipq9574_ppe_reg_read(u32 reg, u32 *val)
{
	*val = readl((void *)(IPQ9574_PPE_BASE_ADDR + reg));
}

/*
 * ipq9574_ppe_reg_write()
 */
static inline void ipq9574_ppe_reg_write(u32 reg, u32 val)
{
	writel(val, (void *)(IPQ9574_PPE_BASE_ADDR + reg));
}

void ppe_ipo_rule_reg_set(union ipo_rule_reg_u *hw_reg, int rule_id)
{
	int i;

	for (i = 0; i < 3; i++) {
		ipq9574_ppe_reg_write(IPO_CSR_BASE_ADDR + IPO_RULE_REG_ADDRESS +
			(rule_id * IPO_RULE_REG_INC) + (i * 4), hw_reg->val[i]);
	}
}

void ppe_ipo_mask_reg_set(union ipo_mask_reg_u *hw_mask, int rule_id)
{
	int i;

	for (i = 0; i < 2; i++) {
		ipq9574_ppe_reg_write((IPO_CSR_BASE_ADDR + IPO_MASK_REG_ADDRESS +
			(rule_id * IPO_MASK_REG_INC) + (i * 4)), hw_mask->val[i]);
	}
}

void ppe_ipo_action_set(union ipo_action_u *hw_act, int rule_id)
{
	int i;

	for (i = 0; i < 5; i++) {
		ipq9574_ppe_reg_write((IPE_L2_BASE_ADDR + IPO_ACTION_ADDRESS +
			(rule_id * IPO_ACTION_INC) + (i * 4)), hw_act->val[i]);
	}
}

void ipq9574_ppe_acl_set(int rule_id, int rule_type, int field0, int field1, int mask, int permit, int deny)
{
	union ipo_rule_reg_u hw_reg = {0};
	union ipo_mask_reg_u hw_mask = {0};
	union ipo_action_u hw_act = {0};

	memset(&hw_reg, 0, sizeof(hw_reg));
	memset(&hw_mask, 0, sizeof(hw_mask));
	memset(&hw_act, 0, sizeof(hw_act));

	if (rule_id < MAX_RULE) {
		hw_act.bf.dest_info_change_en = 1;
		hw_mask.bf.maskfield_0 = mask;
		hw_reg.bf.rule_type = rule_type;
		if (rule_type == ADPT_ACL_HPPE_IPV4_DIP_RULE) {
			hw_reg.bf.rule_field_0 = field1;
			hw_reg.bf.rule_field_1 = field0<<17;
			hw_mask.bf.maskfield_1 = 7<<17;
			if (permit == 0x0) {
				hw_act.bf.fwd_cmd = 0;/* forward */
				hw_reg.bf.pri = 0x1;
			}
			if (deny == 0x1) {
				hw_act.bf.fwd_cmd = 1;/* drop */
				hw_reg.bf.pri = 0x0;
			}
		} else if (rule_type == ADPT_ACL_HPPE_MAC_SA_RULE) {
			/* src mac AC rule */
			hw_reg.bf.rule_field_0 = field1;
			hw_reg.bf.rule_field_1 = field0;
			hw_mask.bf.maskfield_1 = 0xffff;
			hw_act.bf.fwd_cmd = 1;/* drop */
			hw_reg.bf.pri = 0x2;
			/* bypass fdb lean and fdb freash */
			hw_act.bf.bypass_bitmap_0 = 0x1800;
		} else if (rule_type == ADPT_ACL_HPPE_MAC_DA_RULE) {
			/* dest mac AC rule */
			hw_reg.bf.rule_field_0 = field1;
			hw_reg.bf.rule_field_1 = field0;
			hw_mask.bf.maskfield_1 = 0xffff;
			hw_act.bf.fwd_cmd = 1;/* drop */
			hw_reg.bf.pri = 0x2;
		}
		/* bind port1-port6 */
		hw_reg.bf.src_0 = 0x0;
		hw_reg.bf.src_1 = 0x3F;
		ppe_ipo_rule_reg_set(&hw_reg, rule_id);
		ppe_ipo_mask_reg_set(&hw_mask, rule_id);
		ppe_ipo_action_set(&hw_act, rule_id);
	}
}

/*
 * ipq9574_ppe_vp_port_tbl_set()
 */
static void ipq9574_ppe_vp_port_tbl_set(int port, int vsi)
{
	u32 addr = IPQ9574_PPE_L3_VP_PORT_TBL_ADDR +
		 (port * IPQ9574_PPE_L3_VP_PORT_TBL_INC);
	ipq9574_ppe_reg_write(addr, 0x0);
	ipq9574_ppe_reg_write(addr + 0x4 , 1 << 9 | vsi << 10);
	ipq9574_ppe_reg_write(addr + 0x8, 0x0);
	ipq9574_ppe_reg_write(addr + 0xc, 0x0);
}

/*
 * ipq9574_ppe_ucast_queue_map_tbl_queue_id_set()
 */
static void ipq9574_ppe_ucast_queue_map_tbl_queue_id_set(int queue, int port)
{
	uint32_t val;

	ipq9574_ppe_reg_read(IPQ9574_PPE_QM_UQM_TBL +
		 (port * IPQ9574_PPE_UCAST_QUEUE_MAP_TBL_INC), &val);

	val |= queue << 4;

	ipq9574_ppe_reg_write(IPQ9574_PPE_QM_UQM_TBL +
		 (port * IPQ9574_PPE_UCAST_QUEUE_MAP_TBL_INC), val);
}

/*
 * ipq9574_vsi_setup()
 */
static void ipq9574_vsi_setup(int vsi, uint8_t group_mask)
{
	uint32_t val = (group_mask << 24 | group_mask << 16 | group_mask << 8
							    | group_mask);

	/* Set mask */
	ipq9574_ppe_reg_write(0x063800 + (vsi * 0x10), val);

	/*  new addr lrn en | station move lrn en */
	ipq9574_ppe_reg_write(0x063804 + (vsi * 0x10), 0x9);
}

/*
 * ipq9574_gmac_port_disable()
 */
void ipq9574_gmac_port_disable(int port)
{
	ipq9574_ppe_reg_write(IPQ9574_PPE_MAC_ENABLE + (0x200 * port), 0x70);
	ipq9574_ppe_reg_write(IPQ9574_PPE_MAC_SPEED + (0x200 * port), 0x2);
	ipq9574_ppe_reg_write(IPQ9574_PPE_MAC_MIB_CTL + (0x200 * port), 0x1);
}

/*
 * ppe_port_bridge_txmac_set()
 * TXMAC should be disabled for all ports by default
 * TXMAC should be enabled for all ports that are link up alone
 */
void ppe_port_bridge_txmac_set(int port_id, int status)
{
	uint32_t reg_value = 0;

	ipq9574_ppe_reg_read(IPE_L2_BASE_ADDR + PORT_BRIDGE_CTRL_ADDRESS +
		 (port_id * PORT_BRIDGE_CTRL_INC), &reg_value);
	if (status == 0)
		reg_value |= TX_MAC_EN;
	else
		reg_value &= ~TX_MAC_EN;

	ipq9574_ppe_reg_write(IPE_L2_BASE_ADDR + PORT_BRIDGE_CTRL_ADDRESS +
		 (port_id * PORT_BRIDGE_CTRL_INC), reg_value);

}

/*
 * ipq9574_port_mac_clock_reset()
 */
void ipq9574_port_mac_clock_reset(int port)
{
	int reg_val, reg_val1;

	reg_val = readl(NSS_CC_PPE_RESET_ADDR);
	reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
	switch(port) {
		case 0:
			/* Assert */
			reg_val |= GCC_PPE_PORT1_MAC_ARES;
			reg_val1 |= GCC_PORT1_ARES;
			writel(reg_val, NSS_CC_PPE_RESET_ADDR);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			mdelay(150);
			/* De-Assert */
			reg_val = readl(NSS_CC_PPE_RESET_ADDR);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			reg_val &= ~GCC_PPE_PORT1_MAC_ARES;
			reg_val1 &= ~GCC_PORT1_ARES;
			break;
		case 1:
			/* Assert */
			reg_val |= GCC_PPE_PORT2_MAC_ARES;
			reg_val1 |= GCC_PORT2_ARES;
			writel(reg_val, NSS_CC_PPE_RESET_ADDR);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			mdelay(150);
			/* De-Assert */
			reg_val = readl(NSS_CC_PPE_RESET_ADDR);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			reg_val &= ~GCC_PPE_PORT2_MAC_ARES;
			reg_val1 &= ~GCC_PORT2_ARES;
			break;
		case 2:
			/* Assert */
			reg_val |= GCC_PPE_PORT3_MAC_ARES;
			reg_val1 |= GCC_PORT3_ARES;
			writel(reg_val, NSS_CC_PPE_RESET_ADDR);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			mdelay(150);
			/* De-Assert */
			reg_val = readl(NSS_CC_PPE_RESET_ADDR);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			reg_val &= ~GCC_PPE_PORT3_MAC_ARES;
			reg_val1 &= ~GCC_PORT3_ARES;
			break;
		case 3:
			/* Assert */
			reg_val |= GCC_PPE_PORT4_MAC_ARES;
			reg_val1 |= GCC_PORT4_ARES;
			writel(reg_val, NSS_CC_PPE_RESET_ADDR);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			mdelay(150);
			/* De-Assert */
			reg_val = readl(NSS_CC_PPE_RESET_ADDR);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			reg_val &= ~GCC_PPE_PORT4_MAC_ARES;
			reg_val1 &= ~GCC_PORT4_ARES;
			break;
		case 4:
			/* Assert */
			reg_val |= GCC_PPE_PORT5_MAC_ARES;
			reg_val1 |= GCC_PORT5_ARES;
			writel(reg_val, NSS_CC_PPE_RESET_ADDR);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			mdelay(150);
			/* De-Assert */
			reg_val = readl(NSS_CC_PPE_RESET_ADDR);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			reg_val &= ~GCC_PPE_PORT5_MAC_ARES;
			reg_val1 &= ~GCC_PORT5_ARES;
			break;
		case 5:
			/* Assert */
			reg_val |= GCC_PPE_PORT6_MAC_ARES;
			reg_val1 |= GCC_PORT6_ARES;
			writel(reg_val, NSS_CC_PPE_RESET_ADDR);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			mdelay(150);
			/* De-Assert */
			reg_val = readl(NSS_CC_PPE_RESET_ADDR);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			reg_val &= ~GCC_PPE_PORT6_MAC_ARES;
			reg_val1 &= ~GCC_PORT6_ARES;
			break;
		default:
			break;
	}
	writel(reg_val, NSS_CC_PPE_RESET_ADDR);
	writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
	mdelay(150);
}

void ipq9574_speed_clock_set(int port_id, int clk[4])
{
	int i;
	int reg_val[6];

	for (i = 0; i < 6; i++)
	{
		reg_val[i] = readl(NSS_CC_PORT1_RX_CMD_RCGR + (i * 0x4) + (port_id * 0x18));
	}
	reg_val[0] &= ~0x1;
	reg_val[1] &= ~0x71f;
	reg_val[2] &= ~0x1ff;
	reg_val[3] &= ~0x1;
	reg_val[4] &= ~0x71f;
	reg_val[5] &= ~0x1ff;

	reg_val[1] |= clk[0];
	reg_val[2] |= clk[1];
	reg_val[4] |= clk[2];
	reg_val[5] |= clk[3];

	/* Port Rx direction speed clock cfg */
	writel(reg_val[1], NSS_CC_PORT1_RX_CMD_RCGR + 0x4 + (port_id * 0x18));
	writel(reg_val[2], NSS_CC_PORT1_RX_CMD_RCGR + 0x8 + (port_id * 0x18));
	writel(reg_val[0] | 0x1 , NSS_CC_PORT1_RX_CMD_RCGR + (port_id * 0x18));
	/* Port Tx direction speed clock cfg */
	writel(reg_val[4], NSS_CC_PORT1_RX_CMD_RCGR + 0x10 + (port_id * 0x18));
	writel(reg_val[5], NSS_CC_PORT1_RX_CMD_RCGR + 0x14 + (port_id * 0x18));
	writel(reg_val[3] | 0x1, NSS_CC_PORT1_RX_CMD_RCGR + 0xc + (port_id * 0x18));
}

int phy_status_get_from_ppe(int port_id)
{
	uint32_t reg_field = 0;

	if (port_id == 0) {
		ipq9574_ppe_reg_read(PORT_PHY_STATUS0_ADDRESS, &reg_field);
	} else {
		ipq9574_ppe_reg_read(PORT_PHY_STATUS_ADDRESS, &reg_field);

		if (port_id == (PORT5 - PPE_UNIPHY_INSTANCE1))
			reg_field >>= PORT_PHY_STATUS_PORT5_1_OFFSET;
		else
			reg_field >>= PORT_PHY_STATUS_PORT6_OFFSET;
	}

	return ((reg_field >> 7) & 0x1) ? 0 : 1;
}

void ppe_xgmac_speed_set(uint32_t port, int speed)
{
	uint32_t reg_value = 0;

	pr_debug("\nDEBUGGING xgmac_speed_set......... PORTID = %d\n", port);
	ipq9574_ppe_reg_read(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
		 (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION), &reg_value);

	switch(speed) {
	case 0:
	case 1:
	case 2:
		reg_value &=~USS;
		reg_value |=SS(XGMAC_SPEED_SELECT_1000M);
		break;
	case 3:
		reg_value |=USS;
		reg_value |=SS(XGMAC_SPEED_SELECT_10000M);
		break;
	case 4:
		reg_value |=USS;
		reg_value |=SS(XGMAC_SPEED_SELECT_2500M);
		break;
	case 5:
		reg_value |=USS;
		reg_value |=SS(XGMAC_SPEED_SELECT_5000M);
		break;
	}
	reg_value |=JD;
	ipq9574_ppe_reg_write(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
		 (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION), reg_value);
	pr_debug("NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION Address = 0x%x -> Value = %u\n",
	      PPE_SWITCH_NSS_SWITCH_XGMAC0 + (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION),
	      reg_value);

}

void ppe_xgmac_10g_r_speed_set(uint32_t port)
{
	uint32_t reg_value = 0;

	pr_debug("DEBUGGING 10g_r_speed_set......... PORTID = %d\n", port);
	ipq9574_ppe_reg_read(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
		 (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION), &reg_value);

	reg_value |=JD;
	ipq9574_ppe_reg_write(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
		 (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION), reg_value);

	pr_debug("NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION Address = 0x%x -> Value = %u\n",
	      PPE_SWITCH_NSS_SWITCH_XGMAC0 + (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION),
	      reg_value);
}

void ppe_port_txmac_status_set(uint32_t port)
{
	uint32_t reg_value = 0;

	pr_debug("DEBUGGING txmac_status_set......... PORTID = %d\n", port);
	ipq9574_ppe_reg_read(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
		 (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION), &reg_value);

	reg_value |=TE;
	ipq9574_ppe_reg_write(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
		 (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION), reg_value);

	pr_debug("NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION Address = 0x%x -> Value = %u\n",
	      PPE_SWITCH_NSS_SWITCH_XGMAC0 + (port * NSS_SWITCH_XGMAC_MAC_TX_CONFIGURATION),
	      reg_value);
}

void ppe_port_rxmac_status_set(uint32_t port)
{
	uint32_t reg_value = 0;

	pr_debug("DEBUGGING rxmac_status_set......... PORTID = %d\n", port);
	ipq9574_ppe_reg_read(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
			MAC_RX_CONFIGURATION_ADDRESS +
			(port * NSS_SWITCH_XGMAC_MAC_RX_CONFIGURATION), &reg_value);

	reg_value |= 0x300000c0;
	reg_value |=RE;
	reg_value |=ACS;
	reg_value |=CST;
	ipq9574_ppe_reg_write(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
			MAC_RX_CONFIGURATION_ADDRESS +
			(port * NSS_SWITCH_XGMAC_MAC_RX_CONFIGURATION), reg_value);

	pr_debug("NSS_SWITCH_XGMAC_MAC_RX_CONFIGURATION Address = 0x%x -> Value = %u\n",
	      PPE_SWITCH_NSS_SWITCH_XGMAC0 + MAC_RX_CONFIGURATION_ADDRESS +
	      (port * NSS_SWITCH_XGMAC_MAC_RX_CONFIGURATION),
	      reg_value);
}

void ppe_mac_packet_filter_set(uint32_t port)
{
	pr_debug("DEBUGGING mac_packet_filter_set......... PORTID = %d\n", port);
	ipq9574_ppe_reg_write(PPE_SWITCH_NSS_SWITCH_XGMAC0 +
			MAC_PACKET_FILTER_ADDRESS +
			(port * MAC_PACKET_FILTER_INC), 0x80000081);
	pr_debug("NSS_SWITCH_XGMAC_MAC_PACKET_FILTER Address = 0x%x -> Value = %u\n",
	      PPE_SWITCH_NSS_SWITCH_XGMAC0 + MAC_PACKET_FILTER_ADDRESS +
	      (port * MAC_PACKET_FILTER_ADDRESS),
	      0x80000081);
}

void ipq9574_10g_r_speed_set(int port, int status)
{
	ppe_xgmac_10g_r_speed_set(port);
	ppe_port_bridge_txmac_set(port + 1, status);
	ppe_port_txmac_status_set(port);
	ppe_port_rxmac_status_set(port);
	ppe_mac_packet_filter_set(port);
}

void ipq9574_uxsgmii_speed_set(int port, int speed, int duplex,
				int status)
{
	uint32_t uniphy_index = 0;

	switch(port) {
	case 0:
	case 1:
	case 2:
	case 3:
		uniphy_index = PPE_UNIPHY_INSTANCE0;
	break;
	case 4:
		uniphy_index = PPE_UNIPHY_INSTANCE1;
	break;
	case 5:
		uniphy_index = PPE_UNIPHY_INSTANCE2;
	break;
	default:
		printf("Invalid port id , using UNIPHY0 as default \n");
	break;
	}

	ppe_uniphy_usxgmii_autoneg_completed(uniphy_index);
	ppe_uniphy_usxgmii_speed_set(uniphy_index, port + 1, speed);
	ppe_xgmac_speed_set(port, speed);
	ppe_uniphy_usxgmii_duplex_set(uniphy_index, duplex);
	ppe_uniphy_usxgmii_port_reset(uniphy_index);
	ppe_port_bridge_txmac_set(port + 1, status);
	ppe_port_txmac_status_set(port);
	ppe_port_rxmac_status_set(port);
	ppe_mac_packet_filter_set(port);
}

void ipq9574_pqsgmii_speed_set(int port, int speed, int status)
{
	ppe_port_bridge_txmac_set(port + 1, status);
	ipq9574_ppe_reg_write(IPQ9574_PPE_MAC_SPEED + (0x200 * port), speed);
	ipq9574_ppe_reg_write(IPQ9574_PPE_MAC_ENABLE + (0x200 * port), 0x73);
	ipq9574_ppe_reg_write(IPQ9574_PPE_MAC_MIB_CTL + (0x200 * port), 0x1);
}

/*
 * ipq9574_ppe_flow_port_map_tbl_port_num_set()
 */
static void ipq9574_ppe_flow_port_map_tbl_port_num_set(int queue, int port)
{
	ipq9574_ppe_reg_write(IPQ9574_PPE_L0_FLOW_PORT_MAP_TBL +
			queue * IPQ9574_PPE_L0_FLOW_PORT_MAP_TBL_INC, port);
	ipq9574_ppe_reg_write(IPQ9574_PPE_L1_FLOW_PORT_MAP_TBL +
			port * IPQ9574_PPE_L1_FLOW_PORT_MAP_TBL_INC, port);
}

/*
 * ipq9574_ppe_flow_map_tbl_set()
 */
static void ipq9574_ppe_flow_map_tbl_set(int queue, int port)
{
	uint32_t val = port | 0x401000; /* c_drr_wt = 1, e_drr_wt = 1 */
	ipq9574_ppe_reg_write(IPQ9574_PPE_L0_FLOW_MAP_TBL + queue * IPQ9574_PPE_L0_FLOW_MAP_TBL_INC,
									val);

	val = port | 0x100400; /* c_drr_wt = 1, e_drr_wt = 1 */
	ipq9574_ppe_reg_write(IPQ9574_PPE_L1_FLOW_MAP_TBL + port * IPQ9574_PPE_L1_FLOW_MAP_TBL_INC,
									val);
}

/*
 * ipq9574_ppe_tdm_configuration
 */
static void ipq9574_ppe_tdm_configuration(void)
{
	ipq9574_ppe_reg_write(0xc000, 0x26);
	ipq9574_ppe_reg_write(0xc010, 0x34);
	ipq9574_ppe_reg_write(0xc020, 0x25);
	ipq9574_ppe_reg_write(0xc030, 0x30);
	ipq9574_ppe_reg_write(0xc040, 0x21);
	ipq9574_ppe_reg_write(0xc050, 0x36);
	ipq9574_ppe_reg_write(0xc060, 0x20);
	ipq9574_ppe_reg_write(0xc070, 0x35);
	ipq9574_ppe_reg_write(0xc080, 0x26);
	ipq9574_ppe_reg_write(0xc090, 0x31);
	ipq9574_ppe_reg_write(0xc0a0, 0x22);
	ipq9574_ppe_reg_write(0xc0b0, 0x36);
	ipq9574_ppe_reg_write(0xc0c0, 0x27);
	ipq9574_ppe_reg_write(0xc0d0, 0x30);
	ipq9574_ppe_reg_write(0xc0e0, 0x25);
	ipq9574_ppe_reg_write(0xc0f0, 0x32);
	ipq9574_ppe_reg_write(0xc100, 0x26);
	ipq9574_ppe_reg_write(0xc110, 0x36);
	ipq9574_ppe_reg_write(0xc120, 0x20);
	ipq9574_ppe_reg_write(0xc130, 0x37);
	ipq9574_ppe_reg_write(0xc140, 0x24);
	ipq9574_ppe_reg_write(0xc150, 0x30);
	ipq9574_ppe_reg_write(0xc160, 0x23);
	ipq9574_ppe_reg_write(0xc170, 0x36);
	ipq9574_ppe_reg_write(0xc180, 0x26);
	ipq9574_ppe_reg_write(0xc190, 0x34);
	ipq9574_ppe_reg_write(0xc1a0, 0x25);
	ipq9574_ppe_reg_write(0xc1b0, 0x33);
	ipq9574_ppe_reg_write(0xc1c0, 0x20);
	ipq9574_ppe_reg_write(0xc1d0, 0x36);
	ipq9574_ppe_reg_write(0xc1e0, 0x21);
	ipq9574_ppe_reg_write(0xc1f0, 0x35);
	ipq9574_ppe_reg_write(0xc200, 0x26);
	ipq9574_ppe_reg_write(0xc210, 0x30);
	ipq9574_ppe_reg_write(0xc220, 0x27);
	ipq9574_ppe_reg_write(0xc230, 0x31);
	ipq9574_ppe_reg_write(0xc240, 0x20);
	ipq9574_ppe_reg_write(0xc250, 0x36);
	ipq9574_ppe_reg_write(0xc260, 0x25);
	ipq9574_ppe_reg_write(0xc270, 0x37);
	ipq9574_ppe_reg_write(0xc280, 0x26);
	ipq9574_ppe_reg_write(0xc290, 0x30);
	ipq9574_ppe_reg_write(0xc2a0, 0x22);
	ipq9574_ppe_reg_write(0xc2b0, 0x35);
	ipq9574_ppe_reg_write(0xc2c0, 0x20);
	ipq9574_ppe_reg_write(0xc2d0, 0x36);
	ipq9574_ppe_reg_write(0xc2e0, 0x23);
	ipq9574_ppe_reg_write(0xc2f0, 0x32);
	ipq9574_ppe_reg_write(0xc300, 0x26);
	ipq9574_ppe_reg_write(0xc310, 0x30);
	ipq9574_ppe_reg_write(0xc320, 0x25);
	ipq9574_ppe_reg_write(0xc330, 0x33);
	ipq9574_ppe_reg_write(0xc340, 0x20);
	ipq9574_ppe_reg_write(0xc350, 0x36);
	ipq9574_ppe_reg_write(0xc360, 0x27);
	ipq9574_ppe_reg_write(0xc370, 0x35);
	ipq9574_ppe_reg_write(0xc380, 0x26);
	ipq9574_ppe_reg_write(0xc390, 0x30);
	ipq9574_ppe_reg_write(0xc3a0, 0x24);
	ipq9574_ppe_reg_write(0xc3b0, 0x37);
	ipq9574_ppe_reg_write(0xc3c0, 0x20);
	ipq9574_ppe_reg_write(0xc3d0, 0x36);
	ipq9574_ppe_reg_write(0xc3e0, 0x25);
	ipq9574_ppe_reg_write(0xc3f0, 0x34);
	ipq9574_ppe_reg_write(0xc400, 0x26);
	ipq9574_ppe_reg_write(0xc410, 0x30);
	ipq9574_ppe_reg_write(0xc420, 0x21);
	ipq9574_ppe_reg_write(0xc430, 0x35);
	ipq9574_ppe_reg_write(0xc440, 0x20);
	ipq9574_ppe_reg_write(0xc450, 0x36);
	ipq9574_ppe_reg_write(0xc460, 0x22);
	ipq9574_ppe_reg_write(0xc470, 0x31);
	ipq9574_ppe_reg_write(0xc480, 0x26);
	ipq9574_ppe_reg_write(0xc490, 0x30);
	ipq9574_ppe_reg_write(0xc4a0, 0x25);
	ipq9574_ppe_reg_write(0xc4b0, 0x32);
	ipq9574_ppe_reg_write(0xc4c0, 0x20);
	ipq9574_ppe_reg_write(0xc4d0, 0x36);
	ipq9574_ppe_reg_write(0xc4e0, 0x27);
	ipq9574_ppe_reg_write(0xc4f0, 0x35);
	ipq9574_ppe_reg_write(0xc500, 0x26);
	ipq9574_ppe_reg_write(0xc510, 0x30);
	ipq9574_ppe_reg_write(0xc520, 0x23);
	ipq9574_ppe_reg_write(0xc530, 0x37);
	ipq9574_ppe_reg_write(0xc540, 0x20);
	ipq9574_ppe_reg_write(0xc550, 0x36);
	ipq9574_ppe_reg_write(0xc560, 0x25);
	ipq9574_ppe_reg_write(0xc570, 0x33);
	ipq9574_ppe_reg_write(0xc580, 0x26);
	ipq9574_ppe_reg_write(0xc590, 0x30);
	ipq9574_ppe_reg_write(0xc5a0, 0x24);
	ipq9574_ppe_reg_write(0xc5b0, 0x35);
	ipq9574_ppe_reg_write(0xc5c0, 0x20);
	ipq9574_ppe_reg_write(0xc5d0, 0x36);
	ipq9574_ppe_reg_write(0xc5e0, 0x21);
	ipq9574_ppe_reg_write(0xc5f0, 0x34);
	ipq9574_ppe_reg_write(0xc600, 0x26);
	ipq9574_ppe_reg_write(0xc610, 0x30);
	ipq9574_ppe_reg_write(0xc620, 0x25);
	ipq9574_ppe_reg_write(0xc630, 0x31);
	ipq9574_ppe_reg_write(0xc640, 0x20);
	ipq9574_ppe_reg_write(0xc650, 0x36);
	ipq9574_ppe_reg_write(0xc660, 0x22);
	ipq9574_ppe_reg_write(0xc670, 0x35);
	ipq9574_ppe_reg_write(0xc680, 0x26);
	ipq9574_ppe_reg_write(0xc690, 0x30);
	ipq9574_ppe_reg_write(0xc6a0, 0x23);
	ipq9574_ppe_reg_write(0xc6b0, 0x32);
	ipq9574_ppe_reg_write(0xc6c0, 0x20);
	ipq9574_ppe_reg_write(0xc6d0, 0x36);
	ipq9574_ppe_reg_write(0xc6e0, 0x25);
	ipq9574_ppe_reg_write(0xc6f0, 0x33);
	ipq9574_ppe_reg_write(0xc700, 0x26);
	ipq9574_ppe_reg_write(0xc710, 0x30);
	ipq9574_ppe_reg_write(0xc720, 0x24);
	ipq9574_ppe_reg_write(0xc730, 0x35);
	ipq9574_ppe_reg_write(0xc740, 0x20);
	ipq9574_ppe_reg_write(0xc750, 0x36);
	ipq9574_ppe_reg_write(0xb000, 0x80000076);
}

static void ipq9574_ppe_tdm1_configuration(void)
{
	ipq9574_ppe_reg_write(0xc000, 0x26);
	ipq9574_ppe_reg_write(0xc010, 0x36);
	ipq9574_ppe_reg_write(0xc020, 0x20);
	ipq9574_ppe_reg_write(0xc030, 0x30);
	ipq9574_ppe_reg_write(0xc040, 0x25);
	ipq9574_ppe_reg_write(0xc050, 0x35);
	ipq9574_ppe_reg_write(0xc060, 0x21);
	ipq9574_ppe_reg_write(0xc070, 0x31);
	ipq9574_ppe_reg_write(0xc080, 0x22);
	ipq9574_ppe_reg_write(0xc090, 0x32);
	ipq9574_ppe_reg_write(0xc0a0, 0x20);
	ipq9574_ppe_reg_write(0xc0b0, 0x30);
	ipq9574_ppe_reg_write(0xc0c0, 0x26);
	ipq9574_ppe_reg_write(0xc0d0, 0x36);
	ipq9574_ppe_reg_write(0xc0e0, 0x23);
	ipq9574_ppe_reg_write(0xc0f0, 0x33);
	ipq9574_ppe_reg_write(0xc100, 0x25);
	ipq9574_ppe_reg_write(0xc110, 0x35);
	ipq9574_ppe_reg_write(0xc120, 0x21);
	ipq9574_ppe_reg_write(0xc130, 0x31);
	ipq9574_ppe_reg_write(0xc140, 0x20);
	ipq9574_ppe_reg_write(0xc150, 0x30);
	ipq9574_ppe_reg_write(0xc160, 0x24);
	ipq9574_ppe_reg_write(0xc170, 0x34);
	ipq9574_ppe_reg_write(0xc180, 0x26);
	ipq9574_ppe_reg_write(0xc190, 0x36);
	ipq9574_ppe_reg_write(0xc1a0, 0x25);
	ipq9574_ppe_reg_write(0xc1b0, 0x35);
	ipq9574_ppe_reg_write(0xc1c0, 0x20);
	ipq9574_ppe_reg_write(0xc1d0, 0x30);
	ipq9574_ppe_reg_write(0xc1e0, 0x21);
	ipq9574_ppe_reg_write(0xc1f0, 0x31);
	ipq9574_ppe_reg_write(0xc200, 0x27);
	ipq9574_ppe_reg_write(0xc210, 0x37);
	ipq9574_ppe_reg_write(0xc220, 0x22);
	ipq9574_ppe_reg_write(0xc230, 0x32);
	ipq9574_ppe_reg_write(0xc240, 0x26);
	ipq9574_ppe_reg_write(0xc250, 0x36);
	ipq9574_ppe_reg_write(0xc260, 0x20);
	ipq9574_ppe_reg_write(0xc270, 0x30);
	ipq9574_ppe_reg_write(0xc280, 0x25);
	ipq9574_ppe_reg_write(0xc290, 0x35);
	ipq9574_ppe_reg_write(0xc2a0, 0x21);
	ipq9574_ppe_reg_write(0xc2b0, 0x31);
	ipq9574_ppe_reg_write(0xc2c0, 0x23);
	ipq9574_ppe_reg_write(0xc2d0, 0x33);
	ipq9574_ppe_reg_write(0xc2e0, 0x20);
	ipq9574_ppe_reg_write(0xc2f0, 0x30);
	ipq9574_ppe_reg_write(0xc300, 0x26);
	ipq9574_ppe_reg_write(0xc310, 0x36);
	ipq9574_ppe_reg_write(0xc320, 0x24);
	ipq9574_ppe_reg_write(0xc330, 0x34);
	ipq9574_ppe_reg_write(0xc340, 0x25);
	ipq9574_ppe_reg_write(0xc350, 0x35);
	ipq9574_ppe_reg_write(0xc360, 0x21);
	ipq9574_ppe_reg_write(0xc370, 0x31);
	ipq9574_ppe_reg_write(0xc380, 0x20);
	ipq9574_ppe_reg_write(0xc390, 0x30);
	ipq9574_ppe_reg_write(0xc3a0, 0x27);
	ipq9574_ppe_reg_write(0xc3b0, 0x37);
	ipq9574_ppe_reg_write(0xc3c0, 0x26);
	ipq9574_ppe_reg_write(0xc3d0, 0x36);
	ipq9574_ppe_reg_write(0xc3e0, 0x22);
	ipq9574_ppe_reg_write(0xc3f0, 0x32);
	ipq9574_ppe_reg_write(0xc400, 0x25);
	ipq9574_ppe_reg_write(0xc410, 0x35);
	ipq9574_ppe_reg_write(0xc420, 0x20);
	ipq9574_ppe_reg_write(0xc430, 0x30);
	ipq9574_ppe_reg_write(0xc440, 0x21);
	ipq9574_ppe_reg_write(0xc450, 0x31);
	ipq9574_ppe_reg_write(0xc460, 0x23);
	ipq9574_ppe_reg_write(0xc470, 0x33);
	ipq9574_ppe_reg_write(0xc480, 0x26);
	ipq9574_ppe_reg_write(0xc490, 0x36);
	ipq9574_ppe_reg_write(0xc4a0, 0x25);
	ipq9574_ppe_reg_write(0xc4b0, 0x35);
	ipq9574_ppe_reg_write(0xc4c0, 0x20);
	ipq9574_ppe_reg_write(0xc4d0, 0x30);
	ipq9574_ppe_reg_write(0xc4e0, 0x21);
	ipq9574_ppe_reg_write(0xc4f0, 0x31);
	ipq9574_ppe_reg_write(0xc500, 0x24);
	ipq9574_ppe_reg_write(0xc510, 0x34);
	ipq9574_ppe_reg_write(0xc520, 0x26);
	ipq9574_ppe_reg_write(0xc530, 0x36);
	ipq9574_ppe_reg_write(0xc540, 0x20);
	ipq9574_ppe_reg_write(0xc550, 0x30);
	ipq9574_ppe_reg_write(0xc560, 0x25);
	ipq9574_ppe_reg_write(0xc570, 0x35);
	ipq9574_ppe_reg_write(0xc580, 0x27);
	ipq9574_ppe_reg_write(0xc590, 0x37);
	ipq9574_ppe_reg_write(0xc5a0, 0x21);
	ipq9574_ppe_reg_write(0xc5b0, 0x31);
	ipq9574_ppe_reg_write(0xc5c0, 0x22);
	ipq9574_ppe_reg_write(0xc5d0, 0x32);
	ipq9574_ppe_reg_write(0xc5e0, 0x20);
	ipq9574_ppe_reg_write(0xc5f0, 0x30);
	ipq9574_ppe_reg_write(0xc600, 0x26);
	ipq9574_ppe_reg_write(0xc610, 0x36);
	ipq9574_ppe_reg_write(0xc620, 0x25);
	ipq9574_ppe_reg_write(0xc630, 0x35);
	ipq9574_ppe_reg_write(0xc640, 0x23);
	ipq9574_ppe_reg_write(0xc650, 0x33);
	ipq9574_ppe_reg_write(0xc660, 0x21);
	ipq9574_ppe_reg_write(0xc670, 0x31);
	ipq9574_ppe_reg_write(0xc680, 0x20);
	ipq9574_ppe_reg_write(0xc690, 0x30);
	ipq9574_ppe_reg_write(0xc6a0, 0x24);
	ipq9574_ppe_reg_write(0xc6b0, 0x34);
	ipq9574_ppe_reg_write(0xc6c0, 0x27);
	ipq9574_ppe_reg_write(0xc6d0, 0x37);
	ipq9574_ppe_reg_write(0xc6e0, 0x25);
	ipq9574_ppe_reg_write(0xc6f0, 0x35);
	ipq9574_ppe_reg_write(0xc700, 0x26);
	ipq9574_ppe_reg_write(0xc710, 0x36);
	ipq9574_ppe_reg_write(0xc720, 0x20);
	ipq9574_ppe_reg_write(0xc730, 0x30);
	ipq9574_ppe_reg_write(0xc740, 0x21);
	ipq9574_ppe_reg_write(0xc750, 0x31);
	ipq9574_ppe_reg_write(0xb000, 0x80000076);
}
/*
 * ipq9574_ppe_queue_ac_enable
 */
static void ipq9574_ppe_queue_ac_enable(void)
{
	int i;

	/* ucast queue */
	for (i = 0; i < 256; i++) {
		ipq9574_ppe_reg_write(IPQ9574_PPE_UCAST_QUEUE_AC_EN_BASE_ADDR
					+ (i * 0x10), 0x32120001);
		ipq9574_ppe_reg_write(IPQ9574_PPE_UCAST_QUEUE_AC_EN_BASE_ADDR
					+ (i * 0x10) + 0x4, 0x0);
		ipq9574_ppe_reg_write(IPQ9574_PPE_UCAST_QUEUE_AC_EN_BASE_ADDR
					+ (i * 0x10) + 0x8, 0x0);
		ipq9574_ppe_reg_write(IPQ9574_PPE_UCAST_QUEUE_AC_EN_BASE_ADDR
					+ (i * 0x10) + 0xc, 0x48000);
	}

	/* mcast queue */
	for (i = 0; i < 44; i++) {
		ipq9574_ppe_reg_write(IPQ9574_PPE_MCAST_QUEUE_AC_EN_BASE_ADDR
					+ (i * 0x10), 0x00fa0001);
		ipq9574_ppe_reg_write(IPQ9574_PPE_MCAST_QUEUE_AC_EN_BASE_ADDR
					+ (i * 0x10) + 0x4, 0x0);
		ipq9574_ppe_reg_write(IPQ9574_PPE_MCAST_QUEUE_AC_EN_BASE_ADDR
					+ (i * 0x10) + 0x8, 0x1200);
	}
}

/*
 * ipq9574_ppe_enable_port_counter
 */
static void ipq9574_ppe_enable_port_counter(void)
{
	int i;
	uint32_t reg = 0;

	for (i = 0; i < 7; i++) {
		/* MRU_MTU_CTRL_TBL.rx_cnt_en, MRU_MTU_CTRL_TBL.tx_cnt_en */
		ipq9574_ppe_reg_read(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10), &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10), reg);
		ipq9574_ppe_reg_read(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10) + 0x4, &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10) + 0x4, reg | 0x284303);
		ipq9574_ppe_reg_read(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10) + 0x8, &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10) + 0x8, reg);
		ipq9574_ppe_reg_read(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10) + 0xc, &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_MRU_MTU_CTRL_TBL_ADDR
					+ (i * 0x10) + 0xc, reg);

		/* MC_MTU_CTRL_TBL.tx_cnt_en */
		ipq9574_ppe_reg_read(IPQ9574_PPE_MC_MTU_CTRL_TBL_ADDR
					+ (i * 0x4), &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_MC_MTU_CTRL_TBL_ADDR
					+ (i * 0x4), reg | 0x10000);

		/* PORT_EG_VLAN.tx_counting_en */
		ipq9574_ppe_reg_read(IPQ9574_PPE_PORT_EG_VLAN_TBL_ADDR
					+ (i * 0x4), &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_PORT_EG_VLAN_TBL_ADDR
					+ (i * 0x4), reg | 0x100);

		/* TL_PORT_VP_TBL.rx_cnt_en */
		ipq9574_ppe_reg_read(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10), &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10), reg);
		ipq9574_ppe_reg_read(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10) + 0x4, &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10) + 0x4, reg);
		ipq9574_ppe_reg_read(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10) + 0x8, &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10) + 0x8, reg | 0x20000);
		ipq9574_ppe_reg_read(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10) + 0xc, &reg);
		ipq9574_ppe_reg_write(IPQ9574_PPE_TL_PORT_VP_TBL_ADDR
					+ (i * 0x10) + 0xc, reg);
	}
}

/*
 * ipq9574_ppe_c_sp_cfg_tbl_drr_id_set
 */
static void ipq9574_ppe_c_sp_cfg_tbl_drr_id_set(int id)
{
	ipq9574_ppe_reg_write(IPQ9574_PPE_L0_C_SP_CFG_TBL + (id * 0x80), id * 2);
	ipq9574_ppe_reg_write(IPQ9574_PPE_L1_C_SP_CFG_TBL + (id * 0x80), id * 2);
}

/*
 * ipq9574_ppe_e_sp_cfg_tbl_drr_id_set
 */
static void ipq9574_ppe_e_sp_cfg_tbl_drr_id_set(int id)
{
	ipq9574_ppe_reg_write(IPQ9574_PPE_L0_E_SP_CFG_TBL + (id * 0x80), id * 2 + 1);
	ipq9574_ppe_reg_write(IPQ9574_PPE_L1_E_SP_CFG_TBL + (id * 0x80), id * 2 + 1);
}

static void ppe_port_mux_set(int port_id, int port_type, int mode)
{
	uint32_t mux_mac_type = 0;
	union port_mux_ctrl_u port_mux_ctrl;
	int node;
	uint32_t mode1;

	pr_debug("\nport id is: %d, port type is %d, mode is %d",
		port_id, port_type, mode);
	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");

	if (port_type == PORT_GMAC_TYPE)
		mux_mac_type = IPQ9574_PORT_MUX_MAC_TYPE;
	else if (port_type == PORT_XGMAC_TYPE)
		mux_mac_type = IPQ9574_PORT_MUX_XMAC_TYPE;
	else
		printf("\nAttention!!!..Port type configured wrongly..port_id = %d, mode = %d, port_type = %d",
		       port_id, mode, port_type);

	port_mux_ctrl.val = 0;
	ipq9574_ppe_reg_read(IPQ9574_PORT_MUX_CTRL, &(port_mux_ctrl.val));
	pr_debug("\nBEFORE UPDATE: Port MUX CTRL value is %u", port_mux_ctrl.val);


	switch (port_id) {
		case PORT1:
			port_mux_ctrl.bf.port1_mac_sel = mux_mac_type;
			port_mux_ctrl.bf.port1_pcs_sel = 0;
			break;
		case PORT2:
			port_mux_ctrl.bf.port2_mac_sel = mux_mac_type;
			port_mux_ctrl.bf.port2_pcs_sel = 0;
			break;
		case PORT3:
			port_mux_ctrl.bf.port3_mac_sel = mux_mac_type;
			port_mux_ctrl.bf.port3_pcs_sel = 0;
			break;
		case PORT4:
			port_mux_ctrl.bf.port4_mac_sel = mux_mac_type;
			port_mux_ctrl.bf.port4_pcs_sel = 0;
			break;
		case PORT5:
			port_mux_ctrl.bf.port5_mac_sel = mux_mac_type;
			/*
			 * If port 5 is part of uniphy0, then uniphy1 should be
			 * given as 0xFF (EPORT_WRAPPER_MAX) in DT since uniphy1
			 * will not be used in that case
			 */
			mode1 = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode1", -1);
			if (mode1 == EPORT_WRAPPER_MAX)
				port_mux_ctrl.bf.port5_pcs_sel =
						IPQ9574_PORT5_MUX_PCS_UNIPHY0;
			else
				port_mux_ctrl.bf.port5_pcs_sel =
						IPQ9574_PORT5_MUX_PCS_UNIPHY1;
			break;
		case PORT6:
			port_mux_ctrl.bf.port6_mac_sel = mux_mac_type;
			port_mux_ctrl.bf.port6_pcs_sel = 0;
			break;
		default:
			break;
	}

	ipq9574_ppe_reg_write(IPQ9574_PORT_MUX_CTRL, port_mux_ctrl.val);
	pr_debug("\nAFTER UPDATE: Port MUX CTRL value is %u", port_mux_ctrl.val);
}

void ppe_port_mux_mac_type_set(int port_id, int mode)
{
	uint32_t port_type;

	switch(mode)
	{
		case EPORT_WRAPPER_PSGMII:
		case EPORT_WRAPPER_SGMII0_RGMII4:
		case EPORT_WRAPPER_SGMII_PLUS:
		case EPORT_WRAPPER_SGMII_FIBER:
		case EPORT_WRAPPER_SGMII_CHANNEL0:
			port_type = PORT_GMAC_TYPE;
			break;
		case EPORT_WRAPPER_USXGMII:
		case EPORT_WRAPPER_10GBASE_R:
		case EPORT_WRAPPER_UQXGMII:
			port_type = PORT_XGMAC_TYPE;
			break;
		default:
			printf("\nError during port_type set: mode is %d, port_id is: %d",
			       mode, port_id);
			return;
	}
	ppe_port_mux_set(port_id, port_type, mode);
}

void ipq9574_ppe_interface_mode_init(void)
{
	uint32_t mode0, mode1, mode2;
	int node;
	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node < 0) {
		printf("\nError: ess-switch not specified in dts");
		return;
	}

	mode0 = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode0", -1);
	if (mode0 < 0) {
		printf("\nError: switch_mac_mode0 not specified in dts");
		return;
	}

	mode1 = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode1", -1);
	if (mode1 < 0) {
		printf("\nError: switch_mac_mode1 not specified in dts");
		return;
	}

	mode2 = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode2", -1);
	if (mode1 < 0) {
		printf("\nError: switch_mac_mode2 not specified in dts");
		return;
	}

	uniphy_force_mode = fdtdec_get_uint(gd->fdt_blob, node,
				"uniphy_force_mode", -1);

	ppe_uniphy_mode_set(PPE_UNIPHY_INSTANCE0, mode0);
	ppe_uniphy_mode_set(PPE_UNIPHY_INSTANCE1, mode1);
	ppe_uniphy_mode_set(PPE_UNIPHY_INSTANCE2, mode2);

	/*
	 *
	 * Port 1-4 are used mac type as GMAC by default but
	 * Port5 and Port6 can be used as GMAC or XGMAC.
	 */
	ppe_port_mux_mac_type_set(PORT1, mode0);
	ppe_port_mux_mac_type_set(PORT2, mode0);
	ppe_port_mux_mac_type_set(PORT3, mode0);
	ppe_port_mux_mac_type_set(PORT4, mode0);
	if (mode1 == EPORT_WRAPPER_MAX) {
		if (mode0 != EPORT_WRAPPER_UQXGMII) {
			ppe_port_mux_mac_type_set(PORT5, mode0);
			uniphy_port5_clock_source_set();
		}
	} else if (is_uniphy_enabled(PPE_UNIPHY_INSTANCE1)) {
		ppe_port_mux_mac_type_set(PORT5, mode1);
	}
	if (is_uniphy_enabled(PPE_UNIPHY_INSTANCE2)) {
		ppe_port_mux_mac_type_set(PORT6, mode2);
	}
}

/*
 * ipq9574_ppe_provision_init()
 */
void ipq9574_ppe_provision_init(void)
{
	int i;
	uint32_t queue;
	int node, tdm_mode = 0;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node < 0) {
		printf("\nError: ess-switch not specified in dts");
		return;
	}

	tdm_mode = fdtdec_get_uint(gd->fdt_blob, node, "tdm_mode", 0);
	if (tdm_mode < 0) {
		printf("\nError:tdm mode not specified in dts assume tdm 0");
	}

	/* tdm/sched configuration */
	if (tdm_mode == 1)
		ipq9574_ppe_tdm1_configuration();
	else
		ipq9574_ppe_tdm_configuration();

#ifdef CONFIG_IPQ9574_BRIDGED_MODE
	/* Add CPU port 0 to VSI 2 */
	ipq9574_ppe_vp_port_tbl_set(0, 2);

	/* Add port 1 - 4 to VSI 2 */
	ipq9574_ppe_vp_port_tbl_set(1, 2);
	ipq9574_ppe_vp_port_tbl_set(2, 2);
	ipq9574_ppe_vp_port_tbl_set(3, 2);
	ipq9574_ppe_vp_port_tbl_set(4, 2);
	ipq9574_ppe_vp_port_tbl_set(5, 2);
	ipq9574_ppe_vp_port_tbl_set(6, 2);

#else
	ipq9574_ppe_vp_port_tbl_set(1, 2);
	ipq9574_ppe_vp_port_tbl_set(2, 3);
	ipq9574_ppe_vp_port_tbl_set(3, 4);
	ipq9574_ppe_vp_port_tbl_set(4, 5);
	ipq9574_ppe_vp_port_tbl_set(5, 6);
	ipq9574_ppe_vp_port_tbl_set(6, 7);
#endif

	/* Unicast priority map */
	ipq9574_ppe_reg_write(IPQ9574_PPE_QM_UPM_TBL, 0);

	/* Port0 - 7 unicast queue settings */
	for (i = 0; i < 8; i++) {
		if (i == 0)
			queue = 0;
		else
			queue = ((i * 0x10) + 0x70);

		ipq9574_ppe_ucast_queue_map_tbl_queue_id_set(queue, i);
		ipq9574_ppe_flow_port_map_tbl_port_num_set(queue, i);
		ipq9574_ppe_flow_map_tbl_set(queue, i);
		ipq9574_ppe_c_sp_cfg_tbl_drr_id_set(i);
		ipq9574_ppe_e_sp_cfg_tbl_drr_id_set(i);
	}

	/* Port0 multicast queue */
	ipq9574_ppe_reg_write(0x409000, 0x00000000);
	ipq9574_ppe_reg_write(0x403000, 0x00401000);

	/* Port1 - 7 multicast queue */
	for (i = 1; i < 8; i++) {
		ipq9574_ppe_reg_write(0x409100 + ((i - 1) * 0x40), i);
		ipq9574_ppe_reg_write(0x403100 + ((i - 1) * 0x40), 0x401000 | i);
	}

	/* ac enable for queues - disable queue tail drop */
	ipq9574_ppe_queue_ac_enable();

	/* enable queue counter */
	ipq9574_ppe_reg_write(0x020044,0x4);

	/* assign the ac group 0 with buffer number */
	ipq9574_ppe_reg_write(0x84c000, 0x0);
	ipq9574_ppe_reg_write(0x84c004, 0x7D00);
	ipq9574_ppe_reg_write(0x84c008, 0x0);
	ipq9574_ppe_reg_write(0x84c00c, 0x0);

	/* enable physical/virtual port TX/RX counters for all ports (0-6) */
	ipq9574_ppe_enable_port_counter();

	/*
	 * Port0 - TX_EN is set by default, Port1 - LRN_EN is set
	 * Port0 -> CPU Port
	 * Port1-6 -> Ethernet Ports
	 * Port7 -> EIP197
	 */
	for (i = 0; i < 8; i++) {
		if (i == 0)
			ipq9574_ppe_reg_write(IPQ9574_PPE_PORT_BRIDGE_CTRL_OFFSET + (i * 4),
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_PROMISC_EN |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_TXMAC_EN |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_PORT_ISOLATION_BMP |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_STATION_LRN_EN |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_NEW_ADDR_LRN_EN);
		else if (i == 7)
			ipq9574_ppe_reg_write(IPQ9574_PPE_PORT_BRIDGE_CTRL_OFFSET + (i * 4),
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_PROMISC_EN |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_PORT_ISOLATION_BMP |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_STATION_LRN_EN |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_NEW_ADDR_LRN_EN);
		else
			ipq9574_ppe_reg_write(IPQ9574_PPE_PORT_BRIDGE_CTRL_OFFSET + (i * 4),
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_PROMISC_EN |
			      IPQ9574_PPE_PORT_BRIDGE_CTRL_PORT_ISOLATION_BMP);
	}

	/* Global learning */
	ipq9574_ppe_reg_write(0x060038, 0xc0);

#ifdef CONFIG_IPQ9574_BRIDGED_MODE
	ipq9574_vsi_setup(2, 0x7f);
#else
	ipq9574_vsi_setup(2, 0x03);
	ipq9574_vsi_setup(3, 0x05);
	ipq9574_vsi_setup(4, 0x09);
	ipq9574_vsi_setup(5, 0x11);
	ipq9574_vsi_setup(6, 0x21);
	ipq9574_vsi_setup(7, 0x41);
#endif

	/* Port 0-7 STP */
	for (i = 0; i < 8; i++)
		ipq9574_ppe_reg_write(IPQ9574_PPE_STP_BASE + (0x4 * i), 0x3);

	ipq9574_ppe_interface_mode_init();
	/* Port 1-6 disable */
	for (i = 0; i < 6; i++) {
		ipq9574_gmac_port_disable(i);
		ppe_port_bridge_txmac_set(i + 1, 1);
	}

	/* Allowing DHCP packets */
	ipq9574_ppe_acl_set(0, ADPT_ACL_HPPE_IPV4_DIP_RULE, UDP_PKT, 67, 0xffff, 0, 0);
	ipq9574_ppe_acl_set(1, ADPT_ACL_HPPE_IPV4_DIP_RULE, UDP_PKT, 68, 0xffff, 0, 0);
	/* Dropping all the UDP packets */
	ipq9574_ppe_acl_set(2, ADPT_ACL_HPPE_IPV4_DIP_RULE, UDP_PKT, 0, 0, 0, 1);
}
