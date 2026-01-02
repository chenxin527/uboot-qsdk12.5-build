/*
 * Copyright (c) 2016-2021 The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
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
#include <fdtdec.h>

#include <asm/arch-qca-common/qpic_nand.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/scm.h>
#include <asm/arch-qca-common/iomap.h>
#include <ipq9574.h>
#include <mmc.h>
#include <sdhci.h>
#include <usb.h>

#define DLOAD_MAGIC_COOKIE	0x10
#define DLOAD_DISABLED		0x40

#define LINUX6_1_NAND_DTS "/soc@0/nand@79b0000/"
#define LINUX6_1_MMC_DTS "/soc@0/mmc@7804000/"
#define STATUS_OK "status%?okay"
#define STATUS_DISABLED "status%?disabled"

DECLARE_GLOBAL_DATA_PTR;

unsigned long fuse_addr[FUSE_CNT] = {
		0x000A00C0,
		0x000A00C4,
		0x000A00D8,
		0x000A00DC,
		0x000A00E0,
		0x000A00E4,
		0x000A00E8,
		0x000A00EC,
		0x000A00F0,
		0x000A00F4,
		0x000A00F8,
		0x000A00FC,
		0x000A0100,
		0x000A0104,
		0x000A0108,
		0x000A010C,
};

struct sdhci_host mmc_host;
extern int ipq9574_edma_init(void *cfg);
extern int ipq_spi_init(u16);

unsigned int qpic_frequency = 0, qpic_phase = 0;
static int aq_phy_initialised = 0;

extern	int qca_scm_dpr(u32, u32, void *, size_t);

void fdt_fixup_flash(void *blob)
{
	uint32_t flash_type = SMEM_BOOT_NO_FLASH;
	int nand_nodeoff = fdt_path_offset(blob, LINUX6_1_NAND_DTS);
	int mmc_nodeoff = fdt_path_offset(blob, LINUX6_1_MMC_DTS);

	get_current_flash_type(&flash_type);
	if (flash_type == SMEM_BOOT_NORPLUSEMMC ||
		flash_type == SMEM_BOOT_MMC_FLASH ) {
		if(nand_nodeoff >= 0)
			parse_fdt_fixup(LINUX6_1_NAND_DTS"%"STATUS_DISABLED,
					blob);
		if(mmc_nodeoff >= 0)
			parse_fdt_fixup(LINUX6_1_MMC_DTS"%"STATUS_OK, blob);
	}
	return;
}

void qca_serial_init(struct ipq_serial_platdata *plat)
{
	int ret;

	if (plat->gpio_node < 0) {
		printf("serial_init: unable to find gpio node\n");
		return;
	}

	qca_gpio_init(plat->gpio_node);
	plat->port_id = UART_PORT_ID(plat->reg_base);
	ret = uart_clock_config(plat);
	if (ret)
		printf("UART clock config failed %d\n", ret);

	return;
}

void board_nand_init(void)
{
#ifdef CONFIG_QPIC_SERIAL
	/* check for nand node in dts
	 * if nand node in dts is disabled then
	 * simply return from here without
	 * initializing
	 */
	int node;
	node = fdt_path_offset(gd->fdt_blob, "/nand-controller");
	if (!fdtdec_get_is_enabled(gd->fdt_blob, node)) {
		printf("QPIC: disabled, skipping initialization\n");
	} else {
		qpic_nand_init(NULL);
	}
#endif

#ifdef CONFIG_QCA_SPI
	int gpio_node;
	gpio_node = fdt_path_offset(gd->fdt_blob, "/spi/spi_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
		spi_clock_init(0);
		ipq_spi_init(CONFIG_IPQ_SPI_NOR_INFO_IDX);
	}
#endif
}

#ifdef CONFIG_QCA_MMC
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

void board_mmc_deinit(void)
{
/*
 * since we do not have misc register in ipq9574
 * so simply return from this function
 */
	return;
}

int board_mmc_init(bd_t *bis)
{
	int node;
	int ret = 0;
	int gpio_node;

	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	node = fdt_path_offset(gd->fdt_blob, "mmc");
	if (node < 0) {
		printf("sdhci: Node Not found, skipping initialization\n");
		return -1;
	}

	gpio_node = fdt_path_offset(gd->fdt_blob, "/sdhci@7804000/mmc_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
	}

	mmc_host.ioaddr = (void *)MSM_SDC1_SDHCI_BASE;
	mmc_host.voltages = MMC_VDD_165_195;
	mmc_host.version = SDHCI_SPEC_300;
	mmc_host.cfg.part_type = PART_TYPE_EFI;
	mmc_host.quirks = SDHCI_QUIRK_BROKEN_VOLTAGE;

	emmc_clock_reset();
	udelay(10);
	emmc_clock_init();

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

#ifdef CONFIG_USB_XHCI_IPQ
void board_usb_deinit(int id)
{
	int nodeoff;
	char node_name[8];

	if(readl(EUD_EUD_EN2))
	/*
	 * Eud enable skipping deinit part
	 */
		return;

	snprintf(node_name, sizeof(node_name), "usb%d", id);
	nodeoff = fdt_path_offset(gd->fdt_blob, node_name);
	if (fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0))
		return;

	/* Enable USB PHY Power down */
	setbits_le32(USB30_PHY_1_QUSB2PHY_BASE + 0xB4, 0x1);

	usb_clock_deinit();

	/* GCC_QUSB2_0_PHY_BCR */
	set_mdelay_clearbits_le32(GCC_QUSB2_0_PHY_BCR, 0x1, 10);
	/* GCC_USB0_PHY_BCR */
	set_mdelay_clearbits_le32(GCC_USB0_PHY_BCR, 0x1, 10);
	/* GCC Reset USB BCR */
	set_mdelay_clearbits_le32(GCC_USB_BCR, 0x1, 10);
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

	boot_clk_ctl = (u32 *)GCC_USB_0_BOOT_CLOCK_CTL;
	usb_bcr = (u32 *)GCC_USB_BCR;
	qusb2_phy_bcr = (u32 *)GCC_QUSB2_0_PHY_BCR;

	/* Disable USB Boot Clock */
	clrbits_le32(boot_clk_ctl, 0x0);

	/* GCC Reset USB BCR */
	set_mdelay_clearbits_le32(usb_bcr, 0x1, 10);

	/* GCC_QUSB2_PHY_BCR */
	setbits_le32(qusb2_phy_bcr, 0x1);

	/* GCC_USB0_PHY_BCR */
	setbits_le32(GCC_USB0_PHY_BCR, 0x1);
	setbits_le32(GCC_USB3PHY_0_PHY_BCR, 0x1);
	mdelay(10);
	clrbits_le32(GCC_USB3PHY_0_PHY_BCR, 0x1);
	clrbits_le32(GCC_USB0_PHY_BCR, 0x1);

	/* Config user control register */
	writel(0x0a40c010, USB30_1_GUCTL);
	writel(0x0a87f0a0, USB30_1_FLADJ);

	/* GCC_QUSB2_0_PHY_BCR */
	clrbits_le32(qusb2_phy_bcr, 0x1);
	mdelay(10);

	usb_init_hsphy((u32 *)USB30_PHY_1_QUSB2PHY_BASE);
	usb_init_ssphy((u32 *)USB30_PHY_1_USB3PHY_AHB2PHY_BASE);
}

int ipq_board_usb_init(void)
{
	int i, nodeoff;
	char node_name[8];

	if(readl(EUD_EUD_EN2)) {
		printf("USB: EUD Enable, skipping initialization\n");
		return 0;
	}

	for (i = 0; i < CONFIG_USB_MAX_CONTROLLER_COUNT; i++) {
		snprintf(node_name, sizeof(node_name), "usb%d", i);
		nodeoff = fdt_path_offset(gd->fdt_blob, node_name);
		if (!fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0)) {
			usb_clock_init(i);
			usb_init_phy(i);
		} else {
			/* Config user control register */
			writel(0x0c80c010, USB30_1_GUCTL);
		}
	}
	return 0;
}
#endif

int ipq_validate_qfrom_fuse(unsigned int reg_add, int pos)
{
	return (readl(reg_add) & (1 << pos));
}

int is_uniphy_enabled(int uniphy_index)
{
	int bit = 0;

	switch(uniphy_index) {
		case 0:
			bit = UNIPHY_0_DISABLE_BIT;
			break;
		case 1:
			bit = UNIPHY_1_DISABLE_BIT;
			break;
		case 2:
			bit = UNIPHY_2_DISABLE_BIT;
			break;
		default:
			printf("In ipq9574: Max 3 Uniphy's can be supported\n");
			break;
	}
	return !ipq_validate_qfrom_fuse(
			QFPROM_CORR_FEATURE_CONFIG_ROW2_MSB, bit);
}

#ifdef CONFIG_PCI_IPQ
int ipq_sku_pci_validation(int id)
{
	int pos = 0;

	switch(id){
	case 0:
		pos = PCIE_0_CLOCK_DISABLE_BIT;
	break;
	case 1:
		pos = PCIE_1_CLOCK_DISABLE_BIT;
	break;
	case 2:
		pos = PCIE_2_CLOCK_DISABLE_BIT;
	break;
	case 3:
		pos = PCIE_3_CLOCK_DISABLE_BIT;
	break;
	}

	return ipq_validate_qfrom_fuse(
			QFPROM_CORR_FEATURE_CONFIG_ROW1_MSB, pos);
}

void board_pci_init(int id)
{
	int node, gpio_node;
	char name[16];

	snprintf(name, sizeof(name), "pci%d", id);
	node = fdt_path_offset(gd->fdt_blob, name);
	if (node < 0) {
		printf("Could not find PCI%d in device tree\n", id);
		return;
	}

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);

	pcie_v2_clock_init(id);

	return;
}

static void pci_gpio_low(int offset)
{
	struct qca_gpio_config gpio_config;

	for (offset = fdt_first_subnode(gd->fdt_blob, offset); offset > 0;
		offset = fdt_next_subnode(gd->fdt_blob, offset)) {
		gpio_config.gpio        = fdtdec_get_uint(gd->fdt_blob,
							offset, "gpio", 0);
		gpio_set_value(gpio_config.gpio, GPIO_OUT_LOW);
	}
}

void board_pci_deinit()
{
	int node, gpio_node, i, err, is_x2;
	char name[16];
	struct fdt_resource parf;
	struct fdt_resource pci_phy;

	for (i = 0; i < PCI_MAX_DEVICES; i++) {
		snprintf(name, sizeof(name), "pci%d", i);
		node = fdt_path_offset(gd->fdt_blob, name);
		if (node < 0) {
			printf("Could not find PCI%d in device tree\n", i);
			continue;
		}
		err = fdt_get_named_resource(gd->fdt_blob, node, "reg",
				"reg-names", "parf", &parf);

		writel(0x0, parf.start + 0x358);
		writel(0x1, parf.start + 0x40);

		err = fdt_get_named_resource(gd->fdt_blob, node, "reg",
				"reg-names", "pci_phy", &pci_phy);
		if (err < 0)
			continue;

		if ((i == 0) || (i == 1))
			is_x2 = 0;
		else
			is_x2 = 1;

		writel(0x1, pci_phy.start + (0x800 + (0x800 * is_x2)));
		writel(0x0, pci_phy.start + (0x804 + (0x800 * is_x2)));

		gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
		if (gpio_node >= 0)
			pci_gpio_low(gpio_node);

		pcie_v2_clock_deinit(i);
	}

	return ;
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

/**
 * Set the uuid in bootargs variable for mounting rootfilesystem
 */
#ifdef CONFIG_QCA_MMC
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag)
{
	int ret, len;
	block_dev_desc_t *blk_dev;
	disk_partition_t disk_info;

	if (mmc_init(mmc_host.mmc)) {
		/* The HS mode command(cmd6) is getting timed out and mmc is
		 * not getting initialized properly. So do a reset again.
		 */
		if (mmc_init(mmc_host.mmc)) {
			printf("\n MMC re-init failed, might be cmd6 timeout\n");
			return -1;
		}
	}
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

#ifdef CONFIG_IPQ9574_EDMA
int get_sfp_gpio(int sfp_gpio[2])
{
	int sfp_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		sfp_gpio_cnt = fdtdec_get_uint(gd->fdt_blob, node, "sfp_gpio_cnt", -1);
		if (sfp_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node, "sfp_gpio",
						  (u32 *)sfp_gpio, sfp_gpio_cnt);
			if (res >= 0)
				return sfp_gpio_cnt;
		}
	}

	return res;
}



int get_aquantia_gpio(int aquantia_gpio[2])
{
	int aquantia_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		aquantia_gpio_cnt = fdtdec_get_uint(gd->fdt_blob, node, "aquantia_gpio_cnt", -1);
		if (aquantia_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node, "aquantia_gpio",
						  (u32 *)aquantia_gpio, aquantia_gpio_cnt);
			if (res >= 0)
				return aquantia_gpio_cnt;
		}
	}

	return res;
}

int get_qca808x_gpio(int qca808x_gpio[2])
{
	int qca808x_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		qca808x_gpio_cnt = fdtdec_get_uint(gd->fdt_blob, node, "qca808x_gpio_cnt", -1);
		if (qca808x_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node, "qca808x_gpio",
						  (u32 *)qca808x_gpio, qca808x_gpio_cnt);
			if (res >= 0)
				return qca808x_gpio_cnt;
		}
	}

	return res;
}

int get_qca807x_gpio(int qca807x_gpio[2])
{
	int qca807x_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		qca807x_gpio_cnt = fdtdec_get_uint(gd->fdt_blob, node, "qca807x_gpio_cnt", -1);
		if (qca807x_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node, "qca807x_gpio",
						  (u32 *)qca807x_gpio, qca807x_gpio_cnt);
			if (res >= 0)
				return qca807x_gpio_cnt;
		}
	}

	return res;
}

void sfp_reset_init(void)
{
	int sfp_gpio[2] = {-1, -1}, sfp_gpio_cnt, i;
	unsigned int *sfp_gpio_base;
	uint32_t cfg;

	sfp_gpio_cnt = get_sfp_gpio(sfp_gpio);
	if (sfp_gpio_cnt >= 1) {
		for (i = 0; i < sfp_gpio_cnt; i++) {
			if (sfp_gpio[i] >= 0) {
				sfp_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(sfp_gpio[i]);
				cfg = GPIO_OE | GPIO_DRV_8_MA | GPIO_PULL_UP;
				writel(cfg, sfp_gpio_base);
			}
		}
	}
}

void aquantia_phy_reset_init(void)
{
	int aquantia_gpio[2] = {-1, -1}, aquantia_gpio_cnt, i;
	unsigned int *aquantia_gpio_base;
	uint32_t cfg;

	if (!aq_phy_initialised) {
		aquantia_gpio_cnt = get_aquantia_gpio(aquantia_gpio);
		if (aquantia_gpio_cnt >= 1) {
			for (i = 0; i < aquantia_gpio_cnt; i++) {
				if (aquantia_gpio[i] >= 0) {
					aquantia_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(aquantia_gpio[i]);
					cfg = GPIO_OE | GPIO_DRV_8_MA | GPIO_PULL_UP;
					writel(cfg, aquantia_gpio_base);
				}
			}
		}
		aq_phy_initialised = 1;
	}
}

void qca808x_phy_reset_init(void)
{
	int qca808x_gpio[2] = {-1, -1}, qca808x_gpio_cnt, i;
	unsigned int *qca808x_gpio_base;
	uint32_t cfg;

	qca808x_gpio_cnt = get_qca808x_gpio(qca808x_gpio);
	if (qca808x_gpio_cnt >= 1) {
		for (i = 0; i < qca808x_gpio_cnt; i++) {
			if (qca808x_gpio[i] >= 0) {
				qca808x_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(qca808x_gpio[i]);
				cfg = GPIO_OE | GPIO_DRV_8_MA | GPIO_PULL_UP;
				writel(cfg, qca808x_gpio_base);
			}
		}
	}
}

void qca807x_phy_reset_init(void)
{
	int qca807x_gpio[2] = {-1, -1}, qca807x_gpio_cnt, i;
	unsigned int *qca807x_gpio_base;
	uint32_t cfg;

	qca807x_gpio_cnt = get_qca807x_gpio(qca807x_gpio);
	if (qca807x_gpio_cnt >= 1) {
		for (i = 0; i < qca807x_gpio_cnt; i++) {
			if (qca807x_gpio[i] >=0) {
				qca807x_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(qca807x_gpio[i]);
				cfg = GPIO_OE | GPIO_DRV_8_MA | GPIO_PULL_UP;
				writel(cfg, qca807x_gpio_base);
			}
		}
	}
}

void aquantia_phy_reset_init_done(void)
{
	int aquantia_gpio[2] = {-1, -1}, aquantia_gpio_cnt, i;

	aquantia_gpio_cnt = get_aquantia_gpio(aquantia_gpio);
	if (aquantia_gpio_cnt >= 1) {
		for (i = 0; i < aquantia_gpio_cnt; i++)
			gpio_set_value(aquantia_gpio[i], 0x1);
	}
}

void qca808x_phy_reset_init_done(void)
{
	int qca808x_gpio[2] = {-1, -1}, qca808x_gpio_cnt, i;

	qca808x_gpio_cnt = get_qca808x_gpio(qca808x_gpio);
	if (qca808x_gpio_cnt >= 1) {
		for (i = 0; i < qca808x_gpio_cnt; i++)
			gpio_set_value(qca808x_gpio[i], 0x1);
	}
}

void qca807x_phy_reset_init_done(void)
{
	int qca807x_gpio[2] = {-1, -1}, qca807x_gpio_cnt, i;

	qca807x_gpio_cnt = get_qca807x_gpio(qca807x_gpio);
	if (qca807x_gpio_cnt >= 1) {
		for (i = 0; i < qca807x_gpio_cnt; i++)
			gpio_set_value(qca807x_gpio[i], 0x1);
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
	int mdc_mdio_gpio[2] = {-1, -1}, mdc_mdio_gpio_cnt, i;
	unsigned int *mdc_mdio_gpio_base;
	uint32_t cfg;

	mdc_mdio_gpio_cnt = get_mdc_mdio_gpio(mdc_mdio_gpio);
	if (mdc_mdio_gpio_cnt >= 1) {
		for (i = 0; i < mdc_mdio_gpio_cnt; i++) {
			if (mdc_mdio_gpio[i] >=0) {
				mdc_mdio_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(mdc_mdio_gpio[i]);
				if (i == 0) {
					cfg = GPIO_DRV_8_MA | MDC_MDIO_FUNC_SEL | GPIO_NO_PULL;
					writel(cfg, mdc_mdio_gpio_base);
				} else {
					cfg = GPIO_DRV_8_MA | MDC_MDIO_FUNC_SEL | GPIO_PULL_UP;
					writel(cfg, mdc_mdio_gpio_base);
				}
			}
		}
	}
}

void nssnoc_init(void){
	unsigned int gcc_nssnoc_memnoc_bfdcd_cmd_rcgr_addr = 0x1817004;
	unsigned int gcc_qdss_at_cmd_rcgr_addr = 0x182D004;

	writel(0x102, gcc_nssnoc_memnoc_bfdcd_cmd_rcgr_addr + 4);
	writel(0x1, gcc_nssnoc_memnoc_bfdcd_cmd_rcgr_addr);

	writel(0x109, gcc_qdss_at_cmd_rcgr_addr + 4);
	writel(0x1, gcc_qdss_at_cmd_rcgr_addr);

	/* Enable required NSSNOC clocks */
	writel(readl(GCC_MEM_NOC_NSSNOC_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_MEM_NOC_NSSNOC_CLK);

	writel(readl(GCC_NSSCFG_CLK) | GCC_CBCR_CLK_ENABLE, GCC_NSSCFG_CLK);

	writel(readl(GCC_NSSNOC_ATB_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_ATB_CLK);

	writel(readl(GCC_NSSNOC_MEM_NOC_1_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_MEM_NOC_1_CLK);

	writel(readl(GCC_NSSNOC_MEMNOC_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_MEMNOC_CLK);

	writel(readl(GCC_NSSNOC_QOSGEN_REF_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_QOSGEN_REF_CLK);

	writel(readl(GCC_NSSNOC_TIMEOUT_REF_CLK) | GCC_CBCR_CLK_ENABLE,
		GCC_NSSNOC_TIMEOUT_REF_CLK);
}

void frequency_init(void)
{
	unsigned int nss_cc_cfg_addr;
	unsigned int gcc_uniphy_sys_addr;
	unsigned int gcc_pcnoc_addr;
	unsigned int gcc_sysnoc_addr;
	unsigned int reg_val;

	/* GCC NSS frequency 100M */
	nss_cc_cfg_addr = 0x39B28104;
	reg_val = readl(nss_cc_cfg_addr + 4);
	reg_val &= ~0x7ff;
	writel(reg_val | 0x20f, nss_cc_cfg_addr + 4);

	reg_val = readl(nss_cc_cfg_addr);
	writel(reg_val | 0x1, nss_cc_cfg_addr);

	/* GCC CC PPE frequency 353M */
	reg_val = readl(NSS_CC_PPE_FREQUENCY_RCGR + 4);
	reg_val &= ~0x7ff;
	writel(reg_val | 0x101, NSS_CC_PPE_FREQUENCY_RCGR + 4);

	reg_val = readl(NSS_CC_PPE_FREQUENCY_RCGR);
	writel(reg_val | 0x1, NSS_CC_PPE_FREQUENCY_RCGR);

	/* Uniphy SYS 24M */
	gcc_uniphy_sys_addr = 0x1817090;
	reg_val = readl(gcc_uniphy_sys_addr + 4);
	reg_val &= ~0x7ff;
	writel(reg_val | 0x1, gcc_uniphy_sys_addr + 4);
	/* Update Config */
	reg_val = readl(gcc_uniphy_sys_addr);
	writel(reg_val | 0x1, gcc_uniphy_sys_addr);

	/* PCNOC frequency for Uniphy AHB 100M */
	gcc_pcnoc_addr = 0x1831004;
	reg_val = readl(gcc_pcnoc_addr + 4);
	reg_val &= ~0x7ff;
	writel(reg_val | 0x10F, gcc_pcnoc_addr + 4);
	/* Update Config */
	reg_val = readl(gcc_pcnoc_addr);
	writel(reg_val | 0x1, gcc_pcnoc_addr);

	/* SYSNOC frequency 343M */
	gcc_sysnoc_addr = 0x182E004;
	reg_val = readl(gcc_sysnoc_addr + 4);
	reg_val &= ~0x7ff;
	writel(reg_val | 0x206, gcc_sysnoc_addr + 4);
	/* Update Config */
	reg_val = readl(gcc_sysnoc_addr);
	writel(reg_val | 0x1, gcc_sysnoc_addr);
}

void fixed_nss_csr_clock_init(void)
{
	unsigned int gcc_nss_csr_addr;
	unsigned int reg_val;

	/* NSS CSR and NSSNOC CSR Clock init */
	gcc_nss_csr_addr = 0x39B281D0;
	reg_val = readl(gcc_nss_csr_addr);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, gcc_nss_csr_addr);
	/* NSSNOC CSR */
	reg_val = readl(gcc_nss_csr_addr + 0x4);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, gcc_nss_csr_addr + 0x4);
}

void fixed_sys_clock_init(void)
{
	unsigned int reg_val;

	/* SYS Clock init */
	/* Enable AHB and SYS clk of CMN */
	reg_val = readl(GCC_CMN_BLK_ADDR + GCC_CMN_BLK_AHB_CBCR_OFFSET);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
	       GCC_CMN_BLK_ADDR + GCC_CMN_BLK_AHB_CBCR_OFFSET);

	reg_val = readl(GCC_CMN_BLK_ADDR + GCC_CMN_BLK_SYS_CBCR_OFFSET);
	writel(reg_val | GCC_CBCR_CLK_ENABLE,
	       GCC_CMN_BLK_ADDR + GCC_CMN_BLK_SYS_CBCR_OFFSET);
}

void fixed_uniphy_clock_init(void)
{
	int i;
	unsigned int reg_val;

	/* Uniphy AHB AND SYS CBCR init */
	for (i = 0; i < 3; i++) {
		reg_val = readl(GCC_UNIPHY_SYS_ADDR + i*0x10);
		writel(reg_val | GCC_CBCR_CLK_ENABLE,
		      GCC_UNIPHY_SYS_ADDR + i*0x10);

		reg_val = readl((GCC_UNIPHY_SYS_ADDR + 0x4) + i*0x10);
		writel(reg_val | GCC_CBCR_CLK_ENABLE,
		      (GCC_UNIPHY_SYS_ADDR + 0x4) + i*0x10);
	}
}

void port_mac_clock_init(void)
{
	int i;
	unsigned int reg_val;

	/* Port Mac Clock init */
	for (i = 0; i < 6; i++) {
		reg_val = readl(GCC_PORT_MAC_ADDR + i*0x4);
		writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_PORT_MAC_ADDR + i*0x4);
	}
}

void cfg_clock_init(void)
{
	int i;
	unsigned int reg_val;

	/* CFG Clock init */
	for (i = 0; i < 8; i++) {
		reg_val = readl(NSS_CC_PPE_SWITCH_CFG_ADDR + i*0x4);
		writel(reg_val | GCC_CBCR_CLK_ENABLE,
		       NSS_CC_PPE_SWITCH_CFG_ADDR + i*0x4);
	}
	reg_val = readl(NSS_CC_PPE_SWITCH_BTQ_ADDR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, NSS_CC_PPE_SWITCH_BTQ_ADDR);
}

void mdio_clock_init(void)
{
	unsigned int reg_val;

	/* MDIO Clock init */
	reg_val = readl(GCC_MDIO_AHB_CBCR_ADDR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_MDIO_AHB_CBCR_ADDR);
}

void noc_clock_init(void)
{
	unsigned int reg_val;

	/* NOC Clock init */
	reg_val = readl(GCC_NSSNOC_SNOC_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_NSSNOC_SNOC_CBCR);

	reg_val = readl(GCC_NSSNOC_SNOC_1_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_NSSNOC_SNOC_1_CBCR);

	reg_val = readl(GCC_MEM_NOC_SNOC_AXI_CBCR);
	writel(reg_val | GCC_CBCR_CLK_ENABLE, GCC_MEM_NOC_SNOC_AXI_CBCR);
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

void uniphy_clock_enable(enum uniphy_clk_type clk_type, bool enable)
{
	unsigned int reg_val, i;

	i  = clk_type;

	if (clk_type <= NSS_PORT6_TX_CLK_E) {
		reg_val = readl(NSS_CC_PORT1_RX_CBCR + i*0x4);
		if (enable)
			reg_val |= GCC_CBCR_CLK_ENABLE;
		else
			reg_val &= ~GCC_CBCR_CLK_ENABLE;
		writel(reg_val, (NSS_CC_PORT1_RX_CBCR + i*0x4));
	} else {
		if (i >= UNIPHY1_PORT5_RX_CLK_E) {
			i = i - 2;
		}
		reg_val = readl(NSS_CC_UNIPHY_PORT1_RX_CBCR + (i - 12)*0x4);
		if (enable)
			reg_val |= GCC_CBCR_CLK_ENABLE;
		else
			reg_val &= ~GCC_CBCR_CLK_ENABLE;
		writel(reg_val, (NSS_CC_UNIPHY_PORT1_RX_CBCR + (i - 12)*0x4));
	}
}

void uniphy_clk_init(bool enable)
{
	int i;
	/* Uniphy clock enable */
	for (i = NSS_PORT1_RX_CLK_E; i < PORT5_RX_SRC_E; i++)
		uniphy_clock_enable(i, enable);
}

void cmnblk_init(void)
{
	uint32_t gcc_pll_base, reg_val;

	gcc_pll_base = CMN_BLK_ADDR;
	reg_val = readl(gcc_pll_base + 4);
	reg_val = (reg_val & FREQUENCY_MASK) | INTERNAL_48MHZ_CLOCK;
	writel(reg_val, gcc_pll_base + 0x4);
	reg_val = readl(gcc_pll_base);
	reg_val = reg_val | 0x40;
	writel(reg_val, gcc_pll_base);
	mdelay(1);
	reg_val = reg_val & (~0x40);
	writel(reg_val, gcc_pll_base);
	mdelay(1);
	writel(0xbf, gcc_pll_base);
	mdelay(1);
	writel(0xff, gcc_pll_base);
	mdelay(1);
}

void uniphy_port5_clock_source_set(void)
{
	int reg_val, reg_val1, node, mode;

	reg_val = readl(NSS_CC_PORT_SPEED_DIVIDER + 0x64);
	reg_val1 = readl(NSS_CC_PORT_SPEED_DIVIDER + 0x70);

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node < 0) {
		printf("\nError: ess-switch not specified in dts");
		return;
	}
	mode = fdtdec_get_uint(gd->fdt_blob, node, "switch_mac_mode1", -1);
	if (mode < 0) {
		printf("\nError: switch_mac_mode1 not specified in dts");
		return;
	}
	if (mode == PORT_WRAPPER_MAX) { /* PORT_WRAPPER_MAX */
		reg_val |= 0x200;
		reg_val1 |= 0x300;
	} else {
		reg_val |= 0x400;
		reg_val1 |= 0x500;
	}

	writel(reg_val, NSS_CC_PORT_SPEED_DIVIDER + 0x64);
	writel(0x1, NSS_CC_PORT_SPEED_DIVIDER + 0x60);
	writel(reg_val1, NSS_CC_PORT_SPEED_DIVIDER + 0x70);
	writel(0x1, NSS_CC_PORT_SPEED_DIVIDER + 0x6c);
}

void nss_ppe_reset(void)
{
	unsigned int reg_val;

	reg_val = readl(NSS_CC_PPE_RESET_ADDR);
	writel(reg_val | 0x1e0000, NSS_CC_PPE_RESET_ADDR);
	mdelay(500);
	writel(reg_val & (~0x1e0000), NSS_CC_PPE_RESET_ADDR);
	mdelay(100);
}

void bring_phy_out_of_reset(void)
{
	qca807x_phy_reset_init();
	aquantia_phy_reset_init();
	qca808x_phy_reset_init();
	sfp_reset_init();
	mdelay(500);
	qca807x_phy_reset_init_done();
	aquantia_phy_reset_init_done();
	qca808x_phy_reset_init_done();
	mdelay(500);
}

void eth_clock_init(void)
{
	nssnoc_init();

	fixed_clock_init();

	uniphy_clk_init(true);

	cmnblk_init();

	uniphy_port5_clock_source_set();
}

void ipq9574_eth_initialize(void)
{
	eth_clock_init();

	nss_ppe_reset();

	set_function_select_as_mdc_mdio();

	bring_phy_out_of_reset();
}

int board_eth_init(bd_t *bis)
{
	int ret = 0;

	ipq9574_eth_initialize();

	ret = ipq9574_edma_init(NULL);
	if (ret != 0)
		printf("%s: ipq9574_edma_init failed : %d\n", __func__, ret);

	return ret;
}
#endif

unsigned long timer_read_counter(void)
{
	return 0;
}

void reset_crashdump(void)
{
	unsigned int ret = 0;
	unsigned int cookie = 0;

	cookie = ipq_read_tcsr_boot_misc();
	qca_scm_sdi();
	if (cookie & DLOAD_ENABLE) {
		cookie |= CRASHDUMP_RESET;
	}
	cookie &= DLOAD_DISABLE;
	ret = qca_scm_dload(cookie);
	if (ret)
		printf ("Error in reseting the Magic cookie\n");
	return;
}

void psci_sys_reset(void)
{
	__invoke_psci_fn_smc(PSCI_RESET_SMC_ID, 0, 0, 0);
}

void reset_cpu(unsigned long a)
{
	reset_crashdump();

	psci_sys_reset();

	while (1);
}

void power_cycle_sdx(void)
{
	int node, power_on_gpio = -1, reset_gpio = -1;
	int e911_gpio = -1;
	unsigned int *power_on_gpio_base, *reset_gpio_base;

	unsigned int machid = gd->bd->bi_arch_number;
	if (machid != 0x8050201 && machid != 0x8051201)
		return;

	node = fdt_path_offset(gd->fdt_blob, "/sdx-gpio");
	if (node >= 0) {
		power_on_gpio = fdtdec_get_uint(gd->fdt_blob, node, "power_on", -1);
		reset_gpio = fdtdec_get_uint(gd->fdt_blob, node, "reset", -1);
		e911_gpio = fdtdec_get_uint(gd->fdt_blob, node, "e911", -1);
	}

	if (power_on_gpio > 0 && reset_gpio > 0 &&
		(e911_gpio <= 0 || !gpio_get_value(e911_gpio))) {
		power_on_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(power_on_gpio);
		reset_gpio_base = (unsigned int *)GPIO_CONFIG_ADDR(reset_gpio);
		writel(0x2c1, power_on_gpio_base);
		writel(0x2c1, reset_gpio_base);
		gpio_set_value(power_on_gpio, 0x1);
		gpio_set_value(reset_gpio, 0x1);
		mdelay(1000);
		gpio_set_value(power_on_gpio, 0x0);
		gpio_set_value(reset_gpio, 0x0);
	}
}

void reset_board(void)
{
	run_command("reset", 0);
}

void set_flash_secondary_type(qca_smem_flash_info_t *smem)
{
	return;
};

const char *rsvd_node = "/reserved-memory";
const char *del_node[] = {"uboot",
			  "sbl",
			  NULL};
const add_node_t add_fdt_node[] = {{}};

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
	{ "UNAME.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "CPU_INFO.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "DMESG.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "PT.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "WLAN_MOD.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
};
int dump_entries_n = ARRAY_SIZE(dumpinfo_n);


int ipq_read_tcsr_boot_misc(void)
{
	u32 *dmagic = TCSR_BOOT_MISC_REG;
	return *dmagic;
}

int apps_iscrashed_crashdump_disabled(void)
{
	u32 dmagic = ipq_read_tcsr_boot_misc();

	if (dmagic & DLOAD_DISABLED) {
		power_cycle_sdx();
		return 1;
	}

	return 0;
}

int apps_iscrashed(void)
{
	u32 dmagic = ipq_read_tcsr_boot_misc();

	if (dmagic & DLOAD_MAGIC_COOKIE) {
		power_cycle_sdx();
		return 1;
	}

	return 0;
}


__weak int ipq_get_tz_version(char *version_name, int buf_size)
{
	return 1;
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

unsigned int get_dts_machid(unsigned int machid)
{
	switch (machid)
	{
		case MACH_TYPE_IPQ9574_EMULATION:
			return MACH_TYPE_IPQ9574_EMULATION;
		case MACH_TYPE_IPQ9574_AP_AL02_C5:
			return MACH_TYPE_IPQ9574_AP_AL02_C4;
		case MACH_TYPE_IPQ9574_AP_AL02_C6:
			return MACH_TYPE_IPQ9574_AP_AL02_C1;
		case MACH_TYPE_IPQ9574_AP_AL02_C11:
			return MACH_TYPE_IPQ9574_AP_AL02_C4;
		case MACH_TYPE_IPQ9574_AP_AL02_C12:
                        return MACH_TYPE_IPQ9574_AP_AL02_C4;
		case MACH_TYPE_IPQ9574_AP_AL02_C14:
                        return MACH_TYPE_IPQ9574_AP_AL02_C8;
		case MACH_TYPE_IPQ9574_AP_AL02_C15:
                        return MACH_TYPE_IPQ9574_AP_AL02_C1;
		case MACH_TYPE_IPQ9574_AP_AL02_C16:
                        return MACH_TYPE_IPQ9574_AP_AL02_C13;
		case MACH_TYPE_IPQ9574_AP_AL02_C20:
			return MACH_TYPE_IPQ9574_AP_AL02_C13;
		case MACH_TYPE_IPQ9574_AP_AL03_C2:
			return MACH_TYPE_IPQ9574_AP_AL03_C1;
		default:
			return machid;
	}
}

void ipq_uboot_fdt_fixup(void)
{
	init_config_list();
	switch (gd->bd->bi_arch_number)
	{
		case MACH_TYPE_IPQ9574_EMULATION:
			add_config_entry("config@emulation-fbc");
			add_config_entry("config-emulation-fbc");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C5:
			add_config_entry("config@al02-c5");
			add_config_entry("config-al02-c5");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C6:
			add_config_entry("config@al02-c6");
			add_config_entry("config-al02-c6");
			add_config_entry("config@rdp449");
			add_config_entry("config-rdp449");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C11:
			add_config_entry("config@al02-c11");
			add_config_entry("config-al02-c11");
			add_config_entry("config@rdp455");
			add_config_entry("config-rdp455");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C12:
			add_config_entry("config@al02-c12");
			add_config_entry("config-al02-c12");
			add_config_entry("config@rdp455");
			add_config_entry("config-rdp455");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C14:
			add_config_entry("config-al02-c14");
			add_config_entry("config@al02-c14");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C15:
			add_config_entry("config@al02-c15");
			add_config_entry("config-al02-c15");
			add_config_entry("config@rdp457");
			add_config_entry("config-rdp457");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C16:
			add_config_entry("config@al02-c16");
			add_config_entry("config-al02-c16");
			add_config_entry("config@rdp456");
			add_config_entry("config-rdp456");
			break;
		case MACH_TYPE_IPQ9574_AP_AL02_C20:
			add_config_entry("config@al02-c20");
			add_config_entry("config-al02-c20");
			add_config_entry("config@rdp467");
			add_config_entry("config-rdp467");
			break;
		case MACH_TYPE_IPQ9574_AP_AL03_C2:
			add_config_entry("config@al03-c2");
			add_config_entry("config-al03-c2");
			add_config_entry("config@rdp458");
			add_config_entry("config-rdp458");
			break;
		default:
			add_config_list_from_fdt();
	}
	return;
}

void fdt_fixup_for_atf(void *blob)
{
	if (fdt_path_offset(blob, "/soc/dma@704000") >= 0) {
		parse_fdt_fixup("/soc/dma@704000%qcom,controlled-remotely%0",
				blob);
		parse_fdt_fixup("/soc/dma@704000%qti,config-pipe-trust-reg%2",
				blob);
	}
}

int do_dpr(cmd_tbl_t *cmdtp, int flag, int argc, char *const argv[])
{
	int ret;
	char *loadaddr;
	uint32_t dpr_status = 0;
	struct dpr {
		uint32_t address;
		uint32_t status;
	} dpr;

	if (argc > 2) {
		return CMD_RET_USAGE;
	}

	if (argc == 2){
		dpr.address = simple_strtoul(argv[1], NULL, 16);
	} else {
		loadaddr = getenv("fileaddr");

		if (loadaddr == NULL) {
			printf("No Arguments provided\n");
			printf("Command format: dpr_execute <address>\n");
			return CMD_RET_USAGE;
		}
		if (loadaddr != NULL)
			dpr.address = simple_strtoul(loadaddr, NULL, 16);
	}

	dpr.status = (uint32_t)&dpr_status;

	ret = qca_scm_dpr(SCM_SVC_FUSE, TME_DPR_PROCESSING,
			&dpr, sizeof(dpr));

	if (ret || dpr_status){
		printf("%s: Error in DPR Processing (%d, %d)\n",
			__func__, ret, dpr_status);
	} else {
		printf("DPR Process Successful\n");
	}
	return ret;
}

U_BOOT_CMD(dpr_execute, 2, 0, do_dpr,
		"Debug Policy Request processing\n",
		"dpr_execute [address] - Processing dpr\n");

void uart_wait_tx_empty(void)
{
        ipq_serial_wait_tx_empty();
}
