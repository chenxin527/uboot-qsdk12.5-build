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
#include "ipq_phy.h"
#include "ipq_qca8084_clk.h"
#include <div64.h>
#include <linux/compat.h>
#include <malloc.h>
#include <command.h>

#define QCA8084_PORT_CLK_CBC_MAX		8
/* 2 uniphy with rx and tx */
#define QCA8084_UNIPHY_INSTANCE			2

#ifdef DEBUG
#define pr_debug(fmt, args...) printf(fmt, ##args);
#else
#define pr_debug(fmt, args...)
#endif

extern uint32_t ipq_mii_read(uint32_t reg);
extern void ipq_mii_write(uint32_t reg, uint32_t val);
extern void ipq_mii_update(uint32_t reg, uint32_t mask, uint32_t val);

static uint64_t qca8084_uniphy_raw_clock[QCA8084_UNIPHY_INSTANCE * 2] = {0};

static const unsigned long qca8084_switch_core_support_rates[] = {
	UQXGMII_SPEED_2500M_CLK,
};

static const unsigned long qca8084_cpuport_clk_support_rates[] = {
	UQXGMII_SPEED_10M_CLK,
	UQXGMII_SPEED_100M_CLK,
	UQXGMII_SPEED_1000M_CLK,
	UQXGMII_SPEED_2500M_CLK,
};

static const unsigned long qca8084_phyport_clk_support_rates[] = {
	UQXGMII_SPEED_10M_CLK,
	UQXGMII_SPEED_100M_CLK,
	UQXGMII_SPEED_1000M_CLK,
	UQXGMII_SPEED_2500M_CLK,
	UQXGMII_XPCS_SPEED_2500M_CLK,
};

static const unsigned long qca8084_ahb_clk_support_rates[] = {
	QCA8084_AHB_CLK_RATE_104P17M
};

static const unsigned long qca8084_sys_clk_support_rates[] = {
	QCA8084_SYS_CLK_RATE_25M,
};

static const struct qca8084_parent_data qca8084_switch_core_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX312P5M, 1 },
};

static const struct qca8084_parent_data qca8084_mac0_tx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 } ,
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY1_TX, 2 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX, 2 },
};

static const struct qca8084_parent_data qca8084_mac0_rx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 } ,
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY1_RX, 1 },
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY1_TX, 2 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_RX, 1 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX, 2 },
};

/* port 1, 2, 3 rx/tx clock have the same parents */
static const struct qca8084_parent_data qca8084_mac1_tx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 } ,
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX312P5M, 6 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_RX312P5M, 7 },
};

static const struct qca8084_parent_data qca8084_mac1_rx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX312P5M, 6 },
};

static const struct qca8084_parent_data qca8084_mac4_tx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY0_RX, 1 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY0_RX, 1 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX312P5M, 3 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_RX312P5M, 7 },
};

static const struct qca8084_parent_data qca8084_mac4_rx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY0_TX, 2 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY0_TX, 2 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX312P5M, 3 },
};

static const struct qca8084_parent_data qca8084_mac5_tx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY0_TX, 2 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY0_TX, 2 },
};

static const struct qca8084_parent_data qca8084_mac5_rx_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY0_RX, 1 },
	{ UQXGMII_SPEED_1000M_CLK, QCA8084_P_UNIPHY0_TX, 2 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY0_RX, 1 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY0_TX, 2 },
};

static const struct qca8084_parent_data qca8084_ahb_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
	{ UQXGMII_SPEED_2500M_CLK, QCA8084_P_UNIPHY1_TX312P5M, 2 },
};

static const struct qca8084_parent_data qca8084_sys_clk_pdata[] = {
	{ QCA8084_XO_CLK_RATE_50M, QCA8084_P_XO, 0 },
};

static struct clk_lookup qca8084_clk_lookup_table[] = {
	/* switch core clock */
	CLK_LOOKUP(4, 0, 8, CBCR_CLK_RESET,
			QCA8084_SWITCH_CORE_CLK,
			qca8084_switch_core_support_rates, ARRAY_SIZE(qca8084_switch_core_support_rates),
			qca8084_switch_core_pdata, ARRAY_SIZE(qca8084_switch_core_pdata)),
	CLK_LOOKUP(4, 0, 0x10, CBCR_CLK_RESET,
			QCA8084_APB_BRIDGE_CLK,
			qca8084_switch_core_support_rates, ARRAY_SIZE(qca8084_switch_core_support_rates),
			qca8084_switch_core_pdata, ARRAY_SIZE(qca8084_switch_core_pdata)),
	/* port 0 tx clock */
	CLK_LOOKUP(0x18, 0x1c, 0x20, CBCR_CLK_RESET,
			QCA8084_MAC0_TX_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac0_tx_clk_pdata, ARRAY_SIZE(qca8084_mac0_tx_clk_pdata)),
	CLK_LOOKUP(0x18, 0x1c, 0x24, CBCR_CLK_RESET,
			QCA8084_MAC0_TX_UNIPHY1_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac0_tx_clk_pdata, ARRAY_SIZE(qca8084_mac0_tx_clk_pdata)),
	/* port 0 rx clock */
	CLK_LOOKUP(0x2c, 0x30, 0x34, CBCR_CLK_RESET,
			QCA8084_MAC0_RX_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac0_rx_clk_pdata, ARRAY_SIZE(qca8084_mac0_rx_clk_pdata)),
	CLK_LOOKUP(0x2c, 0x30, 0x3c, CBCR_CLK_RESET,
			QCA8084_MAC0_RX_UNIPHY1_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac0_rx_clk_pdata, ARRAY_SIZE(qca8084_mac0_rx_clk_pdata)),
	/* port 1 tx clock */
	CLK_LOOKUP(0x44, 0x48, 0x50, CBCR_CLK_RESET,
			QCA8084_MAC1_UNIPHY1_CH0_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0x44, 0x48, 0x54, CBCR_CLK_RESET,
			QCA8084_MAC1_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0x44, 0x48, 0x58, CBCR_CLK_RESET,
			QCA8084_MAC1_GEPHY0_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0x44, 0x4c, 0x5c, CBCR_CLK_RESET,
			QCA8084_MAC1_UNIPHY1_CH0_XGMII_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	/* port 1 rx clock */
	CLK_LOOKUP(0x64, 0x68, 0x70, CBCR_CLK_RESET,
			QCA8084_MAC1_UNIPHY1_CH0_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0x64, 0x68, 0x74, CBCR_CLK_RESET,
			QCA8084_MAC1_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0x64, 0x68, 0x78, CBCR_CLK_RESET,
			QCA8084_MAC1_GEPHY0_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0x64, 0x6c, 0x7c, CBCR_CLK_RESET,
			QCA8084_MAC1_UNIPHY1_CH0_XGMII_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	/* port 2 tx clock */
	CLK_LOOKUP(0x84, 0x88, 0x90, CBCR_CLK_RESET,
			QCA8084_MAC2_UNIPHY1_CH1_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0x84, 0x88, 0x94, CBCR_CLK_RESET,
			QCA8084_MAC2_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0x84, 0x88, 0x98, CBCR_CLK_RESET,
			QCA8084_MAC2_GEPHY1_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0x84, 0x8c, 0x9c, CBCR_CLK_RESET,
			QCA8084_MAC2_UNIPHY1_CH1_XGMII_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	/* port 2 rx clock */
	CLK_LOOKUP(0xa4, 0xa8, 0xb0, CBCR_CLK_RESET,
			QCA8084_MAC2_UNIPHY1_CH1_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0xa4, 0xa8, 0xb4, CBCR_CLK_RESET,
			QCA8084_MAC2_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0xa4, 0xa8, 0xb8, CBCR_CLK_RESET,
			QCA8084_MAC2_GEPHY1_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0xa4, 0xac, 0xbc, CBCR_CLK_RESET,
			QCA8084_MAC2_UNIPHY1_CH1_XGMII_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	/* port 3 tx clock */
	CLK_LOOKUP(0xc4, 0xc8, 0xd0, CBCR_CLK_RESET,
			QCA8084_MAC3_UNIPHY1_CH2_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0xc4, 0xc8, 0xd4, CBCR_CLK_RESET,
			QCA8084_MAC3_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0xc4, 0xc8, 0xd8, CBCR_CLK_RESET,
			QCA8084_MAC3_GEPHY2_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	CLK_LOOKUP(0xc4, 0xcc, 0xdc, CBCR_CLK_RESET,
			QCA8084_MAC3_UNIPHY1_CH2_XGMII_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_tx_clk_pdata, ARRAY_SIZE(qca8084_mac1_tx_clk_pdata)),
	/* port 3 rx clock */
	CLK_LOOKUP(0xe4, 0xe8, 0xf0, CBCR_CLK_RESET,
			QCA8084_MAC3_UNIPHY1_CH2_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0xe4, 0xe8, 0xf4, CBCR_CLK_RESET,
			QCA8084_MAC3_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0xe4, 0xe8, 0xf8, CBCR_CLK_RESET,
			QCA8084_MAC3_GEPHY2_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	CLK_LOOKUP(0xe4, 0xec, 0xfc, CBCR_CLK_RESET,
			QCA8084_MAC3_UNIPHY1_CH2_XGMII_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac1_rx_clk_pdata, ARRAY_SIZE(qca8084_mac1_rx_clk_pdata)),
	/* port 4 tx clock */
	CLK_LOOKUP(0x104, 0x108, 0x110, CBCR_CLK_RESET,
			QCA8084_MAC4_UNIPHY1_CH3_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_tx_clk_pdata, ARRAY_SIZE(qca8084_mac4_tx_clk_pdata)),
	CLK_LOOKUP(0x104, 0x108, 0x114, CBCR_CLK_RESET,
			QCA8084_MAC4_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_tx_clk_pdata, ARRAY_SIZE(qca8084_mac4_tx_clk_pdata)),
	CLK_LOOKUP(0x104, 0x108, 0x118, CBCR_CLK_RESET,
			QCA8084_MAC4_GEPHY3_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_tx_clk_pdata, ARRAY_SIZE(qca8084_mac4_tx_clk_pdata)),
	CLK_LOOKUP(0x104, 0x10c, 0x11c, CBCR_CLK_RESET,
			QCA8084_MAC4_UNIPHY1_CH3_XGMII_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_tx_clk_pdata, ARRAY_SIZE(qca8084_mac4_tx_clk_pdata)),
	/* port 4 rx clock */
	CLK_LOOKUP(0x124, 0x128, 0x130, CBCR_CLK_RESET,
			QCA8084_MAC4_UNIPHY1_CH3_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_rx_clk_pdata, ARRAY_SIZE(qca8084_mac4_rx_clk_pdata)),
	CLK_LOOKUP(0x124, 0x128, 0x134, CBCR_CLK_RESET,
			QCA8084_MAC4_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_rx_clk_pdata, ARRAY_SIZE(qca8084_mac4_rx_clk_pdata)),
	CLK_LOOKUP(0x124, 0x128, 0x138, CBCR_CLK_RESET,
			QCA8084_MAC4_GEPHY3_RX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_rx_clk_pdata, ARRAY_SIZE(qca8084_mac4_rx_clk_pdata)),
	CLK_LOOKUP(0x124, 0x12c, 0x13c, CBCR_CLK_RESET,
			QCA8084_MAC4_UNIPHY1_CH3_XGMII_TX_CLK,
			qca8084_phyport_clk_support_rates, ARRAY_SIZE(qca8084_phyport_clk_support_rates),
			qca8084_mac4_rx_clk_pdata, ARRAY_SIZE(qca8084_mac4_rx_clk_pdata)),
	/* port 5 tx clock */
	CLK_LOOKUP(0x144, 0x148, 0x14c, CBCR_CLK_RESET,
			QCA8084_MAC5_TX_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac5_tx_clk_pdata, ARRAY_SIZE(qca8084_mac5_tx_clk_pdata)),
	CLK_LOOKUP(0x144, 0x148, 0x150, CBCR_CLK_RESET,
			QCA8084_MAC5_TX_UNIPHY0_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac5_tx_clk_pdata, ARRAY_SIZE(qca8084_mac5_tx_clk_pdata)),
	/* port 5 rx clock */
	CLK_LOOKUP(0x158, 0x15c, 0x160, CBCR_CLK_RESET,
			QCA8084_MAC5_RX_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac5_rx_clk_pdata, ARRAY_SIZE(qca8084_mac5_rx_clk_pdata)),
	CLK_LOOKUP(0x158, 0x15c, 0x164, CBCR_CLK_RESET,
			QCA8084_MAC5_RX_UNIPHY0_CLK,
			qca8084_cpuport_clk_support_rates, ARRAY_SIZE(qca8084_cpuport_clk_support_rates),
			qca8084_mac5_rx_clk_pdata, ARRAY_SIZE(qca8084_mac5_rx_clk_pdata)),
	/* AHB bridge clock */
	CLK_LOOKUP(0x16c, 0, 0x170, CBCR_CLK_RESET,
			QCA8084_AHB_CLK,
			qca8084_ahb_clk_support_rates, ARRAY_SIZE(qca8084_ahb_clk_support_rates),
			qca8084_ahb_clk_pdata, ARRAY_SIZE(qca8084_ahb_clk_pdata)),
	CLK_LOOKUP(0x16c, 0, 0x174, CBCR_CLK_RESET,
			QCA8084_SEC_CTRL_AHB_CLK,
			qca8084_ahb_clk_support_rates, ARRAY_SIZE(qca8084_ahb_clk_support_rates),
			qca8084_ahb_clk_pdata, ARRAY_SIZE(qca8084_ahb_clk_pdata)),
	CLK_LOOKUP(0x16c, 0, 0x178, CBCR_CLK_RESET,
			QCA8084_TLMM_CLK,
			qca8084_ahb_clk_support_rates, ARRAY_SIZE(qca8084_ahb_clk_support_rates),
			qca8084_ahb_clk_pdata, ARRAY_SIZE(qca8084_ahb_clk_pdata)),
	CLK_LOOKUP(0x16c, 0, 0x190, CBCR_CLK_RESET,
			QCA8084_TLMM_AHB_CLK,
			qca8084_ahb_clk_support_rates, ARRAY_SIZE(qca8084_ahb_clk_support_rates),
			qca8084_ahb_clk_pdata, ARRAY_SIZE(qca8084_ahb_clk_pdata)),
	CLK_LOOKUP(0x16c, 0, 0x194, CBCR_CLK_RESET,
			QCA8084_CNOC_AHB_CLK,
			qca8084_ahb_clk_support_rates, ARRAY_SIZE(qca8084_ahb_clk_support_rates),
			qca8084_ahb_clk_pdata, ARRAY_SIZE(qca8084_ahb_clk_pdata)),
	CLK_LOOKUP(0x16c, 0, 0x198, CBCR_CLK_RESET,
			QCA8084_MDIO_AHB_CLK,
			qca8084_ahb_clk_support_rates, ARRAY_SIZE(qca8084_ahb_clk_support_rates),
			qca8084_ahb_clk_pdata, ARRAY_SIZE(qca8084_ahb_clk_pdata)),
	CLK_LOOKUP(0x16c, 0, 0x19c, CBCR_CLK_RESET,
			QCA8084_MDIO_MASTER_AHB_CLK,
			qca8084_ahb_clk_support_rates, ARRAY_SIZE(qca8084_ahb_clk_support_rates),
			qca8084_ahb_clk_pdata, ARRAY_SIZE(qca8084_ahb_clk_pdata)),
	/* SYS clock */
	CLK_LOOKUP(0x1a4, 0, 0x1a8, CBCR_CLK_RESET,
			QCA8084_SRDS0_SYS_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),
	CLK_LOOKUP(0x1a4, 0, 0x1ac, CBCR_CLK_RESET,
			QCA8084_SRDS1_SYS_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),
	CLK_LOOKUP(0x1a4, 0, 0x1b0, CBCR_CLK_RESET,
			QCA8084_GEPHY0_SYS_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),
	CLK_LOOKUP(0x1a4, 0, 0x1b4, CBCR_CLK_RESET,
			QCA8084_GEPHY1_SYS_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),
	CLK_LOOKUP(0x1a4, 0, 0x1b8, CBCR_CLK_RESET,
			QCA8084_GEPHY2_SYS_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),
	CLK_LOOKUP(0x1a4, 0, 0x1bc, CBCR_CLK_RESET,
			QCA8084_GEPHY3_SYS_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),

	/* SEC control clock */
	CLK_LOOKUP(0x1c4, 0, 0x1c8, CBCR_CLK_RESET,
			QCA8084_SEC_CTRL_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),
	CLK_LOOKUP(0x1c4, 0, 0x1d0, CBCR_CLK_RESET,
			QCA8084_SEC_CTRL_SENSE_CLK,
			qca8084_sys_clk_support_rates, ARRAY_SIZE(qca8084_sys_clk_support_rates),
			qca8084_sys_clk_pdata, ARRAY_SIZE(qca8084_sys_clk_pdata)),

	/* GEPHY reset */
	CLK_LOOKUP(0, 0, 0x304, BIT(0), QCA8084_GEPHY_P0_MDC_SW_RST, NULL, 0, NULL, 0),
	CLK_LOOKUP(0, 0, 0x304, BIT(1), QCA8084_GEPHY_P1_MDC_SW_RST, NULL, 0, NULL, 0),
	CLK_LOOKUP(0, 0, 0x304, BIT(2), QCA8084_GEPHY_P2_MDC_SW_RST, NULL, 0, NULL, 0),
	CLK_LOOKUP(0, 0, 0x304, BIT(3), QCA8084_GEPHY_P3_MDC_SW_RST, NULL, 0, NULL, 0),
	CLK_LOOKUP(0, 0, 0x304, BIT(4), QCA8084_GEPHY_DSP_HW_RST, NULL, 0, NULL, 0),

	/* Global reset */
	CLK_LOOKUP(0, 0, 0x308, BIT(0), QCA8084_GLOBAL_RST, NULL, 0, NULL, 0),

	/* XPCS reset */
	CLK_LOOKUP(0, 0, 0x30c, BIT(0), QCA8084_UNIPHY_XPCS_RST, NULL, 0, NULL, 0),
};

static struct clk_lookup *qca8084_clk_find(const char *clock_id)
{
	int i;
	struct clk_lookup *clk;

	for (i = 0; i < ARRAY_SIZE(qca8084_clk_lookup_table); i++) {
		clk = &qca8084_clk_lookup_table[i];
		if (!strncmp(clock_id, clk->clk_name, strlen(clock_id)))
			return clk;
	}

	return NULL;
}

static void qca8084_clk_update(uint32_t cmd_reg)
{
	uint32_t i, reg_val;

	/* update RCG to the new programmed configuration */
	reg_val = ipq_mii_read(cmd_reg);
	reg_val |= RCGR_CMD_UPDATE;
	ipq_mii_write(cmd_reg, reg_val);

	for (i = 1000; i > 0; i--) {
		reg_val = ipq_mii_read(cmd_reg);
		if (!(reg_val & RCGR_CMD_UPDATE))
			return;

		udelay(1);
	}

	pr_debug("CLK cmd reg 0x%x fails updating to new configurations\n", cmd_reg);
	return;
}

void qca8084_clk_assert(const char *clock_id)
{
	struct clk_lookup *clk;
	uint32_t cbc_reg = 0;

	clk = qca8084_clk_find(clock_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clock_id);
		return;
	}

	cbc_reg = QCA8084_CLK_BASE_REG + clk->cbc;

	ipq_mii_update(cbc_reg, clk->rst_bit, clk->rst_bit);
	return;
}

void qca8084_clk_deassert(const char *clock_id)
{
	struct clk_lookup *clk;
	uint32_t cbc_reg = 0;

	clk = qca8084_clk_find(clock_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clock_id);
		return;
	}

	cbc_reg = QCA8084_CLK_BASE_REG + clk->cbc;

	ipq_mii_update(cbc_reg, clk->rst_bit, 0);
	return;
}

void qca8084_clk_reset(const char *clock_id)
{
	qca8084_clk_assert(clock_id);

	/* Time required by HW to complete assert */
	udelay(10);

	qca8084_clk_deassert(clock_id);

	return;
}

uint8_t qca8084_clk_is_enabled(const char *clock_id)
{
	struct clk_lookup *clk;
	uint32_t reg_val = 0;

	clk = qca8084_clk_find(clock_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clock_id);
		return 0;
	}

	reg_val = ipq_mii_read(QCA8084_CLK_BASE_REG + clk->rcg - 4);
	return (reg_val & RCGR_CMD_ROOT_OFF) == 0;
}

void qca8084_clk_enable(const char *clock_id)
{
	struct clk_lookup *clk;
	uint32_t cbc_reg = 0, reg_val = 0;

	clk = qca8084_clk_find(clock_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clock_id);
		return;
	}

	cbc_reg = QCA8084_CLK_BASE_REG + clk->cbc;
	ipq_mii_update(cbc_reg, CBCR_CLK_ENABLE, CBCR_CLK_ENABLE);

	udelay(1);
	reg_val = ipq_mii_read(cbc_reg);
	if (reg_val & CBCR_CLK_OFF) {
		pr_debug("CLK %s is not enabled!\n", clock_id);
		return;
	}

	return;
}

void qca8084_clk_disable(const char *clock_id)
{
	struct clk_lookup *clk;
	uint32_t cbc_reg = 0;

	clk = qca8084_clk_find(clock_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clock_id);
		return;
	}

	cbc_reg = QCA8084_CLK_BASE_REG + clk->cbc;

	ipq_mii_update(cbc_reg, CBCR_CLK_ENABLE, 0);
	return;
}

void qca8084_clk_parent_set(const char *clock_id, qca8084_clk_parent_t parent)
{
	struct clk_lookup *clk;
	uint32_t i, reg_val;
	uint32_t rcg_reg = 0, cmd_reg = 0, cfg = 0, cur_cfg = 0;
	const struct qca8084_parent_data *pdata = NULL;

	clk = qca8084_clk_find(clock_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clock_id);
		return;
	}

	for (i = 0; i < clk->num_parent; i++) {
		pdata = &(clk->pdata[i]);
		if (pdata->parent == parent)
			break;
	}

	if (i == clk->num_parent) {
		pr_debug("CLK %s is configured as incorrect parent %d\n", clock_id, parent);
		return;
	}

	rcg_reg = QCA8084_CLK_BASE_REG + clk->rcg;
	cmd_reg = QCA8084_CLK_BASE_REG + clk->rcg - 4;

	reg_val = ipq_mii_read(rcg_reg);
	cur_cfg = (reg_val & RCGR_SRC_SEL) >> RCGR_SRC_SEL_SHIFT;
	cfg = pdata->cfg;

	if (cfg == cur_cfg) {
		pr_debug("CLK %s parent %d is already configured correctly\n", clock_id, parent);
		return;
	}

	/* update clock parent */
	reg_val &= ~RCGR_SRC_SEL;
	reg_val |= cfg << RCGR_SRC_SEL_SHIFT;
	ipq_mii_write(rcg_reg, reg_val);

	/* update RCG to the new programmed configuration */
	qca8084_clk_update(cmd_reg);
}

void qca8084_uniphy_raw_clock_set(qca8084_clk_parent_t uniphy_clk, uint64_t rate)
{
	switch (uniphy_clk) {
		case QCA8084_P_UNIPHY0_RX:
		case QCA8084_P_UNIPHY0_TX:
		case QCA8084_P_UNIPHY1_RX:
		case QCA8084_P_UNIPHY1_TX:
			break;
		default:
			pr_debug("Invalid uniphy_clk %d\n", uniphy_clk);
			return;
	}

	qca8084_uniphy_raw_clock[uniphy_clk - QCA8084_P_UNIPHY0_RX] = rate;
	return;
}

uint64_t qca8084_uniphy_raw_clock_get(qca8084_clk_parent_t uniphy_clk)
{
	switch (uniphy_clk) {
		case QCA8084_P_UNIPHY0_RX:
		case QCA8084_P_UNIPHY0_TX:
		case QCA8084_P_UNIPHY1_RX:
		case QCA8084_P_UNIPHY1_TX:
			break;
		default:
			pr_debug("Invalid uniphy_clk %d\n", uniphy_clk);
			return QCA8084_XO_CLK_RATE_50M;
	}

	return qca8084_uniphy_raw_clock[uniphy_clk - QCA8084_P_UNIPHY0_RX];
}

void qca8084_clk_rate_set(const char *clock_id, uint32_t rate)
{
	struct clk_lookup *clk;
	uint64_t div, prate = 0;
	uint32_t i, reg_val, parent_index = 0;
	uint32_t rcg_reg = 0, cmd_reg = 0, cdiv_reg = 0, cdiv_val = 0;
	const struct qca8084_parent_data *pdata = NULL;

	clk = qca8084_clk_find(clock_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clock_id);
		return;
	}

	for (i = 0; i < clk->num_rate; i++)
		if (rate == clk->support_rate[i])
			break;

	if (i == clk->num_rate) {
		pr_debug("CLK %s does not support to configure rate %d\n", clock_id, rate);
		return;
	}

	rcg_reg = QCA8084_CLK_BASE_REG + clk->rcg;
	cmd_reg = QCA8084_CLK_BASE_REG + clk->rcg - 4;
	if (clk->cdiv != 0)
		cdiv_reg = QCA8084_CLK_BASE_REG + clk->cdiv;

	reg_val = ipq_mii_read(rcg_reg);

	/* get the parent rate of clock */
	parent_index = (reg_val & RCGR_SRC_SEL) >> RCGR_SRC_SEL_SHIFT;
	for (i = 0; i < clk->num_parent; i++) {
		pdata = &(clk->pdata[i]);
		if (pdata->cfg == parent_index) {
			/* uniphy0 rx, tx and unphy1 rx, tx clock can be 125M or 312.5M, which
			 * depends on the current link speed, the clock rate needs to be acquired
			 * dynamically.
			 */
			switch (pdata->parent) {
				case QCA8084_P_UNIPHY0_RX:
				case QCA8084_P_UNIPHY0_TX:
				case QCA8084_P_UNIPHY1_RX:
				case QCA8084_P_UNIPHY1_TX:
					prate = qca8084_uniphy_raw_clock_get(pdata->parent);
					break;
				default:
					/* XO 50M or 315P5M fix clock rate */
					prate = pdata->prate;
					break;
			}
			/* find the parent clock rate */
			break;
		}
	}

	if (i == clk->num_parent || prate == 0) {
		pr_debug("CLK %s is configured as unsupported parent value %d\n",
				clock_id, parent_index);
		return;
	}

	/* when configuring XPSC clock to UQXGMII_XPCS_SPEED_2500M_CLK, the RCGR divider
	 * need to be bypassed, since there are two dividers from the same RCGR, one is
	 * for XPCS clock, the other is for EPHY port clock.
	 */
	if (rate == UQXGMII_XPCS_SPEED_2500M_CLK) {
		if (prate != UQXGMII_SPEED_2500M_CLK) {
			pr_debug("CLK %s parent(%lld) needs to be updated to %d\n",
					clock_id, prate, UQXGMII_SPEED_2500M_CLK);
			return;
		}
		div = RCGR_DIV_BYPASS;
		cdiv_val = (UQXGMII_SPEED_2500M_CLK / UQXGMII_XPCS_SPEED_2500M_CLK) - 1;
	} else {

		/* calculate the RCGR divider prate/rate = (rcg_divider + 1)/2 */
		div = prate * 2;
		do_div(div, rate);
		div--;

		/* if the RCG divider can't meet the requirement, the CDIV reg can be simply
		 * divided by 10 to satisfy the required clock rate.
		 */
		if (div > RCGR_DIV_MAX) {
			/* update CDIV Reg to be divided by 10(N+1) */
			cdiv_val = CDIVR_DIVIDER_10;

			/* caculate the new RCG divider */
			do_div(prate, CDIVR_DIVIDER_10 + 1);
			div = prate * 2;
			do_div(div, rate);
			div--;
		}
	}

	/* update CDIV Reg to be divided by N(N-1 for reg value) */
	if (cdiv_reg != 0)
		ipq_mii_update(cdiv_reg,
				CDIVR_DIVIDER, cdiv_val << CDIVR_DIVIDER_SHIFT);

	if (cdiv_reg == 0 && cdiv_val > 0) {
		pr_debug("CLK %s needs CDIVR to generate rate %d from prate %lld\n",
				clock_id, rate, prate);
		return;
	}

	/* update RCGR */
	reg_val &= ~RCGR_HDIV;
	reg_val |= div << RCGR_HDIV_SHIFT;
	ipq_mii_write(rcg_reg, reg_val);

	/* update RCG to the new programmed configuration */
	qca8084_clk_update(cmd_reg);
}

#ifdef CONFIG_QCA8084_DEBUG
void qca8084_port5_uniphy0_clk_src_get(uint8_t *bypass_en)
{
	uint32_t reg_val = 0;

	/* In switch mode, uniphy0 rx clock is from mac5 rx, uniphy0 tx clock is from mac5 tx;
	 * In bypass mode, uniphy0 rx clock is from mac4 tx, uniphy0 tx clock is from mac4 rx;
	 */
	reg_val = ipq_mii_read(QCA8084_CLK_BASE_REG + QCA8084_CLK_MUX_SEL);
	*bypass_en = (reg_val & QCA8084_UNIPHY0_SEL_MAC5) ? 0 : 1;

	return;
}

int qca8084_clk_rate_get(const char *clock_id,
			  struct qca8084_clk_data *clk_data)
{
	struct clk_lookup *clk;
	uint64_t div, prate = 0;
	uint32_t i, reg_val, parent_index = 0;
	const struct qca8084_parent_data *pdata = NULL;
	char clk_id[64] = {0};
	uint8_t bypass_en = 0;

	strlcpy(clk_id, clock_id, sizeof(clk_id));

	qca8084_port5_uniphy0_clk_src_get(&bypass_en);
	if (bypass_en == 1) {
		if (strncasecmp(clock_id, QCA8084_MAC5_TX_UNIPHY0_CLK,
					strlen(QCA8084_MAC5_TX_UNIPHY0_CLK)) == 0)
			strlcpy(clk_id, QCA8084_MAC4_RX_CLK, sizeof(clk_id));
		else if (strncasecmp(clock_id, QCA8084_MAC5_RX_UNIPHY0_CLK,
					strlen(QCA8084_MAC5_RX_UNIPHY0_CLK)) == 0)
			strlcpy(clk_id, QCA8084_MAC4_TX_CLK, sizeof(clk_id));
	}

	clk = qca8084_clk_find(clk_id);
	if (!clk) {
		pr_debug("CLK %s is not found!\n", clk_id);
		return -1;
	}

	reg_val = ipq_mii_read(QCA8084_CLK_BASE_REG + clk->rcg);

	/* get the parent rate of clock */
	parent_index = (reg_val & RCGR_SRC_SEL) >> RCGR_SRC_SEL_SHIFT;
	for (i = 0; i < clk->num_parent; i++) {
		pdata = &(clk->pdata[i]);
		if (pdata->cfg == parent_index) {
			/* uniphy0 rx, tx and unphy1 rx, tx clock can be 125M or 312.5M, which
			 * depends on the current link speed, the clock rate needs to be acquired
			 * dynamically.
			 */
			switch (pdata->parent) {
				case QCA8084_P_UNIPHY0_RX:
				case QCA8084_P_UNIPHY0_TX:
				case QCA8084_P_UNIPHY1_RX:
				case QCA8084_P_UNIPHY1_TX:
					prate = qca8084_uniphy_raw_clock_get(pdata->parent);
					break;
				default:
					/* XO 50M or 315P5M fix clock rate */
					prate = pdata->prate;
					break;
			}
			/* find the parent clock rate */
			break;
		}
	}

	if (i == clk->num_parent || prate == 0) {
		pr_debug("CLK %s is configured as unsupported parent value %d\n",
				clk_id, parent_index);
		return -1;
	}

	/* calculate the current clock rate */
	div = (reg_val >> RCGR_HDIV_SHIFT) & RCGR_HDIV;
	if (div != 0) {
		/* RCG divider is bypassed if the div value is 0 */
		prate *= 2;
		do_div(prate, div + 1);
	}

	clk_data->rcg_val = reg_val;

	reg_val = ipq_mii_read(QCA8084_CLK_BASE_REG + clk->cbc);
	clk_data->cbc_val = reg_val;

	if (clk->cdiv != 0) {
		reg_val = ipq_mii_read(QCA8084_CLK_BASE_REG + clk->cdiv);
		clk_data->cdiv_val = reg_val;
		do_div(prate, ((reg_val >> CDIVR_DIVIDER_SHIFT) & CDIVR_DIVIDER) + 1);
	}

	clk_data->rate = prate;

	return 0;
}

void qca8084_clk_dump(void)
{
	uint32_t i;
	struct clk_lookup *clk;
	struct qca8084_clk_data clk_data;
	int ret;

	printf("%-31s  Frequency  RCG_VAL  CDIV_VAL  CBC_VAL\n", "Clock Name");

	for (i = 0; i < ARRAY_SIZE(qca8084_clk_lookup_table); i++) {
		clk = &qca8084_clk_lookup_table[i];
		if (clk->rcg != 0) {
			ret = qca8084_clk_rate_get(clk->clk_name, &clk_data);
			if (ret != 0)
				continue;
			printf("%-31s  %-9ld  0x%-5x  0x%-6x  0x%-5x\n",
				clk->clk_name, clk_data.rate,
				clk_data.rcg_val, clk_data.cdiv_val, clk_data.cbc_val);
		}
	}
}

static int do_qca8084_clk_dump(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	qca8084_clk_dump();

	return 0;
}

U_BOOT_CMD(
	qca8084_clk_dump, 1, 1, do_qca8084_clk_dump,
	"QCA8084 utility command to dump clocks\n",
	"qca8084_clk_dump	- dump all the qca8084 clocks\n"
	"This command can be used to check if clocks are all as expected\n"
);
#endif  /* CONFIG_QCA8084_DEBUG */

void qca8084_port5_uniphy0_clk_src_set(uint8_t bypass_en)
{
	uint32_t mux_sel = 0;

	/* In switch mode, uniphy0 rx clock is from mac5 rx, uniphy0 tx clock is from mac5 tx;
	 * In bypass mode, uniphy0 rx clock is from mac4 tx, uniphy0 tx clock is from mac4 rx;
	 */

	if (bypass_en)
		mux_sel = QCA8084_UNIPHY0_SEL_MAC4;
	else
		mux_sel = QCA8084_UNIPHY0_SEL_MAC5;

	ipq_mii_update(QCA8084_CLK_BASE_REG + QCA8084_CLK_MUX_SEL,
			QCA8084_UNIPHY0_MUX_SEL_MASK, mux_sel);
	return;
}

void qca8084_port_clk_rate_set(uint32_t qca8084_port_id, uint32_t rate)
{
	char *mac_rx_clk = NULL, *mac_tx_clk = NULL;
	char *xgmii_tx_clk = NULL, *xgmii_rx_clk = NULL;

	switch (qca8084_port_id) {
		case PORT0:
			mac_rx_clk = QCA8084_MAC0_RX_CLK;
			mac_tx_clk = QCA8084_MAC0_TX_CLK;
			break;
		case PORT1:
			mac_rx_clk = QCA8084_MAC1_RX_CLK;
			mac_tx_clk = QCA8084_MAC1_TX_CLK;
			xgmii_rx_clk = QCA8084_MAC1_UNIPHY1_CH0_XGMII_RX_CLK;
			xgmii_tx_clk = QCA8084_MAC1_UNIPHY1_CH0_XGMII_TX_CLK;
			break;
		case PORT2:
			mac_rx_clk = QCA8084_MAC2_RX_CLK;
			mac_tx_clk = QCA8084_MAC2_TX_CLK;
			xgmii_rx_clk = QCA8084_MAC2_UNIPHY1_CH1_XGMII_RX_CLK;
			xgmii_tx_clk = QCA8084_MAC2_UNIPHY1_CH1_XGMII_TX_CLK;
			break;
		case PORT3:
			mac_rx_clk = QCA8084_MAC3_RX_CLK;
			mac_tx_clk = QCA8084_MAC3_TX_CLK;
			xgmii_rx_clk = QCA8084_MAC3_UNIPHY1_CH2_XGMII_RX_CLK;
			xgmii_tx_clk = QCA8084_MAC3_UNIPHY1_CH2_XGMII_TX_CLK;
			break;
		case PORT4:
			mac_rx_clk = QCA8084_MAC4_RX_CLK;
			mac_tx_clk = QCA8084_MAC4_TX_CLK;
			xgmii_rx_clk = QCA8084_MAC4_UNIPHY1_CH3_XGMII_RX_CLK;
			xgmii_tx_clk = QCA8084_MAC4_UNIPHY1_CH3_XGMII_TX_CLK;
			break;
		case PORT5:
			mac_rx_clk = QCA8084_MAC5_RX_CLK;
			mac_tx_clk = QCA8084_MAC5_TX_CLK;
			break;
		default:
			pr_debug("Unsupported qca8084_port_id %d\n", qca8084_port_id);
			return;
	}

	qca8084_clk_rate_set(mac_rx_clk, rate);
	qca8084_clk_rate_set(mac_tx_clk, rate);

	if (xgmii_rx_clk != NULL && xgmii_tx_clk != NULL) {
		/* XGMII take the different clock rate from MAC clock when the link
		 * speed is 2.5G.
		 */
		if (rate == UQXGMII_SPEED_2500M_CLK)
			rate = UQXGMII_XPCS_SPEED_2500M_CLK;
		qca8084_clk_rate_set(xgmii_rx_clk, rate);
		qca8084_clk_rate_set(xgmii_tx_clk, rate);
	}

	return;
}

static void qca8084_clk_ids_get(uint32_t qca8084_port_id,
		uint8_t mask, char **clk_ids)
{
	switch (qca8084_port_id) {
		case PORT0:
			if (mask & QCA8084_CLK_TYPE_MAC) {
				*clk_ids++ = QCA8084_MAC0_TX_CLK;
				*clk_ids++ = QCA8084_MAC0_RX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_UNIPHY) {
				*clk_ids++ = QCA8084_MAC0_TX_UNIPHY1_CLK;
				*clk_ids++ = QCA8084_MAC0_RX_UNIPHY1_CLK;
			}
			break;
		case PORT1:
			if (mask & QCA8084_CLK_TYPE_MAC) {
				*clk_ids++ = QCA8084_MAC1_TX_CLK;
				*clk_ids++ = QCA8084_MAC1_RX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_UNIPHY) {
				*clk_ids++ = QCA8084_MAC1_UNIPHY1_CH0_RX_CLK;
				*clk_ids++ = QCA8084_MAC1_UNIPHY1_CH0_TX_CLK;
				*clk_ids++ = QCA8084_MAC1_UNIPHY1_CH0_XGMII_RX_CLK;
				*clk_ids++ = QCA8084_MAC1_UNIPHY1_CH0_XGMII_TX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_EPHY) {
				*clk_ids++ = QCA8084_MAC1_GEPHY0_TX_CLK;
				*clk_ids++ = QCA8084_MAC1_GEPHY0_RX_CLK;
			}
			break;
		case PORT2:
			if (mask & QCA8084_CLK_TYPE_MAC) {
				*clk_ids++ = QCA8084_MAC2_TX_CLK;
				*clk_ids++ = QCA8084_MAC2_RX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_UNIPHY) {
				*clk_ids++ = QCA8084_MAC2_UNIPHY1_CH1_RX_CLK;
				*clk_ids++ = QCA8084_MAC2_UNIPHY1_CH1_TX_CLK;
				*clk_ids++ = QCA8084_MAC2_UNIPHY1_CH1_XGMII_RX_CLK;
				*clk_ids++ = QCA8084_MAC2_UNIPHY1_CH1_XGMII_TX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_EPHY) {
				*clk_ids++ = QCA8084_MAC2_GEPHY1_TX_CLK;
				*clk_ids++ = QCA8084_MAC2_GEPHY1_RX_CLK;
			}
			break;
		case PORT3:
			if (mask & QCA8084_CLK_TYPE_MAC) {
				*clk_ids++ = QCA8084_MAC3_TX_CLK;
				*clk_ids++ = QCA8084_MAC3_RX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_UNIPHY) {
				*clk_ids++ = QCA8084_MAC3_UNIPHY1_CH2_RX_CLK;
				*clk_ids++ = QCA8084_MAC3_UNIPHY1_CH2_TX_CLK;
				*clk_ids++ = QCA8084_MAC3_UNIPHY1_CH2_XGMII_RX_CLK;
				*clk_ids++ = QCA8084_MAC3_UNIPHY1_CH2_XGMII_TX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_EPHY) {
				*clk_ids++ = QCA8084_MAC3_GEPHY2_TX_CLK;
				*clk_ids++ = QCA8084_MAC3_GEPHY2_RX_CLK;
			}
			break;
		case PORT4:
			if (mask & QCA8084_CLK_TYPE_MAC) {
				*clk_ids++ = QCA8084_MAC4_TX_CLK;
				*clk_ids++ = QCA8084_MAC4_RX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_UNIPHY) {
				*clk_ids++ = QCA8084_MAC4_UNIPHY1_CH3_RX_CLK;
				*clk_ids++ = QCA8084_MAC4_UNIPHY1_CH3_TX_CLK;
				*clk_ids++ = QCA8084_MAC4_UNIPHY1_CH3_XGMII_RX_CLK;
				*clk_ids++ = QCA8084_MAC4_UNIPHY1_CH3_XGMII_TX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_EPHY) {
				*clk_ids++ = QCA8084_MAC4_GEPHY3_TX_CLK;
				*clk_ids++ = QCA8084_MAC4_GEPHY3_RX_CLK;
			}
			break;
		case PORT5:
			if (mask & QCA8084_CLK_TYPE_MAC) {
				*clk_ids++ = QCA8084_MAC5_TX_CLK;
				*clk_ids++ = QCA8084_MAC5_RX_CLK;
			}

			if (mask & QCA8084_CLK_TYPE_UNIPHY) {
				*clk_ids++ = QCA8084_MAC5_TX_UNIPHY0_CLK;
				*clk_ids++ = QCA8084_MAC5_RX_UNIPHY0_CLK;
			}
			break;
		default:
			pr_debug("Unsupported qca8084_port_id %d\n", qca8084_port_id);
			return;
	}

	return;
}

void qca8084_port_clk_reset(uint32_t qca8084_port_id, uint8_t mask)
{
	char *clk_ids[QCA8084_PORT_CLK_CBC_MAX + 1] = {NULL};
	uint32_t i = 0;

	qca8084_clk_ids_get(qca8084_port_id, mask, clk_ids);

	while(clk_ids[i] != NULL) {
		qca8084_clk_reset(clk_ids[i]);
		i++;
	}

	return;
}

void qca8084_port_clk_en_set(uint32_t qca8084_port_id, uint8_t mask,
			     uint8_t enable)
{
	char *clk_ids[QCA8084_PORT_CLK_CBC_MAX + 1] = {NULL};
	uint32_t i = 0;

	qca8084_clk_ids_get(qca8084_port_id, mask, clk_ids);

	while(clk_ids[i] != NULL) {
		if (enable)
			qca8084_clk_enable(clk_ids[i]);
		else
			qca8084_clk_disable(clk_ids[i]);
		i++;
	}

	return;
}

void qca8084_gcc_common_clk_parent_enable(qca8084_work_mode_t clk_mode)
{
	/* Switch core */
	qca8084_clk_parent_set(QCA8084_SWITCH_CORE_CLK, QCA8084_P_UNIPHY1_TX312P5M);
	qca8084_clk_rate_set(QCA8084_SWITCH_CORE_CLK, UQXGMII_SPEED_2500M_CLK);

	/* Disable switch core clock to save power in phy mode */
	if (QCA8084_PHY_UQXGMII_MODE == clk_mode || QCA8084_PHY_SGMII_UQXGMII_MODE == clk_mode)
		qca8084_clk_disable(QCA8084_SWITCH_CORE_CLK);
	else
		qca8084_clk_enable(QCA8084_SWITCH_CORE_CLK);

	qca8084_clk_enable(QCA8084_APB_BRIDGE_CLK);

	/* AHB bridge */
	qca8084_clk_parent_set(QCA8084_AHB_CLK, QCA8084_P_UNIPHY1_TX312P5M);
	qca8084_clk_rate_set(QCA8084_AHB_CLK, QCA8084_AHB_CLK_RATE_104P17M);
	qca8084_clk_enable(QCA8084_AHB_CLK);
	qca8084_clk_enable(QCA8084_SEC_CTRL_AHB_CLK);
	qca8084_clk_enable(QCA8084_TLMM_CLK);
	qca8084_clk_enable(QCA8084_TLMM_AHB_CLK);
	qca8084_clk_enable(QCA8084_CNOC_AHB_CLK);
	qca8084_clk_enable(QCA8084_MDIO_AHB_CLK);
	qca8084_clk_enable(QCA8084_MDIO_MASTER_AHB_CLK);

	/* System */
	qca8084_clk_parent_set(QCA8084_SRDS0_SYS_CLK, QCA8084_P_XO);
	qca8084_clk_rate_set(QCA8084_SRDS0_SYS_CLK, QCA8084_SYS_CLK_RATE_25M);

	/* Disable serdes0 clock to save power in phy mode */
	if (QCA8084_PHY_UQXGMII_MODE == clk_mode || QCA8084_PHY_SGMII_UQXGMII_MODE == clk_mode)
		qca8084_clk_disable(QCA8084_SRDS0_SYS_CLK);
	else
		qca8084_clk_enable(QCA8084_SRDS0_SYS_CLK);

	qca8084_clk_enable(QCA8084_SRDS1_SYS_CLK);
	qca8084_clk_enable(QCA8084_GEPHY0_SYS_CLK);
	qca8084_clk_enable(QCA8084_GEPHY1_SYS_CLK);
	qca8084_clk_enable(QCA8084_GEPHY2_SYS_CLK);
	qca8084_clk_enable(QCA8084_GEPHY3_SYS_CLK);

	/* Sec control */
	qca8084_clk_parent_set(QCA8084_SEC_CTRL_CLK, QCA8084_P_XO);
	qca8084_clk_rate_set(QCA8084_SEC_CTRL_CLK, QCA8084_SYS_CLK_RATE_25M);
	qca8084_clk_enable(QCA8084_SEC_CTRL_CLK);
	qca8084_clk_enable(QCA8084_SEC_CTRL_SENSE_CLK);
}

void qca8084_gcc_port_clk_parent_set(qca8084_work_mode_t clk_mode, uint32_t qca8084_port_id)
{
	qca8084_clk_parent_t port_tx_parent, port_rx_parent;
	char *tx_clk_id, *rx_clk_id;

	/* Initialize the clock parent with port 1, 2, 3, clock parent is same for these ports;
	 * the clock parent will be updated for port 0, 4, 5.
	 */
	switch(clk_mode) {
		case QCA8084_SWITCH_MODE:
		case QCA8084_SWITCH_BYPASS_PORT5_MODE:
			port_tx_parent = QCA8084_P_UNIPHY1_TX312P5M;
			break;
		case QCA8084_PHY_UQXGMII_MODE:
		case QCA8084_PHY_SGMII_UQXGMII_MODE:
			port_tx_parent = QCA8084_P_UNIPHY1_RX312P5M;
			break;
		default:
			pr_debug("Unsupported clock mode %d\n", clk_mode);
			return;
	}
	port_rx_parent = QCA8084_P_UNIPHY1_TX312P5M;

	switch (qca8084_port_id) {
		case PORT0:
			port_tx_parent = QCA8084_P_UNIPHY1_TX;
			port_rx_parent = QCA8084_P_UNIPHY1_RX;
			tx_clk_id = QCA8084_MAC0_TX_CLK;
			rx_clk_id = QCA8084_MAC0_RX_CLK;
			break;
		case PORT1:
			tx_clk_id = QCA8084_MAC1_TX_CLK;
			rx_clk_id = QCA8084_MAC1_RX_CLK;
			break;
		case PORT2:
			tx_clk_id = QCA8084_MAC2_TX_CLK;
			rx_clk_id = QCA8084_MAC2_RX_CLK;
			break;
		case PORT3:
			tx_clk_id = QCA8084_MAC3_TX_CLK;
			rx_clk_id = QCA8084_MAC3_RX_CLK;
			break;
		case PORT4:
			switch(clk_mode) {
				case QCA8084_SWITCH_BYPASS_PORT5_MODE:
				case QCA8084_PHY_SGMII_UQXGMII_MODE:
					port_tx_parent = QCA8084_P_UNIPHY0_RX;
					port_rx_parent = QCA8084_P_UNIPHY0_TX;
					break;
				case QCA8084_SWITCH_MODE:
					port_tx_parent = QCA8084_P_UNIPHY1_TX312P5M;
					port_rx_parent = QCA8084_P_UNIPHY1_TX312P5M;
					break;
				case QCA8084_PHY_UQXGMII_MODE:
					port_tx_parent = QCA8084_P_UNIPHY1_RX312P5M;
					port_rx_parent = QCA8084_P_UNIPHY1_TX312P5M;
					break;
				default:
					pr_debug("Unsupported clock mode %d\n", clk_mode);
					return;
			}
			tx_clk_id = QCA8084_MAC4_TX_CLK;
			rx_clk_id = QCA8084_MAC4_RX_CLK;
			break;
		case PORT5:
			port_tx_parent = QCA8084_P_UNIPHY0_TX;
			port_rx_parent = QCA8084_P_UNIPHY0_RX;
			tx_clk_id = QCA8084_MAC5_TX_CLK;
			rx_clk_id = QCA8084_MAC5_RX_CLK;
			switch (clk_mode) {
				case QCA8084_SWITCH_BYPASS_PORT5_MODE:
				case QCA8084_PHY_SGMII_UQXGMII_MODE:
					qca8084_port5_uniphy0_clk_src_set(1);
					break;
				case QCA8084_SWITCH_MODE:
				case QCA8084_PHY_UQXGMII_MODE:
					qca8084_port5_uniphy0_clk_src_set(0);
					break;
				default:
					pr_debug("Unsupported clock mode %d\n", clk_mode);
					return;
			}
			break;
		default:
			pr_debug("Unsupported qca8084_port_id %d\n", qca8084_port_id);
			return;
	}

	qca8084_clk_parent_set(tx_clk_id, port_tx_parent);
	qca8084_clk_parent_set(rx_clk_id, port_rx_parent);
}

void qca8084_gcc_clock_init(qca8084_work_mode_t clk_mode, u32 pbmp)
{
	uint32_t qca8084_port_id = 0;
	/* clock type mask value for 6 manhattan ports */
	uint8_t clk_mask[PORT5 + 1] = {0};
	uint8_t switch_flag = 0;
	qca8084_clk_parent_t uniphy_index = QCA8084_P_UNIPHY0_RX;

	switch (clk_mode) {
		case QCA8084_SWITCH_MODE:
		case QCA8084_SWITCH_BYPASS_PORT5_MODE:
			while (pbmp) {
				if (pbmp & 1) {
					if (qca8084_port_id == PORT0 ||
							qca8084_port_id == PORT5) {
						clk_mask[qca8084_port_id] = QCA8084_CLK_TYPE_MAC |
							QCA8084_CLK_TYPE_UNIPHY;
					} else {
						clk_mask[qca8084_port_id] = QCA8084_CLK_TYPE_MAC |
							QCA8084_CLK_TYPE_EPHY;
					}
				}
				pbmp >>= 1;
				qca8084_port_id++;
			}

			if (clk_mode == QCA8084_SWITCH_BYPASS_PORT5_MODE) {
				/* For phy port 4 in switch bypass mode */
				clk_mask[PORT4] = QCA8084_CLK_TYPE_EPHY;
				clk_mask[PORT5] = QCA8084_CLK_TYPE_UNIPHY;
			}

			switch_flag = 1;
			break;
		case QCA8084_PHY_UQXGMII_MODE:
		case QCA8084_PHY_SGMII_UQXGMII_MODE:
			clk_mask[PORT1] = QCA8084_CLK_TYPE_UNIPHY | QCA8084_CLK_TYPE_EPHY;
			clk_mask[PORT2] = QCA8084_CLK_TYPE_UNIPHY | QCA8084_CLK_TYPE_EPHY;
			clk_mask[PORT3] = QCA8084_CLK_TYPE_UNIPHY | QCA8084_CLK_TYPE_EPHY;
			clk_mask[PORT4] = QCA8084_CLK_TYPE_UNIPHY | QCA8084_CLK_TYPE_EPHY;
			if (clk_mode == QCA8084_PHY_SGMII_UQXGMII_MODE) {
				/* For phy port4 in PHY bypass mode */
				clk_mask[PORT4] = QCA8084_CLK_TYPE_EPHY;
				clk_mask[PORT5] = QCA8084_CLK_TYPE_UNIPHY;
			}
			break;
		default:
			pr_debug("Unsupported clock mode %d\n", clk_mode);
			return;
	}

	qca8084_gcc_common_clk_parent_enable(clk_mode);

	/* Initialize the uniphy raw clock, if the port4 is in bypass mode, the uniphy0
	 * raw clock need to be dynamically updated between UQXGMII_SPEED_2500M_CLK and
	 * UQXGMII_SPEED_1000M_CLK according to the realtime link speed.
	 */
	uniphy_index = QCA8084_P_UNIPHY0_RX;
	while (uniphy_index <= QCA8084_P_UNIPHY1_TX) {
		/* the uniphy raw clock may be already initialized. */
		if (0 == qca8084_uniphy_raw_clock_get(uniphy_index))
			qca8084_uniphy_raw_clock_set(uniphy_index,
					UQXGMII_SPEED_2500M_CLK);
		uniphy_index++;
	}

	qca8084_port_id = 0;
	while (qca8084_port_id < ARRAY_SIZE(clk_mask)) {
		if (clk_mask[qca8084_port_id] != 0) {
			qca8084_gcc_port_clk_parent_set(clk_mode, qca8084_port_id);
			if (clk_mask[qca8084_port_id] & QCA8084_CLK_TYPE_MAC)
				qca8084_port_clk_en_set(qca8084_port_id, QCA8084_CLK_TYPE_MAC, 1);
			if (clk_mask[qca8084_port_id] & QCA8084_CLK_TYPE_UNIPHY && switch_flag == 1)
				qca8084_port_clk_en_set(qca8084_port_id, QCA8084_CLK_TYPE_UNIPHY, 1);
			pbmp |= BIT(qca8084_port_id);
		}
		qca8084_port_id++;
	}

	pr_debug("QCA8084 GCC CLK initialization with clock mode %d on port bmp 0x%x\n",
			clk_mode, pbmp);
}
