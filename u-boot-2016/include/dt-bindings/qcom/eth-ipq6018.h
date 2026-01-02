/*
 * Copyright (c) 2019, The Linux Foundation. All rights reserved.
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

#ifndef __DT_BINDINGS_IPQ6018_ETH_H__
#define __DT_BINDINGS_IPQ6018_ETH_H__

/* ESS Switch Mac Modes */
#define PORT_WRAPPER_PSGMII 0x0
#define PORT_WRAPPER_SGMII 0x1
#define PORT_WRAPPER_USXGMII 0x2
#define PORT_WRAPPER_QSGMII 0x5
#define PORT_WRAPPER_SGMII_PLUS 0x6
#define PORT_WRAPPER_10GBASE_R 0x7
#define PORT_WRAPPER_SGMII_FIBER 0x8
#define UNUSED 0xFF

/* ETH PHY Types */
#define MALIBU_PHY_TYPE 0x1
#define QCA8081_PHY_TYPE 0x2
#define AQ_PHY_TYPE 0x3
#define QCA8084_PHY_TYPE 0x6
#define UNUSED_PHY_TYPE 0xFF

/* QCA8x8x internal PHY mode type */
#define EPORT_WRAPPER_SGMII_PLUS	0xc
#endif
