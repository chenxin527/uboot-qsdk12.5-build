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
#define PPE_UNIPHY_INSTANCE0			0
#define PPE_UNIPHY_INSTANCE1			1
#define PPE_UNIPHY_INSTANCE2			2

#define PPE_MAX_UNIPHY_INSTANCE			3
#define GCC_UNIPHY_REG_INC 			0x10

#define PPE_UNIPHY_OFFSET_CALIB_4		0x1E0
#define UNIPHY_CALIBRATION_DONE			0x1

#define PPE_UNIPHY_BASE				0X07A00000
#define PPE_UNIPHY_REG_INC 			0x10000
#define PPE_UNIPHY_MODE_CONTROL			0x46C
#define UNIPHY_XPCS_MODE			(1 << 12)
#define UNIPHY_SG_PLUS_MODE			(1 << 11)
#define UNIPHY_SG_MODE				(1 << 10)
#define UNIPHY_CH0_PSGMII_QSGMII		(1 << 9)
#define UNIPHY_CH0_QSGMII_SGMII			(1 << 8)
#define UNIPHY_CH4_CH1_0_SGMII			(1 << 2)
#define UNIPHY_CH1_CH0_SGMII			(1 << 1)
#define UNIPHY_CH0_ATHR_CSCO_MODE_25M		(1 << 0)

#define UNIPHY_INSTANCE_LINK_DETECT		0x570
#define UNIPHYQP_USXG_OPITON1			0x584

#define UNIPHY_MISC2_REG_OFFSET 		0x218
#define UNIPHY_MISC2_REG_SGMII_MODE 		0x30
#define UNIPHY_MISC2_REG_SGMII_PLUS_MODE 	0x50

#define UNIPHY_MISC2_REG_VALUE			0x70

#define UNIPHY_MISC_SOURCE_SELECTION_REG_OFFSET	0x21c
#define UNIPHY_MISC_SRC_PHY_MODE		0xa882

#define UNIPHY_DEC_CHANNEL_0_INPUT_OUTPUT_4	0x480
#define UNIPHY_FORCE_SPEED_25M			(1 << 3)

#define UNIPHY_PLL_RESET_REG_OFFSET 		0x780
#define UNIPHY_PLL_RESET_REG_VALUE 		0x02bf
#define UNIPHY_PLL_RESET_REG_DEFAULT_VALUE 	0x02ff

#define SR_XS_PCS_KR_STS1_ADDRESS 		0x30020
#define UNIPHY_10GR_LINKUP 			0x1

#define VR_XS_PCS_DIG_CTRL1_ADDRESS 		0x38000
#define VR_XS_PCS_EEE_MCTRL0_ADDRESS		0x38006
#define VR_XS_PCS_KR_CTRL_ADDRESS		0x38007
#define VR_XS_PCS_EEE_TXTIMER_ADDRESS		0x38008
#define VR_XS_PCS_EEE_RXTIMER_ADDRESS		0x38009
#define VR_XS_PCS_DIG_STS_ADDRESS		0x3800a
#define VR_XS_PCS_EEE_MCTRL1_ADDRESS		0x3800b

#define SIGN_BIT				(1 << 6)
#define MULT_FACT_100NS				(1 << 8)
#define GMII_SRC_SEL				(1 << 0)
#define USXG_EN					(1 << 9)
#define USXG_MODE				(5 << 10)
#define USRA_RST				(1 << 10)
#define AM_COUNT				(0x6018 << 0)
#define VR_RST					(1 << 15)
#define UNIPHY_XPCS_TSL_TIMER			(0xa << 0)
#define UNIPHY_XPCS_TLU_TIMER			(0x3 << 6)
#define UNIPHY_XPCS_TWL_TIMER			(0x16 << 8)
#define UNIPHY_XPCS_100US_TIMER			(0xc8 << 0)
#define UNIPHY_XPCS_TWR_TIMER			(0x1c << 8)
#define TRN_LPI					(1 << 0)
#define TRN_RXLPI				(1 << 8)
#define LRX_EN					(1 << 0)
#define LTX_EN					(1 << 1)

#define VR_MII_AN_CTRL_CHANNEL1_ADDRESS		0x1a8001
#define VR_MII_AN_CTRL_CHANNEL2_ADDRESS		0x1b8001
#define VR_MII_AN_CTRL_CHANNEL3_ADDRESS		0x1c8001
#define VR_MII_AN_CTRL_ADDRESS			0x1f8001
#define MII_AN_INTR_EN				(1 << 0)
#define MII_CTRL				(1 << 8)

#define VR_XAUI_MODE_CTRL_CHANNEL1_ADDRESS	0x1a8004
#define VR_XAUI_MODE_CTRL_CHANNEL2_ADDRESS	0x1b8004
#define VR_XAUI_MODE_CTRL_CHANNEL3_ADDRESS	0x1c8004
#define VR_XAUI_MODE_CTRL_ADDRESS		0x1f8004
#define IPG_CHECK				0x1

#define SR_MII_CTRL_CHANNEL1_ADDRESS		0x1a0000
#define SR_MII_CTRL_CHANNEL2_ADDRESS		0x1b0000
#define SR_MII_CTRL_CHANNEL3_ADDRESS		0x1c0000
#define SR_MII_CTRL_ADDRESS 			0x1f0000
#define AN_ENABLE				(1 << 12)
#define SS5					(1 << 5)
#define SS6					(1 << 6)
#define SS13					(1 << 13)
#define DUPLEX_MODE				(1 << 8)

#define VR_MII_AN_INTR_STS			0x1f8002
#define CL37_ANCMPLT_INTR			(1 << 0)

enum uniphy_reset_type {
	UNIPHY0_SOFT_RESET = 0,
	UNIPHY0_XPCS_RESET,
	UNIPHY1_SOFT_RESET,
	UNIPHY1_XPCS_RESET,
	UNIPHY2_SOFT_RESET,
	UNIPHY2_XPCS_RESET,
	UNIPHY_RST_MAX
};

void ppe_uniphy_mode_set(uint32_t uniphy_index, uint32_t mode);
void ppe_uniphy_usxgmii_port_reset(uint32_t uniphy_index);
void ppe_uniphy_usxgmii_duplex_set(uint32_t uniphy_index, int duplex);
void ppe_uniphy_usxgmii_speed_set(uint32_t uniphy_index, uint32_t port_id, int speed);
void ppe_uniphy_usxgmii_autoneg_completed(uint32_t uniphy_index);
