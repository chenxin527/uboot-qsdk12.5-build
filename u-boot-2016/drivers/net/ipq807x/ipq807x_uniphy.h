/*
 * Copyright (c) 2017, The Linux Foundation. All rights reserved.
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

#define GCC_UNIPHY0_MISC			0x01856004
#define GCC_UNIPHY_REG_INC 			0x100
#define GCC_UNIPHY_USXGMII_XPCS_RESET 		0x4
#define GCC_UNIPHY_USXGMII_XPCS_RELEASE_RESET	0x0

#define PPE_UNIPHY_OFFSET_CALIB_4		0x1E0
#define UNIPHY_CALIBRATION_DONE			0x1

#define GCC_UNIPHY_PSGMII_SOFT_RESET 		0x3ff2
#define GCC_UNIPHY_USXGMII_SOFT_RESET 		0x36

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

#define UNIPHY_MISC2_REG_OFFSET 		0x218
#define UNIPHY_MISC2_REG_SGMII_MODE 		0x30
#define UNIPHY_MISC2_REG_SGMII_PLUS_MODE 	0x50

#define UNIPHY_MISC2_REG_VALUE			0x70

#define UNIPHY_PLL_RESET_REG_OFFSET 		0x780
#define UNIPHY_PLL_RESET_REG_VALUE 		0x02bf
#define UNIPHY_PLL_RESET_REG_DEFAULT_VALUE 	0x02ff

#define SR_XS_PCS_KR_STS1_ADDRESS 		0x30020
#define UNIPHY_10GR_LINKUP 			0x1

#define VR_XS_PCS_DIG_CTRL1_ADDRESS 		0x38000
#define USXG_EN					(1 << 9)
#define USRA_RST				(1 << 10)

#define VR_MII_AN_CTRL_ADDRESS			0x1f8001
#define MII_AN_INTR_EN				(1 << 0)
#define MII_CTRL				(1 << 8)

#define SR_MII_CTRL_ADDRESS 			0x1f0000
#define AN_ENABLE				(1 << 12)
#define SS5					(1 << 5)
#define SS6					(1 << 6)
#define SS13					(1 << 13)
#define DUPLEX_MODE				(1 << 8)

#define VR_MII_AN_INTR_STS			0x1f8002
#define CL37_ANCMPLT_INTR			(1 << 0)

void ppe_uniphy_mode_set(uint32_t uniphy_index, uint32_t mode);
void ppe_uniphy_usxgmii_port_reset(uint32_t uniphy_index);
void ppe_uniphy_usxgmii_duplex_set(uint32_t uniphy_index, int duplex);
void ppe_uniphy_usxgmii_speed_set(uint32_t uniphy_index, int speed);
void ppe_uniphy_usxgmii_autoneg_completed(uint32_t uniphy_index);
