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
#include <asm-generic/errno.h>
#include <environment.h>
#include <fdtdec.h>
#include <asm/arch-qca-common/gsbi.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/smem.h>
#include <asm/arch-ipq806x/msm_ipq806x_gmac.h>
#include <linux/mtd/ipq_nand.h>
#include <asm/arch-qca-common/nand.h>
#include <asm/arch-ipq806x/clk.h>
#include <linux/usb/ipq_usb30.h>
#include <linux/usb/dwc3.h>
#include "ipq806x.h"
#include <asm/arch-qca-common/qca_common.h>
#include <asm/arch-qca-common/scm.h>
#include <asm/arch-qca-common/iomap.h>
#include <asm/io.h>
#include <dm/device.h>
#include <mmc.h>
#include <spi.h>
#include "ipq_spi.h"

#define DLOAD_MAGIC_COOKIE_1 0xE47B337D
#define DLOAD_MAGIC_COOKIE_2 0x0501CAB0

ipq_gmac_board_cfg_t gmac_cfg[CONFIG_IPQ_NO_MACS];
DECLARE_GLOBAL_DATA_PTR;

qca_mmc mmc_host;

const char *rsvd_node = "/reserved-memory";
const char *del_node[] = {NULL};
const add_node_t add_fdt_node[] = {{}};

struct dumpinfo_t dumpinfo_n[] = {
	/* Note1: when aligned access is set, the contents
	 * are copied to a temporary location and so
	 * the size of region should not exceed the size
	 * of region pointed by IPQ_TEMP_DUMP_ADDR
	 *
	 * Note2: IPQ_NSSTCM_DUMP_ADDR should be the
	 * first entry */
	{ "NSSTCM.BIN",   IPQ_NSSTCM_DUMP_ADDR, 0x20000, 0 },
	{ "IMEM_A.BIN",   0x2a000000, 0x0003f000, 0 },
	{ "IMEM_C.BIN",   0x2a03f000, 0x00001000, 0 },
	{ "IMEM_D.BIN",   0x2A040000, 0x00020000, 0 },
	{ "CODERAM.BIN",  0x00020000, 0x00028000, 0 },
	{ "SPS_RAM.BIN",  0x12000000, 0x0002C000, 0 },
	{ "RPM_MSG.BIN",  0x00108000, 0x00005fff, 1 },
	{ "SPS_BUFF.BIN", 0x12040000, 0x00004000, 0 },
	{ "SPS_PIPE.BIN", 0x12800000, 0x00008000, 0 },
	{ "LPASS.BIN",    0x28400000, 0x00020000, 0 },
	{ "RPM_WDT.BIN",  0x0006206C, 0x00000004, 0 },
	{ "CPU0_WDT.BIN", 0x0208A044, 0x00000004, 0 },
	{ "CPU1_WDT.BIN", 0x0209A044, 0x00000004, 0 },
	{ "CPU0_REG.BIN", 0x39013ea8, 0x000000AC, 0 },
	{ "CPU1_REG.BIN", 0x39013f54, 0x000000AC, 0 },
	{ "WLAN_FW.BIN",  0x41400000, 0x000FFF80, 0 },
	{ "WLAN_FW_900B.BIN", 0x44000000, 0x00600000, 0 },
	{ "EBICS0.BIN",   0x40000000, 0x20000000, 0 },
	{ "EBI1CS1.BIN",  0x60000000, 0x20000000, 0 },
	{ "EBICS2.BIN",  0x60000000, 0x20000000, 0, 0, 0, 0, 1 },
	{ "EBICS1.BIN",  CONFIG_UBOOT_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS0.BIN",  0x40000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 }
};
int dump_entries_n = ARRAY_SIZE(dumpinfo_n);

struct dumpinfo_t dumpinfo_s[] = {
	/* Note1: when aligned access is set, the contents
	 * are copied to a temporary location and so
	 * the size of region should not exceed the size
	 * of region pointed by IPQ_TEMP_DUMP_ADDR
	 *
	 * Note2: IPQ_NSSTCM_DUMP_ADDR should be the
	 * first entry */
	{ "NSSTCM.BIN",   IPQ_NSSTCM_DUMP_ADDR, 0x20000, 0 },
	{ "IMEM_A.BIN",   0x2a000000, 0x0003f000, 0 },
	{ "IMEM_C.BIN",   0x2a03f000, 0x00001000, 0 },
	{ "IMEM_D.BIN",   0x2A040000, 0x00020000, 0 },
	{ "CODERAM.BIN",  0x00020000, 0x00028000, 0 },
	{ "SPS_RAM.BIN",  0x12000000, 0x0002C000, 0 },
	{ "RPM_MSG.BIN",  0x00108000, 0x00005fff, 1 },
	{ "SPS_BUFF.BIN", 0x12040000, 0x00004000, 0 },
	{ "SPS_PIPE.BIN", 0x12800000, 0x00008000, 0 },
	{ "LPASS.BIN",    0x28400000, 0x00020000, 0 },
	{ "RPM_WDT.BIN",  0x0006206C, 0x00000004, 0 },
	{ "CPU0_WDT.BIN", 0x0208A044, 0x00000004, 0 },
	{ "CPU1_WDT.BIN", 0x0209A044, 0x00000004, 0 },
	{ "CPU0_REG.BIN", 0x39013ea8, 0x000000AC, 0 },
	{ "CPU1_REG.BIN", 0x39013f54, 0x000000AC, 0 },
	{ "WLAN_FW.BIN",  0x41400000, 0x000FFF80, 0 },
	{ "WLAN_FW_900B.BIN", 0x44000000, 0x00600000, 0 },
	{ "EBICS0.BIN",   0x40000000, 0x20000000, 0 },
	{ "EBI1CS1.BIN",  0x60000000, 0x20000000, 0 },
	{ "EBICS2.BIN",  0x60000000, 0x20000000, 0, 0, 0, 0, 1 },
	{ "EBICS1.BIN",  CONFIG_UBOOT_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS0.BIN",  0x40000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 }
};
int dump_entries_s = ARRAY_SIZE(dumpinfo_s);

extern int ipq_spi_init(u16);

pci_clk_offset_t pcie_0_clk = {
	.aclk_ctl = PCIE_0_ACLK_CTL,
	.pclk_ctl = PCIE_0_PCLK_CTL,
	.hclk_ctl = PCIE_0_HCLK_CTL,
	.aux_clk_ctl = PCIE_0_AUX_CLK_CTL,
	.alt_ref_clk_ns = PCIE_0_ALT_REF_CLK_NS,
	.alt_ref_clk_acr = PCIE_0_ALT_REF_CLK_ACR,
	.aclk_fs = PCIE_0_ACLK_FS,
	.pclk_fs = PCIE_0_PCLK_FS,
	.parf_phy_refclk = PCIE20_0_PARF_PHY_REFCLK
};

pci_clk_offset_t pcie_1_clk = {
	.aclk_ctl = PCIE_1_ACLK_CTL,
	.pclk_ctl = PCIE_1_PCLK_CTL,
	.hclk_ctl = PCIE_1_HCLK_CTL,
	.aux_clk_ctl = PCIE_1_AUX_CLK_CTL,
	.alt_ref_clk_ns = PCIE_1_ALT_REF_CLK_NS,
	.alt_ref_clk_acr = PCIE_1_ALT_REF_CLK_ACR,
	.aclk_fs = PCIE_1_ACLK_FS,
	.pclk_fs = PCIE_1_PCLK_FS,
	.parf_phy_refclk = PCIE20_1_PARF_PHY_REFCLK
};

pci_clk_offset_t pcie_2_clk = {
	.aclk_ctl = PCIE_2_ACLK_CTL,
	.pclk_ctl = PCIE_2_PCLK_CTL,
	.hclk_ctl = PCIE_2_HCLK_CTL,
	.aux_clk_ctl = PCIE_2_AUX_CLK_CTL,
	.alt_ref_clk_ns = PCIE_2_ALT_REF_CLK_NS,
	.alt_ref_clk_acr = PCIE_2_ALT_REF_CLK_ACR,
	.aclk_fs = PCIE_2_ACLK_FS,
	.pclk_fs = PCIE_2_PCLK_FS,
	.parf_phy_refclk = PCIE20_2_PARF_PHY_REFCLK
};

enum pcie_id {
	PCIE_0,
	PCIE_1,
	PCIE_2,
};

unsigned long timer_read_counter(void)
{
	return 0;
}

void reset_crashdump(void)
{
	unsigned long *dmagic1 = (unsigned long *) 0x2A03F000;
	unsigned long *dmagic2 = (unsigned long *) 0x2A03F004;

	*dmagic1 = 0;
	*dmagic2 = 0;

	return;
}

void reset_cpu(unsigned long a)
{
	int reset_s17_gpio_node;

	reset_s17_gpio_node = fdt_path_offset(gd->fdt_blob, "/reset_s17_gpio");
	if (reset_s17_gpio_node)
		qca_gpio_init(reset_s17_gpio_node);

	reset_crashdump();

	printf("\nResetting with watch dog!\n");

	writel(0, APCS_WDT0_EN);
	writel(1, APCS_WDT0_RST);
	writel(RESET_WDT_BARK_TIME, APCS_WDT0_BARK_TIME);
	writel(RESET_WDT_BITE_TIME, APCS_WDT0_BITE_TIME);
	writel(1, APCS_WDT0_EN);
	writel(1, APCS_WDT0_CPU0_WDOG_EXPIRED_ENABLE);

	while(1);
}

void reset_board(void)
{
	run_command("reset", 0);
}

void ipq_uboot_fdt_fixup(void)
{
	int ret, len;
	const char *config = "config@ap148_1xx";
	len = fdt_totalsize(gd->fdt_blob) + strlen(config) + 1;

	if (gd->bd->bi_arch_number == MACH_TYPE_IPQ806X_AP148_1XX)
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

int board_mmc_init(bd_t *bis)
{
	int node, gpio_node;
	int ret = -ENODEV;
	const u32 *emmc_base;
	int len;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	node = fdt_path_offset(gd->fdt_blob, "sdcc");

	if (node < 0) {
		printf("SDCC : Node Not found, skipping initialization\n");
		goto out;
	}

	emmc_base = fdt_getprop(gd->fdt_blob, node, "reg", &len);

	if ((u32)emmc_base == FDT_ADDR_T_NONE) {
		printf("No valid SDCC base address found in device tree\n");
		goto out;
        }

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "emmc_gpio");
	if (gpio_node >= 0) {

		mmc_host.clk_mode = MMC_IDENTIFY_MODE;
		mmc_host.base = fdt32_to_cpu(emmc_base[0]);
		emmc_clock_config(mmc_host.clk_mode);
		qca_gpio_init(gpio_node);
		ret = qca_mmc_init(bis, &mmc_host);
	}

	if (!ret && sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
		ret = board_mmc_env_init(mmc_host);
	}
out:
	return ret;
}
void board_nand_init(void)
{
	int node, gpio_node;
	const u32 *nand_base;
	struct ipq_nand ipq_nand;
	int len;

	node = fdt_path_offset(gd->fdt_blob, "nand");

	if (node < 0) {
		printf("NAND : Not found, skipping initialization\n");
		goto spi_init;
	}

	nand_base = fdt_getprop(gd->fdt_blob, node, "reg", &len);

	if ((u32)nand_base == FDT_ADDR_T_NONE) {
		printf("No valid NAND base address found in device tree\n");
		goto spi_init;
        }

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "nand_gpio");
	if (gpio_node >= 0) {
		nand_clock_config();
		memset(&ipq_nand, 0, sizeof(ipq_nand));
		ipq_nand.ebi2cr_regs = fdt32_to_cpu(nand_base[0]);
		ipq_nand.ebi2nd_regs = fdt32_to_cpu(nand_base[2]);
		ipq_nand.layout = IPQ_NAND_LAYOUT_LINUX;
		ipq_nand.variant = QCA_NAND_IPQ;
		qca_gpio_init(gpio_node);
		ipq_nand_init(&ipq_nand);
	}

spi_init:
	if(!(gsbi_pin_config(CONFIG_SF_DEFAULT_BUS, CONFIG_SF_DEFAULT_CS)))
		ipq_spi_init(CONFIG_SPI_FLASH_INFO_IDX);
}

int board_eth_init(bd_t *bis)
{
	int status;
	int gmac_gpio_node = 0, storm_switch_gpio_node = 0;
	int ak01_reset_gpio_node = 0, ak01_config_gpio_node = 0;
	int gmac_cfg_node = 0, offset = 0;
	unsigned int machid;
	int loop = 0, inner_loop = 0;
	int phy_name_len = 0;
	unsigned int tmp_phy_array[8] = {0};
	char *phy_name_ptr = NULL;

	gmac_cfg_node = fdt_path_offset(gd->fdt_blob, "/gmac_cfg");
	if (gmac_cfg_node >= 0) {
		for (offset = fdt_first_subnode(gd->fdt_blob, gmac_cfg_node);
			offset > 0;
			offset = fdt_next_subnode(gd->fdt_blob, offset) , loop++) {

			gmac_cfg[loop].base = fdtdec_get_uint(gd->fdt_blob,
					offset, "base", 0);

			gmac_cfg[loop].unit = fdtdec_get_uint(gd->fdt_blob,
					offset, "unit", 0);

			gmac_cfg[loop].is_macsec = fdtdec_get_uint(gd->fdt_blob,
					offset, "is_macsec", 0);

			gmac_cfg[loop].mac_pwr0 = fdtdec_get_uint(gd->fdt_blob,
					offset, "mac_pwr0", 0);

			gmac_cfg[loop].mac_pwr1 = fdtdec_get_uint(gd->fdt_blob,
					offset, "mac_pwr1", 0);

			gmac_cfg[loop].mac_conn_to_phy = fdtdec_get_uint(gd->fdt_blob,
					offset, "mac_conn_to_phy", 0);

			gmac_cfg[loop].phy = fdtdec_get_uint(gd->fdt_blob,
					offset, "phy_interface_type", 0);

			gmac_cfg[loop].phy_addr.count = fdtdec_get_uint(gd->fdt_blob,
					offset, "phy_address_count", 0);

			fdtdec_get_int_array(gd->fdt_blob, offset, "phy_address",
					tmp_phy_array, gmac_cfg[loop].phy_addr.count);

			for(inner_loop = 0; inner_loop < gmac_cfg[loop].phy_addr.count;
					inner_loop++){
				gmac_cfg[loop].phy_addr.addr[inner_loop] =
					(char)tmp_phy_array[inner_loop];
			}

			phy_name_ptr = (char*)fdt_getprop(gd->fdt_blob, offset,
					"phy_name", &phy_name_len);

			strncpy((char *)gmac_cfg[loop].phy_name, phy_name_ptr, phy_name_len);

		}
	}
	gmac_cfg[loop].unit = -1;

	storm_switch_gpio_node = fdt_path_offset(gd->fdt_blob,
						"/storm_switch_gpio");
	if (storm_switch_gpio_node) {
		qca_gpio_init(storm_switch_gpio_node);
	}

	ipq_gmac_common_init(gmac_cfg);

	gmac_gpio_node = fdt_path_offset(gd->fdt_blob, "gmac_gpio");
	if (gmac_gpio_node) {
		qca_gpio_init(gmac_gpio_node);
	}
	/*
	 * Register the swith driver routines before
	 * initializng the GMAC
	 */
	machid = fdtdec_get_uint(gd->fdt_blob, 0, "machid", 0);

	switch (machid) {
		case MACH_TYPE_IPQ806X_AP160_2XX:
			ipq_register_switch(ipq_qca8511_init);
			break;

		case MACH_TYPE_IPQ806X_AK01_1XX:
			ak01_reset_gpio_node = fdt_path_offset(gd->fdt_blob, "/ak01_gmac_reset_gpio");
			if (ak01_reset_gpio_node){
				qca_gpio_init(ak01_reset_gpio_node);
			}

			mdelay(100);

			ak01_config_gpio_node = fdt_path_offset(gd->fdt_blob, "/ak01_gmac_config_gpio");
			if (ak01_config_gpio_node){
				qca_gpio_init(ak01_config_gpio_node);
			};

			ipq_register_switch(NULL);
			break;

		default:
			ipq_register_switch(ipq_athrs17_init);
			break;
	}

	status = ipq_gmac_init(gmac_cfg);
	return status;
}

void qca_serial_init(struct ipq_serial_platdata *plat)
{
	int serial_node, gpio_node, uart2_node;
	unsigned gsbi_base;

	serial_node = fdt_path_offset(gd->fdt_blob, "console");
        if (serial_node < 0) {
             return;
        }

	if (plat->port_id == 2) {
		uart2_node = fdt_path_offset(gd->fdt_blob, "uart2");
		if (uart2_node < 0) {
			printf("uart2 node not defined\n");
		} else {
			serial_node = uart2_node;
		}
	}

        gpio_node = fdt_subnode_offset(gd->fdt_blob,
				       serial_node, "serial_gpio");
	gsbi_base = fdtdec_get_uint(gd->fdt_blob,
				    serial_node, "gsbi_base", 0);
	if (!gsbi_base)
		return;

	qca_gpio_init(gpio_node);
	if (!(plat->m_value == -1) || ( plat->n_value == -1) || (plat->d_value == -1))
		uart_clock_config(plat->port_id,
				plat->m_value,
				plat->n_value,
				plat->d_value);

	writel(GSBI_PROTOCOL_CODE_I2C_UART <<
			GSBI_CTRL_REG_PROTOCOL_CODE_S,
			GSBI_CTRL_REG(gsbi_base));

}

void ipq_wifi_pci_power_enable(void)
{
	int offset;
	u32 gpio;

	offset = fdt_path_offset(gd->fdt_blob, "pci_pwr");
	if (offset >= 0) {
		qca_gpio_init(offset);
		for (offset = fdt_first_subnode(gd->fdt_blob, offset); offset > 0;
			offset = fdt_next_subnode(gd->fdt_blob, offset)) {

			gpio = fdtdec_get_uint(gd->fdt_blob,
					  offset, "gpio", 0);
			gpio_set_value(gpio, 1);
		}
	}
}

static void ipq_wifi_pci_power_disable(void)
{
	int offset;
	u32 gpio;
	offset = fdt_path_offset(gd->fdt_blob, "pci_pwr");
	if (offset >= 0) {
		for (offset = fdt_first_subnode(gd->fdt_blob, offset); offset > 0;
			offset = fdt_next_subnode(gd->fdt_blob, offset)) {

			gpio = fdtdec_get_uint(gd->fdt_blob,
					  offset, "gpio", 0);
			gpio_set_value(gpio, 0);
		}
	}
}

void board_pcie_clock_init(int id)
{
	switch(id) {
		case PCIE_0:
			pcie_clock_config(&pcie_0_clk);
			break;
		case PCIE_1:
			pcie_clock_config(&pcie_1_clk);
			break;
		case PCIE_2:
			pcie_clock_config(&pcie_2_clk);
			break;
	}
}

void board_pci_init(int id)
{
	int node, gpio_node, offset;
	char name[16];
	u32 gpio;

	sprintf(name, "pci%d", id);
	node = fdt_path_offset(gd->fdt_blob, name);
	if (node < 0) {
		printf("Could not find PCI in device tree\n");
		return;
	}
	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
		offset = fdt_first_subnode(gd->fdt_blob, gpio_node);
		if (offset) {
			gpio = fdtdec_get_uint(gd->fdt_blob,
							offset, "gpio", 0);
			gpio_set_value(gpio, 1);
			udelay(3000);
		}
	}

	return;
}

void board_pci_deinit()
{
	int node, i;
	char name[16];
	struct fdt_resource parf;
	struct fdt_resource pci_rst;
	struct qca_gpio_config gpio_config = {0};

	for (i = 0; i < PCI_MAX_DEVICES; i++) {
		snprintf(name, sizeof(name), "pci%d", i);
		node = fdt_path_offset(gd->fdt_blob, name);
		if (node < 0) {
			printf("Could not find PCI in device tree\n");
			return;
		}
		gpio_config.gpio = fdtdec_get_uint(gd->fdt_blob,
						node, "perst_gpio", 0);

		gpio_tlmm_config(&gpio_config);

		fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "pci_rst",
					     &pci_rst);
		writel(0x7d, pci_rst.start);
		fdt_get_named_resource(gd->fdt_blob, node, "reg", "reg-names", "parf",
					     &parf);
		writel(0x1, parf.start + 0x40);
		switch(i) {
			case PCIE_0:
				pcie_clock_shutdown(&pcie_0_clk);
				break;
			case PCIE_1:
				pcie_clock_shutdown(&pcie_1_clk);
				break;
			case PCIE_2:
				pcie_clock_shutdown(&pcie_2_clk);
				break;
		}

	}
	ipq_wifi_pci_power_disable();

	return ;
}

#ifdef CONFIG_IPQ_FDT_FIXUP
void ipq_fdt_fixup_usb_device_mode(void *blob)
{
	return;
}
#endif

void board_mmc_deinit(void)
{
	emmc_clock_reset();
	emmc_clock_disable();
}

void set_flash_secondary_type(qca_smem_flash_info_t *smem)
{
	/*
	 * Both eMMC and NAND share common GPIOs, only one of them shall be
	 * enabled from device tree, based on board configuration.
	 *
	 * flash_secondary_type is set to eMMC/NAND device whichever is
	 * initialized, as there is no smem entry to differentiate between the
	 * two.
	 */
#ifdef CONFIG_QCA_MMC
	struct mmc *mmc;

	mmc = find_mmc_device(mmc_host.dev_num);
	if (mmc) {
		smem->flash_secondary_type = SMEM_BOOT_MMC_FLASH;
		return;
	}
#endif
	smem->flash_secondary_type = SMEM_BOOT_NAND_FLASH;
	return;
}

int switch_ce_channel_buf(unsigned int channel_id)
{
	int ret;
	switch_ce_chn_buf_t ce1_chn_buf;

	ce1_chn_buf.resource   = CE1_RESOURCE;
	ce1_chn_buf.channel_id = channel_id;

	ret = scm_call(SCM_SVC_TZ, CE_CHN_SWITCH_CMD, &ce1_chn_buf,
		sizeof(switch_ce_chn_buf_t), NULL, 0);

	return ret;
}

#ifdef CONFIG_USB_XHCI_IPQ
__weak void ipq_reset_usb_phy(void *data)
{
	return;
}

static u16 dwc3_ipq_ssusb_read_phy_reg(unsigned int  addr, unsigned int ipq_base)
{
	u16 tmp_phy[3], i;
	do {
		for (i = 0; i < 3; i++) {
			writel(addr, ipq_base +
				IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_DATA_IN);
			writel(0x1, ipq_base +
				IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_CAP_ADDR);
			while (0 != readl(ipq_base +
				IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_CAP_ADDR));
			writel(0x1, ipq_base +
				IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_READ);
			while (0 != readl(ipq_base +
				IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_READ));
			tmp_phy[i] = (u16)readl(ipq_base +
				IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_DATA_OUT);
		}
	} while (tmp_phy[1] != tmp_phy[2]);
	return tmp_phy[2];
}

static void dwc3_ipq_ssusb_write_phy_reg(u32 addr, u16 data, unsigned int ipq_base)
{
	writel(addr, ipq_base + IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_DATA_IN);
	writel(0x1, ipq_base + IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_CAP_ADDR);
	while (0 != readl(ipq_base +
		IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_CAP_ADDR));
	writel(data, ipq_base + IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_DATA_IN);
	writel(0x1, ipq_base + IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_CAP_DATA);
	while (0 != readl(ipq_base +
		IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_CAP_DATA));
	writel(0x1, ipq_base + IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_WRITE);
	while (0 != readl(ipq_base +
		IPQ_SSUSB_REG_QSCRATCH_SS_CR_PROTOCOL_WRITE));
}

static void ipq_ssusb_clear_bits32(u32 offset, u32 bits, unsigned int ipq_base)
{
	u32 data;
	data = readl(ipq_base+offset);
	data = data & ~bits;
	writel(data, ipq_base + offset);
}

static void ipq_ssusb_clear_and_set_bits32(u32 offset, u32 clear_bits, u32 set_bits, unsigned int ipq_base)
{
	u32 data;
	data = readl(ipq_base + offset);
	data = (data & ~clear_bits) | set_bits;
	writel(data, ipq_base + offset);
}

static void partial_rx_reset_init(unsigned int ipq_base)
{
	u32 addr = DWC3_SSUSB_PHY_TX_ALT_BLOCK_REG;
	u16 data = dwc3_ipq_ssusb_read_phy_reg(addr, ipq_base);
	data |= DWC3_SSUSB_PHY_TX_ALT_BLOCK_EN_ALT_BUS;
	dwc3_ipq_ssusb_write_phy_reg(addr, data, ipq_base);
	return;
}

static void  uw_ssusb_pre_init(unsigned int ipq_base)
{
	u32  set_bits, tmp;

	/* GCTL Reset ON */
	writel(0x800, ipq_base + DWC3_SSUSB_REG_GCTL);
	/* Config SS PHY CTRL */
	set_bits = 0;
	writel(0x80, ipq_base + IPQ_SS_PHY_CTRL_REG);
	udelay(5);
	ipq_ssusb_clear_bits32(IPQ_SS_PHY_CTRL_REG, 0x80, ipq_base);
	udelay(5);
	/* REF_USE_PAD */
	set_bits = 0x0000000;  /* USE Internal clock */
	set_bits |= IPQ_SSUSB_QSCRATCH_SS_PHY_CTRL_LANE0_PWR_PRESENT;
	set_bits |= IPQ_SSUSB_QSCRATCH_SS_PHY_CTRL_REF_SS_PHY_EN;
	writel(set_bits, ipq_base + IPQ_SS_PHY_CTRL_REG);
	/* Config HS PHY CTRL */
	set_bits = IPQ_SSUSB_REG_QSCRATCH_HS_PHY_CTRL_UTMI_OTG_VBUS_VALID;
	/*
	 * COMMONONN forces xo, bias and pll to stay on during suspend;
	 * Allowing suspend (writing 1) kills Aragorn V1
	 */
	set_bits |= IPQ_SSUSB_REG_QSCRATCH_HS_PHY_CTRL_COMMONONN;
	set_bits |= IPQ_SSUSB_REG_QSCRATCH_HS_PHY_CTRL_USE_CLKCORE;
	set_bits |= IPQ_SSUSB_REG_QSCRATCH_HS_PHY_CTRL_FSEL_VAL;
	/*
	 * If the configuration of clocks is not bypassed in Host mode,
	 * HS PHY suspend needs to be prohibited, otherwise - SS connection fails
	 */
	ipq_ssusb_clear_and_set_bits32(IPQ_SSUSB_REG_QSCRATCH_HS_PHY_CTRL, 0,
					set_bits, ipq_base);
	/* USB2 PHY Reset ON */
	writel(DWC3_SSUSB_REG_GUSB2PHYCFG_PHYSOFTRST, ipq_base +
		DWC3_SSUSB_REG_GUSB2PHYCFG(0));
	/* USB3 PHY Reset ON */
	writel(DWC3_SSUSB_REG_GUSB3PIPECTL_PHYSOFTRST, ipq_base +
		DWC3_SSUSB_REG_GUSB3PIPECTL(0));
	udelay(5);
	/* USB3 PHY Reset OFF */
	ipq_ssusb_clear_bits32(DWC3_SSUSB_REG_GUSB3PIPECTL(0),
				DWC3_SSUSB_REG_GUSB3PIPECTL_PHYSOFTRST, ipq_base);
	ipq_ssusb_clear_bits32(DWC3_SSUSB_REG_GUSB2PHYCFG(0),
				DWC3_GUSB2PHYCFG_PHYSOFTRST, ipq_base);
	udelay(5);
	/* GCTL Reset OFF */
	ipq_ssusb_clear_bits32(DWC3_SSUSB_REG_GCTL, DWC3_GCTL_CORESOFTRESET,
				ipq_base);
	udelay(5);
	if (RX_TERM_VALUE) {
		dwc3_ipq_ssusb_write_phy_reg(DWC3_SSUSB_PHY_RTUNE_RTUNE_CTRL_REG,
						0, ipq_base);
		dwc3_ipq_ssusb_write_phy_reg(DWC3_SSUSB_PHY_RTUNE_DEBUG_REG,
						0x0448, ipq_base);
		dwc3_ipq_ssusb_write_phy_reg(DWC3_SSUSB_PHY_RTUNE_DEBUG_REG,
						RX_TERM_VALUE, ipq_base);
	}
	if (0 != RX_EQ_VALUE) { /* Values from 1 to 7 */
		tmp =0;
		/*
		 * 1. Fixed EQ setting. This can be achieved as follows:
		 * LANE0.RX_OVRD_IN_HI. RX_EQ_EN set to 0 - address 1006 bit 6
		 * LANE0.RX_OVRD_IN_HI.RX_EQ_EN_OVRD set to 1 0- address 1006 bit 7
		 * LANE0.RX_OVRD_IN_HI.RX_EQ set to 4 (also try setting 3 if possible) -
		 * address 1006 bits 10:8 - please make this a variable, if unchanged the section is not executed
		 * LANE0.RX_OVRD_IN_HI.RX_EQ_OVRD set to 1 - address 1006 bit 11
		 */
		tmp = dwc3_ipq_ssusb_read_phy_reg(DWC3_SSUSB_PHY_RX_OVRD_IN_HI_REG,
							ipq_base);
		tmp &= ~((u16)1 << DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_EN);
		tmp |= ((u16)1 << DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_EN_OVRD);
		tmp &= ~((u16) DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_MASK <<
			DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ);
		tmp |= RX_EQ_VALUE << DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ;
		tmp |= 1 << DWC3_SSUSB_PHY_RX_OVRD_IN_HI_RX_EQ_OVRD;
		dwc3_ipq_ssusb_write_phy_reg(DWC3_SSUSB_PHY_RX_OVRD_IN_HI_REG,
						tmp, ipq_base);
	}
	if ((113 != AMPLITUDE_VALUE) || (21 != TX_DEEMPH_3_5DB)) {
		tmp = dwc3_ipq_ssusb_read_phy_reg(DWC3_SSUSB_PHY_TX_OVRD_DRV_LO_REG,
			ipq_base);
		tmp &= ~DWC3_SSUSB_PHY_TX_DEEMPH_MASK;
		tmp |= (TX_DEEMPH_3_5DB << DWC3_SSUSB_PHY_TX_DEEMPH_SHIFT);
		tmp &= ~DWC3_SSUSB_PHY_AMP_MASK;
		tmp |= AMPLITUDE_VALUE;
		tmp |= DWC3_SSUSB_PHY_AMP_EN;
		dwc3_ipq_ssusb_write_phy_reg(DWC3_SSUSB_PHY_TX_OVRD_DRV_LO_REG,
						tmp, ipq_base);
	}
	ipq_ssusb_clear_and_set_bits32(IPQ_SS_PHY_PARAM_CTRL_1_REG,
					0x7, 0x5, ipq_base);
	/* XHCI REV */
	writel((1 << 2), ipq_base + IPQ_QSCRATCH_GENERAL_CFG);
	writel(0x0c80c010, ipq_base + DWC3_SSUSB_REG_GUCTL);
	partial_rx_reset_init(ipq_base);
	set_bits = 0;
	/* Test  U2EXIT_LFPS */
	set_bits |= IPQ_SSUSB_REG_GCTL_U2EXIT_LFPS;
	ipq_ssusb_clear_and_set_bits32(DWC3_SSUSB_REG_GCTL, 0,
					set_bits, ipq_base);
	set_bits = 0;
	set_bits |= IPQ_SSUSB_REG_GCTL_U2RSTECN;
	set_bits |= IPQ_SSUSB_REG_GCTL_U2EXIT_LFPS;
	ipq_ssusb_clear_and_set_bits32(DWC3_SSUSB_REG_GCTL, 0,
					set_bits, ipq_base);
	writel(DWC3_GCTL_U2EXIT_LFPS | DWC3_GCTL_SOFITPSYNC |
		DWC3_GCTL_PRTCAPDIR(1) |
		DWC3_GCTL_U2RSTECN | DWC3_GCTL_PWRDNSCALE(2),
		ipq_base + DWC3_GCTL);
	writel((IPQ_SSUSB_QSCRATCH_SS_PHY_CTRL_MPLL_MULTI(0x19) |
		IPQ_SSUSB_QSCRATCH_SS_PHY_CTRL_REF_SS_PHY_EN |
		IPQ_SSUSB_QSCRATCH_SS_PHY_CTRL_LANE0_PWR_PRESENT),
		ipq_base + IPQ_SS_PHY_CTRL_REG);
	writel((DWC3_SSUSB_REG_GUSB2PHYCFG_SUSPENDUSB20 |
		DWC3_SSUSB_REG_GUSB2PHYCFG_ENBLSLPM |
		DWC3_SSUSB_REG_GUSB2PHYCFG_USBTRDTIM(9)),
		ipq_base + DWC3_SSUSB_REG_GUSB2PHYCFG(0));
	writel(DWC3_SSUSB_REG_GUSB3PIPECTL_ELASTIC_BUFFER_MODE |
		DWC3_SSUSB_REG_GUSB3PIPECTL_TX_DE_EPPHASIS(1) |
		DWC3_SSUSB_REG_GUSB3PIPECTL_TX_MARGIN(0)|
		DWC3_SSUSB_REG_GUSB3PIPECTL_DELAYP1TRANS |
		DWC3_SSUSB_REG_GUSB3PIPECTL_DELAYP1P2P3(1) |
		DWC3_SSUSB_REG_GUSB3PIPECTL_U1U2EXITFAIL_TO_RECOV |
		DWC3_SSUSB_REG_GUSB3PIPECTL_REQUEST_P1P2P3,
		ipq_base + DWC3_SSUSB_REG_GUSB3PIPECTL(0));
	writel(IPQ_SSUSB_REG_QSCRATCH_SS_PHY_PARAM_CTRL_1_LOS_LEVEL(0x9) |
		IPQ_SSUSB_REG_QSCRATCH_SS_PHY_PARAM_CTRL_1_TX_DEEMPH_3_5DB(0x17) |
		IPQ_SSUSB_REG_QSCRATCH_SS_PHY_PARAM_CTRL_1_TX_DEEMPH_6DB(0x20) |
		IPQ_SSUSB_REG_QSCRATCH_SS_PHY_PARAM_CTRL_1_TX_SWING_FULL(0x6E),
		ipq_base + IPQ_SS_PHY_PARAM_CTRL_1_REG);
	writel(IPQ_SSUSB_REG_QSCRATCH_GENERAL_CFG_XHCI_REV(DWC3_SSUSB_XHCI_REV_10),
		ipq_base + IPQ_QSCRATCH_GENERAL_CFG);
}

static void usb30_common_pre_init(int id, unsigned int ipq_base)
{
	unsigned int reg;

	if (id == 0)
		reg = USB30_RESET;
	else
		reg = USB30_1_RESET;

	writel(IPQ_USB30_RESET_PHY_ASYNC_RESET, reg);
	writel(IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET, reg);
	writel(IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
		IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET, reg);
	writel(IPQ_USB30_RESET_SLEEP_ASYNC_RESET |
		IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
		IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET, reg);
	writel(IPQ_USB30_RESET_MASTER_ASYNC_RESET |
		IPQ_USB30_RESET_SLEEP_ASYNC_RESET |
		IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
		IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET, reg);
	if (id == 0) {
		writel(IPQ_USB30_RESET_PORT2_HS_PHY_ASYNC_RESET |
			IPQ_USB30_RESET_MASTER_ASYNC_RESET |
			IPQ_USB30_RESET_SLEEP_ASYNC_RESET |
			IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
			IPQ_USB30_RESET_POWERON_ASYNC_RESET |
			IPQ_USB30_RESET_PHY_ASYNC_RESET, reg);
	}
	udelay(5);
	writel(IPQ_USB30_RESET_MASK & ~(IPQ_USB30_RESET_PHY_ASYNC_RESET), reg);
	writel(IPQ_USB30_RESET_MASK & ~(IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET), reg);
	writel(IPQ_USB30_RESET_MASK & ~(IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
		IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET), reg);
	writel(IPQ_USB30_RESET_MASK & ~(IPQ_USB30_RESET_SLEEP_ASYNC_RESET |
		IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
		IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET), reg);
	writel(IPQ_USB30_RESET_MASK & ~(IPQ_USB30_RESET_MASTER_ASYNC_RESET |
		IPQ_USB30_RESET_SLEEP_ASYNC_RESET|
		IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
		IPQ_USB30_RESET_POWERON_ASYNC_RESET |
		IPQ_USB30_RESET_PHY_ASYNC_RESET), reg);
	if (id == 0) {
		writel(IPQ_USB30_RESET_MASK &
			~(IPQ_USB30_RESET_PORT2_HS_PHY_ASYNC_RESET |
			IPQ_USB30_RESET_MASTER_ASYNC_RESET |
			IPQ_USB30_RESET_SLEEP_ASYNC_RESET |
			IPQ_USB30_RESET_MOC_UTMI_ASYNC_RESET |
			IPQ_USB30_RESET_POWERON_ASYNC_RESET |
			IPQ_USB30_RESET_PHY_ASYNC_RESET), reg);
		reg = IPQ_TCSR_USB_CONTROLLER_TYPE_SEL;
		if (reg) {
			qca_scm_usb_mode_write(reg, 0X3);
		}
	}
	writel((IPQ_SSUSB_REG_QSCRATCH_CGCTL_RAM1112_EN |
		IPQ_SSUSB_REG_QSCRATCH_CGCTL_RAM13_EN),
		ipq_base + IPQ_SSUSB_REG_QSCRATCH_CGCTL);
	writel((IPQ_SSUSB_REG_QSCRATCH_RAM1_RAM13_EN |
		IPQ_SSUSB_REG_QSCRATCH_RAM1RAM12_EN |
		IPQ_SSUSB_REG_QSCRATCH_RAM1_RAM11_EN),
		ipq_base + IPQ_SSUSB_REG_QSCRATCH_RAM1);
}

int ipq_board_usb_init(void)
{
	int i;
	unsigned int ipq_base;

	uint32_t flash_type;

	/*Return if it is recovery path*/
	if (ipq_smem_get_boot_flash(&flash_type) < 0)
		return -1;

	/* Configure the usb core clock */
	usb_ss_core_clock_config(0, 1, 5, 32);
	/* Configure the usb core clock */
	usb_ss_utmi_clock_config(0, 1, 40, 1);

	for (i = 0; i < CONFIG_USB_MAX_CONTROLLER_COUNT; i++) {

		if (i == 0)
			ipq_base = IPQ_XHCI_BASE_1;
		else
			ipq_base = IPQ_XHCI_BASE_2;

		usb30_common_pre_init(0, ipq_base);
		uw_ssusb_pre_init(ipq_base);
	}
	return 0;
}
#endif /* CONFIG_USB_XHCI_IPQ */

int apps_iscrashed(void)
{
	u32 *dmagic1 = (u32 *)0x2A03F000;
	u32 *dmagic2 = (u32 *)0x2A03F004;

	if (*dmagic1 == DLOAD_MAGIC_COOKIE_1
	    && *dmagic2 == DLOAD_MAGIC_COOKIE_2)
		return 1;

	return 0;
}

int ipq_get_tz_version(char *version_name, int buf_size)
{
	int ret;

	ret = scm_call(SCM_SVC_INFO, TZBSP_BUILD_VER_QUERY_CMD, NULL,
			0, version_name, BUILD_ID_LEN);
	if(ret)
		return -ENOMSG;

	snprintf(version_name, buf_size, "%s\n", version_name);
	return 0;
}

void forever(void) { while (1); }
extern void ak_secondary_cpu_init(void);
extern void ak_secondary_cpu_reinit(void);
extern void send_event(void);
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

	if (enable_sec_core)
		cmd.addr = (unsigned long)ak_secondary_cpu_init;
	else
		cmd.addr = (unsigned long)forever;

	cmd.flags = SCM_FLAG_COLDBOOT_CPU1;

	ret = scm_call(SCM_SVC_BOOT, SCM_BOOT_ADDR,
				&cmd, sizeof(cmd), NULL, 0);
	if (ret) {
		printf("--- %s: scm_call failed ret = %d\n", __func__, ret);
	}

	return ret;
}

void clear_l2cache_err(void)
{
        unsigned int val;
#ifndef CONFIG_SYS_DCACHE_OFF
        val = get_l2_indirect_reg(L2ESR_IND_ADDR);
#endif

#ifdef CONFIG_IPQ_REPORT_L2ERR
        report_l2err(val);
#endif

#ifndef CONFIG_SYS_DCACHE_OFF
        set_l2_indirect_reg(L2ESR_IND_ADDR, val);
#endif
}

static int dcache_old_status;

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

/**
 * Set the uuid in bootargs variable for mounting rootfilesystem
 */
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag)
{
	return 0;
}
int is_secondary_core_off(unsigned int cpuid)
{
	if (dcache_old_status)
		dcache_enable();
	return 1;
}

static int secondary_core_already_reset;
extern void wait_event(void (*)(void));

void bring_secondary_core_down(unsigned int state)
{
	wait_event(ak_secondary_cpu_reinit);
}

static int krait_release_secondary(void)
{
	dcache_disable();
	writel(0xa4, CPU1_APCS_SAW2_VCTL);
	barrier();
	udelay(512);

	writel(0x109, CPU1_APCS_CPU_PWR_CTL);
	writel(0x101, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(1);

	writel(0x121, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(2);

	writel(0x120, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(2);

	writel(0x100, CPU1_APCS_CPU_PWR_CTL);
	barrier();
	udelay(100);

	writel(0x180, CPU1_APCS_CPU_PWR_CTL);
	barrier();

	return 0;
}
int bring_sec_core_up(unsigned int cpuid, unsigned int entry, unsigned int arg)
{
	dcache_old_status = dcache_status();
	if (!secondary_core_already_reset) {
		secondary_core_already_reset = 1;
		if (scm_set_boot_addr(true) == 0) {
			/* Pull Core-1 out of reset, iff scm call succeeds */
			krait_release_secondary();
		}
	} else {
		dcache_disable();
		send_event();
	}
	return 0;
}
unsigned int get_dts_machid(unsigned int machid)
{
	switch (machid)
	{
		case MACH_TYPE_IPQ806X_AP148_1XX:
			return MACH_TYPE_IPQ806X_AP148;
		default:
			return machid;
	}
}

void uart_wait_tx_empty(void)
{
	ipq_serial_wait_tx_empty();
}
