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

#ifndef _IPQ5018_UNIPHY_H_
#define _IPQ5018_UNIPHY_H
#include "ipq_phy.h"

#define PPE_UNIPHY_INSTANCE0			0

#define GCC_UNIPHY_RX_CBCR			0x01856110
#define GCC_UNIPHY_TX_CBCR			0x01856114

#define GCC_GMAC1_RX_CBCR			0x01868248
#define GCC_GMAC1_TX_CBCR			0x0186824C

#define GCC_UNIPHY0_MISC			0x01856104

#define PPE_UNIPHY_OFFSET_CALIB_4		0x1E0
#define UNIPHY_CALIBRATION_DONE			0x1

#define GCC_UNIPHY_PSGMII_SOFT_RESET 		0x3ff2
#define GCC_UNIPHY_SGMII_SOFT_RESET 		0x32

#define PPE_UNIPHY_BASE				0x00098000
#define PPE_UNIPHY_MODE_CONTROL			0x46C
#define PPE_UNIPHY_ALLREG_DEC_MISC2		0x218
#define UNIPHY_XPCS_MODE			(1 << 12)
#define UNIPHY_SG_PLUS_MODE			(1 << 11)
#define UNIPHY_SG_MODE				(1 << 10)
#define UNIPHY_CH0_PSGMII_QSGMII		(1 << 9)
#define UNIPHY_CH0_QSGMII_SGMII			(1 << 8)
#define UNIPHY_PSGMII_MAC_MODE			(1 << 5)
#define UNIPHY_CH4_CH1_0_SGMII			(1 << 2)
#define UNIPHY_CH1_CH0_SGMII			(1 << 1)
#define UNIPHY_CH0_ATHR_CSCO_MODE_25M		(1 << 0)

#define UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_4	0x480
#define UNIPHY_FORCE_SPEED_25M			(1 << 3)

#define UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_6	0x488
#define CH0_LINK_MAC				(1 << 7)
#define CH0_DUPLEX_MODE_MAC			(1 << 6)
#define CH0_SPEED_MODE_MAC			(3 << 4)

#define UNIPHY_REF_CLK_CTRL_REG			0x74

#define UNIPHY_INSTANCE_LINK_DETECT		0x570

#define UNIPHY_MISC2_REG_OFFSET 		0x218
#define UNIPHY_MISC2_REG_SGMII_MODE 		0x30
#define UNIPHY_MISC2_REG_SGMII_PLUS_MODE 	0x50

#define UNIPHY_MISC2_REG_VALUE			0x70

#define UNIPHY_PLL_RESET_REG_OFFSET 		0x780
#define UNIPHY_PLL_RESET_REG_VALUE 		0x02bf
#define UNIPHY_PLL_RESET_REG_DEFAULT_VALUE 	0x02ff

#define UNIPHY_SPEED_10M			0
#define UNIPHY_SPEED_100M			1
#define UNIPHY_SPEED_1000M			2

void ppe_uniphy_mode_set(uint32_t mode, uint32_t phy_mode);
void ppe_uniphy_set_forceMode(void);
void ppe_uniphy_refclk_set(void);
void uniphy_channel0_input_output_6_get(int mode, u32 gpio, u8 *status,
					fal_port_speed_t *speed,
					fal_port_duplex_t *duplex);
#endif
