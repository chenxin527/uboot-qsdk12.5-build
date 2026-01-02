/*
 * Copyright (c) 2019, 2021, The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef __DT_BINDINGS_IPQ9574_ETH_H__
#define __DT_BINDINGS_IPQ9574_ETH_H__

/* ESS Switch Mac Modes */
#define PORT_WRAPPER_PSGMII		0
#define PORT_WRAPPER_PSGMII_RGMII5	1
#define PORT_WRAPPER_SGMII0_RGMII5	2
#define PORT_WRAPPER_SGMII1_RGMII5	3
#define PORT_WRAPPER_PSGMII_RMII0	4
#define PORT_WRAPPER_PSGMII_RMII1	5
#define PORT_WRAPPER_PSGMII_RMII0_RMII1	6
#define PORT_WRAPPER_PSGMII_RGMII4	7
#define PORT_WRAPPER_SGMII0_RGMII4	8
#define PORT_WRAPPER_SGMII1_RGMII4	9
#define PORT_WRAPPER_SGMII4_RGMII4	10
#define PORT_WRAPPER_QSGMII		11
#define PORT_WRAPPER_SGMII_PLUS		12
#define PORT_WRAPPER_USXGMII		13
#define PORT_WRAPPER_10GBASE_R		14
#define PORT_WRAPPER_SGMII_CHANNEL0	15
#define PORT_WRAPPER_SGMII_CHANNEL1	16
#define PORT_WRAPPER_SGMII_CHANNEL4	17
#define PORT_WRAPPER_RGMII		18
#define PORT_WRAPPER_PSGMII_FIBER	19
#define PORT_WRAPPER_SGMII_FIBER	20
#define PORT_WRAPPER_UQXGMII		21
#define PORT_WRAPPER_UQXGMII_3CHANNELS	22
#define PORT_WRAPPER_MAX		0xFF

/* ETH PHY Types */
#define QCA807x_PHY_TYPE		0x1
#define QCA808x_PHY_TYPE		0x2
#define AQ_PHY_TYPE			0x3
#define QCA8033_PHY_TYPE		0x4
#define SFP_PHY_TYPE			0x5
#define QCA8084_PHY_TYPE		0x6
#define UNUSED_PHY_TYPE 		0xFF
#endif

/* MDIO config */
#define MDIO_MODE_DEFAULT		0
#define MDIO_MODE_BITBANG		1
