/*
 * Copyright (c) 2022, The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/
#ifndef __QCA8084_IF_CTRL_H_
#define __QCA8084_IF_CTRL_H_

#define EPHY_CFG_OFFSET				0xC90F018
#define EPHY_CFG_EPHY0_ADDR_BOFFSET		0
#define EPHY_CFG_EPHY1_ADDR_BOFFSET		5
#define EPHY_CFG_EPHY2_ADDR_BOFFSET		10
#define EPHY_CFG_EPHY3_ADDR_BOFFSET		15

#define SERDES_CFG_OFFSET			0xC90F014
#define SERDES_CFG_S0_ADDR_BOFFSET		0
#define SERDES_CFG_S1_ADDR_BOFFSET		5
#define SERDES_CFG_S1_XPCS_ADDR_BOFFSET		10

#define QCA8084_UNIPHY_SGMII_0                                               0
#define QCA8084_UNIPHY_SGMII_1                                               1
#define QCA8084_UNIPHY_XPCS                                                  2

/*UNIPHY MII registers*/
#define QCA8084_UNIPHY_PLL_POWER_ON_AND_RESET                                0

/*UNIPHY MII register field*/
#define QCA8084_UNIPHY_ANA_SOFT_RESET                                        0
#define QCA8084_UNIPHY_ANA_SOFT_RELEASE                                      0x40

/*UNIPHY MMD*/
#define QCA8084_UNIPHY_MMD1                                                  0x1
#define QCA8084_UNIPHY_MMD3                                                  0x3
#define QCA8084_UNIPHY_MMD26                                                 0x1a
#define QCA8084_UNIPHY_MMD27                                                 0x1b
#define QCA8084_UNIPHY_MMD28                                                 0x1c
#define QCA8084_UNIPHY_MMD31                                                 0x1f

/*UNIPHY MMD1 registers*/
#define QCA8084_UNIPHY_MMD1_CDA_CONTROL1                                     0x20
#define QCA8084_UNIPHY_MMD1_CALIBRATION4                                     0x78
#define QCA8084_UNIPHY_MMD1_BYPASS_TUNING_IPG                                0x189
#define QCA8084_UNIPHY_MMD1_MODE_CTRL                                        0x11b
#define QCA8084_UNIPHY_MMD1_CHANNEL0_CFG                                     0x120
#define QCA8084_UNIPHY_MMD1_GMII_DATAPASS_SEL                                0x180
#define QCA8084_UNIPHY_MMD1_USXGMII_RESET                                    0x18c

/*UNIPHY MMD1 register field*/
#define QCA8084_UNIPHY_MMD1_BYPASS_TUNING_IPG_EN                             0x0fff
#define QCA8084_UNIPHY_MMD1_XPCS_MODE                                        0x1000
#define QCA8084_UNIPHY_MMD1_SGMII_MODE                                       0x400
#define QCA8084_UNIPHY_MMD1_SGMII_PLUS_MODE                                  0x800
#define QCA8084_UNIPHY_MMD1_1000BASE_X                                       0x0
#define QCA8084_UNIPHY_MMD1_SGMII_PHY_MODE                                   0x10
#define QCA8084_UNIPHY_MMD1_SGMII_MAC_MODE                                   0x20
#define QCA8084_UNIPHY_MMD1_SGMII_MODE_CTRL_MASK                             0x1f70
#define QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_MASK                             0xe
#define QCA8084_UNIPHY_MMD1_CH0_AUTONEG_ENABLE                               0x0
#define QCA8084_UNIPHY_MMD1_CH0_FORCE_ENABLE                                 0x8
#define QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_1G                               0x4
#define QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_100M                             0x2
#define QCA8084_UNIPHY_MMD1_CH0_FORCE_SPEED_10M                              0x0
#define QCA8084_UNIPHY_MMD1_DATAPASS_MASK                                    0x1
#define QCA8084_UNIPHY_MMD1_DATAPASS_USXGMII                                 0x1
#define QCA8084_UNIPHY_MMD1_DATAPASS_SGMII                                   0x0
#define QCA8084_UNIPHY_MMD1_CALIBRATION_DONE                                 0x80
#define QCA8084_UNIPHY_MMD1_SGMII_FUNC_RESET                                 0x10
#define QCA8084_UNIPHY_MMD1_SGMII_ADPT_RESET                                 0x800
#define QCA8084_UNIPHY_MMD1_SSCG_ENABLE                                      0x8

/*UNIPHY MMD3 registers*/
#define QCA8084_UNIPHY_MMD3_PCS_CTRL2                                        0x7
#define QCA8084_UNIPHY_MMD3_AN_LP_BASE_ABL2                                  0x14
#define QCA8084_UNIPHY_MMD3_10GBASE_R_PCS_STATUS1                            0x20
#define QCA8084_UNIPHY_MMD3_DIG_CTRL1                                        0x8000
#define QCA8084_UNIPHY_MMD3_EEE_MODE_CTRL                                    0x8006
#define QCA8084_UNIPHY_MMD3_VR_RPCS_TPC                                      0x8007
#define QCA8084_UNIPHY_MMD3_EEE_TX_TIMER                                     0x8008
#define QCA8084_UNIPHY_MMD3_EEE_RX_TIMER                                     0x8009
#define QCA8084_UNIPHY_MMD3_MII_AM_INTERVAL                                  0x800a
#define QCA8084_UNIPHY_MMD3_EEE_MODE_CTRL1                                   0x800b

/*UNIPHY MMD3 register field*/
#define QCA8084_UNIPHY_MMD3_PCS_TYPE_10GBASE_R                               0
#define QCA8084_UNIPHY_MMD3_10GBASE_R_UP                                     0x1000
#define QCA8084_UNIPHY_MMD3_USXGMII_EN                                       0x200
#define QCA8084_UNIPHY_MMD3_QXGMII_EN                                        0x1400
#define QCA8084_UNIPHY_MMD3_MII_AM_INTERVAL_VAL                              0x6018
#define QCA8084_UNIPHY_MMD3_XPCS_SOFT_RESET                                  0x8000
#define QCA8084_UNIPHY_MMD3_XPCS_EEE_CAP                                     0x40
#define QCA8084_UNIPHY_MMD3_EEE_RES_REGS                                     0x100
#define QCA8084_UNIPHY_MMD3_EEE_SIGN_BIT_REGS                                0x40
#define QCA8084_UNIPHY_MMD3_EEE_EN                                           0x3
#define QCA8084_UNIPHY_MMD3_EEE_TSL_REGS                                     0xa
#define QCA8084_UNIPHY_MMD3_EEE_TLU_REGS                                     0xc0
#define QCA8084_UNIPHY_MMD3_EEE_TWL_REGS                                     0x1600
#define QCA8084_UNIPHY_MMD3_EEE_100US_REG_REGS                               0xc8
#define QCA8084_UNIPHY_MMD3_EEE_RWR_REG_REGS                                 0x1c00
#define QCA8084_UNIPHY_MMD3_EEE_TRANS_LPI_MODE                               0x1
#define QCA8084_UNIPHY_MMD3_EEE_TRANS_RX_LPI_MODE                            0x100
#define QCA8084_UNIPHY_MMD3_USXG_FIFO_RESET                                  0x400

/*UNIPHY MMD26 27 28 31 registers*/
#define QCA8084_UNIPHY_MMD_MII_CTRL                                          0
#define QCA8084_UNIPHY_MMD_MII_DIG_CTRL                                      0x8000
#define QCA8084_UNIPHY_MMD_MII_AN_INT_MSK                                    0x8001
#define QCA8084_UNIPHY_MMD_MII_ERR_SEL                                       0x8002
#define QCA8084_UNIPHY_MMD_MII_XAUI_MODE_CTRL                                0x8004

/*UNIPHY MMD26 27 28 31 register field*/
#define QCA8084_UNIPHY_MMD_AN_COMPLETE_INT                                   0x1
#define QCA8084_UNIPHY_MMD_MII_4BITS_CTRL                                    0x0
#define QCA8084_UNIPHY_MMD_TX_CONFIG_CTRL                                    0x8
#define QCA8084_UNIPHY_MMD_MII_AN_ENABLE                                     0x1000
#define QCA8084_UNIPHY_MMD_MII_AN_RESTART                                    0x200
#define QCA8084_UNIPHY_MMD_MII_AN_COMPLETE_INT                               0x1
#define QCA8084_UNIPHY_MMD_USXG_FIFO_RESET                                   0x20
#define QCA8084_UNIPHY_MMD_XPC_SPEED_MASK                                    0x2060
#define QCA8084_UNIPHY_MMD_XPC_SPEED_2500                                    0x20
#define QCA8084_UNIPHY_MMD_XPC_SPEED_1000                                    0x40
#define QCA8084_UNIPHY_MMD_XPC_SPEED_100                                     0x2000
#define QCA8084_UNIPHY_MMD_XPC_SPEED_10                                      0
#define QCA8084_UNIPHY_MMD_TX_IPG_CHECK_DISABLE                              0x1

#define UNIPHY_CLK_RATE_25M         25000000
#define UNIPHY_CLK_RATE_50M         50000000
#define UNIPHY_CLK_RATE_125M        125000000
#define UNIPHY_CLK_RATE_312M        312500000
#define UNIPHY_DEFAULT_RATE         UNIPHY_CLK_RATE_125M

typedef enum {
	QCA8084_UNIPHY_MAC = QCA8084_UNIPHY_MMD1_SGMII_MAC_MODE,
	QCA8084_UNIPHY_PHY = QCA8084_UNIPHY_MMD1_SGMII_PHY_MODE,
	QCA8084_UNIPHY_SGMII = QCA8084_UNIPHY_MMD1_SGMII_MODE,
	QCA8084_UNIPHY_SGMII_PLUS = QCA8084_UNIPHY_MMD1_SGMII_PLUS_MODE,
	QCA8084_UNIPHY_UQXGMII = QCA8084_UNIPHY_MMD1_XPCS_MODE,
} qca8084_uniphy_mode_t;

typedef enum {
	QCA8084_INTERFACE_CLOCK_MAC_MODE = 0,
	QCA8084_INTERFACE_CLOCK_PHY_MODE = 1,
} qca8084_clock_mode_t;

typedef enum {
	QCA8084_MAC_MODE_RGMII = 0,
	QCA8084_MAC_MODE_GMII,
	QCA8084_MAC_MODE_MII,
	QCA8084_MAC_MODE_SGMII,
	QCA8084_MAC_MODE_FIBER,
	QCA8084_MAC_MODE_RMII,
	QCA8084_MAC_MODE_SGMII_PLUS,
	QCA8084_MAC_MODE_DEFAULT,
	QCA8084_MAC_MODE_MAX = 0xFF,
} qca8084_mac_mode_t;

typedef struct {
	qca8084_mac_mode_t mac_mode;
	qca8084_clock_mode_t clock_mode;
	bool auto_neg;
	u32 force_speed;
	bool prbs_enable;
	bool rem_phy_lpbk;
} mac_config_t;

#endif
