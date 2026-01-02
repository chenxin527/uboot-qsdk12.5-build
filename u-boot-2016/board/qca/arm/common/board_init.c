/*
 * Copyright (c) 2015-2017, 2020 The Linux Foundation. All rights reserved.
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
#include <environment.h>
#include <asm/arch-qca-common/qca_common.h>
#include <asm/arch-qca-common/smem.h>
#include <asm/arch-qca-common/uart.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/scm.h>
#include <memalign.h>
#include <fdtdec.h>
#include <mmc.h>
#include <sdhci.h>

DECLARE_GLOBAL_DATA_PTR;
#ifdef CONFIG_ENV_IS_IN_NAND
extern int nand_env_device;
extern env_t *nand_env_ptr;
extern char *nand_env_name_spec;
#endif
extern char *sf_env_name_spec;
extern int nand_saveenv(void);
extern int sf_saveenv(void);

#ifdef CONFIG_QCA_MMC
extern env_t *mmc_env_ptr;
extern char *mmc_env_name_spec;
extern int mmc_saveenv(void);

#ifndef CONFIG_SDHCI_SUPPORT
extern qca_mmc mmc_host;
#else
extern struct sdhci_host mmc_host;
#endif
#endif

#ifdef CONFIG_LIST_OF_CONFIG_NAMES_SUPPORT
struct config_list config_entries;
#endif

env_t *env_ptr;
char *env_name_spec;
int (*saveenv)(void);

loff_t board_env_offset;
loff_t board_env_range;
loff_t board_env_size;

static enum atf_status_t {
        ATF_STATE_DISABLED,
        ATF_STATE_ENABLED,
        ATF_STATE_UNKNOWN,
} atf_status = ATF_STATE_UNKNOWN;

__weak
int ipq_board_usb_init(void)
{
	return 0;
}
__weak
void board_usb_deinit(int id)
{
	return;
}
__weak
void board_pci_deinit(void)
{
	return;
}
__weak
void disable_audio_clks(void)
{
	return;
}
__weak
void ipq_uboot_fdt_fixup(void)
{
	return;
}

__weak void uart_wait_tx_empty(void)
{
	return;
}

__weak void sdi_disable(void)
{
	return;
}

#ifdef CONFIG_SMP_CMD_SUPPORT
__weak int is_secondary_core_off(unsigned int cpuid)
{
	return __invoke_psci_fn_smc(ARM_PSCI_TZ_FN_AFFINITY_INFO, cpuid, 0, 0);
}

__weak void bring_secondary_core_down(unsigned int state)
{
	__invoke_psci_fn_smc(ARM_PSCI_TZ_FN_CPU_OFF, state, 0, 0);
}

__weak int bring_sec_core_up(unsigned int cpuid, unsigned int entry, unsigned int arg)
{
	int err;

	err = __invoke_psci_fn_smc(ARM_PSCI_TZ_FN_CPU_ON, cpuid, entry, arg);
	if (err) {
		printf("Enabling CPU%d via psci failed!\n", cpuid);
		return CMD_RET_FAILURE;
	}

	printf("Enabled CPU%d via psci successfully!\n", cpuid);
	return CMD_RET_SUCCESS;
}
#endif

#define SECURE_BOARD_MAGIC	0x5ECB001

void update_board_type(void)
{
	int ret;
	uint8_t buf = 0;
	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	if(SMEM_BOOT_NO_FLASH == sfi->flash_type)
		return;

	ret = qca_scm_call(SCM_SVC_FUSE, QFPROM_IS_AUTHENTICATE_CMD, &buf,
								sizeof(char));

	if (ret) {
		printf("%s: scm call failed. ret = %d\n", __func__, ret);
		printf("%s: Failed\n", __func__);
		gd->board_type = 0;
		return;
	}

	gd->board_type = (buf == 1) ? SECURE_BOARD_MAGIC : 0;

	return;
}

int board_init(void)
{
	int ret;
	uint32_t start_blocks;
	uint32_t size_blocks;

#ifdef CONFIG_IPQ_REPORT_L2ERR
        u32 l2esr;

        /* Record any kind of L2 errors caused during
         * the previous boot stages as we are clearing
         * the L2 errors before jumping to linux.
         * Refer to cleanup_before_linux() */
#ifndef CONFIG_SYS_DCACHE_OFF
        l2esr = get_l2_indirect_reg(L2ESR_IND_ADDR);
#endif
        report_l2err(l2esr);
#endif

	qgic_init();

	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	gd->bd->bi_boot_params = QCA_BOOT_PARAMS_ADDR;
#ifndef CONFIG_OF_BOARD_FIXUP
	gd->bd->bi_arch_number = smem_get_board_platform_type();
#endif

	ret = smem_get_boot_flash(&sfi->flash_type,
				  &sfi->flash_index,
				  &sfi->flash_chip_select,
				  &sfi->flash_block_size,
				  &sfi->flash_density);

	/*
	 * Should be inited, before env_relocate() is called,
	 * since env. offset is obtained from SMEM.
	 */
	switch (sfi->flash_type) {
	case SMEM_BOOT_MMC_FLASH:
	case SMEM_BOOT_NO_FLASH:
		break;
	default:
		ret = smem_ptable_init();
		if (ret < 0) {
			printf("cdp: SMEM init failed\n");
			return ret;
		}
	}

#ifndef CONFIG_ENV_IS_NOWHERE
	switch (sfi->flash_type) {
#ifdef CONFIG_ENV_IS_IN_NAND
	case SMEM_BOOT_NAND_FLASH:
	case SMEM_BOOT_QSPI_NAND_FLASH:
		nand_env_device = CONFIG_NAND_FLASH_INFO_IDX;
		break;
#endif
	case SMEM_BOOT_SPI_FLASH:
#ifdef CONFIG_ENV_IS_IN_NAND
		nand_env_device = CONFIG_SPI_FLASH_INFO_IDX;
#endif
		break;
	case SMEM_BOOT_MMC_FLASH:
	case SMEM_BOOT_NO_FLASH:
		break;
	default:
		printf("BUG: unsupported flash type : %d\n", sfi->flash_type);
		BUG();
	}

	if ((sfi->flash_type != SMEM_BOOT_MMC_FLASH) && (sfi->flash_type != SMEM_BOOT_NO_FLASH))  {
		ret = smem_getpart("0:APPSBLENV", &start_blocks, &size_blocks);
		if (ret < 0) {
			printf("cdp: get environment part failed\n");
			return ret;
		}

		board_env_offset = ((loff_t) sfi->flash_block_size) * start_blocks;
		board_env_size = ((loff_t) sfi->flash_block_size) * size_blocks;
	}

	switch (sfi->flash_type) {
	case SMEM_BOOT_NAND_FLASH:
	case SMEM_BOOT_QSPI_NAND_FLASH:
		board_env_range = CONFIG_ENV_SIZE_MAX;
		BUG_ON(board_env_size < CONFIG_ENV_SIZE_MAX);
		break;
	case SMEM_BOOT_SPI_FLASH:
		board_env_range = board_env_size;
		BUG_ON(board_env_size > CONFIG_ENV_SIZE_MAX);
		break;
#ifdef CONFIG_QCA_MMC
	case SMEM_BOOT_MMC_FLASH:
		board_env_range = CONFIG_ENV_SIZE_MAX;
		break;
#endif
	case SMEM_BOOT_NO_FLASH:
		board_env_range = CONFIG_ENV_SIZE_MAX;
		break;
	default:
		printf("BUG: unsupported flash type : %d\n", sfi->flash_type);
		BUG();
	}
	if (sfi->flash_type == SMEM_BOOT_SPI_FLASH) {
#ifdef CONFIG_ENV_IS_IN_SPI_FLASH
		saveenv = sf_saveenv;
		env_name_spec = sf_env_name_spec;
#endif
#ifdef CONFIG_QCA_MMC
	} else if (sfi->flash_type == SMEM_BOOT_MMC_FLASH) {
		saveenv = mmc_saveenv;
		env_ptr = mmc_env_ptr;
		env_name_spec = mmc_env_name_spec;
#endif
	} else {
#ifdef CONFIG_ENV_IS_IN_NAND
		saveenv = nand_saveenv;
		env_ptr = nand_env_ptr;
		env_name_spec = nand_env_name_spec;
#else
		saveenv = sf_saveenv;
		env_name_spec = sf_env_name_spec;

#endif
	}
#endif
	ret = ipq_board_usb_init();
	if (ret < 0) {
		printf("WARN: ipq_board_usb_init failed\n");
	}

#if defined(CONFIG_IPQ9574_EDMA)
	aquantia_phy_reset_init();
#endif
	disable_audio_clks();
	/*
	 * Needed by ipq806x & ipq9574 to avoid TX FIFO curruption during
	 * serial init after relocation
	 */
	uart_wait_tx_empty();

	update_board_type();

	return 0;
}

int get_current_flash_type(uint32_t *flash_type)
{
	int ret;

	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	/* get current boot mode from smem and set in env*/
	ret = ipq_smem_get_boot_flash(flash_type);
	if (ret) {
		printf("ipq: fdt fixup cannot get boot mode\n");
		return ret;
	}

	if (*flash_type == SMEM_BOOT_SPI_FLASH) {
		if (get_which_flash_param("rootfs") ||
		    ((sfi->flash_secondary_type == SMEM_BOOT_NAND_FLASH) ||
			(sfi->flash_secondary_type == SMEM_BOOT_QSPI_NAND_FLASH)))
			*flash_type = SMEM_BOOT_NORPLUSNAND;
		else {
			if ((sfi->rootfs.offset == 0xBAD0FF5E) ||
			    sfi->flash_secondary_type == SMEM_BOOT_MMC_FLASH)
				*flash_type = SMEM_BOOT_NORPLUSEMMC;
		}
	}

	return ret;
}

int get_soc_version(uint32_t *soc_ver_major, uint32_t *soc_ver_minor)
{
	int ret;
	uint32_t soc_version;

	ret = ipq_smem_get_socinfo_version((uint32_t *)&soc_version);
	if (!ret) {
		*soc_ver_major = SOCINFO_VERSION_MAJOR(soc_version);
		*soc_ver_minor = SOCINFO_VERSION_MINOR(soc_version);
	}

	return ret;
}
void get_kernel_fs_part_details(void)
{
	int ret, i;
	uint32_t start;         /* block number */
	uint32_t size;          /* no. of blocks */

	qca_smem_flash_info_t *smem = &qca_smem_flash_info;

	struct { char *name; qca_part_entry_t *part; } entries[] = {
		{ "0:HLOS", &smem->hlos },
		{ "rootfs", &smem->rootfs },
	};

	for (i = 0; i < ARRAY_SIZE(entries); i++) {
		ret = smem_getpart(entries[i].name, &start, &size);
		if (ret < 0) {
			qca_part_entry_t *part = entries[i].part;

			/*
			 * To set SoC specific secondary flash type to
			 * eMMC/NAND device based on the one that is enabled.
			 */
			set_flash_secondary_type(smem);

			debug("cdp: get part failed for %s\n", entries[i].name);
			part->offset = 0xBAD0FF5E;
			part->size = 0xBAD0FF5E;
		} else {
			qca_set_part_entry(entries[i].name, smem, entries[i].part, start, size);
		}
	}

	return;
}

int is_atf_enabled(void)
{
	int ret;
	u32 val[2] = {0};

        if (likely(atf_status != ATF_STATE_UNKNOWN))
                return (atf_status == ATF_STATE_ENABLED);

	/*
	 * Understanding is this smc call will not be implemented in ATF in
	 * future as well. If its implemented, Bit 7 should be made to 1.
	 */
	atf_status = ATF_STATE_DISABLED;
	ret = is_scm_sec_auth_available(SCM_SVC_INFO, GET_SECURE_STATE_CMD);
	if (ret > 0) {
		ret = qca_scm_get_secure_state(&val, sizeof(val));
		if ((ret == 0) && (val[0] & 0x80))
			atf_status = ATF_STATE_ENABLED;
	} else
		atf_status = ATF_STATE_ENABLED;

	return (atf_status == ATF_STATE_ENABLED);
}

/*
 * This function is called in the very beginning.
 * Retreive the machtype info from SMEM and map the board specific
 * parameters. Shared memory region at Dram address 0x40400000
 * contains the machine id/ board type data polulated by SBL.
 */
int board_early_init_f(void)
{
	return 0;
}

int board_fix_fdt(void *rw_fdt_blob)
{
	gd->bd->bi_arch_number = smem_get_board_platform_type();

	ipq_uboot_fdt_fixup();
	return 0;
}

#ifdef CONFIG_FLASH_PROTECT
void board_flash_protect(void)
{
#ifdef CONFIG_QCA_MMC
	int num_part;
	int i;
	int ret;
	block_dev_desc_t *mmc_dev;
	disk_partition_t info;

	mmc_dev = mmc_get_dev(mmc_host.dev_num);
	if (mmc_dev != NULL && mmc_dev->type != DEV_TYPE_UNKNOWN) {
		num_part = get_partition_count_efi(mmc_dev);
		if (num_part < 0) {
			printf("Both primary & backup GPT are invalid, skipping mmc write protection.\n");
			return;
		}

		for (i = 1; i <= num_part; i++) {
			ret = get_partition_info_efi(mmc_dev, i, &info);
			if (ret == -1)
				return;
			if (!ret && info.readonly
			    && !mmc_write_protect(mmc_host.mmc,
						  info.start,
						  info.size, 1))
				printf("\"%s\""
					"-protected MMC partition\n",
					info.name);
		}
	}
#endif
}
#endif

__weak int get_soc_hw_version(void)
{
	return 0;
}

int board_late_init(void)
{
	unsigned int machid;
	uint32_t flash_type;
	uint32_t soc_ver_major, soc_ver_minor;
	uint32_t soc_hw_version;
	int ret;
	char *s = NULL;

	qca_smem_flash_info_t *sfi = &qca_smem_flash_info;

	if (sfi->flash_type != SMEM_BOOT_MMC_FLASH) {
		get_kernel_fs_part_details();
	}

	/* get machine type from SMEM and set in env */
	machid = gd->bd->bi_arch_number;
	printf("machid: %x\n", machid);
	if (machid != 0) {
		setenv_addr("machid", (void *)machid);
		gd->bd->bi_arch_number = machid;
	}

	/* get current boot mode from smem and set in env*/
	ret = get_current_flash_type(&flash_type);
	if (!ret)
		setenv_ulong("flash_type", (unsigned long)flash_type);

	ret = get_soc_version(&soc_ver_major, &soc_ver_minor);
	if (!ret) {
		setenv_ulong("soc_version_major", (unsigned long)soc_ver_major);
		setenv_ulong("soc_version_minor", (unsigned long)soc_ver_minor);
	}

	soc_hw_version = get_soc_hw_version();
	if (soc_hw_version)
		setenv_hex("soc_hw_version", (unsigned long)soc_hw_version);
#ifdef CONFIG_FLASH_PROTECT
	board_flash_protect();
#endif
	set_ethmac_addr();

	/*
	 * set fdt_high parameter so that u-boot will not
	 * load dtb above CONFIG_IPQ_FDT_HIGH region.
	 */
	run_command("setenv fdt_high " MK_STR(CONFIG_IPQ_FDT_HIGH) "\n", 0);

	s = getenv("dload_warm_reset");
	if (s) {
		printf("Dload magic cookie will not be set for warm reset\n");
		sdi_disable();
	}

	return 0;
}

#ifdef CONFIG_SMEM_VERSION_C
int ram_ptable_init_v2(void)
{
	struct usable_ram_partition_table rtable;
	int mx = ARRAY_SIZE(rtable.ram_part_entry);
	int i;

	if (smem_ram_ptable_init_v2(&rtable) > 0) {
		gd->ram_size = 0;
		for (i = 0; i < mx; i++) {
			if (rtable.ram_part_entry[i].partition_category == RAM_PARTITION_SDRAM &&
			    rtable.ram_part_entry[i].partition_type == RAM_PARTITION_SYS_MEMORY) {
				gd->ram_size += rtable.ram_part_entry[i].length;
				return 0;
			}
		}
	} else {
		gd->ram_size = fdtdec_get_uint(gd->fdt_blob, 0, "ddr_size", 256);
		gd->ram_size <<= 20;
	}
	return 0;
}
#endif

int dram_init(void)
{
	struct smem_ram_ptable rtable;
	int i;
	int mx = ARRAY_SIZE(rtable.parts);

	if (smem_ram_ptable_init(&rtable) > 0) {
#ifdef CONFIG_SMEM_VERSION_C
		if (rtable.version == 2) {
			return ram_ptable_init_v2();
		}
#endif
		gd->ram_size = 0;
		for (i = 0; i < mx; i++) {
			if (rtable.parts[i].category == RAM_PARTITION_SDRAM &&
			    rtable.parts[i].type == RAM_PARTITION_SYS_MEMORY) {
				gd->ram_size += rtable.parts[i].size;
			}
		}
	} else {
		gd->ram_size = fdtdec_get_uint(gd->fdt_blob, 0, "ddr_size", 256);
		gd->ram_size <<= 20;
	}
	return 0;
}

#ifdef CONFIG_IPQ_REPORT_L2ERR
void report_l2err(u32 l2esr)
{
        if (l2esr & L2ESR_MPDCD)
                printf("L2 Master port decode error\n");

        if (l2esr & L2ESR_MPSLV)
                printf("L2 master port slave error\n");

        if (l2esr & L2ESR_TSESB)
                printf("L2 tag soft error, single-bit\n");

        if (l2esr & L2ESR_TSEDB)
                printf("L2 tag soft error, double-bit\n");

        if (l2esr & L2ESR_DSESB)
                printf("L2 data soft error, single-bit\n");

        if (l2esr & L2ESR_DSEDB)
                printf("L2 data soft error, double-bit\n");

        if (l2esr & L2ESR_MSE)
                printf("L2 modified soft error\n");

        if (l2esr & L2ESR_MPLDREXNOK)
                printf("L2 master port LDREX received Normal OK response\n");
}
#endif

__weak void clear_l2cache_err(void)
{
	return;
}

__weak int smem_read_cpu_count()
{
	return -1;
}

#ifdef CONFIG_LIST_OF_CONFIG_NAMES_SUPPORT
void add_config_entry(const char *config)
{
	if (strlen(config) < CONFIG_NAME_MAX_LEN) {
		 if (config_entries.no_of_entries < CONFIG_NAME_MAX_ENTRIES)
			strlcpy(config_entries.entry
					[config_entries.no_of_entries++],
					config, CONFIG_NAME_MAX_LEN);
		else
			printf("add config entry failed ... \n");
	} else {
		printf("config: %s exceeds max len(%d) ...\n",
						config,
						CONFIG_NAME_MAX_LEN);
	}
}

void init_config_list(void)
{
	memset(&config_entries, 0, sizeof(config_entries));
}

void add_config_list_from_fdt(void)
{
	int i, strings_count;
	const char *config = NULL;

	strings_count = fdt_count_strings(gd->fdt_blob, 0,
						"config_name");
	if (!strings_count) {
		printf("Failed to get config_name\n");
		return;
	}

	if (strings_count > CONFIG_NAME_MAX_ENTRIES) {
		printf("config_name entries exceeds max len\n");
		return;
	}

	for (i = 0; i < strings_count; i++) {
		fdt_get_string_index(gd->fdt_blob, 0,
			"config_name", i, &config);
		add_config_entry(config);
	}
}
#endif
