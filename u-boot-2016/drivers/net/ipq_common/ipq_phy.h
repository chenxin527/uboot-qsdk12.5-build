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

#ifndef _IPQ_EDMA_H
#define _IPQ_EDMA_H

#include <common.h>
#include <net.h>
#ifdef CONFIG_ATHRS17C_SWITCH
#include "athrs17_phy.h"
#endif

#define PHY_MAX		6
#define IPQ9574_PHY_MAX	6
#define IPQ6018_PHY_MAX 5
#define IPQ5332_PHY_MAX	2

#define QCA8084_MAX_PORTS	6

#define MDIO_CTRL_0_REG		0x00090040
#define MDIO_CTRL_0_DIV(x)	(x << 0)
#define MDIO_CTRL_0_MODE	(1 << 8)
#define MDIO_CTRL_0_RES(x)	(x << 9)
#define MDIO_CTRL_0_MDC_MODE	(1 << 12)
#define MDIO_CTRL_0_GPHY(x)	(x << 13)
#define MDIO_CTRL_0_RES1(x)	(x << 17)

#define PORT_LINK_DOWN		0
#define PORT_LINK_UP		1
#define GP_PULL_DOWN		1
#define GP_OE_EN		(1 << 9)
#define GP_VM_EN		(1 << 11)
#define GP_PU_RES(x)		(x << 13)
#define QCA8075_RST_VAL		(GP_PULL_DOWN | GP_OE_EN | \
				GP_VM_EN | GP_PU_RES(2))
#define QCA8337_PHY				0x004DD036
#define QCA8075_PHY_V1_0_5P			0x004DD0B0
#define QCA8075_PHY_V1_1_5P			0x004DD0B1
#define QCA8075_PHY_V1_1_2P			0x004DD0B2
#define QCA8033_PHY				0x004DD074
#define QCA8033_PHY_ADDR			0x6
#define QCA8081_PHY				0x004DD100
#define QCA8081_1_1_PHY				0x004DD101
#define QCA8084_PHY				0x004DD180
#define AQUANTIA_PHY_107			0x03a1b4e2
#define AQUANTIA_PHY_109			0x03a1b502
#define AQUANTIA_PHY_111			0x03a1b610
#define AQUANTIA_PHY_111B0			0x03a1b612
#define AQUANTIA_PHY_112			0x03a1b660
#define AQUANTIA_PHY_112C			0x03a1b792
#define AQUANTIA_PHY_113C_A0			0x31c31C10
#define AQUANTIA_PHY_113C_A1			0x31c31C11
#define AQUANTIA_PHY_113C_B0			0x31c31C12
#define AQUANTIA_PHY_113C_B1			0x31c31C13
#define MARVELL_PHY_X3410			0x31c31DD3
#define AQU_PHY_ADDR				0x7
#define QCA_PHY_ID1				0x2
#define QCA_PHY_ID2				0x3

/* Phy preferred medium type */
typedef enum {
	QCA8075_PHY_MEDIUM_COPPER = 0,
	QCA8075_PHY_MEDIUM_FIBER = 1, /**< Fiber */
} qca8075_phy_medium_t;

/* Phy pages */
typedef enum {
	QCA8075_PHY_SGBX_PAGES = 0, /* sgbx pages */
	QCA8075_PHY_COPPER_PAGES = 1 /* copper pages */
} qca8075_phy_reg_pages_t;

typedef enum {
	FAL_HALF_DUPLEX = 0,
	FAL_FULL_DUPLEX,
	FAL_DUPLEX_BUTT = 0xffff
} fal_port_duplex_t;

typedef enum {
	FAL_SPEED_10 = 10,
	FAL_SPEED_100 = 100,
	FAL_SPEED_1000 = 1000,
	FAL_SPEED_2500 = 2500,
	FAL_SPEED_5000 = 5000,
	FAL_SPEED_10000 = 10000,
	FAL_SPEED_BUTT = 0xffff,
} fal_port_speed_t;

typedef enum {
	FAL_CABLE_STATUS_NORMAL = 0,
	FAL_CABLE_STATUS_SHORT = 1,
	FAL_CABLE_STATUS_OPENED = 2,
	FAL_CABLE_STATUS_INVALID = 3,
	FAL_CABLE_STATUS_BUTT = 0xffff,
} fal_cable_status_t;

enum eport_wrapper_cfg {
	EPORT_WRAPPER_PSGMII = 0,
	EPORT_WRAPPER_PSGMII_RGMII5,
	EPORT_WRAPPER_SGMII0_RGMII5,
	EPORT_WRAPPER_SGMII1_RGMII5,
	EPORT_WRAPPER_PSGMII_RMII0,
	EPORT_WRAPPER_PSGMII_RMII1,
	EPORT_WRAPPER_PSGMII_RMII0_RMII1,
	EPORT_WRAPPER_PSGMII_RGMII4,
	EPORT_WRAPPER_SGMII0_RGMII4,
	EPORT_WRAPPER_SGMII1_RGMII4,
	EPORT_WRAPPER_SGMII4_RGMII4,
	EPORT_WRAPPER_QSGMII,
	EPORT_WRAPPER_SGMII_PLUS,
	EPORT_WRAPPER_USXGMII,
	EPORT_WRAPPER_10GBASE_R,
	EPORT_WRAPPER_SGMII_CHANNEL0,
	EPORT_WRAPPER_SGMII_CHANNEL1,
	EPORT_WRAPPER_SGMII_CHANNEL4,
	EPORT_WRAPPER_RGMII,
	EPORT_WRAPPER_PSGMII_FIBER,
	EPORT_WRAPPER_SGMII_FIBER,
	EPORT_WRAPPER_UQXGMII, /* for four channels qca8084 phy mode*/
	EPORT_WRAPPER_UQXGMII_3CHANNELS, /* for three channels qca8084 phy mode */
	EPORT_WRAPPER_MAX = 0xFF
};

enum port_wrapper_cfg {
	PORT_WRAPPER_PSGMII = 0,
	PORT_WRAPPER_SGMII0_RGMII4,
	PORT_WRAPPER_USXGMII,
	PORT_WRAPPER_SGMII1_RGMII4,
	PORT_WRAPPER_SGMII4_RGMII4,
	PORT_WRAPPER_QSGMII,
	PORT_WRAPPER_SGMII_PLUS,
	PORT_WRAPPER_10GBASE_R,
	PORT_WRAPPER_SGMII_FIBER,
};

enum phy_mode {
	MALIBU_PHY_TYPE = 1,
	QCA8081_PHY_TYPE = 2,
	AQ_PHY_TYPE = 3,
	QCA8033_PHY_TYPE = 4,
	SFP_PHY_TYPE = 5,
	QCA8084_PHY_TYPE = 6,
	ATHRS17C_SWITCH_TYPE = 7,
	UNUSED_PHY_TYPE = 0xFF,
};

typedef struct {
	u32 phy_address;
	u32 phy_type;
	u32 forced_speed;
	u32 forced_duplex;
}phy_info_t;

typedef struct {
	u32 mode;
	u32 bus_no;
}mdio_info_t;

struct phy_ops {
	u8 (*phy_get_link_status) (u32 dev_id, u32 phy_id);
	u32 (*phy_get_duplex) (u32 dev_id, u32 phy_id,
				fal_port_duplex_t * duplex);
	u32 (*phy_get_speed) (u32 dev_id, u32 phy_id,
				fal_port_speed_t * speed);
};
#endif /* _IPQ_EDMA_H */
