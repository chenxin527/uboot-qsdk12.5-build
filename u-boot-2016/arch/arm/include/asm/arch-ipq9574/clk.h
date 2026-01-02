/*
 * Copyright (c) 2015-2016, 2018, 2021 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef IPQ9574_CLK_H
#define IPQ9574_CLK_H

#include <asm/arch-qca-common/uart.h>

#define GCC_BLSP1_UART1_BCR	0x1802028
#define GCC_BLSP1_UART2_BCR	0x1803028
#define GCC_BLSP1_UART3_BCR	0x1804028
#define GCC_BLSP1_UART4_BCR	0x1805028
#define GCC_BLSP1_UART5_BCR	0x1806028
#define GCC_BLSP1_UART6_BCR	0x1807028

#define GCC_BLSP1_UART_BCR(id)	((id < 1) ? \
				(GCC_BLSP1_UART1_BCR):\
				(GCC_BLSP1_UART1_BCR + (0x1000 * id)))

#define GCC_BLSP1_UART_APPS_CMD_RCGR(id)	(GCC_BLSP1_UART_BCR(id) + 0x04)
#define GCC_BLSP1_UART_APPS_CFG_RCGR(id)	(GCC_BLSP1_UART_BCR(id) + 0x08)
#define GCC_BLSP1_UART_APPS_M(id)		(GCC_BLSP1_UART_BCR(id) + 0x0c)
#define GCC_BLSP1_UART_APPS_N(id)		(GCC_BLSP1_UART_BCR(id) + 0x10)
#define GCC_BLSP1_UART_APPS_D(id)		(GCC_BLSP1_UART_BCR(id) + 0x14)
#define GCC_BLSP1_UART_APPS_CBCR(id)		(GCC_BLSP1_UART_BCR(id) + 0x18)

#define GCC_UART_CFG_RCGR_MODE_MASK	0x3000
#define GCC_UART_CFG_RCGR_SRCSEL_MASK	0x0700
#define GCC_UART_CFG_RCGR_SRCDIV_MASK	0x001F

#define GCC_UART_CFG_RCGR_MODE_SHIFT	12
#define GCC_UART_CFG_RCGR_SRCSEL_SHIFT	8
#define GCC_UART_CFG_RCGR_SRCDIV_SHIFT	0

#define UART_RCGR_SRC_SEL	0x1
#define UART_RCGR_SRC_DIV	0x0
#define UART_RCGR_MODE		0x2
#define UART_CMD_RCGR_UPDATE	0x1
#define UART_CBCR_CLK_ENABLE	0x1

#define NOT_2D(two_d)		(~two_d)
#define NOT_N_MINUS_M(n,m)	(~(n - m))
#define CLOCK_UPDATE_TIMEOUT_US	1000

#define CMD_UPDATE      0x1
#define ROOT_EN         0x2
#define CLK_ENABLE      0x1

/*
 * Qpic SPI Nand clock
 */

#define GCC_QPIC_IO_MACRO_CMD_RCGR		0x1832004
#define GCC_QPIC_IO_MACRO_CFG_RCGR		0x1832008
#define GCC_QPIC_IO_MACRO_CBCR			0x183200C
#define GCC_QPIC_AHB_CBCR_ADDR			0x1832010
#define GCC_QPIC_CBCR_ADDR			0x1832014
#define GCC_QPIC_SLEEP_CBCR			0x1832018

#define IO_MACRO_CLK_320_MHZ			320000000
#define IO_MACRO_CLK_266_MHZ			266000000
#define IO_MACRO_CLK_228_MHZ			228000000
#define IO_MACRO_CLK_200_MHZ			200000000
#define IO_MACRO_CLK_100_MHZ			100000000
#define IO_MACRO_CLK_24MHZ			24000000

#define QPIC_IO_MACRO_CLK       		0
#define QPIC_CORE_CLK           		1
#define XO_CLK_SRC				2
#define GPLL0_CLK_SRC				3
#define FB_CLK_BIT				(1 << 4)
#define UPDATE_EN				0x1

/*
 * GCC-SDCC
 */
#define GCC_SDCC1_BCR				0x1833000
#define GCC_SDCC1_APPS_CMD_RCGR			0x1833004
#define GCC_SDCC1_APPS_CFG_RCGR			0x1833008
#define GCC_SDCC1_APPS_M			0x183300C
#define GCC_SDCC1_APPS_N			0x1833010
#define GCC_SDCC1_APPS_D			0x1833014
#define GCC_SDCC1_APPS_CBCR			0x183302C
#define GCC_SDCC1_AHB_CBCR			0x1833034
#define SDCC1_M_VAL				0x1
#define SDCC1_N_VAL				0xFC
#define SDCC1_D_VAL				0xFD
#define GCC_SDCC1_APPS_CFG_RCGR_SRC_SEL		(2 << 8)
#define GCC_SDCC1_APPS_CFG_RCGR_SRC_DIV		(0xB << 0)

/*
 * USB
 */
#define GCC_USB_BCR				0x182C000
#define GCC_USB0_MASTER_CMD_RCGR		0x182C004
#define GCC_USB0_MASTER_CFG_RCGR		0x182C008
#define GCC_USB0_AUX_CMD_RCGR			0x182C018
#define GCC_USB0_AUX_CFG_RCGR			0x182C01C
#define GCC_USB0_AUX_M				0x182C020
#define GCC_USB0_AUX_N				0x182C024
#define GCC_USB0_AUX_D				0x182C028
#define GCC_USB0_MOCK_UTMI_CMD_RCGR		0x182C02C
#define GCC_USB0_MOCK_UTMI_CFG_RCGR		0x182C030
#define GCC_USB0_MOCK_UTMI_M			0x182C034
#define GCC_USB0_MOCK_UTMI_N			0x182C038
#define GCC_USB0_MOCK_UTMI_D			0x182C03C
#define GCC_USB0_MASTER_CBCR			0x182C044
#define GCC_USB0_AUX_CBCR			0x182C048
#define GCC_USB0_MOCK_UTMI_CBCR			0x182C04C
#define GCC_USB0_PIPE_CBCR			0x182C054
#define GCC_USB0_SLEEP_CBCR			0x182C058
#define GCC_USB0_PHY_CFG_AHB_CBCR		0x182C05C
#define GCC_USB_0_BOOT_CLOCK_CTL		0x182C060
#define GCC_QUSB2_0_PHY_BCR			0x182C068
#define GCC_USB0_PHY_BCR			0x182C06C
#define GCC_USB3PHY_0_PHY_BCR			0x182C070
#define GCC_USB0_PHY_PIPE_MISC			0x182C074
#define GCC_SNOC_USB_CBCR			0x182E058
#define GCC_ANOC_USB_AXI_CBCR			0x182E084

#define AUX_M					0x0
#define AUX_N					0x0
#define AUX_D					0x0
#define SW_COLLAPSE_ENABLE			(1 << 0)
#define SW_OVERRIDE_ENABLE			(1 << 2)
#define GCC_USB0_MASTER_CFG_RCGR_SRC_SEL	(1 << 8)
#define GCC_USB0_MASTER_CFG_RCGR_SRC_DIV	(0x7 << 0)
#define GCC_USB_MOCK_UTMI_SRC_SEL		(0 << 8)
#define GCC_USB_MOCK_UTMI_SRC_DIV		(0x1 << 0)
#define UTMI_M					0x1
#define UTMI_N					0xFFFE
#define UTMI_D					0xFFFD
#define GCC_USB0_AUX_CFG_MODE_DUAL_EDGE 	(2 << 12)
#define GCC_USB0_AUX_CFG_SRC_SEL		(0 << 8)
#define GCC_USB0_AUX_CFG_SRC_DIV		(0 << 0)

/*
 * PCIE
 */
#define GCC_PCIE_BASE				0x1828000
#define GCC_PCIE_REG(_offset, _index)	(GCC_PCIE_BASE + _offset +\
						(_index * 0x1000))

#define GCC_PCIE_BCR				0x0
#define GCC_PCIE_AUX_CMD_RCGR			0x4
#define GCC_PCIE_AUX_CFG_RCGR			0x8
#define GCC_PCIE_AUX_M				0xC
#define GCC_PCIE_AUX_N				0x10
#define GCC_PCIE_AUX_D				0x14
#define GCC_PCIE_AXI_M_CMD_RCGR			0x18
#define GCC_PCIE_AXI_M_CFG_RCGR			0x1C
#define GCC_PCIE_AXI_S_CMD_RCGR			0x20
#define GCC_PCIE_AXI_S_CFG_RCGR			0x24
#define GCC_PCIE_RCHNG_CMD_RCGR			0x28
#define GCC_PCIE_RCHNG_CFG_RCGR			0x2C
#define GCC_PCIE_AHB_CBCR			0x30
#define GCC_PCIE_AUX_CBCR			0x34
#define GCC_PCIE_AXI_M_CBCR			0x38
#define GCC_PCIE_AXI_S_CBCR			0x3C
#define GCC_PCIE_AXI_S_BRIDGE_CBCR		0x40
#define GCC_PCIE_PIPE_CBCR			0x44
#define GCC_PCIE_BOOT_CLOCK_CTL			0x50
#define GCC_PCIE_LINK_DOWN_BCR			0x54
#define GCC_PCIE_MISC_RESET			0x58
#define GCC_PCIEPHY_PHY_BCR			0x5C
#define GCC_PCIE_PHY_BCR			0x60
#define GCC_PCIE_PHY_PIPE_MISC			0x64

#define GCC_SNOC_PCIE0_1LANE_S_CBCR		0x182E048
#define GCC_SNOC_PCIE1_1LANE_S_CBCR		0x182E04C
#define GCC_SNOC_PCIE2_2LANE_S_CBCR		0x182E050
#define GCC_SNOC_PCIE3_2LANE_S_CBCR		0x182E054
#define GCC_ANOC_PCIE0_1LANE_M_CBCR		0x182E07C
#define GCC_ANOC_PCIE2_2LANE_M_CBCR		0x182E080
#define GCC_ANOC_PCIE1_1LANE_M_CBCR		0x182E08C
#define GCC_ANOC_PCIE3_2LANE_M_CBCR		0x182E090

#define GCC_PCIE_AUX_CFG_RCGR_MN_MODE		(2 << 12)
#define GCC_PCIE_AUX_CFG_RCGR_SRC_SEL		(1 << 8)
#define GCC_PCIE_AUX_CFG_RCGR_SRC_DIV		(0x13 << 0)
#define GCC_PCIE_AXI_M_CFG_RCGR_SRC_SEL		(2 << 8)
#define GCC_PCIE_AXI_M_CFG_RCGR_SRC_DIV_LANE2	(6 << 0)
#define GCC_PCIE_AXI_M_CFG_RCGR_SRC_DIV_LANE1	(9 << 0)
#define GCC_PCIE_AXI_S_CFG_RCGR_SRC_SEL		(2 << 8)
#define GCC_PCIE_AXI_S_CFG_RCGR_SRC_DIV		(9 << 0)
#define CMD_UPDATE				0x1
#define ROOT_EN					0x2
#define PIPE_CLK_ENABLE				0x4FF1
#define CLK_DISABLE				0x0
#define NOC_HANDSHAKE_FSM_EN			(1 << 15)
#define GCC_PCIE_RCHNG_CFG_RCGR_SRC_SEL		(1 << 8)
#define GCC_PCIE_RCHNG_CFG_RCGR_SRC_DIV		(0xF << 0)
#define GCC_PCIE_PHY_PIPE_MISC_SRC_SEL		(0x1 << 8)

int uart_clock_config(struct ipq_serial_platdata *plat);

#ifdef CONFIG_QPIC_NAND
void qpic_set_clk_rate(unsigned int clk_rate, int blk_type,
		int req_clk_src_type);
#endif

#ifdef CONFIG_USB_XHCI_IPQ
void usb_clock_init(int id);
void usb_clock_deinit(void);
#endif

#ifdef CONFIG_QCA_MMC
void emmc_clock_init(void);
void emmc_clock_reset(void);
#endif

#ifdef CONFIG_PCI_IPQ
void pcie_v2_clock_init(int pcie_id);
void pcie_v2_clock_deinit(int pcie_id);
#endif

#endif /*IPQ9574_CLK_H*/
