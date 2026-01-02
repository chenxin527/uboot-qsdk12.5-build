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

#define AQ_ETHPHYFW_IMAGE_SIZE	0x80000

#define AQUANTIA_MII_ADDR_C45  (1<<30)
#define AQUANTIA_REG_ADDRESS(dev_ad, reg_num) (AQUANTIA_MII_ADDR_C45 |\
				((dev_ad & 0x1f) << 16) | (reg_num & 0xFFFF))

#define AQUANTIA_MMD_PHY_XS_REGISTERS 4
#define AQUANTIA_PHY_XS_USX_TRANSMIT 0xc441
#define AQUANTIA_PHY_USX_AUTONEG_ENABLE 0x8

#define AQUANTIA_MMD_AUTONEG 0x7
#define AQUANTIA_AUTONEG_TRANSMIT_VENDOR_INTR_MASK 0xD401
#define AQUANTIA_INTR_LINK_STATUS_CHANGE          0x0001

#define AQUANTIA_MMD_GLOABLE_REGISTERS 0x1E
#define AQUANTIA_GLOBAL_INTR_STANDARD_MASK 0xff00
#define AQUANTIA_ALL_VENDOR_ALARMS_INTERRUPT_MASK  0x0001

#define AQUANTIA_GLOBAL_INTR_VENDOR_MASK 0xff01
#define AQUANTIA_AUTO_AND_ALARMS_INTR_MASK 0x1001

#define AQUANTIA_AUTONEG_STANDARD_CONTROL1  0
#define AQUANTIA_CTRL_AUTONEGOTIATION_ENABLE      0x1000
#define AQUANTIA_CTRL_RESTART_AUTONEGOTIATION     0x0200

#define AQ_PHY_AUTO_STATUS_REG 0x70001

#define AQ_PHY_LINK_STATUS_REG 0x7c800
#define SPEED_5G	5
#define SPEED_2_5G	4
#define SPEED_10G	3
#define SPEED_1000MBS	2
#define SPEED_100MBS	1
#define SPEED_10MBS	0
