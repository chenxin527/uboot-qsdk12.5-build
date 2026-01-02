/*
 * Copyright (c) 2015-2017, The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/
#ifndef _IPQ_MDIO_H
#define _IPQ_MDIO_H

#define IPQ_MDIO_BASE				0x90000
#define MDIO_CTRL_0_REG				0x40
#define MDIO_CTRL_1_REG				0x44
#define MDIO_CTRL_2_REG				0x48
#define MDIO_CTRL_3_REG				0x4c
#define MDIO_CTRL_4_REG				0x50
#define MDIO_CTRL_4_ACCESS_BUSY			(1 << 16)
#define MDIO_CTRL_4_ACCESS_START		(1 << 8)
#define MDIO_CTRL_4_ACCESS_CODE_READ		0
#define MDIO_CTRL_4_ACCESS_CODE_WRITE		1
#define MDIO_CTRL_4_ACCESS_CODE_C45_ADDR        0
#define MDIO_CTRL_4_ACCESS_CODE_C45_WRITE       1
#define MDIO_CTRL_4_ACCESS_CODE_C45_READ        2
#define CTRL_0_REG_DEFAULT_VALUE	        0x1500F
#ifdef MDIO_12_5_MHZ
#define CTRL_0_REG_C45_DEFAULT_VALUE	        0x15107
#else
#define CTRL_0_REG_C45_DEFAULT_VALUE		0x1510F
#endif
#define CTRL_0_REG_C45_DEFAULT_VALUE_3_1M	0x1511F
#define IPQ_MDIO_RETRY				1000
#define IPQ_MDIO_DELAY				5

#ifdef CONFIG_QCA8084_PHY
/* QCA8084 related MDIO Init macros */
#define UNIPHY_CFG				0xC90F014
#define EPHY_CFG				0xC90F018
#define GEPHY0_TX_CBCR				0xC800058
#define SRDS0_SYS_CBCR				0xC8001A8
#define SRDS1_SYS_CBCR				0xC8001AC
#define EPHY0_SYS_CBCR				0xC8001B0
#define EPHY1_SYS_CBCR				0xC8001B4
#define EPHY2_SYS_CBCR				0xC8001B8
#define EPHY3_SYS_CBCR				0xC8001BC
#define QCA8084_GCC_GEPHY_MISC			0xC800304
#define QFPROM_RAW_PTE_ROW2_MSB			0xC900014
#define QFPROM_RAW_CALIBRATION_ROW4_LSB 	0xC900048
#define QFPROM_RAW_CALIBRATION_ROW6_MSB 	0xC90005C
#define QFPROM_RAW_CALIBRATION_ROW7_LSB 	0xC900060
#define QFPROM_RAW_CALIBRATION_ROW8_LSB 	0xC900068
#define PHY_ADDR_LENGTH				5
#define PHY_ADDR_NUM				4
#define UNIPHY_ADDR_NUM				3
#define MII_HIGH_ADDR_PREFIX			0x18
#define MII_LOW_ADDR_PREFIX			0x10
#define PHY_DEBUG_PORT_ADDR			0x1d
#define PHY_DEBUG_PORT_DATA			0x1e
#define PHY_LDO_EFUSE_REG			0x180
#define PHY_ICC_EFUSE_REG			0x280

DEFINE_MUTEX(switch_mdio_lock);
#endif /* End QCA8084_PHY */

#endif /* End _IPQ_MDIO_H */
