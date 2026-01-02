/*
 * Copyright (c) 2016-2019 The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2022 Qualcomm Innovation Center, Inc. All rights reserved.
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

#include <common.h>
#include <asm/arch-ipq5332/clk.h>
#include <asm/io.h>
#include <asm/errno.h>
#include <fdtdec.h>

DECLARE_GLOBAL_DATA_PTR;

static void uart_configure_mux(u8 id)
{
	unsigned long cfg_rcgr;

	cfg_rcgr = readl(GCC_BLSP1_UART_APPS_CFG_RCGR(id));
	/* Clear mode, src sel, src div */
	cfg_rcgr &= ~(GCC_UART_CFG_RCGR_MODE_MASK |
			GCC_UART_CFG_RCGR_SRCSEL_MASK |
			GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART_RCGR_SRC_SEL << GCC_UART_CFG_RCGR_SRCSEL_SHIFT)
			& GCC_UART_CFG_RCGR_SRCSEL_MASK);

	cfg_rcgr |= ((UART_RCGR_SRC_DIV << GCC_UART_CFG_RCGR_SRCDIV_SHIFT)
			& GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART_RCGR_MODE << GCC_UART_CFG_RCGR_MODE_SHIFT)
			& GCC_UART_CFG_RCGR_MODE_MASK);

	writel(cfg_rcgr, GCC_BLSP1_UART_APPS_CFG_RCGR(id));
}

static int uart_trigger_update(u8 id)
{
	unsigned long cmd_rcgr;
	int timeout = 0;

	cmd_rcgr = readl(GCC_BLSP1_UART_APPS_CMD_RCGR(id));
	cmd_rcgr |= UART_CMD_RCGR_UPDATE | UART_CMD_RCGR_ROOT_EN;
	writel(cmd_rcgr, GCC_BLSP1_UART_APPS_CMD_RCGR(id));

	while (readl(GCC_BLSP1_UART_APPS_CMD_RCGR(id)) & UART_CMD_RCGR_UPDATE) {
		if (timeout++ >= CLOCK_UPDATE_TIMEOUT_US) {
			printf("Timeout waiting for UART clock update\n");
			return -ETIMEDOUT;
		}
		udelay(1);
	}
	return 0;
}

int uart_clock_config(struct ipq_serial_platdata *plat)
{
	unsigned long cbcr_val;
	int ret;

	cbcr_val = readl(GCC_APCS_CLOCK_BRANCH_ENA_VOTE);
	cbcr_val |= BLSP1_AHB_CLK_ENABLE;
	writel(cbcr_val, GCC_APCS_CLOCK_BRANCH_ENA_VOTE);

	uart_configure_mux(plat->port_id);

	writel(plat->m_value, GCC_BLSP1_UART_APPS_M(plat->port_id));
	writel(NOT_N_MINUS_M(plat->n_value, plat->m_value),
				GCC_BLSP1_UART_APPS_N(plat->port_id));
	writel(NOT_2D(plat->d_value), GCC_BLSP1_UART_APPS_D(plat->port_id));

	ret = uart_trigger_update(plat->port_id);
	if (ret)
		return ret;

	cbcr_val = readl(GCC_BLSP1_UART_APPS_CBCR(plat->port_id));
	cbcr_val |= UART_CBCR_CLK_ENABLE;
	writel(cbcr_val, GCC_BLSP1_UART_APPS_CBCR(plat->port_id));
	return 0;
}

#ifdef CONFIG_QCA_MMC
void emmc_clock_init(void)
{
	int cfg;

	/* Configure sdcc1_apps_clk_src */
	cfg = (GCC_SDCC1_APPS_CFG_RCGR_SRC_SEL |
		GCC_SDCC1_APPS_CFG_RCGR_SRC_DIV |
		GCC_SDCC1_APPS_CFG_RCGR_MODE_SEL);
	writel(cfg, GCC_SDCC1_APPS_CFG_RCGR);
	/*
	 * Mode is dual edge,
	 * For 192Mhz, MND need to be set to zero
	 * 1152 / 6 = 192
	 */

	writel(0, GCC_SDCC1_APPS_M);
	writel(0, GCC_SDCC1_APPS_N);
	writel(0, GCC_SDCC1_APPS_D);

	writel(CMD_UPDATE, GCC_SDCC1_APPS_CMD_RCGR);
	mdelay(10);
	writel(ROOT_EN, GCC_SDCC1_APPS_CMD_RCGR);

	/* Configure CBCRs */
	writel(readl(GCC_SDCC1_APPS_CBCR) | CLK_ENABLE, GCC_SDCC1_APPS_CBCR);
	udelay(10);
	writel(readl(GCC_SDCC1_AHB_CBCR) | CLK_ENABLE, GCC_SDCC1_AHB_CBCR);
	udelay(10);
	return;
}

void emmc_clock_reset(void)
{
	writel(0x1, GCC_SDCC1_BCR);
	udelay(10);
	writel(0x0, GCC_SDCC1_BCR);
}
#endif
#ifdef CONFIG_PCI_IPQ
void pcie_v2_clock_init(int pcie_id)
{
	int cfg, cfg1,cfg2;
	static int clk_configure;

	if (clk_configure == 0) {
		/* Configure pcie_aux_clk_src */
		cfg = (GCC_PCIE_AUX_CFG_RCGR_MN_MODE |
			GCC_PCIE_AUX_CFG_RCGR_SRC_SEL |
			GCC_PCIE_AUX_CFG_RCGR_SRC_DIV);
		writel(cfg, GCC_PCIE_AUX_CFG_RCGR);
		writel(0, GCC_PCIE_AUX_M);
		writel(0, GCC_PCIE_AUX_N);
		writel(0, GCC_PCIE_AUX_D);
		writel(CMD_UPDATE, GCC_PCIE_AUX_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE_AUX_CMD_RCGR);
		clk_configure = 1;
	}
		/* Configure pcie axi clk source */
	cfg = (GCC_PCIE_AXI_CFG_RCGR_SRC_SEL |
			GCC_PCIE_AXI_CFG_RCGR_SRC_DIV);
	cfg1 = (GCC_PCIE_RCHG_CFG_RCGR_SRC_SEL |
			GCC_PCIE_RCHG_CFG_RCGR_SRC_DIV);
	cfg2 = (GCC_PCIE_AXI_M_CFG_RCGR_SRC_SEL |
			GCC_PCIE_AXI_M_CFG_RCGR_SRC_DIV);
	switch(pcie_id) {
	case 0:
		writel(cfg, GCC_PCIE3X1_0_AXI_CFG_RCGR);
		writel(CMD_UPDATE, GCC_PCIE3X1_0_AXI_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE3X1_0_AXI_CMD_RCGR);
		writel(cfg1, GCC_PCIE3X1_0_RCHG_CFG_RCGR);
		writel(CMD_UPDATE, GCC_PCIE3X1_0_RCHG_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE3X1_0_RCHG_CMD_RCGR);
		writel(CLK_ENABLE, GCC_PCIE3X1_0_AHB_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_0_AXI_M_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_0_AXI_S_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_0_AXI_S_BRIDGE_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_0_PIPE_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_0_AUX_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_PHY_AHB_CBCR);
		break;
	case 1:
		writel(cfg2, GCC_PCIE3X2_AXI_M_CFG_RCGR);
		writel(CMD_UPDATE, GCC_PCIE3X2_AXI_M_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE3X2_AXI_M_CMD_RCGR);
		cfg = (GCC_PCIE3X2_AXI_S_CFG_RCGR_SRC_SEL |
				GCC_PCIE3X2_AXI_S_CFG_RCGR_SRC_DIV);
		writel(cfg, GCC_PCIE3X2_AXI_S_CFG_RCGR);
		writel(CMD_UPDATE, GCC_PCIE3X2_AXI_S_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE3X2_AXI_S_CMD_RCGR);
		writel(cfg1, GCC_PCIE3X2_RCHG_CFG_RCGR);
		writel(CMD_UPDATE, GCC_PCIE3X2_RCHG_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE3X2_RCHG_CMD_RCGR);
		writel(CLK_ENABLE, GCC_PCIE3X2_AHB_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X2_AXI_M_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X2_AXI_S_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X2_AXI_S_BRIDGE_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X2_PIPE_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X2_AUX_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X2_PHY_AHB_CBCR);
		break;
	case 2:
		writel(cfg, GCC_PCIE3X1_1_AXI_CFG_RCGR);
		writel(CMD_UPDATE, GCC_PCIE3X1_1_AXI_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE3X1_1_AXI_CMD_RCGR);
		writel(cfg1, GCC_PCIE3X1_1_RCHG_CFG_RCGR);
		writel(CMD_UPDATE, GCC_PCIE3X1_1_RCHG_CMD_RCGR);
		mdelay(10);
		writel(ROOT_EN, GCC_PCIE3X1_1_RCHG_CMD_RCGR);
		writel(CLK_ENABLE, GCC_PCIE3X1_1_AHB_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_1_AXI_M_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_1_AXI_S_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_1_AXI_S_BRIDGE_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_1_PIPE_CBCR);
		writel(CLK_ENABLE, GCC_PCIE3X1_1_AUX_CBCR);
		break;
	}
	writel(CLK_ENABLE, GCC_SNOC_PCIE3_2LANE_M_CBCR);
	writel(CLK_ENABLE, GCC_SNOC_PCIE3_2LANE_S_CBCR);
	writel(CLK_ENABLE, GCC_SNOC_PCIE3_1LANE_M_CBCR);
	writel(CLK_ENABLE, GCC_SNOC_PCIE3_1LANE_S_CBCR);
	writel(CLK_ENABLE, GCC_SNOC_PCIE3_1LANE_1_M_CBCR);
	writel(CLK_ENABLE, GCC_SNOC_PCIE3_1LANE_1_S_CBCR);
	return;
}

void pcie_v2_clock_deinit(int pcie_id)
{
	writel(0x0, GCC_SNOC_PCIE3_2LANE_M_CBCR);
	writel(0x0, GCC_SNOC_PCIE3_2LANE_S_CBCR);
	writel(0x0, GCC_SNOC_PCIE3_1LANE_M_CBCR);
	writel(0x0, GCC_SNOC_PCIE3_1LANE_S_CBCR);
	writel(0x0, GCC_SNOC_PCIE3_1LANE_1_M_CBCR);
	writel(0x0, GCC_SNOC_PCIE3_1LANE_1_S_CBCR);
	switch(pcie_id) {
	case 0:
		writel(0x0, GCC_PCIE3X1_0_AHB_CBCR);
		writel(0x0, GCC_PCIE3X1_0_AXI_M_CBCR);
		writel(0x0, GCC_PCIE3X1_0_AXI_S_CBCR);
		writel(0x0, GCC_PCIE3X1_0_AXI_S_BRIDGE_CBCR);
		writel(0x0, GCC_PCIE3X1_0_PIPE_CBCR);
		writel(0x0, GCC_PCIE3X1_0_AUX_CBCR);
		writel(0x0, GCC_PCIE3X1_PHY_AHB_CBCR);
		break;
	case 1:
		writel(0x0, GCC_PCIE3X2_AHB_CBCR);
		writel(0x0, GCC_PCIE3X2_AXI_M_CBCR);
		writel(0x0, GCC_PCIE3X2_AXI_S_CBCR);
		writel(0x0, GCC_PCIE3X2_AXI_S_BRIDGE_CBCR);
		writel(0x0, GCC_PCIE3X2_PIPE_CBCR);
		writel(0x0, GCC_PCIE3X2_AUX_CBCR);
		writel(0x0, GCC_PCIE3X2_PHY_AHB_CBCR);
		break;
	case 2:
		writel(0x0, GCC_PCIE3X1_1_AHB_CBCR);
		writel(0x0, GCC_PCIE3X1_1_AXI_M_CBCR);
		writel(0x0, GCC_PCIE3X1_1_AXI_S_CBCR);
		writel(0x0, GCC_PCIE3X1_1_AXI_S_BRIDGE_CBCR);
		writel(0x0, GCC_PCIE3X1_1_PIPE_CBCR);
		writel(0x0, GCC_PCIE3X1_1_AUX_CBCR);
		break;
	}
	return;
}
#endif
#ifdef CONFIG_USB_XHCI_IPQ
void usb_clock_init(void)
{
	int cfg;

	/* Configure usb0_master_clk_src */
	cfg = (GCC_USB0_MASTER_CFG_RCGR_SRC_SEL |
		GCC_USB0_MASTER_CFG_RCGR_SRC_DIV);
	writel(cfg, GCC_USB0_MASTER_CFG_RCGR);
	writel(CMD_UPDATE, GCC_USB0_MASTER_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_MASTER_CMD_RCGR);

	/* Configure usb0_mock_utmi_clk_src */
	cfg = (GCC_USB_MOCK_UTMI_MN_MODE | GCC_USB_MOCK_UTMI_SRC_SEL |
		GCC_USB_MOCK_UTMI_SRC_DIV);
	writel(cfg, GCC_USB0_MOCK_UTMI_CFG_RCGR);
	writel(MOCK_UTMI_M, GCC_USB0_MOCK_UTMI_M);
	writel(MOCK_UTMI_N, GCC_USB0_MOCK_UTMI_N);
	writel(MOCK_UTMI_D, GCC_USB0_MOCK_UTMI_D);
	writel(CMD_UPDATE, GCC_USB0_MOCK_UTMI_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_MOCK_UTMI_CMD_RCGR);

	/* Configure usb0_aux_clk_src */
	cfg = (GCC_USB0_AUX_CFG_SRC_SEL |
		GCC_USB0_AUX_CFG_SRC_DIV);
	writel(cfg, GCC_USB0_AUX_CFG_RCGR);
	writel(CMD_UPDATE, GCC_USB0_AUX_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_AUX_CMD_RCGR);

	/* Configure usb0_lfps_cmd_rcgr */
	cfg = (GCC_USB0_LFPS_CFG_SRC_SEL |
		GCC_USB0_LFPS_CFG_SRC_DIV);
	writel(cfg, GCC_USB0_LFPS_CFG_RCGR);
	writel(LFPS_M, GCC_USB0_LFPS_M);
	writel(LFPS_N, GCC_USB0_LFPS_N);
	writel(LFPS_D, GCC_USB0_LFPS_D);
	writel(readl(GCC_USB0_LFPS_CFG_RCGR) | GCC_USB0_LFPS_MODE,
			GCC_USB0_LFPS_CFG_RCGR);
	writel(CMD_UPDATE, GCC_USB0_LFPS_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_USB0_LFPS_CMD_RCGR);

	/* Configure CBCRs */
	writel((readl(GCC_USB0_MASTER_CBCR) | CLK_ENABLE),
		GCC_USB0_MASTER_CBCR);
	writel(CLK_ENABLE, GCC_USB0_SLEEP_CBCR);
	writel(CLK_ENABLE, GCC_USB0_MOCK_UTMI_CBCR);
	writel(CLK_DISABLE, GCC_USB0_PIPE_CBCR);
	writel(CLK_ENABLE, GCC_USB0_PHY_CFG_AHB_CBCR);
	writel(CLK_ENABLE, GCC_USB0_AUX_CBCR);
	writel(CLK_ENABLE, GCC_USB0_LFPS_CBCR);
	return;
}

void usb_clock_deinit(void)
{
	writel(0x0, GCC_USB0_PHY_CFG_AHB_CBCR);
	writel(0x4220, GCC_USB0_MASTER_CBCR);
	writel(0x0, GCC_USB0_SLEEP_CBCR);
	writel(0x0, GCC_USB0_MOCK_UTMI_CBCR);
	writel(0x0, GCC_USB0_AUX_CBCR);
	writel(0x0, GCC_USB0_LFPS_CBCR);
	return;
}
#endif

#ifdef CONFIG_IPQ5332_EDMA
void nssnoc_init(void)
{
	unsigned int reg_val;

	writel(QDSS_AT_SRC_SEL | QDSS_AT_DIV_SEL, GCC_QDSS_AT_CFG_RCGR);
	reg_val = readl(GCC_QDSS_AT_CMD_RCGR);
	writel(reg_val | CMD_UPDATE, GCC_QDSS_AT_CMD_RCGR);
	mdelay(1);
	writel(reg_val | ROOT_EN, GCC_QDSS_AT_CMD_RCGR);


	/* Enable required NSSNOC clocks */
	writel(readl(GCC_NSSCFG_CLK) |
		GCC_CBCR_CLK_ENABLE, GCC_NSSCFG_CLK);

	writel(readl(GCC_NSSNOC_ATB_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_ATB_CLK);

	writel(readl(GCC_NSSNOC_QOSGEN_REF_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_QOSGEN_REF_CLK);

	writel(readl(GCC_NSSNOC_TIMEOUT_REF_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_TIMEOUT_REF_CLK);
}

void frequency_init(void)
{
	unsigned int reg_val;

	/* PCNOC_BFDCD frequency for Uniphy AHB 100M */
	reg_val = readl(GCC_PCNOC_BFDCD_CFG_RCGR);
	reg_val &= ~0x7ff;
	writel(reg_val | PCCNOC_BFDCD_SRC_SEL | PCCNOC_BFDCD_DIV_SEL,
		GCC_PCNOC_BFDCD_CFG_RCGR);
	reg_val = readl(GCC_PCNOC_BFDCD_CMD_RCGR);
	writel(reg_val | CMD_UPDATE, GCC_PCNOC_BFDCD_CMD_RCGR);
	mdelay(1);
	writel(reg_val | ROOT_EN, GCC_PCNOC_BFDCD_CMD_RCGR);

	/* GCC NSS frequency 100M */
	reg_val = readl(NSS_CC_CFG_CFG_RCGR);
	reg_val &= ~0x7ff;
	writel(reg_val | NSS_CC_SRC_SEL | NSS_CC_DIV_SEL ,
		NSS_CC_CFG_CFG_RCGR);

	reg_val = readl(NSS_CC_CFG_CMD_RCGR);
	writel(reg_val | CMD_UPDATE, NSS_CC_CFG_CMD_RCGR);
	mdelay(1);
	writel(reg_val | ROOT_EN, NSS_CC_CFG_CMD_RCGR);

	/* SYSNOC frequency 266.666667M */
	reg_val = readl(GCC_SYSTEM_NOC_BFDCD_CFG_RCGR);
	reg_val &= ~0x7ff;
	writel(reg_val | SYSTEM_NOC_BFDCD_SRC_SEL | SYSTEM_NOC_BFDCD_DIV_SEL,
			GCC_SYSTEM_NOC_BFDCD_CFG_RCGR);

	reg_val = readl(GCC_SYSTEM_NOC_BFDCD_CMD_RCGR);
	writel(reg_val | CMD_UPDATE, GCC_SYSTEM_NOC_BFDCD_CMD_RCGR);
	mdelay(1);
	writel(reg_val | ROOT_EN, GCC_SYSTEM_NOC_BFDCD_CMD_RCGR);

	/* Port Clock rate 200M */
	reg_val = readl(NSS_CC_PPE_CFG_RCGR);
	reg_val &= ~0x7ff;
	writel(reg_val | NSS_CC_PPE_SRC_SEL | NSS_CC_PPE_DIV_SEL,
			NSS_CC_PPE_CFG_RCGR);

	reg_val = readl( NSS_CC_PPE_CMD_RCGR);
	writel(reg_val | CMD_UPDATE, NSS_CC_PPE_CMD_RCGR);
	mdelay(1);
	writel(reg_val | ROOT_EN,  NSS_CC_PPE_CMD_RCGR);

	reg_val = readl(GCC_NSSCC_CBCR);
	writel(reg_val | CLK_ENABLE, GCC_NSSCC_CBCR);

	reg_val = readl(GCC_NSSNOC_NSSCC_CBCR);
	writel(reg_val | CLK_ENABLE, GCC_NSSNOC_NSSCC_CBCR);

}

void fixed_nss_csr_clock_init(void)
{
	unsigned int reg_val;

	/* NSS CSR and NSSNOC CSR Clock init */
	reg_val = readl(NSS_CC_NSSNOC_NSS_CSR_CBCR);
	writel(reg_val | CLK_ENABLE, NSS_CC_NSSNOC_NSS_CSR_CBCR);

	reg_val = readl(NSS_CC_NSS_CSR_CBCR);
	writel(reg_val | CLK_ENABLE, NSS_CC_NSS_CSR_CBCR);
}

void fixed_sys_clock_init(void)
{
	unsigned int reg_val;

	/* SYS Clock init */
	/* Enable AHB and SYS clk of CMN */

	reg_val = readl(GCC_IM_SLEEP_CBCR);
	writel(reg_val | CLK_ENABLE, GCC_IM_SLEEP_CBCR);

	reg_val = readl(GCC_CMN_BLK_ADDR + GCC_CMN_BLK_AHB_CBCR_OFFSET);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
	       GCC_CMN_BLK_ADDR + GCC_CMN_BLK_AHB_CBCR_OFFSET);

	reg_val = readl(GCC_CMN_BLK_ADDR + GCC_CMN_BLK_SYS_CBCR_OFFSET);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
	       GCC_CMN_BLK_ADDR + GCC_CMN_BLK_SYS_CBCR_OFFSET);
}

void fixed_uniphy_clock_init(void)
{
	unsigned int reg_val;

	/* Uniphy AHB AND SYS CBCR init */
	reg_val = readl(GCC_UNIPHY0_SYS_CBCR);
	writel(reg_val | CLK_ENABLE, GCC_UNIPHY0_SYS_CBCR);

	reg_val = readl(GCC_UNIPHY1_SYS_CBCR);
	writel(reg_val | CLK_ENABLE, GCC_UNIPHY1_SYS_CBCR);

	reg_val = readl(GCC_UNIPHY0_AHB_CBCR);
	writel(reg_val | CLK_ENABLE, GCC_UNIPHY0_AHB_CBCR);

	reg_val = readl(GCC_UNIPHY1_AHB_CBCR);
	writel(reg_val | CLK_ENABLE, GCC_UNIPHY1_AHB_CBCR);
}

void port_mac_clock_init(void)
{
	int i;
	unsigned int reg_val;

	/* Port Mac Clock init */
	for (i = 0; i < 2; i++) {
		reg_val = readl(GCC_PORT_MAC_ADDR + i*0x8);
		writel(reg_val | GCC_CBCR_CLK_ENABLE,
				GCC_PORT_MAC_ADDR + i*0x8);
	}
}

void cfg_clock_init(void)
{
	unsigned int reg_val;

	/* CFG Clock init */
	reg_val = readl(NSS_CC_PPE_SWITCH_CFG_ADDR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
			NSS_CC_PPE_SWITCH_CFG_ADDR);

	reg_val = readl(NSS_CC_PPE_SWITCH_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
			NSS_CC_PPE_SWITCH_CBCR);

	reg_val = readl(NSS_CC_PPE_SWITCH_CFG_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
			NSS_CC_PPE_SWITCH_CFG_CBCR);

	reg_val = readl(NSS_CC_PPE_EDMA_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
			NSS_CC_PPE_EDMA_CBCR);

	reg_val = readl(NSS_CC_PPE_EDMA_CFG_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
			NSS_CC_PPE_EDMA_CFG_CBCR);

	reg_val = readl(NSS_CC_NSSNOC_PPE_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
			NSS_CC_NSSNOC_PPE_CBCR);

	reg_val = readl(NSS_CC_NSSNOC_PPE_CFG_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
			NSS_CC_NSSNOC_PPE_CFG_CBCR);

	reg_val = readl(NSS_CC_PPE_SWITCH_BTQ_ADDR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, NSS_CC_PPE_SWITCH_BTQ_ADDR);
}

void mdio_clock_init(void)
{
	unsigned int reg_val;
	int node = fdt_path_offset(gd->fdt_blob, "/ess-switch");

	/* MDIO Master Clock init */
	reg_val = readl(GCC_MDIO_MASTER_AHB_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_MDIO_MASTER_AHB_CBCR);

	/* Enable 50MHZ */
	reg_val = readl(MDIO_50MHZ_CLK_BASE);
	reg_val |= BIT(0);
	writel(reg_val, MDIO_50MHZ_CLK_BASE);

	if (!(fdtdec_get_uint(gd->fdt_blob, node,
		"qca8084_bypass_enable", 0))) {
		reg_val = readl(MDIO_50MHZ_CLK_BASE + 0x10000);
		reg_val |= BIT(0);
		writel(reg_val, MDIO_50MHZ_CLK_BASE + 0x10000);
	}
}


void noc_clock_init(void)
{
	unsigned int reg_val;

	/* NOC Clock init */
	reg_val = readl(GCC_NSSNOC_SNOC_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_NSSNOC_SNOC_CBCR);

	reg_val = readl(GCC_NSSNOC_SNOC_1_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_NSSNOC_SNOC_1_CBCR);
}

void uniphy_clock_enable(enum uniphy_clk_type clk_type, bool enable)
{
	unsigned int reg_val, i;

	i  = clk_type;

	if (clk_type <= NSS_PORT2_TX_CLK_E) {
		reg_val = readl(NSS_CC_PORT1_RX_CBCR + i*0x8);
		if (enable)
			reg_val |= GCC_CBCR_CLK_ENABLE;
		else
			reg_val &= ~GCC_CBCR_CLK_ENABLE;
		writel(reg_val, (NSS_CC_PORT1_RX_CBCR + i*0x8));
	} else {
		reg_val = readl(NSS_CC_UNIPHY_PORT1_RX_CBCR + (i - 4)*0x4);
		if (enable)
			reg_val |= GCC_CBCR_CLK_ENABLE;
		else
			reg_val &= ~GCC_CBCR_CLK_ENABLE;
		writel(reg_val, (NSS_CC_UNIPHY_PORT1_RX_CBCR + (i - 4)*0x4));
	}
}

void uniphy_clk_init(bool enable)
{
	int i;
	/* Uniphy clock enable */
	for (i = NSS_PORT1_RX_CLK_E; i < UNIPHYT_CLK_MAX; i++)
		uniphy_clock_enable(i, enable);
}

void fixed_clock_init(void)
{
	frequency_init();

	fixed_nss_csr_clock_init();

	fixed_sys_clock_init();

	fixed_uniphy_clock_init();

	port_mac_clock_init();

	cfg_clock_init();

	mdio_clock_init();

	noc_clock_init();
}

void cmbblk_init(void)
{
	unsigned int reg_val;

	reg_val = readl(PLL_REFERENCE_CLOCK);
	reg_val = (reg_val & FREQUENCY_MASK) | INTERNAL_48MHZ_CLOCK;
	/*Select clock source*/
	writel(reg_val, PLL_REFERENCE_CLOCK);

	/* Soft reset to calibration clocks */
	reg_val = readl(PLL_POWER_ON_AND_RESET);
	reg_val &= ~BIT(6);
	writel(reg_val, PLL_POWER_ON_AND_RESET);
	mdelay(10);
	reg_val |= BIT(6);
	writel(reg_val, PLL_POWER_ON_AND_RESET);
	mdelay(10);
}

void eth_clock_init(void)
{
	nssnoc_init();

	fixed_clock_init();

	uniphy_clk_init(true);

	cmbblk_init();
}
#endif
