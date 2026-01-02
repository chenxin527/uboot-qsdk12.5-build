/*
 * Copyright (c) 2016-2019, The Linux Foundation. All rights reserved.
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
#include <asm/global_data.h>
#include <asm/io.h>
#include <asm/errno.h>
#include <environment.h>
#include <fdtdec.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/scm.h>
#include <asm/arch-qca-common/iomap.h>
#include <ipq5332.h>
#include <spi.h>
#include <spi_flash.h>

#if defined(CONFIG_ART_COMPRESSED) &&   \
        (defined(CONFIG_GZIP) || defined(CONFIG_LZMA))
#ifndef CONFIG_COMPRESSED_LOAD_ADDR
#define CONFIG_COMPRESSED_LOAD_ADDR CONFIG_SYS_LOAD_ADDR
#endif
#include <mapmem.h>
#include <lzma/LzmaTools.h>
#endif

#ifdef CONFIG_QPIC_NAND
#include <asm/arch-qca-common/qpic_nand.h>
#include <nand.h>
#endif
#ifdef CONFIG_QCA_MMC
#include <mmc.h>
#include <sdhci.h>
#endif
#ifdef CONFIG_USB_XHCI_IPQ
#include <usb.h>
#endif

#define FLASH_SEL_BIT	7
#define LINUX_NAND_DTS "/soc/nand@79b0000/"
#define LINUX6_1_NAND_DTS "/soc@0/nand@79b0000/"
#define LINUX_MMC_DTS "/soc/sdhci@7804000/"
#define LINUX6_1_MMC_DTS "/soc@0/mmc@7804000/"
#define STATUS_OK "status%?okay"
#define STATUS_DISABLED "status%?disabled"

#define NSS_CC_PPE_BCR			0x39B003E4
#define GCC_UNIPHY0_BCR			0x1816000
#define GCC_UNIPHY1_BCR			0x1816014

DECLARE_GLOBAL_DATA_PTR;

unsigned long fuse_addr[FUSE_CNT] = {
		0x000A00D0,
		0x000A00E8,
		0x000A00F0,
		0x000A00F8,
		0x000A0100,
		0x000A0108,
		0x000A0110,
		0x000A0118,
};

static int aq_phy_initialised = 0;
extern int ipq5332_edma_init(void *cfg);
extern int ipq_spi_init(u16);

const char *rsvd_node = "/reserved-memory";
const char *del_node[] = {"uboot",
			  "sbl",
			  NULL};
const add_node_t add_fdt_node[] = {{}};

unsigned int qpic_frequency = 0, qpic_phase = 0;

#ifdef CONFIG_QCA_MMC
struct sdhci_host mmc_host;
#endif

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
#ifndef CONFIG_IPQ_TINY
	{ "EBICS2.BIN", 0x60000000, 0x20000000, 0, 0, 0, 0, 1 },
	{ "EBICS1.BIN", CONFIG_UBOOT_END_ADDR, 0x10000000, 0, 0, 0, 0, 1 },
	{ "EBICS0.BIN", 0x40000000, CONFIG_QCA_UBOOT_OFFSET, 0, 0, 0, 0, 1 },
#endif
	{ "IMEM.BIN", 0x08600000, 0x00001000, 0 },
	{ "IMEM2.BIN", 0x860F000, 0x00001000, 0 },
	{ "UNAME.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "CPU_INFO.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "DMESG.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "PT.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
	{ "WLAN_MOD.BIN", 0, 0, 0, 0, 0, MINIMAL_DUMP },
};
int dump_entries_n = ARRAY_SIZE(dumpinfo_n);

#ifdef CONFIG_IPQ_FDT_FIXUP
void fdt_fixup_flash(void *blob)
{
	uint32_t flash_type = SMEM_BOOT_NO_FLASH;
	int nand_nodeoff = fdt_path_offset(blob, LINUX_NAND_DTS);
	int mmc_nodeoff = fdt_path_offset(blob, LINUX_MMC_DTS);

	get_current_flash_type(&flash_type);
	if (flash_type == SMEM_BOOT_NORPLUSEMMC ||
		flash_type == SMEM_BOOT_MMC_FLASH ) {
		(nand_nodeoff >= 0) ?
			parse_fdt_fixup(LINUX_NAND_DTS"%"STATUS_DISABLED, blob) :
			parse_fdt_fixup(LINUX6_1_NAND_DTS"%"STATUS_DISABLED,
					blob);
		(mmc_nodeoff >= 0) ?
			parse_fdt_fixup(LINUX_MMC_DTS"%"STATUS_OK, blob) :
			parse_fdt_fixup(LINUX6_1_MMC_DTS"%"STATUS_OK, blob);
	}
	return;
}
#endif

#ifdef CONFIG_IPQ_TINY_SPI_NOR
void fdt_fixup_art_format(void *blob)
{
	int nodeoffset;
	int ret;

	nodeoffset = fdt_path_offset(blob, "/");
	ret = fdt_setprop(blob, nodeoffset, "compressed_art", NULL, 0);
	if (ret != 0)
		printf("fdt-fixup: unable to set property 'compressed_art'\n");
}
#endif

void qca_serial_init(struct ipq_serial_platdata *plat)
{
	int ret;

	if (plat->gpio_node >= 0) {
		qca_gpio_init(plat->gpio_node);
	}

	plat->port_id = UART_PORT_ID(plat->reg_base);
	ret = uart_clock_config(plat);
	if (ret)
		printf("UART clock config failed %d\n", ret);

	return;
}

void reset_board(void)
{
	run_command("reset", 0);
}

/*
 * Set the uuid in bootargs variable for mounting rootfilesystem
 */
#ifdef CONFIG_QCA_MMC
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen,
			bool gpt_flag)
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
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen,
			bool gpt_flag)
{
	return 0;
}
#endif

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

__weak void board_mmc_deinit(void)
{
	/*since we do not have misc register in ipq5332
	 * so simply return from this function
	 */
	return;
}

int do_mmc_init(void)
{
	int node, gpio_node;

	node = fdt_path_offset(gd->fdt_blob, "mmc");
	if (node < 0) {
		printf("sdhci: Node Not found, skipping initialization\n");
		return -1;
	}

	if (!fdtdec_get_is_enabled(gd->fdt_blob, node)) {
		printf("MMC: disabled, skipping initialization\n");
		return -1;
	}

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "mmc_gpio");
	if (node >= 0)
		qca_gpio_init(gpio_node);

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

	return 0;
}

int board_mmc_init(bd_t *bis)
{
	int ret = 0;
	uint32_t flash_type = SMEM_BOOT_NO_FLASH;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;
	char *name = NULL;
#ifdef CONFIG_QPIC_SERIAL
	name = nand_info[CONFIG_NAND_FLASH_INFO_IDX].name;
#endif

	get_current_flash_type(&flash_type);

	if (flash_type != SMEM_BOOT_NORPLUSNAND &&
		flash_type !=  SMEM_BOOT_QSPI_NAND_FLASH &&
		!name)
		ret = do_mmc_init();

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
#ifdef CONFIG_PCI_IPQ
void pcie_reset(int pcie_id)
{
	u32 reg_val;

	switch(pcie_id) {
	case 0:
		reg_val = readl(GCC_PCIE3X1_0_BCR);
		writel(reg_val | GCC_PCIE_BCR_ENABLE, GCC_PCIE3X1_0_BCR);
		mdelay(1);
		writel(reg_val & (~GCC_PCIE_BCR_ENABLE), GCC_PCIE3X1_0_BCR);

		reg_val = readl(GCC_PCIE3X1_0_PHY_BCR);
		writel(reg_val | GCC_PCIE_BLK_ARES, GCC_PCIE3X1_0_PHY_BCR);
		mdelay(1);
		writel(reg_val & (~GCC_PCIE_BLK_ARES), GCC_PCIE3X1_0_PHY_BCR);

		break;
	case 1:
		reg_val = readl(GCC_PCIE3X2_BCR);
		writel(reg_val | GCC_PCIE_BCR_ENABLE, GCC_PCIE3X2_BCR);
		mdelay(1);
		writel(reg_val & (~GCC_PCIE_BCR_ENABLE), GCC_PCIE3X2_BCR);

		reg_val = readl(GCC_PCIE3X2_PHY_BCR);
		writel(reg_val | GCC_PCIE_BLK_ARES, GCC_PCIE3X2_PHY_BCR);
		mdelay(1);
		writel(reg_val & (~GCC_PCIE_BLK_ARES), GCC_PCIE3X2_PHY_BCR);

		break;
	case 2:
		reg_val = readl(GCC_PCIE3X1_1_BCR);
		writel(reg_val | GCC_PCIE_BCR_ENABLE, GCC_PCIE3X1_1_BCR);
		mdelay(1);
		writel(reg_val & (~GCC_PCIE_BCR_ENABLE), GCC_PCIE3X1_1_BCR);

		reg_val = readl(GCC_PCIE3X1_1_PHY_BCR);
		writel(reg_val | GCC_PCIE_BLK_ARES, GCC_PCIE3X1_1_PHY_BCR);
		mdelay(1);
		writel(reg_val & (~GCC_PCIE_BLK_ARES), GCC_PCIE3X1_1_PHY_BCR);

		break;
	}
}

int ipq_validate_qfrom_fuse(unsigned int reg_add, int pos)
{
	return (readl(reg_add) & (1 << pos));
}

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
	}

	return ipq_validate_qfrom_fuse(
			QFPROM_CORR_FEATURE_CONFIG_ROW1_MSB, pos);
}

void board_pci_init(int id)
{
	int node, gpio_node, ret, lane;
	char name[16];
	struct fdt_resource pci_rst;

	snprintf(name, sizeof(name), "pci%d", id);
	node = fdt_path_offset(gd->fdt_blob, name);
	if (node < 0) {
		printf("Could not find PCI%d in device tree\n", id);
		return;
	}

	gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);

	lane = fdtdec_get_int(gd->fdt_blob, node, "lane", 1);

	/*
	 * setting dual port mode if PCIE1 & PCIE2 come up with 1 lane.
	 */
	if ((id == 1) || (id ==2)) {
		if (lane == 1)
			writel(TWO_PORT_MODE,
				(void *)TCSR_MODE_CTRL_2PORT_2LANE);
		else
			writel(TWO_LANE_MODE,
				(void *)TCSR_MODE_CTRL_2PORT_2LANE);
		mdelay(10);
	}

	ret = fdt_get_named_resource(gd->fdt_blob, node, "reg",
				"reg-names", "pci_rst", &pci_rst);
	if (ret == 0) {
		set_mdelay_clearbits_le32(pci_rst.start, 0x1, 10);
		set_mdelay_clearbits_le32(pci_rst.end + 1, 0x1, 10);
	}

	pcie_reset(id);
	pcie_v2_clock_init(id);

	return;
}

void board_pci_deinit()
{
	int node, gpio_node, i, err;
	char name[16];
	struct fdt_resource parf;

	for (i = 0; i < PCI_MAX_DEVICES; i++) {
		snprintf(name, sizeof(name), "pci%d", i);
		node = fdt_path_offset(gd->fdt_blob, name);
		if (node < 0) {
			printf("Could not find PCI%d in device tree\n", i);
			continue;
		}
		err = fdt_get_named_resource(gd->fdt_blob, node, "reg",
				"reg-names", "parf", &parf);
		if (err < 0) {
			printf("Unable to find parf node for PCIE%d \n", i);
			continue;
		}

		writel(0x0, parf.start + PCIE_PARF_SLV_ADDR_SPACE_SIZE);
		writel(PCIE_PHY_TEST_PWR_DOWN,
				parf.start + PCIE_PARF_PHY_CTRL);

		gpio_node = fdt_subnode_offset(gd->fdt_blob, node, "pci_gpio");
		if (gpio_node >= 0)
			qca_gpio_deinit(gpio_node);

		pcie_v2_clock_deinit(i);
		pcie_reset(i);
	}

	return;
}
#endif

 /*
  * Gets the Caldata from the ART partition table and return the value
  */
int get_eth_caldata(u32 *caldata, u32 offset)
{
	s32 ret = 0 ;
	u32 flash_type=0u;
	u32 start_blocks;
	u32 size_blocks;
	u32 art_offset=0U ;
	u32 length = 4;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	struct spi_flash *flash = NULL;

#if defined(CONFIG_ART_COMPRESSED) && (defined(CONFIG_GZIP) || defined(CONFIG_LZMA))
	void *load_buf, *image_buf;
	unsigned long img_size;
	unsigned long desMaxSize;
#endif

#ifdef CONFIG_QCA_MMC
	block_dev_desc_t *blk_dev;
	disk_partition_t disk_info;
	struct mmc *mmc;
	char mmc_blks[512];
#endif

	if (sfi->flash_type == SMEM_BOOT_NO_FLASH)
		return -1;

	if ((sfi->flash_type == SMEM_BOOT_SPI_FLASH) ||
		(sfi->flash_type == SMEM_BOOT_NOR_FLASH) ||
		(sfi->flash_type == SMEM_BOOT_NORPLUSNAND) ||
		(sfi->flash_type == SMEM_BOOT_NORPLUSEMMC))
	{
		ret = smem_getpart("0:ART", &start_blocks, &size_blocks);
		if (ret < 0) {
			printf("No ART partition found\n");
			return ret;
		}

		/*
		* ART partition 0th position.
		*/
		art_offset = (u32)((u32) qca_smem_flash_info.flash_block_size * start_blocks);

#ifndef CONFIG_ART_COMPRESSED
		art_offset = (art_offset + offset);
#endif

		flash = spi_flash_probe(CONFIG_SF_DEFAULT_BUS, CONFIG_SF_DEFAULT_CS,
				CONFIG_SF_DEFAULT_SPEED, CONFIG_SF_DEFAULT_MODE);


		if (flash == NULL){
			printf("No SPI flash device found\n");
			ret = -1;
		} else {
#if defined(CONFIG_ART_COMPRESSED) && defined(CONFIG_LZMA)
		image_buf = map_sysmem(CONFIG_COMPRESSED_LOAD_ADDR, 0);
		load_buf = map_sysmem(CONFIG_COMPRESSED_LOAD_ADDR + 0x100000, 0);
		img_size = qca_smem_flash_info.flash_block_size * size_blocks;
		desMaxSize = 0x100000;
		ret = spi_flash_read(flash, art_offset, img_size, image_buf);
		if (ret == 0) {
			ret = -1;
#ifdef CONFIG_LZMA
			if (ret != 0){

			ret = lzmaBuffToBuffDecompress(load_buf,
				(SizeT *)&desMaxSize,
				image_buf,
				(SizeT)img_size);
			}
#endif
			if((!ret) && (memcpy(caldata, load_buf + offset , length))){}
			else {
				printf("Invalid compression type..\n");
				ret = -1;
			}
		}
#else
			ret = spi_flash_read(flash, art_offset, length, caldata);
#endif
		}

		if (ret < 0)
			printf("ART partition read failed..\n");
	}
#ifdef CONFIG_QPIC_NAND
	else if ((sfi->flash_type == SMEM_BOOT_NAND_FLASH ) || (sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH))
	{
		if (qca_smem_flash_info.flash_type == SMEM_BOOT_SPI_FLASH)
			flash_type = CONFIG_SPI_FLASH_INFO_IDX;
		else{
			flash_type = CONFIG_NAND_FLASH_INFO_IDX;
		}

		ret = smem_getpart("0:ART", &start_blocks, &size_blocks);
		if (ret < 0) {
			printf("No ART partition found\n");
			return ret;
		}

		/*
		* ART partition 0th position.
		*/
		art_offset = (u32)((u32) qca_smem_flash_info.flash_block_size * start_blocks);
		art_offset = /*(loff_t)*/(art_offset + offset);

		ret = nand_read(&nand_info[flash_type],art_offset, &length,(u_char*) caldata);

		if (ret < 0)
		printf("ART partition read failed..\n");
	}
#endif
	else{
#ifdef CONFIG_QCA_MMC
		blk_dev = mmc_get_dev(mmc_host.dev_num);
		ret = get_partition_info_efi_by_name(blk_dev, "0:ART", &disk_info);
		/*
		* ART partition 0th position will contain MAC address.
		* Read 1 block.
		*/
		if (ret == 0) {
			mmc = mmc_host.mmc;
			ret = mmc->block_dev.block_read
				(mmc_host.dev_num, (disk_info.start+(offset/512)),
						1, mmc_blks);
			memcpy(caldata, (mmc_blks+(offset%512)), length);
		}
		if (ret < 0)
			printf("ART partition read failed..\n");
#endif
	}

	/*
	*  Avoid unused warning
	*  */
	(void)flash_type;

	return ret;

}

void board_update_caldata(void)
{
	u32 reg_val=0u;
	s32 ret = 0 ;
	u32 u32_calDataOffset = 0U;
	u32 u32_calData = 0u;
	u32 u32_CDACIN =0U, u32_CDACOUT = 0u;
	int node_off,slotId;

	node_off = fdt_path_offset(gd->fdt_blob, "/slot_Id");
	if (node_off < 0) {
		printf("Default CapIn/CapOut values used\n");
		return;
         }

	slotId = fdtdec_get_uint(gd->fdt_blob,node_off, "slotId", 0);

	u32_calDataOffset  = (u32)(((slotId*150)+4)*1024 + 0x66c4);
	ret = get_eth_caldata(&u32_calData,u32_calDataOffset);
	if (ret < 0)
		return;

	u32_CDACIN = u32_calData & 0x3FF;
	u32_CDACOUT = (u32_calData >> 16) & 0x1FFu;

	if(((u32_CDACIN == 0x0u) || (u32_CDACIN == 0x3FFu)) && ((u32_CDACOUT == 0x0u) || (u32_CDACOUT == 0x1FFu)))
	{
		u32_CDACIN = 0x230;
		u32_CDACOUT = 0xB0;
	}
	u32_CDACIN = u32_CDACIN<<22u;
	u32_CDACOUT = u32_CDACOUT<<13u;

	qca_scm_call_read(0x2, 0x22, (u32 *)PHYA0_RFA_RFA_RFA_OTP_OTP_OV_1,&reg_val);
	reg_val = (reg_val & 0xFFF9FFFF) | (0x3 << 17u);
	qca_scm_call_write(0x2, 0x23,(u32 *)PHYA0_RFA_RFA_RFA_OTP_OTP_OV_1, reg_val);

	qca_scm_call_read(0x2, 0x22, (u32 *)PHYA0_RFA_RFA_RFA_OTP_OTP_XO_0,&reg_val);

	if((u32_CDACIN == (reg_val & (0x3FF<<22u))) && (u32_CDACOUT == (reg_val & (0x1FF<<13u))))
	{
		printf("ART data same as PHYA0_RFA_RFA_RFA_OTP_OTP_XO_0\n");
		return;
	}

	reg_val = ((reg_val&0x00001FFF) | ((u32_CDACIN | u32_CDACOUT)&(~0x00001FFF)));
	qca_scm_call_write(0x2, 0x23,(u32 *)PHYA0_RFA_RFA_RFA_OTP_OTP_XO_0, reg_val);
}

#ifdef CONFIG_USB_XHCI_IPQ
void board_usb_deinit(int id)
{
	int nodeoff, ssphy;
	char node_name[8];

	snprintf(node_name, sizeof(node_name), "usb%d", id);
	nodeoff = fdt_path_offset(gd->fdt_blob, node_name);
	if (fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0))
		return;

	ssphy = fdtdec_get_int(gd->fdt_blob, nodeoff, "ssphy", 0);
	/* Enable USB PHY Power down */
	setbits_le32(QUSB2PHY_BASE + 0xA4, 0x0);
	/* Disable clocks */
	usb_clock_deinit();
	/* GCC_QUSB2_0_PHY_BCR */
	set_mdelay_clearbits_le32(GCC_QUSB2_0_PHY_BCR, 0x1, 10);
	/* GCC_USB0_PHY_BCR */
	if (ssphy)
		set_mdelay_clearbits_le32(GCC_USB0_PHY_BCR, 0x1, 10);
	/* GCC Reset USB BCR */
	set_mdelay_clearbits_le32(GCC_USB_BCR, 0x1, 10);
	/* Deselect the usb phy mux */
	if (ssphy)
		writel(TCSR_USB_PCIE_SEL_PCI, TCSR_USB_PCIE_SEL);

}

static void usb_init_hsphy(void __iomem *phybase, int ssphy)
{
	if (!ssphy) {
		/*Enable utmi instead of pipe*/
		writel((readl(USB30_GENERAL_CFG) |
			PIPE_UTMI_CLK_DIS), USB30_GENERAL_CFG);
		udelay(100);
		writel((readl(USB30_GENERAL_CFG) |
			PIPE_UTMI_CLK_SEL | PIPE3_PHYSTATUS_SW),
			USB30_GENERAL_CFG);
		udelay(100);
		writel((readl(USB30_GENERAL_CFG) &
			~PIPE_UTMI_CLK_DIS), USB30_GENERAL_CFG);
	}
	/* Disable USB PHY Power down */
	setbits_le32(phybase + 0xA4, 0x1);
	/* Enable override ctrl */
	writel(UTMI_PHY_OVERRIDE_EN, phybase + USB_PHY_CFG0);
	/* Enable POR*/
	writel(POR_EN, phybase + USB_PHY_UTMI_CTRL5);
	udelay(15);
	/* Configure frequency select value*/
	writel(FREQ_SEL, phybase + USB_PHY_FSEL_SEL);
	/* Configure refclk frequency */

	writel(COMMONONN | FSEL_VALUE | RETENABLEN,
			phybase + USB_PHY_HS_PHY_CTRL_COMMON0);

	writel(POR_EN & ATERESET,
		phybase + USB_PHY_UTMI_CTRL5);

	writel(USB2_SUSPEND_N_SEL | USB2_SUSPEND_N | USB2_UTMI_CLK_EN,
			phybase + USB_PHY_HS_PHY_CTRL2);

	writel(XCFG_COARSE_TUNE_NUM | XCFG_FINE_TUNE_NUM,
		phybase + USB2PHY_USB_PHY_M31_XCFGI_11);

	/* Adjust HSTX slew rate to 400 ps*/
	/* Adjust PLL lock Time counter for release clock to 35uA */
	/* Adjust Manual control ODT value to 38.02 Ohm */
	writel(HSTX_SLEW_RATE_400PS | PLL_CHARGING_PUMP_CURRENT_35UA |
		ODT_VALUE_38_02_OHM, phybase + USB2PHY_USB_PHY_M31_XCFGI_4);

	/*
	* Enable to always turn on USB 2.0 TX driver
	* when system is in USB 2.0 HS mode
	*/
	writel(USB2_0_TX_ENABLE, phybase + USB2PHY_USB_PHY_M31_XCFGI_1);

	/* Adjust HSTX Pre-emphasis level to 0.55mA */
	writel(HSTX_PRE_EMPHASIS_LEVEL_0_55MA,
		phybase + USB2PHY_USB_PHY_M31_XCFGI_5);

	/*
	* Adjust HSTX Current of current-mode driver,
	* default 18.5mA * 22.5ohm = 416mV
	* 17.1mA * 22.5ohm = 385mV
	*/
	writel(HSTX_CURRENT_17_1MA_385MV,
		phybase + USB2PHY_USB_PHY_M31_XCFGI_9);

	udelay(10);

	writel(0, phybase + USB_PHY_UTMI_CTRL5);

	writel(USB2_SUSPEND_N | USB2_UTMI_CLK_EN,
		phybase + USB_PHY_HS_PHY_CTRL2);
}

static void usb_init_ssphy(void __iomem *phybase)
{
	writel(CLK_ENABLE, GCC_PCIE3X1_PHY_AHB_CBCR);
	writel(CLK_ENABLE, GCC_USB0_PHY_CFG_AHB_CBCR);
	writel(CLK_ENABLE, GCC_USB0_PIPE_CBCR);
	udelay(100);
	writel(APB_REG_UPHY_RX_RESCAL_CODE | APB_REG_UPHY_RX_AFE_CAP1 |
		APB_REG_UPHY_RX_AFE_RES1, PCIE_USB_COMBO_PHY_CFG_RX_AFE_2);
	writel(APB_REG_UPHY_RXD_BIT_WIDTH | APB_REG_UPHY_RX_PLOOP_GAIN |
		APB_REG_UPHY_RX_DLF_RATE | APB_UPHY_RX_PLOOP_EN |
		APB_REG_UPHY_RX_CDR_EN, PCIE_USB_COMBO_PHY_CFG_RX_DLF_DEMUX_2);
	writel(APB_REG_FLOOP_GAIN, PCIE_USB_COMBO_PHY_CFG_MISC1);

	return;
}

static void usb_init_phy(int ssphy)
{
	void __iomem *boot_clk_ctl, *usb_bcr, *qusb2_phy_bcr;

	boot_clk_ctl = (u32 *)GCC_USB0_BOOT_CLOCK_CTL;
	usb_bcr = (u32 *)GCC_USB_BCR;
	qusb2_phy_bcr = (u32 *)GCC_QUSB2_0_PHY_BCR;

	/* Disable USB Boot Clock */
	clrbits_le32(boot_clk_ctl, 0x0);

	/* GCC Reset USB BCR */
	set_mdelay_clearbits_le32(usb_bcr, 0x1, 10);

	if (ssphy)
		setbits_le32(GCC_USB0_PHY_BCR, 0x1);
	setbits_le32(qusb2_phy_bcr, 0x1);
	udelay(1);
	/* Config user control register */
	writel(0x4004010, USB30_GUCTL);
	writel(0x4945920, USB30_FLADJ);
	if (ssphy)
		clrbits_le32(GCC_USB0_PHY_BCR, 0x1);
	clrbits_le32(qusb2_phy_bcr, 0x1);
	udelay(30);

	if (ssphy)
		usb_init_ssphy((u32 *)USB3PHY_APB_BASE);
	usb_init_hsphy((u32 *)QUSB2PHY_BASE, ssphy);
}

int ipq_board_usb_init(void)
{
	int nodeoff, ssphy;

	nodeoff = fdt_path_offset(gd->fdt_blob, "usb0");
	if (nodeoff < 0){
		printf("USB: Node Not found,skipping initialization\n");
		return 0;
	}

	ssphy = fdtdec_get_int(gd->fdt_blob, nodeoff, "ssphy", 0);
	if (!fdtdec_get_int(gd->fdt_blob, nodeoff, "qcom,emulation", 0)) {
		/* select usb phy mux */
		if (ssphy)
			writel(TCSR_USB_PCIE_SEL_USB,
				TCSR_USB_PCIE_SEL);
		usb_clock_init();
		usb_init_phy(ssphy);
	} else {
		/* Config user control register */
		writel(0x0C804010, USB30_GUCTL);
	}

	return 0;
}
#endif

unsigned int get_dts_machid(unsigned int machid)
{
	switch (machid)
	{
		case MACH_TYPE_IPQ5332_AP_MI01_2_C2:
			return MACH_TYPE_IPQ5332_AP_MI01_2;
		case MACH_TYPE_IPQ5332_AP_MI01_3_C2:
			return MACH_TYPE_IPQ5332_AP_MI01_3;
		case MACH_TYPE_IPQ5332_AP_MI01_3_C3:
			return MACH_TYPE_IPQ5332_AP_MI01_3;
		case MACH_TYPE_IPQ5332_AP_MI01_7:
			return MACH_TYPE_IPQ5332_AP_MI01_13;
		case MACH_TYPE_IPQ5332_AP_MI01_14:
			return MACH_TYPE_IPQ5332_AP_MI01_12;
		case MACH_TYPE_IPQ5332_AP_MI04_1_C2:
			return MACH_TYPE_IPQ5332_AP_MI04_1;
		default:
			return machid;
	}
}

void ipq_uboot_fdt_fixup(void)
{
	init_config_list();
	switch (gd->bd->bi_arch_number)
	{
		case MACH_TYPE_IPQ5332_AP_MI01_2_C2:
			add_config_entry("config@mi01.2-c2");
			add_config_entry("config-mi01.2-c2");
			add_config_entry("config@rdp484");
			add_config_entry("config-rdp484");
			break;
		case MACH_TYPE_IPQ5332_AP_MI01_3_C2:
			add_config_entry("config@mi01.3-c2");
			add_config_entry("config-mi01.3-c2");
			add_config_entry("config@rdp477");
			add_config_entry("config-rdp477");
			break;
		case MACH_TYPE_IPQ5332_AP_MI01_3_C3:
			add_config_entry("config@mi01.3-c3");
			add_config_entry("config-mi01.3-c3");
			add_config_entry("config@rdp486");
			add_config_entry("config-rdp486");
			break;
		case MACH_TYPE_IPQ5332_AP_MI01_7:
			add_config_entry("config@mi01.7");
			add_config_entry("config-mi01.7");
			add_config_entry("config@rdp473");
			add_config_entry("config-rdp473");
			break;
		case MACH_TYPE_IPQ5332_AP_MI04_1_C2:
			add_config_entry("config@mi04.1-c2");
			add_config_entry("config-mi04.1-c2");
			add_config_entry("config@rdp478");
			add_config_entry("config-rdp478");
			add_config_entry("config@1");
			add_config_entry("config-1");
			break;
		case MACH_TYPE_IPQ5332_AP_MI01_14:
			add_config_entry("config@mi01.14");
			add_config_entry("config-mi01.14");
			add_config_entry("config@rdp481");
			add_config_entry("config-rdp481");
			break;
		default:
			add_config_list_from_fdt();
	}
	return;
}

__weak int ipq_get_tz_version(char *version_name, int buf_size)
{
	return 1;
}

int ipq_read_tcsr_boot_misc(void)
{
	u32 dmagic;
	int ret;
	long feat_avail;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	/* In recovery path, we dont have TZ. So, skipping
	 * dload magic read
	 */
	if (sfi->flash_type == SMEM_BOOT_NO_FLASH)
		return 0;

	/* The TCSR dload register is protected in latest TZ.
	 * Old TZ will allow direct read.
	 * Use the qca_scm_is_feature_available() call to know
	 * if TZ supports direct or scm read. Based on return
	 * value, read the TCSR dload register appropriately.
	 */
	feat_avail = qca_scm_is_feature_available(0x6);
	if (feat_avail == 0x401000) {
		if (is_scm_armv8()) {
			ret = qca_scm_call_read(SCM_SVC_IO, SCM_IO_READ,
					TCSR_BOOT_MISC_REG, &dmagic);
			if (ret)
				return 0;
		}
		else
			return 0;
	}
	else {
		dmagic = *(TCSR_BOOT_MISC_REG);
	}

	return dmagic;
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

void psci_sys_reset(void)
{
	__invoke_psci_fn_smc(PSCI_RESET_SMC_ID, 0, 0, 0);
}

void qti_scm_pshold(void)
{
	return;
}

void reset_cpu(unsigned long a)
{
	reset_crashdump();

	psci_sys_reset();

	while(1);
}

#ifdef CONFIG_QPIC_SERIAL
void do_nand_init(void)
{
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
}
#endif

void board_nand_init(void)
{
#ifdef CONFIG_QPIC_SERIAL
	uint32_t flash_type = SMEM_BOOT_NO_FLASH;

	get_current_flash_type(&flash_type);
	if (flash_type != SMEM_BOOT_NORPLUSEMMC &&
		flash_type != SMEM_BOOT_MMC_FLASH)
		do_nand_init();
#endif
#ifdef CONFIG_QCA_SPI
	int gpio_node;
	gpio_node = fdt_path_offset(gd->fdt_blob, "/spi/spi_gpio");
	if (gpio_node >= 0) {
		qca_gpio_init(gpio_node);
		spi_clock_init(0);
#ifdef CONFIG_MTD_DEVICE
		ipq_spi_init(CONFIG_IPQ_SPI_NOR_INFO_IDX);
#endif
	}
#endif
}

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

unsigned long timer_read_counter(void)
{
	return 0;
}

void set_flash_secondary_type(qca_smem_flash_info_t *smem)
{
	return;
};

int get_soc_hw_version(void)
{
	return readl(TCSR_SOC_HW_VERSION_REG);
}

#ifdef CONFIG_IPQ5332_EDMA
void set_function_select_as_mdc_mdio(void)
{
	int gpio_node;

	gpio_node = fdt_path_offset(gd->fdt_blob, "/ess-switch/mdio_gpio");
	if (gpio_node >= 0)
		qca_gpio_init(gpio_node);
	else
		printf("mdio gpio not detect \n");
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

int get_qca8033_gpio(int qca8033_gpio[2])
{
	int qca8033_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		qca8033_gpio_cnt =
			fdtdec_get_uint(gd->fdt_blob, node,
				"qca8033_gpio_cnt", -1);
		if (qca8033_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node,
				"qca8033_gpio", (u32 *)qca8033_gpio,
				qca8033_gpio_cnt);
			if (res >= 0)
				return qca8033_gpio_cnt;
		}
	}

	return res;
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
					cfg = GPIO_OE | GPIO_DRV_2_MA | GPIO_PULL_UP;
					writel(cfg, aquantia_gpio_base);
					writel(0x0, GPIO_IN_OUT_ADDR(aquantia_gpio[i]));
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

	qca808x_gpio_cnt = get_qca808x_gpio(qca808x_gpio);
	if (qca808x_gpio_cnt >= 1) {
		for (i = 0; i < qca808x_gpio_cnt; i++) {
			if (qca808x_gpio[i] >= 0) {
				qca808x_gpio_base = (unsigned int *)
					GPIO_CONFIG_ADDR(qca808x_gpio[i]);
				writel(0x203, qca808x_gpio_base);
				gpio_set_value(qca808x_gpio[i], 0x0);
			}
		}
	}
}

void aquantia_phy_reset_init_done(void)
{
	int aquantia_gpio[2] = {-1, -1}, aquantia_gpio_cnt, i;

	aquantia_gpio_cnt = get_aquantia_gpio(aquantia_gpio);
	if (aquantia_gpio_cnt >= 1) {
		for (i = 0; i < aquantia_gpio_cnt; i++) {
			gpio_set_value(aquantia_gpio[i], 0x1);
			writel(0x3, GPIO_IN_OUT_ADDR(aquantia_gpio[i]));
			mdelay(500);
		}
	}
}

void qca808x_phy_reset_init_done(void)
{
	int qca808x_gpio[2] = {-1, -1}, qca808x_gpio_cnt, i;

	qca808x_gpio_cnt = get_qca808x_gpio(qca808x_gpio);
	if (qca808x_gpio_cnt >= 1) {
		for (i = 0; i < qca808x_gpio_cnt; i++)
			gpio_set_value(qca808x_gpio[i], 0x3);
	}
}

int get_sfp_gpio(int sfp_gpio[2])
{
	int sfp_gpio_cnt = -1, node;
	int res = -1;

	node = fdt_path_offset(gd->fdt_blob, "/ess-switch");
	if (node >= 0) {
		sfp_gpio_cnt = fdtdec_get_uint(gd->fdt_blob, node,
				"sfp_gpio_cnt", -1);
		if (sfp_gpio_cnt >= 1) {
			res = fdtdec_get_int_array(gd->fdt_blob, node,
							"sfp_gpio",
							(u32 *)sfp_gpio,
							sfp_gpio_cnt);
			if (res >= 0)
				return sfp_gpio_cnt;
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
				sfp_gpio_base =
					(unsigned int *)GPIO_CONFIG_ADDR(
								sfp_gpio[i]);
				cfg = GPIO_OE | GPIO_DRV_8_MA | GPIO_PULL_UP;
				writel(cfg, sfp_gpio_base);
			}
		}
	}
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

void qca8081_napa_reset(void)
{
	int napa_gpio[2] = {-1, -1}, napa_gpio_cnt, i;
	unsigned int *napa_gpio_base;
	uint32_t cfg;

	napa_gpio_cnt = get_napa_gpio(napa_gpio);
	if (napa_gpio_cnt >= 1) {
		for (i = 0; i < napa_gpio_cnt; i++) {
			if (napa_gpio[i] >= 0) {
				napa_gpio_base =
					(unsigned int *)GPIO_CONFIG_ADDR(
								napa_gpio[i]);
				cfg = GPIO_OE | GPIO_DRV_8_MA | GPIO_PULL_UP;
				writel(cfg, napa_gpio_base);
				mdelay(100);
				gpio_set_value(napa_gpio[i], 0x1);
			}
		}
	}
}

void qca8033_phy_reset(void)
{
	int qca8033_gpio[2] = {-1, -1}, qca8033_gpio_cnt, i;
	unsigned int *qca8033_gpio_base;
	uint32_t cfg;

	qca8033_gpio_cnt = get_qca8033_gpio(qca8033_gpio);
	if (qca8033_gpio_cnt >= 1) {
		for (i = 0; i < qca8033_gpio_cnt; i++) {
			if (qca8033_gpio[i] >= 0) {
				qca8033_gpio_base =
					(unsigned int *)GPIO_CONFIG_ADDR(
					qca8033_gpio[i]);
				cfg = GPIO_OE | GPIO_DRV_2_MA | GPIO_PULL_UP;
				writel(cfg, qca8033_gpio_base);
				writel(0x0, GPIO_IN_OUT_ADDR(qca8033_gpio[i]));
				mdelay(100);
				writel(0x3, GPIO_IN_OUT_ADDR(qca8033_gpio[i]));
			}
		}
	}
}

void bring_phy_out_of_reset(void)
{
	qca8081_napa_reset();
	aquantia_phy_reset_init();
	qca808x_phy_reset_init();
	sfp_reset_init();
	mdelay(500);
	aquantia_phy_reset_init_done();
	qca808x_phy_reset_init_done();
}

void ipq5332_eth_initialize(void)
{
	eth_clock_init();

	set_function_select_as_mdc_mdio();

	bring_phy_out_of_reset();
}

int board_eth_init(bd_t *bis)
{
	int ret = 0;

	set_mdelay_clearbits_le32(NSS_CC_PPE_BCR, 0x1, 100);
	set_mdelay_clearbits_le32(GCC_UNIPHY0_BCR, 0x1, 10);
	set_mdelay_clearbits_le32(GCC_UNIPHY1_BCR, 0x1, 10);

	ipq5332_eth_initialize();

	ret = ipq5332_edma_init(NULL);
	if (ret != 0)
		printf("%s: ipq5332_edma_init failed : %d\n", __func__, ret);
	board_update_caldata();
	return ret;
}
#endif
