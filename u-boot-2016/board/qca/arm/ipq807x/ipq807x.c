/*
 * Copyright (c) 2016-2017, The Linux Foundation. All rights reserved.
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
#include <asm/global_data.h>
#include <asm/io.h>
#include <asm/errno.h>
#include <environment.h>
#include <asm/arch-qca-common/qca_common.h>
#include <asm/arch-qca-common/qpic_nand.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/smem.h>
#include <asm/arch-qca-common/scm.h>
#include <fdtdec.h>
#include <mmc.h>
#include <usb.h>
#include <linux/linkage.h>
#include <sdhci.h>

#define MSM_GIC_DIST_BASE	0x0B000000
#define MSM_GIC_CPU_BASE	0x0B002000

#define GIC_CPU_REG(off)	(MSM_GIC_CPU_BASE  + (off))
#define GIC_DIST_REG(off)	(MSM_GIC_DIST_BASE + (off))

#define GIC_CPU_CTRL		GIC_CPU_REG(0x00)
#define GIC_CPU_PRIMASK		GIC_CPU_REG(0x04)
#define GIC_CPU_BINPOINT	GIC_CPU_REG(0x08)
#define GIC_CPU_INTACK		GIC_CPU_REG(0x0c)
#define GIC_CPU_EOI		GIC_CPU_REG(0x10)
#define GIC_CPU_RUNNINGPRI	GIC_CPU_REG(0x14)
#define GIC_CPU_HIGHPRI		GIC_CPU_REG(0x18)

#define GIC_DIST_CTRL		GIC_DIST_REG(0x000)
#define GIC_DIST_CTR		GIC_DIST_REG(0x004)
#define GIC_DIST_ENABLE_SET	GIC_DIST_REG(0x100)
#define GIC_DIST_ENABLE_CLEAR	GIC_DIST_REG(0x180)
#define GIC_DIST_PENDING_SET	GIC_DIST_REG(0x200)
#define GIC_DIST_PENDING_CLEAR	GIC_DIST_REG(0x280)
#define GIC_DIST_ACTIVE_BIT	GIC_DIST_REG(0x300)
#define GIC_DIST_PRI		GIC_DIST_REG(0x400)
#define GIC_DIST_TARGET		GIC_DIST_REG(0x800)
#define GIC_DIST_CONFIG		GIC_DIST_REG(0xc00)
#define GIC_DIST_SOFTINT	GIC_DIST_REG(0xf00)

#define REG_VAL_NOC_ERR		0x100000
#define NOC_ERR_STATUS_REG	0xb000220
#define NOC_ERR_CLR_REG		0xb0002a0

#define DLOAD_MAGIC_COOKIE	0x10

#define TCSR_SOC_HW_VERSION_REG 0x194D000

DECLARE_GLOBAL_DATA_PTR;

#define GCNT_PSHOLD             0x004AB000

#ifndef CONFIG_SDHCI_SUPPORT
qca_mmc mmc_host;
#else
struct sdhci_host mmc_host;
#endif
extern loff_t board_env_offset;
extern loff_t board_env_range;
extern loff_t board_env_size;

extern int ipq_spi_init(u16);
extern int ipq807x_edma_init(void *cfg);

#ifdef CONFIG_QCA_MMC
#ifdef CONFIG_SDHCI_SUPPORT
extern int board_mmc_env_init(struct sdhci_host mmc_host);
#else
extern int board_mmc_env_init(qca_mmc mmc_host);
#endif
#endif

const char *rsvd_node = "/reserved-memory";
const char *del_node[] = {"uboot",
			  "sbl",
			  NULL};
const add_node_t add_fdt_node[] = {{}};
#ifdef CONFIG_PCI_IPQ
static int pci_initialised;
#endif
static int aq_phy_initialised;
struct dumpinfo_t dumpinfo_n[] = {
	/* TZ stores the DDR physical address at which it stores the
	 * APSS regs, NSS IMEM copy and PMIC dump. We will have the TZ IMEM
	 * IMEM Addr at which the DDR physical address is stored as
	 * the start
	 *     --------------------
         *     |  DDR phy (start) | ----> ------------------------
         *     --------------------       | APSS regsave (8k)    |
         *                                ------------------------
         *                                |                      |
	 *                                |  NSS IMEM copy       |
         *                                |        (384k)        |
	 *                                |                      |
         *                                ------------------------
	 *                                |  PMIC dump (8k)      |
	 *                                ------------------------
	 */

	/* Compressed EBICS dump follows descending order
	 * to use in-memory compression for which destination
	 * for compression will be address of EBICS2.BIN
	 */
	{ "EBICS0.BIN", 0x40000000, 0x10000000, 0 },
	{ "EBICS2.BIN", 0x60000000, 0x20000000, 0, 0, 0, 0, 1 },
	{ "EBICS1.BIN", CONFIG_UBOOT_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS0.BIN", 0x40000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 },
	{ "CODERAM.BIN", 0x00200000, 0x00028000, 0 },
	{ "DATARAM.BIN", 0x00290000, 0x00014000, 0 },
	{ "MSGRAM.BIN", 0x00060000, 0x00006000, 1 },
	{ "IMEM.BIN", 0x08600000, 0x00001000, 0 },
	{ "NSSIMEM.BIN", 0x08600658, 0x00060000, 0, 1, 0x2000 },
	{ "UNAME.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "CPU_INFO.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "DMESG.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "PT.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "WLAN_MOD.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
};
int dump_entries_n = ARRAY_SIZE(dumpinfo_n);

gpio_func_data_t spi_nor_gpio[] = {
	{
		.gpio = 38,
		.func = 3,
		.pull = 3,
		.oe = 0,
		.vm = 1,
		.od_en = 0,
		.pu_res = 2,
	},
	{
		.gpio = 39,
		.func = 3,
		.pull = 3,
		.oe = 0,
		.vm = 1,
		.od_en = 0,
		.pu_res = 2,
	},
	{
		.gpio = 40,
		.func = 2,
		.pull = 3,
		.oe = 0,
		.vm = 1,
		.od_en = 0,
		.pu_res = 2,
	},
	{
		.gpio = 41,
		.func = 2,
		.pull = 3,
		.oe = 0,
		.vm = 1,
		.od_en = 0,
		.pu_res = 2,
	},
};

gpio_func_data_t qpic_nand_gpio[] = {
	{
		.gpio = 1,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 3,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 4,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 5,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 6,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 7,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 8,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 10,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 11,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 12,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 13,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 14,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 15,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
	{
		.gpio = 17,
		.func = 1,
		.pull = 3,
		.drvstr = 3,
		.oe = 0,
	},
};

board_param_t gboard_param = {
	.spi_nor_cfg = {
		.gpio = spi_nor_gpio,
		.gpio_count = ARRAY_SIZE(spi_nor_gpio),
	},
	.qpic_nand_cfg = {
		.gpio = qpic_nand_gpio,
		.gpio_count = ARRAY_SIZE(qpic_nand_gpio),
	},
};

void uart2_configure_mux(void)
{
	unsigned long cfg_rcgr;

	cfg_rcgr = readl(GCC_BLSP1_UART2_APPS_CFG_RCGR);
	/* Clear mode, src sel, src div */
	cfg_rcgr &= ~(GCC_UART_CFG_RCGR_MODE_MASK |
			GCC_UART_CFG_RCGR_SRCSEL_MASK |
			GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART2_RCGR_SRC_SEL << GCC_UART_CFG_RCGR_SRCSEL_SHIFT)
			& GCC_UART_CFG_RCGR_SRCSEL_MASK);

	cfg_rcgr |= ((UART2_RCGR_SRC_DIV << GCC_UART_CFG_RCGR_SRCDIV_SHIFT)
			& GCC_UART_CFG_RCGR_SRCDIV_MASK);

	cfg_rcgr |= ((UART2_RCGR_MODE << GCC_UART_CFG_RCGR_MODE_SHIFT)
			& GCC_UART_CFG_RCGR_MODE_MASK);

	writel(cfg_rcgr, GCC_BLSP1_UART2_APPS_CFG_RCGR);
}

void uart2_set_rate_mnd(unsigned int m,
			unsigned int n, unsigned int two_d)
{
	writel(m, GCC_BLSP1_UART2_APPS_M);
	writel(NOT_N_MINUS_M(n, m), GCC_BLSP1_UART2_APPS_N);
	writel(NOT_2D(two_d), GCC_BLSP1_UART2_APPS_D);
}

int uart2_trigger_update(void)
{
	unsigned long cmd_rcgr;
	int timeout = 0;

	cmd_rcgr = readl(GCC_BLSP1_UART2_APPS_CMD_RCGR);
	cmd_rcgr |= UART2_CMD_RCGR_UPDATE;
	writel(cmd_rcgr, GCC_BLSP1_UART2_APPS_CMD_RCGR);

	while (readl(GCC_BLSP1_UART2_APPS_CMD_RCGR) & UART2_CMD_RCGR_UPDATE) {
		if (timeout++ >= CLOCK_UPDATE_TIMEOUT_US) {
			printf("Timeout waiting for UART2 clock update\n");
			return -ETIMEDOUT;
		}
		udelay(1);
	}
	cmd_rcgr = readl(GCC_BLSP1_UART2_APPS_CMD_RCGR);
	return 0;
}

void uart2_toggle_clock(void)
{
	unsigned long cbcr_val;

	cbcr_val = readl(GCC_BLSP1_UART2_APPS_CBCR);
	cbcr_val |= UART2_CBCR_CLK_ENABLE;
	writel(cbcr_val, GCC_BLSP1_UART2_APPS_CBCR);
}

void uart2_clock_config(unsigned int m,
			unsigned int n, unsigned int two_d)
{
	uart2_configure_mux();
	uart2_set_rate_mnd(m, n, two_d);
	uart2_trigger_update();
	uart2_toggle_clock();
}

void qca_serial_init(struct ipq_serial_platdata *plat)
{
	int node, uart2_node;

	if (plat->port_id == 1) {
		uart2_node = fdt_path_offset(gd->fdt_blob, "uart2");
		if (uart2_node < 0) {
			printf("Could not find uart2 node\n");
			return;
		}
		node = fdt_subnode_offset(gd->fdt_blob,
				uart2_node, "serial_gpio");
		uart2_clock_config(plat->m_value, plat->n_value, plat->d_value);
		writel(1, GCC_BLSP1_UART2_APPS_CBCR);
		qca_gpio_init(node);
	}
}

unsigned long timer_read_counter(void)
{
	return 0;
}

void reset_crashdump(void)
{
	unsigned int ret = 0;
	unsigned int cookie = 0;

	qca_scm_sdi();

	cookie = ipq_read_tcsr_boot_misc();
	cookie &= DLOAD_DISABLE;
	ret = qca_scm_dload(cookie);
	if (ret)
		printf ("Error in reseting the Magic cookie\n");
	return;
}

void psci_sys_reset(void)
{
	__invoke_psci_fn_smc(0x84000009, 0, 0, 0);
}

void qti_scm_pshold(void)
{
	int ret;

	ret = scm_call(SCM_SVC_BOOT, SCM_CMD_TZ_PSHOLD, NULL, 0, NULL, 0);

	if (ret != 0)
		writel(0, GCNT_PSHOLD);
}

void reset_cpu(unsigned long a)
{
	reset_crashdump();
	if (is_scm_armv8()) {
		psci_sys_reset();
	} else {
		qti_scm_pshold();
	}
	while(1);
}


#ifdef CONFIG_IPQ_FDT_FIXUP
int sdx65_attached(void);

int get_ap2mdm_gpio(void)
{
	int ap2mdm_gpio = -1, node;

	node = fdt_path_offset(gd->fdt_blob, "/sdx-gpio");
	if (node >= 0) {
		if(sdx65_attached())
			ap2mdm_gpio = fdtdec_get_uint(gd->fdt_blob, node, "x65-ap2mdm", -1);
		else
			ap2mdm_gpio = fdtdec_get_uint(gd->fdt_blob, node, "x55-ap2mdm", -1);
	} else
		return node;

	return ap2mdm_gpio;
}

void indicate_sdx_device(void)
{
	int ap2mdm_gpio;
	unsigned int *ap2mdm_gpio_base;

	unsigned int machid = gd->bd->bi_arch_number;
	if (machid != 0x08010400)
		return;

	ap2mdm_gpio = get_ap2mdm_gpio();
	if(ap2mdm_gpio >= 0) {
		/* Enabling OE in gpio cfg reg */
		ap2mdm_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(ap2mdm_gpio);
		writel(0x2c0, ap2mdm_gpio_base);
		/* Indicate SDx by writing low to ap2mdm */
		gpio_set_value(ap2mdm_gpio, 0x0);
	}

}
#endif

void reset_board(void)
{
	run_command("reset", 0);
}

void emmc_clock_config(int mode)
{
	/* Enable root clock generator */
	writel(readl(GCC_SDCC1_APPS_CBCR)|0x1, GCC_SDCC1_APPS_CBCR);
	/* Add 10us delay for CLK_OFF to get cleared */
	udelay(10);

	if (mode == MMC_IDENTIFY_MODE) {
		/* XO - 400Khz*/
		writel(0x2017, GCC_SDCC1_APPS_CFG_RCGR);
		/* Delay for clock operation complete */
		udelay(10);
		writel(0x1, GCC_SDCC1_APPS_M);
		writel(0xFC, GCC_SDCC1_APPS_N);
		writel(0xFD, GCC_SDCC1_APPS_D);
		/* Delay for clock operation complete */
		udelay(10);

	}
	if (mode == MMC_DATA_TRANSFER_MODE) {
		/* PLL0 - 50Mhz */
		writel(0x40F, GCC_SDCC1_APPS_CFG_RCGR);
		/* Delay for clock operation complete */
		udelay(10);
		writel(0x1, GCC_SDCC1_APPS_M);
		writel(0xFC, GCC_SDCC1_APPS_N);
		writel(0xFD, GCC_SDCC1_APPS_D);
		/* Delay for clock operation complete */
		udelay(10);
	}
	if (mode == MMC_DATA_TRANSFER_SDHCI_MODE) {
		/* PLL0 - 192Mhz */
		writel(0x20B, GCC_SDCC1_APPS_CFG_RCGR);
		/* Delay for clock operation complete */
		udelay(10);
		writel(0x1, GCC_SDCC1_APPS_M);
		writel(0xFC, GCC_SDCC1_APPS_N);
		writel(0xFD, GCC_SDCC1_APPS_D);
		/* Delay for clock operation complete */
		udelay(10);
	}
	/* Update APPS_CMD_RCGR to reflect source selection */
	writel(readl(GCC_SDCC1_APPS_CMD_RCGR)|0x1, GCC_SDCC1_APPS_CMD_RCGR);
	/* Add 10us delay for clock update to complete */
	udelay(10);
}

void emmc_clock_disable(void)
{
	/* Clear divider */
	writel(0x0, GCC_SDCC1_MISC);
}

void board_mmc_deinit(void)
{
	emmc_clock_disable();
}

void emmc_clock_reset(void)
{
	writel(0x1, GCC_SDCC1_BCR);
	udelay(10);
	writel(0x0, GCC_SDCC1_BCR);
}

void emmc_sdhci_init(void)
{
	writel(readl(MSM_SDC1_MCI_HC_MODE) & (~0x1), MSM_SDC1_MCI_HC_MODE);
	writel(readl(MSM_SDC1_BASE) | (1 << 7), MSM_SDC1_BASE); //SW_RST
	udelay(10);
	writel(readl(MSM_SDC1_MCI_HC_MODE) | (0x1), MSM_SDC1_MCI_HC_MODE);
}

int get_aquantia_gpio(void)
{
	int aquantia_gpio = -1, node;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0)
		aquantia_gpio = fdtdec_get_uint(gd->fdt_blob, node, "aquantia_gpio", -1);
	else
		return node;

	return aquantia_gpio;
}

int get_napa_gpio(int napa_gpio[2])
{
	int napa_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		napa_gpio_cnt = fdtdec_get_uint(gd->fdt_blob, node, "napa_gpio_cnt", -1);
		if (napa_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node, "napa_gpio",
						   (u32 *)napa_gpio, napa_gpio_cnt);
			if (res >= 0)
				return napa_gpio_cnt;
		}
	}

	return res;
}

void aquantia_phy_reset_init(void)
{
	int aquantia_gpio = -1, node;
	unsigned int *aquantia_gpio_base;

	if (!aq_phy_initialised) {
		node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
		if (node >= 0)
			aquantia_gpio = fdtdec_get_uint(gd->fdt_blob, node, "aquantia_gpio", -1);

		if (aquantia_gpio >=0) {
			aquantia_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(aquantia_gpio);
			writel(0x203, aquantia_gpio_base);
			gpio_direction_output(aquantia_gpio, 0x0);
		}
		aq_phy_initialised = 1;
	}
}

void napa_phy_reset_init(void)
{
	int napa_gpio[2] = {0}, napa_gpio_cnt, i;
	unsigned int *napa_gpio_base;

	napa_gpio_cnt = get_napa_gpio(napa_gpio);
	if (napa_gpio_cnt >= 1) {
		for (i = 0; i < napa_gpio_cnt; i++) {
			if (napa_gpio[i] >=0) {
				napa_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(napa_gpio[i]);
				writel(0x203, napa_gpio_base);
				gpio_direction_output(napa_gpio[i], 0x0);
			}
		}
	}
}

void sfp_reset_init(void)
{
	int sfp_gpio = -1, node;
	unsigned int *sfp_gpio_base;

		node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
		if (node >= 0)
			sfp_gpio = fdtdec_get_uint(gd->fdt_blob, node, "sfp_gpio", -1);

		if (sfp_gpio >=0) {
			sfp_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(sfp_gpio);
			writel(0x2C1, sfp_gpio_base);
		}
}

void napa_phy_reset_init_done(void)
{
	int napa_gpio[2] = {0}, napa_gpio_cnt, i;

	napa_gpio_cnt = get_napa_gpio(napa_gpio);
	if (napa_gpio_cnt >= 1) {
		for (i = 0; i < napa_gpio_cnt; i++)
			gpio_set_value(napa_gpio[i], 0x1);
	}
}

void aquantia_phy_reset_init_done(void)
{
	int aquantia_gpio;

	aquantia_gpio = get_aquantia_gpio();
	if (aquantia_gpio >= 0) {
		gpio_set_value(aquantia_gpio, 0x1);
	}
}
void check_uniphy_ext_ref_clk(void)
{
	int node;
	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		if(fdtdec_get_bool(gd->fdt_blob, node, "uniphy_ext_ref_clk")){
			printf("External ref clk setting found... \n");
			writel(PLL_REF_CLKSEL_50M, PLL_REFERENCE_CLOCK); /*0x8218 - 50M 0x8017 - 48M(default)*/
			writel(ANA_EN_SW_RSTN_DIS, PLL_POWER_ON_AND_RESET);	/*give reset*/
			mdelay(1);
			writel(ANA_EN_SW_RSTN_EN, PLL_POWER_ON_AND_RESET);
		}
	}
}
void eth_clock_enable(void)
{
	int tlmm_base = 0x1025000;

	/*
	 * ethernet clk rcgr block init -- start
	 * these clk init will be moved to sbl later
	 */

	writel(0x100 ,0x01868024);
	writel(0x1 ,0x01868020);
	writel(0x2 ,0x01868020);
	writel(0x100 ,0x0186802C);
	writel(0x1 ,0x01868028);
	writel(0x2 ,0x01868028);
	writel(0x100 ,0x01868034);
	writel(0x1 ,0x01868030);
	writel(0x2 ,0x01868030);
	writel(0x100 ,0x0186803C);
	writel(0x1 ,0x01868038);
	writel(0x2 ,0x01868038);
	writel(0x100 ,0x01868044);
	writel(0x1 ,0x01868040);
	writel(0x2 ,0x01868040);
	writel(0x100 ,0x0186804C);
	writel(0x1 ,0x01868048);
	writel(0x2 ,0x01868048);
	writel(0x100 ,0x01868054);
	writel(0x1 ,0x01868050);
	writel(0x2 ,0x01868050);
	writel(0x100 ,0x0186805C);
	writel(0x1 ,0x01868058);
	writel(0x2 ,0x01868058);
	writel(0x100 ,0x01868064);
	writel(0x1 ,0x01868060);
	writel(0x2 ,0x01868060);
	writel(0x100 ,0x0186806C);
	writel(0x1 ,0x01868068);
	writel(0x2 ,0x01868068);
	writel(0x100 ,0x01868074);
	writel(0x1 ,0x01868070);
	writel(0x2 ,0x01868070);
	writel(0x100 ,0x0186807C);
	writel(0x1 ,0x01868078);
	writel(0x2 ,0x01868078);
	writel(0x101 ,0x01868084);
	writel(0x1 ,0x01868080);
	writel(0x2 ,0x01868080);
	writel(0x100 ,0x0186808C);
	writel(0x1 ,0x01868088);
	writel(0x2 ,0x01868088);

	/*
	 * ethernet clk rcgr block init -- end
	 * these clk init will be moved to sbl later
	 */

	/*this is for ext oscillator clk for ref clk-*/
	check_uniphy_ext_ref_clk();

	/* bring phy out of reset */
	writel(7, tlmm_base + 0x1f000);
	writel(7, tlmm_base + 0x20000);
	writel(0x203, tlmm_base);
	writel(0, tlmm_base + 0x4);
	aquantia_phy_reset_init();
	napa_phy_reset_init();
	sfp_reset_init();
	mdelay(500);
	writel(2, tlmm_base + 0x4);
	aquantia_phy_reset_init_done();
	napa_phy_reset_init_done();
	mdelay(500);
}

int board_eth_init(bd_t *bis)
{
	int ret=0;

	eth_clock_enable();
	ret = ipq807x_edma_init(NULL);

	if (ret != 0)
		printf("%s: ipq807x_edma_init failed : %d\n", __func__, ret);

	return ret;
}

int board_mmc_init(bd_t *bis)
{
	int node;
	int ret = 0;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	node = fdt_path_offset(gd->fdt_blob, "mmc");
	if (node < 0) {
		printf("sdhci: Node Not found, skipping initialization\n");
		return -1;
	}

#ifndef CONFIG_SDHCI_SUPPORT
	mmc_host.base = MSM_SDC1_BASE;
	mmc_host.clk_mode = MMC_IDENTIFY_MODE;
	emmc_clock_config(mmc_host.clk_mode);

	ret = qca_mmc_init(bis, &mmc_host);
#else
	mmc_host.ioaddr = (void *)MSM_SDC1_SDHCI_BASE;
	mmc_host.voltages = MMC_VDD_165_195;
	mmc_host.version = SDHCI_SPEC_300;
	mmc_host.cfg.part_type = PART_TYPE_EFI;
	mmc_host.quirks = SDHCI_QUIRK_BROKEN_VOLTAGE;

	emmc_clock_disable();
	emmc_clock_reset();
	udelay(10);
	emmc_clock_config(MMC_DATA_TRANSFER_SDHCI_MODE);
	emmc_sdhci_init();

	if (add_sdhci(&mmc_host, 200000000, 400000)) {
		printf("add_sdhci fail!\n");
		return -1;
	}
#endif

	if (!ret && sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
		ret = board_mmc_env_init(mmc_host);
	}

	return ret;
}


void board_nand_init(void)
{
#ifdef CONFIG_QCA_SPI
	int gpio_node;
	int i;
#endif

	qpic_nand_init(&gboard_param.qpic_nand_cfg);

#ifdef CONFIG_QCA_SPI
	gpio_node = fdt_path_offset(gd->fdt_blob, "/spi/spi_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
		spi_clock_init(0);
	} else {
		/* Setting default values */
		for (i = 0; i < gboard_param.spi_nor_cfg.gpio_count; i++)
			gpio_tlmm_config(&gboard_param.spi_nor_cfg.gpio[i]);
	}

	ipq_spi_init(CONFIG_IPQ_SPI_NOR_INFO_IDX);

#endif
}

#ifdef CONFIG_PCI_IPQ
static void pcie_clock_init(int id)
{

	/* Enable PCIE CLKS */
	if (id == 0) {
		writel(0x2, GCC_PCIE0_AUX_CMD_RCGR);
		writel(0x107, GCC_PCIE0_AXI_CFG_RCGR);
		writel(0x1, GCC_PCIE0_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x2, GCC_PCIE0_AXI_CMD_RCGR);
		writel(0x20000001, GCC_PCIE0_AHB_CBCR);
		writel(0x4FF1, GCC_PCIE0_AXI_M_CBCR);
		writel(0x20004FF1, GCC_PCIE0_AXI_S_CBCR);
		writel(0x1, GCC_PCIE0_AUX_CBCR);
		writel(0x80004FF1, GCC_PCIE0_PIPE_CBCR);
		writel(0x2, GCC_PCIE1_AUX_CMD_RCGR);
		writel(0x107, GCC_PCIE1_AXI_CFG_RCGR);
		writel(0x1, GCC_PCIE1_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x2, GCC_PCIE1_AXI_CMD_RCGR);
		writel(0x20000001, GCC_PCIE1_AHB_CBCR);
		writel(0x4FF1, GCC_PCIE1_AXI_M_CBCR);
		writel(0x20004FF1, GCC_PCIE1_AXI_S_CBCR);
		writel(0x1, GCC_PCIE1_AUX_CBCR);
		writel(0x80004FF1, GCC_PCIE1_PIPE_CBCR);
		pci_initialised = 1;
	}
}

static void pcie_v2_clock_init(int id)
{

	/* Enable PCIE CLKS */
	if (id == 0) {
		writel(0x2, GCC_PCIE0_V2_AUX_CMD_RCGR);
		writel(0x107, GCC_PCIE0_AXI_CFG_RCGR);
		writel(0x1, GCC_PCIE0_V2_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x2, GCC_PCIE0_V2_AXI_CMD_RCGR);
		writel(0x20000001, GCC_PCIE0_AHB_CBCR);
		writel(0x4FF1, GCC_PCIE0_AXI_M_CBCR);
		writel(0x20004FF1, GCC_PCIE0_AXI_S_CBCR);
		writel(0x1, GCC_PCIE0_AUX_CBCR);
		writel(0x80004FF1, GCC_PCIE0_PIPE_CBCR);
		writel(0x1, GCC_PCIE0_AXI_S_BRIDGE_CBCR);
		writel(0x10F, GCC_PCIE0_RCHNG_CFG_RCGR);
		writel(0x3, GCC_PCIE0_RCHNG_CMD_RCGR);

		writel(0x2, GCC_PCIE1_V2_AUX_CMD_RCGR);
		writel(0x107, GCC_PCIE1_AXI_CFG_RCGR);
		writel(0x1, GCC_PCIE1_V2_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x2, GCC_PCIE1_V2_AXI_CMD_RCGR);
		writel(0x20000001, GCC_PCIE1_AHB_CBCR);
		writel(0x4FF1, GCC_PCIE1_AXI_M_CBCR);
		writel(0x20004FF1, GCC_PCIE1_AXI_S_CBCR);
		writel(0x1, GCC_PCIE1_AUX_CBCR);
		writel(0x80004FF1, GCC_PCIE1_PIPE_CBCR);
	}
}

static void pcie_v2_clock_deinit(int id)
{

	if (id == 0) {
		writel(0x0, GCC_PCIE0_AUX_CMD_RCGR);
		writel(0x0, GCC_PCIE0_AXI_CFG_RCGR);
		writel(0x0, GCC_PCIE0_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x0, GCC_SYS_NOC_PCIE0_AXI_CLK);
		writel(0x0, GCC_PCIE0_AHB_CBCR);
		writel(0x0, GCC_PCIE0_AXI_M_CBCR);
		writel(0x0, GCC_PCIE0_AXI_S_CBCR);
		writel(0x0, GCC_PCIE0_AUX_CBCR);
		writel(0x0, GCC_PCIE0_PIPE_CBCR);
		writel(0x0, GCC_PCIE0_AXI_S_BRIDGE_CBCR);
		writel(0x0, GCC_PCIE0_RCHNG_CFG_RCGR);
		writel(0x0, GCC_PCIE0_RCHNG_CMD_RCGR);
		writel(0x0, GCC_PCIE1_V2_AUX_CMD_RCGR);
		writel(0x0, GCC_PCIE1_AXI_CFG_RCGR);
		writel(0x0, GCC_PCIE1_V2_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x0, GCC_SYS_NOC_PCIE1_AXI_CLK);
		writel(0x0, GCC_PCIE1_AHB_CBCR);
		writel(0x0, GCC_PCIE1_AXI_M_CBCR);
		writel(0x0, GCC_PCIE1_AXI_S_CBCR);
		writel(0x0, GCC_PCIE1_AUX_CBCR);
		writel(0x0, GCC_PCIE1_PIPE_CBCR);
	}
}

static void pcie_clock_deinit(int id)
{

	if (id == 0) {
		writel(0x0, GCC_PCIE0_V2_AUX_CMD_RCGR);
		writel(0x0, GCC_PCIE0_V2_AXI_CMD_RCGR);
		writel(0x0, GCC_PCIE0_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x0, GCC_SYS_NOC_PCIE0_AXI_CLK);
		writel(0x0, GCC_PCIE0_AHB_CBCR);
		writel(0x0, GCC_PCIE0_AXI_M_CBCR);
		writel(0x0, GCC_PCIE0_AXI_S_CBCR);
		writel(0x0, GCC_PCIE0_AUX_CBCR);
		writel(0x0, GCC_PCIE0_PIPE_CBCR);
		writel(0x0, GCC_PCIE1_AUX_CMD_RCGR);
		writel(0x0, GCC_PCIE1_AXI_CFG_RCGR);
		writel(0x0, GCC_PCIE1_AXI_CMD_RCGR);
		mdelay(100);
		writel(0x0, GCC_SYS_NOC_PCIE1_AXI_CLK);
		writel(0x0, GCC_PCIE1_AHB_CBCR);
		writel(0x0, GCC_PCIE1_AXI_M_CBCR);
		writel(0x0, GCC_PCIE1_AXI_S_CBCR);
		writel(0x0, GCC_PCIE1_AUX_CBCR);
		writel(0x0, GCC_PCIE1_PIPE_CBCR);
	}
}

void board_pci_init(int id)
{
	int node, gpio_node;
	char name[16];
	uint32_t soc_ver_major, soc_ver_minor;

	snprintf(name, sizeof(name), "pci%d", id);
	node = fdt_path_offset(gd->fdt_blob, name);
	if (node < 0) {
		printf("Could not find PCI in device tree\n");
		return;
	}
	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
	get_soc_version(&soc_ver_major, &soc_ver_minor);
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);
	if(soc_ver_major == 2)
		pcie_v2_clock_init(id);
	else
		pcie_clock_init(id);

	return;
}

void board_pci_deinit()
{
	int node, gpio_node, i, err;
	char name[16];
	struct fdt_resource parf;
	struct fdt_resource pci_phy;
	uint32_t soc_ver_major, soc_ver_minor;

	get_soc_version(&soc_ver_major, &soc_ver_minor);
	for (i = 0; i < PCI_MAX_DEVICES; i++) {
		snprintf(name, sizeof(name), "pci%d", i);
		node = fdt_path_offset(gd->fdt_blob, name);
		if (node < 0) {
			printf("Could not find PCI in device tree\n");
			return;
		}
		err = fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "parf",
				&parf);
		writel(0x0, parf.start + 0x358);
		writel(0x1, parf.start + 0x40);
		err = fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "pci_phy",
				     &pci_phy);
		if (err < 0) {

			if(soc_ver_major == 1) {
				err = fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "pci_phy_gen2",
					     &pci_phy);
				if (err < 0)
					return;
			} else if(soc_ver_major == 2) {
				err = fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "pci_phy_gen3",
					     &pci_phy);
				if (err < 0)
					return;
			} else {
				return;
			}
		}
		writel(0x1, pci_phy.start + 800);
		writel(0x0, pci_phy.start + 804);
		gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
		if (gpio_node >= 0)
			qca_gpio_deinit(gpio_node);

	}

	if (soc_ver_major == 2)
		pcie_v2_clock_deinit(0);
	else
		pcie_clock_deinit(0);

	return ;
}
#endif

#ifdef CONFIG_IPQ_FDT_FIXUP
int sdx65_attached(void)
{
	const char *sdx65_env = getenv("x65_attached");
	int sdx65_available = 0;

	if (sdx65_env != NULL && strncmp(sdx65_env, "1", sizeof("1")) == 0) {
		printf("sdx65_attached env is set to 1\n");
		sdx65_available = 1;
		return sdx65_available;
	}

	return sdx65_available;
}

void fdt_fixup_sdx65_gpio(void *blob)
{
	unsigned int machid = gd->bd->bi_arch_number;
	int offset, len;
	u32 *data;

	if (machid != 0x08010400)
		return;

	if (sdx65_attached() == 0)
		return;

	parse_fdt_fixup("/soc/pci@20000000/%add%x65_attached", blob);
	parse_fdt_fixup("/soc/pci@20000000/%x65_attached%1", blob);

	offset = fdt_path_offset(blob, "/soc/pci@20000000/pcie0_rp/qcom,mhi@0");
	if(offset >= 0) {
		data = (u32 *)fdt_getprop(blob, offset, "mdm2ap", &len);
		if (data) {
			parse_fdt_fixup("/soc/pci@20000000/pcie0_rp/qcom,mhi@0/%mdm2ap%21", blob);
		} else {
			data = (u32 *)fdt_getprop(blob, offset, "mdm2ap-gpio", &len);
			if (data) {
				data[1] = cpu_to_fdt32(21);
				fdt_setprop_inplace(blob, offset, "mdm2ap-gpio", data, len);
			}
		}

		data = (u32 *)fdt_getprop(blob, offset, "ap2mdm", &len);
		if (data) {
			parse_fdt_fixup("/soc/pci@20000000/pcie0_rp/qcom,mhi@0/%ap2mdm%45", blob);
		} else {
			data = (u32 *)fdt_getprop(blob, offset, "ap2mdm-gpio", &len);
			if (data) {
				data[1] = cpu_to_fdt32(45);
				fdt_setprop_inplace(blob, offset, "ap2mdm-gpio", data, len);
			}
		}
	}

	if (fdt_path_offset(blob, "/soc/pinctrl@1000000/ap2mdm_status") >= 0)
		parse_fdt_fixup("/soc/pinctrl@1000000/ap2mdm_status/%pins%?gpio45", blob);
	else if (fdt_path_offset(blob, "/soc/pinctrl@1000000/pcie_sdx_pinmux/ap2mdm_status") >= 0)
		parse_fdt_fixup("/soc/pinctrl@1000000/pcie_sdx_pinmux/ap2mdm_status/%pins%?gpio45", blob);

	if (fdt_path_offset(blob, "/soc/pinctrl@1000000/mdm2ap_e911_status/") >= 0)
		parse_fdt_fixup("/soc/pinctrl@1000000/mdm2ap_e911_status/%pins%?gpio22", blob);
	else if (fdt_path_offset(blob, "/soc/pinctrl@1000000/pcie_sdx_pinmux/mdm2ap_e911_status") >= 0)
		parse_fdt_fixup("/soc/pinctrl@1000000/pcie_sdx_pinmux/mdm2ap_e911_status/%pins%?gpio22", blob);
}
#endif

#ifdef CONFIG_USB_XHCI_IPQ
void board_usb_deinit(int id)
{
	void __iomem *usb_phy_bcr, *usb_bcr, *qusb2_phy_bcr, *phy_base;

	if (id == 0) {
		usb_bcr = (u32 *)GCC_USB0_BCR;
		qusb2_phy_bcr = (u32 *)GCC_QUSB2_0_PHY_BCR;
		usb_phy_bcr = (u32 *)GCC_USB0_PHY_BCR;
		phy_base = (u32 *)USB30_PHY_1_QUSB2PHY_BASE;
	}
	else if (id == 1) {
		usb_bcr = (u32 *)GCC_USB1_BCR;
		qusb2_phy_bcr = (u32 *)GCC_QUSB2_1_PHY_BCR;
		usb_phy_bcr = (u32 *)GCC_USB1_PHY_BCR;
		phy_base = (u32 *)USB30_PHY_2_QUSB2PHY_BASE;
	}
	else {
		return;
	}
	//Enable USB2 PHY Power down
	setbits_le32(phy_base+0xB4, 0x1);

	if (id == 0) {
		writel(0x8000, GCC_USB0_PHY_CFG_AHB_CBCR);
		writel(0xcff0, GCC_USB0_MASTER_CBCR);
		writel(0, GCC_SYS_NOC_USB0_AXI_CBCR);
		writel(0, GCC_SNOC_BUS_TIMEOUT2_AHB_CBCR);
		writel(0, GCC_USB0_SLEEP_CBCR);
		writel(0, GCC_USB0_MOCK_UTMI_CBCR);
		writel(0, GCC_USB0_AUX_CBCR);
	}
	else if (id == 1) {
		writel(0x8000, GCC_USB1_PHY_CFG_AHB_CBCR);
		writel(0xcff0, GCC_USB1_MASTER_CBCR);
		writel(0, GCC_SYS_NOC_USB1_AXI_CBCR);
		writel(0, GCC_SNOC_BUS_TIMEOUT3_AHB_CBCR);
		writel(0, GCC_USB1_SLEEP_CBCR);
		writel(0, GCC_USB1_MOCK_UTMI_CBCR);
		writel(0, GCC_USB1_AUX_CBCR);
	}

	//GCC_QUSB2_0_PHY_BCR
	setbits_le32(qusb2_phy_bcr, 0x1);
	mdelay(10);
	clrbits_le32(qusb2_phy_bcr, 0x1);

	//GCC_USB0_PHY_BCR
	setbits_le32(usb_phy_bcr, 0x1);
	mdelay(10);
	clrbits_le32(usb_phy_bcr, 0x1);

	//GCC Reset USB0 BCR
	setbits_le32(usb_bcr, 0x1);
	mdelay(10);
	clrbits_le32(usb_bcr, 0x1);
}

static void usb_clock_init(int id)
{
	if (id == 0) {
		writel(0x222000, GCC_USB0_GDSCR);
		writel(0, GCC_SYS_NOC_USB0_AXI_CBCR);
		writel(0, GCC_SNOC_BUS_TIMEOUT2_AHB_CBCR);
		writel(0x10b, GCC_USB0_MASTER_CFG_RCGR);
		writel(0x1, GCC_USB0_MASTER_CMD_RCGR);
		writel(1, GCC_SYS_NOC_USB0_AXI_CBCR);
		writel(0xcff1, GCC_USB0_MASTER_CBCR);
		writel(1, GCC_SNOC_BUS_TIMEOUT2_AHB_CBCR);
		writel(1, GCC_USB0_SLEEP_CBCR);
		writel(0x210b, GCC_USB0_MOCK_UTMI_CFG_RCGR);
		writel(0x1, GCC_USB0_MOCK_UTMI_M);
		writel(0xf7, GCC_USB0_MOCK_UTMI_N);
		writel(0xf6, GCC_USB0_MOCK_UTMI_D);
		writel(0x3, GCC_USB0_MOCK_UTMI_CMD_RCGR);
		writel(1, GCC_USB0_MOCK_UTMI_CBCR);
		writel(0x8001, GCC_USB0_PHY_CFG_AHB_CBCR);
		writel(1, GCC_USB0_AUX_CBCR);
		writel(1, GCC_USB0_PIPE_CBCR);
	}
	else if (id == 1) {
		writel(0x222000, GCC_USB1_GDSCR);
		writel(0, GCC_SYS_NOC_USB1_AXI_CBCR);
		writel(0, GCC_SNOC_BUS_TIMEOUT3_AHB_CBCR);
		writel(0x10b, GCC_USB1_MASTER_CFG_RCGR);
		writel(0x1, GCC_USB1_MASTER_CMD_RCGR);
		writel(1, GCC_SYS_NOC_USB1_AXI_CBCR);
		writel(0xcff1, GCC_USB1_MASTER_CBCR);
		writel(1, GCC_SNOC_BUS_TIMEOUT3_AHB_CBCR);
		writel(1, GCC_USB1_SLEEP_CBCR);
		writel(0x210b, GCC_USB1_MOCK_UTMI_CFG_RCGR);
		writel(0x1, GCC_USB1_MOCK_UTMI_M);
		writel(0xf7, GCC_USB1_MOCK_UTMI_N);
		writel(0xf6, GCC_USB1_MOCK_UTMI_D);
		writel(0x3, GCC_USB1_MOCK_UTMI_CMD_RCGR);
		writel(1, GCC_USB1_MOCK_UTMI_CBCR);
		writel(0x8001, GCC_USB1_PHY_CFG_AHB_CBCR);
		writel(1, GCC_USB1_AUX_CBCR);
		writel(1, GCC_USB1_PIPE_CBCR);
	}
}

static void usb_init_ssphy(int index)
{
	void __iomem *phybase;

	if (index == 0) {
		phybase = (u32 *)USB0_SSPHY_BASE;
	}
	else if (index == 1) {
		phybase = (u32 *)USB1_SSPHY_BASE;
	} else
		return;

	out_8( phybase + USB3_PHY_POWER_DOWN_CONTROL,0x1);
	out_8(phybase + QSERDES_COM_SYSCLK_EN_SEL,0x1a);
	out_8(phybase + QSERDES_COM_BIAS_EN_CLKBUFLR_EN,0x08);
	out_8(phybase + QSERDES_COM_CLK_SELECT,0x30);
	out_8(phybase + QSERDES_COM_BG_TRIM,0x0f);
	out_8(phybase + QSERDES_RX_UCDR_FASTLOCK_FO_GAIN,0x0b);
	out_8(phybase + QSERDES_COM_SVS_MODE_CLK_SEL,0x01);
	out_8(phybase + QSERDES_COM_HSCLK_SEL,0x00);
	out_8(phybase + QSERDES_COM_CMN_CONFIG,0x06);
	out_8(phybase + QSERDES_COM_PLL_IVCO,0x0f);
	out_8(phybase + QSERDES_COM_SYS_CLK_CTRL,0x06);
	out_8(phybase + QSERDES_COM_DEC_START_MODE0,0x82);
	out_8(phybase + QSERDES_COM_DIV_FRAC_START1_MODE0,0x55);
	out_8(phybase + QSERDES_COM_DIV_FRAC_START2_MODE0,0x55);
	out_8(phybase + QSERDES_COM_DIV_FRAC_START3_MODE0,0x03);
	out_8(phybase + QSERDES_COM_CP_CTRL_MODE0,0x0b);
	out_8(phybase + QSERDES_COM_PLL_RCTRL_MODE0,0x16);
	out_8(phybase + QSERDES_COM_PLL_CCTRL_MODE0,0x28);
	out_8(phybase + QSERDES_COM_INTEGLOOP_GAIN0_MODE0,0x80);
	out_8(phybase + QSERDES_COM_LOCK_CMP1_MODE0,0x15);
	out_8(phybase + QSERDES_COM_LOCK_CMP2_MODE0,0x34);
	out_8(phybase + QSERDES_COM_LOCK_CMP3_MODE0,0x00);
	out_8(phybase + QSERDES_COM_CORE_CLK_EN,0x00);
	out_8(phybase + QSERDES_COM_LOCK_CMP_CFG,0x00);
	out_8(phybase + QSERDES_COM_VCO_TUNE_MAP,0x00);
	out_8(phybase + QSERDES_COM_BG_TIMER,0x0a);
	out_8(phybase + QSERDES_COM_SSC_EN_CENTER,0x01);
	out_8(phybase + QSERDES_COM_SSC_PER1,0x31);
	out_8(phybase + QSERDES_COM_SSC_PER2,0x01);
	out_8(phybase + QSERDES_COM_SSC_ADJ_PER1,0x00);
	out_8(phybase + QSERDES_COM_SSC_ADJ_PER2,0x00);
	out_8(phybase + QSERDES_COM_SSC_STEP_SIZE1,0xde);
	out_8(phybase + QSERDES_COM_SSC_STEP_SIZE2,0x07);
	out_8(phybase + QSERDES_RX_UCDR_SO_GAIN,0x06);
	out_8(phybase + QSERDES_RX_RX_EQU_ADAPTOR_CNTRL2,0x02);
	out_8(phybase + QSERDES_RX_RX_EQU_ADAPTOR_CNTRL3,0x6c);
	out_8(phybase + QSERDES_RX_RX_EQU_ADAPTOR_CNTRL3,0x4c);
	out_8(phybase + QSERDES_RX_RX_EQU_ADAPTOR_CNTRL4,0xb8);
	out_8(phybase + QSERDES_RX_RX_EQ_OFFSET_ADAPTOR_CNTRL,0x77);
	out_8(phybase + QSERDES_RX_RX_OFFSET_ADAPTOR_CNTRL2,0x80);
	out_8(phybase + QSERDES_RX_SIGDET_CNTRL,0x03);
	out_8(phybase + QSERDES_RX_SIGDET_DEGLITCH_CNTRL,0x16);
	out_8(phybase + QSERDES_RX_SIGDET_ENABLES,0x0c);
	out_8(phybase + QSERDES_TX_HIGHZ_TRANSCEIVEREN_BIAS_D,0x45);
	out_8(phybase + QSERDES_TX_RCV_DETECT_LVL_2,0x12);
	out_8(phybase + QSERDES_TX_LANE_MODE,0x06);
	out_8(phybase + PCS_TXDEEMPH_M6DB_V0,0x15);
	out_8(phybase + PCS_TXDEEMPH_M3P5DB_V0,0x0e);
	out_8(phybase + PCS_FLL_CNTRL2,0x83);
	out_8(phybase + PCS_FLL_CNTRL1,0x02);
	out_8(phybase + PCS_FLL_CNT_VAL_L,0x09);
	out_8(phybase + PCS_FLL_CNT_VAL_H_TOL,0xa2);
	out_8(phybase + PCS_FLL_MAN_CODE,0x85);
	out_8(phybase + PCS_LOCK_DETECT_CONFIG1,0xd1);
	out_8(phybase + PCS_LOCK_DETECT_CONFIG2,0x1f);
	out_8(phybase + PCS_LOCK_DETECT_CONFIG3,0x47);
	out_8(phybase + PCS_POWER_STATE_CONFIG2,0x1b);
	out_8(phybase + PCS_RXEQTRAINING_WAIT_TIME,0x75);
	out_8(phybase + PCS_RXEQTRAINING_RUN_TIME,0x13);
	out_8(phybase + PCS_LFPS_TX_ECSTART_EQTLOCK,0x86);
	out_8(phybase + PCS_PWRUP_RESET_DLY_TIME_AUXCLK,0x04);
	out_8(phybase + PCS_TSYNC_RSYNC_TIME,0x44);
	out_8(phybase + PCS_RCVR_DTCT_DLY_P1U2_L,0xe7);
	out_8(phybase + PCS_RCVR_DTCT_DLY_P1U2_H,0x03);
	out_8(phybase + PCS_RCVR_DTCT_DLY_U3_L,0x40);
	out_8(phybase + PCS_RCVR_DTCT_DLY_U3_H,0x00);
	out_8(phybase + PCS_RX_SIGDET_LVL,0x88);
	out_8(phybase + USB3_PCS_TXDEEMPH_M6DB_V0,0x17);
	out_8(phybase + USB3_PCS_TXDEEMPH_M3P5DB_V0,0x0f);
	out_8(phybase + QSERDES_RX_SIGDET_ENABLES,0x0);
	out_8(phybase + USB3_PHY_START_CONTROL,0x03);
	out_8(phybase + USB3_PHY_SW_RESET,0x00);
}

static void usb_init_phy(int index)
{
	void __iomem *boot_clk_ctl, *usb_bcr, *qusb2_phy_bcr;
	void __iomem *usb_phy_bcr, *usb3_phy_bcr, *usb_guctl, *phy_base;

	if (index == 0) {
		boot_clk_ctl = (u32 *)GCC_USB_0_BOOT_CLOCK_CTL;
		usb_bcr = (u32 *)GCC_USB0_BCR;
		qusb2_phy_bcr = (u32 *)GCC_QUSB2_0_PHY_BCR;
		usb_phy_bcr = (u32 *)GCC_USB0_PHY_BCR;
		usb3_phy_bcr = (u32 *)GCC_USB3PHY_0_PHY_BCR;
		usb_guctl = (u32 *)USB30_1_GUCTL;
		phy_base = (u32 *)USB30_PHY_1_QUSB2PHY_BASE;
	}
	else if (index == 1) {
		boot_clk_ctl = (u32 *)GCC_USB_1_BOOT_CLOCK_CTL;
		usb_bcr = (u32 *)GCC_USB1_BCR;
		qusb2_phy_bcr = (u32 *)GCC_QUSB2_1_PHY_BCR;
		usb_phy_bcr = (u32 *)GCC_USB1_PHY_BCR;
		usb3_phy_bcr = (u32 *)GCC_USB3PHY_1_PHY_BCR;
		usb_guctl = (u32 *)USB30_2_GUCTL;
		phy_base = (u32 *)USB30_PHY_2_QUSB2PHY_BASE;
	}
	else {
		return;
	}
	//2. Enable SS Ref Clock
	setbits_le32(GCC_USB_SS_REF_CLK_EN, 0x1);

	//3. Disable USB Boot Clock
	clrbits_le32(boot_clk_ctl, 0x0);

	//4. GCC Reset USB0 BCR
	setbits_le32(usb_bcr, 0x1);

	//5. Delay 100us
	mdelay(10);

	//6. GCC Reset USB0 BCR
	clrbits_le32(usb_bcr, 0x1);
	//7. GCC_QUSB2_0_PHY_BCR
	setbits_le32(qusb2_phy_bcr, 0x1);

	//8. GCC_USB0_PHY_BCR
	setbits_le32(usb_phy_bcr, 0x1);
	setbits_le32(usb3_phy_bcr, 0x1);

	//9. Delay 100us
	mdelay(10);

	//10. GCC_USB0_PHY_BCR
	clrbits_le32(usb3_phy_bcr, 0x1);
	clrbits_le32(usb_phy_bcr, 0x1);

	//11. GCC_QUSB2_0_PHY_BCR
	clrbits_le32(qusb2_phy_bcr, 0x1);

	//12. Delay 100us
	mdelay(10);

	//20. Config user control register
	writel(0x0c80c010, usb_guctl);

	//21. Enable USB2 PHY Power down
	setbits_le32(phy_base+0xB4, 0x1);

	//22. PHY Config Sequence
	out_8(phy_base+0x80, 0xF8);
	out_8(phy_base+0x84, 0x83);
	out_8(phy_base+0x88, 0x83);
	out_8(phy_base+0x8C, 0xC0);
	out_8(phy_base+0x9C, 0x14);
	out_8(phy_base+0x08, 0x30);
	out_8(phy_base+0x0C, 0x79);
	out_8(phy_base+0x10, 0x21);
	out_8(phy_base+0x90, 0x00);
	out_8(phy_base+0x18, 0x00);
	out_8(phy_base+0x1C, 0x9F);
	out_8(phy_base+0x04, 0x80);

	//23. Disable USB2 PHY Power down
	clrbits_le32(phy_base+0xB4, 0x1);

	usb_init_ssphy(index);
}

int ipq_board_usb_init(void)
{
	int i;

	for (i=0; i<CONFIG_USB_MAX_CONTROLLER_COUNT; i++) {
		usb_clock_init(i);
		usb_init_phy(i);
	}
	return 0;
}
#endif

unsigned int get_dts_machid(unsigned int machid)
{
	switch (machid)
	{
		case MACH_TYPE_IPQ807x_AP_HK01_C3:
		case MACH_TYPE_IPQ807x_AP_HK01_C6:
		case MACH_TYPE_IPQ807x_AP_OAK03:
			return MACH_TYPE_IPQ807x_AP_HK01_C1;
		case MACH_TYPE_IPQ807x_AP_AC02:
			return MACH_TYPE_IPQ807x_AP_AC01;
		case MACH_TYPE_IPQ807x_AP_HK12_C1:
			return MACH_TYPE_IPQ807x_AP_HK10_C2;
		default:
			return machid;
	}
}

void ipq_uboot_fdt_fixup(void)
{
	init_config_list();
	switch (gd->bd->bi_arch_number)
	{
		case MACH_TYPE_IPQ807x_AP_HK01_C3:
			add_config_entry("config@hk01.c3");
			add_config_entry("config-hk01.c3");
			break;
		case MACH_TYPE_IPQ807x_AP_HK01_C6:
			add_config_entry("config@hk01.c6");
			add_config_entry("config-hk01.c6");
			break;
		case MACH_TYPE_IPQ807x_AP_HK12_C1:
			add_config_entry("config@hk12");
			add_config_entry("config-hk12");
			break;
		case MACH_TYPE_IPQ807x_AP_AC02:
			add_config_entry("config@ac02");
			add_config_entry("config-ac02");
			break;
		case MACH_TYPE_IPQ807x_AP_OAK03:
			add_config_entry("config@oak03");
			add_config_entry("config-oak03");
			break;
		default:
			add_config_list_from_fdt();
	}
	return;
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void ipq_fdt_fixup_usb_device_mode(void *blob)
{
	int nodeoff, ret, node;
	const char *usb_dr_mode = "peripheral"; /* Supported mode */
	const char *usb_max_speed = "high-speed";/* Supported speed */
	const char *usb_node[] = {"/soc/usb3@8A00000/dwc3@8A00000"};
	const char *usb_cfg;

	usb_cfg = getenv("usb_mode");
	if (!usb_cfg)
		return;

	if (strcmp(usb_cfg, usb_dr_mode)) {
		printf("fixup_usb: usb_mode can be either 'peripheral' or not set\n");
		return;
	}

	for (node = 0; node < ARRAY_SIZE(usb_node); node++) {
		nodeoff = fdt_path_offset(blob, usb_node[node]);
		if (nodeoff < 0) {
			printf("fixup_usb: unable to find node '%s'\n",
			       usb_node[node]);
			return;
		}
		ret = fdt_setprop(blob, nodeoff, "dr_mode",
				  usb_dr_mode,
				  (strlen(usb_dr_mode) + 1));
		if (ret)
			printf("fixup_usb: 'dr_mode' cannot be set");

		/* if mode is peripheral restricting to high-speed */
		ret = fdt_setprop(blob, nodeoff, "maximum-speed",
				  usb_max_speed,
				  (strlen(usb_max_speed) + 1));
		if (ret)
			printf("fixup_usb: 'maximum-speed' cannot be set");
	}
}

void fdt_fixup_auto_restart(void *blob)
{
	int nodeoff, ret;
	const char *node = "/soc/q6v5_wcss@CD00000";
	const char *paniconwcssfatal;

	paniconwcssfatal = getenv("paniconwcssfatal");

	if (!paniconwcssfatal)
		return;

	if (strncmp(paniconwcssfatal, "1", sizeof("1"))) {
		printf("fixup_auto_restart: invalid variable 'paniconwcssfatal'");
	} else {
		nodeoff = fdt_path_offset(blob, node);
		if (nodeoff < 0) {
			printf("fixup_auto_restart: unable to find node '%s'\n", node);
			return;
		}
		ret = fdt_delprop(blob, nodeoff, "qca,auto-restart");

		if (ret)
			printf("fixup_auto_restart: cannot delete property");
	}
	return;
}
#endif

#define TCSR_CPR	0x0193d008 /* TCSR_TZ_WONCE_2 */
#define BM(lsb, msb)            ((BIT(msb) - BIT(lsb)) + BIT(msb))

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_cpr(void *blob)
{
	int node, subnode, phandle;
	int i, ret;
	uint64_t opp_hz[] = {1017600000, 1382400000, 1651200000,
			     1843200000, 1920000000, 2208000000};
	uint32_t opp_microvolt[] = {840000, 904000, 944000,
				    984000, 992000, 1064000};

	char *compatible[] = {"qcom,cpr4-ipq807x-apss-regulator",
			      "qcom,cpr3-ipq807x-npu-regulator",
			      "qcom,ipq807x-apm"};

	uint32_t tcsr_cpr = readl(TCSR_CPR);

	tcsr_cpr = (tcsr_cpr >> 8) & BM(0, 1);

	if (tcsr_cpr != 1)
		return;

	node = fdt_path_offset(blob,
				"/soc/qcom,spmi@200f000/pmic@1/regulators/s3");
	if (node < 0)
		return;

	phandle = fdt_get_phandle(blob, node);
	if (phandle <= 0)
		return;

	/* Set cpu-supply for all 4 cores */
	node = fdt_path_offset(blob, "/cpus");
	if (node < 0)
		return;

	subnode = fdt_first_subnode(blob, node);
	if (subnode < 0)
		return;

	ret = fdt_setprop_cell(blob, subnode, "cpu0-supply", phandle);
	if (ret)
		return;

	for (i = 1; i <= 3; i++) {
		subnode = fdt_next_subnode(blob, subnode);
		if (subnode < 0)
			return;

		ret = fdt_setprop_cell(blob, subnode, "cpu-supply", phandle);
		if (ret)
			return;
	}

	/* Set operating point */
	node = fdt_path_offset(blob, "/cpus/opp_table0");
	if (node < 0)
		return;

	subnode = fdt_first_subnode(blob, node);
	if (subnode < 0)
		return;

	ret = fdt_setprop_cell(blob, subnode,
			       "opp-microvolt", opp_microvolt[0]);
	if (ret)
		return;

	ret = fdt_setprop_u64(blob, subnode, "opp-hz", opp_hz[0]);
	if (ret)
		return;

	for (i = 1; i < ARRAY_SIZE(opp_microvolt); i++) {
		subnode = fdt_next_subnode(blob, subnode);
		if (subnode < 0)
			return;

		ret = fdt_setprop_cell(blob, subnode,
				       "opp-microvolt", opp_microvolt[i]);
		if (ret)
			return;

		ret = fdt_setprop_u64(blob, subnode, "opp-hz", opp_hz[i]);
		if (ret)
			return;
	}

	/* Delete opp06 subnode */
	subnode = fdt_next_subnode(blob, subnode);
	if (subnode < 0)
		return;

	ret = fdt_del_node(blob, subnode);
	if (ret)
		return;

	node = fdt_path_offset(blob,
				"/soc/qcom,spmi@200f000/pmic@1/regulators/s4");
	if (node < 0)
		return;

	phandle = fdt_get_phandle(blob, node);
	if (phandle <= 0)
		return;

	/* Delete npu-supply and mx-supply */
	node = fdt_path_offset(blob, "/soc/nss@40000000");
	if (node < 0)
		return;

	ret = fdt_delprop(blob, node, "npu-supply");
	if (node < 0)
		return;

	ret = fdt_delprop(blob, node, "mx-supply");
	if (node < 0)
		return;

	/* Disable cpr, apu */
	for (i = 0; i < ARRAY_SIZE(compatible); i++) {
		node = fdt_node_offset_by_compatible(blob, 0, compatible[i]);
		if (node < 0)
			return;
		ret = fdt_setprop_string(blob, node, "status", "disabled");
	}

	return;
}

void fdt_low_memory_fixup(void *blob)
{
	int node;
	int len;
	u64 *reg;
	char *wcnss_node = "/reserved-memory/wcnss@4b000000";
	char *wifi_dump_node = "/reserved-memory/wifi_dump@50500000";
	char *tzapp_node = "/reserved-memory/tzapp@4a400000";
	unsigned int wcnss_size = 0x03700000;
	unsigned int wifi_dump_size = 0x200000;
	char *mem_mode = getenv("low_mem_mode");
	int ret;

	if (!mem_mode)
		return;

	printf("Configuring kernel for low memory mode...\n");

	node = fdt_path_offset(blob, wcnss_node);
	if (node >= 0) {
		reg = (u64 *)fdt_getprop(blob, node, "reg", &len);
		if (reg != NULL)
			reg[1] = cpu_to_fdt64(wcnss_size);
	} else {
		printf("Node \"%s\" not found\n", wcnss_node);
	}

	node = fdt_path_offset(blob, wifi_dump_node);
	if (node >= 0) {
		reg = (u64 *)fdt_getprop(blob, node, "reg", &len);
		if (reg != NULL)
			reg[1] = cpu_to_fdt64(wifi_dump_size);
	} else {
		printf("Node \"%s\" not found\n", wifi_dump_node);
	}

	node = fdt_path_offset(blob, tzapp_node);
	if (node >= 0) {
		ret = fdt_del_node(blob, node);
		if (ret)
			printf("Cannot delete \"%s\" node\n", tzapp_node);

	} else {
		printf("Node \"%s\" not found\n", tzapp_node);
	}
}

void fdt_fixup_set_dload_warm_reset(void *blob)
{
	int nodeoff, ret;
	uint32_t setval = 1;

	nodeoff = fdt_path_offset(blob, "/soc/qca,scm_restart_reason");
	if (nodeoff < 0) {
		nodeoff = fdt_path_offset(blob, "/qti,scm_restart_reason");
		if (nodeoff < 0) {
			printf("fixup_set_dload: unable to find scm_restart_reason node\n");
			return;
		}
	}

	ret = fdt_setprop_u32(blob, nodeoff, "dload_status", setval);
	if (ret)
		printf("fixup_set_dload: 'dload_status' not set");

	ret = fdt_setprop_u32(blob, nodeoff, "dload_warm_reset", setval);
	if (ret)
		printf("fixup_set_dload: 'dload_warm_reset' not set");
}

void fdt_fixup_set_qce_fixed_key(void *blob)
{
	int node_off, ret;
	const char *qce_node = {"/soc/crypto@8e3a000"};

	node_off = fdt_path_offset(blob, qce_node);
	if (node_off < 0) {
		printf("qce_crypto: unable to find node '%s'\n",
				qce_node);
		return;
	}

	ret = fdt_setprop_u32(blob, node_off, "qce,use_fixed_hw_key", 1);
	if (ret)
		printf("qce_crypto: 'qce,use_fixed_hw_key' property no set");

}
#endif

void set_flash_secondary_type(qca_smem_flash_info_t *smem)
{
	return;
};

void enable_caches(void)
{
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	smem_get_boot_flash(&sfi->flash_type,
			    &sfi->flash_index,
			    &sfi->flash_chip_select,
			    &sfi->flash_block_size,
			    &sfi->flash_density);
	icache_enable();
	/*Skips dcache_enable during JTAG recovery */
	if (sfi->flash_type)
		dcache_enable();
}

void disable_caches(void)
{
	icache_disable();
	dcache_disable();
}

/*
 * To determine the spi flash addr is in 3 byte
 * or 4 byte.
 */
unsigned int get_smem_spi_addr_len(void)
{
	int ret;
	uint32_t spi_flash_addr_len;

	ret = smem_read_alloc_entry(SMEM_SPI_FLASH_ADDR_LEN,
					&spi_flash_addr_len, sizeof(uint32_t));
	if (ret != 0) {
		printf("SPI: using 3 byte address mode as default\n");
		spi_flash_addr_len = SPI_DEFAULT_ADDR_LEN;
	}

	return spi_flash_addr_len;
}

int ipq_read_tcsr_boot_misc(void)
{
	u32 *dmagic = TCSR_BOOT_MISC_REG;
	return *dmagic;
}

int apps_iscrashed(void)
{
	u32 dmagic = ipq_read_tcsr_boot_misc();

	if (dmagic & DLOAD_MAGIC_COOKIE)
		return 1;

	return 0;
}

/**
 * Set the uuid in bootargs variable for mounting rootfilesystem
 */
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag)
{
	int ret, len;
	block_dev_desc_t *blk_dev;
	disk_partition_t disk_info;

	blk_dev = mmc_get_dev(mmc_host.dev_num);
	if (!blk_dev) {
		printf("Invalid block device name\n");
		return -EINVAL;
	}

	if (buflen <= 0 || buflen > MAX_BOOT_ARGS_SIZE)
		return -EINVAL;

#ifdef CONFIG_PARTITION_UUIDS
	ret = get_partition_info_efi_by_name(blk_dev,
			part_name, &disk_info);
	if (ret) {
		printf("bootipq: unsupported partition name %s\n",part_name);
		return -EINVAL;
	}
	if ((len = strlcpy(boot_args, "root=PARTUUID=", buflen)) >= buflen)
		return -EINVAL;
#else
	if ((len = strlcpy(boot_args, "rootfsname=", buflen)) >= buflen)
		return -EINVAL;
#endif
	boot_args += len;
	buflen -= len;

#ifdef CONFIG_PARTITION_UUIDS
	if ((len = strlcpy(boot_args, disk_info.uuid, buflen)) >= buflen)
		return -EINVAL;
#else
	if ((len = strlcpy(boot_args, part_name, buflen)) >= buflen)
		return -EINVAL;
#endif
	boot_args += len;
	buflen -= len;

	if (gpt_flag && strlcpy(boot_args, " gpt", buflen) >= buflen)
		return -EINVAL;

	return 0;
}

int is_secondary_core_off(unsigned int cpuid)
{
	int err;

	err = __invoke_psci_fn_smc(ARM_PSCI_TZ_FN_AFFINITY_INFO, cpuid, 0, 0);

	return err;
}

void bring_secondary_core_down(unsigned int state)
{
	__invoke_psci_fn_smc(ARM_PSCI_TZ_FN_CPU_OFF, state, 0, 0);
}

int bring_sec_core_up(unsigned int cpuid, unsigned int entry, unsigned int arg)
{
	int err;

	err = __invoke_psci_fn_smc(ARM_PSCI_TZ_FN_CPU_ON, cpuid, entry, arg);
	if (err) {
		printf("Enabling CPU%d via psci failed!\n", cpuid);
		return -1;
	}

	printf("Enabled CPU%d via psci successfully!\n", cpuid);
	return 0;
}

#ifndef CONFIG_CMD_DISABLE_EXECTZT
void run_tzt(void *address)
{
	execute_tzt(address);
}
#endif

void sdi_disable(void)
{
	qca_scm_sdi();
}

void handle_noc_err(void)
{
	uint32_t noc_err_pending = 0;
	noc_err_pending = readl(NOC_ERR_STATUS_REG);

	if ((noc_err_pending & REG_VAL_NOC_ERR) == REG_VAL_NOC_ERR) {
		printf("NOC Error detected, restarting");
		writel(REG_VAL_NOC_ERR, NOC_ERR_CLR_REG);
		run_command("reset", 0);
	}
}

/* Intialize distributor */
static void qgic_dist_init(void)
{
	uint32_t i;
	uint32_t num_irq = 0;
	uint32_t cpumask = 1;

	cpumask |= cpumask << 8;
	cpumask |= cpumask << 16;

	/* Disabling GIC */
	writel(0, GIC_DIST_CTRL);

	/*
	 * Find out how many interrupts are supported.
	 */
	num_irq = readl(GIC_DIST_CTR) & 0x1f;
	num_irq = (num_irq + 1) * 32;

	/* Set each interrupt line to use N-N software model
	 * and edge sensitive, active high
	 */
	for (i = 32; i < num_irq; i += 16)
		writel(0xffffffff, GIC_DIST_CONFIG + i * 4 / 16);

	writel(0xffffffff, GIC_DIST_CONFIG + 4);

	/* Set up interrupts for this CPU */
	for (i = 32; i < num_irq; i += 4)
		writel(cpumask, GIC_DIST_TARGET + i * 4 / 4);

	/* Set priority of all interrupts */

	/*
	 * In bootloader we dont care about priority so
	 * setting up equal priorities for all
	 */
	for (i = 0; i < num_irq; i += 4)
		writel(0xa0a0a0a0, GIC_DIST_PRI + i * 4 / 4);

	/* Disabling interrupts */
	for (i = 0; i < num_irq; i += 32)
		writel(0xffffffff, GIC_DIST_ENABLE_CLEAR + i * 4 / 32);

	writel(0x0000ffff, GIC_DIST_ENABLE_SET);

	/*Enabling GIC */
	writel(1, GIC_DIST_CTRL);
}

/* Intialize cpu specific controller */
static void qgic_cpu_init(void)
{
	writel(0xf0, GIC_CPU_PRIMASK);
	writel(1, GIC_CPU_CTRL);
}

/* Initialize QGIC. Called from platform specific init code */
void qgic_init(void)
{
	qgic_dist_init();
	qgic_cpu_init();
}

int get_soc_hw_version(void)
{
	return readl(TCSR_SOC_HW_VERSION_REG);
}
