/*
 * Copyright (c) 2012 - 2014 The Linux Foundation. All rights reserved.
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

#ifndef __PLATFORM_IPQ860X_CLOCK_H_
#define __PLATFORM_IPQ860X_CLOCK_H_

#include <configs/ipq806x.h>
#include <asm/io.h>

#define MSM_CLK_CTL_BASE                        0x00900000
#define GSBIn_UART_APPS_MD_REG(n)               (MSM_CLK_CTL_BASE + 0x29D0 + (0x20*((n)-1)))
#define GSBIn_UART_APPS_NS_REG(n)               (MSM_CLK_CTL_BASE + 0x29D4 + (0x20*((n)-1)))
#define GSBIn_HCLK_CTL_REG(n)                   (MSM_CLK_CTL_BASE + 0x29C0 + (0x20*((n)-1)))
#define BB_PLL_ENA_SC0_REG                      (MSM_CLK_CTL_BASE + 0x34C0)
#define PLL_LOCK_DET_STATUS_REG                 (MSM_CLK_CTL_BASE + 0x03420)
#define EBI2_CLK_CTL_REG                 	(MSM_CLK_CTL_BASE + 0x03B00)

#define MN_MODE_DUAL_EDGE                       0x2

#define BM(m, l)                                (((((unsigned int)-1) << (31-m)) >> (31-m+l)) << l)
#define BVAL(m, l, val)                         (((val) << l) & BM(m, l))

#define Uart_clk_ns_mask                        (BM(31, 16) | BM(6, 0))
#define Uart_en_mask                            BIT(11)
#define MD16(m, n)                              (BVAL(31, 16, m) | BVAL(15, 0, ~(n)))
/* MD Registers */
#define MD4(m_lsb, m, n_lsb, n) \
		(BVAL((m_lsb+3), m_lsb, m) | BVAL((n_lsb+3), n_lsb, ~(n)))

#define MD8(m_lsb, m, n_lsb, n) \
		(BVAL((m_lsb+7), m_lsb, m) | BVAL((n_lsb+7), n_lsb, ~(n)))

/* NS Registers */
#define NS(n_msb, n_lsb, n, m, mde_lsb, d_msb, d_lsb, d, s_msb, s_lsb, s) \
        (BVAL(n_msb, n_lsb, ~(n-m)) \
         | (BVAL((mde_lsb+1), mde_lsb, MN_MODE_DUAL_EDGE) * !!(n)) \
         | BVAL(d_msb, d_lsb, (d-1)) | BVAL(s_msb, s_lsb, s))

#define GMAC_CORE_RESET(n)      \
                ((void *)(0x903CBC + ((n) * 0x20)))
#define GMACSEC_CORE_RESET(n)   \
                ((void *)(0x903E28 + ((n - 1) * 4)))

#define ALWAYS_ON_CLK_BRANCH_ENA(i)         ((i) << 8)
#define CLK_BRANCH_ENA(i)                   ((i) << 4)

#define MSM_CLK_CTL_BASE	0x00900000
#define REG(off)	(MSM_CLK_CTL_BASE + (off))

#define BIT_POS_23	23
#define BIT_POS_16	16
#define BIT_POS_6 	6
#define BIT_POS_0	0
#define I2C_en_mask	BIT(11)
#define I2C_clk_ns_mask	(BM(BIT_POS_23, BIT_POS_16) | BM(BIT_POS_6, BIT_POS_0))

#define GSBIn_QUP_APPS_MD_REG(n)	REG(0x29C8+(0x20*((n)-1)))
#define GSBIn_QUP_APPS_NS_REG(n)	REG(0x29CC+(0x20*((n)-1)))
#define SDC1_HCLK_CTL		REG(0x2820)
#define SDC1_APPS_CLK_MD	REG(0x2828)
#define SDC1_APPS_CLK_NS	REG(0x282C)
#define SDC1_RESET		REG(0x2830)
#define emmc_clk_ns_mask (BM(BIT_POS_23, BIT_POS_16) | BM(BIT_POS_6, BIT_POS_0))
#define emmc_en_mask BIT(11)

#define PCIE_0_ACLK_CTL                         0x9022C0
#define PCIE_1_ACLK_CTL                         0x903a80
#define PCIE_2_ACLK_CTL                         0x903ac0
#define PCIE_0_PCLK_CTL                         0x9022D0
#define PCIE_1_PCLK_CTL                         0x903A90
#define PCIE_2_PCLK_CTL                         0x903AD0
#define PCIE_0_HCLK_CTL                         0x9022CC
#define PCIE_1_HCLK_CTL                         0x903A8C
#define PCIE_2_HCLK_CTL                         0x903ACC
#define PCIE_0_AUX_CLK_CTL                      0x9022C8
#define PCIE_1_AUX_CLK_CTL                      0x903A88
#define PCIE_2_AUX_CLK_CTL                      0x903AC8
#define PCIE_0_ALT_REF_CLK_NS                   0x903860
#define PCIE_1_ALT_REF_CLK_NS                   0x903AA0
#define PCIE_2_ALT_REF_CLK_NS                   0x903AE0
#define PCIE_0_ALT_REF_CLK_ACR                  0x901344
#define PCIE_1_ALT_REF_CLK_ACR                  0x901354
#define PCIE_2_ALT_REF_CLK_ACR                  0x90135C
#define PCIE_0_ACLK_FS                          0x9022C4
#define PCIE_0_PCLK_FS                          0x9022D4
#define PCIE_1_ACLK_FS                          0x903A84
#define PCIE_1_PCLK_FS                          0x903A94
#define PCIE_2_ACLK_FS                          0x903AC4
#define PCIE_2_PCLK_FS                          0x903AD4
#define PCIE20_0_PARF_PHY_REFCLK                0x1B60004C
#define PCIE20_1_PARF_PHY_REFCLK                0x1B80004C
#define PCIE20_2_PARF_PHY_REFCLK                0x1BA0004C

typedef struct {
        unsigned int aclk_ctl;
        unsigned int pclk_ctl;
        unsigned int hclk_ctl;
        unsigned int aux_clk_ctl;
        unsigned int alt_ref_clk_ns;
        unsigned int alt_ref_clk_acr;
        unsigned int aclk_fs;
        unsigned int pclk_fs;
        unsigned int parf_phy_refclk;
} pci_clk_offset_t;

#define USB30_MASTER_CLK_CTL				REG(0x3B24)
#define USB30_MASTER_1_CLK_CTL				REG(0x3B34)
#define USB30_MASTER_CLK_MD				REG(0x3B28)
#define USB30_MASTER_CLK_NS				REG(0x3B2C)
#define USB30_MOC_UTMI_CLK_MD				REG(0x3B40)
#define USB30_MOC_UTMI_CLK_NS				REG(0x3B44)
#define USB30_MOC_UTMI_CLK_CTL				REG(0x3B48)
#define USB30_MOC_1_UTMI_CLK_CTL			REG(0x3B4C)

#define USB_clk_ns_mask  (BM(BIT_POS_23, BIT_POS_16) | BM(BIT_POS_6, BIT_POS_0))
#define USB_en_mask  BIT(11)

void usb_ss_core_clock_config(unsigned int usb_port, unsigned int m,
		unsigned int n, unsigned int d);
void usb_ss_utmi_clock_config(unsigned int usb_port, unsigned int m,
		unsigned int n, unsigned int d);

void i2c_clock_config(void);
void emmc_clock_config(int mode);
void nand_clock_config(void);
void pcie_clock_config(pci_clk_offset_t *offset);
void pcie_clock_shutdown(pci_clk_offset_t *offset);
void emmc_clock_reset(void);
void emmc_clock_disable(void);
/* Uart specific clock settings */
void uart_pll_vote_clk_enable(void);
void uart_clock_config(unsigned int gsbi_port, unsigned int m, unsigned int n,
		unsigned int d);
#endif  /*  __PLATFORM_IPQ860X_CLOCK_H_ */
