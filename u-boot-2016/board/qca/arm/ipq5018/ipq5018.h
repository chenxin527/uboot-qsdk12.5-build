/*
* Copyright (c) 2016-2020, The Linux Foundation. All rights reserved.
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

#ifndef _IPQ5018_CDP_H_
#define _IPQ5018_CDP_H_

#include <configs/ipq5018.h>
#include <asm/u-boot.h>
#include <asm/arch-qca-common/qca_common.h>
#include "phy.h"

/*
 * Eud register
 */
#define EUD_EUD_EN2				0x0005A000

#define MSM_SDC1_BASE				0x7800000
#define MSM_SDC1_SDHCI_BASE			0x7804000

#define GCC_MDIO0_BASE				0x1858000
#define GCC_GMAC_CFG_RCGR			0x01868084
#define GCC_GMAC_CMD_RCGR			0x01868080
#define GCC_GMAC_BASE				0x01868000


#define GCC_GMAC_CFG_RCGR_SRC_SEL_MASK		0x700
#define GCC_GMAC0_RX_SRC_SEL_GEPHY_TX		0x200
#define GCC_GMAC0_TX_SRC_SEL_GEPHY_TX		0x100
#define GCC_GMAC1_RX_SRC_SEL_UNIPHY_RX		0x100
#define GCC_GMAC1_TX_SRC_SEL_UNIPHY_TX		0x100
#define CMN_PLL_PLL_LOCKED_REG			0x9B064
#define CMN_PLL_PLL_LOCKED_SIZE			0x4
#define CMN_PLL_LOCKED				0x4

/*
 * CMN BLK clock
 */
#define GCC_CMN_BLK_AHB_CBCR			0x01856308
#define GCC_CMN_BLK_SYS_CBCR			0x0185630C
#define CMN_BLK_ADDR				0x0009B780
#define CMN_BLK_SIZE				0x100
#define FREQUENCY_MASK				0xfffffdf0
#define INTERNAL_48MHZ_CLOCK    		0x7

#define CMN_BLK_PLL_SRC_ADDR			0x0009B028
#define PLL_CTRL_SRC_MASK			0xfffffcff
#define PLL_REFCLK_DIV_MASK			0xfffffe0f
#define PLL_REFCLK_DIV_2			0x20
#define CMN_BLK_PLL_SRC_SEL_FROM_REG		0x0
#define CMN_BLK_PLL_SRC_SEL_FROM_LOGIC		0x1
#define CMN_BLK_PLL_SRC_SEL_FROM_PCS		0x2
#define TCSR_ETH_LDO_RDY_REG			0x19475C4
#define TCSR_ETH_LDO_RDY_SIZE			0x4
#define ETH_LDO_RDY				0x1

/*
 * GEPHY Block Register
 */
#define GCC_GEPHY_BCR				0x01856000
#define GCC_GEPHY_MISC				0x01856004
#define GCC_GEPHY_RX_CBCR			0x01856010
#define GCC_GEPHY_TX_CBCR			0x01856014
#define GCC_GEPHY_BCR_BLK_ARES			0x1
#define GCC_GEPHY_MISC_ARES			0xf

/*
 * UNIPHY Block Register
 */
#define GCC_UNIPHY_BCR				0x01856100
#define GCC_UNIPHY_AHB_CBCR			0x01856108
#define GCC_UNIPHY_SYS_CBCR			0x0185610C
#define GCC_UNIPHY_BCR_BLK_ARES			0x1
#define GCC_UNIPHY_MISC_ARES			0x32
#define GCC_UNIPHY_RX_CBCR			0x01856110
#define GCC_UNIPHY_TX_CBCR			0x01856114

/* GMAC0 GCC clock */
#define GCC_GMAC0_RX_CMD_RCGR			0x01868020
#define GCC_GMAC0_RX_CFG_RCGR			0x01868024
#define GCC_GMAC0_TX_CMD_RCGR			0x01868028
#define GCC_GMAC0_TX_CFG_RCGR			0x0186802C
#define GCC_GMAC0_RX_MISC			0x01868420
#define GCC_GMAC0_TX_MISC			0x01868424
#define GCC_GMAC0_MISC				0x01868428
#define GCC_GMAC0_BCR				0x01819000
#define GCC_SNOC_GMAC0_AXI_CBCR			0x01826084
#define GCC_SNOC_GMAC0_AHB_CBCR			0x018260A0
#define GCC_GMAC0_PTP_CBCR			0x01868300
#define GCC_GMAC0_CFG_CBCR			0x01868304
#define GCC_GMAC0_SYS_CBCR			0x01868190
#define GCC_GMAC0_RX_CBCR			0x01868240
#define GCC_GMAC0_TX_CBCR			0x01868244
#define GCC_GMAC0_BCR_BLK_ARES			0x1

/* GMAC1 GCC Clock */
#define GCC_GMAC1_RX_CMD_RCGR			0x01868030
#define GCC_GMAC1_RX_CFG_RCGR			0x01868034
#define GCC_GMAC1_TX_CMD_RCGR			0x01868038
#define GCC_GMAC1_TX_CFG_RCGR			0x0186803C
#define GCC_GMAC1_RX_MISC			0x01868430
#define GCC_GMAC1_TX_MISC			0x01868434
#define GCC_GMAC1_MISC				0x01868438
#define GCC_GMAC1_BCR				0x01819100
#define GCC_SNOC_GMAC1_AXI_CBCR			0x01826088
#define GCC_SNOC_GMAC1_AHB_CBCR			0x018260A4
#define GCC_GMAC1_SYS_CBCR			0x01868310
#define GCC_GMAC1_PTP_CBCR			0x01868320
#define GCC_GMAC1_CFG_CBCR			0x01868324
#define GCC_GMAC1_RX_CBCR			0x01868248
#define GCC_GMAC1_TX_CBCR			0x0186824C
#define GCC_GMAC1_BCR_BLK_ARES			0x1

#define GCC_CBCR_CLK_ENABLE			0x1

/*
 * GCC-SDCC Registers
 */

#define GCC_SDCC1_BCR			0x01842000
#define GCC_SDCC1_APPS_CMD_RCGR		0x01842004
#define GCC_SDCC1_APPS_CFG_RCGR		0x01842008
#define GCC_SDCC1_APPS_M		0x0184200C
#define GCC_SDCC1_APPS_N		0x01842010
#define GCC_SDCC1_APPS_D		0x01842014
#define GCC_SDCC1_APPS_CBCR		0x01842018
#define GCC_SDCC1_AHB_CBCR		0x0184201C

/*
 * GCC-QPIC Registers
 */
#define GCC_QPIC_IO_MACRO_CBCR          0x0185701C
#define GCC_QPIC_CBCR_ADDR		0x01857020
#define GCC_QPIC_AHB_CBCR_ADDR		0x01857024
#define GCC_QPIC_SLEEP_CBCR		0x01857028
#define QPIC_CBCR_VAL			0x80004FF1
#define GCC_QPIC_IO_MACRO_CMD_RCGR     0x01857010
#define GCC_QPIC_IO_MACRO_CFG_RCGR     0x01857014
#define IO_MACRO_CLK_320_MHZ		320000000
#define IO_MACRO_CLK_266_MHZ		266000000
#define IO_MACRO_CLK_228_MHZ		228000000
#define IO_MACRO_CLK_200_MHZ		200000000
#define IO_MACRO_CLK_100_MHZ		100000000
#define IO_MACRO_CLK_24MHZ		24000000
#define QPIC_IO_MACRO_CLK       	0
#define QPIC_CORE_CLK           	1
#define XO_CLK_SRC			2
#define GPLL0_CLK_SRC			3
#define FB_CLK_BIT			(1 << 4)
#define UPDATE_EN			0x1

/* UART 1 */
#define GCC_BLSP1_UART1_BCR               0x01802038
#define GCC_BLSP1_UART1_APPS_CBCR         0x0180203C
#define GCC_BLSP1_UART1_APPS_CMD_RCGR     0x01802044
#define GCC_BLSP1_UART1_APPS_CFG_RCGR     0x01802048
#define GCC_BLSP1_UART1_APPS_M            0x0180204C
#define GCC_BLSP1_UART1_APPS_N            0x01802050
#define GCC_BLSP1_UART1_APPS_D            0x01802054

/* UART 2 */
#define GCC_BLSP1_UART2_BCR               0x01803028
#define GCC_BLSP1_UART2_APPS_CBCR         0x0180302C
#define GCC_BLSP1_UART2_APPS_CMD_RCGR     0x01803034
#define GCC_BLSP1_UART2_APPS_CFG_RCGR     0x01803038
#define GCC_BLSP1_UART2_APPS_M            0x0180303C
#define GCC_BLSP1_UART2_APPS_N            0x01803040
#define GCC_BLSP1_UART2_APPS_D            0x01803044

#define GCC_UART_CFG_RCGR_MODE_MASK       0x3000
#define GCC_UART_CFG_RCGR_SRCSEL_MASK     0x0700
#define GCC_UART_CFG_RCGR_SRCDIV_MASK     0x001F

#define GCC_UART_CFG_RCGR_MODE_SHIFT      12
#define GCC_UART_CFG_RCGR_SRCSEL_SHIFT    8
#define GCC_UART_CFG_RCGR_SRCDIV_SHIFT    0

#define UART1_RCGR_SRC_SEL			0x1
#define UART1_RCGR_SRC_DIV			0x0
#define UART1_RCGR_MODE				0x2
#define UART1_CMD_RCGR_UPDATE			0x1
#define UART1_CMD_RCGR_ROOT_EN			0x2
#define UART1_CBCR_CLK_ENABLE			0x1

/* USB Registers */
#define GCC_SYS_NOC_USB0_AXI_CBCR		0x1826040

#define TCSR_USB_PCIE_SEL			0x01947540

#define GCC_USB0_MASTER_CBCR			0x183E000
#define GCC_USB0_SLEEP_CBCR			0x183E004
#define GCC_USB0_MOCK_UTMI_CBCR			0x183E008
#define GCC_USB0_MASTER_CMD_RCGR		0x183E00C
#define GCC_USB0_MASTER_CFG_RCGR		0x183E010
#define GCC_USB0_MASTER_M			0x183E014
#define GCC_USB0_MASTER_N			0x183E018
#define GCC_USB0_MASTER_D			0x183E01C
#define GCC_USB0_MOCK_UTMI_CMD_RCGR		0x183E020
#define GCC_USB0_MOCK_UTMI_CFG_RCGR		0x183E024
#define GCC_USB0_MOCK_UTMI_M			0x183E028
#define GCC_USB0_MOCK_UTMI_N			0x183E02C
#define GCC_USB0_MOCK_UTMI_D			0x183E030
#define GCC_USB0_PHY_BCR			0x183E034
#define GCC_USB0_PIPE_CBCR			0x183E040
#define GCC_USB0_AUX_CBCR			0x183E044
#define GCC_USB0_PHY_PIPE_MISC			0x183E048
#define GCC_USB0_EUD_AT_CBCR			0x183E04C
#define GCC_USB0_LFPS_CBCR			0x183E050
#define GCC_USB0_AUX_CMD_RCGR			0x183E05C
#define GCC_USB0_AUX_CFG_RCGR			0x183E060
#define GCC_USB0_BCR				0x183E070
#define GCC_USB0_PHY_CFG_AHB_CBCR		0x183E080
#define GCC_USB0_LFPS_CMD_RCGR			0x183E090
#define GCC_USB0_LFPS_CFG_RCGR			0x183E094
#define GCC_USB0_LFPS_M				0x183E098
#define GCC_USB0_LFPS_N				0x183E09C
#define GCC_USB0_LFPS_D				0x183E0A0

#define GCC_USB_0_BOOT_CLOCK_CTL		0x1840000
#define GCC_QUSB2_0_PHY_BCR			0x1841030

#define USB30_GENERAL_CFG			0x8AF8808
#define USB30_GUCTL				0x8A0C12C
#define USB30_FLADJ				0x8A0C630
#define GUCTL					0x700C12C
#define FLADJ					0x700C630

#define PIPE_UTMI_CLK_SEL			0x1
#define PIPE3_PHYSTATUS_SW			(0x1 << 3)
#define PIPE_UTMI_CLK_DIS			(0x1 << 8)

#define QUSB2PHY_BASE				0x5b000

#define GCC_USB0_LFPS_CFG_SRC_SEL		(0x1 << 8)
#define GCC_USB0_LFPS_CFG_SRC_DIV		(0x1f << 0)
#define LFPS_M					0x1
#define LFPS_N					0xfe
#define LFPS_D					0xfd
#define GCC_USB0_LFPS_MODE			(0x2 << 12)

#define GCC_USB0_AUX_CFG_MODE_DUAL_EDGE 	(2 << 12)
#define GCC_USB0_AUX_CFG_SRC_SEL		(0 << 8)
#define GCC_USB0_AUX_CFG_SRC_DIV		(0x17 << 0)

#define AUX_M					0x0
#define AUX_N					0x0
#define AUX_D					0x0

#define SW_COLLAPSE_ENABLE			(1 << 0)
#define SW_OVERRIDE_ENABLE			(1 << 2)


#define GCC_USB0_MASTER_CFG_RCGR_SRC_SEL	(1 << 8)
#define GCC_USB0_MASTER_CFG_RCGR_SRC_DIV	(0x7 << 0)

#define GCC_USB_MOCK_UTMI_SRC_SEL		(1 << 8)
#define GCC_USB_MOCK_UTMI_SRC_DIV		(0x13 << 0)
#define GCC_USB_MOCK_UTMI_CLK_DIV		(0x1 << 16)

#define GCC_QUSB2_1_PHY_BCR			0x1841040

#define USB3PHY_APB_BASE			0x5d000

#define USB3_PHY_POWER_DOWN_CONTROL		0x804
#define QSERDES_COM_SYSCLK_EN_SEL		0xac
#define QSERDES_COM_BIAS_EN_CLKBUFLR_EN		0x34
#define QSERDES_COM_CLK_SELECT			0x174
#define QSERDES_COM_BG_TRIM			0x70
#define QSERDES_RX_UCDR_FASTLOCK_FO_GAIN	0x440
#define QSERDES_COM_SVS_MODE_CLK_SEL		0x19c
#define QSERDES_COM_HSCLK_SEL			0x178
#define QSERDES_COM_CMN_CONFIG			0x194
#define QSERDES_COM_PLL_IVCO			0x048
#define QSERDES_COM_SYS_CLK_CTRL		0x3c
#define QSERDES_COM_DEC_START_MODE0		0xd0
#define QSERDES_COM_DIV_FRAC_START1_MODE0	0xdc
#define QSERDES_COM_DIV_FRAC_START2_MODE0	0xe0
#define QSERDES_COM_DIV_FRAC_START3_MODE0	0xe4
#define QSERDES_COM_CP_CTRL_MODE0		0x78
#define QSERDES_COM_PLL_RCTRL_MODE0		0x84
#define QSERDES_COM_PLL_CCTRL_MODE0		0x90
#define QSERDES_COM_INTEGLOOP_GAIN0_MODE0	0x108
#define QSERDES_COM_LOCK_CMP1_MODE0		0x4c
#define QSERDES_COM_LOCK_CMP2_MODE0		0x50
#define QSERDES_COM_LOCK_CMP3_MODE0		0x54
#define QSERDES_COM_CORE_CLK_EN			0x18c
#define QSERDES_COM_LOCK_CMP_CFG		0xcc
#define QSERDES_COM_VCO_TUNE_MAP		0x128
#define QSERDES_COM_BG_TIMER			0x0c
#define QSERDES_COM_SSC_EN_CENTER		0x10
#define QSERDES_COM_SSC_PER1			0x1c
#define QSERDES_COM_SSC_PER2			0x20
#define QSERDES_COM_SSC_ADJ_PER1		0x14
#define QSERDES_COM_SSC_ADJ_PER2		0x18
#define QSERDES_COM_SSC_STEP_SIZE1		0x24
#define QSERDES_COM_SSC_STEP_SIZE2		0x28
#define QSERDES_RX_UCDR_SO_GAIN			0x410
#define QSERDES_RX_RX_EQU_ADAPTOR_CNTRL2	0x4d8
#define QSERDES_RX_RX_EQU_ADAPTOR_CNTRL3	0x4dc
#define QSERDES_RX_RX_EQU_ADAPTOR_CNTRL4	0x4e0
#define QSERDES_RX_RX_EQ_OFFSET_ADAPTOR_CNTRL	0x508
#define QSERDES_RX_RX_OFFSET_ADAPTOR_CNTRL2	0x50c
#define QSERDES_RX_SIGDET_CNTRL			0x514
#define QSERDES_RX_SIGDET_DEGLITCH_CNTRL	0x51c
#define QSERDES_RX_SIGDET_ENABLES		0x510
#define QSERDES_TX_HIGHZ_TRANSCEIVEREN_BIAS_D	0x268
#define QSERDES_TX_RCV_DETECT_LVL_2		0x2ac
#define QSERDES_TX_LANE_MODE			0x294
#define PCS_TXDEEMPH_M6DB_V0			0x824
#define PCS_TXDEEMPH_M3P5DB_V0			0x828
#define PCS_FLL_CNTRL2				0x8c8
#define PCS_FLL_CNTRL1				0x8c4
#define PCS_FLL_CNT_VAL_L			0x8cc
#define PCS_FLL_CNT_VAL_H_TOL			0x8d0
#define PCS_FLL_MAN_CODE			0x8d4
#define PCS_LOCK_DETECT_CONFIG1			0x880
#define PCS_LOCK_DETECT_CONFIG2			0x884
#define PCS_LOCK_DETECT_CONFIG3			0x888
#define PCS_POWER_STATE_CONFIG2			0x864
#define PCS_RXEQTRAINING_WAIT_TIME		0x8b8
#define PCS_RXEQTRAINING_RUN_TIME		0x8bc
#define PCS_LFPS_TX_ECSTART_EQTLOCK		0x8b0
#define PCS_PWRUP_RESET_DLY_TIME_AUXCLK		0x8a0
#define PCS_TSYNC_RSYNC_TIME			0x88c
#define PCS_RCVR_DTCT_DLY_P1U2_L		0x870
#define PCS_RCVR_DTCT_DLY_P1U2_H		0x874
#define PCS_RCVR_DTCT_DLY_U3_L			0x878
#define PCS_RCVR_DTCT_DLY_U3_H			0x87c
#define PCS_RX_SIGDET_LVL			0x9d8
#define USB3_PCS_TXDEEMPH_M6DB_V0		0x824
#define USB3_PCS_TXDEEMPH_M3P5DB_V0		0x828
#define QSERDES_RX_SIGDET_ENABLES		0x510
#define USB3_PHY_START_CONTROL			0x808
#define USB3_PHY_SW_RESET			0x800

#define CMD_UPDATE				0x1
#define ROOT_EN					0x2
#define CLK_DISABLE				0x0
#define NOC_HANDSHAKE_FSM_EN			(1 << 15)

#define set_mdelay_clearbits_le32(addr, value, delay)	\
	 setbits_le32(addr, value);			\
	 mdelay(delay);					\
	 clrbits_le32(addr, value);			\

/*
 * OTP Register
 */
#define IRON2G_RFA_RFA_OTP_OTP_XO_0             0xC4D44A0
#define IRON2G_RFA_RFA_OTP_OTP_OV_1             0xC4D4484

/*
 * PCIE Register
 */
#define GCC_SYS_NOC_PCIE0_AXI_CBCR		0x01826048
#define GCC_SYS_NOC_PCIE1_AXI_CBCR		0x0182604C

#define GCC_PCIE_BCR_ENABLE			(1 << 0)
#define GCC_PCIE_BLK_ARES			(1 << 0)
#define GCC_PCIE_PIPE_ARES			(1 << 0)
#define GCC_PCIE_SLEEP_ARES			(1 << 1)
#define GCC_PCIE_CORE_STICKY_ARES		(1 << 2)
#define GCC_PCIE_AXI_MASTER_ARES		(1 << 3)
#define GCC_PCIE_AXI_SLAVE_ARES			(1 << 4)
#define GCC_PCIE_AHB_ARES			(1 << 5)
#define GCC_PCI_AXI_MASTER_STICKY_ARES		(1 << 6)
#define GCC_PCI_AXI_SLAVE_STICKY_ARES		(1 << 7)

#define GCC_PCIE0_BOOT_CLOCK_CTL		0x01875000
#define GCC_PCIE0_BCR				0x01875004
#define GCC_PCIE0_AXI_M_CBCR			0x01875008
#define GCC_PCIE0_AXI_S_CBCR			0x0187500C
#define GCC_PCIE0_AHB_CBCR			0x01875010
#define GCC_PCIE0_PHY_PIPE_MISC			0x0187501C
#define GCC_PCIE0_AUX_CBCR			0x01875014
#define GCC_PCIE0_PIPE_CBCR			0x01875018
#define GCC_PCIE0_PHY_PIPE_MISC			0x0187501C
#define GCC_PCIE0_AUX_CMD_RCGR			0x01875020
#define GCC_PCIE0_AUX_CFG_RCGR			0x01875024
#define GCC_PCIE0_PHY_BCR			0x01875038
#define GCC_PCIE0PHY_PHY_BCR			0x0187503C
#define GCC_PCIE0_MISC_RESET			0x01875040
#define GCC_PCIE0_AXI_S_BRIDGE_CBCR		0x01875048
#define GCC_PCIE0_AXI_CMD_RCGR			0x01875050
#define GCC_PCIE0_AXI_CFG_RCGR			0x01875054
#define GCC_PCIE0_LINK_DOWN_BCR			0x018750A8
#define GCC_PCIE0_AUX_CFG_RCGR_SRC_SEL		(0 << 8)
#define GCC_PCIE0_AUX_CFG_RCGR_SRC_DIV		0x17
#define GCC_PCIE0_AXI_CFG_RCGR_SRC_SEL		(2 << 8)
#define GCC_PCIE0_AXI_CFG_RCGR_SRC_DIV		0x9


#define GCC_PCIE1_BOOT_CLOCK_CTL		0x01876000
#define GCC_PCIE1_BCR				0x01876004
#define GCC_PCIE1_AXI_M_CBCR			0x01876008
#define GCC_PCIE1_AXI_S_CBCR			0x0187600C
#define GCC_PCIE1_AHB_CBCR			0x01876010
#define GCC_PCIE1_AUX_CBCR			0x01876014
#define GCC_PCIE1_PIPE_CBCR			0x01876018
#define GCC_PCIE1_PHY_PIPE_MISC			0x0187601C
#define GCC_PCIE1_AUX_CMD_RCGR			0x01876020
#define GCC_PCIE1_AUX_CFG_RCGR			0x01876024
#define GCC_PCIE1_PHY_BCR			0x01876038
#define GCC_PCIE1PHY_PHY_BCR			0x0187603C
#define GCC_PCIE1_MISC_RESET			0x01876040
#define GCC_PCIE1_LINK_DOWN_BCR			0x01876044
#define GCC_PCIE1_AXI_S_BRIDGE_CBCR		0x01876048
#define GCC_PCIE1_AXI_CMD_RCGR			0x01876050
#define GCC_PCIE1_AXI_CFG_RCGR			0x01876054
#define GCC_PCIE1_AUX_CFG_RCGR_SRC_SEL		(0 << 8)
#define GCC_PCIE1_AUX_CFG_RCGR_SRC_DIV		0x17
#define GCC_PCIE1_AXI_CFG_RCGR_SRC_SEL		(1 << 8)
#define GCC_PCIE1_AXI_CFG_RCGR_SRC_DIV		0x7

#define PCIE_BCR			0x4
#define PCIE_AXI_M_CBCR			0x8
#define PCIE_AXI_S_CBCR			0xC
#define PCIE_AHB_CBCR			0x10
#define PCIE_AUX_CBCR			0x14
#define PCIE_PIPE_CBCR			0x18
#define PCIE_AUX_CMD_RCGR		0x20
#define PCIE_AUX_CFG_RCGR		0x24
#define PCIE_PHY_BCR			0x38
#define PCIE_PHY_PHY_BCR		0x3c
#define PCIE_MISC_RESET			0x40
#define PCIE_AXI_S_BRIDGE_CBCR		0x48
#define PCIE_AXI_CMD_RCGR		0x50
#define PCIE_AXI_CFG_RCGR		0x54

#define NOT_2D(two_d)                     (~two_d)
#define NOT_N_MINUS_M(n,m)                (~(n - m))
#define CLOCK_UPDATE_TIMEOUT_US           1000

#define KERNEL_AUTH_CMD                   0x13
#define SCM_CMD_SEC_AUTH		0x15

#define ARM_PSCI_TZ_FN_BASE		0x84000000
#define ARM_PSCI_TZ_FN(n)		(ARM_PSCI_TZ_FN_BASE + (n))

#define ARM_PSCI_TZ_FN_CPU_OFF		ARM_PSCI_TZ_FN(2)
#define ARM_PSCI_TZ_FN_CPU_ON		ARM_PSCI_TZ_FN(3)
#define ARM_PSCI_TZ_FN_AFFINITY_INFO	ARM_PSCI_TZ_FN(4)

#define CLK_ENABLE			0x1

#define SSCG_CTRL_REG_1			0x9c
#define SSCG_CTRL_REG_2			0xa0
#define SSCG_CTRL_REG_3			0xa4
#define SSCG_CTRL_REG_4			0xa8
#define SSCG_CTRL_REG_5			0xac
#define SSCG_CTRL_REG_6			0xb0
#define CDR_CTRL_REG_1                  0x80
#define CDR_CTRL_REG_2                  0x84
#define CDR_CTRL_REG_3                  0x88
#define CDR_CTRL_REG_4                  0x8C
#define CDR_CTRL_REG_5                  0x90
#define CDR_CTRL_REG_6                  0x94
#define CDR_CTRL_REG_7                  0x98

#define USB_PHY_CFG0                    0x94
#define USB_PHY_UTMI_CTRL5              0x50
#define USB_PHY_FSEL_SEL                0xB8
#define USB_PHY_HS_PHY_CTRL_COMMON0     0x54
#define USB_PHY_REFCLK_CTRL             0xA0
#define USB_PHY_HS_PHY_CTRL2            0x64
#define USB_PHY_UTMI_CTRL0              0x3c

#define UTMI_PHY_OVERRIDE_EN           (1 << 1)
#define POR_EN                         (1 << 1)
#define FREQ_SEL                       (1 << 0)
#define COMMONONN                      (1 << 7)
#define FSEL                           (1 << 4)
#define RETENABLEN                     (1 << 3)
#define USB2_SUSPEND_N_SEL             (1 << 3)
#define USB2_SUSPEND_N                 (1 << 2)
#define USB2_UTMI_CLK_EN               (1 << 1)
#define CLKCORE                        (1 << 1)
#define ATERESET                       ~(1 << 0)

unsigned int __invoke_psci_fn_smc(unsigned int, unsigned int,
					 unsigned int, unsigned int);

#define S17C_MAX_PORT			4

typedef struct {
	u32 base;
	int unit;
	int phy_addr;
	int phy_interface_mode;
	int phy_napa_gpio;
	int phy_8033_gpio;
	u32 sfp_tx_gpio;
	u32 sfp_rx_gpio;
	u32 sfp_mode;
	int phy_type;
	u32 mac_pwr;
	int ipq_swith;
	int phy_external_link;
	int switch_port_count;
	int switch_port_phy_address[S17C_MAX_PORT];
	const char phy_name[MDIO_NAME_LEN];
} ipq_gmac_board_cfg_t;

extern ipq_gmac_board_cfg_t gmac_cfg[];

static inline int gmac_cfg_is_valid(ipq_gmac_board_cfg_t *cfg)
{
	/*
	* 'cfg' is valid if and only if
	*      unit number is non-negative and less than CONFIG_IPQ_NO_MACS.
	*/
	return ((cfg >= &gmac_cfg[0]) &&
		(cfg < &gmac_cfg[CONFIG_IPQ_NO_MACS]) &&
			(cfg->unit >= 0) && (cfg->unit < CONFIG_IPQ_NO_MACS));
}

extern void ipq_gmac_common_init(ipq_gmac_board_cfg_t *cfg);
extern int ipq_gmac_init(ipq_gmac_board_cfg_t *cfg);

#ifdef CONFIG_PCI_IPQ
void board_pci_init(int id);
#endif

struct smem_ram_ptn {
	char name[16];
	unsigned long long start;
	unsigned long long size;

	/* RAM Partition attribute: READ_ONLY, READWRITE etc.  */
	unsigned attr;

	/* RAM Partition category: EBI0, EBI1, IRAM, IMEM */
	unsigned category;

	/* RAM Partition domain: APPS, MODEM, APPS & MODEM (SHARED) etc. */
	unsigned domain;

	/* RAM Partition type: system, bootloader, appsboot, apps etc. */
	unsigned type;

	/* reserved for future expansion without changing version number */
	unsigned reserved2, reserved3, reserved4, reserved5;
} __attribute__ ((__packed__));

__weak void aquantia_phy_reset_init_done(void) {}
__weak void aquantia_phy_reset_init(void) {}
__weak void qgic_init(void) {}
__weak void handle_noc_err(void) {}
__weak void board_pcie_clock_init(int id) {}

struct smem_ram_ptable {
	#define _SMEM_RAM_PTABLE_MAGIC_1	0x9DA5E0A8
	#define _SMEM_RAM_PTABLE_MAGIC_2	0xAF9EC4E2
	unsigned magic[2];
	unsigned version;
	unsigned reserved1;
	unsigned len;
	unsigned buf;
	struct smem_ram_ptn parts[32];
} __attribute__ ((__packed__));

int get_eth_caldata(u32 *caldata, u32 offset);
void board_update_caldata(void);
int smem_ram_ptable_init(struct smem_ram_ptable *smem_ram_ptable);
void reset_crashdump(void);
void reset_board(void);
void qpic_clk_enbale(void);
int ipq_get_tz_version(char *version_name, int buf_size);
void ipq_fdt_fixup_socinfo(void *blob);
void qpic_set_clk_rate(unsigned int clk_rate, int blk_type,
		int req_clk_src_type);

extern const char *rsvd_node;
extern const char *del_node[];
extern const add_node_t add_fdt_node[];

typedef enum {
	SMEM_SPINLOCK_ARRAY = 7,
	SMEM_AARM_PARTITION_TABLE = 9,
	SMEM_HW_SW_BUILD_ID = 137,
	SMEM_USABLE_RAM_PARTITION_TABLE = 402,
	SMEM_POWER_ON_STATUS_INFO = 403,
	SMEM_MACHID_INFO_LOCATION = 425,
	SMEM_IMAGE_VERSION_TABLE = 469,
	SMEM_BOOT_FLASH_TYPE = 498,
	SMEM_BOOT_FLASH_INDEX = 499,
	SMEM_BOOT_FLASH_CHIP_SELECT = 500,
	SMEM_BOOT_FLASH_BLOCK_SIZE = 501,
	SMEM_BOOT_FLASH_DENSITY = 502,
	SMEM_BOOT_DUALPARTINFO = 503,
	SMEM_PARTITION_TABLE_OFFSET = 504,
	SMEM_SPI_FLASH_ADDR_LEN = 505,
	SMEM_FIRST_VALID_TYPE = SMEM_SPINLOCK_ARRAY,
	SMEM_LAST_VALID_TYPE = SMEM_SPI_FLASH_ADDR_LEN,
	SMEM_MAX_SIZE = SMEM_SPI_FLASH_ADDR_LEN + 1,
} smem_mem_type_t;

#ifdef CONFIG_IPQ_BT_SUPPORT
#define NVM_SEGMENT_SIZE 243
#define TLV_REQ_OPCODE 0xFC00
#define TLV_COMMAND_REQUEST 0x1E
#define DATA_REMAINING_LENGTH 2
#define TLV_RESPONSE_PACKET_SIZE 8
#define TLV_RESPONSE_STATUS_INDEX 6

#define PACKED_STRUCT __attribute__((__packed__))

#define LE_UNALIGNED(x, y)  \
{                                        \
	((u8 *)(x))[0] = ((u8)(((u32)(y)) & 0xFF));            \
	((u8 *)(x))[1] = ((u8)((((u32)(y)) >> 8) & 0xFF));     \
}

typedef enum
{
	ptHCICommandPacket = 0x01,  /* Simple HCI Command Packet    */
	ptHCIACLDataPacket = 0x02,  /* HCI ACL Data Packet Type.    */
	ptHCISCODataPacket = 0x03,  /* HCI SCO Data Packet Type.    */
	ptHCIeSCODataPacket= 0x03,  /* HCI eSCO Data Packet Type.   */
	ptHCIEventPacket   = 0x04,  /* HCI Event Packet Type.       */
	ptHCIAdditional    = 0x05   /* Starting Point for Additional*/
} HCI_PacketType_t;

typedef struct _tlv_download_req
{
	u16 opcode;
	u8 parameter_total_length;
	u8 command_request;
	u8 tlv_segment_length;
	u8 tlv_segment_data[0];

} PACKED_STRUCT tlv_download_req;

typedef struct _tagHCI_Packet_t
{
	u8 HCIPacketType;
	tlv_download_req HCIPayload;
} PACKED_STRUCT HCI_Packet_t;

typedef enum {
	BT_WAIT_FOR_START = 0,
	BT_WAIT_FOR_TX_COMPLETE = 1,
	BT_WAIT_FOR_STOP = 2,
} bt_wait;

#define BT_TIMEOUT_US 500000

int bt_init(void);
#endif
#endif /* _IPQ5018_CDP_H_ */
