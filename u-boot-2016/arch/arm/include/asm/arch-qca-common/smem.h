/*
 * Copyright (c) 2015-2017, 2020 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
*/

#ifndef SMEM_H
#define SMEM_H

#define RAM_PARTITION_SDRAM 14
#define RAM_PARTITION_SYS_MEMORY 1
#define IPQ_NAND_ROOTFS_SIZE (64 << 20)

#define SOCINFO_VERSION_MAJOR(ver) ((ver & 0xffff0000) >> 16)
#define SOCINFO_VERSION_MINOR(ver) (ver & 0x0000ffff)

#define INDEX_LENGTH			2
#define SEP1_LENGTH			1
#define VERSION_STRING_LENGTH		72
#define VARIANT_STRING_LENGTH		20
#define SEP2_LENGTH			1
#define OEM_VERSION_STRING_LENGTH	32
#define BUILD_ID_LEN			32

enum {
	SMEM_BOOT_NO_FLASH        = 0,
	SMEM_BOOT_NOR_FLASH       = 1,
	SMEM_BOOT_NAND_FLASH      = 2,
	SMEM_BOOT_ONENAND_FLASH   = 3,
	SMEM_BOOT_SDC_FLASH       = 4,
	SMEM_BOOT_MMC_FLASH       = 5,
	SMEM_BOOT_SPI_FLASH       = 6,
	SMEM_BOOT_NORPLUSNAND     = 7,
	SMEM_BOOT_NORPLUSEMMC     = 8,
	SMEM_BOOT_QSPI_NAND_FLASH  = 11,
};

struct version_entry
{
	char index[INDEX_LENGTH];
	char colon_sep1[SEP1_LENGTH];
	char version_string[VERSION_STRING_LENGTH];
	char variant_string[VARIANT_STRING_LENGTH];
	char colon_sep2[SEP2_LENGTH];
	char oem_version_string[OEM_VERSION_STRING_LENGTH];
} __attribute__ ((__packed__));


unsigned int smem_get_board_platform_type(void);
int smem_ptable_init(void);
#ifdef CONFIG_IPQ_MIBIB_RELOAD
int mibib_ptable_init(unsigned int* load_addr);
#endif
int smem_get_boot_flash(uint32_t *flash_type,
			uint32_t *flash_index,
			uint32_t *flash_chip_select,
			uint32_t *flash_block_size,
			uint32_t *flash_density);
int smem_getpart(char *name, uint32_t *start, uint32_t *size);
int smem_getpart_from_offset(uint32_t offset, uint32_t *start, uint32_t *size);
int getpart_offset_size(char *part_name, uint32_t *offset, uint32_t *size);
unsigned int smem_get_board_machtype(void);
uint32_t get_nand_block_size(uint8_t dev_id);
unsigned int get_which_flash_param(char *part_name);
int smem_get_build_version(char *version_name, int buf_size, int index);
int ipq_smem_get_boot_version(char *version_name, int buf_size);
int get_current_flash_type(uint32_t *flash_type);
void ipq_fdt_fixup_usb_device_mode(void *blob);
void fdt_fixup_auto_restart(void *blob);
void fdt_fixup_flash(void *blob);
int get_soc_version(uint32_t *soc_ver_major, uint32_t *soc_ver_minor);
unsigned int get_dts_machid(unsigned int machid);
#ifdef IPQ_UBI_VOL_WRITE_SUPPORT
int ubi_set_rootfs_part(void);
#endif

typedef struct {
	loff_t offset;
	loff_t size;
} qca_part_entry_t;

typedef struct {
	uint32_t		flash_type;
	uint32_t		flash_index;
	uint32_t		flash_chip_select;
	uint32_t		flash_block_size;
	uint32_t		flash_density;
	uint32_t		flash_secondary_type;
	qca_part_entry_t	hlos;
	qca_part_entry_t	rootfs;
	qca_part_entry_t	dtb;
} qca_smem_flash_info_t;

extern qca_smem_flash_info_t qca_smem_flash_info;

void qca_set_part_entry(char *name, qca_smem_flash_info_t *sfi, qca_part_entry_t *part,
			uint32_t start, uint32_t size);

#define ALT_PART_NAME_LENGTH 16
struct per_part_info
{
	char name[ALT_PART_NAME_LENGTH];
	uint32_t primaryboot;
};

typedef struct
{
#define _SMEM_DUAL_BOOTINFO_MAGIC_START			0xA3A2A1A0
#define _SMEM_DUAL_BOOTINFO_MAGIC_START_TRYMODE		0xA3A2A1A1
#define _SMEM_DUAL_BOOTINFO_MAGIC_END			0xB3B2B1B0

	/* Magic number for identification when reading from flash */
	uint32_t magic_start;
	/* upgradeinprogress indicates to attempting the upgrade */
	uint32_t    age;
	/* numaltpart indicate number of alt partitions */
	uint32_t    numaltpart;

	struct per_part_info per_part_entry[NUM_ALT_PARTITION];

	uint32_t magic_end;

} qca_smem_bootconfig_info_t;

extern qca_smem_bootconfig_info_t qca_smem_bootconfig_info;

int smem_bootconfig_info(void);
unsigned int get_smem_spi_addr_len(void);
unsigned int get_rootfs_active_partition(void);
unsigned int get_mibib_active_partition(void);
void qca_smem_part_to_mtdparts(char *mtdid, int len);
int ipq_smem_get_socinfo_cpu_type(uint32_t *cpu_type);
int ipq_smem_get_socinfo_version(uint32_t *version);
int ipq_smem_get_boot_flash(uint32_t *flash_type);
#endif
