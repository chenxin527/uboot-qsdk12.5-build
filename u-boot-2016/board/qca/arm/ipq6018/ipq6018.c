/*
 * Copyright (c) 2016-2018, The Linux Foundation. All rights reserved.
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
#include <asm/arch-qca-common/qpic_nand.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/scm.h>
#include <asm/arch-qca-common/iomap.h>
#include <ipq6018.h>
#include <mmc.h>
#include <sdhci.h>
#include <usb.h>
#include <i2c.h>
#include <dm.h>
#include <command.h>

#define DLOAD_MAGIC_COOKIE	0x10
#define DLOAD_DISABLED		0x40

#define TCSR_SOC_HW_VERSION_REG 0x194D000

DECLARE_GLOBAL_DATA_PTR;
struct sdhci_host mmc_host;
extern int ipq6018_edma_init(void *cfg);
extern int ipq_spi_init(u16);

const char *rsvd_node = "/reserved-memory";
const char *del_node[] = {"uboot",
			  "sbl",
			  NULL};
const add_node_t add_fdt_node[] = {{}};
static int aq_phy_initialised;
struct dumpinfo_t dumpinfo_n[] = {
	/* TZ stores the DDR physical address at which it stores the
	 * APSS regs, UTCM copy dump. We will have the TZ IMEM
	 * IMEM Addr at which the DDR physical address is stored as
	 * the start
	 *     --------------------
         *     |  DDR phy (start) | ----> ------------------------
         *     --------------------       | APSS regsave (8k)    |
         *                                ------------------------
         *                                |                      |
	 *                                | 	 UTCM copy	 |
         *                                |        (192k)        |
	 *                                |                      |
         *                                ------------------------
	 */

	/* Compressed EBICS dump follows descending order
	 * to use in-memory compression for which destination
	 * for compression will be address of EBICS2.BIN
	 *
	 * EBICS2 - (ddr size / 2) [to] end of ddr
	 * EBICS1 - uboot end addr [to] (ddr size / 2)
	 * EBICS0 - ddr start      [to] uboot start addr
	 */

	{ "EBICS0.BIN", 0x40000000, 0x10000000, 0 },
	{ "EBICS2.BIN", 0x60000000, 0x20000000, 0, 0, 0, 0, 1 },
	{ "EBICS1.BIN", CONFIG_UBOOT_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS0.BIN", 0x40000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 },
	{ "CODERAM.BIN", 0x00200000, 0x00028000, 0 },
	{ "DATARAM.BIN", 0x00290000, 0x00014000, 0 },
	{ "MSGRAM.BIN", 0x00060000, 0x00006000, 1 },
	{ "IMEM.BIN", 0x08600000, 0x00001000, 0 },
	{ "NSSUTCM.BIN", 0x08600658, 0x00030000, 0, 1, 0x2000 },
	{ "UNAME.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "CPU_INFO.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "DMESG.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "PT.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "WLAN_MOD.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
};
int dump_entries_n = ARRAY_SIZE(dumpinfo_n);

u32 *tz_wonce = (u32 *)CONFIG_IPQ6018_TZ_WONCE_4_ADDR;

#define BLSP1_UART0_BASE	0x078AF000
#define UART_PORT_ID(reg)	((reg - BLSP1_UART0_BASE) / 0x1000)

void qca_serial_init(struct ipq_serial_platdata *plat)
{
	int ret;

	if (plat->gpio_node < 0) {
		printf("serial_init: unable to find gpio node \n");
		return;
	}

	qca_gpio_init(plat->gpio_node);
	plat->port_id = UART_PORT_ID(plat->reg_base);
	ret = uart_clock_config(plat);
	if (ret)
		printf("UART clock config failed %d \n", ret);

	return;
}

int do_pmic_reset()
{
	struct udevice *bus, *dev;
	int bus_no = 1;
	int ret;
	uchar byte = CONFIG_IPQ6018_PMIC_RESET_VAL;

	ret = uclass_get_device_by_seq(UCLASS_I2C, bus_no, &bus);
	if (ret) {
		debug("%s: No bus %d\n", __func__, bus_no);
		return -1;
	}

	ret = dm_i2c_probe(bus, CONFIG_IPQ6018_PMIC_CHIP_ADDR, 0, &dev);
	if (ret) {
		printf("Probe failed\n");
		return -1;
	}

	ret = i2c_get_chip(bus, CONFIG_IPQ6018_PMIC_CHIP_ADDR, 1, &dev);
	if (ret) {
		printf("Error 'i2c_get_chip': %d\n",ret);
		return CMD_RET_FAILURE;
	}

	ret = dm_i2c_write(dev, CONFIG_IPQ6018_PMIC_OFFSET, &byte, 1);
	if (ret) {
		printf("Error writing the chip: %d\n", ret);
		return CMD_RET_FAILURE;
	}

	return 0;
}

void reset_crashdump(void)
{
	unsigned int ret = 0;
	unsigned int cookie = 0;

	cookie = ipq_read_tcsr_boot_misc();
	qca_scm_sdi();
	/* Set CRASHDUMP_RESET in crashdump path,
	 * for TZ to differentiate it from normal reset */
	if (cookie & DLOAD_ENABLE) {
		cookie |= CRASHDUMP_RESET;
	}
	cookie &= DLOAD_DISABLE;
	ret = qca_scm_dload(cookie);
	if (ret)
		printf ("Error in reseting the Magic cookie\n");
	return;
}

#ifdef CONFIG_QCA_MMC
void emmc_clock_config(void)
{
	int cfg;

	/* Configure sdcc1_apps_clk_src */
	cfg = (GCC_SDCC1_APPS_CFG_RCGR_SRC_SEL
			| GCC_SDCC1_APPS_CFG_RCGR_SRC_DIV);
	writel(cfg, GCC_SDCC1_APPS_CFG_RCGR);
	writel(SDCC1_M_VAL, GCC_SDCC1_APPS_M);
	writel(SDCC1_N_VAL, GCC_SDCC1_APPS_N);
	writel(SDCC1_D_VAL, GCC_SDCC1_APPS_D);
	writel(CMD_UPDATE, GCC_SDCC1_APPS_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_SDCC1_APPS_CMD_RCGR);

	/* Configure CBCRs */
	writel(readl(GCC_SDCC1_APPS_CBCR) | CLK_ENABLE, GCC_SDCC1_APPS_CBCR);
	udelay(10);
	writel(readl(GCC_SDCC1_AHB_CBCR) | CLK_ENABLE, GCC_SDCC1_AHB_CBCR);
}

void mmc_iopad_config(struct sdhci_host *host)
{
	u32 val;
	val = sdhci_readb(host, SDHCI_VENDOR_IOPAD);
	/*set bit 15 & 16*/
	val |= 0x18000;
	writel(val, host->ioaddr + SDHCI_VENDOR_IOPAD);
}

void sdhci_bus_pwr_off(struct sdhci_host *host)
{
	u32 val;

	val = sdhci_readb(host, SDHCI_HOST_CONTROL);
	sdhci_writeb(host,(val & (~SDHCI_POWER_ON)), SDHCI_POWER_CONTROL);
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

	mmc_host.ioaddr = (void *)MSM_SDC1_SDHCI_BASE;
	mmc_host.voltages = MMC_VDD_165_195;
	mmc_host.version = SDHCI_SPEC_300;
	mmc_host.cfg.part_type = PART_TYPE_EFI;
	mmc_host.quirks = SDHCI_QUIRK_BROKEN_VOLTAGE;

	emmc_clock_disable();
	emmc_clock_reset();
	udelay(10);
	emmc_clock_config();

	if (add_sdhci(&mmc_host, 200000000, 400000)) {
		printf("add_sdhci fail!\n");
		return -1;
	}

	if (!ret && sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
		ret = board_mmc_env_init(mmc_host);
	}

	return ret;
}
#else
int board_mmc_init(bd_t *bis)
{
	return 0;
}
#endif

void board_nand_init(void)
{
#ifdef CONFIG_QCA_SPI
	int gpio_node;
#endif

	qpic_nand_init(NULL);

#ifdef CONFIG_QCA_SPI
	gpio_node = fdt_path_offset(gd->fdt_blob, "/spi/spi_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
		spi_clock_init(0);
		ipq_spi_init(CONFIG_IPQ_SPI_NOR_INFO_IDX);
	}
#ifdef CONFIG_SPI_NAND
	if (fdtdec_get_uint(gd->fdt_blob, 0, "spi_nand_available", 0))
		spi_nand_init();
#endif
#endif
}

#ifdef CONFIG_PCI_IPQ
static void pcie_v2_clock_init(void)
{
	int cfg;


	/* Configure pcie0_aux_clk_src */
	cfg = (GCC_PCIE0_AUX_CFG_RCGR_SRC_SEL | GCC_PCIE0_AUX_CFG_RCGR_SRC_DIV);
	writel(cfg, GCC_PCIE0_AUX_CFG_RCGR);
	writel(CMD_UPDATE, GCC_PCIE0_AUX_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_PCIE0_AUX_CMD_RCGR);

	/* Configure pcie0_axi_clk_src */
	cfg = (GCC_PCIE0_AXI_CFG_RCGR_SRC_SEL | GCC_PCIE0_AXI_CFG_RCGR_SRC_DIV);
	writel(cfg, GCC_PCIE0_AXI_CFG_RCGR);
	writel(CMD_UPDATE, GCC_PCIE0_AXI_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_PCIE0_AXI_CMD_RCGR);

	/* Configure CBCRs */
	writel(CLK_ENABLE, GCC_SYS_NOC_PCIE0_AXI_CBCR);
	writel(CLK_ENABLE, GCC_PCIE0_AHB_CBCR);
	writel(CLK_ENABLE, GCC_PCIE0_AXI_M_CBCR);
	writel(CLK_ENABLE, GCC_PCIE0_AXI_S_CBCR);
	writel(CLK_ENABLE, GCC_PCIE0_AUX_CBCR);
	writel(PIPE_CLK_ENABLE, GCC_PCIE0_PIPE_CBCR);
	writel(CLK_ENABLE, GCC_PCIE0_AXI_S_BRIDGE_CBCR);

	/* Configure pcie0_rchng_clk_src */
	cfg = (GCC_PCIE0_RCHNG_CFG_RCGR_SRC_SEL
			| GCC_PCIE0_RCHNG_CFG_RCGR_SRC_DIV);
	writel(cfg, GCC_PCIE0_RCHNG_CFG_RCGR);
	writel(CMD_UPDATE, GCC_PCIE0_RCHNG_CMD_RCGR);
	mdelay(100);
	writel(ROOT_EN, GCC_PCIE0_RCHNG_CMD_RCGR);


}

static void pcie_v2_clock_deinit(void)
{
	writel(0x0, GCC_PCIE0_AUX_CMD_RCGR);
	writel(0x0, GCC_PCIE0_AXI_CFG_RCGR);
	writel(0x0, GCC_PCIE0_AXI_CMD_RCGR);
	mdelay(100);
	writel(0x0, GCC_SYS_NOC_PCIE0_AXI_CBCR);
	writel(0x0, GCC_PCIE0_AHB_CBCR);
	writel(0x0, GCC_PCIE0_AXI_M_CBCR);
	writel(0x0, GCC_PCIE0_AXI_S_CBCR);
	writel(0x0, GCC_PCIE0_AUX_CBCR);
	writel(0x0, GCC_PCIE0_PIPE_CBCR);
	writel(0x0, GCC_PCIE0_AXI_S_BRIDGE_CBCR);
	writel(0x0, GCC_PCIE0_RCHNG_CFG_RCGR);
	writel(0x0, GCC_PCIE0_RCHNG_CMD_RCGR);
}

void board_pci_init(int id)
{
	int node, gpio_node;
	char name[16];

	snprintf(name, sizeof(name), "pci%d", id);
	node = fdt_path_offset(gd->fdt_blob, name);
	if (node < 0) {
		printf("Could not find PCI in device tree\n");
		return;
	}
	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);

	pcie_v2_clock_init();

	return;
}

void board_pci_deinit()
{
	int node, gpio_node, i, err;
	char name[16];
	struct fdt_resource parf;
	struct fdt_resource pci_phy;

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
		if (err < 0)
			return;

		writel(0x1, pci_phy.start + 800);
		writel(0x0, pci_phy.start + 804);
		gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
		if (gpio_node >= 0)
			qca_gpio_deinit(gpio_node);

	}

	pcie_v2_clock_deinit();

	return ;
}
#endif
void set_flash_secondary_type(qca_smem_flash_info_t *smem)
{
	return;
};

#ifdef CONFIG_USB_XHCI_IPQ
void board_usb_deinit(int id)
{
	int nodeoff;
	char node_name[8];

	snprintf(node_name, sizeof(node_name), "usb%d", id);
	nodeoff = fdt_path_offset(gd->fdt_blob, node_name);
	if (fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0))
		return;

	if (id == 0) {
		/* Enable USB PHY Power down */
		setbits_le32(USB30_PHY_1_QUSB2PHY_BASE + 0xB4, 0x1);
		/* Disable clocks */
		writel(0x8000, GCC_USB0_PHY_CFG_AHB_CBCR);
		writel(0xcff0, GCC_USB0_MASTER_CBCR);
		writel(0, GCC_SYS_NOC_USB0_AXI_CBCR);
		writel(0, GCC_SNOC_BUS_TIMEOUT2_AHB_CBCR);
		writel(0, GCC_USB0_SLEEP_CBCR);
		writel(0, GCC_USB0_MOCK_UTMI_CBCR);
		writel(0, GCC_USB0_AUX_CBCR);
		/* GCC_QUSB2_0_PHY_BCR */
		set_mdelay_clearbits_le32(GCC_QUSB2_0_PHY_BCR, 0x1, 10);
		/* GCC_USB0_PHY_BCR */
		set_mdelay_clearbits_le32(GCC_USB0_PHY_BCR, 0x1, 10);
		/* GCC Reset USB BCR */
		set_mdelay_clearbits_le32(GCC_USB0_BCR, 0x1, 10);
	} else if (id == 1) {
		/* Enable USB PHY Power down */
		setbits_le32(USB30_PHY_2_QUSB2PHY_BASE + 0xB4, 0x1);
		/* Disable clocks */
		writel(0x8000, GCC_USB1_PHY_CFG_AHB_CBCR);
		writel(0xcff0, GCC_USB1_MASTER_CBCR);
		writel(0, GCC_USB1_SLEEP_CBCR);
		writel(0, GCC_USB1_MOCK_UTMI_CBCR);
		/* GCC_QUSB2_0_PHY_BCR */
		set_mdelay_clearbits_le32(GCC_QUSB2_1_PHY_BCR, 0x1, 10);
		/* GCC Reset USB0 BCR */
		set_mdelay_clearbits_le32(GCC_USB1_BCR, 0x1, 10);
	}
}

static void usb_clock_init(int id)
{
	int cfg;

	if (id == 0) {
		cfg = readl(GCC_USB0_GDSCR) | SW_OVERRIDE_ENABLE;
		cfg &= ~(SW_COLLAPSE_ENABLE);
		writel(cfg, GCC_USB0_GDSCR);

		/* Configure usb0_master_clk_src */
		cfg = (GCC_USB0_MASTER_CFG_RCGR_SRC_SEL |
			GCC_USB0_MASTER_CFG_RCGR_SRC_DIV);
		writel(cfg, GCC_USB0_MASTER_CFG_RCGR);
		writel(CMD_UPDATE, GCC_USB0_MASTER_CMD_RCGR);
		mdelay(100);
		writel(ROOT_EN, GCC_USB0_MASTER_CMD_RCGR);

		/* Configure usb0_mock_utmi_clk_src */
		cfg = (GCC_USB_MOCK_UTMI_SRC_SEL |
			GCC_USB_MOCK_UTMI_SRC_DIV);
		writel(cfg, GCC_USB0_MOCK_UTMI_CFG_RCGR);
		writel(UTMI_M, GCC_USB0_MOCK_UTMI_M);
		writel(UTMI_N, GCC_USB0_MOCK_UTMI_N);
		writel(UTMI_D, GCC_USB0_MOCK_UTMI_D);
		writel(CMD_UPDATE, GCC_USB0_MOCK_UTMI_CMD_RCGR);
		mdelay(100);
		writel(ROOT_EN, GCC_USB0_MOCK_UTMI_CMD_RCGR);

		/* Configure usb0_aux_clk_src */
		cfg = (GCC_USB0_AUX_CFG_SRC_SEL |
			GCC_USB0_AUX_CFG_SRC_DIV);
		writel(cfg, GCC_USB0_AUX_CFG_RCGR);
		writel(AUX_M, GCC_USB0_AUX_M);
		writel(AUX_N, GCC_USB0_AUX_N);
		writel(AUX_D, GCC_USB0_AUX_D);
		writel(CMD_UPDATE, GCC_USB0_AUX_CMD_RCGR);
		mdelay(100);
		writel(ROOT_EN, GCC_USB0_AUX_CMD_RCGR);

		/* Configure CBCRs */
		writel(CLK_DISABLE, GCC_SYS_NOC_USB0_AXI_CBCR);
		writel(CLK_DISABLE, GCC_SNOC_BUS_TIMEOUT2_AHB_CBCR);
		writel(CLK_ENABLE, GCC_SYS_NOC_USB0_AXI_CBCR);
		writel((readl(GCC_USB0_MASTER_CBCR) | CLK_ENABLE),
						GCC_USB0_MASTER_CBCR);
		writel(CLK_ENABLE, GCC_SNOC_BUS_TIMEOUT2_AHB_CBCR);
		writel(CLK_ENABLE, GCC_USB0_SLEEP_CBCR);
		writel(CLK_ENABLE, GCC_USB0_MOCK_UTMI_CBCR);
		writel((CLK_ENABLE | NOC_HANDSHAKE_FSM_EN),
						GCC_USB0_PHY_CFG_AHB_CBCR);
		writel(CLK_ENABLE, GCC_USB0_AUX_CBCR);
		writel(CLK_ENABLE, GCC_USB0_PIPE_CBCR);

	} else if (id == 1) {
		cfg = readl(GCC_USB1_GDSCR) | SW_OVERRIDE_ENABLE;
		cfg &= ~(SW_COLLAPSE_ENABLE);
		writel(cfg, GCC_USB1_GDSCR);

		/* Configure usb1_mock_utmi_clk_src */
		cfg = (GCC_USB_MOCK_UTMI_SRC_SEL |
			GCC_USB_MOCK_UTMI_SRC_DIV);
		writel(cfg, GCC_USB1_MOCK_UTMI_CFG_RCGR);
		writel(UTMI_M, GCC_USB1_MOCK_UTMI_M);
		writel(UTMI_N, GCC_USB1_MOCK_UTMI_N);
		writel(UTMI_D, GCC_USB1_MOCK_UTMI_D);
		writel(CMD_UPDATE, GCC_USB1_MOCK_UTMI_CMD_RCGR);
		mdelay(100);
		writel(ROOT_EN, GCC_USB1_MOCK_UTMI_CMD_RCGR);

		/* Configure CBCRs */
		writel(readl(GCC_USB1_MASTER_CBCR) | CLK_ENABLE,
						GCC_USB1_MASTER_CBCR);
		writel(CLK_ENABLE, GCC_USB1_SLEEP_CBCR);
		writel(CLK_ENABLE, GCC_USB1_MOCK_UTMI_CBCR);
		writel((CLK_ENABLE | NOC_HANDSHAKE_FSM_EN),
					GCC_USB1_PHY_CFG_AHB_CBCR);
	}
}

static void usb_init_hsphy(void __iomem *phybase)
{
	/* Enable QUSB2PHY Power down */
	setbits_le32(phybase+0xB4, 0x1);

	/* PHY Config Sequence */
	/* QUSB2PHY_PLL:PLL Feedback Divider Value */
	out_8(phybase+0x00, 0x14);
	/* QUSB2PHY_PORT_TUNE1: USB Product Application Tuning Register A */
	out_8(phybase+0x80, 0xF8);
	/* QUSB2PHY_PORT_TUNE2: USB Product Application Tuning Register B */
	out_8(phybase+0x84, 0xB3);
	/* QUSB2PHY_PORT_TUNE3: USB Product Application Tuning Register C */
	out_8(phybase+0x88, 0x83);
	/* QUSB2PHY_PORT_TUNE4: USB Product Application Tuning Register D */
	out_8(phybase+0x8C, 0xC0);
	/* QUSB2PHY_PORT_TEST2 */
	out_8(phybase+0x9C, 0x14);
	/* QUSB2PHY_PLL_TUNE: PLL Test Configuration */
	out_8(phybase+0x08, 0x30);
	/* QUSB2PHY_PLL_USER_CTL1: PLL Control Configuration */
	out_8(phybase+0x0C, 0x79);
	/* QUSB2PHY_PLL_USER_CTL2: PLL Control Configuration */
	out_8(phybase+0x10, 0x21);
	/* QUSB2PHY_PORT_TUNE5 */
	out_8(phybase+0x90, 0x00);
	/* QUSB2PHY_PLL_PWR_CTL: PLL Manual SW Programming
	 * and Biasing Power Options */
	out_8(phybase+0x18, 0x00);
	/* QUSB2PHY_PLL_AUTOPGM_CTL1: Auto vs. Manual PLL/Power-mode
	 * programming State Machine Control Options */
	out_8(phybase+0x1C, 0x9F);
	/* QUSB2PHY_PLL_TEST: PLL Test Configuration-Disable diff ended clock */
	out_8(phybase+0x04, 0x80);

	/* Disable QUSB2PHY Power down */
	clrbits_le32(phybase+0xB4, 0x1);
}

static void usb_init_ssphy(void __iomem *phybase)
{
	out_8(phybase + USB3_PHY_POWER_DOWN_CONTROL,0x1);
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
	out_8(phybase + QSERDES_COM_DEC_START_MODE0,0x68);
	out_8(phybase + QSERDES_COM_DIV_FRAC_START1_MODE0,0xAB);
	out_8(phybase + QSERDES_COM_DIV_FRAC_START2_MODE0,0xAA);
	out_8(phybase + QSERDES_COM_DIV_FRAC_START3_MODE0,0x02);
	out_8(phybase + QSERDES_COM_CP_CTRL_MODE0,0x09);
	out_8(phybase + QSERDES_COM_PLL_RCTRL_MODE0,0x16);
	out_8(phybase + QSERDES_COM_PLL_CCTRL_MODE0,0x28);
	out_8(phybase + QSERDES_COM_INTEGLOOP_GAIN0_MODE0,0xA0);
	out_8(phybase + QSERDES_COM_LOCK_CMP1_MODE0,0xAA);
	out_8(phybase + QSERDES_COM_LOCK_CMP2_MODE0,0x29);
	out_8(phybase + QSERDES_COM_LOCK_CMP3_MODE0,0x00);
	out_8(phybase + QSERDES_COM_CORE_CLK_EN,0x00);
	out_8(phybase + QSERDES_COM_LOCK_CMP_CFG,0x00);
	out_8(phybase + QSERDES_COM_VCO_TUNE_MAP,0x00);
	out_8(phybase + QSERDES_COM_BG_TIMER,0x0a);
	out_8(phybase + QSERDES_COM_SSC_EN_CENTER,0x01);
	out_8(phybase + QSERDES_COM_SSC_PER1,0x7D);
	out_8(phybase + QSERDES_COM_SSC_PER2,0x01);
	out_8(phybase + QSERDES_COM_SSC_ADJ_PER1,0x00);
	out_8(phybase + QSERDES_COM_SSC_ADJ_PER2,0x00);
	out_8(phybase + QSERDES_COM_SSC_STEP_SIZE1,0x0A);
	out_8(phybase + QSERDES_COM_SSC_STEP_SIZE2,0x05);
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

	if (index == 0) {
		boot_clk_ctl = (u32 *)GCC_USB_0_BOOT_CLOCK_CTL;
		usb_bcr = (u32 *)GCC_USB0_BCR;
		qusb2_phy_bcr = (u32 *)GCC_QUSB2_0_PHY_BCR;
	} else if (index == 1) {
		boot_clk_ctl = (u32 *)GCC_USB_1_BOOT_CLOCK_CTL;
		usb_bcr = (u32 *)GCC_USB1_BCR;
		qusb2_phy_bcr = (u32 *)GCC_QUSB2_1_PHY_BCR;
	} else {
		return;
	}
	/* Enable SS Ref Clock */
	setbits_le32(GCC_USB_SS_REF_CLK_EN, 0x1);

	/* Disable USB Boot Clock */
	clrbits_le32(boot_clk_ctl, 0x0);

	/* GCC Reset USB BCR */
	set_mdelay_clearbits_le32(usb_bcr, 0x1, 10);

	/* GCC_QUSB2_PHY_BCR */
	setbits_le32(qusb2_phy_bcr, 0x1);

	if (index == 0) {
		/* GCC_USB0_PHY_BCR */
		setbits_le32(GCC_USB0_PHY_BCR, 0x1);
		setbits_le32(GCC_USB3PHY_0_PHY_BCR, 0x1);
		mdelay(10);
		clrbits_le32(GCC_USB3PHY_0_PHY_BCR, 0x1);
		clrbits_le32(GCC_USB0_PHY_BCR, 0x1);
		/* Config user control register */
		writel(0x0a40c010, USB30_1_GUCTL);
		writel(0x0a87f0a0, USB30_1_FLADJ);
	} else if (index == 1) {
		/* Config user control register */
		writel(0x0a40c010, GUCTL);
		writel(0x0a87f0a0, FLADJ);
	} else {
		return;
	}

	/* GCC_QUSB2_0_PHY_BCR */
	clrbits_le32(qusb2_phy_bcr, 0x1);
	mdelay(10);

	if (index == 0) {
		usb_init_hsphy((u32 *)USB30_PHY_1_QUSB2PHY_BASE);
		usb_init_ssphy((u32 *)USB30_PHY_1_USB3PHY_AHB2PHY_BASE);
	} else {
		usb_init_hsphy((u32 *)USB30_PHY_2_QUSB2PHY_BASE);
	}
}

int ipq_board_usb_init(void)
{
	int i, nodeoff;
	char node_name[8];

	for (i=0; i<CONFIG_USB_MAX_CONTROLLER_COUNT; i++) {
		snprintf(node_name, sizeof(node_name), "usb%d", i);
		nodeoff = fdt_path_offset(gd->fdt_blob, node_name);
		if (!fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0)) {
			usb_clock_init(i);
			usb_init_phy(i);
		}
	}
	return 0;
}
#endif

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

__weak int ipq_get_tz_version(char *version_name, int buf_size)
{
	return 1;
}

int ipq_read_tcsr_boot_misc(void)
{
	u32 *dmagic = TCSR_BOOT_MISC_REG;
	return *dmagic;
}

int apps_iscrashed_crashdump_disabled(void)
{
	u32 dmagic = ipq_read_tcsr_boot_misc();

	if (dmagic & DLOAD_DISABLED)
		return 1;

	return 0;
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
#ifdef CONFIG_QCA_MMC
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
#else
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag)
{
	return 0;
}
#endif

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

int get_malibu_gpio(int malibu_gpio[2])
{
	int malibu_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		malibu_gpio_cnt = fdtdec_get_uint(gd->fdt_blob, node, "malibu_gpio_cnt", -1);
		if (malibu_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node, "malibu_gpio",
						   (u32 *)malibu_gpio, malibu_gpio_cnt);
			if (res >= 0)
				return malibu_gpio_cnt;
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

void malibu_phy_reset_init(void)
{
	int malibu_gpio[2] = {0}, malibu_gpio_cnt, i;
	unsigned int *malibu_gpio_base;

	malibu_gpio_cnt = get_malibu_gpio(malibu_gpio);
	if (malibu_gpio_cnt >= 1) {
		for (i = 0; i < malibu_gpio_cnt; i++) {
			if (malibu_gpio[i] >=0) {
				malibu_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(malibu_gpio[i]);
				writel(0x203, malibu_gpio_base);
				gpio_direction_output(malibu_gpio[i], 0x0);
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

void aquantia_phy_reset_init_done(void)
{
	int aquantia_gpio;

	aquantia_gpio = get_aquantia_gpio();
	if (aquantia_gpio >= 0) {
		gpio_set_value(aquantia_gpio, 0x1);
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

void malibu_phy_reset_init_done(void)
{
	int malibu_gpio[2] = {0}, malibu_gpio_cnt, i;

	malibu_gpio_cnt = get_malibu_gpio(malibu_gpio);
	if (malibu_gpio_cnt >= 1) {
		for (i = 0; i < malibu_gpio_cnt; i++)
			gpio_set_value(malibu_gpio[i], 0x1);
	}
}

int get_mdc_mdio_gpio(int mdc_mdio_gpio[2])
{
	int mdc_mdio_gpio_cnt = 2, node;
	int res = -1;
	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		res = fdtdec_get_int_array(gd->fdt_blob, node, "mdc_mdio_gpio",
					   (u32 *)mdc_mdio_gpio, mdc_mdio_gpio_cnt);
		if (res >= 0)
			return mdc_mdio_gpio_cnt;
	}

	return res;
}

void set_function_select_as_mdc_mdio(void)
{
	int mdc_mdio_gpio[2] = {0}, mdc_mdio_gpio_cnt, i;
	unsigned int *mdc_mdio_gpio_base;

	mdc_mdio_gpio_cnt = get_mdc_mdio_gpio(mdc_mdio_gpio);
	if (mdc_mdio_gpio_cnt >= 1) {
		for (i = 0; i < mdc_mdio_gpio_cnt; i++) {
			if (mdc_mdio_gpio[i] >=0) {
				mdc_mdio_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(mdc_mdio_gpio[i]);
				writel(0xC7, mdc_mdio_gpio_base);
			}
		}
	}
}

static void ppe_clk_init(void)
{
	uint32_t reg_val, i;
	int gcc_ppeclock_base = 0x01868000;
	int gcc_pll_base = 0x0009B780;

	reg_val = readl(gcc_pll_base + 4);
	reg_val=(reg_val&0xfffffff0)|0x7;
	writel(reg_val, gcc_pll_base + 0x4);
	reg_val = readl(gcc_pll_base);
	reg_val=reg_val | 0x40;
	writel(reg_val, gcc_pll_base);
	mdelay(1);
	reg_val=reg_val & (~0x40);
	writel(reg_val, gcc_pll_base);
	writel(0xbf, gcc_pll_base);
	reg_val = readl(gcc_pll_base);
	mdelay(1);
	writel(0xff, gcc_pll_base);
	reg_val = readl(gcc_pll_base);
	mdelay(1);
	/*set clock src and div*/
	reg_val = 1 | (1 << 8);
	writel(reg_val, gcc_ppeclock_base + 0x84);
	/*issue command*/
	reg_val = readl(gcc_ppeclock_base + 0x80);
	reg_val |= 1;
	writel(reg_val, gcc_ppeclock_base + 0x80);
	mdelay(100);
	reg_val = readl(gcc_ppeclock_base + 0x80);
	reg_val |= 2;
	writel(reg_val, gcc_ppeclock_base + 0x80);

	/*set CBCR*/
	for (i= 0; i < 4; i++) {
		reg_val = readl(gcc_ppeclock_base + 0x190 + i*4);
		reg_val |= 1;
		writel(reg_val, gcc_ppeclock_base + 0x190 + i*4);
	}

	/*enable nss noc ppe*/
	reg_val = readl(gcc_ppeclock_base + 0x300);
	reg_val |= 1;
	writel(reg_val, gcc_ppeclock_base + 0x300);

	/*enable nss noc ppe config*/
	reg_val = readl(gcc_ppeclock_base + 0x304);
	reg_val |= 1;
	writel(reg_val, gcc_ppeclock_base + 0x304);

	/*enable crypto ppe*/
	reg_val = readl(gcc_ppeclock_base + 0x310);
	reg_val |= 1;
	writel(reg_val, gcc_ppeclock_base + 0x310);

	/*enable mac, ipe btq*/
	for (i= 0; i < 8; i++) {
		reg_val = readl(gcc_ppeclock_base + 0x320 + i*4);
		reg_val |= 1;
		writel(reg_val, gcc_ppeclock_base + 0x320 + i*4);
	}
}

void eth_clock_enable(void)
{
	ppe_clk_init();

	/* RCGR and CBCR regs will be
	 * config by SBL. It will later be moved to u-boot.
	 */

	/*
	 * Take NSS PPE out of reset
	 */
	writel(PPE_ASSERT, GCC_NSS_PPE_RESET);
	mdelay(500);
	writel(PPE_DEASSERT, GCC_NSS_PPE_RESET);
	mdelay(100);

	/* set function select as mdio */
	set_function_select_as_mdc_mdio();

	/* bring phy out of reset */
	malibu_phy_reset_init();
	aquantia_phy_reset_init();
	napa_phy_reset_init();
	sfp_reset_init();
	mdelay(500);
	malibu_phy_reset_init_done();
	aquantia_phy_reset_init_done();
	napa_phy_reset_init_done();
	mdelay(500);
}

int board_eth_init(bd_t *bis)
{
	int ret=0;

	eth_clock_enable();
	ret = ipq6018_edma_init(NULL);

	if (ret != 0)
		printf("%s: ipq6018_edma_init failed : %d\n", __func__, ret);

	return ret;
}

unsigned long timer_read_counter(void)
{
	return 0;
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

static void atf_reset(void)
{
	if(*tz_wonce == 0 ) {	/*COLD REBOOT*/
		if(do_pmic_reset())
			printf("PMIC Reset failed, please do power cycle\n");
	}
	else {		/*WARM REBOOT*/
		psci_sys_reset();
	}
	while(1);
}

void reset_cpu(unsigned long a)
{
	reset_crashdump();

	if(is_atf_enabled())
		atf_reset();
	else
		psci_sys_reset();

	while(1);
}

void reset_board(void)
{
	reset_crashdump();

	puts ("resetting ...\n");
	mdelay(100);

	if(*tz_wonce == 0) {	/*COLD REBOOT*/
		if(do_pmic_reset())
			printf("PMIC Reset failed, please do power cycle\n");
	}
	else {		/*WARM REBOOT*/
		psci_sys_reset();
	}
	while(1);
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_auto_restart(void *blob)
{
	const char *paniconwcssfatal;

	paniconwcssfatal = getenv("paniconwcssfatal");

	if (!paniconwcssfatal)
		return;

	if (strncmp(paniconwcssfatal, "1", sizeof("1"))) {
		printf("fixup_auto_restart: invalid variable 'paniconwcssfatal'");
	} else {
		parse_fdt_fixup("/soc/q6v5_wcss@CD00000%delete%?qca,auto-restart", blob);
	}
	return;
}
#endif

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

unsigned int get_dts_machid(unsigned int machid)
{
	switch (machid)
	{
		case MACH_TYPE_IPQ6018_AP_CP01_C2:
		case MACH_TYPE_IPQ6018_AP_CP01_C3:
		case MACH_TYPE_IPQ6018_AP_CP01_C5:
			return MACH_TYPE_IPQ6018_AP_CP01_C1;
		case MACH_TYPE_IPQ6018_AP_CP01_C4:
			return MACH_TYPE_IPQ6018_AP_CP01_C1;
		default:
			return machid;
	}
}

void ipq_uboot_fdt_fixup(void)
{
	init_config_list();
	switch (gd->bd->bi_arch_number)
	{
		case MACH_TYPE_IPQ6018_AP_CP01_C2:
			add_config_entry("config@cp01-c2");
			add_config_entry("config-cp01-c2");
			break;
		case MACH_TYPE_IPQ6018_AP_CP01_C3:
			add_config_entry("config@cp01-c3");
			add_config_entry("config-cp01-c3");
			break;
		case MACH_TYPE_IPQ6018_AP_CP01_C4:
			add_config_entry("config@cp01-c4");
			add_config_entry("config-cp01-c4");
			break;
		case MACH_TYPE_IPQ6018_AP_CP01_C5:
			add_config_entry("config@cp01-c5");
			add_config_entry("config-cp01-c5");
			break;
		default:
			add_config_list_from_fdt();
	}
	return;
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_set_qca_cold_reboot_enable(void *blob)
{
	parse_fdt_fixup("/soc/qca,scm_restart_reason%qca,coldreboot-enabled%1", blob);
}
#endif

void fdt_fixup_for_atf(void *blob)
{
	if (fdt_path_offset(blob, "/soc/remoteproc@cd00000") >= 0)
		parse_fdt_fixup("/soc/remoteproc@cd00000%qcom,nosecure%1", blob);
	else {
		parse_fdt_fixup("/soc/qcom_q6v5_wcss@CD00000%qcom,nosecure%1", blob);
		parse_fdt_fixup("/soc/qcom_q6v5_wcss@CD00000%qca,wcss-aon-reset-seq%1", blob);
	}
	if (fdt_path_offset(blob, "/soc/dma@704000") >= 0) {
		parse_fdt_fixup("/soc/dma@704000%qcom,controlled-remotely%0",
				blob);
		parse_fdt_fixup("/soc/dma@704000%qti,config-pipe-trust-reg%2",
				blob);
	}
}

int get_soc_hw_version(void)
{
	return readl(TCSR_SOC_HW_VERSION_REG);
}
