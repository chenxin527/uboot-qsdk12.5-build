/*
 * Copyright (c) 2015-2017 The Linux Foundation. All rights reserved.
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
#include <asm/io.h>
#include <asm/errno.h>
#include <environment.h>
#include <configs/ipq40xx.h>
#include <nand.h>
#include <part.h>
#include <asm/arch-qca-common/smem.h>
#include <asm/arch-ipq40xx/clk.h>
#include <asm/arch-qca-common/scm.h>
#include <asm/arch-qca-common/qpic_nand.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/iomap.h>
#include <jffs2/load_kernel.h>
#include <fdtdec.h>
#include <asm/arch-qca-common/uart.h>
#include "fdt_info.h"
#include <asm/arch-ipq40xx/ess/ipq40xx_edma.h>
#include <phy.h>
#include "ipq40xx_edma_eth.h"
#include <asm/arch-qca-common/qca_common.h>
#include "ipq_phy.h"
#include <sdhci.h>

#define DLOAD_MAGIC_COOKIE 0x10
#define TCSR_USB_HSPHY_DEVICE_MODE		0x00C700E7

#define TCSR_SOC_HW_VERSION_REG 0x194D000

DECLARE_GLOBAL_DATA_PTR;

#define CPU0_APCS_SAW2_VCTL	0x0b089014
#define CPU0_APCS_CPU_PWR_CTL	0x0b088004

#define CPU_APCS_SAW2_VCTL(cpuid) (CPU0_APCS_SAW2_VCTL + (cpuid * 0x10000))
#define CPU_APCS_CPU_PWR_CTL(cpuid) (CPU0_APCS_CPU_PWR_CTL + (cpuid * 0x10000))

#ifndef CONFIG_SDHCI_SUPPORT
qca_mmc mmc_host;
#else
struct sdhci_host mmc_host;
#endif

#define ADSS_AUDIO_RXM_CBCR_REG			0x0770012C
#define ADSS_AUDIO_RXB_CBCR_REG			0x0770010C
#define ADSS_AUDIO_TXB_CBCR_REG			0x0770014C
#define ADSS_AUDIO_SPDIF_CBCR_REG		0x07700154
#define ADSS_AUDIO_SPDIF_DIV2_CBCR_REG		0x0770015C
#define ADSS_AUDIO_TXM_CBCR_REG			0x0770016C
#define ADSS_AUDIO_PCM_CBCR_REG			0x077001AC
#define ADSS_AUDIO_SPDIF_IN_FAST_CBCR_REG	0x077001EC

const char *rsvd_node = "/reserved-memory";
const char *del_node[] = {"rsvd1",
			  "rsvd2",
			  "wifi_dump",
			  NULL};
const add_node_t add_fdt_node[] = {
	{
		.nodename = "rsvd1",
		.val[0] = htonl(RESERVE_ADDRESS_START),
		.val[1] = htonl(RESERVE_ADDRESS_SIZE)
	},
	{
	}
};

struct dumpinfo_t dumpinfo_n[] = {
	{ "EBICS0.BIN", 0x80000000, 0x10000000, 0 },
	{ "EBICS2.BIN", 0xA0000000, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS1.BIN", CONFIG_UBOOT_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS0.BIN", 0x80000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 },
};

int dump_entries_n = ARRAY_SIZE(dumpinfo_n);

struct dumpinfo_t dumpinfo_s[] = {
	{ "EBICS_S0.BIN", CONFIG_QCA_KERNEL_CRASHDUMP_ADDRESS,
	  CONFIG_CPU_CONTEXT_DUMP_SIZE, 0 },
};

int dump_entries_s = ARRAY_SIZE(dumpinfo_s);

extern loff_t board_env_offset;
extern loff_t board_env_range;
extern loff_t board_env_size;

extern int ipq_spi_init(u16);
extern int mmc_env_init(void);
extern void mmc_env_relocate_spec(void);

extern int ipq40xx_edma_init(ipq40xx_edma_board_cfg_t *edma_cfg);
extern int ipq_qca8075_phy_init(struct phy_ops **ops);
extern int ipq40xx_qca8033_phy_init(struct ipq40xx_eth_dev *cfg);
extern void ipq40xx_register_switch(
	int (*sw_init)(struct phy_ops **ops));

void qca_serial_init(struct ipq_serial_platdata *plat)
{
	int node, uart2_node;
	node = fdt_path_offset(gd->fdt_blob, "/serial/serial_gpio");
	if (node < 0) {
		printf("Could not find serial_gpio node\n");
		return;
	}

	if (plat->port_id == 2) {
		uart2_node = fdt_path_offset(gd->fdt_blob, "uart2");
		if (uart2_node < 0) {
			printf("Could not find uart2 node\n");
			return;
		}

		node = fdt_subnode_offset(gd->fdt_blob,
				       uart2_node, "serial_gpio");
		uart2_clock_config(plat->m_value, plat->n_value, plat->d_value);
		writel(1, GCC_BLSP1_UART2_APPS_CBCR);
	}
	qca_gpio_init(node);
}

void reset_crashdump(void)
{
	unsigned int magic_cookie;
	unsigned int clear_info[] =
		{ 1 /* Disable wdog debug */, 0 /* SDI enable*/, };

	magic_cookie = ipq_read_tcsr_boot_misc();
	magic_cookie &= DLOAD_DISABLE;
        scm_call(SCM_SVC_BOOT, SCM_CMD_TZ_CONFIG_HW_FOR_RAM_DUMP_ID,
		 (const void *)&clear_info, sizeof(clear_info), NULL, 0);
        scm_call(SCM_SVC_BOOT, SCM_CMD_TZ_FORCE_DLOAD_ID, &magic_cookie,
		 sizeof(magic_cookie), NULL, 0);
}

void reset_cpu(ulong addr)
{
	/* Clear Debug sw entry register */
	reset_crashdump();
	/* clear ps-hold bit to reset the soc */
	writel(0, GCNT_PSHOLD);
	while (1);
}

void reset_board(void)
{
	run_command("reset", 0);
}

void board_nand_init(void)
{
	int gpio_node;

	qpic_nand_init(NULL);

	gpio_node = fdt_path_offset(gd->fdt_blob, "/spi/spi_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
	}

#ifdef CONFIG_SPI_NAND
	if (fdtdec_get_uint(gd->fdt_blob, 0, "spi_nand_available", 0))
		spi_nand_init();
#endif
	if (fdtdec_get_uint(gd->fdt_blob, 0, "spi_nor_available", 0))
		ipq_spi_init(CONFIG_IPQ_SPI_NOR_INFO_IDX);
}

static void ipq40xx_edma_common_init(void)
{
	writel(1, GCC_ESS_BCR);
	mdelay(10);
	writel(0, GCC_ESS_BCR);
	mdelay(100);

	writel(1, GCC_MDIO_AHB_CBCR);
	writel(MDIO_CTRL_0_DIV(0xff) |
		MDIO_CTRL_0_MDC_MODE |
		MDIO_CTRL_0_GPHY(0xa), MDIO_CTRL_0_REG);
}

int board_eth_init(bd_t *bis)
{
	u32 status;
	int gpio_node, node, len;
	ipq40xx_edma_board_cfg_t* edma_cfg =
		(ipq40xx_edma_board_cfg_t*)malloc(sizeof(ipq40xx_edma_board_cfg_t));

	gpio_node = fdt_path_offset(gd->fdt_blob, "/ess-switch/sw_gpio");
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);

	ipq40xx_edma_common_init();
	switch (gd->bd->bi_arch_number) {
	case MACH_TYPE_IPQ40XX_AP_DK01_1_S1:
	case MACH_TYPE_IPQ40XX_AP_DK01_1_C2:
	case MACH_TYPE_IPQ40XX_AP_DK05_1_C1:
		/* 8075 out of reset */
		mdelay(1);
		gpio_set_value(62, 1);
		ipq40xx_register_switch(ipq_qca8075_phy_init);
		break;
	case MACH_TYPE_IPQ40XX_AP_DK01_1_C1:
		/* 8075 out of reset */
		mdelay(1);
		gpio_set_value(59, 1);
		ipq40xx_register_switch(ipq_qca8075_phy_init);
		break;
	case MACH_TYPE_IPQ40XX_AP_DK04_1_C1:
	case MACH_TYPE_IPQ40XX_AP_DK04_1_C3:
	case MACH_TYPE_IPQ40XX_AP_DK04_1_C4:
	case MACH_TYPE_IPQ40XX_AP_DK04_1_C6:
		/* 8075 out of reset */
		mdelay(1);
		gpio_set_value(47, 1);
		ipq40xx_register_switch(ipq_qca8075_phy_init);
		break;
	case MACH_TYPE_IPQ40XX_AP_DK04_1_C2:
		/* 8075 out of reset */
		mdelay(1);
		gpio_set_value(67, 1);
		ipq40xx_register_switch(ipq_qca8075_phy_init);
		break;
	case MACH_TYPE_IPQ40XX_AP_DK06_1_C1:
		/* 8075 out of reset */
		mdelay(1);
		gpio_set_value(19, 1);
		ipq40xx_register_switch(ipq_qca8075_phy_init);
		break;
	case MACH_TYPE_IPQ40XX_AP_DK07_1_C1:
	case MACH_TYPE_IPQ40XX_AP_DK07_1_C2:
	case MACH_TYPE_IPQ40XX_AP_DK07_1_C3:
	case MACH_TYPE_IPQ40XX_AP_DK07_1_C4:
		/* 8075 out of reset */
		mdelay(1);
		gpio_set_value(41, 1);
		ipq40xx_register_switch(ipq_qca8075_phy_init);
		break;
	default:
		break;
	}
	node = fdt_path_offset(gd->fdt_blob, "/edma_cfg");
	if (node < 0) {
		printf("Error: edma_cfg not specified in dts");
		return -1;
	}
	edma_cfg->unit = fdtdec_get_uint(gd->fdt_blob, node, "unit", 0);
	edma_cfg->phy = fdtdec_get_uint(gd->fdt_blob, node, "phy", 0);
	strcpy((char *)edma_cfg->phy_name, fdt_getprop(gd->fdt_blob, node, "phy_name", &len));

	status = ipq40xx_edma_init(edma_cfg);
	return status;
}

#ifdef CONFIG_QCA_MMC
void emmc_clock_reset(void)
{
	writel(0x1, GCC_SDCC1_BCR);
	udelay(100);
	writel(0x0, GCC_SDCC1_BCR);
}

void emmc_sdhci_init(void)
{
	writel(readl(MSM_SDC1_MCI_HC_MODE) & (~0x1), MSM_SDC1_MCI_HC_MODE);
	writel(readl(MSM_SDC1_BASE) | (1 << 7), MSM_SDC1_BASE); //SW_RST
	udelay(10);
	writel(readl(MSM_SDC1_MCI_HC_MODE) | (0x1), MSM_SDC1_MCI_HC_MODE);
}

int board_mmc_init(bd_t *bis)
{
	int ret = 0;
	int node, gpio_node;
	fdt_addr_t base;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	node = fdt_path_offset(gd->fdt_blob, "/sdhci");
	if (!fdtdec_get_is_enabled(gd->fdt_blob, node)) {
		printf("sdhci: disabled, skipping initialization\n");
		return -1;
	}

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "mmc_gpio");
	qca_gpio_init(gpio_node);

	base = fdtdec_get_addr(gd->fdt_blob, node, "reg");
	if (base == FDT_ADDR_T_NONE) {
		printf("No valid MMC base address found in device tree\n");
		return -1;
        }

#ifndef CONFIG_SDHCI_SUPPORT
	mmc_host.base = base;
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

void board_mmc_deinit(void)
{
	emmc_clock_reset();
	udelay(10);
	emmc_clock_disable();
}
#endif


static void pcie_clock_init(void)
{

	/* Enable PCIE CLKS */
	pcie_clock_enable(GCC_PCIE_SLEEP_CBCR);
	pcie_clock_enable(GCC_PCIE_AXI_M_CBCR);
	pcie_clock_enable(GCC_PCIE_AXI_S_CBCR);
	pcie_clock_enable(GCC_PCIE_AHB_CBCR);

}

void board_pci_init(int id)
{
	int node, gpio_node;
	char name[16];

	sprintf(name, "pci%d", id);
	node = fdt_path_offset(gd->fdt_blob, name);
	if (node < 0) {
		printf("Could not find PCI in device tree\n");
		return;
	}
	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);

	pcie_clock_init();
}

void board_pci_deinit(void)
{

	/* Disable PCIE CLKS */
	pcie_clock_disable(GCC_PCIE_SLEEP_CBCR);
	pcie_clock_disable(GCC_PCIE_AXI_M_CBCR);
	pcie_clock_disable(GCC_PCIE_AXI_S_CBCR);
	pcie_clock_disable(GCC_PCIE_AHB_CBCR);
}

/*
 * The audio block is out of reset by default due to which the
 * audio clock blocks are also turned on. When audio TLMM is
 * enabled in kernel, the clocks will also be available at the
 * pins which causes pop noise during kernel bootup.
 * To avoid this, the clocks are turned off in u-boot.
 */
void disable_audio_clks(void)
{
	writel(0, ADSS_AUDIO_RXM_CBCR_REG);
	writel(0, ADSS_AUDIO_RXB_CBCR_REG);
	writel(0, ADSS_AUDIO_TXB_CBCR_REG);
	writel(0, ADSS_AUDIO_SPDIF_CBCR_REG);
	writel(0, ADSS_AUDIO_SPDIF_DIV2_CBCR_REG);
	writel(0, ADSS_AUDIO_TXM_CBCR_REG);
	writel(0, ADSS_AUDIO_PCM_CBCR_REG);
	writel(0, ADSS_AUDIO_SPDIF_IN_FAST_CBCR_REG);
}

void ipq_fdt_fixup_socinfo(void *blob)
{
	int nodeoff, ret;
	uint32_t cpu_type;
	uint32_t soc_version, soc_version_major, soc_version_minor;
	const char *model = "Qualcomm Technologies, Inc. IPQ4019/AP-DK04.1-C6";

	nodeoff = fdt_path_offset(blob, "/");

	if (nodeoff < 0) {
		printf("ipq: fdt fixup cannot find root node\n");
		return;
	}

	if (gd->bd->bi_arch_number == MACH_TYPE_IPQ40XX_AP_DK04_1_C6)
		ret = fdt_setprop(blob, nodeoff, "model",
			  model, (strlen(model) + 1));

	/* Add "cpu_type" to root node of the devicetree*/
	ret = ipq_smem_get_socinfo_cpu_type(&cpu_type);
	if (!ret) {
		ret = fdt_setprop(blob, nodeoff, "cpu_type",
				  &cpu_type, sizeof(cpu_type));
		if (ret)
			printf("%s: cannot set cpu type %d\n", __func__, ret);
	} else {
		printf("ipq: fdt fixup cannot get socinfo\n");
	}

	ret = ipq_smem_get_socinfo_version((uint32_t *)&soc_version);
	if (!ret) {
		soc_version_major = SOCINFO_VERSION_MAJOR(soc_version);
		soc_version_minor = SOCINFO_VERSION_MINOR(soc_version);

		ret = fdt_setprop(blob, nodeoff, "soc_version_major",
				  &soc_version_major,
				  sizeof(soc_version_major));
		if (ret)
			printf("%s: cannot set soc_version_major %d\n",
			       __func__, soc_version_major);

		ret = fdt_setprop(blob, nodeoff, "soc_version_minor",
				  &soc_version_minor,
				  sizeof(soc_version_minor));
		if (ret)
			printf("%s: cannot set soc_version_minor %d\n",
			       __func__, soc_version_minor);
	} else {
		printf("%s: cannot get soc version\n", __func__);
	}
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_sd_ldo_gpios_toggle(void *blob)
{
	int noff;
	int ret;

	if (mmc_host.mmc != NULL) {
		if (mmc_host.mmc->has_init == 0)
			return;
		else {
			if(IS_SD(mmc_host.mmc))
				return;
		}
	}
	else
		return;

	noff = fdt_path_offset(blob, "/soc/sdhci");
	if (noff < 0) {
		printf("ipq: fdt fixup unable to find node /soc/sdhci\n");
		return;
	}

	/**
	 * In eMMC card, power-on write protection also gets cleared
	 * during sd-ldo toggle in kernel.
	 */
	ret = fdt_delprop(blob, noff, "sd-ldo-gpios");
	if (ret < 0) {
		printf("sdhci: cann't delete sd-ldo-gpios\n");
		return;
	}
}

void ipq_fdt_fixup_usb_device_mode(void *blob)
{
	int nodeoff, ret, i;
	int phy_mode = htonl(TCSR_USB_HSPHY_DEVICE_MODE);
	const char *mode = "peripheral";
	const char *node[] = {"/soc/ssphy", "/soc/hsphy", "/soc/usb3"};
	char *usb_cfg;

	usb_cfg = getenv("usb_mode");
	if (!usb_cfg)
		return;

	if (strcmp(usb_cfg, "device"))
		return;

	nodeoff = fdt_path_offset(blob, "/soc/tcsr");
	if (nodeoff < 0) {
		printf("ipq: fdt fixup unable to find node /soc/tcsr\n");
		return;
	}
	ret = fdt_setprop(blob, nodeoff, "ipq,usb-hsphy-mode-select",
					&phy_mode, sizeof(phy_mode));
	if (ret != 0) {
		printf("ipq: unable to set prop: %d\n", ret);
		return;
	}

	phy_mode = 0;
	for (i = 0; i < (sizeof(node) / sizeof(node[0])); i++) {
		nodeoff = fdt_path_offset(blob, node[i]);
		if (nodeoff < 0) {
			printf("ipq: fdt fixup unable to find node %s\n",
								node[i]);
			continue;
		}
		ret = fdt_setprop(blob, nodeoff, "qca,host",
					&phy_mode, sizeof(phy_mode));
		if (ret != 0) {
			printf("ipq: unable to set prop: %d\n", ret);
			continue;
		}
	}

	nodeoff = fdt_path_offset(blob, "/soc/usb3/dwc3");
	if (nodeoff < 0) {
		printf("ipq: fdt fixup unable to find node /soc/usb3/dwc3\n");
		return;
	}
	ret = fdt_setprop(blob, nodeoff, "dr_mode",
				mode, (strlen(mode) + 1));
	if (ret != 0) {
		printf("ipq: unable to set prop: %d\n", ret);
		return;
	}
	return;
}
#endif

void set_flash_secondary_type(qca_smem_flash_info_t * smem)
{
	return;
}

int ipq_read_tcsr_boot_misc(void)
{
	u32 *dmagic = TCSR_BOOT_MISC_REG;
	return *dmagic;
}

int apps_iscrashed(void)
{
	u32 *dmagic = TCSR_BOOT_MISC_REG;

	if (*dmagic & DLOAD_MAGIC_COOKIE)
		return 1;

	return 0;
}

unsigned int get_smem_spi_addr_len(void)
{
	return SPI_DEFAULT_ADDR_LEN;
}


void enable_caches(void)
{
	icache_enable();
	dcache_enable();
}

void disable_caches(void)
{
	icache_disable();
	dcache_disable();
}

unsigned int get_dts_machid(unsigned int machid)
{
	switch (machid)
	{
		case MACH_TYPE_IPQ40XX_AP_DK04_1_C6:
			return MACH_TYPE_IPQ40XX_AP_DK04_1_C1;
		case MACH_TYPE_IPQ40XX_AP_DK05_1_C1:
			return MACH_TYPE_IPQ40XX_AP_DK01_1_C2;
		default:
			return machid;
	}
}

/**
 * Set the uuid in bootargs variable for mounting rootfilesystem
 */
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag)
{
	return 0;
}
extern void dk_secondary_cpu_init(void);
extern void dk_secondary_cpu_reinit(void);
/*
 * Set the cold/warm boot address for one of the CPU cores.
 */
int scm_set_boot_addr(bool enable_sec_core)
{
	int ret;
	struct {
		unsigned int flags;
		unsigned long addr;
	} cmd;

	if (!enable_sec_core)
		return -1;

	cmd.addr = (unsigned long)dk_secondary_cpu_init;
	cmd.flags = 0xff;

	ret = scm_call(SCM_SVC_BOOT, SCM_BOOT_ADDR,
				&cmd, sizeof(cmd), NULL, 0);
	if (ret) {
		printf("--- %s: scm_call failed ret = %d\n", __func__, ret);
	}

	return ret;
}

int is_secondary_core_off(unsigned int cpuid)
{
	return 1;
}

static int secondary_core_already_reset[NR_CPUS];
static int scm_boot_addr_already_set;
extern int get_cpu_id(void);
static volatile int core_var;

void bring_secondary_core_down(unsigned int state)
{
	int current_cpu_id;

	current_cpu_id = (1 << get_cpu_id());
	core_var &= (~current_cpu_id);
	while (!(core_var & current_cpu_id)) {
		cp_delay();
	}
	dk_secondary_cpu_reinit();
}

static int kpssv1_release_secondary(unsigned int cpuid)
{
	dcache_enable();

	writel(0xa4, CPU_APCS_SAW2_VCTL(cpuid));
	barrier();
	udelay(512);

	writel(0x109, CPU_APCS_CPU_PWR_CTL(cpuid));
	writel(0x101, CPU_APCS_CPU_PWR_CTL(cpuid));
	barrier();
	udelay(1);

	writel(0x121, CPU_APCS_CPU_PWR_CTL(cpuid));
	barrier();
	udelay(2);

	writel(0x120, CPU_APCS_CPU_PWR_CTL(cpuid));
	barrier();
	udelay(2);

	writel(0x100, CPU_APCS_CPU_PWR_CTL(cpuid));
	barrier();
	udelay(100);

	writel(0x180, CPU_APCS_CPU_PWR_CTL(cpuid));
	barrier();

	dcache_disable();

	return 0;
}
int bring_sec_core_up(unsigned int cpuid, unsigned int entry, unsigned int arg)
{
	int err = 0;

	if (!secondary_core_already_reset[cpuid]) {
		if (!scm_boot_addr_already_set) {
			err = scm_set_boot_addr(true);
			core_var = 0;
			if (!err) {
				scm_boot_addr_already_set = 1;
				kpssv1_release_secondary(cpuid);
				secondary_core_already_reset[cpuid] = 1;
			} else
				return err;
		} else {
			kpssv1_release_secondary(cpuid);
			secondary_core_already_reset[cpuid] = 1;
		}
	} else {
		core_var |= (1 << cpuid);
	}


	return 0;
}

int smem_read_cpu_count()
{
	uint32_t core_no;

	if (!smem_read_alloc_entry(SMEM_NUM_CPUINFO, &core_no,
			sizeof(uint32_t))) {
		if (core_no != 4)
			return core_no;
	}
	return -1;
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_cpus_node(void *blob)
{
	int numcpus;
	int nodeoff;

	numcpus =  smem_read_cpu_count();

	if (numcpus == 2)
	{
		nodeoff = fdt_path_offset(blob, "/cpus/cpu@2");

		if (nodeoff >= 0)
			fdt_del_node((void *)blob, nodeoff);
		else
			printf("fixup_cpus_node: can't disable cpu2\n");

		nodeoff = fdt_path_offset(blob, "/cpus/cpu@3");

		if (nodeoff >= 0)
			fdt_del_node((void *)blob, nodeoff);
		else
			printf("fixup_cpus_node: can't disable cpu3\n");
	}

	else if (numcpus == 1)
	{
		nodeoff = fdt_path_offset(blob, "/cpus/cpu@1");

		if (nodeoff >= 0)
			fdt_del_node((void *)blob, nodeoff);
		else
			printf("fixup_cpus_node: can't disable cpu1\n");

		nodeoff = fdt_path_offset(blob, "/cpus/cpu@2");

		if (nodeoff >= 0)
			fdt_del_node((void *)blob, nodeoff);
		else
			printf("fixup_cpus_node: can't disable cpu2\n");

		nodeoff = fdt_path_offset(blob, "/cpus/cpu@3");

		if (nodeoff >= 0)
			fdt_del_node((void *)blob, nodeoff);
		else
			printf("fixup_cpus_node: can't disable cpu3\n");
	}
	return;
}
#endif

void ipq_uboot_fdt_fixup(void)
{
	int ret, len;
	const char *config = "config@ap.dk05.1-c1";
	len = fdt_totalsize(gd->fdt_blob) + strlen(config) + 1;

	if (gd->bd->bi_arch_number == MACH_TYPE_IPQ40XX_AP_DK05_1_C1)
	{
		/*
		 * Open in place with a new length.
		 */
		ret = fdt_open_into(gd->fdt_blob, (void *)gd->fdt_blob, len);
		if (ret)
			 debug("uboot-fdt-fixup: Cannot expand FDT: %s\n", fdt_strerror(ret));

		ret = fdt_setprop((void *)gd->fdt_blob, 0, "config_name",
				config, (strlen(config)+1));
		if (ret)
			debug("uboot-fdt-fixup: unable to set config_name(%d)\n", ret);
	}
	return;
}

int get_soc_hw_version(void)
{
	return readl(TCSR_SOC_HW_VERSION_REG);
}
