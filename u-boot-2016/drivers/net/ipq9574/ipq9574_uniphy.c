/*
 * Copyright (c) 2017-2019, 2021, The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */
#include <common.h>
#include <asm/global_data.h>
#include <net.h>
#include <asm-generic/errno.h>
#include <asm/io.h>
#include <malloc.h>
#include <phy.h>
#include <net.h>
#include <miiphy.h>
#include <asm/arch-ipq9574/edma_regs.h>
#include "ipq9574_edma.h"
#include "ipq9574_uniphy.h"
#include "ipq9574_ppe.h"
#include <fdtdec.h>
#include "ipq_phy.h"

extern int uniphy_force_mode;

extern int is_uniphy_enabled(int uniphy_index);

DECLARE_GLOBAL_DATA_PTR;
extern int ipq_mdio_write(int mii_id,
		int regnum, u16 value);
extern int ipq_mdio_read(int mii_id,
		int regnum, ushort *data);
extern void ipq9574_qca8075_phy_serdes_reset(u32 phy_id);
extern void qca8084_phy_interface_mode_set(void);
int uniphy_cur_mode[PPE_MAX_UNIPHY_INSTANCE] = {-1, -1, -1};

void csr1_write(int phy_id, int addr, int  value)
{
	int  addr_h, addr_l, ahb_h, ahb_l,  phy;
	phy=phy_id<<(0x10);
	addr_h=(addr&0xffffff)>>8;
	addr_l=((addr&0xff)<<2)|(0x20<<(0xa));
	ahb_l=(addr_l&0xffff)|(0x7A00000|phy);
	ahb_h=(0x7A083FC|phy);
	writel(addr_h,ahb_h);
	writel(value,ahb_l);
}

int  csr1_read(int phy_id, int  addr )
{
	int  addr_h ,addr_l,ahb_h, ahb_l, phy;
	phy=phy_id<<(0x10);
	addr_h=(addr&0xffffff)>>8;
	addr_l=((addr&0xff)<<2)|(0x20<<(0xa));
	ahb_l=(addr_l&0xffff)|(0x7A00000|phy);
	ahb_h=(0x7A083FC|phy);
	writel(addr_h, ahb_h);
	return  readl(ahb_l);
}

static int ppe_uniphy_calibration(uint32_t uniphy_index)
{
	int retries = 100, calibration_done = 0;
	uint32_t reg_value = 0;

	while(calibration_done != UNIPHY_CALIBRATION_DONE) {
		mdelay(1);
		if (retries-- == 0) {
			printf("uniphy callibration time out!\n");
			return -1;
		}
		reg_value = readl(PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			+ PPE_UNIPHY_OFFSET_CALIB_4);
		calibration_done = (reg_value >> 0x7) & 0x1;
	}

	return 0;
}

static void ppe_uniphy_reset(enum uniphy_reset_type rst_type, bool enable)
{
	uint32_t mode, node;
	uint32_t reg_val, reg_val1;

	switch(rst_type) {
		case UNIPHY0_SOFT_RESET:
			node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
			if (node < 0) {
				printf("\nError: ess-switch not specified in dts");
				return;
			}
			mode = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode1", -1);
			if (mode < 0) {
				printf("\nError: switch_mac_mode1 not specified in dts");
				return;
			}
			reg_val = readl(GCC_UNIPHY0_MISC);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			if (mode == EPORT_WRAPPER_MAX) {
				if (enable) {
					reg_val |= 0x1;
					reg_val1 |= 0xffc000;
				} else {
					reg_val &= ~0x1;
					reg_val1 &= ~0xffc000;
				}
			} else {
				if (enable) {
					reg_val |= 0x1;
					reg_val1 |= 0xff0000;
				} else {
					reg_val &= ~0x1;
					reg_val1 &= ~0xff0000;
				}
			}
			writel(reg_val, GCC_UNIPHY0_MISC);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			break;
		case UNIPHY0_XPCS_RESET:
			reg_val = readl(GCC_UNIPHY0_MISC);
			if (enable)
				reg_val |= 0x4;
			else
				reg_val &= ~0x4;
			writel(reg_val, GCC_UNIPHY0_MISC);
			break;
		case UNIPHY1_SOFT_RESET:
			reg_val = readl(GCC_UNIPHY0_MISC + GCC_UNIPHY_REG_INC);
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			if (enable) {
				reg_val |= 0x1;
				reg_val1 |= 0xC000;
			} else {
				reg_val &= ~0x1;
				reg_val1 &= ~0xC000;
			}
			writel(reg_val, GCC_UNIPHY0_MISC + GCC_UNIPHY_REG_INC);
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			break;
		case UNIPHY1_XPCS_RESET:
			reg_val = readl(GCC_UNIPHY0_MISC + GCC_UNIPHY_REG_INC);
			if (enable)
				reg_val |= 0x4;
			else
				reg_val &= ~0x4;
			writel(reg_val, GCC_UNIPHY0_MISC + GCC_UNIPHY_REG_INC);
			break;
		case UNIPHY2_SOFT_RESET:
			reg_val = readl(GCC_UNIPHY0_MISC + (2 * GCC_UNIPHY_REG_INC));
			reg_val1 = readl(NSS_CC_UNIPHY_MISC_RESET);
			if (enable) {
				reg_val |= 0x1;
				reg_val1 |= 0x3000;
			} else {
				reg_val &= ~0x1;
				reg_val1 &= ~0x3000;
			}
			writel(reg_val, GCC_UNIPHY0_MISC + (2 * GCC_UNIPHY_REG_INC));
			writel(reg_val1, NSS_CC_UNIPHY_MISC_RESET);
			break;
		case UNIPHY2_XPCS_RESET:
			reg_val = readl(GCC_UNIPHY0_MISC + (2 * GCC_UNIPHY_REG_INC));
			if (enable)
				reg_val |= 0x4;
			else
				reg_val &= ~0x4;
			writel(reg_val, GCC_UNIPHY0_MISC + (2 * GCC_UNIPHY_REG_INC));
			break;
		default:
			break;
	}
}

static void ppe_uniphy_psgmii_mode_set(uint32_t uniphy_index)
{
	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, true);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, true);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, true);
	mdelay(100);

	writel(0x220, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			+ PPE_UNIPHY_MODE_CONTROL);

	if (uniphy_index == 0) {
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, false);
	} else if (uniphy_index == 1) {
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, false);
	} else {
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, false);
	}
	mdelay(100);
	ppe_uniphy_calibration(uniphy_index);
#ifdef CONFIG_IPQ9574_QCA8075_PHY
	ipq9574_qca8075_phy_serdes_reset(0x10);
#endif
}

static void ppe_uniphy_qsgmii_mode_set(uint32_t uniphy_index)
{
	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, true);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, true);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, true);
	mdelay(100);

	writel(0x120, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			+ PPE_UNIPHY_MODE_CONTROL);
	if (uniphy_index == 0) {
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, false);
	} else if (uniphy_index == 1) {
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, false);
	} else {
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, false);
	}
	mdelay(100);
}

void ppe_uniphy_set_forceMode(uint32_t uniphy_index)
{
	uint32_t reg_value;

	reg_value = readl(PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
				+ UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_4);
	reg_value |= UNIPHY_FORCE_SPEED_25M;

	writel(reg_value, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
				+ UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_4);
}

static void ppe_uniphy_sgmii_mode_set(uint32_t uniphy_index, uint32_t mode)
{
	writel(UNIPHY_MISC_SRC_PHY_MODE, PPE_UNIPHY_BASE +
			(uniphy_index * PPE_UNIPHY_REG_INC) +
			UNIPHY_MISC_SOURCE_SELECTION_REG_OFFSET);

	if (uniphy_force_mode == uniphy_index)
		ppe_uniphy_set_forceMode(uniphy_index);

	if (mode == EPORT_WRAPPER_SGMII_PLUS) {
		writel(UNIPHY_MISC2_REG_SGMII_PLUS_MODE, PPE_UNIPHY_BASE +
			(uniphy_index * PPE_UNIPHY_REG_INC) +
			UNIPHY_MISC2_REG_OFFSET);
	} else {
		writel(UNIPHY_MISC2_REG_SGMII_MODE, PPE_UNIPHY_BASE +
			(uniphy_index * PPE_UNIPHY_REG_INC) +
			UNIPHY_MISC2_REG_OFFSET);
	}

	writel(UNIPHY_PLL_RESET_REG_VALUE, PPE_UNIPHY_BASE +
		(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(500);
	writel(UNIPHY_PLL_RESET_REG_DEFAULT_VALUE, PPE_UNIPHY_BASE +
		(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(500);
	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, true);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, true);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, true);
	mdelay(100);

	if (uniphy_index == 0) {
		writel(0x0, NSS_CC_UNIPHY_PORT1_RX_CBCR);
		writel(0x0, NSS_CC_UNIPHY_PORT1_RX_CBCR + 0x4);
		writel(0x0, NSS_CC_PORT1_RX_CBCR);
		writel(0x0, NSS_CC_PORT1_RX_CBCR + 0x4);
	} else if (uniphy_index == 1) {
		writel(0x0, NSS_CC_UNIPHY_PORT1_RX_CBCR + (PORT5 - 1) * 0x8);
		writel(0x0, NSS_CC_UNIPHY_PORT1_RX_CBCR + 0x4 + (PORT5 - 1) * 0x8);
		writel(0x0, NSS_CC_PORT1_RX_CBCR + (PORT5 - 1) * 0x8);
		writel(0x0, NSS_CC_PORT1_RX_CBCR + 0x4 + (PORT5 - 1) * 0x8);
	} else if (uniphy_index == 2) {
		writel(0x0, NSS_CC_UNIPHY_PORT1_RX_CBCR + (PORT6 - 1) * 0x8);
		writel(0x0, NSS_CC_UNIPHY_PORT1_RX_CBCR + 0x4 + (PORT6 - 1) * 8);
		writel(0x0, NSS_CC_PORT1_RX_CBCR + (PORT6 - 1) * 0x8);
		writel(0x0, NSS_CC_PORT1_RX_CBCR + 0x4 + (PORT6 - 1) * 0x8);
	}

	switch (mode) {
		case EPORT_WRAPPER_SGMII_FIBER:
			writel(0x400, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
					 + PPE_UNIPHY_MODE_CONTROL);
			break;

		case EPORT_WRAPPER_SGMII0_RGMII4:
		case EPORT_WRAPPER_SGMII1_RGMII4:
		case EPORT_WRAPPER_SGMII4_RGMII4:
			writel(0x420, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
					 + PPE_UNIPHY_MODE_CONTROL);
			break;

		case EPORT_WRAPPER_SGMII_PLUS:
			if (uniphy_index == 0)
				writel(0x20, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
					 + PPE_UNIPHY_MODE_CONTROL);
			else
				writel(0x820, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
					 + PPE_UNIPHY_MODE_CONTROL);
			break;

		default:
			printf("SGMII Config. wrongly");
			break;
	}

	if (uniphy_index == 0) {
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, false);
	} else if (uniphy_index == 1) {
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, false);
	} else {
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, false);
	}
	mdelay(100);

	if (uniphy_index == 0) {
		writel(0x1, NSS_CC_UNIPHY_PORT1_RX_CBCR);
		writel(0x1, NSS_CC_UNIPHY_PORT1_RX_CBCR + 0x4);
		writel(0x1, NSS_CC_PORT1_RX_CBCR);
		writel(0x1, NSS_CC_PORT1_RX_CBCR + 0x4);
	} else if (uniphy_index == 1) {
		writel(0x1, NSS_CC_UNIPHY_PORT1_RX_CBCR + (PORT5 - 1) * 0x8);
		writel(0x1, NSS_CC_UNIPHY_PORT1_RX_CBCR + 0x4 + (PORT5 - 1) * 0x8);
		writel(0x1, NSS_CC_PORT1_RX_CBCR + (PORT5 - 1) * 0x8);
		writel(0x1, NSS_CC_PORT1_RX_CBCR + 0x4 + (PORT5 - 1) * 0x8);
	} else if (uniphy_index == 2) {
		writel(0x1, NSS_CC_UNIPHY_PORT1_RX_CBCR + (PORT6 - 1) * 0x8);
		writel(0x1, NSS_CC_UNIPHY_PORT1_RX_CBCR + 0x4 + (PORT6 - 1) * 8);
		writel(0x1, NSS_CC_PORT1_RX_CBCR + (PORT6 - 1) * 0x8);
		writel(0x1, NSS_CC_PORT1_RX_CBCR + 0x4 + (PORT6 - 1) * 0x8);
	}

	ppe_uniphy_calibration(uniphy_index);
}

static int ppe_uniphy_10g_r_linkup(uint32_t uniphy_index)
{
	uint32_t reg_value = 0;
	uint32_t retries = 100, linkup = 0;

	while (linkup != UNIPHY_10GR_LINKUP) {
		mdelay(1);
		if (retries-- == 0)
			return -1;
		reg_value = csr1_read(uniphy_index, SR_XS_PCS_KR_STS1_ADDRESS);
		linkup = (reg_value >> 12) & UNIPHY_10GR_LINKUP;
	}
	mdelay(10);
	return 0;
}

static void ppe_uniphy_10g_r_mode_set(uint32_t uniphy_index)
{
	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, true);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, true);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, true);

	writel(0x1021, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			 + PPE_UNIPHY_MODE_CONTROL);
	writel(0x1C0, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			 + UNIPHY_INSTANCE_LINK_DETECT);

	if (uniphy_index == 0) {
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, false);
	} else if (uniphy_index == 1) {
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, false);
	} else {
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, false);
	}
	mdelay(100);

	ppe_uniphy_calibration(uniphy_index);

	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, false);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, false);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, false);
}

static void ppe_uniphy_uqxgmii_eee_set(uint32_t uniphy_index)
{
	uint32_t reg_value = 0;

	/* configure eee related timer value */
	reg_value = csr1_read(uniphy_index, VR_XS_PCS_EEE_MCTRL0_ADDRESS);
	reg_value |= SIGN_BIT | MULT_FACT_100NS;
	csr1_write(uniphy_index, VR_XS_PCS_EEE_MCTRL0_ADDRESS, reg_value);

	reg_value = csr1_read(uniphy_index, VR_XS_PCS_EEE_TXTIMER_ADDRESS);
	reg_value |= UNIPHY_XPCS_TSL_TIMER | UNIPHY_XPCS_TLU_TIMER
			| UNIPHY_XPCS_TWL_TIMER;
	csr1_write(uniphy_index, VR_XS_PCS_EEE_TXTIMER_ADDRESS, reg_value);

	reg_value = csr1_read(uniphy_index, VR_XS_PCS_EEE_RXTIMER_ADDRESS);
	reg_value |= UNIPHY_XPCS_100US_TIMER | UNIPHY_XPCS_TWR_TIMER;
	csr1_write(uniphy_index, VR_XS_PCS_EEE_RXTIMER_ADDRESS, reg_value);

	/* Transparent LPI mode and LPI pattern enable */
	reg_value = csr1_read(uniphy_index, VR_XS_PCS_EEE_MCTRL1_ADDRESS);
	reg_value |= TRN_LPI | TRN_RXLPI;
	csr1_write(uniphy_index, VR_XS_PCS_EEE_MCTRL1_ADDRESS, reg_value);

	reg_value = csr1_read(uniphy_index, VR_XS_PCS_EEE_MCTRL0_ADDRESS);
	reg_value |= LRX_EN | LTX_EN;
	csr1_write(uniphy_index, VR_XS_PCS_EEE_MCTRL0_ADDRESS, reg_value);
}

static void ppe_uniphy_uqxgmii_mode_set(uint32_t uniphy_index)
{
	uint32_t reg_value = 0;

	writel(UNIPHY_MISC2_REG_VALUE, PPE_UNIPHY_BASE +
	(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_MISC2_REG_OFFSET);

	/* reset uniphy */
	writel(UNIPHY_PLL_RESET_REG_VALUE, PPE_UNIPHY_BASE +
		(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(500);
	writel(UNIPHY_PLL_RESET_REG_DEFAULT_VALUE, PPE_UNIPHY_BASE +
		(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(500);

	/* keep xpcs to reset status */
	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, true);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, true);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, true);
	mdelay(100);

	/* configure uniphy to usxgmii mode */
	writel(0x1021, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			 + PPE_UNIPHY_MODE_CONTROL);

	reg_value = readl(PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			 + UNIPHYQP_USXG_OPITON1);
	reg_value |= GMII_SRC_SEL;
	writel(reg_value, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			 + UNIPHYQP_USXG_OPITON1);

	/* configure uniphy usxgmii gcc software reset */
	if (uniphy_index == 0) {
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, false);
	} else if (uniphy_index == 1) {
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, false);
	} else {
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, false);
	}
	mdelay(100);

	/* wait calibration done to uniphy */
	ppe_uniphy_calibration(uniphy_index);

	/* release xpcs reset status */
	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, false);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, false);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, false);
	mdelay(100);

	/* wait 10g base_r link up */
	ppe_uniphy_10g_r_linkup(uniphy_index);

	/* enable uniphy usxgmii */
	reg_value = csr1_read(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS);
	reg_value |= USXG_EN;
	csr1_write(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS, reg_value);

	/* set qxgmii mode */
	reg_value = csr1_read(uniphy_index, VR_XS_PCS_KR_CTRL_ADDRESS);
	reg_value |= USXG_MODE;
	csr1_write(uniphy_index, VR_XS_PCS_KR_CTRL_ADDRESS, reg_value);

	/* set AM interval mode */
	reg_value = csr1_read(uniphy_index, VR_XS_PCS_DIG_STS_ADDRESS);
	reg_value |= AM_COUNT;
	csr1_write(uniphy_index, VR_XS_PCS_DIG_STS_ADDRESS, reg_value);

	/* xpcs software reset */
	reg_value = csr1_read(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS);
	reg_value |= VR_RST;
	csr1_write(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS, reg_value);

	/* enable uniphy autoneg complete interrupt and 10M/100M 8-bits MII width */
	reg_value = csr1_read(uniphy_index, VR_MII_AN_CTRL_ADDRESS);
	reg_value |= MII_AN_INTR_EN;
	reg_value |= MII_CTRL;
	csr1_write(uniphy_index, VR_MII_AN_CTRL_ADDRESS, reg_value);
	csr1_write(uniphy_index, VR_MII_AN_CTRL_CHANNEL1_ADDRESS, reg_value);
	csr1_write(uniphy_index, VR_MII_AN_CTRL_CHANNEL2_ADDRESS, reg_value);
	csr1_write(uniphy_index, VR_MII_AN_CTRL_CHANNEL3_ADDRESS, reg_value);

	/* disable TICD */
	reg_value = csr1_read(uniphy_index, VR_XAUI_MODE_CTRL_ADDRESS);
	reg_value |= IPG_CHECK;
	csr1_write(uniphy_index, VR_XAUI_MODE_CTRL_ADDRESS, reg_value);
	csr1_write(uniphy_index, VR_XAUI_MODE_CTRL_CHANNEL1_ADDRESS, reg_value);
	csr1_write(uniphy_index, VR_XAUI_MODE_CTRL_CHANNEL2_ADDRESS, reg_value);
	csr1_write(uniphy_index, VR_XAUI_MODE_CTRL_CHANNEL3_ADDRESS, reg_value);

	/* enable uniphy autoneg ability and usxgmii 10g speed and full duplex */
	reg_value = csr1_read(uniphy_index, SR_MII_CTRL_ADDRESS);
	reg_value |= AN_ENABLE;
	reg_value &= ~SS5;
	reg_value |= SS6 | SS13 | DUPLEX_MODE;
	csr1_write(uniphy_index, SR_MII_CTRL_ADDRESS, reg_value);
	csr1_write(uniphy_index, SR_MII_CTRL_CHANNEL1_ADDRESS, reg_value);
	csr1_write(uniphy_index, SR_MII_CTRL_CHANNEL2_ADDRESS, reg_value);
	csr1_write(uniphy_index, SR_MII_CTRL_CHANNEL3_ADDRESS, reg_value);

	/* enable uniphy eee transparent mode*/
	ppe_uniphy_uqxgmii_eee_set(uniphy_index);

#ifdef CONFIG_QCA8084_PHY_MODE
	/* phy interface mode configuration for qca8084 */
	qca8084_phy_interface_mode_set();
#endif
}

static void ppe_uniphy_usxgmii_mode_set(uint32_t uniphy_index)
{
	uint32_t reg_value = 0;

	writel(UNIPHY_MISC2_REG_VALUE, PPE_UNIPHY_BASE +
		(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_MISC2_REG_OFFSET);
	writel(UNIPHY_PLL_RESET_REG_VALUE, PPE_UNIPHY_BASE +
		(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(500);
	writel(UNIPHY_PLL_RESET_REG_DEFAULT_VALUE, PPE_UNIPHY_BASE +
		(uniphy_index * PPE_UNIPHY_REG_INC) + UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(500);

	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, true);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, true);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, true);
	mdelay(100);

	writel(0x1021, PPE_UNIPHY_BASE + (uniphy_index * PPE_UNIPHY_REG_INC)
			 + PPE_UNIPHY_MODE_CONTROL);

	if (uniphy_index == 0) {
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY0_SOFT_RESET, false);
	} else if (uniphy_index == 1) {
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY1_SOFT_RESET, false);
	} else {
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, true);
		mdelay(100);
		ppe_uniphy_reset(UNIPHY2_SOFT_RESET, false);
	}
	mdelay(100);

	ppe_uniphy_calibration(uniphy_index);

	if (uniphy_index == 0)
		ppe_uniphy_reset(UNIPHY0_XPCS_RESET, false);
	else if (uniphy_index == 1)
		ppe_uniphy_reset(UNIPHY1_XPCS_RESET, false);
	else
		ppe_uniphy_reset(UNIPHY2_XPCS_RESET, false);
	mdelay(100);

	ppe_uniphy_10g_r_linkup(uniphy_index);
	reg_value = csr1_read(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS);
	reg_value |= USXG_EN;
	csr1_write(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS, reg_value);
	reg_value = csr1_read(uniphy_index, VR_MII_AN_CTRL_ADDRESS);
	reg_value |= MII_AN_INTR_EN;
	reg_value |= MII_CTRL;
	csr1_write(uniphy_index, VR_MII_AN_CTRL_ADDRESS, reg_value);
	reg_value = csr1_read(uniphy_index, SR_MII_CTRL_ADDRESS);
	reg_value |= AN_ENABLE;
	reg_value &= ~SS5;
	reg_value |= SS6 | SS13 | DUPLEX_MODE;
	csr1_write(uniphy_index, SR_MII_CTRL_ADDRESS, reg_value);
}

void ppe_uniphy_mode_set(uint32_t uniphy_index, uint32_t mode)
{
	if (!is_uniphy_enabled(uniphy_index)) {
		printf("Uniphy %u is disabled\n", uniphy_index);
		return;
	}

	if (uniphy_cur_mode[uniphy_index] == mode)
		return;

	switch(mode) {
		case EPORT_WRAPPER_PSGMII:
			ppe_uniphy_psgmii_mode_set(uniphy_index);
			break;
		case EPORT_WRAPPER_QSGMII:
			ppe_uniphy_qsgmii_mode_set(uniphy_index);
			break;
		case EPORT_WRAPPER_SGMII0_RGMII4:
		case EPORT_WRAPPER_SGMII1_RGMII4:
		case EPORT_WRAPPER_SGMII4_RGMII4:
		case EPORT_WRAPPER_SGMII_PLUS:
		case EPORT_WRAPPER_SGMII_FIBER:
			ppe_uniphy_sgmii_mode_set(uniphy_index, mode);
			break;
		case EPORT_WRAPPER_USXGMII:
			ppe_uniphy_usxgmii_mode_set(uniphy_index);
			break;
		case EPORT_WRAPPER_10GBASE_R:
			ppe_uniphy_10g_r_mode_set(uniphy_index);
			break;
		case EPORT_WRAPPER_UQXGMII:
		case EPORT_WRAPPER_UQXGMII_3CHANNELS:
			ppe_uniphy_uqxgmii_mode_set(uniphy_index);
			break;
		default:
			return;
	}

	uniphy_cur_mode[uniphy_index] = mode;
}

void ppe_uniphy_usxgmii_autoneg_completed(uint32_t uniphy_index)
{
	uint32_t autoneg_complete = 0, retries = 100;
	uint32_t reg_value = 0;

	while (autoneg_complete != 0x1) {
		mdelay(1);
		if (retries-- == 0)
		{
			return;
		}
		reg_value = csr1_read(uniphy_index, VR_MII_AN_INTR_STS);
		autoneg_complete = reg_value & 0x1;
	}
	reg_value &= ~CL37_ANCMPLT_INTR;
	csr1_write(uniphy_index, VR_MII_AN_INTR_STS, reg_value);
}

void ppe_uniphy_usxgmii_speed_set(uint32_t uniphy_index, uint32_t port_id,
				  int speed)
{
	uint32_t reg_value = 0;

	if (port_id == PORT2)
		reg_value = csr1_read(uniphy_index, SR_MII_CTRL_CHANNEL1_ADDRESS);
	else if (port_id == PORT3)
		reg_value = csr1_read(uniphy_index, SR_MII_CTRL_CHANNEL2_ADDRESS);
	else if (port_id == PORT4)
		reg_value = csr1_read(uniphy_index, SR_MII_CTRL_CHANNEL3_ADDRESS);
	else
		reg_value = csr1_read(uniphy_index, SR_MII_CTRL_ADDRESS);

	reg_value |= DUPLEX_MODE;

	switch(speed) {
	case 0:
		reg_value &=~SS5;
		reg_value &=~SS6;
		reg_value &=~SS13;
		break;
	case 1:
		reg_value &=~SS5;
		reg_value &=~SS6;
		reg_value |=SS13;
		break;
	case 2:
		reg_value &=~SS5;
		reg_value |=SS6;
		reg_value &=~SS13;
		break;
	case 3:
		reg_value &=~SS5;
		reg_value |=SS6;
		reg_value |=SS13;
		break;
	case 4:
		reg_value |=SS5;
		reg_value &=~SS6;
		reg_value &=~SS13;
		break;
	case 5:
		reg_value |=SS5;
		reg_value &=~SS6;
		reg_value |=SS13;
		break;
	}

	if (port_id == PORT2)
		csr1_write(uniphy_index, SR_MII_CTRL_CHANNEL1_ADDRESS, reg_value);
	else if (port_id == PORT3)
		csr1_write(uniphy_index, SR_MII_CTRL_CHANNEL2_ADDRESS, reg_value);
	else if (port_id == PORT4)
		csr1_write(uniphy_index, SR_MII_CTRL_CHANNEL3_ADDRESS, reg_value);
	else
		csr1_write(uniphy_index, SR_MII_CTRL_ADDRESS, reg_value);
}

void ppe_uniphy_usxgmii_duplex_set(uint32_t uniphy_index, int duplex)
{
	uint32_t reg_value = 0;

	reg_value = csr1_read(uniphy_index, SR_MII_CTRL_ADDRESS);

	if (duplex & 0x1)
		reg_value |= DUPLEX_MODE;
	else
		reg_value &= ~DUPLEX_MODE;

	csr1_write(uniphy_index, SR_MII_CTRL_ADDRESS, reg_value);
}

void ppe_uniphy_usxgmii_port_reset(uint32_t uniphy_index)
{
	uint32_t reg_value = 0;

	reg_value = csr1_read(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS);
	reg_value |= USRA_RST;
	csr1_write(uniphy_index, VR_XS_PCS_DIG_CTRL1_ADDRESS, reg_value);
}
