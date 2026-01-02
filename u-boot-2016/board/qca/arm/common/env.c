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
#include <asm/arch-qca-common/smem.h>
#include <environment.h>

#ifdef CONFIG_SDHCI_SUPPORT
#include <sdhci.h>
#endif
#ifdef CONFIG_ENV_IS_IN_NAND
extern void nand_env_relocate_spec(void);
extern int nand_env_init(void);
#endif
#ifdef CONFIG_ENV_IS_IN_SPI_FLASH
extern void sf_env_relocate_spec(void);
extern int sf_env_init(void);
#endif

#ifdef CONFIG_QCA_MMC
extern int mmc_env_init(void);
extern void mmc_env_relocate_spec(void);
extern int mmc_init(struct mmc *mmc);
#endif

/*
 * Function description: Board specific initialization.
 * I/P : None
 * O/P : integer, 0 - no error.
 */
int env_init(void)
{
	int ret = 0;
	qca_smem_flash_info_t sfi;

	smem_get_boot_flash(&sfi.flash_type,
			    &sfi.flash_index,
			    &sfi.flash_chip_select,
			    &sfi.flash_block_size,
			    &sfi.flash_density);

	if (sfi.flash_type == SMEM_BOOT_SPI_FLASH) {
#ifdef CONFIG_ENV_IS_IN_SPI_FLASH
		ret = sf_env_init();
#endif
#ifdef CONFIG_QCA_MMC
	} else if (sfi.flash_type == SMEM_BOOT_MMC_FLASH) {
		ret = mmc_env_init();
#endif
	} else {
#ifdef CONFIG_ENV_IS_IN_NAND
		ret = nand_env_init();
#endif
	}

	return ret;
}

void env_relocate_spec(void)
{
	qca_smem_flash_info_t sfi;

	smem_get_boot_flash(&sfi.flash_type,
			    &sfi.flash_index,
			    &sfi.flash_chip_select,
			    &sfi.flash_block_size,
			    &sfi.flash_density);

	if (sfi.flash_type == SMEM_BOOT_NO_FLASH) {
		set_default_env("!flashless boot");
#ifdef CONFIG_ENV_IS_IN_SPI_FLASH
	} else if (sfi.flash_type == SMEM_BOOT_SPI_FLASH) {
		sf_env_relocate_spec();
#endif
#ifdef CONFIG_QCA_MMC
	} else if (sfi.flash_type == SMEM_BOOT_MMC_FLASH) {
                mmc_env_relocate_spec();
#endif
	} else {
#ifdef CONFIG_ENV_IS_IN_NAND
		nand_env_relocate_spec();
#endif
	}

};

#ifdef CONFIG_QCA_MMC
#ifdef CONFIG_SDHCI_SUPPORT
int board_mmc_env_init(struct sdhci_host mmc_host)
#else
int board_mmc_env_init(qca_mmc mmc_host)
#endif
{
	block_dev_desc_t *blk_dev;
	disk_partition_t disk_info;
	int ret;

	if (mmc_init(mmc_host.mmc)) {
		/* The HS mode command(cmd6) is getting timed out. So mmc card is
		* not getting initialized properly. Since the env partition is not
		* visible, the env default values are writing into the default
		* partition (start of the mmc device). So do a reset again.
		*/
		if (mmc_init(mmc_host.mmc)) {
			printf("MMC init failed \n");
			return -1;
		}
	}
	blk_dev = mmc_get_dev(mmc_host.dev_num);
	ret = get_partition_info_efi_by_name(blk_dev,
				"0:APPSBLENV", &disk_info);

	if (ret == 0) {
		board_env_offset = disk_info.start * disk_info.blksz;
		board_env_size = disk_info.size * disk_info.blksz;
		board_env_range = board_env_size;
		BUG_ON(board_env_size > CONFIG_ENV_SIZE_MAX);
	}
	return ret;
}
#endif

void set_platform_specific_default_env(void)
{
	uint32_t soc_ver_major, soc_ver_minor, soc_version;
	uint32_t machid;
	uint32_t soc_hw_version;
	int ret;

	machid = smem_get_board_platform_type();
	if (machid != 0)
		setenv_addr("machid", (void *)machid);

	soc_hw_version = get_soc_hw_version();
	if (soc_hw_version)
		setenv_hex("soc_hw_version", (unsigned long)soc_hw_version);

	ret = ipq_smem_get_socinfo_version((uint32_t *)&soc_version);
	if (!ret) {
		soc_ver_major = SOCINFO_VERSION_MAJOR(soc_version);
		soc_ver_minor = SOCINFO_VERSION_MINOR(soc_version);
		setenv_ulong("soc_version_major", (unsigned long)soc_ver_major);
		setenv_ulong("soc_version_minor", (unsigned long)soc_ver_minor);
	}
}
