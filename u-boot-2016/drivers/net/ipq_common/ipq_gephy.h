/*
 * Copyright (c) 2018, 2020 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/

#ifndef _IPQ_GEPHY_H_
#define _IPQ_GEPHY_H_

/* PHY Registers */
#define GEPHY_PHY_CONTROL			0
#define GEPHY_PHY_STATUS			1
#define GEPHY_PHY_SPEC_STATUS			17

#define GEPHY_PHY_ID1				2
#define GEPHY_PHY_ID2				3
#define GEPHY_AUTONEG_ADVERT			4
#define GEPHY_LINK_PARTNER_ABILITY		5
#define GEPHY_1000BASET_CONTROL		9
#define GEPHY_1000BASET_STATUS		10
#define GEPHY_MMD_CTRL_REG			13
#define GEPHY_MMD_DATA_REG			14
#define GEPHY_EXTENDED_STATUS			15
#define GEPHY_PHY_SPEC_CONTROL		16
#define GEPHY_PHY_INTR_MASK			18
#define GEPHY_PHY_INTR_STATUS			19
#define GEPHY_PHY_CDT_CONTROL			22
#define GEPHY_DEBUG_PORT_ADDRESS		29
#define GEPHY_DEBUG_PORT_DATA			30

#define GEPHY_STATUS_LINK_PASS		0x0400

#define GEPHY_STATUS_FULL_DUPLEX		0x2000

#define GEPHY_STATUS_SPEED_MASK		0x380
#define GEPHY_STATUS_SPEED_2500MBS		0x200
#define GEPHY_STATUS_SPEED_1000MBS		0x100
#define GEPHY_STATUS_SPEED_100MBS		0x80
#define GEPHY_STATUS_SPEED_10MBS		0x0000

#define QCA808X_PHY_MMD3_AZ_TRAINING_VAL	0x1c32
#define QCA808X_PHY_MMD3_NUM			3
#define QCA808X_PHY_MMD3_ADDR_CLD_CTRL7		0x8007
#define QCA808X_PHY_MMD3_AZ_TRAINING_CTRL	0x8008
#define QCA808X_PHY_8023AZ_AFE_CTRL_MASK	0x01f0
#define QCA808X_PHY_8023AZ_AFE_EN		0x0090
#define QCA808X_MII_ADDR_C45			(1<<30)
#define QCA808X_REG_C45_ADDRESS(dev_type, reg_num) (QCA808X_MII_ADDR_C45 | \
                        ((dev_type & 0x1f) << 16) | (reg_num & 0xffff))
#define QCA808X_8023AZ_ENABLE_VGA QCA808X_REG_C45_ADDRESS(QCA808X_PHY_MMD3_NUM, \
			QCA808X_PHY_MMD3_ADDR_CLD_CTRL7)
#define QCA808X_AZ_CONFIG_UNDER_1G_SPEED QCA808X_REG_C45_ADDRESS(QCA808X_PHY_MMD3_NUM, \
			QCA808X_PHY_MMD3_AZ_TRAINING_CTRL)

#endif				/* _GEPHY_PHY_H_ */
