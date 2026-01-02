/*
 * Copyright (c) 2017-2019, 2021, The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2022, Qualcomm Innovation Center, Inc. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */
#include <common.h>
#include <net.h>
#include <asm-generic/errno.h>
#include <asm/io.h>
#include <malloc.h>
#include <phy.h>
#include <miiphy.h>
#include "ipq_phy.h"
#include "ipq_aquantia_phy.h"
#include <crc.h>
#include <mmc.h>
#include <asm/errno.h>
#include <nand.h>
#include <spi_flash.h>
#include <spi.h>
#include <asm/global_data.h>
#include <fdtdec.h>

DECLARE_GLOBAL_DATA_PTR;
typedef struct {
	unsigned int image_type;
	unsigned int header_vsn_num;
	unsigned int image_src;
	unsigned char *image_dest_ptr;
	unsigned int image_size;
	unsigned int code_size;
	unsigned char *signature_ptr;
	unsigned int signature_size;
	unsigned char *cert_chain_ptr;
	unsigned int cert_chain_size;
} mbn_header_t;

mbn_header_t *fwimg_header;
static int debug = 0;

#ifdef CONFIG_QCA_MMC
extern qca_mmc mmc_host;
static qca_mmc *host = &mmc_host;
#endif

extern int ipq_mdio_write(int mii_id,
		int regnum, u16 value);
extern int ipq_mdio_read(int mii_id,
		int regnum, ushort *data);

extern int ipq_mdio_write1(int mii_id,
		int regnum, u16 value);
extern int ipq_mdio_read1(int mii_id,
		int regnum, ushort *data);


extern int ipq_sw_mdio_init(const char *);
extern void ipq5332_eth_initialize(void);
static int program_ethphy_fw(unsigned int phy_addr,
			 uint32_t load_addr,uint32_t file_size );
static qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

u16 aq_phy_reg_write(u32 dev_id, u32 phy_id,
		u32 reg_id, u16 reg_val)
{
#ifdef MDIO_IO_CLK_315M
	ipq_mdio_write1(phy_id, reg_id, reg_val);
#else
	ipq_mdio_write(phy_id, reg_id, reg_val);
#endif
	return 0;
}

u16 aq_phy_reg_read(u32 dev_id, u32 phy_id, u32 reg_id)
{
#ifdef MDIO_IO_CLK_315M
	return ipq_mdio_read1(phy_id, reg_id, NULL);
#else
	return ipq_mdio_read(phy_id, reg_id, NULL);
#endif
}

u8 aq_phy_get_link_status(u32 dev_id, u32 phy_id)
{
	u16 phy_data;
	uint32_t reg;

	reg = AQ_PHY_AUTO_STATUS_REG | AQUANTIA_MII_ADDR_C45;
	phy_data = aq_phy_reg_read(dev_id, phy_id, reg);
	phy_data = aq_phy_reg_read(dev_id, phy_id, reg);

	if (((phy_data >> 2) & 0x1) & PORT_LINK_UP)
		return 0;

	return 1;
}

u32 aq_phy_get_duplex(u32 dev_id, u32 phy_id, fal_port_duplex_t *duplex)
{
	u16 phy_data;
	uint32_t reg;

	reg = AQ_PHY_LINK_STATUS_REG | AQUANTIA_MII_ADDR_C45;
	phy_data = aq_phy_reg_read(dev_id, phy_id, reg);

	/*
	 * Read duplex
	 */
	phy_data = phy_data & 0x1;
	if (phy_data & 0x1)
		*duplex = FAL_FULL_DUPLEX;
	else
		*duplex = FAL_HALF_DUPLEX;

	return 0;
}

u32 aq_phy_get_speed(u32 dev_id, u32 phy_id, fal_port_speed_t *speed)
{
	u16 phy_data;
	uint32_t reg;

	reg = AQ_PHY_LINK_STATUS_REG | AQUANTIA_MII_ADDR_C45;
	phy_data = aq_phy_reg_read(dev_id, phy_id, reg);

	switch ((phy_data >> 1) & 0x7) {
	case SPEED_10G:
		*speed = FAL_SPEED_10000;
		break;
	case SPEED_5G:
		*speed = FAL_SPEED_5000;
		break;
	case SPEED_2_5G:
		*speed = FAL_SPEED_2500;
		break;
	case SPEED_1000MBS:
		*speed = FAL_SPEED_1000;
		break;
	case SPEED_100MBS:
		*speed = FAL_SPEED_100;
		break;
	case SPEED_10MBS:
		*speed = FAL_SPEED_10;
		break;
	default:
		return -EINVAL;
	}
	return 0;
}

void aquantia_phy_restart_autoneg(u32 phy_id)
{
	u16 phy_data;

	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_PHY_XS_REGISTERS,
			AQUANTIA_PHY_XS_USX_TRANSMIT));
	if (!(phy_data & AQUANTIA_PHY_USX_AUTONEG_ENABLE))
		aq_phy_reg_write(0x0, phy_id,AQUANTIA_REG_ADDRESS(
			AQUANTIA_MMD_PHY_XS_REGISTERS,
			AQUANTIA_PHY_XS_USX_TRANSMIT),
			 phy_data | AQUANTIA_PHY_USX_AUTONEG_ENABLE);

	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_AUTONEG,
			AQUANTIA_AUTONEG_STANDARD_CONTROL1));

	phy_data |= AQUANTIA_CTRL_AUTONEGOTIATION_ENABLE;
	aq_phy_reg_write(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_AUTONEG,
		AQUANTIA_AUTONEG_STANDARD_CONTROL1),
		phy_data | AQUANTIA_CTRL_RESTART_AUTONEGOTIATION);
}

int ipq_qca_aquantia_phy_init(struct phy_ops **ops, u32 phy_id)
{
	u16 phy_data;
	struct phy_ops *aq_phy_ops;
	aq_phy_ops = (struct phy_ops *)malloc(sizeof(struct phy_ops));
	if (!aq_phy_ops)
		return -ENOMEM;
	aq_phy_ops->phy_get_link_status = aq_phy_get_link_status;
	aq_phy_ops->phy_get_speed = aq_phy_get_speed;
	aq_phy_ops->phy_get_duplex = aq_phy_get_duplex;
	*ops = aq_phy_ops;

	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_PHY_XS_REGISTERS,
			AQUANTIA_PHY_XS_USX_TRANSMIT));

	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(1, QCA_PHY_ID1));
	printf ("PHY ID1: 0x%x\n", phy_data);
	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(1, QCA_PHY_ID2));
	printf ("PHY ID2: 0x%x\n", phy_data);
	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_PHY_XS_REGISTERS,
			AQUANTIA_PHY_XS_USX_TRANSMIT));
	phy_data |= AQUANTIA_PHY_USX_AUTONEG_ENABLE;
	aq_phy_reg_write(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_PHY_XS_REGISTERS,
			AQUANTIA_PHY_XS_USX_TRANSMIT), phy_data);
	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_AUTONEG,
			AQUANTIA_AUTONEG_TRANSMIT_VENDOR_INTR_MASK));
	phy_data |= AQUANTIA_INTR_LINK_STATUS_CHANGE;
	aq_phy_reg_write(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_AUTONEG,
			AQUANTIA_AUTONEG_TRANSMIT_VENDOR_INTR_MASK), phy_data);
	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_GLOABLE_REGISTERS,
			AQUANTIA_GLOBAL_INTR_STANDARD_MASK));
	phy_data |= AQUANTIA_ALL_VENDOR_ALARMS_INTERRUPT_MASK;
	aq_phy_reg_write(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_GLOABLE_REGISTERS,
			AQUANTIA_GLOBAL_INTR_STANDARD_MASK), phy_data);
	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_GLOABLE_REGISTERS,
			AQUANTIA_GLOBAL_INTR_VENDOR_MASK));
	phy_data |= AQUANTIA_AUTO_AND_ALARMS_INTR_MASK;
	aq_phy_reg_write(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_GLOABLE_REGISTERS,
			AQUANTIA_GLOBAL_INTR_VENDOR_MASK), phy_data);

	phy_data = aq_phy_reg_read(0x0, phy_id, AQUANTIA_REG_ADDRESS(AQUANTIA_MMD_PHY_XS_REGISTERS,
			AQUANTIA_PHY_XS_USX_TRANSMIT));
	return 0;
}

static int do_aq_phy_restart(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	unsigned int phy_addr = AQU_PHY_ADDR;
	if (argc > 2)
		return CMD_RET_USAGE;

	if (argc == 2)
		phy_addr = simple_strtoul(argv[1], NULL, 16);

	aquantia_phy_restart_autoneg(phy_addr);
	return 0;
}

int ipq_board_fw_download(unsigned int phy_addr)
{
	char runcmd[256];
	int ret,i=0;
	uint32_t start;         /* block number */
	uint32_t size;          /* no. of blocks */
	qca_part_entry_t	ethphyfw;
	unsigned int *ethphyfw_load_addr = NULL;
	struct { char *name; qca_part_entry_t *part; } entries[] = {
		{ "0:ETHPHYFW", &ethphyfw },
	};
#ifdef CONFIG_QCA_MMC
	block_dev_desc_t *blk_dev;
	disk_partition_t disk_info;
#endif
	/* check the smem info to see which flash used for booting */
	if (sfi->flash_type == SMEM_BOOT_SPI_FLASH) {
		if (debug) {
			printf("Using nor device \n");
		}
	} else if (sfi->flash_type == SMEM_BOOT_NAND_FLASH) {
		if (debug) {
			printf("Using nand device 0\n");
		}
	} else if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
		if (debug) {
			printf("Using MMC device\n");
		}
	} else if (sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH) {
		if (debug) {
			printf("Using qspi nand device 0\n");
		}
	} else {
		printf("Unsupported BOOT flash type\n");
		return -1;
	}

	ret = smem_getpart(entries[i].name, &start, &size);
	if (ret < 0) {
		debug("cdp: get part failed for %s\n", entries[i].name);
	} else {
		qca_set_part_entry(entries[i].name, sfi, entries[i].part, start, size);
	}

	if ((sfi->flash_type == SMEM_BOOT_NAND_FLASH) ||
	    (sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH) ||
	    (sfi->flash_type == SMEM_BOOT_SPI_FLASH)) {
		ethphyfw_load_addr = (uint *)malloc(AQ_ETHPHYFW_IMAGE_SIZE);
		/* We only need memory equivalent to max size ETHPHYFW
		 * which is currently assumed as 512 KB.
		 */
		if (ethphyfw_load_addr == NULL) {
			printf("ETHPHYFW Loading failed, size = %llu\n",
			       ethphyfw.size);
			return -1;
		} else {
			memset(ethphyfw_load_addr, 0, AQ_ETHPHYFW_IMAGE_SIZE);
		}
	}

	if ((sfi->flash_type == SMEM_BOOT_NAND_FLASH) ||
	    (sfi->flash_type == SMEM_BOOT_QSPI_NAND_FLASH)) {
		/*
		 * Kernel is in a separate partition
		 */
		snprintf(runcmd, sizeof(runcmd),
			 /* NOR is treated as psuedo NAND */
			 "nand read 0x%p 0x%llx 0x%llx && ",
			 ethphyfw_load_addr, ethphyfw.offset, (long long unsigned int) AQ_ETHPHYFW_IMAGE_SIZE);

		if (debug)
			printf("%s", runcmd);

		if (run_command(runcmd, 0) != CMD_RET_SUCCESS) {
			free(ethphyfw_load_addr);
			return CMD_RET_FAILURE;
		}
	} else if (sfi->flash_type == SMEM_BOOT_SPI_FLASH) {
		snprintf(runcmd, sizeof(runcmd),
			 "sf probe && " "sf read 0x%p 0x%llx 0x%llx && ",
			 ethphyfw_load_addr, ethphyfw.offset, (long long unsigned int) AQ_ETHPHYFW_IMAGE_SIZE);

		if (debug)
			printf("%s", runcmd);

		if (run_command(runcmd, 0) != CMD_RET_SUCCESS) {
			free(ethphyfw_load_addr);
			return CMD_RET_FAILURE;
		}
#ifdef CONFIG_QCA_MMC
	} else if (sfi->flash_type == SMEM_BOOT_MMC_FLASH ) {
		blk_dev = mmc_get_dev(host->dev_num);
		 ret = get_partition_info_efi_by_name(blk_dev,
						"0:ETHPHYFW", &disk_info);

		ethphyfw_load_addr = (uint *)malloc(((uint)disk_info.size) *
						    ((uint)disk_info.blksz));
		if (ethphyfw_load_addr == NULL) {
			printf("ETHPHYFW Loading failed, size = %lu\n",
			      ((long unsigned int)(uint)disk_info.size) * ((uint)disk_info.blksz));
			return -1;
		} else {
			memset(ethphyfw_load_addr, 0,
			       (((uint)disk_info.size) *
				((uint)disk_info.blksz)));
		}

		if (ret == 0) {
			snprintf(runcmd, sizeof(runcmd),
				 "mmc read 0x%p 0x%X 0x%X",
				 ethphyfw_load_addr,
				 (uint)disk_info.start, (uint)disk_info.size);

			if (run_command(runcmd, 0) != CMD_RET_SUCCESS) {
				free(ethphyfw_load_addr);
				return CMD_RET_FAILURE;
			}
		}
#endif
	}

	fwimg_header = (mbn_header_t *)(ethphyfw_load_addr);

	if (fwimg_header->image_type == 0x13 &&
	    fwimg_header->header_vsn_num == 0x3) {
		program_ethphy_fw(phy_addr,
				  (uint32_t)(((uint32_t)ethphyfw_load_addr)
					     + sizeof(mbn_header_t)),
				  (uint32_t)(fwimg_header->image_size));
	} else {
		printf("bad magic on ETHPHYFW partition\n");
		free(ethphyfw_load_addr);
		return -1;
	}
	free(ethphyfw_load_addr);
	return 0;
}


#define AQ_PHY_IMAGE_HEADER_CONTENT_OFFSET_HHD 0x300
static int program_ethphy_fw(unsigned int phy_addr, uint32_t load_addr, uint32_t file_size)
{
	int i;
	uint8_t *buf;
	uint16_t file_crc;
	uint16_t computed_crc;
	uint32_t reg1, reg2;
	uint16_t recorded_ggp8_val;
	uint16_t daisy_chain_dis;
	uint32_t primary_header_ptr = 0x00000000;
	uint32_t primary_iram_ptr = 0x00000000;
	uint32_t primary_dram_ptr = 0x00000000;
	uint32_t primary_iram_sz = 0x00000000;
	uint32_t primary_dram_sz = 0x00000000;
	uint32_t phy_img_hdr_off;
	uint32_t byte_sz;
	uint32_t dword_sz;
	uint32_t byte_ptr;
	uint16_t msw = 0;
	uint16_t lsw = 0;
	uint8_t msb1;
	uint8_t msb2;
	uint8_t lsb1;
	uint8_t lsb2;
	uint16_t mailbox_crc;

	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x300), 0xdead);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x301), 0xbeaf);
	reg1 = aq_phy_reg_read(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x300));
	reg2 = aq_phy_reg_read(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x301));

	if(reg1 != 0xdead && reg2 != 0xbeaf) {
		printf("PHY::Scratchpad Read/Write test fail\n");
		return 0;
	}
	buf = (uint8_t *)load_addr;
	file_crc = buf[file_size - 2] << 8 | buf[file_size - 1];
	computed_crc = cyg_crc16(buf, file_size - 2);

	if (file_crc != computed_crc) {
		printf("CRC check failed on phy fw file\n");
		return 0;
	} else {
		printf("CRC check good on phy fw file (0x%04X)\n",computed_crc);
	}

	daisy_chain_dis = aq_phy_reg_read(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc452));
	if (!(daisy_chain_dis & 0x1))
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc452), 0x1);

	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc471), 0x40);
	recorded_ggp8_val = aq_phy_reg_read(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc447));
	if ((recorded_ggp8_val & 0x1f) != phy_addr)
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc447), phy_addr);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc441), 0x4000);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc001), 0x41);
	primary_header_ptr = (((buf[0x9] & 0x0F) << 8) | buf[0x8]) << 12;
	phy_img_hdr_off = AQ_PHY_IMAGE_HEADER_CONTENT_OFFSET_HHD;
	primary_iram_ptr = (buf[primary_header_ptr + phy_img_hdr_off + 0x4 + 2] << 16) |
			(buf[primary_header_ptr + phy_img_hdr_off + 0x4 + 1] << 8) |
			buf[primary_header_ptr + phy_img_hdr_off + 0x4];
	primary_iram_sz = (buf[primary_header_ptr + phy_img_hdr_off + 0x7 + 2] << 16) |
			(buf[primary_header_ptr + phy_img_hdr_off + 0x7 + 1] << 8) |
			buf[primary_header_ptr + phy_img_hdr_off + 0x7];
	primary_dram_ptr = (buf[primary_header_ptr + phy_img_hdr_off + 0xA + 2] << 16) |
			(buf[primary_header_ptr + phy_img_hdr_off + 0xA + 1] << 8) |
			buf[primary_header_ptr + phy_img_hdr_off + 0xA];
	primary_dram_sz = (buf[primary_header_ptr + phy_img_hdr_off + 0xD + 2] << 16) |
			(buf[primary_header_ptr + phy_img_hdr_off + 0xD + 1] << 8) |
			buf[primary_header_ptr + phy_img_hdr_off + 0xD];
	primary_iram_ptr += primary_header_ptr;
	primary_dram_ptr += primary_header_ptr;

	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x200), 0x1000);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x200), 0x0);
	computed_crc = 0;
	printf("PHYFW:Loading IRAM...........");
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x202), 0x4000);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x203), 0x0);
	byte_sz = primary_iram_sz;
	dword_sz = byte_sz >> 2;
	byte_ptr = primary_iram_ptr;
	for (i = 0; i < dword_sz; i++) {
		lsw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		msw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x204), msw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x205), lsw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x200), 0xc000);
		msb1 = msw >> 8;
		msb2 = msw & 0xFF;
		lsb1 = lsw >> 8;
		lsb2 = lsw & 0xFF;
		computed_crc = cyg_crc16_computed(&msb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&msb2, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb2, 0x1, computed_crc);
	}

	switch (byte_sz & 0x3) {
	case 0x1:
		lsw = buf[byte_ptr++];
		msw = 0x0000;
		break;
	case 0x2:
		lsw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		msw = 0x0000;
		break;
	case 0x3:
		lsw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		msw = buf[byte_ptr++];
		break;
	}

	if (byte_sz & 0x3) {
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x204), msw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x205), lsw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x200), 0xc000);
		msb1 = msw >> 8;
		msb2 = msw & 0xFF;
		lsb1 = lsw >> 8;
		lsb2 = lsw & 0xFF;
		computed_crc = cyg_crc16_computed(&msb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&msb2, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb2, 0x1, computed_crc);
	}
	printf("done.\n");
	printf("PHYFW:Loading DRAM..............");
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x202), 0x3ffe);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x203), 0x0);
	byte_sz = primary_dram_sz;
	dword_sz = byte_sz >> 2;
	byte_ptr = primary_dram_ptr;
	for (i = 0; i < dword_sz; i++) {
		lsw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		msw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x204), msw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x205), lsw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x200), 0xc000);
		msb1 = msw >> 8;
		msb2 = msw & 0xFF;
		lsb1 = lsw >> 8;
		lsb2 = lsw & 0xFF;
		computed_crc = cyg_crc16_computed(&msb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&msb2, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb2, 0x1, computed_crc);
	}

	switch (byte_sz & 0x3) {
	case 0x1:
		lsw = buf[byte_ptr++];
		msw = 0x0000;
		break;
	case 0x2:
		lsw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		msw = 0x0000;
		break;
	case 0x3:
		lsw = (buf[byte_ptr + 1] << 8) | buf[byte_ptr];
		byte_ptr += 2;
		msw = buf[byte_ptr++];
		break;
	}

	if (byte_sz & 0x3) {
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x204), msw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x205), lsw);
		aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x200), 0xc000);
		msb1 = msw >> 8;
		msb2 = msw & 0xFF;
		lsb1 = lsw >> 8;
		lsb2 = lsw & 0xFF;
		computed_crc = cyg_crc16_computed(&msb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&msb2, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb1, 0x1, computed_crc);
		computed_crc = cyg_crc16_computed(&lsb2, 0x1, computed_crc);
	}
	printf("done.\n");
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc441), 0x2010);
	mailbox_crc = aq_phy_reg_read(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x201));
	if (mailbox_crc != computed_crc) {
		printf("phy fw image load  CRC-16 (0x%X) does not match calculated CRC-16 (0x%X)\n", mailbox_crc, computed_crc);
		return 0;
	} else
		printf("phy fw image load good CRC-16 matches (0x%X)\n", mailbox_crc);

	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0x0), 0x0);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc001), 0x41);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc001), 0x8041);
	mdelay(100);
	aq_phy_reg_write(0x0, phy_addr, AQUANTIA_REG_ADDRESS(0x1e, 0xc001), 0x40);
	mdelay(100);
	aquantia_phy_restart_autoneg(phy_addr);
	return 0;
}

static int do_load_fw(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	unsigned int phy_addr = AQU_PHY_ADDR;

	if (argc > 2)
		return CMD_RET_USAGE;

	if (argc == 2)
		phy_addr = simple_strtoul(argv[1], NULL, 16);

	miiphy_init();
	ipq5332_eth_initialize();
	ipq_sw_mdio_init("IPQ MDIO0");
	ipq_board_fw_download(phy_addr);
	return 0;
}

U_BOOT_CMD(
	aq_load_fw,	5,	1,	do_load_fw,
	"LOAD aq-fw-binary",
	""
);

U_BOOT_CMD(
	aq_phy_restart,	5,	1,	do_aq_phy_restart,
	"Restart Aquantia phy",
	""
);
