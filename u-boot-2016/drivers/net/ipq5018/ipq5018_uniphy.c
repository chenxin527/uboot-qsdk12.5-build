/*
 * Copyright (c) 2017-2020, The Linux Foundation. All rights reserved.
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
#include <net.h>
#include <asm-generic/errno.h>
#include <asm/io.h>
#include <malloc.h>
#include <phy.h>
#include <net.h>
#include <miiphy.h>
#include "ipq5018_uniphy.h"
#include "ipq_phy.h"

static uint32_t cur_mode;

static int ppe_uniphy_calibration(void)
{
	int retries = 100, calibration_done = 0;
	uint32_t reg_value = 0;

	while(calibration_done != UNIPHY_CALIBRATION_DONE) {
		mdelay(1);
		if (retries-- == 0) {
			printf("uniphy callibration time out!\n");
			return -1;
		}
		reg_value = readl(PPE_UNIPHY_BASE + PPE_UNIPHY_OFFSET_CALIB_4);
		calibration_done = (reg_value >> 0x7) & 0x1;
	}

	return 0;
}

static void ppe_gcc_uniphy_soft_reset(void)
{
	uint32_t reg_value;

	reg_value = readl(GCC_UNIPHY0_MISC);

	reg_value |= GCC_UNIPHY_SGMII_SOFT_RESET;

	writel(reg_value, GCC_UNIPHY0_MISC);

	udelay(500);

	reg_value &= ~GCC_UNIPHY_SGMII_SOFT_RESET;

	writel(reg_value, GCC_UNIPHY0_MISC);
}

void uniphy_channel0_input_output_6_get(int mode, u32 gpio, u8 *status,
					fal_port_speed_t *speed,
					fal_port_duplex_t *duplex)
{
	uint32_t reg_value;
	int val;

	*status = 1;
	*speed = FAL_SPEED_BUTT;
	*duplex = FAL_DUPLEX_BUTT;

	reg_value = readl(PPE_UNIPHY_BASE + UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_6);

	val = reg_value & CH0_LINK_MAC;

	if (val) {
		switch(mode) {
			case PORT_WRAPPER_SGMII_FIBER:
				*status = 0; /* LINK UP */
				break;
			case PORT_WRAPPER_SGMII_PLUS:
				/*
				 * get rx_los status
				 * if, rx_los = 0, link up
				 * else, link down
				 */
				if (gpio && !gpio_get_value(gpio)) {
					*status = 0;
					*speed = FAL_SPEED_2500;
					*duplex = FAL_FULL_DUPLEX;
				}
				return;
			default:
				printf("%s: Invalid mode\n", __func__);
				break;
		}
	}

	val = (reg_value & CH0_SPEED_MODE_MAC) >> 4;

	switch(val) {
		case UNIPHY_SPEED_1000M:
			*speed = FAL_SPEED_1000;
			break;
		case UNIPHY_SPEED_100M:
			*speed = FAL_SPEED_100;
			break;
		case UNIPHY_SPEED_10M:
			*speed = FAL_SPEED_10;
			break;
		default:
			*speed = FAL_SPEED_BUTT;
			break;

	}

	val = (reg_value & CH0_DUPLEX_MODE_MAC) >> 6;

	if (val)
		*duplex = FAL_FULL_DUPLEX;
	else
		*duplex = FAL_HALF_DUPLEX;

	return;
}

static void ppe_uniphy_sgmii_mode_set(uint32_t mode, uint32_t phy_mode)
{
	writel(UNIPHY_MISC2_REG_SGMII_MODE,
		PPE_UNIPHY_BASE + UNIPHY_MISC2_REG_OFFSET);

	writel(UNIPHY_PLL_RESET_REG_VALUE, PPE_UNIPHY_BASE +
		UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(10);
	writel(UNIPHY_PLL_RESET_REG_DEFAULT_VALUE, PPE_UNIPHY_BASE +
		UNIPHY_PLL_RESET_REG_OFFSET);
	mdelay(10);

	writel(0x0, GCC_UNIPHY_RX_CBCR);
	udelay(500);
	writel(0x0, GCC_UNIPHY_TX_CBCR);
	udelay(500);
	writel(0x0, GCC_GMAC1_RX_CBCR);
	udelay(500);
	writel(0x0, GCC_GMAC1_TX_CBCR);
	udelay(500);

	switch (mode) {
		case PORT_WRAPPER_SGMII_FIBER:
			writel(UNIPHY_SG_MODE, PPE_UNIPHY_BASE + PPE_UNIPHY_MODE_CONTROL);
			break;

		case PORT_WRAPPER_SGMII0_RGMII4:
		case PORT_WRAPPER_SGMII1_RGMII4:
		case PORT_WRAPPER_SGMII4_RGMII4:
			writel((UNIPHY_SG_MODE | UNIPHY_PSGMII_MAC_MODE),
					PPE_UNIPHY_BASE + PPE_UNIPHY_MODE_CONTROL);
			break;

		case PORT_WRAPPER_SGMII_PLUS:
			writel((UNIPHY_SG_PLUS_MODE | UNIPHY_PSGMII_MAC_MODE),
					PPE_UNIPHY_BASE + PPE_UNIPHY_MODE_CONTROL);
			break;

		default:
			printf("SGMII Config. wrongly");
			break;
	}
	if ((cur_mode == PORT_WRAPPER_SGMII_PLUS) ||
		(mode == PORT_WRAPPER_SGMII_PLUS)){
		cur_mode = mode;
		ppe_gcc_uniphy_soft_reset();
	}

	writel(phy_mode, PPE_UNIPHY_BASE + PPE_UNIPHY_ALLREG_DEC_MISC2);

	writel(0x1, GCC_UNIPHY_RX_CBCR);
	udelay(500);
	writel(0x1, GCC_UNIPHY_TX_CBCR);
	udelay(500);
	writel(0x1, GCC_GMAC1_RX_CBCR);
	udelay(500);
	writel(0x1, GCC_GMAC1_TX_CBCR);
	udelay(500);

	ppe_uniphy_calibration();
}

void ppe_uniphy_mode_set(uint32_t mode, uint32_t phy_mode)
{
	/*
	 * SGMII and SHMII plus confugure in same function
	 */
	ppe_uniphy_sgmii_mode_set(mode, phy_mode);
}

void ppe_uniphy_set_forceMode(void)
{
	uint32_t reg_value;

	reg_value = readl(PPE_UNIPHY_BASE + UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_4);
	reg_value |= UNIPHY_FORCE_SPEED_25M;

	writel(reg_value, PPE_UNIPHY_BASE + UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_4);

}

void ppe_uniphy_refclk_set(void)
{
/*
 * This function drive the uniphy ref clock
 * DEC_REFCLKOUTPUTCONTROLREGISTERS
 * Its is configured as 25 MHZ
 */

	u32 reg_val = readl(PPE_UNIPHY_BASE | UNIPHY_REF_CLK_CTRL_REG);
	reg_val |= 0x2;
	writel(reg_val, PPE_UNIPHY_BASE | UNIPHY_REF_CLK_CTRL_REG);
	mdelay(200);
}
