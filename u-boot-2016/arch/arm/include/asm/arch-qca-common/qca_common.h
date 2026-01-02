/*
 * Copyright (c) 2015-2017, 2019 The Linux Foundation. All rights reserved.

 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef ___QCA_COMMON_H_
#define ___QCA_COMMON_H_
#include <asm/u-boot.h>
#include <asm/arch-qca-common/smem.h>
#include <asm/arch-qca-common/gpio.h>
#include <asm/arch-qca-common/clk.h>

#ifdef CONFIG_ARCH_IPQ5018
#include <asm/arch-ipq5018/clk.h>
#endif

#ifdef CONFIG_ARCH_IPQ5332
#include <asm/arch-ipq5332/clk.h>
#endif

#ifdef CONFIG_ARCH_IPQ6018
#include <asm/arch-ipq6018/clk.h>
#endif

#ifdef CONFIG_ARCH_IPQ9574
#include <asm/arch-ipq9574/clk.h>
#endif

#ifdef CONFIG_ARCH_IPQ807x
#include <asm/arch-ipq807x/clk.h>
#endif

#ifdef CONFIG_ARCH_IPQ40xx
#include <asm/arch-ipq40xx/clk.h>
#endif

#ifdef CONFIG_ARCH_IPQ806x
#include <asm/arch-ipq806x/clk.h>
#endif

#define XMK_STR(x)#x
#define MK_STR(x)XMK_STR(x)

/* Crashdump levels */
enum {
	FULL_DUMP,
	MINIMAL_DUMP
};

struct ipq_i2c_platdata {
	int type;
};

typedef struct {
	uint base;
	uint clk_mode;
	struct mmc *mmc;
	int dev_num;
} qca_mmc;

/* Reserved-memory node names and register value*/
typedef struct {
	const char *nodename;
	u32 val[2];
} add_node_t;

typedef struct qca_gpio_config gpio_func_data_t;

typedef struct  {
	gpio_func_data_t *gpio;
	unsigned int gpio_count;
}spi_cfg_t;

typedef struct  {
	gpio_func_data_t *gpio;
	unsigned int gpio_count;
}qpic_nand_cfg_t;

typedef struct {
	spi_cfg_t spi_nor_cfg;
	qpic_nand_cfg_t qpic_nand_cfg;
}board_param_t;

int qca_mmc_init(bd_t *, qca_mmc *);

#if defined(CONFIG_QCA_MMC) && !defined(CONFIG_SDHCI_SUPPORT)
int board_mmc_env_init(qca_mmc mmc_host);
#endif

#ifdef CONFIG_QCA_MMC
int do_mmc_init(void);
#endif
#ifdef CONFIG_QPIC_SERIAL
void do_nand_init(void);
#endif
int ipq_board_usb_init(void);
int spi_nand_init(void);
void board_mmc_deinit(void);
void board_pci_deinit(void);
void set_flash_secondary_type(qca_smem_flash_info_t *);
void dump_func(unsigned int dump_level);
int do_dumpqca_flash_data(const char *);
int do_dumpqca_usb_data(unsigned int dump_level);
void crashdump_exit(void);
int apps_iscrashed(void);
int ipq_read_tcsr_boot_misc(void);
int set_uuid_bootargs(char *boot_args, char *part_name, int buflen, bool gpt_flag);

int get_eth_mac_address(uchar *enetaddr, uint no_of_macs);
void set_ethmac_addr(void);

void aquantia_phy_reset_init_done(void);
void aquantia_phy_reset_init(void);

int bring_sec_core_up(unsigned int cpuid, unsigned int entry, unsigned int arg);
int is_secondary_core_off(unsigned int cpuid);
int smem_read_cpu_count(void);
int get_soc_hw_version(void);
int is_atf_enabled(void);
void get_kernel_fs_part_details(void);

struct dumpinfo_t{
	char name[256]; /* use only file name in 8.3 format */
	uint32_t start;
	uint32_t size;
	int is_aligned_access; /* non zero represent 4 byte access */
	uint32_t is_redirected; /* If this flag is set, 'start' is considered a ptr
			    * to address to be dumped
			    */
	uint32_t offset; /* offset to be added to start address */
	uint32_t dump_level;
	uint32_t to_compress; /* non-zero represent for compressed dump*/
};
extern struct dumpinfo_t dumpinfo_n[];
extern int dump_entries_n;

#ifdef CONFIG_IPQ5018
extern struct dumpinfo_t dumpinfo_s[];
extern int dump_entries_s;
#endif

#define MMC_IDENTIFY_MODE	0
#define MMC_DATA_TRANSFER_MODE	1
#define MMC_DATA_TRANSFER_SDHCI_MODE 2
#define MMC_MODE_HC		0x800

#define SPI_DEFAULT_ADDR_LEN	3
#define SPI_MAX_ADDR_LEN	4

#define MAX_BOOT_ARGS_SIZE 	64

#ifdef CONFIG_LIST_OF_CONFIG_NAMES_SUPPORT
struct config_list {
	char entry[CONFIG_NAME_MAX_ENTRIES][CONFIG_NAME_MAX_LEN];
	uint32_t no_of_entries;
} __attribute__ ((__packed__));

void init_config_list(void);
void add_config_entry(const char *config);
void add_config_list_from_fdt(void);
#endif
#endif  /*  __QCA_COMMON_H_ */
